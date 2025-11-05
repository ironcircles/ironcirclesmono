import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';

class TableRatchetKeySender {
  static const String tableName = 'senderKeys';
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
  TableRatchetKeySender._();

  static Future<int> deleteAll(String tableName) async {
    try {
      return await TableRatchetKeyHelper.deleteAll(tableName);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeyUser.upsert: $err');
      rethrow;
    }
  }

  static Future<Iterable<CircleObject>> fetchKeysByCircle(
    String userID,
    List<CircleObject> circleObjects,
  ) async {
    try {
      return TableRatchetKeyHelper.fetchKeysByCircle(
          tableName, userID, circleObjects);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeySender.fetchKeysByCircle: $err');
      rethrow;
    }
  }

  static Future<RatchetPair> findRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return TableRatchetKeyHelper.findRatchetPair(tableName, keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeySender.findRatchetPair: $err');
      rethrow;
    }
  }

  static Future<void> upsert(RatchetKey ratchetKey) async {
    try {
      if (ratchetKey.created == null) ratchetKey.created = DateTime.now();

      ratchetKey.lastUpdate = DateTime.now();

      await TableRatchetKeyHelper.upsert(tableName, ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableRatchetKeySender.upsert: $err');
      rethrow;
    }
  }
}
