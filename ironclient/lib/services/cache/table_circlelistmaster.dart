import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableCircleListMaster {
  static const String tableName = 'circlelistmaster';
  static const String pk = "pk";
  static const String id = "id";
  static const String name = "name";
  static const String owner = "owner";
  static const String jsonString = "jsonString";
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT,"
      "$name TEXT,"
      "$owner TEXT,"
      "$jsonString TEXT,"
      "$lastUpdate INT,"
      "$created INT)";

  static Database? _database;

  TableCircleListMaster._();

  static Future<void> upsert(CircleListTemplate template) async {
    CircleListMasterCache? circleListMasterCache;
    try {
      _database = await DatabaseProvider.db.database;

      int? count = 0;

      if (template.id != null) {
        count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $id = ?', [template.id]));
      } else
        return;

      if (count == 0) {
        circleListMasterCache = CircleListMasterCache(
            id: template.id,
            owner: template.owner,
            jsonString: json.encode(template.toJson()).toString(),
            name: template.name,
            lastUpdate: template.lastUpdate,
            created: template.created);

        circleListMasterCache.pk =
            await _database!.insert(tableName, circleListMasterCache.toJson());
      } else {
        circleListMasterCache = await read(template.id);

        circleListMasterCache!.jsonString =
            json.encode(template.toJson()).toString();
        circleListMasterCache.name = template.name;
        circleListMasterCache.lastUpdate = template.lastUpdate;

        //Map<String, dynamic> map = ;

        await _database!.update(tableName, circleListMasterCache.toJson(),
            where: "$id = ?", whereArgs: [template.id]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleListMaster.upsert: $err");
      rethrow;
    }

    return; // userCircleCache;
  }

  static Future<CircleListMasterCache?> read(String? circleListMasterID) async {
    _database = await DatabaseProvider.db.database;

    CircleListMasterCache? retValue;

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          id,
          name,
          owner,
          jsonString,
          created,
          lastUpdate,
        ],
        where: "$id = ?",
        whereArgs: [circleListMasterID],
        orderBy: "$name DESC");

    if (results.isNotEmpty) {
      retValue =
          CircleListMasterCache.fromJson(results.first as Map<String, dynamic>);
    }

    return retValue;
  }

  static Future<int?> delete(String? circleListMasterID) async {
    int? records;

    try {
      _database = await DatabaseProvider.db.database;

      //int? count = 0;

      // count = Sqflite.firstIntValue(await _database!.rawQuery(
      //   'SELECT COUNT(*) FROM $tableName WHERE $id = ?',
      //   [circleListMasterID]));

      records = await _database!
          .delete(tableName, where: '$id = ?', whereArgs: [circleListMasterID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleListMaster.delete: $err");
    }

    return records;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<List<CircleListMasterCache>?> readForUser(
      List<UserFurnace> userFurnaces) async {
    List<CircleListMasterCache>? collection;

    try {
      _database = await DatabaseProvider.db.database;

      collection = [];

      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        List<Map> results = await _database!.query(
          tableName,
          columns: [
            pk,
            id,
            name,
            owner,
            jsonString,
            created,
            lastUpdate,
          ],
          where: "$owner = ?",
          whereArgs: [userFurnace.userid],
          orderBy: "$name DESC",
        );

        results.forEach((result) {
          CircleListMasterCache individual =
              CircleListMasterCache.fromJson(result as Map<String, dynamic>);

          //add the hitchhikers
          individual.userFurnace = userFurnace;
          collection!.add(individual);
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleListMaster.readForUser: $err");
    }

    //collection.sort()
    return collection;
  }
}
