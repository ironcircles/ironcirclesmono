import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/circleevent_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:rxdart/rxdart.dart';

class CircleEventBloc {
  final CircleEventService _service = CircleEventService();
  final CircleObjectService _circleObjectService = CircleObjectService();

  final _scheduledEvents = PublishSubject<List<CircleObject>>();
  Stream<List<CircleObject>> get scheduledEvents => _scheduledEvents.stream;

  /*final _created = PublishSubject<CircleObject>();
  Stream<CircleObject> get created => _created.stream;

  final _cached = PublishSubject<CircleObject>();
  Stream<CircleObject> get cached => _cached.stream;

  final _updated = PublishSubject<CircleObject>();
  Stream<CircleObject> get updated => _updated.stream;

   */

  /// Sink top 5000 from cache
  void readEventsFromCache(GlobalEventBloc globalEventBloc, List<UserFurnace> userFurnaces, UserCircleCache? userCircleCache) async {
    // DateTime retValue;

    try {
      List<UserCircleCache> userCircles = [];
      //List<CircleObjectCache> sinkList = [];
      List<CircleObject> retValue = [];
      List<String> circles = [];

      //grab a list of locally cached circles for this user
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<UserCircleCache> furnaceCircles =
            await TableUserCircleCache.readAllForLibrary(
                userFurnace.pk, userFurnace.userid, userCircleCache: userCircleCache );

        for (UserCircleCache userCircleCache in furnaceCircles) {
          //add the hitchhiker
          userCircleCache.furnaceObject = userFurnace;

          circles.add(userCircleCache.circle!);
        }

        userCircles.addAll(furnaceCircles);
      }

      List<Map> results = await TableCircleObjectCache.readTypeByCircles(
          circles, CircleObjectType.CIRCLEEVENT);

      for (var result in results) {
        Map<String, dynamic> decode = json.decode(result["circleObjectJson"]);

        CircleObject circleObject = CircleObject.fromJson(decode);

        //check Timer
        if (circleObject.timer != null) {
          if (circleObject.timerExpires != null) {
            if (circleObject.timerExpires!.compareTo(DateTime.now()) < 0) {
              //timer expired.  Don't add this object.  Delete

              TableCircleObjectCache.delete(circleObject.id!);
              globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
              continue;
            }
          }
        }

        if (circleObject.oneTimeView == true) continue;

        //find the right hitchhikers
        UserCircleCache userCircleCache = userCircles.singleWhere(
            (element) => element.circle == circleObject.circle!.id!);

        //add the hitchikers
        circleObject.userCircleCache = userCircleCache;
        circleObject.userFurnace = userFurnaces
            .firstWhere((element) => element.pk == userCircleCache.userFurnace);

        retValue.add(circleObject);
      }

      retValue.sort((a, b) {
        return a.event!.startDate.compareTo(b.event!.startDate);
      });

      _scheduledEvents.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('LibraryBloc._sinkCache: $error');
      throw (error);
    }
  }

  createEvent(
      CircleObjectBloc circleObjectBloc,
      UserCircleCache userCircleCache,
      CircleEvent circleEvent,
      UserFurnace userFurnace,
      GlobalEventBloc globalEventBloc,
      CircleObject? replyObject,
      int? increment,
      DateTime? scheduledFor) async {
    CircleObject circleObject = CircleObject(ratchetIndexes: []);
    try {
      circleObject = CircleObject.prepNewCircleObject(
          userCircleCache, userFurnace, '', 0, replyObject, type: CircleObjectType.CIRCLEEVENT);

      //circleObject.type = CircleObjectType.CIRCLEEVENT;
      circleObject.event = circleEvent;
      circleObject.dateIncrement = increment;
      circleObject.scheduledFor = scheduledFor;

      circleObject = await _circleObjectService.cacheCircleObject(circleObject);
      if (circleObject.timer != null) {
        globalEventBloc.startTimer(circleObject.timer!, circleObject);
      }

      circleObjectBloc.sinkCircleObjectSave(circleObject);

      circleObject = await _service.createEvent(
          userCircleCache, circleObject, userFurnace, globalEventBloc);

      circleObjectBloc.sinkCircleObjectSave(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEventBloc.createEvent: $err');
      circleObjectBloc.sinkCircleObjectSaveError(
          SaveError(circleObject: circleObject, errorMessage: err.toString()));
    }
  }

  updateEvent(
      CircleObjectBloc circleObjectBloc,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      //CircleList circleList,
      UserFurnace userFurnace) async {
    try {
      circleObject.updating = true;
      circleObject = await _circleObjectService.cacheCircleObject(circleObject);

      circleObjectBloc.sinkCircleObjectSave(circleObject);

      circleObject = await _service.updateEvent(
          userCircleCache, circleObject, userFurnace);

      circleObject.updating = false;

      circleObjectBloc.sinkCircleObjectSave(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEventBloc.updateEvent: $err');
      circleObjectBloc.sinkCircleObjectSaveError(
          SaveError(circleObject: circleObject, errorMessage: err.toString()));
    }
  }

  dispose() async {
    await _scheduledEvents.drain();
    _scheduledEvents.close();
    /*
    await _cached.drain();
    _cached.close();

    await _updated.drain();
    _updated.close();

    */
  }
}
