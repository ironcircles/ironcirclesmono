import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/circlevote_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class CircleVoteBloc {
  final _voteService = VoteService();

  final _created = PublishSubject<CircleObject>();
  Stream<CircleObject> get createdResponse => _created.stream;

  final _submitVote = PublishSubject<CircleObject>();
  Stream<CircleObject> get submitVoteResults => _submitVote.stream;

  createVote(
      UserCircleCache userCircleCache,
      CircleVote circleVote,
      UserFurnace userFurnace,
      int? timer,
      DateTime? scheduledFor,
      Circle circle,
      int? increment) async {
    try {
      ///add to the screen immediately
      CircleObject sinkValue = CircleObject.prepNewCircleObject(
          userCircleCache, userFurnace, '', 0, null, type: CircleObjectType.CIRCLEVOTE);
      //sinkValue.type = CircleObjectType.CIRCLEVOTE;
      sinkValue.vote = circleVote;
      sinkValue.vote!.open = true;
      sinkValue.seed = const Uuid().v4();
      _created.sink.add(sinkValue);

      CircleObject circleObject = await _voteService.createUserVote(
          userCircleCache,
          circleVote,
          userFurnace,
          timer,
          scheduledFor,
          increment,
          sinkValue.seed!);

      circleObject.created = circleObject.lastUpdate;
      circleObject.circle = circle;
      circleObject.dateIncrement = increment;
      circleObject.scheduledFor = scheduledFor;

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      TableUserCircleCache.updateLastItemUpdate(circleObject.circle!.id,
          circleObject.creator!.id, circleObject.lastUpdate);

      _created.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVoteBloc.createVote: $err');
      _created.sink.addError(err);
    }
  }

  submitVote(UserCircleCache userCircleCache, CircleObject circleObject,
      CircleVoteOption selectedOption, UserFurnace userFurnace) async {
    try {
      CircleObject result = await _voteService.submitVote(
          userCircleCache, circleObject, selectedOption, userFurnace);

      if (result.circle != null) {
        result.created = result.lastUpdate;

        //cache the result
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, result);

        TableUserCircleCache.updateLastItemUpdate(
            result.circle!.id, result.creator!.id, result.lastUpdate);
      }

      _submitVote.sink.add(result);

      //_created.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('$err');
      _submitVote.sink.addError(err);
    }
  }

  dispose() async {
    await _created.drain();
    _created.close();

    await _submitVote.drain();
    _submitVote.close();
  }
}
