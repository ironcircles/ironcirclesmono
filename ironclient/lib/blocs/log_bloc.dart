import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_log.dart';
import 'package:ironcirclesapp/services/log_service.dart';
import 'package:ironcirclesapp/services/logdetailservice.dart';
import 'package:rxdart/rxdart.dart';

class LogBloc {
  final _fetchLogs = PublishSubject<List<Log>>();
  Stream<List<Log>> get fetchLogs => _fetchLogs.stream;

  final _toggleSuccess = PublishSubject<bool>();
  Stream<bool> get toggleSuccess => _toggleSuccess.stream;

  final _detailedBackupFinished = PublishSubject<bool>();
  Stream<bool> get detailedBackupFinished => _detailedBackupFinished.stream;

  toggle(UserFurnace userFurnace, bool submitLogs) async {
    try {
      await LogService.toggle(userFurnace, submitLogs);

      _toggleSuccess.sink.add(submitLogs);

      if (submitLogs) post(userFurnace);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeychainBackupBloc.toggle: $err');
      _toggleSuccess.sink.addError(err);
    }
  }

  fetchRecent() async {
    try {
      List<Log> logs = await TableLog.readAmount(2500);

      _fetchLogs.sink.add(logs);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      // debugPrint('LoggerBloc.fetchRecent + $error');
      _fetchLogs.sink.addError(error);
    }
  }

  sendDetailedLog(UserFurnace userFurnace, User user,
      GlobalEventBloc globalEventBloc) async {
    try {
      LogDetailService.sendDetailedLog(userFurnace, user, globalEventBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  static Future<bool> post(UserFurnace userFurnace) async {
    try {
      DateTime lastSubmissionDate =
          DateTime.parse('20200101'); //Beginning of IC time

      DateTime? lastSubmission = globalState.userSetting.lastLogSubmission;

      if (lastSubmission != null) {
        lastSubmissionDate = lastSubmission;
      }
      List<Log> logs =
          await TableLog.readSinceLastSubmission(lastSubmissionDate);

      bool success = await LogService.post(userFurnace, logs);

      if (success) {
        globalState.userSetting.setLastLogSubmission(DateTime.now());
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return false;
  }

  static insertError(Object error, StackTrace trace,
      {String source = ''}) async {
    try {
      debugPrint('$error');
      debugPrint(trace.toString());

      late String stackTrace;

      if (kReleaseMode) {
        ///Log the stack trace if the user is an admin
        if (globalState.user.id != null &&
            globalState.user.role == Role.IC_ADMIN) {
          if (source.isEmpty)
            stackTrace = trace.toString();
          else
            stackTrace = '$source: ${trace.toString()}';
        } else {
          if (globalState.user.id == null) {
            insertLog('globalState.user.id is null', 'insertError');
          }

          if (source.isEmpty)
            stackTrace = 'obfuscated';
          else
            stackTrace = source;
        }
      } else if (source.isEmpty)
        stackTrace = trace.toString();
      else
        stackTrace = "$source: $trace";

      Device device = await globalState.getDevice();

      TableLog.insert(Log(
          device: device.uuid,
          user: globalState.user.id,
          message: error.toString(),
          stack: stackTrace,
          timeStamp: DateTime.now()));
    } catch (error) {
      debugPrint('Log.insertError + $error');
    }
  }

  static deleteAll() async {
    try {
      TableLog.deleteAll();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('Log.insertLog + $error');
    }
  }

  static deleteOlderThanThirty() async {
    try {
      TableLog.deleteOlderThan30Days();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('Log.insertLog + $error');
    }
  }

  static insertLog(String message, String source) async {
    try {
      Device device = await globalState.getDevice();

      TableLog.insert(Log(
          device: device.uuid,
          type: 'log',
          user: globalState.user.id,
          message: message,
          stack: source,
          timeStamp: DateTime.now()));

      debugPrint('$message\n$source');
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('Log.insertLog + $error');
    }
  }

  static postLog(String message, String source) async {
    try {
      debugPrint('message: $message\nsource:$source');

      Device device = await globalState.getDevice();

      Log log = Log(
          device: device.uuid,
          type: 'log',
          //user: globalState.user.id,
          message: message,
          stack: source,
          timeStamp: DateTime.now());

      TableLog.insert(log);
      LogService.postToForge([log]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint('Log.insertLog + $error');
    }
  }

  dispose() async {
    await _fetchLogs.drain();
    _fetchLogs.close();

    await _toggleSuccess.drain();
    _toggleSuccess.close();
  }
}
