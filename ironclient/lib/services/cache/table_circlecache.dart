import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableCircleCache {
  static const String tableName = 'circlecache';
  static const String pk = "pk";
  static const String id = "id";
  static const String name = "name";
  static const String type = "type";
  static const String ownershipModel = "ownershipModel";
  static const String toggleMemberPosting = "toggleMemberPosting";
  static const String toggleMemberReacting = "toggleMemberReacting";
  static const String background = "background";
  //static final String backgroundSize = "backgroundSize";
  static const String votingModel = "votingModel";
  static const String owner = "owner";
  static const String dm = "dm";
  static const String privacyShareImage = "privacyShareImage";
  static const String privacyShareURL = "privacyShareURL";
  static const String privacyShareGif = "privacyShareGif";
  static const String privacyCopyText = "privacyCopyText";
  static const String privacyVotingModel = "privacyVotingModel";
  static const String toggleEntryVote = "toggleEntryVote";
  static const String securityVotingModel = "securityVotingModel";
  static const String securityMinPassword = "securityMinPassword";
  static const String securityDaysPasswordValid = "securityDaysPasswordValid";
  static const String securityTokenExpirationDays =
      "securityTokenExpirationDays";
  static const String securityLoginAttempts = "securityLoginAttempts";
  static const String security2FA = "security2FA";
  static const String lastUpdate = "lastUpdate";
  static const String created = "created";
  static const String expiration = "expiration";
  static const String privacyDisappearingTimer = "privacyDisappearingTimer";
  static const String backgroundKey = "backgroundKey";
  static const String backgroundSignature = "backgroundSignature";
  static const String backgroundCrank = "backgroundCrank";
  static const String backgroundCipher = "backgroundCipher";
  static const String retention = "retention";

  //static final String jwt= "token";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT UNIQUE,"
      "$name TEXT,"
      "$type TEXT,"
      "$retention INT,"
      "$ownershipModel TEXT,"
      "$toggleMemberPosting BIT,"
      "$toggleMemberReacting BIT,"
      "$background TEXT,"
      "$backgroundKey TEXT," //private keys are already on this machine, no harm in storing the cipher key for invites
      "$backgroundSignature TEXT,"
      "$backgroundCrank TEXT,"
      "$backgroundCipher TEXT,"
      "$votingModel TEXT,"
      "$owner TEXT,"
      "$dm BIT,"
      "$privacyShareImage BIT,"
      "$privacyShareURL BIT,"
      "$privacyShareGif BIT,"
      "$privacyCopyText BIT,"
      "$privacyVotingModel TEXT,"
      "$toggleEntryVote BIT,"
      "$securityVotingModel TEXT,"
      "$securityMinPassword INT,"
      "$privacyDisappearingTimer INT,"
      "$securityDaysPasswordValid INT,"
      "$securityTokenExpirationDays INT,"
      "$securityLoginAttempts INT,"
      "$security2FA BIT,"
      "$lastUpdate TEXT, "
      "$expiration TEXT,"
      "$created TEXT)";

  static Database? _database;

  TableCircleCache._();

  static Future<Circle> upsert(Circle circle, {updateKey = false}) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $id = ?', [circle.id]));

      Map<String, dynamic> map = circle.toJsonSQL();

      if (!updateKey) {
        map.remove("backgroundKey");
        map.remove("backgroundSignature");
        map.remove("backgroundCrank");
        map.remove("backgroundCipher");
      }

      if (count == 0) {
        await _database!.insert(tableName, map);
      } else {
        //remove the name
        if (map.containsKey("name")) {
          if (map["name"] == null) map.remove("name");
        }

        await _database!
            .update(tableName, map, where: "$id = ?", whereArgs: [circle.id]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleCache.upsert: $err");
      rethrow;
    }

    return circle;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> deleteByID(String circleID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$id = ?', whereArgs: [circleID]);
  }

  static Future<Circle?> read(String circleID) async {
    Circle? retValue;
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(tableName,
          columns: [
            pk,
            id,
            name,
            type,
            retention,
            ownershipModel,
            toggleMemberPosting,
            toggleMemberReacting,
            background,
            backgroundKey,
            backgroundSignature,
            backgroundCrank,
            backgroundCipher,
            votingModel,
            owner,
            dm,
            privacyShareImage,
            privacyShareURL,
            privacyShareGif,
            privacyCopyText,
            privacyVotingModel,
            securityVotingModel,
            securityMinPassword,
            securityDaysPasswordValid,
            securityTokenExpirationDays,
            securityLoginAttempts,
            security2FA,
            lastUpdate,
            created,
            expiration,
            privacyDisappearingTimer,
          ],
          where: "$id = ?",
          whereArgs: [circleID]);
      //orderBy: "$lastItemUpdate DESC");

      if (results.isNotEmpty) {
        retValue = Circle.fromJsonSQL(results.first as Map<String, dynamic>);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleCache.read: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<List<Circle>> readAll() async {
    List<Circle> retValue = [];
    try {
      _database = await DatabaseProvider.db.database;

      List<Map> results = await _database!.query(
        tableName,
        columns: [
          pk,
          id,
          name,
          type,
          retention,
          ownershipModel,
          toggleMemberPosting,
          toggleMemberReacting,
          background,
          backgroundKey,
          backgroundSignature,
          backgroundCrank,
          backgroundCipher,
          votingModel,
          owner,
          dm,
          privacyShareImage,
          privacyShareURL,
          privacyShareGif,
          privacyCopyText,
          privacyVotingModel,
          securityVotingModel,
          securityMinPassword,
          securityDaysPasswordValid,
          securityTokenExpirationDays,
          securityLoginAttempts,
          security2FA,
          privacyDisappearingTimer,
          lastUpdate,
          created,
          expiration,
        ],
      );

      if (results.isNotEmpty) {
        //retValue = Circle.fromJsonSQL(results.first as Map<String, dynamic>);
        results.forEach((result) {
          Circle circle = Circle.fromJsonSQL(result as Map<String, dynamic>);
          retValue.add(circle);
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableCircleCache.readAll: $err");
      rethrow;
    }

    return retValue;
  }
}
