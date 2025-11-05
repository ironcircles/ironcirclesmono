import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';

class TableRatchetKeyReceiver {
  static const String tableName = 'receiverKeys';
  static const String pk = "pk";
  static const String keyIndex = "keyIndex";
  static const String public = "public";
  static const String private = "private";
  static const String device = "device";
  static const String type = "type";
  static const String userCircle = "userCircle";
  static const String user = "user";
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

  TableRatchetKeyReceiver._();

  static Future<int> countRecords() async {
    return await TableRatchetKeyHelper.countRecords(tableName);
  }

  static Future<int> deleteAll(String tableName) async {
    try {
      return await TableRatchetKeyHelper.deleteAll(tableName);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> findBlankPrivateKeys() async {
    try {
      return await TableRatchetKeyHelper.findBlankPrivateKeys(tableName);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.fetchKeysForUser: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> fetchKeysForUser(
      String userID,
      //List<UserCircleCache> userCircleCaches,
      DateTime lastKeychainBackup) async {
    try {
      return await TableRatchetKeyHelper.fetchKeysForUser(
          tableName, userID, lastKeychainBackup);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.fetchKeysForUser: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> fetchKeys(
      String userID,
      //List<UserCircleCache> userCircleCaches,
      DateTime lastKeychainBackup) async {
    try {
      return await TableRatchetKeyHelper.fetchKeys(
          tableName, lastKeychainBackup);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.fetchKeysForUser: $err');
      rethrow;
    }
  }

  static Future<List<CircleObject>> fetchKeysByCircle(
    String userID,
    List<CircleObject> circleObjects,
  ) async {
    try {
      return TableRatchetKeyHelper.fetchKeysByCircle(
          tableName, userID, circleObjects);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.fetchKeysByCircle: $err');
      rethrow;
    }
  }

  static Future<List<ReplyObject>> fetchReplyKeysByCircle(
    String userID,
    List<ReplyObject> replyObjects,
  ) async {
    try {
      return TableRatchetKeyHelper.fetchReplyKeysByCircle(
          tableName, userID, replyObjects);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.fetchReplyKeysByCircle: $err');
      rethrow;
    }
  }

  static Future<RatchetPair> findRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return TableRatchetKeyHelper.findRatchetPair(tableName, keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<int> insert(RatchetKey ratchetKey) async {
    try {
      return await TableRatchetKeyHelper.insert(tableName, ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.insert: $err');
      rethrow;
    }
  }

  static Future bulkInsert(List<RatchetKey> ratchetKeys) async {
    try {
      await TableRatchetKeyHelper.bulkInsert(tableName, ratchetKeys);

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyReceiver.bulkInsert: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> findRatchetKeysByIndex(String index) async {
    try {
      return await TableRatchetKeyHelper.findRatchetKeysByIndex(
          tableName, index);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<bool> keysMissing(String userID, String userCircleID) async {
    try {
      return await TableRatchetKeyHelper.keysMissing(
          tableName, userID, userCircleID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
  }
}
