import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/circlelist_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class CircleListBloc {
  final CircleListService _listService = CircleListService();
  final CircleObjectService _circleObjectService = CircleObjectService();

  final _created = PublishSubject<CircleObject>();
  Stream<CircleObject> get created => _created.stream;

  final _updated = PublishSubject<CircleObject>();
  Stream<CircleObject> get updated => _updated.stream;

  final _taskChangeSubmitted = PublishSubject<CircleObject>();
  Stream<CircleObject> get taskChangeSubmitted => _taskChangeSubmitted.stream;

  createList(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      bool? saveList,
      UserFurnace userFurnace,
      GlobalEventBloc globalEventBloc) async {
    try {
      //generate seeds for the circletasks
      for (CircleListTask item in circleObject.list!.tasks!) {
        item.seed = const Uuid().v4();
      }

      circleObject = await _circleObjectService.cacheCircleObject(circleObject);
      if (circleObject.timer != null) {
        globalEventBloc.startTimer(circleObject.timer!, circleObject);
      }

      if (circleObject.timer != null) {
        globalEventBloc.startTimer(circleObject.timer!, circleObject);
      }
      _created.sink.add(circleObject);

      circleObject = await _listService.createList(
          userCircleCache, circleObject, saveList, userFurnace);

      _created.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListBloc.createList: $err');
      _created.sink.addError(err);
    }
  }

  updateList(UserCircleCache userCircleCache, CircleObject circleObject,
      CircleList circleList, bool saveList, UserFurnace userFurnace) async {
    try {
      //update the order field
      // debugPrint('Bloc a: ${circleList.lastUpdate}');
      //update the object from the deepcopy

      circleObject.list!.ingestDeepCopy(circleList);

      for (CircleListTask item in circleObject.list!.tasks!) {
        item.seed ??= const Uuid().v4();
      }

      circleObject = await _listService.updateList(
          userCircleCache, circleObject, saveList, userFurnace);

      debugPrint('raising updated event at ${DateTime.now()}');

      _updated.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListBloc.updateList: $err');
      _updated.sink.addError(err);
    }
  }

  /*submitTaskChanged(UserCircleCache userCircleCache, CircleObject circleObject,
      List<CircleListTask> tasks, UserFurnace userFurnace) async {
    try {
      CircleObject result = await _listService.submitTaskChange(
          userCircleCache, circleObject, tasks, userFurnace);

      //cache the result
     // await TableCircleObjectCache.updateCacheSingleObject(result);

      _taskChangeSubmitted.sink.add(result);

      //_created.sink.add(true);
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('$err');
      _created.sink.addError(err);
    }
  }

   */

  dispose() async {
    await _created.drain();
    _created.close();

    await _taskChangeSubmitted.drain();
    _taskChangeSubmitted.close();

    await _updated.drain();
    _updated.close();
  }
}
