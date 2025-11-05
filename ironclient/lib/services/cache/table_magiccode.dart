import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/magiccode.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableMagicCode {
  static const String tableName = 'magiccodes';
  static const String pk = "pk";
  static const String userFurnaceKey = "userFurnaceKey";
  static const String code = "code";
  static const String type = "type";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$userFurnaceKey INT,"
      "$code TEXT,"
      "$type INT)";

  static Database? _database;

  TableMagicCode._();

  static Future<void> insert(MagicCode magicCode) async {
    _database = await DatabaseProvider.db.database;

    //Map map = {userFurnaceKey: pUserFurnaceKey, magicCode: magicCode, };

    try {
      await _database!.insert(tableName, magicCode.toJson());
    } catch (error) {
      debugPrint('table_log.insert: ${error.toString}');
    }

    return;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<List<MagicCode>> readByCode(String pCode) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        userFurnaceKey,
        code,
        type,
      ],
      where: "$code = ?",
      whereArgs: [pCode],
    );

    List<MagicCode> collection = [];
    results.forEach((result) {
      MagicCode individual = MagicCode.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }
}
