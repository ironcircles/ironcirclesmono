import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableSubscription {
  static const String tableName = 'subscription';
  static const String pk = "pk";
  static const String id = "id";
  static const String userID = "userID";
  static const String type = "type";
  static const String transactionDate = "transactionDate";
  static const String cancelDate = "cancelDate";
  static const String pauseDate = "pauseDate";
  static const String resumeDate = "resumeDate";
  static const String verificationLocal = "verificationLocal";
  static const String verificationServer = "verificationServer";
  static const String verificationSource = "verificationSource";
  static const String status = "status";
  static const String purchaseID = "purchaseID";
  static const String seed = "seed";
  static const String purchaseDetailsJson = "purchaseDetailsJson";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT,"
      "$seed TEXT UNIQUE,"
      "$userID TEXT,"
      "$purchaseDetailsJson TEXT,"
      "$type TEXT,"
      "$transactionDate INT,"
      "$cancelDate INT,"
      "$pauseDate INT,"
      "$resumeDate INT,"
      "$verificationLocal TEXT,"
      "$verificationServer TEXT,"
      "$verificationSource TEXT,"
      "$purchaseID TEXT,"
      "$status INT)";

  static Database? _database;

  TableSubscription._();

  static Future<Subscription> upsert(Subscription subscription) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
          [subscription.seed]));

      if (count == 0) {
        await _database!.insert(tableName, subscription.toJsonSQL());
      } else {
        Map<String, dynamic> map = subscription.toJsonSQL();

        await _database!.update(tableName, map,
            where: "$seed = ?", whereArgs: [subscription.seed]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableActionRequiredCache.upsert: $err");
      rethrow;
    }

    return subscription;
  }

  static Future<int> upsertSubscriptions(Iterable<Subscription> subscriptions) async {
    try {
      _database = await DatabaseProvider.db.database;

      var batch = _database!.batch();

      for (Subscription subscription in subscriptions) {
        //debugPrint('5: cache for loop  ${DateTime.now()}');
        try {
          var count = Sqflite.firstIntValue(await _database!.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
              [subscription.seed]));

          if (count == 0) {
            batch.insert(tableName, subscription.toJsonSQL());
          } else {
            batch.update(tableName, subscription.toJsonSQL(),
                where: "$seed = ?", whereArgs: [subscription.seed]);
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'TableSubscription.upsertSubscriptions:inner $err');
        }
      }

      var results = await batch.commit(noResult: false, continueOnError: true);

      return results.length;
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint('TableSubscription.upsertSubscriptions: $err');

      return 0;
    }
  }

  static Future<Subscription> readLatestActive(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        seed,
        userID,
        type,
        purchaseDetailsJson,
        transactionDate,
        cancelDate,
        pauseDate,
        resumeDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
      ],
      where: "$userID = ? AND $status = ?",
      whereArgs: [pUserID, SubscriptionStatus.ACTIVE],
      limit: 1,
      orderBy: "$transactionDate ASC",
    );

    Subscription first = Subscription.blank();

    if (results.length > 1)
      debugPrint('readLastestActive Subscription returned more than 1!!!!!');
    else if (results.isEmpty)
      debugPrint('readLastestActive Subscription return 0!!!!!');

    results.forEach((result) {
      first = Subscription.fromJsonSQL(result as Map<String, dynamic>);
    });

    return first;
  }

  static Future<List<Subscription>> readPendingForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        seed,
        userID,
        type,
        purchaseDetailsJson,
        transactionDate,
        cancelDate,
        pauseDate,
        resumeDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
      ],
      where: "$userID = ? AND $status = ?",
      whereArgs: [pUserID, SubscriptionStatus.PENDING],
      orderBy: "$transactionDate ASC",
    );

    List<Subscription> collection = [];
    results.forEach((result) {
      Subscription individual =
          Subscription.fromJsonSQL(result as Map<String, dynamic>);
      //individual.userFurnace = userFurnace;
      collection.add(individual);
    });

    return collection;
  }

  static Future<List<Subscription>> readForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        seed,
        userID,
        type,
        purchaseDetailsJson,
        transactionDate,
        cancelDate,
        pauseDate,
        resumeDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
      ],
      where: "$userID = ?",
      whereArgs: [pUserID],
      orderBy: "$transactionDate ASC",
    );

    List<Subscription> collection = [];
    results.forEach((result) {
      Subscription individual =
          Subscription.fromJsonSQL(result as Map<String, dynamic>);
      //individual.userFurnace = userFurnace;
      collection.add(individual);
    });

    return collection;
  }

  static Future<List<Subscription>> read(String pPurchaseID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        seed,
        userID,
        type,
        purchaseDetailsJson,
        transactionDate,
        cancelDate,
        pauseDate,
        resumeDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
      ],
      where: "$purchaseID = ?",
      whereArgs: [pPurchaseID],
      orderBy: "$transactionDate ASC",
    );

    List<Subscription> collection = [];
    results.forEach((result) {
      Subscription individual =
          Subscription.fromJsonSQL(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }
}
