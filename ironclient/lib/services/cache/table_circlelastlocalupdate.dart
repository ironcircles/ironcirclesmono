import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableCircleLastLocalUpdate {
  static const String tableName = 'circlelastupdate';
  static const String pk = "pk";
  static const String circleID = "circleID";
  static const String lastFetched = "lastFetched";

  //static final String jwt= "token";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$circleID TEXT,"
      "$lastFetched INT)";

  static Database? _database;

  TableCircleLastLocalUpdate._();

  static Future<CircleLastLocalUpdate> upsert(
      CircleLastLocalUpdate circleLastLocalUpdate) async {
    _database = await DatabaseProvider.db.database;

    try {
      int? count = 0;

      if (circleLastLocalUpdate.pk != null) {
        count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $pk = ?',
            [circleLastLocalUpdate.pk]));
      }

      if (count == 0) {
        await _database!.insert(tableName, circleLastLocalUpdate.toJson());
      } else {
        await _database!.update(tableName, circleLastLocalUpdate.toJson(),
            where: "$pk = ?", whereArgs: [circleLastLocalUpdate.pk]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleLastLocalUpdate.upsert: $err");
      rethrow;
    }

    return circleLastLocalUpdate;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> delete(String pCircle) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$circleID = ?', whereArgs: [pCircle]);
  }

  static Future<CircleLastLocalUpdate?> read(String pCircle) async {
    CircleLastLocalUpdate? retValue;
    try {
      _database = await DatabaseProvider.db.database;

      //debugPrint(pCircle);

      List<Map> results = await _database!.query(tableName,
          columns: [pk, circleID, lastFetched],
          where: "$circleID = ?",
          whereArgs: [pCircle]);
      //orderBy: "$lastItemUpdate DESC");

      if (results.isNotEmpty) {
        retValue = CircleLastLocalUpdate.fromJson(
            results.first as Map<String, dynamic>);

        //debugPrint('break');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleLastLocalUpdate.read: $err");
      rethrow;
    }

    //debugPrint('break');
    return retValue;
  }

  static Future<List<CircleLastLocalUpdate>> readAll() async {
    List<CircleLastLocalUpdate> retValue = [];
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(
        tableName,
        columns: [pk, circleID, lastFetched],
      );

      if (results.isNotEmpty) {
        //retValue = Circle.fromJsonSQL(results.first as Map<String, dynamic>);
        results.forEach((result) {
          CircleLastLocalUpdate circleLastLocalUpdate =
              CircleLastLocalUpdate.fromJson(result as Map<String, dynamic>);
          retValue.add(circleLastLocalUpdate);
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleLastLocalUpdate.readAll: $err");
      rethrow;
    }

    return retValue;
  }
}
