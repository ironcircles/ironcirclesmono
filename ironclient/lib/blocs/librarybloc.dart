import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/updatetracker_service.dart';
import 'package:rxdart/rxdart.dart';

class LibraryBloc {
  final GlobalEventBloc globalEventBloc;
  //late UserCircleBloc _userCircleBloc; // = UserCircleBloc();

  LibraryBloc({required this.globalEventBloc}) {
    //_userCircleBloc = UserCircleBloc(globalEventBloc: globalEventBloc);
  }

  final _circleObjects = PublishSubject<List<CircleObject>?>();
  Stream<List<CircleObject>?> get allCircleObjects => _circleObjects.stream;

  final _olderCircleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get olderCircleObjects =>
      _olderCircleObjects.stream;

  final _newerCircleObjects = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get newerCircleObjects =>
      _newerCircleObjects.stream;

  final _saveResults = PublishSubject<CircleObject>();
  Stream<CircleObject> get saveResults => _saveResults.stream;

  final _circleObjectDeleted = PublishSubject<CircleObject>();
  Stream<CircleObject> get circleObjectDeleted => _circleObjectDeleted.stream;

  final _circleObjectsDeleted = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get circleObjectsDeleted =>
      _circleObjectsDeleted.stream;

  final _circles = PublishSubject<List<UserCircleCache>>();
  Stream<List<UserCircleCache>> get circles => _circles.stream;

  final _convertedCredentials = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get convertedCredentials =>
      _convertedCredentials.stream;

  /// Initial load from a screen
  initialLoad(List<UserFurnace> userFurnaces, bool initialSync,
      {int amount = 200}) async {
    try {
      ///send the cached results first in case there is no internet
      if (initialSync) _sinkCache(userFurnaces, amount: amount);

      ///intentionally not resinking the cache
      //_userCircleBloc.fetchUserCircles(userFurnaces, false);

      //TODO add a realtime update to this screen if a item comes in
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectCrosscircleBloc.initalLoad: $error");
      _circleObjects.sink.addError(error);
    }
  }

  void sinkCircles(List<UserFurnace> userFurnaces) async {
    try {
      List<UserCircleCache> userCircles = [];

      //List<Circle> cachedCircles = await TableCircleCache.readAll();

      DateTime start = DateTime.now();

      //grab a list of locally cached circles for this user
      for (UserFurnace userFurnace in userFurnaces) {

        if (!userFurnace.connected!) continue;

        DateTime start = DateTime.now();

        List<UserCircleCache> furnaceCircles =
            await TableUserCircleCache.readAllForLibrary(
                userFurnace.pk, userFurnace.userid);

        for (UserCircleCache userCircleCache in furnaceCircles) {
          //add the hitchhiker
          userCircleCache.furnaceObject = userFurnace;
        }

        userCircles.addAll(furnaceCircles);

        debugPrint('sinkCircles: ${DateTime.now().difference(start).inMilliseconds}');
      }

      userCircles.sort((a, b) =>
          a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase()));


      debugPrint('sinkCircles: ${DateTime.now().difference(start).inMilliseconds}');

      _circles.sink.add(userCircles);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('LibraryBloc.sinkCircles: $error');
      rethrow;
    }
  }

  /// Sink top from cache
  void sinkMemCache(List<UserFurnace> userFurnaces, {int amount = 200}) async {
    try {
      List<UserCircleCache> userCircleCaches = [];
      List<String> circles = [];

      List<Circle> cachedCircles = await TableCircleCache.readAll();

      ///TODO PERF this for loop should only call readAllForLibrary once, then filter out the ones not needed
      ///grab a list of locally cached circles for this user
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<UserCircleCache> furnaceCircles =
            await TableUserCircleCache.readAllForLibrary(
                userFurnace.pk, userFurnace.userid);

        /// Grabbing circles from furnaces
        furnaceCircles.add(UserCircleCache(
            prefName: DeviceOnlyCircle.prefName,
            circlePath: await FileSystemService.returnCirclesDirectory(
                globalState.user.id!, DeviceOnlyCircle.circleID),
            circle: DeviceOnlyCircle.circleID,
            user: globalState.user.id!,
            userFurnace: globalState.userFurnace!.pk));

        for (UserCircleCache userCircleCache in furnaceCircles) {
          ///add the hitchhiker
          userCircleCache.furnaceObject = userFurnace;

          circles.add(userCircleCache.circle!);
        }

        userCircleCaches.addAll(furnaceCircles);
      }

      /// get circle objects
      List<Map> map =
          await TableCircleObjectCache.readAmountForMemCache(amount);

      List<CircleObject> retValue =
          CircleObjectService.convertFromCachePerformant(
              globalEventBloc, map, userFurnaces[0].userid!,
              userCircleCaches: userCircleCaches, userFurnaces: userFurnaces);

      _circleObjects.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('LibraryBloc._sinkCache: $error');
      rethrow;
    }
  }

  /// Sink top from cache
  void _sinkCache(List<UserFurnace> userFurnaces, {int amount = 200}) async {
    try {
      List<UserCircleCache> userCircles = [];
      List<CircleObject> retValue = [];
      List<String> circles = [];

      List<Circle> cachedCircles = await TableCircleCache.readAll();

      ///TODO PERF this for loop should only call readAllForLibrary once, then filter out the ones not needed
      ///grab a list of locally cached circles for this user
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<UserCircleCache> furnaceCircles =
            await TableUserCircleCache.readAllForLibrary(
                userFurnace.pk, userFurnace.userid);

        /// Grabbing circles from furnaces
        furnaceCircles.add(UserCircleCache(
            prefName: DeviceOnlyCircle.prefName,
            circlePath: await FileSystemService.returnCirclesDirectory(
                globalState.user.id!, DeviceOnlyCircle.circleID),
            circle: DeviceOnlyCircle.circleID,
            user: globalState.user.id!,
            userFurnace: globalState.userFurnace!.pk));

        for (UserCircleCache userCircleCache in furnaceCircles) {
          ///add the hitchhiker
          userCircleCache.furnaceObject = userFurnace;

          circles.add(userCircleCache.circle!);
        }

        userCircles.addAll(furnaceCircles);
      }

      /// get circle objects
      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readLibrary(circles, amount);

      for (CircleObjectCache circleObjectCache in circleObjectCacheList) {
        ///find the right hitchhikers
        UserCircleCache userCircleCache = userCircles.firstWhere(
            (element) => element.circle == circleObjectCache.circleid,
            orElse: () => UserCircleCache());

        if (userCircleCache.circle == null) continue;

        ///add the hitchikers
        circleObjectCache.userCircleCache = userCircleCache;
        circleObjectCache.userFurnace = userFurnaces
            .firstWhere((element) => element.pk == userCircleCache.userFurnace);

        Map<String, dynamic> decode =
            json.decode(circleObjectCache.circleObjectJson!);

        CircleObject circleObject = CircleObject.fromJson(decode);

        ///check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              ///timer expired.  Don't add this object.  Delete
              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc
                  .broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        ///why do we have to set circle ids for objects? do they not have them?
        try {
          if (circleObject.circle!.id != DeviceOnlyCircle.circleID)
            circleObject.circle = cachedCircles.singleWhere(
                (element) => element.id == circleObjectCache.circleid);
        } catch (err) {
          debugPrint('LibraryBloc._sinkCache: $err');
        }

        if (circleObject.oneTimeView == true) continue;

        ///add the hitchihikers
        circleObject.userFurnace = circleObjectCache.userFurnace;
        circleObject.userCircleCache = circleObjectCache.userCircleCache;

        retValue.add(circleObject);
      }

      _circleObjects.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('LibraryBloc._sinkCache: $error');
      rethrow;
    }
  }

  /// Pulls newer items
  requestNewerThan(List<UserCircleCache> userCircleCaches,
      List<UserFurnace> userFurnaces, DateTime newest,
      {int amount = 1000}) async {
    try {
      List<Circle> cachedCircles = await TableCircleCache.readAll();
      List<String> circleIDs = [];
      List<CircleObject> retValue = [];

      ///make circleid list
      for (var element in userCircleCaches) {
        if (element.guarded != true) {
          circleIDs.add(element.circle!);
        }
      }

      /// get circle objects
      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readLibraryNewerThanMap(
              circleIDs, amount, newest);

      for (CircleObjectCache circleObjectCache in circleObjectCacheList) {
        // find the right hitchhikers
        UserCircleCache userCircleCache = userCircleCaches.firstWhere(
            (element) => element.circle == circleObjectCache.circleid);

        //add the hitchhikers
        circleObjectCache.userCircleCache = userCircleCache;
        circleObjectCache.userFurnace = userFurnaces
            .firstWhere((element) => element.pk == userCircleCache.userFurnace);

        Map<String, dynamic> decode =
            json.decode(circleObjectCache.circleObjectJson!);
        CircleObject circleObject = CircleObject.fromJson(decode);

        ///check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              ///timer expired. Don't add this object. Delete
              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc
                  .broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        try {
          if (circleObject.circle!.id != DeviceOnlyCircle.circleID) {
            circleObject.circle = cachedCircles.singleWhere(
                (element) => element.id == circleObjectCache.circleid);
          }
        } catch (err) {
          debugPrint('LibraryBloc._requestnewerthan: $err');
        }

        //grab the latest Circle object
        if (circleObject.type == 'circlelist') {
          if (circleObject.list!.complete) continue;
        } else if (circleObject.type == 'circlevote') {
          if (!circleObject.vote!.open!) continue;
        }
        if (circleObject.oneTimeView == true) continue;

        //add the hitchhikers
        circleObject.userFurnace = circleObjectCache.userFurnace;
        circleObject.userCircleCache = circleObjectCache.userCircleCache;
        retValue.add(circleObject);
      }
      _newerCircleObjects.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("LibraryBloc.requestOlderThan: $error");
    }
  }

  /// Pulls old items
  requestOlderThan(List<UserCircleCache> userCircleCaches,
      List<UserFurnace> userFurnaces, DateTime created,
      {int amount = 1000, String? type}) async {
    ///need to pass information to library
    ///have correct function there to get older objects
    ///pass objects back here, add them to current
    ///displayed library, not replace

    try {
      List<Circle> cachedCircles = await TableCircleCache.readAll();
      List<String> circleIDs = [];
      List<CircleObject> retValue = [];

      ///make circleid list
      for (var element in userCircleCaches) {
        circleIDs.add(element.circle!);
      }

      /// get circle objects
      late List<CircleObjectCache> circleObjectCacheList;

      if (type != null) {
        circleObjectCacheList =
            await TableCircleObjectCache.readLibraryOlderThanMapByType(
                circleIDs, amount, created, type);
      } else {
        circleObjectCacheList =
            await TableCircleObjectCache.readLibraryOlderThanMap(
                circleIDs, amount, created);
      }

      for (CircleObjectCache circleObjectCache in circleObjectCacheList) {
        // find the right hitchhikers
        UserCircleCache userCircleCache = userCircleCaches.firstWhere(
            (element) => element.circle == circleObjectCache.circleid);

        //add the hitchhikers
        circleObjectCache.userCircleCache = userCircleCache;
        circleObjectCache.userFurnace = userFurnaces
            .firstWhere((element) => element.pk == userCircleCache.userFurnace);

        Map<String, dynamic> decode =
            json.decode(circleObjectCache.circleObjectJson!);
        CircleObject circleObject = CircleObject.fromJson(decode);

        ///check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              ///timer expired. Don't add this object. Delete
              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc
                  .broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        try {
          if (circleObject.circle!.id != DeviceOnlyCircle.circleID) {
            circleObject.circle = cachedCircles.singleWhere(
                (element) => element.id == circleObjectCache.circleid);
          }
        } catch (err) {
          debugPrint('LibraryBloc._requestOlderThan: $err');
        }

        //grab the latest Circle object
        if (circleObject.type == 'circlelist') {
          if (circleObject.list!.complete) continue;
        } else if (circleObject.type == 'circlevote') {
          if (!circleObject.vote!.open!) continue;
        }
        if (circleObject.oneTimeView == true) continue;

        //add the hitchhikers
        circleObject.userFurnace = circleObjectCache.userFurnace;
        circleObject.userCircleCache = circleObjectCache.userCircleCache;
        retValue.add(circleObject);
      }
      _olderCircleObjects.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("LibraryBloc.requestOlderThan: $error");
    }
  }

  convertOldCredentials(List<UserFurnace> userFurnaces) async {
    try {
      List<Map> map = await TableCircleObjectCache.getOldCredentials();

      if (map.isEmpty) {
        await UpdateTrackerService.put(
            UpdateTrackerType.credentialUpgrade, true);
        _convertedCredentials.sink.add([]);
        return;
      }

      List<CircleObject> credentials =
          CircleObjectService.convertFromCachePerformant(
              globalEventBloc, map, userFurnaces[0].userid!);

      for (CircleObject credential in credentials) {
        credential.type = CircleObjectType.CIRCLECREDENTIAL;
      }

      await TableCircleObjectCache.upsertListofObjectsFailsafe('', credentials);

      await UpdateTrackerService.put(UpdateTrackerType.credentialUpgrade, true);

      // _sinkCache(userFurnaces);

      _convertedCredentials.sink.add(credentials);

      return;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  dispose() async {
    await _circleObjects.drain();
    _circleObjects.close();

    await _olderCircleObjects.drain();
    _olderCircleObjects.close();

    await _saveResults.drain();
    _saveResults.close();

    await _circleObjectDeleted.drain();
    _circleObjectDeleted.close();

    await _circleObjectsDeleted.drain();
    _circleObjectsDeleted.close();

    await _circles.drain();
    _circles.close();
  }
}
