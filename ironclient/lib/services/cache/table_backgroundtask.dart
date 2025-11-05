import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableBackgroundTask {
  static const String tableName = 'backgroundtask';
  static const String pk = "pk";
  static const String taskID = "taskID";
  static const String networkID = "networkID";
  static const String circleID = "circleID";
  static const String userCircleID = "userCircleID";
  static const String userID = "userID";
  static const String seed = "seed";
  static const String type = "type";
  static const String status = "status";
  static const String path = "path";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$taskID TEXT UNIQUE,"
      "$networkID INT,"
      "$circleID TEXT,"
      "$userCircleID TEXT,"
      "$userID TEXT,"
      "$seed TEXT,"
      "$path TEXT,"
      "$type INT,"
      "$status INT)";

  static const List<String> _selectColumns = [
    pk,
    taskID,
    networkID,
    circleID,
    userCircleID,
    userID,
    seed,
    path,
    type,
    status
  ];

  static Database? _database;

  TableBackgroundTask._();

  static Future<void> upsert(BackgroundTask task) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $taskID = ?', [task.taskID]));

      if (count == 0) {
        await _database!.insert(tableName, task.toJson());
      } else {
        await _database!.update(tableName, task.toJson(),
            where: "$taskID = ?", whereArgs: [task.taskID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  // static Future<void> upsertReducedFields(Device device, var map) async {
  //   _database = await DatabaseProvider.db.database;
  //
  //   try {
  //     await _database!
  //         .update(tableName, map, where: "$uuid = ?", whereArgs: [device.uuid]);
  //
  //     return;
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint("TableUserFurnace.upsert: $err");
  //     rethrow;
  //   }
  // }

  static Future<int> deleteByTaskID(String pTaskID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$taskID = ?', whereArgs: [pTaskID]);
  }

  static Future<BackgroundTask> read(String pTaskID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _selectColumns,
        where: '$taskID = ?',
        whereArgs: [pTaskID],
        orderBy: pk);

    BackgroundTask backgroundTask = BackgroundTask();

    if (results.length > 1) {
      LogBloc.postLog('Multiple tasks with the same ID in SQLLite',
          'TableBackgroundTask.read');
    }

    for (var result in results) {
      backgroundTask = BackgroundTask.fromJson(result as Map<String, dynamic>);

      ///don't break, grab the last instead
      //break;
    }

    return backgroundTask;
  }
}
