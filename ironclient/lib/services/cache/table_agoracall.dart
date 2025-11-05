import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circleagoracall.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableAgoraCall {
  static const String tableName = 'agoracall';
  static const String pk = "pk";
  static const String channelName = "channelName";
  static const String token = "token";
  static const String agoraUserID = "agoraUserID";
  static const String active = "active";
  static const String startTime = "startTime";
  static const String endTime = "endTime";
  static const String userID = "userID";
  static const String circleID = "circleID";

  static final _columns = [
    pk,
    channelName,
    token,
    agoraUserID,
    active,
    startTime,
    endTime,
    userID,
    circleID,
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$channelName TEXT,"
      "$token TEXT,"
      "$agoraUserID INTEGER,"
      "$active BIT,"
      "$startTime INTEGER,"
      "$endTime INTEGER,"
      "$userID TEXT,"
      "$circleID TEXT)";

  static Database? _database;

  TableAgoraCall._();

  static Future<CircleAgoraCall> insert(CircleAgoraCall agoraCall, String userID, String circleID) async {
    _database = await DatabaseProvider.db.database;

    try {
      agoraCall.pk = await _database!.insert(tableName, {
        channelName: agoraCall.channelName,
        token: agoraCall.token,
        agoraUserID: agoraCall.agoraUserID,
        active: agoraCall.active ? 1 : 0,
        startTime: DateTime.now().millisecondsSinceEpoch,
        endTime: null,
        userID: userID,
        circleID: circleID,
      });

      return agoraCall;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.insert: $err");
      rethrow;
    }
  }

  static Future<CircleAgoraCall> upsert(CircleAgoraCall agoraCall, String userID, String circleID) async {
    _database = await DatabaseProvider.db.database;

    try {
      int? count = 0;

      // Try by pk
      if (agoraCall.pk != null) {
        count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $pk = ?', [agoraCall.pk]));

        if (count != 0) {
          await _database!.update(tableName, {
            channelName: agoraCall.channelName,
            token: agoraCall.token,
            agoraUserID: agoraCall.agoraUserID,
            active: agoraCall.active ? 1 : 0,
            userID: userID,
            circleID: circleID,
          }, where: "$pk = ?", whereArgs: [agoraCall.pk]);

          return agoraCall;
        }
      }

      // Try by channel and user
      count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $channelName = ? AND $userID = ? AND $active = ?',
          [agoraCall.channelName, userID, 1]));

      if (count != 0) {
        await _database!.update(tableName, {
          token: agoraCall.token,
          agoraUserID: agoraCall.agoraUserID,
          active: agoraCall.active ? 1 : 0,
        }, where: "$channelName = ? AND $userID = ? AND $active = ?",
            whereArgs: [agoraCall.channelName, userID, 1]);

        return agoraCall;
      }

      // Insert new record
      agoraCall.pk = await _database!.insert(tableName, {
        channelName: agoraCall.channelName,
        token: agoraCall.token,
        agoraUserID: agoraCall.agoraUserID,
        active: agoraCall.active ? 1 : 0,
        startTime: DateTime.now().millisecondsSinceEpoch,
        endTime: null,
        userID: userID,
        circleID: circleID,
      });

      return agoraCall;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.upsert: $err");
      rethrow;
    }
  }

  static Future<void> endCall(String channelName, String userID) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.update(tableName, {
        active: 0,
        endTime: DateTime.now().millisecondsSinceEpoch,
      }, where: "$channelName = ? AND $userID = ? AND $active = ?",
          whereArgs: [channelName, userID, 1]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.endCall: $err");
      rethrow;
    }
  }

  static Future<void> endAllActiveCallsForUser(String userID) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.update(tableName, {
        active: 0,
        endTime: DateTime.now().millisecondsSinceEpoch,
      }, where: "$userID = ? AND $active = ?", whereArgs: [userID, 1]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.endAllActiveCallsForUser: $err");
      rethrow;
    }
  }

  static Future<void> endAllActiveCallsForCircle(String circleID) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.update(tableName, {
        active: 0,
        endTime: DateTime.now().millisecondsSinceEpoch,
      }, where: "$circleID = ? AND $active = ?", whereArgs: [circleID, 1]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.endAllActiveCallsForCircle: $err");
      rethrow;
    }
  }

  static Future<CircleAgoraCall?> readActiveCall(String channelName, String userID) async {
    _database = await DatabaseProvider.db.database;

    try {
      List<Map<String, dynamic>> maps = await _database!.query(tableName,
          columns: _columns,
          where: "$channelName = ? AND $userID = ? AND $active = ?",
          whereArgs: [channelName, userID, 1]);

      if (maps.isNotEmpty) {
        return _mapToAgoraCall(maps.first);
      }
      return null;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.readActiveCall: $err");
      rethrow;
    }
  }

  static Future<List<CircleAgoraCall>> readActiveCallsForUser(String userID) async {
    _database = await DatabaseProvider.db.database;

    try {
      List<Map<String, dynamic>> results = await _database!.query(tableName,
          columns: _columns,
          where: "$userID = ? AND $active = ?",
          whereArgs: [userID, 1],
          orderBy: "$startTime DESC");

      List<CircleAgoraCall> calls = [];
      for (var result in results) {
        calls.add(_mapToAgoraCall(result));
      }

      return calls;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.readActiveCallsForUser: $err");
      rethrow;
    }
  }

  static Future<List<CircleAgoraCall>> readActiveCallsForCircle(String circleID) async {
    _database = await DatabaseProvider.db.database;

    try {
      List<Map<String, dynamic>> results = await _database!.query(tableName,
          columns: _columns,
          where: "$circleID = ? AND $active = ?",
          whereArgs: [circleID, 1],
          orderBy: "$startTime DESC");

      List<CircleAgoraCall> calls = [];
      for (var result in results) {
        calls.add(_mapToAgoraCall(result));
      }

      return calls;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.readActiveCallsForCircle: $err");
      rethrow;
    }
  }

  static Future<List<CircleAgoraCall>> readCallHistory(String userID, {int limit = 50}) async {
    _database = await DatabaseProvider.db.database;

    try {
      List<Map<String, dynamic>> results = await _database!.query(tableName,
          columns: _columns,
          where: "$userID = ?",
          whereArgs: [userID],
          orderBy: "$startTime DESC",
          limit: limit);

      List<CircleAgoraCall> calls = [];
      for (var result in results) {
        calls.add(_mapToAgoraCall(result));
      }

      return calls;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.readCallHistory: $err");
      rethrow;
    }
  }

  static Future<int> delete(int? pkToRemove) async {
    _database = await DatabaseProvider.db.database;
    return await _database!.delete(tableName, where: '$pk = ?', whereArgs: [pkToRemove]);
  }

  static Future<int> deleteAllForUser(String userID) async {
    _database = await DatabaseProvider.db.database;
    return await _database!.delete(tableName, where: '$userID = ?', whereArgs: [userID]);
  }

  static Future<int> deleteAllForCircle(String circleID) async {
    _database = await DatabaseProvider.db.database;
    return await _database!.delete(tableName, where: '$circleID = ?', whereArgs: [circleID]);
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;
    return await _database!.delete(tableName);
  }

  static CircleAgoraCall _mapToAgoraCall(Map<String, dynamic> map) {
    return CircleAgoraCall(
      channelName: map[channelName] ?? '',
      token: map[token] ?? '',
      agoraUserID: map[agoraUserID] ?? 0,
      active: map[active] == 1,
      startTime: map[startTime] != null ? DateTime.fromMillisecondsSinceEpoch(map[startTime]) : null,
      endTime: map[endTime] != null ? DateTime.fromMillisecondsSinceEpoch(map[endTime]) : null,
      userID: map[userID],
      circleID: map[circleID],
    )..pk = map[pk];
  }

  static Future<Map<String, dynamic>> getCallStats(String userID, {int days = 30}) async {
    _database = await DatabaseProvider.db.database;

    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
      
      List<Map> results = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as totalCalls,
          SUM(CASE WHEN $endTime IS NOT NULL THEN ($endTime - $startTime) ELSE 0 END) as totalDuration,
          AVG(CASE WHEN $endTime IS NOT NULL THEN ($endTime - $startTime) ELSE NULL END) as avgDuration
        FROM $tableName 
        WHERE $userID = ? AND $startTime >= ?
      ''', [userID, cutoffTime]);

      if (results.isNotEmpty) {
        return {
          'totalCalls': results.first['totalCalls'] ?? 0,
          'totalDuration': results.first['totalDuration'] ?? 0,
          'avgDuration': results.first['avgDuration'] ?? 0,
        };
      }
      
      return {
        'totalCalls': 0,
        'totalDuration': 0,
        'avgDuration': 0,
      };
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableAgoraCall.getCallStats: $err");
      rethrow;
    }
  }
} 