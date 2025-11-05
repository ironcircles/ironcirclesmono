import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableDevice {
  static const String tableName = 'device';
  static const String pk = "pk";
  static const String uuid = "uuid";
  static const String manufacturerID = "manufacturerID";
  static const String pushToken = "pushToken";
  static const String kyberSharedSecret = "kyberSharedSecret";
  //static const String lastIncremental = "lastIncremental";
  //static const String lastFull = "lastFull";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$uuid TEXT UNIQUE,"
      "$manufacturerID TEXT,"
      "$kyberSharedSecret TEXT,"
      // "$lastIncremental INT,"
      // "$lastFull INT,"
      "$pushToken TEXT)";

  static const List<String> _selectColumns = [
    pk,
    uuid,
    manufacturerID,
    pushToken,
    kyberSharedSecret,
    //lastIncremental,
    //lastFull
  ];

  static Database? _database;

  TableDevice._();

  static Future<void> upsert(Device device) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $uuid = ?', [device.uuid]));

      if (count == 0) {
        await _database!.insert(tableName, device.toJsonSQL());
      } else {
        await _database!.update(tableName, device.toJsonSQL(),
            where: "$uuid = ?", whereArgs: [device.uuid]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  static Future<void> upsertReducedFields(Device device, var map) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!
          .update(tableName, map, where: "$uuid = ?", whereArgs: [device.uuid]);

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  static Future<Device> read() async {
    _database = await DatabaseProvider.db.database;

    List<Map> results =
        await _database!.query(tableName, columns: _selectColumns, orderBy: pk);

    Device device = Device();

    if (results.length > 1) {
      LogBloc.postLog('Multiple devices in SQLLite', 'TableDevice.read');
    }

    for (var result in results) {
      device = Device.fromJsonSQL(result as Map<String, dynamic>);

      ///don't break, grab the last instead
      //break;
    }

    return device;
  }
}
