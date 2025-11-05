import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableDeleteIDTracker {
  static const String tableName = 'deleteidtracker';
  static const String pk = "pk";
  static const String id = "id";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT UNIQUE)";

  static Database? _database;

  TableDeleteIDTracker._();

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> exists(String pID) async {
    _database = await DatabaseProvider.db.database;

    var count = Sqflite.firstIntValue(await _database!
        .rawQuery('SELECT COUNT(*) FROM $tableName WHERE $id = ?', [pID]));

    return count ?? 0;
  }

  static upsert(String pID) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = await exists(pID);

      if (count != 0) {
        Map<String, dynamic> map = {id: pID};

        await _database!.insert(tableName, map);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableDeleteIDTracker.upsert: $err");
      //rethrow;
    }
  }
}
