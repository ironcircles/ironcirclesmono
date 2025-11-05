import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/models/usercircleenvelopecontents.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableUserCircleEnvelope {
  static const String tableName = 'usercircleenvelope';
  static const String pk = "pk";
  static const String userCircle = "userCircle";
  static const String circle = "circle";
  static const String user = "user";
  static const String contents = "contents";

  //static final String jwt= "token";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$userCircle TEXT UNIQUE,"
      "$circle TEXT,"
      "$user TEXT,"
      "$contents TEXT)";

  static Database? _database;

  TableUserCircleEnvelope._();

  static Future<UserCircleEnvelope> upsert(
      UserCircleEnvelope userCircleEnvelope) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userCircle = ? AND $user = ?',
          [userCircleEnvelope.userCircle, userCircleEnvelope.user]));

      if (count == 0) {
        //the pk might be set from another device
        userCircleEnvelope.pk = null;

        userCircleEnvelope.pk =
            await _database!.insert(tableName, userCircleEnvelope.toJson());
      } else {
        await _database!.update(tableName, userCircleEnvelope.toJson(),
            where: "$userCircle = ? AND $user= ?",
            whereArgs: [
              userCircleEnvelope.userCircle,
              userCircleEnvelope.user
            ]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleEnvelope.upsert: $err");
      rethrow;
    }

    return userCircleEnvelope;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> deleteByID(String userCircleID, String userID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(tableName,
        where: '$userCircle = ? AND $user = ?',
        whereArgs: [userCircleID, userID]);
  }

  static Future<UserCircleEnvelope> get(
      String userCircleID, String userID) async {
    UserCircleEnvelope retValue = UserCircleEnvelope(
        user: userID,
        userCircle: userCircleID,
        contents: UserCircleEnvelopeContents(circleName: '', prefName: ''));

    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(tableName,
          columns: [
            pk,
            userCircle,
            circle,
            user,
            contents,
          ],
          where: "$userCircle = ?  AND $user = ?",
          whereArgs: [userCircleID, userID]);
      //orderBy: "$lastItemUpdate DESC");

      if (results.isNotEmpty) {
        retValue =
            UserCircleEnvelope.fromJson(results.first as Map<String, dynamic>);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('TableUserCircleEnvelope.read: $err');
      rethrow;
    }

    return retValue;
  }
}
