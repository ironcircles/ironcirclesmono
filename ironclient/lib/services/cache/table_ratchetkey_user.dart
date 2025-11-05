import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';

class TableRatchetKeyUser {
  static const String tableName = 'userKeys';
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
      "$user TEXT, "
      "$type INT,"
      "$lastUpdate INT,"
      "$created INT)";

  TableRatchetKeyUser._();

  ///TODO Recipe and List Templates will break if there are duplicate user keys, this function should go away and be replaced with findRatchetKeysByIndex
  static Future<RatchetPair> findRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return TableRatchetKeyHelper.findRatchetPair(tableName, keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<int> countRecords() async {

    return await TableRatchetKeyHelper.countRecords(
        tableName);
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

  static Future<List<RatchetKey>> findRatchetKeysForAllUsers() async {
    try {
      return await TableRatchetKeyHelper.findRatchetKeysForAllUsers(tableName);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<void> bulkInsert(List<RatchetKey> ratchetKeys) async {
    try {
      await TableRatchetKeyHelper.bulkInsert(tableName, ratchetKeys);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
  }

  static Future<void> upsert(RatchetKey ratchetKey) async {
    try {
      await TableRatchetKeyHelper.upsert(tableName, ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
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

  static Future<void> deleteByUser(String userID) async {
    try {
      await TableRatchetKeyHelper.deleteByUser(tableName, userID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
  }


  static Future<RatchetKey> getKeyPairByType(String userID, RatchetKeyType keyType) async {
    try {
      return await TableRatchetKeyHelper.getKeyPairByType(
          tableName, userID, keyType);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.getKeyPairByType: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> getKeyPairByTypeAndDevice(String userID, RatchetKeyType keyType, String device) async {
    try {
      return await TableRatchetKeyHelper.getKeyPairByTypeAndDevice(
          tableName, userID, keyType, device);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.getKeyPairByType: $err');
      rethrow;
    }
  }
}
