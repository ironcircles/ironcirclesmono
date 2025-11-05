import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/membercircles_service.dart';
import 'package:rxdart/rxdart.dart';

class MemberCircleBloc {
  final _loaded = PublishSubject<List<MemberCircle>>();
  Stream<List<MemberCircle>> get loaded => _loaded.stream;

  getForCircles(List<UserCircleCache> userCircleCaches) async {
    try {
      _loaded.sink
          .add(await MemberCircleService.getForCircles(userCircleCaches));
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberCircleBloc.getForCircles + $err');
      _loaded.sink.addError(err);
    }
  }

  Future<MemberCircle?> getDM(String userID, String memberID) async {
    try {
      return await TableMemberCircle.getDM(userID, memberID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberCircleBloc.getDM + $err');
      rethrow;
    }
  }

  dispose() async {
    await _loaded.drain();
    _loaded.close();
  }
}
