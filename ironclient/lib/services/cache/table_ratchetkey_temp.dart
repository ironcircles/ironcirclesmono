

/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';

class TableRatchetKeyTemp {
  static const String tableName = 'tempKeys';
  static const String pk = "pk";
  static const String keyIndex = "keyIndex";
  static const String public = "public";
  static const String private = "private";
  static const String device = "device";
  static const String userCircle = "userCircle";
  static const String user = "user";
  static const String type = "type";
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$keyIndex TEXT, "
      "$public TEXT, "
      "$private TEXT, "
      "$device TEXT, "
      "$userCircle TEXT, "
      "$type INT,"
      "$user TEXT, "
      "$lastUpdate INT,"
      "$created INT)";
  //"$created INTEGER DEFAULT (cast(strftime('%s','now') as int)))";

  //static Database? _database;

  TableRatchetKeyTemp._();

  /*
  static Future<List<RatchetKey>> fetchKeysForUser(
      String userID, List<UserCircleCache> userCircleCaches) async {
    try {
      return TableRatchetKeyHelper.fetchKeysForUser(
        tableName,
        userID,
      );
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.fetchKeysForUser: $err');
      throw (err);
    }
  }

   */

  static Future<RatchetPair> findRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return TableRatchetKeyHelper.findRatchetPair(tableName, keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyTemp.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<void> bulkInsert(List<RatchetKey> ratchetKeys) async {
    try {
      await TableRatchetKeyHelper.bulkInsert(tableName, ratchetKeys);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyTemp.upsert: $err');
      rethrow;
    }
  }

  static Future<void> upsert(RatchetKey ratchetKey) async {
    try {
      await TableRatchetKeyHelper.upsert(tableName, ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyTemp.upsert: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> getLatestKeyPair(String userID) async {
    try {
      return await TableRatchetKeyHelper.getLatestKeyPair(tableName, userID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyTemp.getLatestKeyPair: $err');
      rethrow;
    }
  }
}

 */
