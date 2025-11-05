import 'dart:async';

import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/backlog.dart';
import 'package:ironcirclesapp/models/backlogreply.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/backlog_service.dart';
import 'package:rxdart/rxdart.dart';

class BacklogBloc {
  final BacklogService _service = BacklogService();

  final _backlogLoaded = PublishSubject<List<Backlog>>();
  Stream<List<Backlog>> get backlogLoaded => _backlogLoaded.stream;

  final _backlogAdded = PublishSubject<Backlog>();
  Stream<Backlog> get backlogAdded => _backlogAdded.stream;

  final _backlogReply= PublishSubject<BacklogReply>();
  Stream<BacklogReply> get backlogReply => _backlogReply.stream;

  _fetch(UserFurnace userFurnace) async {
    List<Backlog> retValue = await _service.get(userFurnace);

    //retValue.sort((a, b) => b.upVotesCount!.compareTo(a.upVotesCount!));

    for (Backlog backlog in retValue) {
      if (backlog.creator!.id! == userFurnace.userid) {
        backlog.voteLabel = '';
      } else {
        int index = backlog.upVotes!
            .indexWhere((element) => element.id == userFurnace.userid);

        if (index == -1)
          backlog.voteLabel = 'upvote';
        else
          backlog.voteLabel = 'downvote';
      }
    }

    _backlogLoaded.sink.add(retValue);
  }

  get(UserFurnace userFurnace) async {
    try {
      _fetch(userFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('BacklogBloc.get + $error');
      _backlogLoaded.sink.addError(error);
    }
  }

  vote(UserFurnace userFurnace, Backlog backlog) async {
    try {
      await _service.vote(userFurnace, backlog);

      _fetch(userFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('BacklogBloc.vote + $error');
      _backlogLoaded.sink.addError(error);
    }
  }

  post(UserFurnace userFurnace, Backlog backlog) async {
    try {
      backlog = await _service.post(userFurnace, backlog);

      _backlogAdded.sink.add(backlog);

      //_backlogLoaded.sink.add(retValue);
      get(userFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('BacklogBloc.post + $error');
      _backlogAdded.sink.addError(error);
    }
  }

  reply(UserFurnace userFurnace, Backlog backlog, BacklogReply reply) async {
    try {
      reply = await _service.reply(userFurnace, backlog, reply);

      _backlogReply.sink.add(reply);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('BacklogBloc.post + $error');
      _backlogReply.sink.addError(error);
    }
  }


  dispose() async {
    await _backlogLoaded.drain();
    _backlogLoaded.close();

    await _backlogAdded.drain();
    _backlogAdded.close();

    await _backlogReply.drain();
    _backlogReply.close();
  }
}
