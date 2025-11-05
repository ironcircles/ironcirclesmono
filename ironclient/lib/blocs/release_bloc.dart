import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/release.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/release_service.dart';
import 'package:rxdart/rxdart.dart';

class ReleaseBloc {
  ReleaseService _releaseService = ReleaseService();

  final _releasesLoaded = PublishSubject<List<Release>>();
  Stream<List<Release>> get releasesLoaded => _releasesLoaded.stream;

  get(UserFurnace userFurnace) async {
    try {
      List<Release> retValue = await _releaseService.get(userFurnace);

      _releasesLoaded.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('ReleaseBloc.get + $error');
      _releasesLoaded.sink.addError(error);
    }
  }

  dispose() async {
    await _releasesLoaded.drain();
    _releasesLoaded.close();
  }
}
