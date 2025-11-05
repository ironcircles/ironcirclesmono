import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/usersetting.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableUserSetting {
  static const String tableName = 'usersetting';
  static const String pk = "pk";
  static const String id = "id";
  static const String username = "username";
  static const String accountType = "accountType";
  static const String theme = "theme";
  static const String lastColorIndex = "lastColorIndex";
  static const String fontSize = "fontSize";
  static const String unreadFeedOn = "unreadFeedOn";
  static const String accountRecovery = "accountRecovery";
  static const String allowHidden = "allowHidden";
  static const String submitLogs = "submitLogs";
  static const String autoKeychainBackup = "autoKeychainBackup";
  static const String backupKey = "backupKey";
  static const String minor = "minor";
  static const String reservedUsername = "reservedUsername";
  static const String passwordHelpersSet = "passwordHelpersSet";
  static const String lastLogSubmission = "lastLogSubmission";
  static const String lastSharedToNetwork = "lastSharedToNetwork";
  static const String lastSharedToCircle = "lastSharedToCircle";
  static const String allowLastSharedToCircle = "allowLastSharedToCircle";
  static const String lastAccessedDate = "lastAccessedDate";
  static const String passwordBeforeChange = "passwordBeforeChange";
  static const String askedToGuardVault = "askedToGuardVault";
  static const String firstTimeInCircle = "firstTimeInCircle";
  static const String firstTimeInFeed = "firstTimeInFeed";
  static const String lastIncremental = "lastIncremental";
  static const String lastFull = "lastFull";
  static const String patternPinString = "patternPinString";
  static const String attempts = "attempts";
  static const String lastAttempt = "lastAttempt";
  static const String ironCoin = "ironCoin";
  static const String sortAlpha = "sortAlpha";

  static List<String> selectColumns = [
    pk,
    id,
    username,
    accountType,
    theme,
    lastColorIndex,
    fontSize,
    unreadFeedOn,
    allowHidden,
    submitLogs,
    lastAccessedDate,
    autoKeychainBackup,
    backupKey,
    passwordBeforeChange,
    minor,
    askedToGuardVault,
    reservedUsername,
    accountRecovery,
    passwordHelpersSet,
    lastLogSubmission,
    lastSharedToNetwork,
    lastSharedToCircle,
    lastIncremental,
    lastFull,
    allowLastSharedToCircle,
    firstTimeInCircle,
    patternPinString,
    attempts,
    lastAttempt,
    firstTimeInFeed,
    ironCoin,
    sortAlpha
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT,"
      "$username TEXT,"
      "$accountType INT,"
      "$theme INT,"
      "$lastColorIndex INT,"
      "$fontSize REAL,"
      "$unreadFeedOn INT,"
      "$allowHidden INT,"
      "$submitLogs INT,"
      "$autoKeychainBackup INT,"
      "$backupKey TEXT,"
      "$passwordBeforeChange INT,"
      "$minor INT,"
      "$askedToGuardVault INT,"
      "$firstTimeInCircle INT,"
      "$firstTimeInFeed INT,"
      "$reservedUsername INT,"
      "$passwordHelpersSet INT,"
      "$lastLogSubmission INT,"
      "$lastSharedToNetwork TEXT,"
      "$accountRecovery INT,"
      "$lastSharedToCircle TEXT,"
      "$lastIncremental INT,"
      "$lastFull INT,"
      "$allowLastSharedToCircle INT,"
      "$patternPinString TEXT,"
      "$attempts INT,"
      "$lastAttempt INT,"
      "$lastAccessedDate INT,"
      "$sortAlpha INT,"
      "$ironCoin INT"
      ")";

  static Database? _database;

  TableUserSetting._();

  static Future<UserSetting?> read(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
      where: "$id = ?",
      whereArgs: [pUserID],
      orderBy: "$lastAccessedDate DESC",
    );

    if (results.isNotEmpty) {
      UserSetting retValue =
          UserSetting.fromJson(results.first as Map<String, dynamic>);
      if (results.length > 1)
        LogBloc.insertLog(
            'Duplicate User Setting: ${retValue.id}', 'TableUserSetting');
      return retValue;
    } else {
      LogBloc.insertLog(
          'UserSetting not found: $pUserID', 'TableUserSetting.read');
    }

    return null;
  }

  static Future<UserSetting> upsertReducedMap(
      UserSetting userSetting, Map<String, dynamic> reducedMap) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?', [userSetting.id]));

      if (count == 0) {
        LogBloc.insertLog(
            "Could not find UserSetting to update", "upsertReducedMap");
      } else {
        await _database!.update(tableName, reducedMap,
            where: "$id = ?", whereArgs: [userSetting.id]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return userSetting;
  }

  static Future<void> setBackupKey(String userID, String pBackupKey) async {
    _database = await DatabaseProvider.db.database;

    Map<String, dynamic> reducedMap = {TableUserSetting.backupKey: pBackupKey};

    try {
      var count = Sqflite.firstIntValue(await _database!
          .rawQuery('SELECT COUNT(*) FROM $tableName WHERE $id = ?', [userID]));

      if (count == 0) {
        await _database!.insert(tableName, reducedMap);
      } else {
        await _database!.update(tableName, reducedMap,
            where: "$id = ?", whereArgs: [userID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return;
  }

  static Future<UserSetting> upsert(UserSetting userSetting) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?', [userSetting.id]));

      if (count == 0) {
        await _database!.insert(tableName, userSetting.toJson());
      } else {
        await _database!.update(tableName, userSetting.toJson(),
            where: "$id = ?", whereArgs: [userSetting.id]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return userSetting;
  }

  Future<int> delete(UserSetting userSetting) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$id = ?', whereArgs: [userSetting.id]);
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }
}
