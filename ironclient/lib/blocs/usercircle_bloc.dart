import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/swipepatternattempt.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/models/usercircleenvelopecontents.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_usercircleenvelope.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/circle_background_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:ironcirclesapp/services/usercircle_service.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

class UserCircleBloc {
  final GlobalEventBloc globalEventBloc;

  UserCircleBloc({required this.globalEventBloc}) {
    _circleObjectBloc = CircleObjectBloc(globalEventBloc: globalEventBloc);
  }

  static const String REMOVED_FROM_CIRCLE = 'user removed from circle';

  late CircleObjectBloc _circleObjectBloc; // = CircleObjectBloc();
  final _userCircleService = UserCircleService();
  final _circleBackgroundService = CircleBackgroundService();

  final _userCircles = PublishSubject<List<UserCircleCache>>();
  Stream<List<UserCircleCache>> get allUserCircles => _userCircles.stream;

  final _hiddenAndClosed = PublishSubject<List<UserCircleCache>>();
  Stream<List<UserCircleCache>> get hiddenAndClosed => _hiddenAndClosed.stream;

  final _userCirclesRefreshed = PublishSubject<List<UserCircleCache>>();
  Stream<List<UserCircleCache>> get refreshedUserCircles => _userCircles.stream;

  final _userCirclesRefreshedSync = PublishSubject<bool>();
  Stream<bool> get refreshedUserCirclesSync => _userCirclesRefreshedSync.stream;

  final _userCircle = PublishSubject<UserCircle?>();
  Stream<UserCircle?> get userCircle => _userCircle.stream;

  final _hiddenCircles = PublishSubject<List<UserCircleCache>?>();
  Stream<List<UserCircleCache>?> get returnHiddenCircles =>
      _hiddenCircles.stream;

  final _updated = PublishSubject<UserCircleCache?>();
  Stream<UserCircleCache?> get updateResponse => _updated.stream;

  final _updatedImage = PublishSubject<UserCircleCache?>();
  Stream<UserCircleCache?> get updatedImage => _updatedImage.stream;

  final _imageLoaded = PublishSubject<UserCircleCache>();
  Stream<UserCircleCache> get imageLoaded => _imageLoaded.stream;

  final _leaveCircle = PublishSubject<bool?>();
  Stream<bool?> get leaveCircleResponse => _leaveCircle.stream;

  final _attemptedNetworkConnection = PublishSubject<bool?>();
  Stream<bool?> get attemptedNetworkConnection =>
      _attemptedNetworkConnection.stream;

  final _swipePatternAttempts = PublishSubject<List<SwipePatternAttempt>>();
  Stream<List<SwipePatternAttempt>> get swipePatternAttempts =>
      _swipePatternAttempts.stream;

  leaveCircle(UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      bool response = await _userCircleService.leaveCircle(
          userCircleCache.circle!, userFurnace);

      if (response == true) {
        await _deleteCircleFromCache(userCircleCache);
        await TableMemberCircle.deleteAllForCircle(userCircleCache.circle!);
        globalEventBloc.broadcastHideCircle(userCircleCache.usercircle!);

        _leaveCircle.sink.add(response);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _leaveCircle.sink.addError(error);
    }
  }

  _deleteCircleFromCache(UserCircleCache userCircleCache) async {
    if (userCircleCache.circlePath != null)
      await FileSystemService.deleteCircleCache(userCircleCache.circlePath!);
    if (userCircleCache.circle != null) {
      await TableCircleObjectCache.deleteAllForCircle(userCircleCache.circle);

      globalEventBloc.removeObjectsForCircle(userCircleCache.circle!);
    }
    if (userCircleCache.usercircle != null)
      await TableUserCircleCache.deleteUserCircle(userCircleCache.usercircle);
  }

  sinkOnly(List<UserFurnace> userFurnaces, {bool includeClosed = false}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      sinkCache(userFurnaces, includeClosed: includeClosed);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.fetchAll: $err');
    }
  }

  fetchAll(bool force, {List<UserFurnace> homeFurnaces = const []}) async {
    try {
      if (globalState.user.id == null) return;

      late List<UserFurnace> userFurnaces;

      if (homeFurnaces.isNotEmpty) {
        userFurnaces = homeFurnaces;
      } else {
        userFurnaces =
            await TableUserFurnace.readConnectedForUser(globalState.user.id);
      }
      //debugPrint('UserCircleBloc.fetchAll');

      fetchUserCircles(userFurnaces, false, force);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.fetchAll: $err');
    }
  }

  fetchHistory() async {
    try {

      UserFurnaceBloc userFurnaceBloc = UserFurnaceBloc();
      List<UserFurnace> userFurnaces = await userFurnaceBloc.requestAll();

      //List<UserCircleCache> userCircleCaches =
      //   await TableUserCircleCache.readAllForUserFurnaces(userFurnaces);



      ///Update the cache from the server
      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!) {
          List<UserCircle> sublist =await _fetchHistoryForNetwork(
            userFurnace,
          );

          await _circleObjectBloc.fetchHistory(userFurnace, sublist);
        }
      }

      _userCirclesRefreshedSync.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc.fetchUserCirclesSync: $error');
      _userCirclesRefreshedSync.sink.addError(error);
    }
  }

  fetchUserCirclesSync(bool force) async {
    try {
      //debugPrint('fetchUserCirclesSync');
      List<UserCircleCache>? existingCache;

      UserFurnaceBloc userFurnaceBloc = UserFurnaceBloc();
      List<UserFurnace> userFurnaces =
          await userFurnaceBloc.requestConnected(globalState.user.id);

      //List<UserCircleCache> userCircleCaches =
      //   await TableUserCircleCache.readAllForUserFurnaces(userFurnaces);

      ///Update the cache from the server
      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!) {
          await refreshCacheFromSingleFurnace(
            userFurnace,
            existingCache,
            furnaceCallback,
            userFurnaces,
            force,
            //  userCircleCaches,
            sync: true,
          );
        }
      }

      _userCirclesRefreshedSync.sink.add(true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc.fetchUserCirclesSync: $error');
      _userCirclesRefreshedSync.sink.addError(error);
    }
  }

  fetchUserCircles(List<UserFurnace> userFurnaces, bool initialSink, bool force,
      {overrideLastItemUpdate = false}) async {
    try {
      //debugPrint('fetchUserCircles')

      List<UserCircleCache>? existingCache;
      //List<UserCircle> allCircles = [];

      //sink the cache
      /*if (initialSink)*/
      existingCache = await sinkCache(userFurnaces);

      if (globalState.userCircleFetch != null && force == false) {
        Duration duration =
            DateTime.now().difference(globalState.userCircleFetch!);

        if (duration.inSeconds < 8) {
          debugPrint('*****************fetchUserCircles: too soon');
          return;
        }
      }

      globalState.userCircleFetch = DateTime.now();

      // List<UserCircleCache> userCircleCaches =
      //   await TableUserCircleCache.readAllForUserFurnaces(userFurnaces);

      ///Update the cache from the server
      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!) {
          refreshCacheFromSingleFurnace(
              userFurnace, existingCache, furnaceCallback, userFurnaces, force,
              overrideLastItemUpdate: overrideLastItemUpdate);

          //don't wait for this
          // if (fetchCircleObjects) _fetchCircleObjects(userFurnace);  <---  This is being called from refreshCacheFromSingleFurnace
        }
      }

      //sink the cache again
      //await sinkCache(userFurnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc.fetchUserCircles: $error');
      _userCircles.sink.addError(error);
    }
  }

  void furnaceCallback(List<UserFurnace> userFurnaces) async {
    ///crappy work around for home spinner on iOS because killing the app stops the firebase background process
    // _attemptedNetworkConnection.sink.add(true);

    sinkCache(userFurnaces);
    globalEventBloc.broadcastActionNeededRefresh();
  }

  Future<UserCircleCache> getUserCircleCacheFromCircle(String circleID) async {
    UserCircleCache userCircleCache = UserCircleCache();

    // bool found = false;
    List<UserFurnace> userFurnaces =
        await TableUserFurnace.readConnectedForUser(globalState.user.id);

    for (UserFurnace userFurnace in userFurnaces) {
      String userCircleID = await TableUserCircleCache.getUserCircleID(
          userFurnace.userid!, circleID);

      if (userCircleID.isNotEmpty) {
        userCircleCache = await TableUserCircleCache.read(userCircleID);

        //found = true;
        break;
      }
    }

    return userCircleCache;
  }

  Future<UserCircleCache> refreshFromPushNotification(
    CircleObject circleObject,
    bool generalUpdate,
    bool force,
  ) async {
    late UserCircleCache userCircleCache;

    try {
      if (circleObject.ratchetIndexes.isEmpty) {
        //votes and system notifications

        userCircleCache =
            await getUserCircleCacheFromCircle(circleObject.circle!.id!);

        if (userCircleCache.usercircle == null &&
            circleObject.type == CircleObjectType.SYSTEMMESSAGE) {
          ///no existing user circle yet because it is for user joining new circle/dm
          throw ('user still joining circle/dm');
        }

        if (userCircleCache.usercircle == null)
          throw ('could not find usercircle for push notification');
      } else {
        //there should be only one user in the ratchetIndexes list (but multiple devices)

        ///this won't work with new reactions, there are multiple ratchet index users. Find the user based on
        // userCircleCache =
        // await TableUserCircleCache.readUserCircleCacheByCircleAndUser(
        //     circleObject.circle!.id!, circleObject.ratchetIndexes[0].user);

        List<String> userIDs = [];

        for (RatchetIndex ratchetIndex in circleObject.ratchetIndexes) {
          userIDs.add(ratchetIndex.user);
        }

        userCircleCache =
            await TableUserCircleCache.readUserCircleCacheByCircleAndUsers(
                circleObject.circle!.id!, userIDs);
      }

      UserFurnace userFurnace =
          await TableUserFurnace.read(userCircleCache.userFurnace);

      if (circleObject.type == 'systemmessage') {
        userCircleCache.showBadge = true;
      } else if (circleObject.creator!.id! != userCircleCache.user) {
        userCircleCache.showBadge = true;
      } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
        if (circleObject.list!.lastEdited != null) {
          if (circleObject.list!.lastEdited!.id! != userCircleCache.user)
            userCircleCache.showBadge = true;
        }
      }

      debugPrint(
          'Refresh from push notification showBadge: ${userCircleCache.showBadge.toString()}');
      userCircleCache.furnaceObject = userFurnace;
      userCircleCache.lastItemUpdate = circleObject.lastUpdate;
      await TableUserCircleCache.upsert(userCircleCache);

      //CircleObjectBloc circleObjectBloc = CircleObjectBloc();

      if (circleObject.type != CircleObjectType.CIRCLEALBUM) {
        List<CircleObject> results = await _circleObjectBloc.updateCache(
            userFurnace, circleObject.circle!.id!, [circleObject], true);

        circleObject.body = results[0].body;
        circleObject.userFurnace = userCircleCache.furnaceObject!;
        circleObject.userCircleCache = userCircleCache;
        globalEventBloc.broadcastCircleObject(circleObject);

        //ForwardSecrecy.ratchetReceiverKey(
        //userFurnace, userCircleCache.circle!, userCircleCache.usercircle!);

        if (generalUpdate) {
          refreshFurnaceFromPushNotification(userCircleCache.circle, force);
        }
      }

      return userCircleCache;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshFromPushNotification: $err');
      fetchAll(false);
      rethrow;
    }
  }

  /*Future<UserCircleCache> refreshFromReaction(
      String circleObjectID, var reactions, DateTime lastUpdate) async {
    late UserCircleCache userCircleCache;

    try {
      CircleObjectCache circleObjectCache =
          await TableCircleObjectCache.get(circleObjectID);

      Map<String, dynamic>? decode =
          json.decode(circleObjectCache.circleObjectJson!);

      CircleObject circleObject = CircleObject.fromJson(decode!);

      Map<String, dynamic> map = {"reactions": reactions};

      circleObject.reactions =
          CircleObjectReactionCollection.fromJSON(map, "reactions").reactions;
      circleObject.lastUpdate = lastUpdate;

      //await TableCircleObjectCache.updateCacheSingleObject(circleObject);

      userCircleCache =
          await refreshFromPushNotification(circleObject, false, true);

      return userCircleCache;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshFromReaction: $err');
      fetchAll(false);
      throw (err);
    }
  }

   */

  deleteFromPushNotification(String id) async {
    try {
      CircleObjectCache circleObject = await TableCircleObjectCache.get(id);

      if (circleObject.circleObjectid != null) {
        await TableCircleObjectCache.delete(id);
        globalEventBloc.broadcastCircleObjectDeleted(circleObject.seed!);
        globalEventBloc.broadCastMemCacheCircleObjectsRemove(
            [CircleObject(ratchetIndexes: [], seed: circleObject.seed!)]);
      }

      globalEventBloc.broadcastActionNeededRefresh();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc.refreshFurnace: $error');
      //_userCircles.sink.addError(error);
    }
  }

  Future<List<UserCircle>> refreshFurnaceFromPushNotification(
      String? circleID, bool force) async {
    List<UserCircle> returnCircles = [];

    try {
      ///TODO LastFetched
      /*if (globalState.userCircleFetch != null && !force) {
        Duration duration =
            DateTime.now().difference(globalState.userCircleFetch!);

        if (duration.inSeconds < 20) return returnCircles;
      }

      globalState.userCircleFetch = DateTime.now();

       */

      //Grab the matching usercircles from the cache
      List<UserCircleCache> _userCircleCache =
          await TableUserCircleCache.readUserCircleCacheByCircleID(circleID);

      for (UserCircleCache userCircleCache in _userCircleCache) {
        //CircleObjects are shared between users on the same device.  Any connected furnace will work for a refresh
        UserFurnace userFurnace =
            await TableUserFurnace.read(userCircleCache.userFurnace);

        if (userFurnace.connected!) {
          List<UserCircle> furnaceCircles =
              await refreshCacheForSpecificCirclesFromPushNotification(
                  userFurnace, _userCircleCache, force);

          returnCircles.addAll(furnaceCircles);

          List<UserFurnace> sinkThese = [];
          sinkThese.add(userFurnace);

          await sinkCache(sinkThese);
          // _userCirclesRefreshed.sink.add(userCirclesCache);

          break;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc.refreshFurnace: $error');
      //_userCircles.sink.addError(error);
    }

    return returnCircles;
  }

  _deleteUserCircleCache(String id) async {
    try {
      UserCircleCache userCircleCache = await TableUserCircleCache.read(id);

      await _deleteCircleFromCache(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc._deleteUserCircleCache: $err');
    }
  }

  Future<List<UserCircle>> _fetchHistoryForNetwork(UserFurnace userFurnace) async {
    try {
      if (userFurnace.userid == globalState.userFurnace!.userid &&
          kDebugMode &&
          (Urls.runLocation == RunLocation.staging ||
              Urls.runLocation == RunLocation.production)) {
        ///only print this if debugging staging or production, token is used for postman calls
        debugPrint('TOKEN FOR POSTMAN: ${userFurnace.token}');
      }

      List<UserCircle> userCircles =
          await _userCircleService.fetchHistory(userFurnace);

       if (userCircles.isNotEmpty) {
        bool first = true;

        ///read all the userCircles at once
        List<UserCircleCache> userCircleCaches =
            await TableUserCircleCache.readAllForUserFurnace(
                userFurnace.pk, userFurnace.userid);

        for (UserCircle userCircle in userCircles) {
          try {
            if (first) {
              TableUserFurnace.upsertUserFields(
                  userFurnace, userCircle.user!, globalEventBloc);
              first = false;
            }
            if (userCircle.circle == null) {
              await _deleteUserCircleCache(userCircle.id!);

              if (userCircle.removeFromCache != null) {
                await TableMemberCircle.deleteAllForCircle(
                    userCircle.removeFromCache!);
              }
              continue;
            }

            ///update the circle cache; in the event something changed
            TableCircleCache.upsert(userCircle.circle!);
            _deleteDisappearingMessages(userCircle);

            bool updateBackground = false;

            UserCircleCache? userCircleCache;

            int index = userCircleCaches
                .indexWhere((element) => element.usercircle == userCircle.id);

            if (index > -1) {
              userCircleCache = userCircleCaches[index];
            }

            ///don't check new ones
            if (userCircleCache != null) {
              if (userCircle.background != userCircleCache.background)
                updateBackground = true;
            }

            ///save new ones outside the batch, remove the deleted ones outside of the batch
            if (userCircleCache == null || userCircle.removeFromCache != null) {
              userCircleCache =
                  await TableUserCircleCache.updateUserCircleCache(
                userCircle,
                userFurnace,
              );
            }

            if (userCircleCache != null) {
              processUserCircleObject(userFurnace, userCircle, userCircleCache,
                  updateBackground, false);
            }
          } catch (error, trace) {
            LogBloc.insertError(error, trace);
            //TODO consider removing this circle from the refresh

            userCircle.prefName ??= '';

            await TableUserCircleCache.updateUserCircleCache(
              userCircle,
              userFurnace,
            );
          }
        }

        await TableUserCircleCache.batchUpdateUserCircles(
            userCircles, userCircleCaches, userFurnace);
      } else {
        debugPrint('UserCircles are empty');
      }

      return userCircles;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshCacheFromSingleFurnace: $err');
      return [];
    }
  }

  Future<List<UserCircle>?> refreshCacheFromSingleFurnace(
      UserFurnace userFurnace,
      List<UserCircleCache>? beforeCaches,
      Function callback,
      List<UserFurnace> userFurnaces,
      bool force,
      {bool sync = false,
      bool overrideLastItemUpdate = false,
      UserCirclesAndObjects? registrationUserCirclesAndObjects}) async {
    try {
      if (userFurnace.userid == globalState.userFurnace!.userid &&
          kDebugMode &&
          (Urls.runLocation == RunLocation.staging ||
              Urls.runLocation == RunLocation.production)) {
        ///only print this if debugging staging or production, token is used for postman calls
        debugPrint('TOKEN FOR POSTMAN: ${userFurnace.token}');
      }

      ///TODO LastFetched
      /*
      if (globalState.userCircleFetch != null && !force) {
        Duration duration =
            DateTime.now().difference(globalState.userCircleFetch!);

        if (duration.inSeconds < 20) return null;
      }

      globalState.userCircleFetch = DateTime.now();

       */

      //open and pass a list of any guarded circles currently unguarded
      List<String?> openGuardedIDs =
          await TableUserCircleCache.readOpenGuardedForFurnace(
              userFurnace.pk, userFurnace.userid);

      List<UserCircleCache> cachedUserCircles =
          await TableUserCircleCache.readAllForUserFurnace(
              userFurnace.pk, userFurnace.userid);

      List<CircleLastLocalUpdate> circleLastUpdates =
          await CircleLastLocalUpdate.readAll(cachedUserCircles);

      late UserCirclesAndObjects userCirclesAndObjects;

      ///Objects are returned during registration, not need to refetch
      if (registrationUserCirclesAndObjects != null) {
        userCirclesAndObjects = registrationUserCirclesAndObjects;
      } else {
        userCirclesAndObjects = await _userCircleService.fetchUserCircles(
            userFurnace, openGuardedIDs, circleLastUpdates);
      }

      List<UserCircle> userCircles = userCirclesAndObjects.userCircles;

      CircleObjectBloc circleObjectBloc =
          CircleObjectBloc(globalEventBloc: globalEventBloc);

      if (userCircles.isNotEmpty) {
        //check to see if a local circle should be removed because it is not on the server
        for (UserCircleCache userCircleCache in cachedUserCircles) {
          //UserCircle userCircle = UserCircle(ratchetKeys: []);

          try {
            int index = userCircles.indexWhere(
                (element) => element.id == userCircleCache.usercircle);

            //userCircle = userCircles.firstWhere(
            //    (element) => element.id == userCircleCache.usercircle);

            if (index < 0) {
              //the circle wasn't found from the server for some reason.  Remove from the cache
              TableUserCircleCache.delete(userCircleCache);
            }
          } catch (err) {
            //LogBloc.insertError(err, trace);
            debugPrint(
                'UserCircleBloc.refreshCacheFromSingleFurnace - Inner for loop: $err');
          }
        }

        bool first = true;

        ///read all the userCircles at once
        List<UserCircleCache> userCircleCaches =
            await TableUserCircleCache.readAllForUserFurnace(
                userFurnace.pk, userFurnace.userid);

        for (UserCircle userCircle in userCircles) {
          try {
            ///cache any returned CircleObjects
            try {
              if (userCircle.circle != null) {
                List<CircleObject> circleObjects = userCirclesAndObjects
                    .circleObjects
                    .where((element) => (element.circle != null &&
                        element.circle!.id == userCircle.circle!.id))
                    .toList();

                List<CircleObject> deletedObjects = userCirclesAndObjects
                    .circleObjects
                    .where((element) => (element.circle == null &&
                        element.removeFromCache == userCircle.circle!.id))
                    .toList();

                circleObjects.addAll(deletedObjects);

                if (circleObjects.isNotEmpty) {
                  circleObjectBloc.updateCache(
                      userFurnace, userCircle.circle!.id!, circleObjects, true);
                }
              }

              /*List<CircleObject> circleObjects = userCirclesAndObjects
                  .circleObjects
                  .where((element) => (element.circle != null &&
                      element.circle!.id == userCircle.circle!.id))
                  .toList();

              List<CircleObject> deletedObjects = userCirclesAndObjects
                  .circleObjects
                  .where((element) => (element.circle == null &&
                      element.removeFromCache == userCircle.circle!.id))
                  .toList();

              circleObjects.addAll(deletedObjects);

              if (circleObjects.isNotEmpty) {
                circleObjectBloc.updateCache(
                    userFurnace, userCircle.circle!.id!, circleObjects, true);
              }

               */
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
            }

            if (first) {
              TableUserFurnace.upsertUserFields(
                  userFurnace, userCircle.user!, globalEventBloc);
              first = false;
            }
            if (userCircle.circle == null) {
              await _deleteUserCircleCache(userCircle.id!);

              if (userCircle.removeFromCache != null) {
                await TableMemberCircle.deleteAllForCircle(
                    userCircle.removeFromCache!);
              }
              continue;
            }

            ///update the circle cache; in the event something changed
            TableCircleCache.upsert(userCircle.circle!);
            _deleteDisappearingMessages(userCircle);

            bool updateBackground = false;

            ///Removed for optimization in 1.1.19
            /*
            UserCircleCache? userCircleCache =
                await TableUserCircleCache.read(userCircle.id!);

             */

            UserCircleCache? userCircleCache;

            int index = userCircleCaches
                .indexWhere((element) => element.usercircle == userCircle.id);

            if (index > -1) {
              userCircleCache = userCircleCaches[index];
            }

            ///don't check new ones
            if (userCircleCache != null) {
              if (userCircle.background != userCircleCache.background)
                updateBackground = true;

              try {
                ///Make sure a slow running server pull doesn't override adding a post and returning home quickly
                if (overrideLastItemUpdate == false) {
                  if (userCircleCache.lastItemUpdate != null) {
                    if (userCircle.lastItemUpdate!
                            .compareTo(userCircleCache.lastItemUpdate!) <
                        0)
                      userCircle.lastItemUpdate =
                          userCircleCache.lastItemUpdate;
                  }
                }
              } catch (error, trace) {
                LogBloc.insertError(error, trace);
              }
            }

            ///save new ones outside the batch, remove the deleted ones outside of the batch
            if (userCircleCache == null || userCircle.removeFromCache != null) {
              userCircleCache =
                  await TableUserCircleCache.updateUserCircleCache(
                userCircle,
                userFurnace,
              );
            }

            if (userCircleCache != null) {
              processUserCircleObject(userFurnace, userCircle, userCircleCache,
                  updateBackground, sync);
            }
          } catch (error, trace) {
            LogBloc.insertError(error, trace);
            //TODO consider removing this circle from the refresh

            userCircle.prefName ??= '';

            await TableUserCircleCache.updateUserCircleCache(
              userCircle,
              userFurnace,
            );
          }
        }

        await TableUserCircleCache.batchUpdateUserCircles(
            userCircles, userCircleCaches, userFurnace);

        if (sync) {
          await _circleObjectBloc.getNewForUserCircles(
              userFurnace, openGuardedIDs, circleLastUpdates, force);
        } else {
          ///This is no longer need as the CircleObjects are returned with the UserCircles
          /*
          ///don't wait
          _circleObjectBloc.getNewForUserCircles(
              userFurnace, openGuardedIDs, circleLastUpdates, force);

           */
        }
      } else {
        debugPrint('UserCircles are empty');
      }

      callback(userFurnaces);

      return userCircles;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshCacheFromSingleFurnace: $err');

      callback(userFurnaces);
      return null;
    }
  }

  _deleteDisappearingMessages(UserCircle userCircle) async {
    if (userCircle.circle!.privacyDisappearingTimer != null &&
        userCircle.circle!.privacyDisappearingTimer != 0) {
      int expired = DateTime.now().millisecondsSinceEpoch -
          (userCircle.circle!.privacyDisappearingTimer! * 60 * 60 * 1000);

      TableCircleObjectCache.deleteDisappearingMessages(
          userCircle.circle!, expired);
      globalEventBloc.broadcastMemCacheCircleObjectsRemoveExpired(
          MemCacheExpired(
              circleID: userCircle.circle!.id!,
              privacyDisappearingTimer:
                  expired)); //userCircle.circle!.id!, expired);
    }
  }

  Future<List<UserCircle>> refreshCacheForSpecificCirclesFromPushNotification(
      UserFurnace userFurnace,
      List<UserCircleCache> specificCircles,
      bool force) async {
    List<UserCircle> userCircles = [];

    try {
      ///open and pass a list of any guarded circles currently unguarded
      List<String?> openGuardedIDs =
          await TableUserCircleCache.readOpenGuardedForFurnace(
              userFurnace.pk, userFurnace.userid);

      //TODO hive garbage
      List<CircleLastLocalUpdate> circleLastUpdates =
          await CircleLastLocalUpdate.readAll(specificCircles);

      UserCirclesAndObjects userCirclesAndObjects = await _userCircleService
          .fetchUserCircles(userFurnace, openGuardedIDs, circleLastUpdates);

      userCircles = userCirclesAndObjects.userCircles;

      List<UserCircleCache> userCircleCaches =
          await TableUserCircleCache.readAllForUserFurnace(
              userFurnace.pk!, userFurnace.userid!);

      ///This is no longer need as the CircleObjects are returned with the UserCircles
      /*
      await _circleObjectBloc.getNewForUserCircles(
          userFurnace, openGuardedIDs, circleLastUpdates, force);

       */

      CircleObjectBloc circleObjectBloc =
          CircleObjectBloc(globalEventBloc: globalEventBloc);

      for (UserCircle userCircle in userCircles) {
        if (userCircle.circle == null) {
          await _deleteUserCircleCache(userCircle.id!);
          continue;
        }

        ///cache any returned CircleObjects
        try {
          List<CircleObject> circleObjects = userCirclesAndObjects.circleObjects
              .where((element) => element.circle!.id == userCircle.circle!.id)
              .toList();

          if (circleObjects.isNotEmpty) {
            circleObjectBloc.updateCache(
                userFurnace, userCircle.circle!.id!, circleObjects, true);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }

        ///commented out for performance
        //await TableUserCircleCache.updateUserCircleCache(
        // userCircle, userFurnace);
      }

      await TableUserCircleCache.batchUpdateUserCircles(
          userCircles, userCircleCaches, userFurnace);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'UserCircleBloc.refreshCacheFromSingleFurnaceForSpecificCircles: $err');
    }

    return userCircles;
  }

  Future<List<UserCircleCache>> sinkCacheWithoutMember(
      List<UserFurnace> userFurnaces, User member) async {
    List<UserCircleCache> retValue = [];

    ///debugPrint('start of sinkCache: ${DateTime.now()}');

    try {
      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!) {
          List<UserCircleCache> userCirclesCaches =
              await TableUserCircleCache.readAllForUserFurnace(
                  userFurnace.pk, userFurnace.userid);

          for (UserCircleCache userCircleCache in userCirclesCaches) {
            userCircleCache.furnaceObject = userFurnace;
          }

          retValue.addAll(userCirclesCaches);
        }
      }

      List<MemberCircle> memberCircles =
          await TableMemberCircle.getForCirclesAndMember(retValue, member.id!);

      for (MemberCircle memberCircle in memberCircles) {
        retValue
            .removeWhere((element) => element.circle == memberCircle.circleID);
      }

      if (retValue.isNotEmpty) {
        retValue.sort((a, b) => b.lastItemUpdate!.compareTo(a.lastItemUpdate!));
      }

      _userCircles.sink.add(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }

    return retValue;
  }

  Future<List<UserCircleCache>> sinkCache(List<UserFurnace> userFurnaces,
      {bool includeClosed = false}) async {
    List<UserCircleCache> retValue = [];

    try {
      //debugPrint('start of sinkCache: ${DateTime.now()}');

      ///There can't be that many, read all of them for this user, then filter by connected or not.

      List<String> userIDs = [];

      for (UserFurnace userFurnace in userFurnaces) {
        userIDs.add(userFurnace.userid!);
      }

      retValue = await TableUserCircleCache.readAllForUsers(userIDs);
      retValue.removeWhere((element) => element.circle == null);

      retValue.removeWhere(
          (element) => element.hidden == true && element.hiddenOpen == false);

      if (includeClosed == false) {
        retValue.removeWhere((element) => element.closed == true);
      }

      // for (UserFurnace userFurnace in userFurnaces) {
      //   if (userFurnace.connected!) {
      //     List<UserCircleCache> userCirclesCache = includeClosed
      //         ? await TableUserCircleCache.readAllForCM(
      //             userFurnace.pk, userFurnace.userid)
      //         : await TableUserCircleCache.readAllForUserFurnace(
      //             userFurnace.pk, userFurnace.userid);
      //
      //     //userCirclesCache.removeWhere((element) => element.circle == null);
      //
      //     retValue.addAll(userCirclesCache);
      //   }
      // }

      //debugPrint('fetch for sinkCache finished: ${DateTime.now()}');

      if (retValue.isNotEmpty) {
        //retValue.sort((a, b) => b.lastItemUpdate!.compareTo(a.lastItemUpdate!));

        ///remove just hid items that may refresh
        for (UserCircleCache userCircleCache in globalState.justHid) {
          retValue.removeWhere(
              (element) => element.usercircle == userCircleCache.usercircle);
        }
      }

      if (retValue.isNotEmpty && Platform.isIOS) {
        await globalState.setAppPath();

        String appPath = await globalState.getAppPath();

        if (appPath.isNotEmpty) {
          String circlePath = retValue.first.circlePath!;

          if (!circlePath.startsWith(appPath)) {
            for (UserCircleCache userCircleCache in retValue) {
              userCircleCache.circlePath =
                  await FileSystemService.returnCirclesDirectory(
                      userCircleCache.user!, userCircleCache.circle!);
            }

            await TableUserCircleCache.batchUpdateUserCircleCaches(retValue);

            LogBloc.insertLog('fixed paths', 'sinkCache');
          }
        }
      }

      _userCircles.sink.add(retValue);

      //debugPrint('end of sinkCache: ${DateTime.now()}');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.sinkCache: $err');
    }

    return retValue;
  }

  /*
  flipShowBadge(UserCircleCache userCircleCache) async {
    bool badge = true;
    if (userCircleCache.showBadge == true) {
      badge = false;
    }
    await TableUserCircleCache.flipShowBadge(
        userCircleCache.circle, userCircleCache.user, badge);
  }
   */

  turnOffBadge(UserCircleCache userCircleCache, DateTime lastObjectCreated,
      CircleObjectBloc circleObjectBloc) async {
    try {
      await circleObjectBloc.markReadForCircle(
          userCircleCache.circle!, lastObjectCreated);

      await TableUserCircleCache.flipShowBadge(
          userCircleCache.circle, userCircleCache.user, false);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.turnOffBadge: $err');
    }
  }

  setLastAccessed(UserFurnace userFurnace, UserCircleCache userCircleCache,
      DateTime accessed, CircleObjectBloc circleObjectBloc, bool updateServer) async {
    userCircleCache.lastLocalAccess = accessed;

    userCircleCache.showBadge = false;

    debugPrint('UserCircleBloc.markReadForCircle: started ${DateTime.now()}');

    await circleObjectBloc.markReadForCircle(userCircleCache.circle!, accessed);

    debugPrint('UserCircleBloc.markReadForCircle: ended ${DateTime.now()}');

    debugPrint(
        'UserCircleBloc.updateLastLocalAccess: started ${DateTime.now()}');

    ///CO-REMOVE
    await TableUserCircleCache.updateLastLocalAccess(userCircleCache.circle!,
        userCircleCache.user, userCircleCache.lastLocalAccess!);

    debugPrint('UserCircleBloc.updateLastLocalAccess: ended ${DateTime.now()}');

    if (updateServer) {
      ///update the server
      _userCircleService.setLastAccessed(userCircleCache, userFurnace);
    }

  }

  ///
  setLastAccessedLocalOnly(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      DateTime accessed,
      bool flipBadge) async {
    userCircleCache.lastItemUpdate = accessed;
    userCircleCache.lastLocalAccess = accessed;

    //if (flipBadge) {
    userCircleCache.showBadge = false;

    await TableUserCircleCache.updateLastItemUpdateAndBadge(
      userCircleCache.circle!,
      userCircleCache.user,
      userCircleCache.showBadge,
      userCircleCache.lastItemUpdate!,
    );
    /*} else {
      await TableUserCircleCache.updateLastItemUpdate(userCircleCache.circle!,
          userCircleCache.user, userCircleCache.lastItemUpdate!,
          setLastAccessed: true);
    }

    */

    //update the server
    //_userCircleService.setLastAccessed(userCircleCache, userFurnace);
  }

  _uploadBackground(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      File compressed,
      File encrypted,
      DecryptArguments args,
      String? oldBackground) async {
    /*  File background = await compressed.copy(
        FileSystemService.returnCircleBackgroundNewPath(
            userCircleCache.circlePath!, userCircleCache.usercircle!));
   */

    await _circleBackgroundService.uploadUserCircleBackground(userFurnace,
        userCircleCache, compressed, encrypted, args, oldBackground);
  }

  closeHidden(
      FirebaseBloc firebaseBloc, UserCircleCache userCircleCache) async {
    try {
      firebaseBloc.removeNotification();

      UserFurnace userFurnace =
          await TableUserFurnace.read(userCircleCache.userFurnace);

      ///close immediately
      userCircleCache.hiddenOpen = false;
      await TableUserCircleCache.closeHiddenCircle(userCircleCache.usercircle!);

      globalState.justHid.add(userCircleCache);

      _updateGlobalHidden(userCircleCache.user!);
      _updated.sink.add(userCircleCache);

      _userCircleService.hide(userFurnace, userCircleCache, true, '');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  _updateGlobalHidden(String userID) async {
    if (!await TableUserCircleCache.openClosedForUser(userID)) {
      globalState.hiddenOpen = false;
    }
  }

  hide(FirebaseBloc firebaseBloc, UserCircleCache userCircleCache, bool hide,
      String hiddenPassphrase) async {
    try {
      firebaseBloc.removeNotification();

      userCircleCache.hidden = true;
      userCircleCache.hiddenOpen = false;

      UserFurnace userFurnace =
          await TableUserFurnace.read(userCircleCache.userFurnace);

      await TableUserCircleCache.hideCircle(userCircleCache.usercircle!, hide);
      globalState.secureStorageService.writeKey(
          userCircleCache.usercircle! + KeyType.HIDDEN_PASSPHRASE,
          hiddenPassphrase);

      if (hide) {
        globalEventBloc.broadcastHideCircle(userCircleCache.usercircle!);

        globalState.justHid.add(userCircleCache);
        globalEventBloc.broadcastMemCacheCircleObjectsRemoveCircle(
            userCircleCache.circle!);
      } else {
        globalState.justHid
            .removeWhere((element) => element.pk == userCircleCache.pk);

        globalEventBloc
            .broadcastMemCacheCircleObjectsAddCircle(userCircleCache.circle!);
      }

      _updateGlobalHidden(userCircleCache.user!);

      _updated.sink.add(userCircleCache);

      //don't wait on this
      _userCircleService.hide(
          userFurnace, userCircleCache, hide, hiddenPassphrase);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  updatePrefName(UserFurnace? userFurnace, UserCircle? userCircle,
      UserCircleCache? userCircleCache) async {
    try {
      if (userCircle != null) {
        // if (userCircle.prefName != userCircleCache!.prefName) {
        // userCircle.prefName = await TableUserCircleCache.returnUniqueName(
        //    userFurnace!.pk!, userFurnace.userid!, userCircle.prefName!);
        userCircleCache!.prefName = userCircle.prefName;

        userCircle = await _userCircleService.updateEncryptedFields(
            userCircleCache, userFurnace!, null);
      }
      _updated.sink.add(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.updatePrefName: $err');
    }
  }

  updateColor(UserFurnace userFurnace, UserCircleCache userCircleCache,
      Color color) async {
    userCircleCache.backgroundColor = color;
    _userCircleService.updateColor(userCircleCache, userFurnace);
  }

  updateImage(UserFurnace? userFurnace, UserCircleCache? userCircleCache,
      File image) async {
    try {
      DecryptArguments? fullArgs;
      XFile? compressed;

      String? oldBackground = userCircleCache!.background;

      String newPath = FileSystemService.returnUserCircleBackgroundNewPath(
          userCircleCache.circlePath!);

      debugPrint(newPath);

      String thumbnail =
          await ImageCacheService.compressImage(image, newPath, 20);

      if (!File(thumbnail).existsSync()) throw ('image compression failed');

      fullArgs = await EncryptBlob.encryptBlob(thumbnail);

      UserCircle? userCircle = await _userCircleService.updateEncryptedFields(
          userCircleCache, userFurnace!, fullArgs);

      userCircleCache = await TableUserCircleCache.updateUserCircleCache(
          userCircle!, userFurnace);

      await _uploadBackground(userFurnace, userCircleCache!, File(thumbnail),
          fullArgs.encrypted, fullArgs, oldBackground);

      debugPrint(oldBackground);
      debugPrint(userCircleCache.background);
      _updatedImage.sink.add(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updatedImage.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  update(UserFurnace? userFurnace, UserCircle? userCircle,
      UserCircleCache? userCircleCache) async {
    try {
      userCircle = await _userCircleService.updateUserCircle(
          userCircle!, userCircleCache!, userFurnace!);

      userCircleCache = await TableUserCircleCache.updateUserCircleCache(
          userCircle!, userFurnace);

      _updated.sink.add(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  updateMutedNoFurnace(UserCircleCache userCircleCache, bool muted) async {
    UserFurnace userFurnace =
        await TableUserFurnace.read(userCircleCache.userFurnace);

    updateMuted(userFurnace, userCircleCache, muted);
  }

  updateMuted(UserFurnace userFurnace, UserCircleCache userCircleCache,
      bool muted) async {
    try {
      UserCircle? userCircle = await _userCircleService.updateMuted(
          userFurnace, userCircleCache, muted);

      if (userCircle != null) {
        UserCircleCache? updated =
            await TableUserCircleCache.updateUserCircleCache(
                userCircle, userFurnace);

        if (updated != null) _updated.sink.add(updated);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  updatePinned(UserCircleCache userCircleCache) async {
    try {
      bool result = await TableUserCircleCache.pinnedCircle(userCircleCache);
      if (result)
        _updated.sink.add(userCircleCache);
      else
        throw "unable to pin circle";
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
    }
  }

  updateClosed(UserCircleCache userCircleCache, bool closed) async {
    try {
      UserFurnace userFurnace =
          await TableUserFurnace.read(userCircleCache.userFurnace);

      UserCircle userCircle = await _userCircleService.updateClosed(
          userFurnace, userCircleCache, closed);

      UserCircleCache? updated =
          await TableUserCircleCache.updateUserCircleCache(
              userCircle, userFurnace);

      if (updated != null) _updated.sink.add(updated);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  unguard(UserFurnace? userFurnace, UserCircleCache userCircleCache) async {
    try {
      userFurnace ??= await TableUserFurnace.read(userCircleCache.userFurnace);

      userCircleCache.guarded = false;

      await _userCircleService.unguard(userCircleCache, userFurnace);

      await TableUserCircleCache.upsert(userCircleCache);

      globalEventBloc
          .broadcastMemCacheCircleObjectsAddCircle(userCircleCache.circle!);

      _updated.sink.add(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  setPin(UserFurnace? userFurnace, UserCircleCache userCircleCache,
      List<int> pin) async {
    try {
      userFurnace ??= await TableUserFurnace.read(userCircleCache.userFurnace);

      userCircleCache.guarded = true;

      UserCircle? userCircle =
          await _userCircleService.setPin(userCircleCache, userFurnace, pin);

      await TableUserCircleCache.guardCircle(
          userCircle!.id!, UserCircleCache.pinToString(pin), true);

      globalEventBloc
          .broadcastMemCacheCircleObjectsRemoveCircle(userCircleCache.circle!);

      _updated.sink.add(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _updated.sink.addError(err);
      debugPrint('UserCircleBloc.update: $err');
    }
  }

  fetchUserCircle(UserCircleCache userCircleCache) async {
    try {
      UserFurnace userFurnace =
          await TableUserFurnace.read(userCircleCache.userFurnace);

      UserCircle? retValue = await _userCircleService.fetchUserCircle(
          userCircleCache.circle!, userFurnace);

      _userCircle.sink.add(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.fetchUserCircle: $err');
    }
  }

  validateHiddenPassphrase(
      String hiddenPassphrase, List<UserFurnace> userFurnaces) async {
    try {
      List<UserCircleCache> userCircleCaches = [];

      for (UserFurnace userFurnace in userFurnaces) {
        try {
          if (userFurnace.connected!) {
            List<UserCircleCache>? furnaceResponse;
            furnaceResponse =
                await _validateHiddenPassphrase(hiddenPassphrase, userFurnace);

            if (furnaceResponse != null) {
              userCircleCaches.addAll(furnaceResponse);
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }

      if (userCircleCaches.isEmpty) {
        _hiddenCircles.sink.addError("no match");
      } else {
        _hiddenCircles.sink.add(userCircleCaches);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _hiddenCircles.sink.addError(err);
    }

    // _userCircle.sink.add(retValue);
  }

  validateHiddenPassphraseFurnace(
      String hiddenPassphrase, UserFurnace userFurnace) async {
    try {
      List<UserCircleCache>? furnaceResponse;

      if (userFurnace.connected!) {
        furnaceResponse =
            await _validateHiddenPassphrase(hiddenPassphrase, userFurnace);
      }

      if (furnaceResponse!.isEmpty) {
        _hiddenCircles.sink.addError("no match");
      } else {
        _hiddenCircles.sink.add(furnaceResponse);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.validateHiddenPassphraseFurnace: $err');
      _hiddenCircles.sink.addError(err);
    }

    // _userCircle.sink.add(retValue);
  }

  Future _validateHiddenServerSide(List<UserCircleCache> skipThese,
      String hiddenPassphrase, UserFurnace userFurnace) async {
    List<UserCircleCache> userCircleCaches = [];
    try {
      UserCircleCache? userCircleCache;

      debugPrint(' start of _validateHiddenServerSide ${DateTime.now()}');

      List<UserCircle>? userCircles = await _userCircleService
          .validateHiddenPassphrase(hiddenPassphrase, userFurnace);

      for (UserCircle userCircle in userCircles) {
        try {
          bool skip = false;

          for (UserCircleCache skipThis in skipThese) {
            if (skipThis.usercircle! == userCircle.id! &&
                skipThis.prefName != null &&
                skipThis.prefName!.isNotEmpty) {
              skip = true;
              break;
            }
          }

          if (skip) continue;

          debugPrint(' start of decrypt ${DateTime.now()}');

          await globalState.secureStorageService.writeKey(
              userCircle.id! + KeyType.HIDDEN_PASSPHRASE, hiddenPassphrase);

          RatchetKeyAndMap ratchetKeyAndMap =
              await ForwardSecrecyUser.decryptUserObject(
                  userCircle.ratchetIndex!, userCircle.user!.id!);

          Map<String, dynamic> map = ratchetKeyAndMap.map;

          ///TODO not sure wtf is going on here, the were added catches because the object contents have changed over time
          late UserCircleEnvelope userCircleEnvelope;

          if (map.containsKey("prefName")) {
            //Map<String, dynamic> contents = {'contents': map};

            userCircleEnvelope = UserCircleEnvelope(
                user: '',
                userCircle: '',
                contents: UserCircleEnvelopeContents.fromJson(map));
          } else {
            try {
              userCircleEnvelope = UserCircleEnvelope.fromJsonObject(map);
            } catch (err) {
              userCircleEnvelope = UserCircleEnvelope.fromJson(map);
            }
          }

          ///set the ids in the envelope
          userCircleEnvelope.user = userCircle.user!.id!;
          userCircleEnvelope.userCircle = userCircle.id!;

          userCircle.prefName = userCircleEnvelope.contents.prefName;

          await TableUserCircleCache.setName(
              userCircle.id!,
              //userCircleEnvelope.contents.circleName,
              userCircle.prefName!,
              userCircle.ratchetIndex!.crank,
              userFurnace.pk!);

          await TableUserCircleEnvelope.upsert(userCircleEnvelope);

          userCircleCache = await TableUserCircleCache.updateUserCircleCache(
              userCircle, userFurnace,
              hiddenOpen: true);

          TableCircleCache.upsert(userCircle.circle!, updateKey: true);

          if (userCircleCache != null) {
            userCircleCaches.add(userCircleCache);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }

        debugPrint(' end of for loop ${DateTime.now()}');
      }

      debugPrint(' end of _validateHiddenServerSide ${DateTime.now()}');
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleBloc._validateHiddenPassphrase: $error');
    }

    return userCircleCaches;
  }

  Future _validateHiddenPassphrase(
      String hiddenPassphrase, UserFurnace userFurnace) async {
    try {
      //UserCircleCache? userCircleCache;
      List<UserCircleCache> userCircleCaches = [];
      List<UserCircleCache> foundLocal = [];

      ///check local first
      List<UserCircleCache> localUserCircleCaches =
          await TableUserCircleCache.readHiddenForFurnace(
              userFurnace.pk, userFurnace.userid);

      for (UserCircleCache userCircleCache in localUserCircleCaches) {
        //debugPrint(
        //   'keyexists: ${userCircleCache.usercircle! + KeyType.HIDDEN_PASSPHRASE}');

        if (await globalState.secureStorageService.keyExists(
            userCircleCache.usercircle! + KeyType.HIDDEN_PASSPHRASE)) {
          String passphrase = await globalState.secureStorageService
              .readKey(userCircleCache.usercircle! + KeyType.HIDDEN_PASSPHRASE);

          if (passphrase == hiddenPassphrase) {
            foundLocal.add(userCircleCache);
          }
        }
      }

      if (foundLocal.isNotEmpty) {
        for (UserCircleCache userCircleCache in foundLocal) {
          UserCircleCache? updated =
              await TableUserCircleCache.updateUserCircleCacheByCache(
                  userCircleCache, userFurnace, true);

          if (updated != null) {
            userCircleCaches.add(updated);
          }

          globalState.justHid.removeWhere(
              (element) => element.usercircle == userCircleCache.usercircle);

          ///TODO update the passphrase on the server in case the circle was hidden in airplane mode
        }

        _userCircleService.setTempOpen(
            userFurnace, hiddenPassphrase, foundLocal);

        _validateHiddenServerSide(foundLocal, hiddenPassphrase, userFurnace);
      } else {
        userCircleCaches = await _validateHiddenServerSide(
            foundLocal, hiddenPassphrase, userFurnace);

        if (userCircleCaches.isNotEmpty) {
          for (UserCircleCache userCircleCache in userCircleCaches) {
            globalState.justHid.removeWhere(
                (element) => element.usercircle == userCircleCache.usercircle);
          }
        }
      }

      return userCircleCaches;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc._validateHiddenPassphrase: $err');
      return null;
    }
  }

  static Future<bool> closeHiddenCircles(FirebaseBloc firebaseBloc) async {
    bool retValue = false;

    try {
      firebaseBloc.removeNotification();

      UserCircleService userCircleService = UserCircleService();

      ///remove home filters
      globalState.circleTypeFilter = null;
      globalState.lastSelectedFilter = null;

      List<UserFurnace> userFurnaces =
          await TableUserFurnace.readAllForUser(globalState.user.id);

      retValue = await TableUserCircleCache.closeHiddenCircles();

      ///don't wait for these
      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!)

          ///async, don't wait
          userCircleService.closeOpenHidden(userFurnace);
      }

      //TODO airplane mode, retry until complete

      return true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.closeHiddenCircles: $err');
    }

    return retValue;
  }

  notifyWhenBackgroundReady(
      UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    String path = await _circleBackgroundService.makeCirclePath(
        userFurnace.userid, userCircleCache.circle);

    //debugPrint ('notifyWhenBackgroundReady: ${userCircleCache.prefName} + ${userCircleCache.masterBackground}');

    try {
      //debugPrint ('usercircle ${userCircleCache.usercircle}');
      //debugPrint ('${userCircleCache.usercircle} usercircle backgroundsize: ${userCircleCache.backgroundSize}');
      //debugPrint ('${userCircleCache.circle} circle backgroundsize: ${userCircleCache.backgroundSize}');

      if (userCircleCache.background != null) {
        path = join(path, userCircleCache.background!);

        if (FileSystemService.fileExists(path)) {
          File image = File(path);

          int length = await image.length();

          if (length == userCircleCache.backgroundSize ||
              userCircleCache.backgroundSize == 0) {
            _imageLoaded.sink.add(userCircleCache);
          } else {
            String success = await _circleBackgroundService
                .downloadUserCircleBackground(userFurnace, userCircleCache);

            //debugPrint('break');

            if (success.isNotEmpty) _imageLoaded.sink.add(userCircleCache);
          }
        } else {
          String success = await _circleBackgroundService
              .downloadUserCircleBackground(userFurnace, userCircleCache);

          //debugPrint('break');

          if (success.isNotEmpty) {
            _imageLoaded.sink.add(userCircleCache);
          }
        }
      } else if (userCircleCache.masterBackground != null) {
        path = join(path, userCircleCache.masterBackground!);

        if (FileSystemService.fileExists(path)) {
          File image = File(path);

          int length = await image.length();
          if (length == userCircleCache.masterBackgroundSize ||
              userCircleCache.masterBackgroundSize == 0) {
            _imageLoaded.sink.add(userCircleCache);
          }
        } else {
          // debugPrint('break');
          String success = await _circleBackgroundService
              .downloadCircleBackground(userFurnace, userCircleCache);

          if (success.isNotEmpty) {
            //debugPrint('FIRING THIS DOWNLOAD CIRCLE BACKGROUND');
            _imageLoaded.sink.add(userCircleCache);
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.notifyWhenBackgroundReady: $err');
    }
  }

  bool isBackgroundReady(
      UserFurnace userFurnace, UserCircleCache userCircleCache) {
    String? path = userCircleCache.circlePath;

    bool retValue = false;

    try {
      if (userCircleCache.background != null) {
        path = join(path!, userCircleCache.background!);

        if (FileSystemService.fileExists(path)) {
          File image = File(path);

          int length = image.lengthSync();

          if (length == userCircleCache.backgroundSize ||
              userCircleCache.backgroundSize == 0) {
            retValue = true;
          }
        }
      } else if (userCircleCache.masterBackground != null) {
        path = join(path!, userCircleCache.masterBackground!);

        if (FileSystemService.fileExists(path)) {
          File image = File(path);

          int length = image.lengthSync();

          if (length == userCircleCache.masterBackgroundSize ||
              userCircleCache.masterBackgroundSize == 0) {
            retValue = true;
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.isBackgroundReady: $err');
    }

    return retValue;
  }

  readHiddenAndClosedDMForFurnaces(List<UserFurnace> userFurnaces) async {
    try {
      List<UserCircleCache> userCircleCaches =
          await TableUserCircleCache.readHiddenAndClosedDMForFurnaces(
              userFurnaces);

      _hiddenAndClosed.sink.add(userCircleCaches);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  saveSwipePatternAttempt(UserFurnace? userFurnaceParam, String? circle) async {
    UserFurnace userFurnace;

    if (userFurnaceParam != null)
      userFurnace = userFurnaceParam;
    else
      userFurnace = await UserFurnaceBloc().getLatestUserFurnace();

    _userCircleService.saveSwipePatternAttempt(userFurnace, circle);
  }

  fetchPatternSwipeAttemptsList(User user, UserFurnace userFurnace) async {
    List<SwipePatternAttempt> retValue = [];

    try {
      List<SwipePatternAttempt>? swipePatternAttempts = await _userCircleService
          .fetchSwipePatternAttempts(userFurnace, user.id);

      List<UserCircleCache> userCircleCaches = [];
      if (swipePatternAttempts != null && swipePatternAttempts.isNotEmpty) {

        userCircleCaches = await TableUserCircleCache.readAll();

      }

      for (SwipePatternAttempt swipePatternAttempt in swipePatternAttempts!) {
        retValue.add(swipePatternAttempt);

        //set to "App" to start - null circleID means guarded item the main app
        swipePatternAttempt.guardedItemDisplayName = "App";

        if (swipePatternAttempt.circle != null) {
          //If this guardedItem is a DM
          if (swipePatternAttempt.circle!.dm) {
            Member member = Member(
                username: '(unknown)', alias: '', userID: '', memberID: '');

            List<MemberCircle> memberCircles =
                await TableMemberCircle.getForCircle(
                    userFurnace.userid!, swipePatternAttempt.circle!.id!);

            MemberCircle? memberCircle;

            ///there should only be one
            if (memberCircles.length == 1) {
              memberCircle = memberCircles.first;

              member = globalState.members.singleWhere(
                  (element) => element.memberID == memberCircle!.memberID,
                  orElse: () => Member(
                      username: '(unknown)',
                      alias: '',
                      userID: '',
                      memberID: ''));
            }

            swipePatternAttempt.guardedItemDisplayName =
                "DM: ${member.username}";
          } else if (!swipePatternAttempt.circle!.dm) {

            ///the name can only come from the usercircle
            UserCircleCache? userCircleCache = userCircleCaches.singleWhere(
                (element) => element.circle == swipePatternAttempt.circle!.id && element.user == user.id,
                orElse: () => UserCircleCache(
                    usercircle: '',
                    user: '',
                    circle: '',
                    prefName: '',
                    lastLocalAccess: DateTime.now(),
                    showBadge: false,
                    hidden: false,
                    hiddenOpen: false,
                    closed: false,
                    guarded: false,
                    backgroundColor: Colors.white,
                    background: '',
                    backgroundSize: 0,
                    masterBackground: '',
                    masterBackgroundSize: 0,
                    circlePath: '',
                    lastItemUpdate: DateTime.now()));

            //If this is a regular circle (not a DM)
            swipePatternAttempt.guardedItemDisplayName =
                "Circle: ${userCircleCache.prefName}";
          }
        }
      }

      retValue.sort((a, b) {
        return b.attemptDate.compareTo(a.attemptDate);
      });

      _swipePatternAttempts.sink.add(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.getMembershipList + $err');
      _swipePatternAttempts.sink.addError(err);
    }
  }

  /*
  loadBackground(UserCircleCache userCircleCache) async{
    return await _blobService.fetchUserCircleBackgroundFromCache(userCircleCache);
  }
  */

  dispose() async {
    //_movieId.close();
    await _userCircles.drain();
    _userCircles.close();

    await _userCirclesRefreshed.drain();
    _userCirclesRefreshed.close();

    await _userCircle.drain();
    _userCircle.close();

    await _updated.drain();
    _updated.close();

    await _hiddenCircles.drain();
    _hiddenCircles.close();

    await _imageLoaded.drain();
    _imageLoaded.close();

    await _leaveCircle.drain();
    _leaveCircle.close();

    await _userCirclesRefreshedSync.drain();
    _userCirclesRefreshedSync.close();

    await _swipePatternAttempts.drain();
    _swipePatternAttempts.close();

    await _hiddenAndClosed.drain();
    _hiddenAndClosed.close();
  }

  void processUserCircleObject(UserFurnace userFurnace, UserCircle userCircle,
      UserCircleCache userCircleCache, bool updateBackground, bool sync) async {
    try {
      if (userCircle.dm != null) {
        ///check to see if the user changed their name

        if (userCircle.dm!.username != userCircleCache.prefName) {
          userCircleCache.prefName = userCircle.dm!.username;

          await TableUserCircleCache.setName(
              userCircleCache.usercircle!,
              //userCircleEnvelope.contents.circleName,
              userCircle.dm!.username!,
              userCircle.ratchetIndex!.crank,
              userFurnace.pk!);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshCacheFromSingleFurnace: $err');
    }

    ///check to see if we need to decrypt the name
    if ((userCircleCache.prefName == null && userCircle.ratchetIndex != null) ||
        (userCircle.ratchetIndex != null &&
            userCircle.ratchetIndex!.crank != userCircleCache.crank)) {
      RatchetKeyAndMap ratchetKeyAndMap =
          await ForwardSecrecyUser.decryptUserObject(
              userCircle.ratchetIndex!, userCircleCache.user!);

      Map<String, dynamic> map = ratchetKeyAndMap.map;

      late UserCircleEnvelope userCircleEnvelope;

      if (map["contents"] == null) {
        //from a newly created UserCircle
        UserCircleEnvelopeContents userCircleEnvelopeContents =
            UserCircleEnvelopeContents.fromJson(map);

        userCircleEnvelope = UserCircleEnvelope(
            user: userFurnace.userid!,
            userCircle: userCircleCache.usercircle!,
            contents: userCircleEnvelopeContents);
      } else if (map["pk"] == null) {
        try {
          userCircleEnvelope = UserCircleEnvelope.fromJsonObject(map);
        } catch (err) {
          userCircleEnvelope = UserCircleEnvelope.fromJson(map);
        }

        ///from an invitation
        if (userCircleEnvelope.user.isEmpty) {
          //new invite
          userCircleEnvelope.user = userCircleCache.user!;
          userCircleEnvelope.userCircle = userCircleCache.usercircle!;
        }
      } else {
        ///from a cleared cache or a backup
        try {
          userCircleEnvelope = UserCircleEnvelope.fromJsonObject(map);
        } catch (err) {
          userCircleEnvelope = UserCircleEnvelope.fromJson(map);
        }
      }

      ///uncomment to guarantee unique usercircle name, seems overly complicated
      //userCircle.prefName = await TableUserCircleCache.returnUniqueName(userFurnace.pk!, userFurnace.userid!, userCircleEnvelope.contents.prefName);
      userCircle.prefName = userCircleEnvelope.contents.prefName;

      await TableUserCircleCache.setName(
          userCircleCache.usercircle!,
          //userCircleEnvelope.contents.circleName,
          userCircle.prefName!,
          userCircle.ratchetIndex!.crank,
          userFurnace.pk!);

      await TableUserCircleEnvelope.upsert(userCircleEnvelope);

      if (await RatchetKey.receiverKeysMissing(
          userFurnace.userid!, userCircle.id!)) {
        RatchetKey.ratchetReceiverKeyPair(userFurnace, userCircle.circle!.id!);
      }
    } else {
      if (userCircle.prefName != null) {
        //TODO this is for user pre 27 and for Me Circles, should pass Encrypted Me Circle name as part of registration
        UserCircleEnvelope userCircleEnvelope =
            await TableUserCircleEnvelope.get(
                userCircleCache.usercircle!, userCircleCache.user!);
        userCircleEnvelope.contents.prefName = userCircle.prefName!;
        userCircleEnvelope.contents.circleName = userCircle.circle!.name == null
            ? userCircle.prefName!
            : userCircle.circle!.name!;
        await TableUserCircleEnvelope.upsert(userCircleEnvelope); //async ok

        _userCircleService.updateEncryptedFields(
            userCircleCache, userFurnace, null);
      }
    }

    if (updateBackground)
      notifyWhenBackgroundReady(userFurnace, userCircleCache);

    if (sync) {
      ///used when logging into new device
      await _circleObjectBloc.initialLoad(
          userCircle.circle!.id!, userFurnace, userCircleCache, false,
          downloadImages: false);
    }
  }
}
