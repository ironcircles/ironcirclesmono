import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/log.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableLog {
  static const String tableName = 'log';
  static const String pk = "pk";
  static const String user = "user";
  static const String circle = "circle";
  static const String device = "device";
  static const String type = "type";
  static const String message = "message";
  static const String stack = "stack";
  static const String timeStamp = "timeStamp";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$user TEXT,"
      "$circle TEXT,"
      "$device TEXT,"
      "$type TEXT,"
      "$message TEXT,"
      "$stack TEXT,"
      "$timeStamp INT)";

  static Database? _database;

  TableLog._();

  static Future<void> insert(Log logEntry) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.insert(tableName, logEntry.toJsonSQL());
    } catch (error) {
      debugPrint('table_log.insert: ${error.toString}');
    }

    return;
  }

  static Future<int> countRecords() async {

    var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName'));

    return count!;
  }

  static Future<int> deleteOlderThan30Days() async {
    _database = await DatabaseProvider.db.database;

    int thirtyAgo =
        DateTime.now().millisecondsSinceEpoch - (30 * 24 * 60 * 60 * 1000);

    int records = await _database!
        .delete(tableName, where: '$timeStamp < ?', whereArgs: [thirtyAgo]);

    debugPrint('deleted $records log entries');

    return records;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<List<Log>> readSinceLastSubmission(DateTime since) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        user,
        circle,
        device,
        type,
        message,
        stack,
        timeStamp,
      ],
      where: "$timeStamp > ?",
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: "$timeStamp DESC",
      limit: 500,
    );

    List<Log> collection = [];
    results.forEach((result) {
      Log individual = Log.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }

  static Future<List<Log>> readAmount(int amount) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          user,
          circle,
          device,
          type,
          message,
          stack,
          timeStamp,
        ],
        orderBy: "$timeStamp DESC",
        limit: amount);

    List<Log> collection = [];
    for (var result in results) {
      Log individual = Log.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }
}
