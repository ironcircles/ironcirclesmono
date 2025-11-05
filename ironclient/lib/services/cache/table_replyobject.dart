import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/replyobjectcache.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableReplyObjectCache {
  static const String tableName = 'replyobject';
  static const String pk = "pk";
  static const String seed = "seed";
  static const String circleObjectid = "circleObject"; ///reference to wall object
  static const String replyObjectid = "replyObject";
  static const String replyObjectJson = "replyObjectJson"; ///the reply object
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";
  static const String type = "type";
  static const String creator = "creator";
  static const String retryDecrypt = "retryDecrypt";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$seed TEXT UNIQUE,"
      "$circleObjectid TEXT,"
      "$replyObjectid TEXT UNIQUE,"
      "$replyObjectJson TEXT,"
      "$lastUpdate INT,"
      "$created INT,"
      "$creator TEXT,"
      "$retryDecrypt INT,"
      "$type TEXT)";

  static List<String> selectColumns = [
    pk,
    seed,
    circleObjectid,
    replyObjectid,
    replyObjectJson,
    lastUpdate,
    created,
    creator,
    retryDecrypt,
    type,
  ];

  static Database? _database;

  TableReplyObjectCache._();

  static Future<List<Map>> readAmount(String? circleObjectID, int amount) async {
    _database = await DatabaseProvider.db.database;

    String startTime = DateTime.now().toString();

    List<Map> results = await _database!.query(tableName,
      columns: selectColumns,
      where: "$circleObjectid = ?",
      whereArgs: [circleObjectID],
      orderBy: "$created DESC", ///DESC
      limit: amount);

    debugPrint(
        "******************************TableReplyObject.readAmount start time: $startTime, end time: ${DateTime.now()}, number of records: ${results.length}");

    return results;
  }

  static Future<List<Map>> readAmountMostRecent(int amount) async {
    _database = await DatabaseProvider.db.database;

    String startTime = DateTime.now().toString();

    List<Map> results = await _database!.query(tableName,
      columns: selectColumns,
      orderBy: "$created DESC",
      limit: 1000
    );

    debugPrint(
        "******************************TableReplyObject.readAmountMostRecent start time: $startTime, end time: ${DateTime.now()}, number of records: ${results.length}");

    return results;
  }

  // static Future<List<Map>> readAmountByCircles(List<Circle> circles, int amount) async {
  //   _database = await DatabaseProvider.db.database;
  //
  //   String startTime = DateTime.now().toString();
  //
  //   List<Map> allResults;
  //
  //   for (Circle circle in circles) {
  //     List<Map> results = await _database!.query(
  //       tableName,
  //       columns: selectColumns,
  //       where: "$circleid = ?",
  //       whereArgs: [circle.id],
  //       orderBy: "$created DESC",
  //       //limit: ///IDK
  //     );
  //
  //     allResults.add(List<Map> results);
  //     if (allResults.length > 500) {
  //       return allResults;
  //     }
  //   }
  //
  //   debugPrint(
  //       "******************************TableReplyObject.readAmountByCircles start time: $startTime, end time: ${DateTime.now()}, number of records: ${allResults.length}");
  //
  //   return allResults;
  // }

  static Future<int> delete(String? id) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(tableName, where: '$replyObjectid = ?', whereArgs: [id]);

    return records;
  }

  static Future<List<Map>> readOlderThanMap(
      List<String> circleObjects, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleObjectid IN (${circleObjects.map((e) => "'$e'").join(', ')})';

    where += " and $created < ?";

    List<Map> results = await _database!.query(tableName,
      columns: selectColumns,
      where: where,
      whereArgs: [
        dateTime.millisecondsSinceEpoch,
      ],
      orderBy: "$created ASC",
      limit: amount
    );

    return results;
  }

  static Future<List<ReplyObjectCache>> readForward(
      String circleObjectId, DateTime start) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleObjectid = ? and $lastUpdate >= ?",
      whereArgs: [
        circleObjectId,
        start.millisecondsSinceEpoch,
      ],
      orderBy: "$created DESC",
    );

    List<ReplyObjectCache> collection = [];
    for (var result in results) {
      ReplyObjectCache individual =
          ReplyObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }
    return collection;
  }

  static Future<int> deleteList(GlobalEventBloc globalEventBloc,
      Iterable<ReplyObject> deletedObjects) async {
    _database = await DatabaseProvider.db.database;

    var batch = _database!.batch();

    for (ReplyObject replyObject in deletedObjects) {

      batch.delete(tableName,
        where: '$replyObjectid = ?', whereArgs: [replyObject.id]);
    }

    var results = await batch.commit();

    //globalEventBloc.broadcastMemCacheCircleObjectsRemove(deletedObjects.toList());
    return results.length;
  }

  static Future<List<Map>> readNewerThanMap(
      String circleObjectID, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleObjectid = ? and $lastUpdate >?",
      whereArgs: [circleObjectID, dateTime.millisecondsSinceEpoch],
      orderBy: "$created DESC",
    );

    return results;
  }

  static updateCacheSingleObject(
      String userID, ReplyObject replyObject) async {
    try {
      if (replyObject.seed == null && replyObject.id != null) {
        replyObject.seed = replyObject.id;
      }

      if (userID.isNotEmpty) {
        //_setPinned
      }

      ///sanity check to stop the data issue Gamina had with the devices being a billion \\\\\\\
      if (replyObject.creator!.devices != null) { ///new id doesn't make it here!!!
        replyObject.creator!.devices = '';
      }

      ReplyObjectCache replyObjectCache = ReplyObjectCache(
        circleObjectid: replyObject.circleObjectID, // replyObject.circleObject!.id,
        creator: replyObject.creator?.id,
        replyObjectid: replyObject.id,
        seed: replyObject.seed ?? replyObject.id,
        type: replyObject.type,
        //draft: replyObject.draft,
        replyObjectJson: json.encode(replyObject.toJson()).toString(),
        lastUpdate: replyObject.lastUpdate,
        created: replyObject.created,
      );

      await upsert(replyObjectCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableReplyObject.updateCacheSingleObject: $err");
    }
  }

  static Future<ReplyObjectCache> upsert(
      ReplyObjectCache replyObjectCache) async {
    _database = await DatabaseProvider.db.database;

    try {
      //is this a record
      if (replyObjectCache.replyObjectid == null) {
        replyObjectCache.pk = await _upsertBySeed(replyObjectCache);

      } else {
        //is this object precached?
        if (replyObjectCache.seed != null) {
          await _updateBySeed(replyObjectCache);
        } else {
          replyObjectCache.seed = replyObjectCache.replyObjectid;
          // //to support older version of the app that won't send a seed value
          // circleObjectCache = await _saveSeededElsewhere(circleObjectCache);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table_replyobject.upsert: ${error.toString}');
    }
    return replyObjectCache;
  }

  static Future<void> _updateBySeed(ReplyObjectCache replyObjectCache) async {
    var count = Sqflite.firstIntValue(await _database!.rawQuery(
      'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
      [replyObjectCache.seed]));

    if (count == 0) {
      replyObjectCache = await _saveSeededElsewhere(replyObjectCache);
    } else {
      await _database!.update(tableName, replyObjectCache.toJson(),
        where: "$seed = ?", whereArgs: [replyObjectCache.seed]);
    }
  }

  static Future<ReplyObjectCache> _saveSeededElsewhere(
      ReplyObjectCache replyObjectCache) async {
    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $replyObjectid = ?',
        [replyObjectCache.replyObjectid]));

      if (count == 0) {
        replyObjectCache.pk = await _database!.insert(tableName, replyObjectCache.toJson());
      } else {
        await _database!.update(tableName, replyObjectCache.toJson(),
          where: "$replyObjectid = ?",
          whereArgs: [replyObjectCache.replyObjectid]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table_replyobject.upsert: ${error.toString}');
    }
    return replyObjectCache;
  }

  static Future<int?> _upsertBySeed(ReplyObjectCache replyObjectCache) async {
    var count = Sqflite.firstIntValue(await _database!.rawQuery(
      'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
      [replyObjectCache.seed]));

    if (count == 0) {
      replyObjectCache.pk =
          await _database!.insert(tableName, replyObjectCache.toJson()); ///jere!
    } else {
      await _database!.update(tableName, replyObjectCache.toJson(),
        where: "$seed = ?", whereArgs: [replyObjectCache.seed]);
    }

    return replyObjectCache.pk;
  }

  static Future<List<ReplyObjectCache>> readPrecached() async {
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(
        tableName,
        columns: selectColumns,
        where: "$replyObjectid is null", // AND $draft != 1",
        orderBy: "$created ASC",
      );

      List<ReplyObjectCache> collection = [];
      for (var result in results) {
        ReplyObjectCache individual =
            ReplyObjectCache.fromJson(result as Map<String, dynamic>);
        collection.add(individual);
      }

      return collection;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table._replyobject:readPrecached: $error');
      rethrow;
    }
  }

  static Future<List<Map>> getLength(String circleObjectID) async {
    try {

      _database = await DatabaseProvider.db.database;

      String startTime = DateTime.now().toString();

      List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: "$circleObjectid = ?",
        whereArgs: [circleObjectID],
        orderBy: "$created DESC",
      );

      debugPrint(
          "******************************TableReplyObject.getLength start time: $startTime, end time: ${DateTime.now()}, number of records: ${results.length}");

      //return results.length;
      return results;

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table._replyobject.getLength: $error');
      rethrow;
    }
  }

  static Future<int> upsertListofObjects(
      String userID, Iterable<ReplyObject> replyObjects, //{bool markeEad = false},
      ) async {
    try {
      _database = await DatabaseProvider.db.database;

      var batch = _database!.batch();

      ReplyObjectCache? replyObjectCache;

      for (ReplyObject replyObject in replyObjects) {
        try {
          if (replyObject.seed == null && replyObject.id != null) {
            replyObject.seed = replyObject.id;
          }

          replyObjectCache = _convertToCache(userID, replyObject);

          //if (markRead) replyObjectCache.read = true;

          var count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $replyObjectid = ?',
            [replyObjectCache.replyObjectid]));

          if (count == 0) {
            var skip = Sqflite.firstIntValue(await _database!.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
              [replyObjectCache.seed]));

            if (skip! > 0) {
              continue;
            }

            batch.insert(tableName, replyObjectCache.toJson());
          } else {
            ///don't update the mark read flag
            Map<String, Object?> map = replyObjectCache.toJson();
            // map.remove(read);
            //
            batch.update(tableName, map,
                where: "$replyObjectid = ?",
                whereArgs: [replyObjectCache.replyObjectid]);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('TableReplyObject.upsertListOfObjects:inner $err');
        }
      }

      var results = await batch.commit(noResult: false, continueOnError: true);

      return results.length;
    } catch (err) {
      debugPrint('TableReplyObject.upsertListOfObjects: $err');

      return await upsertListofObjectsFailsafe(userID, replyObjects);
    }
  }

  static Future<int> upsertListofObjectsFailsafe(
      String userID, Iterable<ReplyObject> replyObjects) async {
    int successCount = 0;

    try {
      _database = await DatabaseProvider.db.database;

      ReplyObjectCache? replyObjectCache;

      for (ReplyObject replyObject in replyObjects) {
        try {
          if (replyObject.seed == null && replyObject.id != null) {
            replyObject.seed = replyObject.id;
          }

          replyObjectCache = _convertToCache(userID, replyObject);
          await upsert(replyObjectCache);

          successCount = successCount++;
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('TableReplyObject.upsertListofObjectsFailsafe:inner: $err');
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableReplyObject.upsertListofObjectsFailsafe: $err");
    }
    return successCount;
  }

  static ReplyObjectCache _convertToCache(
      String userID, ReplyObject replyObject)
  {
  //   if (userID.isNotEmpty) {
  //     _setPinner(userID, replyObject);
  // }
  return ReplyObjectCache(
    circleObjectid: replyObject.circleObjectID,
    creator: replyObject.creator?.id,
    replyObjectid: replyObject.id!,
    replyObjectJson: json.encode(replyObject.toJson()).toString(),
    seed: replyObject.seed ?? replyObject.id,
    type: replyObject.type,
    //pinned: replyObject.pinned,
    //draft: replyObject.draft,
    lastUpdate: replyObject.lastUpdate,
    created: replyObject.created
    );
  }

  static Future<int> insertListofObjects(
      String userID, Iterable<ReplyObject> replyObjects,
      ) async {
    _database = await DatabaseProvider.db.database;

    var batch = _database!.batch();

    ReplyObjectCache? replyObjectCache;

    for (ReplyObject replyObject in replyObjects) {
      try {
        if (replyObject.seed == null && replyObject.id != null) {
          replyObject.seed = replyObject.id;
        }

        replyObjectCache = _convertToCache(userID, replyObject);

        //if (markRead) circleObjectCache.read = true;

        batch.insert(tableName, replyObjectCache.toJson());
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('TableReplyObject.insertListofObjects: $err');
      }
    }

    var results = await batch.commit(noResult: true);

    return results.length;
  }

  static Future<int> deleteBySeed(String pSeed) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(tableName, where: '$seed = ?', whereArgs: [pSeed]);

    debugPrint('deleteBySeed: Replyobjects deleted: $records');

    return records;
  }

  static Future<ReplyObjectCache> get(String replyObjectID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$replyObjectid = ?",
      whereArgs: [replyObjectID],
      orderBy: "$created DESC",
    );

    if (results.isNotEmpty) {
      ReplyObjectCache individual = ReplyObjectCache.fromJson(results[0] as Map<String, dynamic>);

      return individual;
    } else {
      throw ('TableReplyObject.get: ReplyObject not found');
    }
  }

}