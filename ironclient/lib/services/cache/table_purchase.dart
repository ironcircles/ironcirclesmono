import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/purchase.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TablePurchase {
  static const String tableName = "purchase";
  static const String pk = 'pk';
  static const String id = "id";
  static const String userID = "userID";
  static const String type = "type";
  static const String transactionDate = "transactionDate";
  static const String verificationLocal = "verificationLocal";
  static const String verificationServer = "verificationServer";
  static const String verificationSource = "verificationSource";
  static const String status = "status";
  static const String purchaseID = "purchaseID";
  static const String seed = "seed";
  static const String quantity = "quantity";
  static const String purchaseDetailsJson = "purchaseDetailsJson";

  static const String columns = "CREATE TABLE $tableName ("
    "$pk INTEGER PRIMARY KEY,"
    "$id TEXT,"
    "$userID TEXT,"
    "$type TEXT,"
    "$transactionDate INT,"
    "$verificationLocal TEXT,"
    "$verificationServer TEXT,"
    "$verificationSource TEXT,"
    "$status INT,"
    "$purchaseID TEXT,"
    "$seed TEXT UNIQUE,"
    "$quantity INT,"
    "$purchaseDetailsJson TEXT)";

  static Database? _database;

  TablePurchase._();

  static Future<Purchase> upsert(Purchase purchase) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $seed = ?',
        [purchase.seed]));

      if (count == 0) {
        await _database!.insert(tableName, purchase.toJsonSQL());
      } else {
        Map<String, dynamic> map = purchase.toJsonSQL();

        await _database!.update(tableName, map,
          where: "$seed = ?", whereArgs: [purchase.seed]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TablePurchase.upsert: $err");
      rethrow;
    }

    return purchase;
  }

  static Future<List<Purchase>> readPendingForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        userID,
        type,
        transactionDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
        seed,
        quantity,
        purchaseDetailsJson,
      ],
      where: "$userID = ? AND $status = ?",
      whereArgs: [pUserID, PurchaseObjectStatus.PENDING],
      orderBy: "$transactionDate ASC",
    );

    List<Purchase> collection = [];
    results.forEach((result) {
      Purchase individual = Purchase.fromJsonSQL(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }

  static Future<List<Purchase>> readForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        userID,
        type,
        transactionDate,
        verificationLocal,
        verificationServer,
        verificationSource,
        status,
        purchaseID,
        seed,
        quantity,
        purchaseDetailsJson,
      ],
      where: "$userID = ?",
      whereArgs: [pUserID],
      orderBy: "$transactionDate ASC",
    );

    List<Purchase> collection = [];
    results.forEach((result) {
      Purchase individual =
          Purchase.fromJsonSQL(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }

  static Future<int> delete(Purchase purchase) async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(tableName, where: "$seed = ?", whereArgs: [purchase.seed]);
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(tableName);
  }
}