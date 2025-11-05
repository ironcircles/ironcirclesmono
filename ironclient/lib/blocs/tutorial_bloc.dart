import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/tutorial.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/tutorial_service.dart';
import 'package:rxdart/rxdart.dart';

class TutorialBloc {
  TutorialService _tutorialService = TutorialService();

  final _tutorialsLoaded = PublishSubject<List<Topic>>();
  Stream<List<Topic>> get tutorialsLoaded => _tutorialsLoaded.stream;

  get(UserFurnace userFurnace) async {
    try {
      List<Topic> retValue = await _tutorialService.get(userFurnace);

      _tutorialsLoaded.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('TutorialBloc.get + $error');
      _tutorialsLoaded.sink.addError(error);
    }
  }

  generateContent(UserFurnace userFurnace) async {
    try {
      List<Topic> retValue = await _tutorialService.generateContent(userFurnace);
      _tutorialsLoaded.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('TutorialBloc.get + $error');
      _tutorialsLoaded.sink.addError(error);
    }
  }


  dispose() async {
    await _tutorialsLoaded.drain();
    _tutorialsLoaded.close();
  }
}
