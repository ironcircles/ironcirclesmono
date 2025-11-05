import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/notificationtracker.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableNotificationTracker {
  static const String tableName = 'notificationtracker';
  static const String pk = "pk";
  static const String id = "id";
  static const String loggedDate = "loggedDate";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$loggedDate INT, "
      "$id TEXT UNIQUE)";

  static Database? _database;

  TableNotificationTracker._();

  static Future<void> upsert(NotificationTracker notificationTracker) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?',
          [notificationTracker.id]));

      if (count == 0) {
        await _database!.insert(tableName, notificationTracker.toJson());
      } else {
        Map<String, dynamic> map = notificationTracker.toJson();

        await _database!.update(tableName, map,
            where: "$id = ?", whereArgs: [notificationTracker.id]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableNotificationTracker.upsert: $err");
      throw (err);
    }

    return;
  }

  /*
  static Future<int> deleteByActionType(String pUserID, int pAlertType) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database.delete(tableName,
        where: '$user = ? AND $alertType = ?',
        whereArgs: [pUserID, pAlertType]);

    return records;
  }

   */

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<bool> exists(String? notificationID) async {
    _database = await DatabaseProvider.db.database;

    bool retValue = false;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?', [notificationID]))!;

      if (count > 0) retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableActionRequiredCache.upsert: $err");
      throw (err);
    }

    return retValue;
  }
}
