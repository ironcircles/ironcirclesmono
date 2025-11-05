import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:sqflite/sqflite.dart';

class TableCircleObjectCache {
  static const String tableName = 'circleobject';

  ///this view is deprecated in favor of indexes
  static const String byCircleIDView = 'bycircleidview';
  static const String pk = "pk";
  static const String circleid = "circle";
  static const String seed = "seed";
  static const String read = "read";
  static const String creator = "creator";
  static const String circleObjectid = "circleObject";
  static const String circleObjectJson = "circleObjectJson";
  static const String type = "type";
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";
  static const String thumbnailTransferState = "thumbnailTransferState";
  static const String fullTransferState = "fullTransferState";
  static const String pinned = "pinned";
  static const String draft = "draft";
  static const String retryDecrypt = "retryDecrypt";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$circleid TEXT,"
      "$circleObjectid TEXT UNIQUE,"
      "$circleObjectJson TEXT,"
      "$type TEXT,"
      "$seed TEXT UNIQUE,"
      "$pinned BIT,"
      "$read BIT,"
      "$draft BIT,"
      "$creator TEXT,"
      "$thumbnailTransferState INT,"
      "$fullTransferState INT,"
      "$lastUpdate INT,"
      "$retryDecrypt INT,"
      "$created INT)";

  static List<String> selectColumns = [
    pk,
    circleid,
    circleObjectid,
    circleObjectJson,
    seed,
    read,
    pinned,
    draft,
    type,
    creator,
    thumbnailTransferState,
    fullTransferState,
    retryDecrypt,
    created,
    lastUpdate,
  ];

  static Database? _database;

  TableCircleObjectCache._();

  static Future<List<Map>> readOlderThanMap(
      List<String> circles, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where += " and $created < ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created ASC",
        limit: amount);

    return results;
  }

  /*static Future<List<CircleObjectCache>> readOlderThan2(
      List<String> circles, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where +=
        " and ($type = ? or $type = ? or $type = ? or $type = ? or $type = ?) and $created < ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          CircleObjectType.CIRCLERECIPE,
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLELINK,
          CircleObjectType.CIRCLEVIDEO,
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created ASC",
        limit: amount);

    List<CircleObjectCache> collection = [];
    //reverse it
    for (int i = results.length - 1; i > -1; i--) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(results[i] as Map<String, dynamic>);
      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    return collection;
  }

   */

  static Future<CircleObjectCache> _saveSeededElsewhere(
      CircleObjectCache circleObjectCache) async {
    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $circleObjectid = ?',
          [circleObjectCache.circleObjectid]));

      if (count == 0) {
        circleObjectCache.pk =
            await _database!.insert(tableName, circleObjectCache.toJson());
      } else {
        await _database!.update(tableName, circleObjectCache.toJson(),
            where: "$circleObjectid = ?",
            whereArgs: [circleObjectCache.circleObjectid]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table_circleobject.upsert: ${error.toString}');
    }

    return circleObjectCache;
  }

  static Future<void> _updateBySeed(CircleObjectCache circleObjectCache) async {
    var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
        [circleObjectCache.seed]));

    if (count == 0) {
      circleObjectCache = await _saveSeededElsewhere(circleObjectCache);
    } else {
      await _database!.update(tableName, circleObjectCache.toJson(),
          where: "$seed = ?", whereArgs: [circleObjectCache.seed]);
    }
  }

  static Future<int?> _upsertBySeed(CircleObjectCache circleObjectCache) async {
    var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
        [circleObjectCache.seed]));

    if (count == 0) {
      circleObjectCache.pk =
          await _database!.insert(tableName, circleObjectCache.toJson());
    } else {
      await _database!.update(tableName, circleObjectCache.toJson(),
          where: "$seed = ?", whereArgs: [circleObjectCache.seed]);
    }

    return circleObjectCache.pk;
  }

  static Future<CircleObjectCache> upsert(
      CircleObjectCache circleObjectCache) async {
    _database = await DatabaseProvider.db.database;

    try {
      //is this a record
      if (circleObjectCache.circleObjectid == null) {
        circleObjectCache.pk = await _upsertBySeed(circleObjectCache);

        // debugPrint(circleObjectCache.pk);
      } else {
        //is this object precached?
        if (circleObjectCache.seed != null) {
          await _updateBySeed(circleObjectCache);
        } else {
          circleObjectCache.seed = circleObjectCache.circleObjectid;
          //to support older version of the app that won't send a seed value
          circleObjectCache = await _saveSeededElsewhere(circleObjectCache);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table_circleobject.upsert: ${error.toString}');
    }

    return circleObjectCache;
  }

  static _setPinned(String userID, CircleObject circleObject) {
    if (circleObject.pinnedUsers != null) {
      String pinnedID = circleObject.pinnedUsers!
          .firstWhere((element) => element == userID, orElse: () => '');

      if (pinnedID.isNotEmpty)
        circleObject.pinned = true;
      else
        circleObject.pinned = false;
    }
  }

  static CircleObjectCache _convertToCache(
      String userID, CircleObject circleObject) {
    if (userID.isNotEmpty) {
      _setPinned(userID, circleObject);
    }

    return CircleObjectCache(
        circleid: circleObject.circle!.id,
        creator: circleObject.creator?.id,
        circleObjectid: circleObject.id,
        seed: circleObject.seed ?? circleObject.id,
        type: circleObject.type,
        pinned: circleObject.pinned,
        draft: circleObject.draft,
        circleObjectJson: json.encode(circleObject.toJson()).toString(),
        lastUpdate: circleObject.lastUpdate,
        thumbnailTransferState: circleObject.thumbnailTransferState,
        fullTransferState: circleObject.fullTransferState,
        created: circleObject.created);
  }

  static Future<int> insertListofObjects(
      String userID, Iterable<CircleObject> circleObjects,
      {bool markRead = false}) async {
    _database = await DatabaseProvider.db.database;

    var batch = _database!.batch();

    CircleObjectCache? circleObjectCache;

    for (CircleObject circleObject in circleObjects) {
      try {
        if (circleObject.seed == null && circleObject.id != null) {
          circleObject.seed = circleObject.id;
        }

        if (circleObject.type == CircleObjectType.CIRCLEEVENT ||
            circleObject.type == CircleObjectType.CIRCLELIST ||
            circleObject.type == CircleObjectType.CIRCLEVOTE ||
            circleObject.type == CircleObjectType.CIRCLERECIPE) {
          if (circleObject.lastUpdate != circleObject.lastReactedDate)
            circleObject.created = circleObject.lastUpdate;
        }

        //debugPrint(circleObject.seed);

        circleObjectCache = _convertToCache(userID, circleObject);

        if (markRead) circleObjectCache.read = true;

        batch.insert(tableName, circleObjectCache.toJson());
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('TableCircleObject.insertListofObjects: $err');
      }
    }

    var results = await batch.commit(noResult: true);

    return results.length;
  }

  static Future<int> countRecords() async {
    var count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $tableName'));

    return count!;
  }

  static _updateSingleObject(String userID, CircleObject circleObject,
      CircleObjectCache circleObjectCache, Batch batch, bool bySeed) async {
    try {
      if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        try {
          CircleObjectCache oldCache =
              await get(circleObjectCache.circleObjectid!);

          Map<String, dynamic>? decode =
              json.decode(oldCache.circleObjectJson!);
          CircleObject oldObject = CircleObject.fromJson(decode!);

          if (oldObject.lastUpdate!.compareTo(circleObject.lastUpdate!) != 0) {
            circleObject.video = oldObject.video;
            circleObjectCache = _convertToCache(userID, circleObject);
          }
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
        }
      }

      ///don't update the mark read flag
      Map<String, Object?> map = circleObjectCache!.toJson();
      map.remove(read);

      if (bySeed) {
        batch.update(tableName, map,
            where: "$seed = ?", whereArgs: [circleObjectCache.seed]);
      } else {
        batch.update(tableName, map,
            where: "$circleObjectid = ?",
            whereArgs: [circleObjectCache.circleObjectid]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('TableCircleObject.updateSingleObject: $error');
    }
  }

  static Future<int> upsertListofObjects(
      String userID, Iterable<CircleObject> circleObjects,
      {bool markRead = false}) async {
    try {
      _database = await DatabaseProvider.db.database;

      Batch batch = _database!.batch();

      CircleObjectCache? circleObjectCache;

      for (CircleObject circleObject in circleObjects) {
        //debugPrint('5: cache for loop  ${DateTime.now()}');
        try {
          if (circleObject.seed == null && circleObject.id != null) {
            circleObject.seed = circleObject.id;
          }

          //make sure an updated list appears at the bottom of insidecircle listview
          if (circleObject.type == CircleObjectType.CIRCLEEVENT ||
              circleObject.type == CircleObjectType.CIRCLELIST ||
              circleObject.type == CircleObjectType.CIRCLEVOTE ||
              circleObject.type == CircleObjectType.CIRCLERECIPE) {
            //if (circleObject.lastUpdate != circleObject.lastReactedDate)
            circleObject.created = circleObject.lastUpdateNotReaction;
          }

          circleObjectCache = _convertToCache(userID, circleObject);

          if (markRead) circleObjectCache.read = true;

          var count = Sqflite.firstIntValue(await _database!.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $circleObjectid = ?',
              [circleObjectCache.circleObjectid]));

          //debugPrint(circleObject.id! + " - " + circleObject.seed!);
          //debugPrint(circleObjectCache.circleObjectid! +              " - " +              circleObjectCache.seed!);

          if (count == 0) {
            //debugPrint(circleObject.id! + " - " + circleObject.seed!);

            var skip = Sqflite.firstIntValue(await _database!.rawQuery(
                'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
                [circleObjectCache.seed]));

            //debugPrint('skip value: $skip');

            if (skip! > 0) {
              ///there is a scenario where the object has a seed but no ID
              await _updateSingleObject(
                  userID, circleObject, circleObjectCache, batch, true);

              continue;
            }

            batch.insert(tableName, circleObjectCache.toJson());
          } else {
            await _updateSingleObject(
                userID, circleObject, circleObjectCache, batch, false);

            //If we made it this far and it's a video update, meaning a reaction, or the owner posted a video, don't update the video state.
            // if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
            //   try {
            //     CircleObjectCache oldCache =
            //         await get(circleObjectCache.circleObjectid!);
            //
            //     Map<String, dynamic>? decode =
            //         json.decode(oldCache.circleObjectJson!);
            //     CircleObject oldObject = CircleObject.fromJson(decode!);
            //
            //     if (oldObject.lastUpdate!.compareTo(circleObject.lastUpdate!) !=
            //         0) {
            //       circleObject.video = oldObject.video;
            //       circleObjectCache = _convertToCache(userID, circleObject);
            //     }
            //   } catch (error, trace) {
            //     LogBloc.insertError(error, trace);
            //   }
            // }
            //
            // ///don't update the mark read flag
            // Map<String, Object?> map = circleObjectCache!.toJson();
            // map.remove(read);
            //
            // batch.update(tableName, map,
            //     where: "$circleObjectid = ?",
            //     whereArgs: [circleObjectCache.circleObjectid]);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('TableCircleObject.upsertListofObjects:inner $err');
        }
      }

      var results = await batch.commit(noResult: false, continueOnError: true);

      return results.length;
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.upsertListofObjects: $err');

      return await upsertListofObjectsFailsafe(userID, circleObjects);
    }
  }

  static Future<int> upsertListofObjectsFailsafe(
      String userID, Iterable<CircleObject> circleObjects) async {
    int successCount = 0;

    try {
      _database = await DatabaseProvider.db.database;

      //var batch = _database!.batch();

      CircleObjectCache? circleObjectCache;

      for (CircleObject circleObject in circleObjects) {
        //debugPrint('5: cache for loop  ${DateTime.now()}');
        try {
          if (circleObject.seed == null && circleObject.id != null) {
            circleObject.seed = circleObject.id;
          }

          circleObjectCache = _convertToCache(userID, circleObject);
          await upsert(circleObjectCache);

          successCount = successCount++;
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'TableCircleObject.upsertListofObjectsFailsafe:inner: $err');
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.upsertListofObjectsFailsafe: $err');
    }

    return successCount;
  }

  ///This should only be called at cold boot
  static Future<int> cleanupNotSaved() async {
    int successCount = 0;

    try {
      _database = await DatabaseProvider.db.database;

      int records = await _database!
          .delete(tableName, where: '$circleObjectid = ?', whereArgs: [null]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.cleanupNotSaved: $err');
    }

    return successCount;
  }

  ///This should only be called at cold boot
  static Future<int> cleanupStuckObjects() async {
    int successCount = 0;

    try {
      _database = await DatabaseProvider.db.database;

      ///cleanup transfer state of stuck
      Map<String, dynamic> map = {
        thumbnailTransferState: BlobState.BLOB_DOWNLOAD_FAILED,
      };

      int count = await _database!.update(tableName, map,
          where: "$thumbnailTransferState = ?",
          whereArgs: [BlobState.DECRYPTING]);

      debugPrint(
          '********************************** cleaned up $count decrypting objects');

      count = await _database!.update(tableName, map,
          where: "$thumbnailTransferState = ?",
          whereArgs: [BlobState.DOWNLOADING]);

      debugPrint(
          '********************************** cleaned up $count downloading objects');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.cleanupStuckObjects: $err');
    }

    return successCount;
  }

  static Future<int> deleteList(GlobalEventBloc globalEventBloc,
      Iterable<CircleObject> deletedObjects) async {
    _database = await DatabaseProvider.db.database;

    var batch = _database!.batch();

    //bool refreshActionNeeded = false;

    for (CircleObject circleObject in deletedObjects) {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id, circleObject.circle!.id);

      batch.delete(tableName,
          where: '$circleObjectid = ?', whereArgs: [circleObject.id]);

      if (circleObject.type == "circleimage") {
        ImageCacheService.deleteCircleObjectImage(
          circleObject,
          circlePath,
        );
      } else if (circleObject.type == CircleObjectType.CIRCLEVOTE ||
          circleObject.type == CircleObjectType.CIRCLELIST) {
        //refreshActionNeeded = true;
      } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        VideoCacheService.deleteVideo(circlePath, circleObject);
      } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
        CircleAlbumBloc.unCacheMedia(circleObject, circlePath);
      }
    }

    var results = await batch.commit();

    globalEventBloc.broadcastActionNeededRefresh();
    globalEventBloc
        .broadCastMemCacheCircleObjectsRemove(deletedObjects.toList());
    return results.length;
  }

  static Future<int> delete(String? id) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!
        .delete(tableName, where: '$circleObjectid = ?', whereArgs: [id]);

    return records;
  }

  static Future<int> deleteDraft(String pSeed) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(tableName,
        where: '$seed = ? AND $draft = 1', whereArgs: [pSeed]);

    debugPrint('deleteBySeed: Circleobjects deleted: $records');

    return records;
  }

  static Future<int> deleteBySeed(String pSeed) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!
        .delete(tableName, where: '$seed = ?', whereArgs: [pSeed]);

    debugPrint('deleteBySeed: Circleobjects deleted: $records');

    return records;
  }

  static Future<int> deleteAllForCircle(String? circleID) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!
        .delete(tableName, where: '$circleid = ?', whereArgs: [circleID]);

    //debugPrint('deleteAllForCircle: Circleobjects deleted: $records');

    return records;
  }

  static Future<int> deleteDisappearingMessages(
    Circle circle,
    int expired,
  ) async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(tableName,
        where: '$circleid = ? AND $created < ?',
        whereArgs: [circle.id!, expired]);

    //debugPrint('deleteAllForCircle: Circleobjects deleted: $records');

    return records;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<List<Map>> readPinnedPosts(String circleID) async {
    _database = await DatabaseProvider.db.database;

    //debugPrint('readAmount start: ${DateTime.now()}');

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleid = ? AND $pinned = ?",
      whereArgs: [circleID, 1],
      orderBy: "$created DESC",
    );
    return results;
  }

  static Future<List<Map>> search(String circleID, String searchText) async {
    _database = await DatabaseProvider.db.database;

    //print('readAmount start: ${DateTime.now()}');

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleid = ? AND $type!=? AND $circleObjectJson LIKE ?",
      whereArgs: [circleID, CircleObjectType.SYSTEMMESSAGE, '%$searchText%'],
      orderBy: "$created DESC",
    );

    //print('readAmount stop: ${DateTime.now()}');

    //debugPrint('readAmount stop: ${DateTime.now()}');

    return results;
  }

  static Future<List<Map>> readAmount(String? circleID, int amount) async {
    _database = await DatabaseProvider.db.database;

    String startTime = DateTime.now().toString();
    //debugPrint('readAmount start: ${DateTime.now()}');

    List<Map> results = await _database!.query(tableName,
        //List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: "$circleid = ?",
        whereArgs: [circleID],
        orderBy: "$created DESC",
        limit: amount);

    debugPrint(
        "******************************TableCircleObject.readAmount start time: $startTime, end time: ${DateTime.now()}, number of records: ${results.length}");

    return results;
  }

  static Future<List<Map>> readAmountForMemCache(int amount) async {
    _database = await DatabaseProvider.db.database;

    String startTime = DateTime.now().toString();

    List<Map> results = await _database!.query(tableName,
        //List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        //where: "$circleid = ?",
        //whereArgs: [circleID],
        orderBy: "$created DESC",
        limit: amount);

    debugPrint(
        "******************************TableCircleObject.readAmountForMemCache start time: $startTime, end time: ${DateTime.now()}, number of records: ${results.length}");

    return results;
  }

  ///used to load wall objects
  static Future<List<Map>> readByCircles(
      List<String> circles, int amount) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    //where += " and ($type = ?)";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        orderBy: "$created DESC",
        //whereArgs: [circleObjectType],
        limit: amount);

    return results;
  }

  static Future<List<Map>> getMessageFeedByCircle(
      UserCircleCache userCircleCache, int amount) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where:
          '$circleid = ? AND $creator != ? AND $created > ? AND ($read = 0 OR $read IS NULL)',
      whereArgs: [
        userCircleCache.circle!,
        userCircleCache.user!,
        userCircleCache.lastLocalAccess == null
            ? DateTime.now().millisecondsSinceEpoch
            : userCircleCache.lastLocalAccess!.millisecondsSinceEpoch,
      ],
      orderBy: "$created ASC",
      limit: amount,
    );

    return results;
  }

  static Future<List<CircleObjectCache>> readOlderThan(
      List<String> circles, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where +=
        " and ($type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ?) and $created < ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          CircleObjectType.CIRCLERECIPE,
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLELINK,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLEALBUM,
          CircleObjectType.CIRCLEAGORACALL,
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created ASC",
        limit: amount);

    List<CircleObjectCache> collection = [];
    //reverse it
    for (int i = results.length - 1; i > -1; i--) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(results[i] as Map<String, dynamic>);
      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    return collection;
  }

  static Future<List<CircleObjectCache>> readLibrary(
      List<String> circles, int amount) async {
    _database = await DatabaseProvider.db.database;

    String startTime = DateTime.now().toString();
    debugPrint("******************************start time: $startTime");

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where +=
        " and ($type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ?)";

    List<Map> results = await _database!.query(tableName, //byCircleIDView,
        columns: selectColumns,
        where: where,
        whereArgs: [
          CircleObjectType.CIRCLERECIPE,
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLELINK,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLECREDENTIAL,
          CircleObjectType.CIRCLEFILE,
          CircleObjectType.CIRCLEEVENT,
          CircleObjectType.CIRCLEVOTE,
          CircleObjectType.CIRCLELIST,
          CircleObjectType.CIRCLEALBUM,
          CircleObjectType.CIRCLEAGORACALL,
        ],
        orderBy: "$created DESC",
        limit: amount);

    String queryDown = DateTime.now().toString();

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    debugPrint(
        "******************************start time: $startTime, query done: $queryDown, end time: ${DateTime.now()}, number of records: ${collection.length}");
    return collection;
  }

  static Future<List<CircleObjectCache>> readLibraryNewerThanMap(
      List<String> circles, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where +=
        " and ($type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ?) and $created > ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          CircleObjectType.CIRCLERECIPE,
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLELINK,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLECREDENTIAL,
          CircleObjectType.CIRCLEFILE,
          CircleObjectType.CIRCLEEVENT,
          CircleObjectType.CIRCLEVOTE,
          CircleObjectType.CIRCLELIST,
          CircleObjectType.CIRCLEALBUM,
          CircleObjectType.CIRCLEAGORACALL,
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created DESC",
        limit: amount);

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    return collection;
  }

  static Future<List<CircleObjectCache>> readLibraryOlderThanMap(
      List<String> circles, int amount, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where +=
        " and ($type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ? or $type = ?) and $created < ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          CircleObjectType.CIRCLERECIPE,
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLELINK,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLECREDENTIAL,
          CircleObjectType.CIRCLEFILE,
          CircleObjectType.CIRCLEEVENT,
          CircleObjectType.CIRCLEVOTE,
          CircleObjectType.CIRCLELIST,
          CircleObjectType.CIRCLEALBUM,
          CircleObjectType.CIRCLEAGORACALL,
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created DESC",
        limit: amount);

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    return collection;
  }

  static Future<List<CircleObjectCache>> readLibraryOlderThanMapByType(
      List<String> circles,
      int amount,
      DateTime dateTime,
      String circleObjectType) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where += " and $type = ? and $created < ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          circleObjectType,
          dateTime.millisecondsSinceEpoch,
        ],
        orderBy: "$created DESC",
        limit: amount);

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    }

    collection.removeWhere((element) => element.circleObjectid == null);

    return collection;
  }

  static Future<List<Map>> readType(String circleObjectType) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$type = ?",
      whereArgs: [circleObjectType],
    );

    /* List<CircleObjectCache> collection = [];
    results.forEach((result) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    });

    */

    return results;
  }

  static Future<List<Map>> readTypeByCircles(
      List<String> circles, String circleObjectType) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where += " and ($type = ?)";

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: where,
      whereArgs: [circleObjectType],
    );

    /* List<CircleObjectCache> collection = [];
    results.forEach((result) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      collection.add(individual);
    });

    */

    return results;
  }

  static Future<List<CircleObjectCache>> readActionNeeded(
      List<String> circles, int amount) async {
    _database = await DatabaseProvider.db.database;

    String where = '$circleid IN (${circles.map((e) => "'$e'").join(', ')})';

    where += ' and ($type = ? or $type = ?)';

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: ['circlelist', 'circlevote'],
        orderBy: "$created ASC",
        limit: amount);

    List<CircleObjectCache> retValue = [];
    List<CircleObjectCache> votes = [];
    List<CircleObjectCache> other = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);

      if (individual.type! == CircleObjectType.CIRCLEVOTE) {
        votes.add(individual);
      } else {
        other.add(individual);
      }
    }

    votes.sort((a, b) => b.lastUpdate!.compareTo(a.lastUpdate!));
    other.sort((a, b) => b.lastUpdate!.compareTo(a.lastUpdate!));

    retValue.addAll(votes);
    retValue.addAll(other);

    return retValue;
  }

  static Future<List<CircleObjectCache>> readPrecached() async {
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(
        tableName,
        columns: selectColumns,
        where: "$circleObjectid is null AND $draft != 1",
        orderBy: "$created ASC",
      );

      List<CircleObjectCache> collection = [];
      for (var result in results) {
        CircleObjectCache individual =
            CircleObjectCache.fromJson(result as Map<String, dynamic>);
        collection.add(individual);
      }

      return collection;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('table_circleboject:readPrecached: $error');
      rethrow;
    }
  }

  static Future<List<CircleObjectCache>> readMediaBeforeAndAfterForCircle(
      CircleObject circleObject, DateTime before, DateTime after,
      {int amount = 50}) async {
    _database = await DatabaseProvider.db.database;

    List<CircleObjectCache> collection = [];

    ///read before
    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where:
            "($type = ? or $type = ? or $type = ? or $type = ?) and $circleid = ? and $created <= ?",
        whereArgs: [
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLEALBUM,
          circleObject.circle!.id,
          before.millisecondsSinceEpoch
        ],
        orderBy: "$created DESC",
        limit: amount);

    //reverse it
    for (int i = results.length - 1; i > -1; i--) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(results[i] as Map<String, dynamic>);
      collection.add(individual);
    }

    results = await _database!.query(tableName,
        columns: selectColumns,
        where:
            "($type = ? or $type = ? or $type = ? or $type = ?) and $circleid = ? and $created > ?",
        whereArgs: [
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLEALBUM,
          circleObject.circle!.id,
          after.millisecondsSinceEpoch
        ],
        orderBy: "$created ASC",
        limit: 500);

    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }

  static Future<List<CircleObjectCache>> readMediaBeforeAndAfterForFeed(
      CircleObject circleObject,
      List<String> circleIDs,
      DateTime before,
      DateTime after,
      {int amount = 50}) async {
    _database = await DatabaseProvider.db.database;

    List<CircleObjectCache> collection = [];

    String where = '$circleid IN (${circleIDs.map((e) => "'$e'").join(', ')})';

    //where += " and $created < ?";

    ///read before
    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where:
            "$where and ($type = ? or $type = ? or $type = ? or $type = ?) and $created <= ?",
        whereArgs: [
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLEALBUM,
          before.millisecondsSinceEpoch
        ],
        orderBy: "$created DESC",
        limit: amount);

    //reverse it
    for (int i = results.length - 1; i > -1; i--) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(results[i] as Map<String, dynamic>);
      collection.add(individual);
    }

    results = await _database!.query(tableName,
        columns: selectColumns,
        where:
            "$where and ($type = ? or $type = ? or $type = ? or $type = ?) and $created > ?",
        whereArgs: [
          CircleObjectType.CIRCLEIMAGE,
          CircleObjectType.CIRCLEGIF,
          CircleObjectType.CIRCLEVIDEO,
          CircleObjectType.CIRCLEALBUM,
          after.millisecondsSinceEpoch
        ],
        orderBy: "$created ASC",
        limit: 500);

    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }

  static Future<CircleObjectCache> get(String pCircleObjectID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleObjectid = ?",
      whereArgs: [pCircleObjectID],
      orderBy: "$created DESC",
    );

    if (results.isNotEmpty) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(results[0] as Map<String, dynamic>);

      return individual;
    } else
      throw ('TableCircleObject.get: CircleObject not found');
  }

  static Future<CircleObjectCache> readBySeed(String pSeed) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$seed = ?",
      whereArgs: [pSeed],
      orderBy: "$created DESC",
    );
    CircleObjectCache individual = CircleObjectCache();

    if (results.isNotEmpty)
      individual =
          CircleObjectCache.fromJson(results[0] as Map<String, dynamic>);

    return individual;
  }

  static Future<List<Map>> readMapBySeed(String pSeed) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$seed = ?",
      whereArgs: [pSeed],
      orderBy: "$created DESC",
    );

    return results;
  }

  static Future<List<CircleObjectCache>> readNewerThan(
      String circleID, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleid = ? and $lastUpdate > ?",
      whereArgs: [circleID, dateTime.millisecondsSinceEpoch],
      orderBy: "$created DESC",
    );

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }

  static Future<List<Map>> readNewerThanMap(
      String circleID, DateTime dateTime) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleid = ? and $lastUpdate > ?",
      whereArgs: [circleID, dateTime.millisecondsSinceEpoch],
      orderBy: "$created DESC",
    );

    return results;
  }

  static Future<List<CircleObjectCache>> readForward(
      String circleID, DateTime start) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$circleid = ?  and $lastUpdate >= ?",
      whereArgs: [
        circleID,
        start.millisecondsSinceEpoch,
      ],
      orderBy: "$created DESC",
    );

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }

  static Future<List<CircleObjectCache>> readBetweenForUser(
      String circleID, DateTime start, DateTime end, String userID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where:
          "$circleid = ? and $lastUpdate >= ? and $lastUpdate <= ? and $creator = ?",
      whereArgs: [
        circleID,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
        userID
      ],
      orderBy: "$created DESC",
    );

    List<CircleObjectCache> collection = [];
    for (var result in results) {
      CircleObjectCache individual =
          CircleObjectCache.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }

  static Future<CircleObjectCache> readMostRecent(
      String? circleID, String? userID) async {
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(tableName,
          columns: selectColumns,
          where: "$creator != ? AND $circleid = ?",
          whereArgs: [userID, circleID],
          orderBy: "$created DESC",
          limit: 1);

      if (results.isEmpty) {
        throw ('most recent not found');
      } else {
        return CircleObjectCache.fromJson(
            results.first as Map<String, dynamic>);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.readMostRecent: $err');
      rethrow;
    }
  }

  static updateCacheSingleObject(
      String userID, CircleObject circleObject) async {
    try {
      if (circleObject.seed == null && circleObject.id != null) {
        circleObject.seed = circleObject.id;
      }

      if (userID.isNotEmpty) {
        _setPinned(userID, circleObject);
      }

      ///sanity check to stop the data issue Gamina had with the devices being a billion \\\\\\\
      if (circleObject.creator!.devices != null) {
        circleObject.creator!.devices = '';
      }

      CircleObjectCache circleObjectCache = CircleObjectCache(
          thumbnailTransferState: circleObject.thumbnailTransferState,
          fullTransferState: circleObject.fullTransferState,
          circleid: circleObject.circle!.id,
          pinned: circleObject.pinned,
          creator: circleObject.creator?.id,
          circleObjectid: circleObject.id,
          seed: circleObject.seed ?? circleObject.id,
          type: circleObject.type,
          draft: circleObject.draft,
          circleObjectJson: json.encode(circleObject.toJson()).toString(),
          lastUpdate: circleObject.lastUpdate,
          created: circleObject.created);

      await upsert(circleObjectCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'TableCircleObject.updateCacheSingleObject');
      debugPrint('TableCircleObject.updateCacheSingleObject: $err');
    }
  }

  static markRead(String pCircleObjectID) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        TableCircleObjectCache.read: 1,
      };

      await _database!.update(tableName, map,
          where: "$circleObjectid = ?", whereArgs: [pCircleObjectID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.setName: $err");
      rethrow;
    }

    return;
  }

  static markReadForCircle(String pCircle, DateTime lastObjectCreated) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        TableCircleObjectCache.read: 1,
      };

      await _database!.update(tableName, map,
          where: "$circleid = ? AND created <= ?",
          whereArgs: [pCircle, lastObjectCreated.millisecondsSinceEpoch]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.setName: $err");
      rethrow;
    }

    return;
  }

  static markMultipleRead(List<String> pCircleObjectIDs) async {
    _database = await DatabaseProvider.db.database;

    try {
      String where =
          '$circleObjectid IN (${pCircleObjectIDs.map((e) => "'$e'").join(', ')})';

      Map<String, dynamic> map = {
        TableCircleObjectCache.read: 1,
      };

      await _database!.update(tableName, map, where: where);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.setName: $err");
      rethrow;
    }

    return;
  }

  static Future<List<CircleObjectCache>> readFailedToDecrypt() async {
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(tableName,
          columns: selectColumns,
          where: "$type = ? AND $retryDecrypt < ?",
          whereArgs: [CircleObjectType.UNABLETODECRYPT, 3],
          orderBy: "$created DESC",
          limit: 20);

      List<CircleObjectCache> collection = [];
      for (var result in results) {
        CircleObjectCache individual =
            CircleObjectCache.fromJson(result as Map<String, dynamic>);
        collection.add(individual);
      }

      return collection;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.readFailedToDecrypt: $err');
      rethrow;
    }
  }

  static Future<void> dropAndCreateView() async {
    _database = await DatabaseProvider.db.database;

    DatabaseProvider.createView(_database, true);
  }

  static Future<List<Map>> getOldCredentials() async {
    try {
      _database = await DatabaseProvider.db.database;
      List<Map> results = await _database!.query(tableName,
          columns: selectColumns,
          where: "$type = ? AND $circleObjectJson LIKE ?",
          whereArgs: [CircleObjectType.CIRCLEMESSAGE, '%"subType":0%'],
          orderBy: "$created DESC",
          limit: 20);

      return results;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }
}
