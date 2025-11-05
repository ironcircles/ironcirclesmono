import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/actionrequiredcache.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableActionRequiredCache {
  static const String tableName = 'actionrequired';
  static const String pk = "pk";
  static const String id = "id";
  static const String alertType = "alertType";
  static const String user = "user";
  static const String actionRequiredJson = "actionRequiredJson";
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";
  static const String networkRequest = "networkRequest";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT UNIQUE,"
      "$alertType INT,"
      "$user TEXT,"
      "$actionRequiredJson TEXT,"
      "$lastUpdate INT,"
      "$networkRequest TEXT,"
      "$created INT)";

  static Database? _database;

  TableActionRequiredCache._();

  static Future<bool> upsertCollection(
      ActionRequiredCollection actionRequiredCollection,
      String? pUserID) async {
    _database = await DatabaseProvider.db.database;

    bool retValue = false;

    try {
      //Remove any action required no longer on the server

      List<ActionRequired> existing = await readForUser(pUserID!);
      for (ActionRequired actionRequiredExisting in existing) {
        bool found = false;

        for (ActionRequired actionRequired
            in actionRequiredCollection.actionRequiredObjects) {
          if (actionRequiredExisting.id == actionRequired.id) {
            found = true;
            break;
          }
        }

        if (!found) delete(actionRequiredExisting.id!); //async should be ok
      }

      //await deleteByUser(pUserID);

      for (ActionRequired actionRequired
          in actionRequiredCollection.actionRequiredObjects) {
        ActionRequiredCache actionRequiredCache =
            ActionRequiredCache.createFromObject(actionRequired);

        try {
          await upsert(actionRequiredCache);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint("TableActionRequiredCache.upsertCollection: $err");
        }
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableActionRequiredCache.upsertCollection: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<ActionRequiredCache> upsert(
      ActionRequiredCache actionRequiredCache) async {
    _database = await DatabaseProvider.db.database;

    try {
      debugPrint('ActionRequiredCache.id: ${actionRequiredCache.id}');

      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?',
          [actionRequiredCache.id]));

      if (count == 0) {
        actionRequiredCache.pk =
            await _database!.insert(tableName, actionRequiredCache.toJson());
      } else {
        Map<String, dynamic> map = actionRequiredCache.toJson();

        await _database!.update(tableName, map,
            where: "$id = ?", whereArgs: [actionRequiredCache.id]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableActionRequiredCache.upsert: $err");
      rethrow;
    }

    return actionRequiredCache;
  }

  static Future<int> deleteByActionType(String? pUserID, int pAlertType) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(tableName,
        where: '$user = ? AND $alertType = ?',
        whereArgs: [pUserID, pAlertType]);

    return records;
  }

  static Future<int> deleteByUser(String? pUserID) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!
        .delete(tableName, where: '$user = ?', whereArgs: [pUserID]);

    return records;
  }

  static Future<int> delete(String pID) async {
    _database = await DatabaseProvider.db.database;

    int records =
        await _database!.delete(tableName, where: '$id = ?', whereArgs: [pID]);

    return records;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<List<ActionRequired>> readForUserAndType(
      String pUserID, int pAlertType) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        alertType,
        user,
        actionRequiredJson,
        lastUpdate,
        created,
        networkRequest,
      ],
      where: "$user = ? AND  $alertType = ?",
      whereArgs: [pUserID, pAlertType],
      orderBy: "$created ASC",
    );

    List<ActionRequiredCache> collection = [];
    results.forEach((result) {
      ActionRequiredCache individual =
          ActionRequiredCache.fromJson(result as Map<String, dynamic>);
      //individual.userFurnace = userFurnace;
      if (individual.alertType != 8) {
        collection.add(individual);
      }
    });

    return ActionRequiredCache.convertFromCache(collection);
  }

  static Future<List<ActionRequired>> readForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        alertType,
        user,
        actionRequiredJson,
        lastUpdate,
        created,
        networkRequest,
      ],
      where: "$user = ?",
      whereArgs: [pUserID],
      orderBy: "$created ASC",
    );

    List<ActionRequiredCache> collection = [];
    results.forEach((result) {
      ActionRequiredCache individual =
          ActionRequiredCache.fromJson(result as Map<String, dynamic>);
      //individual.userFurnace = userFurnace;
      collection.add(individual);
    });

    return ActionRequiredCache.convertFromCache(collection);
  }

  static Future<List<ActionRequired>> read(UserFurnace userFurnace) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        alertType,
        user,
        actionRequiredJson,
        lastUpdate,
        created,
        networkRequest,
      ],
      where: "$user = ?",
      whereArgs: [userFurnace.userid],
      orderBy: "$created ASC",
    );

    List<ActionRequiredCache> collection = [];
    results.forEach((result) {
      ActionRequiredCache individual =
          ActionRequiredCache.fromJson(result as Map<String, dynamic>);
      individual.userFurnace = userFurnace;
      if (individual.alertType != 8) {
        collection.add(individual);
      }
    });

    return ActionRequiredCache.convertFromCache(collection);
  }

  /*
  static updateCacheSingleObject(CircleObject circleObject) async {
    try {
      if (circleObject.seed == null && circleObject.id != null) {
        circleObject.seed = circleObject.id;
      }

      CircleObjectCache circleObjectCache = CircleObjectCache(
          circleid: circleObject.circle.id,
          creator:
              circleObject.creator == null ? null : circleObject.creator.id,
          circleObjectid: circleObject.id,
          seed: circleObject.seed == null ? circleObject.id : circleObject.seed,
          type: circleObject.type,
          circleObjectJson: json.encode(circleObject.toJson()).toString(),
          lastUpdate: circleObject.lastUpdate,
          created: circleObject.created);

      await upsert(circleObjectCache);
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.updateCacheSingleObject: ' + err.toString());
    }
  }

   */
}
