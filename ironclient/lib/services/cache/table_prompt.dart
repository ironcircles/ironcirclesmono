import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TablePrompt {
  static const String tableName = 'prompt';
  static const String pk = "pk";
  static const String id = "id";
  static const String userID = "userID";
  static const String jobID = "jobID";
  static const String prompt = "prompt";
  static const String maskPrompt = "maskPrompt";
  static const String negativePrompt = "negativePrompt";
  static const String promptType = "promptType";
  static const String model = "model";
  static const String guidance = "guidance";
  static const String steps = "steps";
  static const String seed = "seed";
  static const String sampler = "sampler";
  static const String loraOne = "loraOne";
  static const String upscale = "upscale";
  static const String loraTwo = "loraTwo";
  static const String loraOneStrength = "loraOneStrength";
  static const String loraTwoStrength = "loraTwoStrength";
  static const String width = "width";
  static const String height = "height";

  static const String created = "created";

  static List<String> selectColumns = [
    pk,
    id,
    userID,
    jobID,
    prompt,
    maskPrompt,
    negativePrompt,
    model,
    guidance,
    seed,
    sampler,
    steps,
    loraOne,
    loraTwo,
    loraOneStrength,
    loraTwoStrength,
    width,
    height,
    upscale,
    promptType,
    created,
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT,"
      "$userID TEXT,"
      "$jobID TEXT,"
      "$prompt TEXT,"
      "$maskPrompt TEXT,"
      "$negativePrompt TEXT,"
      "$model TEXT,"
      "$guidance REAL,"
      "$seed INT,"
      "$steps INT,"
      "$sampler TEXT,"
      "$loraOne TEXT,"
      "$loraTwo TEXT,"
      "$loraOneStrength REAL,"
      "$loraTwoStrength REAL,"
      "$width INT,"
      "$height INT,"
      "$upscale INT,"
      "$promptType INT,"
      "$created INT)";

  static Database? _database;

  TablePrompt._();

  static Future<void> insert(StableDiffusionPrompt prompt) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.insert(tableName, prompt.toJson());
    } catch (error) {
      debugPrint('table_log.insert: ${error.toString}');

      rethrow;
    }

    return;
  }

  static Future<StableDiffusionPrompt> upsert(
      StableDiffusionPrompt stableDiffusionPrompt) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?',
          [stableDiffusionPrompt.id]));

      if (count == 0) {
        await _database!.insert(tableName, stableDiffusionPrompt.toJson());
      } else {
        await _database!.update(tableName, stableDiffusionPrompt.toJson(),
            where: "$id = ?", whereArgs: [stableDiffusionPrompt.id]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return stableDiffusionPrompt;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    int records = await _database!.delete(
      tableName,
    );

    return records;
  }

  static Future<int> delete(StableDiffusionPrompt prompt) async {
    _database = await DatabaseProvider.db.database;

    String where = "$id = ?";

    int records = await _database!.delete(
      tableName,
      where: where,
      whereArgs: [
        prompt.id,
      ],
    );

    return records;
  }

  static Future<List<StableDiffusionPrompt>> readHistory(
      List<String> userIDs, int amount, PromptType pPromptType) async {
    _database = await DatabaseProvider.db.database;



    String where = '$userID IN (${userIDs.map((e) => "'$e'").join(', ')})';
    where += " and $promptType = ?";

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: [
          pPromptType.index,
        ],
        orderBy: "$created DESC",
        limit: amount);

    List<StableDiffusionPrompt> collection = [];
    for (var result in results) {
      StableDiffusionPrompt individual =
          StableDiffusionPrompt.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    }

    return collection;
  }
}
