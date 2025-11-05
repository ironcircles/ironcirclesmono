import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:sqflite/sqflite.dart';

class TableRatchetKeyHelper {
  static const String pk = "pk";
  static const String keyIndex = "keyIndex";
  static const String public = "public";
  static const String private = "private";
  static const String device = "device";
  static const String userCircle = "userCircle";
  static const String user = "user";
  static const String created = "created";
  static const String type = "type";
  static const String lastUpdate = "lastUpdate";

  static Database? database;

  TableRatchetKeyHelper._();

  static init() async {
    database = await DatabaseProvider.db.database;
    return;
  }

  static Future<int> countRecords(String tableName) async {
    database = await DatabaseProvider.db.database;

    var count = Sqflite.firstIntValue(
        await database!.rawQuery('SELECT COUNT(*) FROM $tableName'));

    return count!;
  }

  static Future<List<RatchetKey>> findBlankPrivateKeys(String tableName) async {
    try {
      database = await DatabaseProvider.db.database;

      String where;
      List whereArgs;

      where = "$private='' OR $private is  null";
      //whereArgs = [userID, lastKeychainBackup.millisecondsSinceEpoch];

      List<Map> results = await database!.query(tableName,
          columns: [
            keyIndex,
            public,
            private,
            userCircle,
            created,
          ],
          //distinct: true,
          where: where,
          //whereArgs: whereArgs,
          orderBy: '$created DESC');

      List<RatchetKey> retValue = [];
      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);
        retValue.add(ratchetKey);
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.fetchKeysFoUser: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> fetchKeys(
      String tableName, DateTime lastKeychainBackup) async {
    try {
      database = await DatabaseProvider.db.database;

      String where;
      List whereArgs;

      List<Map> results = [];

      debugPrint(
          '******************** TableRatchetKeyReceiver.fetchKeys start time: ${DateTime.now()}');

      if (lastKeychainBackup == DateTime.parse('20200101')) {
        ///don't use a where clause to speed up performance
        results = await database!.query(tableName,
            columns: [
              keyIndex,
              private,
              created,
            ],
            distinct: true,
            orderBy: '$created DESC');
      } else {
        whereArgs = [lastKeychainBackup.millisecondsSinceEpoch];

        if (tableName == TableRatchetKeyUser.tableName) {
          ///add null to the where clause if its a user key
          where = "($created > ? OR $created is null)";
        } else {
          where = "($created > ?)";
        }

        results = await database!.query(tableName,
            columns: [
              keyIndex,
              private,
              created,
            ],
            distinct: true,
            where: where,
            whereArgs: whereArgs,
            orderBy: '$created DESC');
      }

      debugPrint(
          '******************** TableRatchetKeyReceiver.fetchKeys db read end time: ${DateTime.now()}');

      List<RatchetKey> retValue = [];
      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);
        retValue.add(ratchetKey);
      }

      debugPrint(
          '******************** TableRatchetKeyReceiver.fetchKeys json conversion end time: ${DateTime.now()}');

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.fetchKeysFoUser: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> fetchKeysForUser(
      String tableName, String userID, DateTime lastKeychainBackup) async {
    try {
      database = await DatabaseProvider.db.database;

      String where;
      List whereArgs;

      where = "$user=? AND ($created > ? OR $created is null)";
      whereArgs = [userID, lastKeychainBackup.millisecondsSinceEpoch];

      List<Map> results = await database!.query(tableName,
          columns: [
            keyIndex,
            private,
            created,
          ],
          distinct: true,
          where: where,
          whereArgs: whereArgs,
          orderBy: '$created DESC');

      List<RatchetKey> retValue = [];
      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);
        retValue.add(ratchetKey);
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.fetchKeysFoUser: $err');
      rethrow;
    }
  }

  static Future<int> deleteByUser(String tableName, String userID) async {
    database = await DatabaseProvider.db.database;

    int records = await database!
        .delete(tableName, where: '$user = ?', whereArgs: [userID]);

    debugPrint('TableRatchetKeyHelper.deleteByUser: $records');

    return records;
  }

  static Future<List<CircleObject>> fetchKeysByCircle(
    String tableName,
    String userID,
    List<CircleObject> circleObjects,
  ) async {
    try {
      database = await DatabaseProvider.db.database;

      List<String> ratchetIndexes = [];

      for (CircleObject circleObject in circleObjects) {
        for (RatchetIndex ratchetIndex in circleObject.ratchetIndexes) {
          if (ratchetIndex.user == userID) {
            if (!ratchetIndexes.contains(ratchetIndex.ratchetIndex)) {
              ratchetIndexes.add(ratchetIndex.ratchetIndex);
            }
          }
        }
      }

      if (ratchetIndexes.isEmpty) return circleObjects;

      String where =
          '$keyIndex IN (${ratchetIndexes.map((e) => "'$e'").join(', ')})';

      List<Map> results = await database!.query(
        tableName,
        columns: [
          pk,
          keyIndex,
          public,
          private,
          device,
          userCircle,
          user,
          created,
          lastUpdate
        ],
        where: where,
      );

      List<RatchetKey> ratchetKeys = [];
      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);

        ratchetKeys.add(ratchetKey);
      }

      ///add the results to the circleobjects
      for (CircleObject circleObject in circleObjects) {
        for (RatchetIndex ratchetIndex in circleObject.ratchetIndexes) {
          for (RatchetKey ratchetKey in ratchetKeys) {
            if (ratchetKey.keyIndex == ratchetIndex.ratchetIndex) {
              circleObject.ratchetPair = RatchetPair(
                  ratchetIndex: ratchetIndex, ratchetKey: ratchetKey);
              break;
            }
          }
        }
      }

      ///Mitigate against objects with no ratchet pairs
      List<CircleObject> noRatchetPair = circleObjects
          .where((element) => (element.ratchetPair == null &&
              element.type != CircleObjectType.SYSTEMMESSAGE))
          .toList();

      ///manually grab the ratchets for these objects
      for (CircleObject circleObject in noRatchetPair) {
        try {
          LogBloc.postLog(
              'SQL query did not find ratchet pair for this object. Searching manually\nid: ${circleObject.id}\nuser: $userID\nbody: ${circleObject.body}\nencryptedBody: ${circleObject.encryptedBody}\npublicKey: ${circleObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(circleObject.ratchetIndexes)}}',
              'fetchKeysByCircle');

          bool found = false;
          for (RatchetIndex ratchetIndex in circleObject.ratchetIndexes) {
            RatchetKey ratchetKey =
                await findByKeyIndex(tableName, ratchetIndex.ratchetIndex);
            if (ratchetKey.keyIndex.isNotEmpty) {
              circleObject.ratchetPair = RatchetPair(
                  ratchetIndex: ratchetIndex, ratchetKey: ratchetKey);
              found = true;
              break;
            }
          }
          if (found == false) {
            LogBloc.postLog(
                'SQL query second attempt did not find ratchet pair for this object.\nid: ${circleObject.id}\nuser: $userID\nbody: ${circleObject.body}\nencryptedBody: ${circleObject.encryptedBody}\npublicKey: ${circleObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(circleObject.ratchetIndexes)}}',
                'fetchKeysByCircle');
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }

    return circleObjects;
  }

  static Future<List<ReplyObject>> fetchReplyKeysByCircle(
    String tableName,
    String userID,
    List<ReplyObject> replyObjects,
  ) async {
    try {
      database = await DatabaseProvider.db.database;

      List<String> ratchetIndexes = [];

      for (ReplyObject replyObject in replyObjects) {
        for (RatchetIndex ratchetIndex in replyObject.ratchetIndexes) {
          if (ratchetIndex.user == userID) {
            if (!ratchetIndexes.contains(ratchetIndex.ratchetIndex)) {
              ratchetIndexes.add(ratchetIndex.ratchetIndex);
            }
          }
        }
      }

      if (ratchetIndexes.isEmpty) return replyObjects;

      String where =
          '$keyIndex IN (${ratchetIndexes.map((e) => "'$e'").join(', ')})';

      List<Map> results = await database!.query(
        tableName,
        columns: [
          pk,
          keyIndex,
          public,
          private,
          device,
          userCircle,
          user,
          created,
          lastUpdate
        ],
        where: where,
      );

      List<RatchetKey> ratchetKeys = [];
      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);

        ratchetKeys.add(ratchetKey);
      }

      ///add the results to the replyobjects
      for (ReplyObject replyObject in replyObjects) {
        for (RatchetIndex ratchetIndex in replyObject.ratchetIndexes) {
          for (RatchetKey ratchetKey in ratchetKeys) {
            if (ratchetKey.keyIndex == ratchetIndex.ratchetIndex) {
              replyObject.ratchetPair = RatchetPair(
                  ratchetIndex: ratchetIndex, ratchetKey: ratchetKey);
              break;
            }
          }
        }
      }

      ///Mitigate against objects with no ratchet pairs
      List<ReplyObject> noRatchetPair = replyObjects
          .where((element) => (element.ratchetPair == null &&
              element.type != CircleObjectType.SYSTEMMESSAGE))
          .toList();

      ///manually grab the ratchets for these objects
      for (ReplyObject replyObject in noRatchetPair) {
        try {
          LogBloc.postLog(
              //\nencryptedBody: ${replyObject.encryptedBody}'
              'SQL query did not find ratchet pair for this object. Searching manually\nid: ${replyObject.id}\nuser: $userID\nbody: ${replyObject.body}'
                  '\npublicKey: ${replyObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(replyObject.ratchetIndexes)}}',
              'fetchKeysByCircle');

          bool found = false;
          for (RatchetIndex ratchetIndex in replyObject.ratchetIndexes) {
            RatchetKey ratchetKey =
                await findByKeyIndex(tableName, ratchetIndex.ratchetIndex);
            if (ratchetKey.keyIndex.isNotEmpty) {
              replyObject.ratchetPair = RatchetPair(
                  ratchetIndex: ratchetIndex, ratchetKey: ratchetKey);
              found = true;
              break;
            }
          }
          if (found == false) {
            LogBloc.postLog(

                ///\nencryptedBody: ${replyObject.encryptedBody}
                'SQL query second attempt did not find ratchet pair for this object.\nid: ${replyObject.id}\nuser: $userID\nbody: ${replyObject.body}'
                    '\npublicKey: ${replyObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(replyObject.ratchetIndexes)}}',
                'fetchKeysByCircle');
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
    return replyObjects;
  }

  static Future<List<RatchetKey>> findByKeysByIndex(
      String tableName, String pKeyIndex) async {
    database = await DatabaseProvider.db.database;

    List<RatchetKey> retValue = [];

    try {
      String where = '$keyIndex = ?';

      List<Map> results = await database!.query(tableName,
          columns: [
            pk,
            keyIndex,
            public,
            private,
            device,
            userCircle,
            user,
            created,
            lastUpdate
          ],
          where: where,
          whereArgs: [pKeyIndex]);

      for (var row in results) {
        retValue.add(RatchetKey.fromJsonSQL(row as Map<String, dynamic>));
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.findRatchetPair: $err');
      rethrow;
    }

    return retValue;
  }

  static Future<RatchetKey> findByKeyIndex(
      String tableName, String pKeyIndex) async {
    database = await DatabaseProvider.db.database;

    RatchetKey retValue = RatchetKey.blank();

    try {
      String where = '$keyIndex = ?';

      List<Map> results = await database!.query(tableName,
          columns: [
            pk,
            keyIndex,
            public,
            private,
            device,
            userCircle,
            user,
            created,
            lastUpdate
          ],
          where: where,
          whereArgs: [pKeyIndex]);

      if (results.isNotEmpty) {
        retValue = RatchetKey.fromJsonSQL(results[0] as Map<String, dynamic>);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.findRatchetPair: $err');
      rethrow;
    }

    return retValue;
  }

  static Future<List<RatchetKey>> findRatchetKeysByIndex(
      String tableName, String pKeyIndex) async {
    database = await DatabaseProvider.db.database;

    List<RatchetKey> retValue = [];

    try {
      String where = '$keyIndex = ?';

      List<Map> results = await database!.query(tableName,
          columns: [
            pk,
            keyIndex,
            public,
            private,
            device,
            userCircle,
            user,
            created,
            lastUpdate
          ],
          where: where,
          whereArgs: [pKeyIndex]);

      for (var result in results) {
        retValue.add(RatchetKey.fromJsonSQL(result as Map<String, dynamic>));
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.findRatchetPair: $err');
      rethrow;
    }

    return retValue;
  }

  static Future<List<RatchetKey>> findRatchetKeysForAllUsers(
      String tableName) async {
    database = await DatabaseProvider.db.database;

    List<RatchetKey> retValue = [];

    try {
      List<Map> results = await database!.query(
        tableName,
        columns: [
          pk,
          keyIndex,
          public,
          private,
          device,
          userCircle,
          user,
          created,
          lastUpdate
        ],
      );

      for (var result in results) {
        retValue.add(RatchetKey.fromJsonSQL(result as Map<String, dynamic>));
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.findRatchetPair: $err');
      rethrow;
    }

    return retValue;
  }

  static Future<RatchetPair> findRatchetPair(
      String tableName, List<RatchetIndex> keyIndexes) async {
    database = await DatabaseProvider.db.database;

    //Iterable<RatchetKey> list = [];
    List<String> whereArgs = [];
    List<RatchetKey> ratchetKeys = [];

    //String where = "$keyIndex in ?";
    RatchetPair retValue = RatchetPair.blank();

    try {
      // debugPrint('wtf');
      debugPrint('findRatchetPair keyIndex.length: ${keyIndexes.length}');

      //find the index
      for (RatchetIndex ratchetIndex in keyIndexes) {
        whereArgs.add(ratchetIndex.ratchetIndex);
      }

      String where =
          '$keyIndex IN (${whereArgs.map((e) => "'$e'").join(', ')})';

      List<Map> results = await database!.query(tableName,
          columns: [
            pk,
            keyIndex,
            public,
            private,
            device,
            userCircle,
            user,
            created,
            lastUpdate
          ],
          where: where,
          limit: 1,
          orderBy: '$pk DESC');

      ///should grab the latest in the event of a conflict
      //whereArgs: whereArgs);

      for (var result in results) {
        RatchetKey ratchetKey =
            RatchetKey.fromJsonSQL(result as Map<String, dynamic>);
        ratchetKeys.add(ratchetKey);
      }

      ///In the event that the user has a bunch of userkeys that have all been added to the receiving keychain, this should pull the very last record.
      for (RatchetKey ratchetKey in ratchetKeys) {
        for (RatchetIndex ratchetIndex in keyIndexes) {
          if (ratchetKey.keyIndex == ratchetIndex.ratchetIndex) {
            //match found
            retValue.ratchetKey = ratchetKey;
            retValue.ratchetIndex = ratchetIndex;

            //return retValue;
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyHelper.findRatchetPair: $err');
      rethrow;
    }

    return retValue;
  }

  static Future<void> bulkInsert(
      String tableName, List<RatchetKey> keys) async {
    database = await DatabaseProvider.db.database;

    try {
      var batch = database!.batch();

      int counter = 1;

      if (tableName == TableRatchetKeyUser.tableName) {
        for (RatchetKey ratchetKey in keys) {
          var count = Sqflite.firstIntValue(await database!.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $keyIndex = ?',
              [ratchetKey.keyIndex]));

          debugPrint(
              'Database counter: ${counter.toString()} of ${keys.length}');
          counter = counter + 1;

          if (count == 0) {
            batch.insert(tableName, ratchetKey.toJsonSQL());
          } else {
            List<RatchetKey> existingRatchetKeys =
                await findByKeysByIndex(tableName, ratchetKey.keyIndex);

            bool found = false;

            for (RatchetKey existingKey in existingRatchetKeys) {
              if (existingKey.private == ratchetKey.private) {
                found = true;
              }
            }

            if (!found) {
              debugPrint(
                  'PRIVATE KEYS DO NOT MATCH: keyIndex: ${ratchetKey.keyIndex} newPrivate: ${ratchetKey.private}');

              batch.insert(tableName, ratchetKey.toJsonSQL());
            }
          }
        }
      } else {
        for (RatchetKey ratchetKey in keys) {
          batch.insert(
            tableName,
            ratchetKey.toJsonSQL(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(
        noResult: true,
        continueOnError: true,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableRatchetKeyHelper.upsert: $err");
      rethrow;
    }

    return;
  }

  static Future<int> deleteAll(String tableName) async {
    database = await DatabaseProvider.db.database;

    return await database!.delete(
      tableName,
    );
  }

  static Future<int> insert(String tableName, RatchetKey ratchetKey) async {
    database = await DatabaseProvider.db.database;

    try {
      return await database!.insert(tableName, ratchetKey.toJsonSQL(),
          conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<void> upsert(String tableName, RatchetKey ratchetKey) async {
    database = await DatabaseProvider.db.database;

    try {
      //debugPrint('break');
      var count = Sqflite.firstIntValue(await database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $keyIndex = ?',
          [ratchetKey.keyIndex]));

      //Map<String, dynamic> test = ratchetKey.toJsonSQL();

      if (count == 0) {
        await database!.insert(tableName, ratchetKey.toJsonSQL());
      } else {
        //Todo can't see a scenario when a key will be updated, only inserted
        await database!.update(tableName, ratchetKey.toJsonSQL(),
            where: "$keyIndex = ?", whereArgs: [ratchetKey.keyIndex]);
        LogBloc.insertLog(
            'TableRatchetKeyHelper.upsert did an upsert instead of an insert. Table: $tableName',
            'Updated keyIndex: ${ratchetKey.keyIndex}');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableRatchetKeyHelper.upsert: $err");
      rethrow;
    }

    return;
  }

  static Future<RatchetKey> getLatestKeyPair(
      String tableName, String userID) async {
    RatchetKey ratchetKey = RatchetKey.blank();
    database = await DatabaseProvider.db.database;

    List<Map> results = await database!.query(
      tableName,
      columns: [
        pk,
        keyIndex,
        public,
        private,
        device,
        userCircle,
        user,
        created,
        lastUpdate
      ],
      where: '$user = ?',
      whereArgs: [userID],
      orderBy: '$pk DESC',
      //limit: 1,
    );

    //should only be one
    if (results.length > 1)
      debugPrint('THERE ARE TWO PUBLIC KEYS FOR THIS USER');

    if (results.isNotEmpty)
      ratchetKey = RatchetKey.fromJsonSQL(results[0] as Map<String, dynamic>);

    /*
    results.forEach((result) {

      ratchetKey = RatchetKey.fromJsonSQL(result as Map<String, dynamic>);

    });

     */

    //debugPrint('break');
    return ratchetKey;
  }

  static Future<RatchetKey> getKeyPairByTypeAndDevice(String tableName,
      String userID, RatchetKeyType keyType, String device) async {
    RatchetKey ratchetKey = RatchetKey.blank();
    database = await DatabaseProvider.db.database;

    List<Map> results = await database!.query(
      tableName,
      columns: [
        pk,
        keyIndex,
        public,
        private,
        device,
        type,
        userCircle,
        user,
        created,
        lastUpdate
      ],
      where: '$user = ? AND $type = ? AND $device = ?',
      whereArgs: [userID, keyType.index, device],
      orderBy: '$pk DESC',
      //limit: 1,
    );

    ///should only be one
    if (results.length > 1)
      LogBloc.insertLog(
          'THERE ARE TWO type: $keyType KEYS FOR THIS USER: $userID AND THIS DEVICE: $device',
          'getKeyPairByTypeAndDevice');

    if (results.isNotEmpty)
      ratchetKey = RatchetKey.fromJsonSQL(results[0] as Map<String, dynamic>);
    return ratchetKey;
  }

  static Future<RatchetKey> getKeyPairByType(
      String tableName, String pUserID, RatchetKeyType keyType) async {
    RatchetKey ratchetKey = RatchetKey.blank();
    database = await DatabaseProvider.db.database;

    List<Map> results = await database!.query(
      tableName,
      columns: [
        pk,
        keyIndex,
        public,
        private,
        device,
        type,
        userCircle,
        user,
        created,
        lastUpdate
      ],
      where: '$user = ? AND $type = ?',
      whereArgs: [pUserID, keyType.index],
      orderBy: '$pk DESC',
      //limit: 1,
    );

    ///needed to support legacy keys with no type
    if (results.isEmpty && keyType == RatchetKeyType.user) {
      results = await database!.query(
        tableName,
        columns: [
          pk,
          keyIndex,
          public,
          private,
          device,
          type,
          userCircle,
          user,
          created,
          lastUpdate
        ],
        where: '$user = ? AND $type IS NULL',

        ///type of null will make sure signature keys are not returned
        whereArgs: [pUserID],
        orderBy: '$pk DESC',
        //limit: 1,
      );
    }

    ///should only be one
    if (results.length > 1)
      LogBloc.insertLog(
          'THERE ARE TWO type: $keyType KEYS FOR THIS USER: $pUserID',
          'getKeyPairByType');

    if (results.isNotEmpty)
      ratchetKey = RatchetKey.fromJsonSQL(results[0] as Map<String, dynamic>);
    return ratchetKey;
  }

  static Future<bool> keysMissing(
      String tableName, String userID, String userCircleID) async {
    database = await DatabaseProvider.db.database;

    var count = Sqflite.firstIntValue(await database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $user = ? AND $userCircle = ?',
        [userID, userCircleID]));

    if (count == 0)
      return true;
    else
      return false;
  }

  static Future<void> upsertPublicKeyForPrivateKey(
      String tableName, RatchetKey ratchetKey) async {
    database = await DatabaseProvider.db.database;

    try {
      //debugPrint('break');
      var count = Sqflite.firstIntValue(await database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $keyIndex = ?',
          [ratchetKey.keyIndex]));

      Map<String, dynamic> map = {
        public: ratchetKey.public,
      };

      if (count == 0) {
        await database!.insert(tableName, ratchetKey.toJsonSQL());
      } else {
        //Todo can't see a scenario when a key will be updated, only inserted
        database!.update(tableName, map,
            where: "$private = ?", whereArgs: [ratchetKey.private]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableRatchetKeyHelper.upsert: $err");
      rethrow;
    }

    return;
  }

/*static Future<void> oneTimeFix(
      String tableName, RatchetKey ratchetKey) async {
    database = await DatabaseProvider.db.database;
    try {
      Map<String, dynamic> map = {
        keyIndex: ratchetKey.keyIndex,
        private: ratchetKey.private,
        public: ratchetKey.public,
      };
      database!.update(tableName, map, where: "$pk = ?", whereArgs: [3]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableRatchetKeyHelper.upsert: $err");
      throw (err);
    }
    return;
  }*/
}
