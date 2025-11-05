import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableMemberDevice {
  static const String tableName = 'memberdevice';
  static const String pk = "pk";
  static const String ownerID = "ownerID";
  static const String userID = "userID";
  static const String identity = "identity";
  static const String uuid = "uuid";
  static const String platform = "platform";
  static const String manufacturer = "manufacturer";
  static const String model = "model";
  static const String build = "build";
  static const String name = "name";
  static const String warningShown = "warningShown";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$ownerID TEXT,"
      "$name TEXT,"
      "$userID TEXT,"
      "$manufacturer TEXT,"
      "$platform TEXT,"
      "$model TEXT,"
      "$build TEXT,"
      "$warningShown BIT,"
      "$uuid TEXT,"
      "$identity TEXT,"
      "UNIQUE($ownerID,$uuid, $userID))";
  //" UNIQUE($memberID,$circleID))";

  static final List<String> _selectColumns = [
    pk,
    ownerID,
    userID,
    identity,
    uuid,
    model,
    build,
    warningShown,
    platform,
    manufacturer,
    name,
  ];

  static Database? _database;

  TableMemberDevice._();

  static Future<void> upsertCollection(String pUserID, List<User> users) async {
    _database = await DatabaseProvider.db.database;

    try {
      var batch = _database!.batch();

      ///if it is the first time inserting, we don't want to show the warning
      List<Device> devices = await getAll(pUserID);

      for (User user in users) {
        if (user.devices == null) continue;

        List<dynamic> jsonDevices = json.decode(user.devices!);

        for (var jsonDevice in jsonDevices) {
          Device device = Device.fromMemberJson(jsonDevice);

          if (device.identity != null && device.identity!.isNotEmpty) {
            device.ownerID = user.id;
            device.userID = pUserID;
            if (globalState.importing || devices.isEmpty)
              device.warningShown = true;

            if (devices.indexWhere((element) =>
                    element.ownerID == device.ownerID &&
                    element.uuid == device.uuid &&
                    element.userID == device.userID) ==
                -1) {
              batch.insert(tableName, device.toMemberJsonSQL());
            }
          }
        }
      }

      await batch.commit(noResult: true, continueOnError: true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return;
  }

  static Future<void> setWarningShown(Device device) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        warningShown: 1,
      };

      await _database!.update(tableName, map,
          where: "$uuid = ? AND $ownerID = ?",
          whereArgs: [device.uuid, device.ownerID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  /*
  ///There should only be inserts, no updates
  static Future<void> insert(String pMemberID, Device device) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $ownerID = ? AND $uuid == ?',
          [pMemberID, device.uuid]));

      device.ownerID = pMemberID;

      if (count == 0) {
        await _database!.insert(tableName, device.toMemberJsonSQL());
      } else {
        debugPrint('Device already exists');
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return;
  }

   */

  static Future<int> deleteAllForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$userID = ?', whereArgs: [pUserID]);
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<List<Device>> getAll(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Device> retValue = [];

    List<Map> results = await _database!.query(
      tableName,
      columns: _selectColumns,
      where: "$userID = ?",
      whereArgs: [pUserID],
    ); //,

    if (results.isNotEmpty) {
      for (var result in results) {
        Device device = Device.fromMemberJson(result as Map<String, dynamic>);

        retValue.add(device);
      }
    }

    return retValue;
  }

  static Future<Device?> getDeviceDM(String pOwnerID, String pUuid) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _selectColumns,
        where: '$ownerID = ? AND $uuid = ?',
        whereArgs: [pOwnerID, pUuid]);

    if (results.isNotEmpty) {
      Device device =
          Device.fromMemberJson(results.first as Map<String, dynamic>);

      return device;
    }

    return null;
  }
}
