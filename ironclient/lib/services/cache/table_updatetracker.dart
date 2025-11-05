import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableUpdateTracker {
  static const String tableName = 'updatetracker';
  static const String pk = "pk";
  static const String type = "type";
  static const String value = "value";

  static const List<String> selectColumns = [
    pk,
    type,
    value,
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$type INT,"
      "$value INT)";

  static Database? _database;

  TableUpdateTracker._();

  static Future<void> upsert(
      UpdateTrackerType updateTrackerType, bool status) async {
    _database = await DatabaseProvider.db.database;

    try {
      UpdateTracker updateTracker = UpdateTracker(
        type: updateTrackerType,
        value: status,
      );

      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $type = ?',
          [updateTracker.type.index]));

      if (count == 0)
        await _database!.insert(tableName, updateTracker.toJson());
      else {
        await _database!.update(tableName, updateTracker.toJson(),
            where: "$type = ?", whereArgs: [updateTracker.type.index]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<UpdateTracker> read(UpdateTrackerType updateTrackerType) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: "$type = ?",
        whereArgs: [updateTrackerType.index],
        limit: 1);

    if (results.isNotEmpty) {
      UpdateTracker retValue =
          UpdateTracker.fromJson(results.first as Map<String, dynamic>);

      return retValue;
    } else {
      return UpdateTracker(
        type: updateTrackerType,
        value: false,
      );
    }
  }
}
