import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableMemberCircle {
  static const String tableName = 'membercircle';
  static const String pk = "pk";
  static const String memberID = "memberID";
  static const String userID = "userID";
  static const String circleID = "circleID";
  //static final String username = "username";
  static const String dm = "dm";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$memberID TEXT,"
      "$userID TEXT,"
      "$circleID TEXT,"
      // "$username TEXT,"
      "$dm BIT,"
      " UNIQUE($memberID,$circleID))";

  static Database? _database;

  TableMemberCircle._();

  static Future<void> upsert(MemberCircle memberCircle) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $memberID = ? AND $circleID = ?',
          [memberCircle.memberID, memberCircle.circleID]));

      if (count == 0) {
        await _database!.insert(tableName, memberCircle.toJson());
      } else {
        await _database!.update(tableName, memberCircle.toJson(),
            where: "$memberID = ? AND $circleID = ?",
            whereArgs: [memberCircle.memberID, memberCircle.circleID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return;
  }

  static Future<void> upsertCollection(
      String pUserID, MemberCircleCollection members) async {
    _database = await DatabaseProvider.db.database;

    ///This is only called from Node.js, there are no updates, only inserts and deletes
    List<MemberCircle> memberCirclesList = await getForUser(pUserID);

    var batch = _database!.batch();

    ///handle deletes first
    for (MemberCircle memberCircle in memberCirclesList) {
      ///dms have a life of their own, skip them
      if (memberCircle.dm == true) continue;

      ///if it is in the database but not returned from the api, delete it
      int index = members.membersCircles.indexWhere((element) =>
          element.userID == pUserID &&
          element.memberID == memberCircle.memberID &&
          element.circleID == memberCircle.circleID);

      if (index == -1) {
        batch.delete(tableName,
            where: "$memberID = ? AND $userID = ? AND $circleID = ?",
            whereArgs: [memberCircle.memberID, pUserID, memberCircle.circleID]);
        continue;
      }
    }

    ///now look for inserts
    for (MemberCircle memberCircle in members.membersCircles) {
      try {
        int index = memberCirclesList.indexWhere((element) =>
            element.userID == pUserID &&
            element.memberID == memberCircle.memberID &&
            element.circleID == memberCircle.circleID);

        if (index == -1) {
          Map<String, dynamic> json = memberCircle.toJson();
          batch.insert(tableName, json);
        }
      } catch (error, trace) {
        debugPrint('$trace');
        debugPrint('$error');
      }
    }

    await batch.commit(noResult: false, continueOnError: true);

    return;
  }

  static Future<int> deleteAllForCircle(String pCircleID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$circleID = ?', whereArgs: [pCircleID]);
  }

  static Future<int> deleteAllForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$userID = ?', whereArgs: [pUserID]);
  }

  static Future<int> deleteDMNoCircleID(String pUser, String pMember) async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(tableName,
        where: '$userID = ? AND $memberID = ? AND $dm =  ?',
        whereArgs: [pUser, pMember, 1]);
  }

  /*
  Future<int> delete(Member member) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$pk = ?', whereArgs: [member.pk]);
  }
   */

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<MemberCircle?> getDM(String pUserID, String pMemberID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          memberID,
          userID,
          circleID,
          dm,
        ],
        where: '$userID = ? AND $memberID = ? AND $dm = 1',
        whereArgs: [pUserID, pMemberID]);

    if (results.isNotEmpty) {
      MemberCircle memberCircle =
          MemberCircle.fromJson(results.first as Map<String, dynamic>);

      return memberCircle;
    }

    return null;
  }

  static Future<List<MemberCircle>> getForCircles(
      List<UserCircleCache> userCircleCaches) async {
    _database = await DatabaseProvider.db.database;
    List<String> circleIDs = [];
    List<MemberCircle> retValue = [];

    for (UserCircleCache userCircleCache in userCircleCaches) {
      circleIDs.add(userCircleCache.circle!);
    }

    String where = '$circleID IN (${circleIDs.map((e) => "'$e'").join(', ')})';

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          memberID,
          userID,
          circleID,
          dm,
        ],
        where: where);

    for (var result in results) {
      MemberCircle member =
          MemberCircle.fromJson(result as Map<String, dynamic>);

      retValue.add(member);
    }

    return retValue;
  }

  static Future<List<MemberCircle>> getForCircle(
      String pUserID, String pCircleID) async {
    _database = await DatabaseProvider.db.database;
    List<MemberCircle> retValue = [];

    String where = '$circleID = ? AND $memberID != ?';

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          memberID,
          userID,
          circleID,
          dm,
        ],
        where: where,
        whereArgs: [pCircleID, pUserID]);

    for (var result in results) {
      MemberCircle member =
          MemberCircle.fromJson(result as Map<String, dynamic>);

      retValue.add(member);
    }

    return retValue;
  }

  static Future<List<MemberCircle>> getForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;
    List<MemberCircle> retValue = [];

    String where = '$userID = ? ';

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          memberID,
          userID,
          circleID,
          dm,
        ],
        where: where,
        whereArgs: [pUserID]);

    for (var result in results) {
      MemberCircle member =
          MemberCircle.fromJson(result as Map<String, dynamic>);

      retValue.add(member);
    }

    return retValue;
  }

  static Future<List<MemberCircle>> getForCirclesAndMember(
      List<UserCircleCache> userCircleCaches, String pMemberID) async {
    _database = await DatabaseProvider.db.database;
    List<String> circleIDs = [];
    List<MemberCircle> retValue = [];

    for (UserCircleCache userCircleCache in userCircleCaches) {
      circleIDs.add(userCircleCache.circle!);
    }

    String where = '$circleID IN (${circleIDs.map((e) => "'$e'").join(', ')})';
    where = '$where AND $memberID = ? AND $dm = ?';

    // debugPrint(where);

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          memberID,
          userID,
          circleID,
          dm,
        ],
        where: where,
        whereArgs: [pMemberID, 0]);

    for (var result in results) {
      MemberCircle member =
          MemberCircle.fromJson(result as Map<String, dynamic>);

      retValue.add(member);
    }

    return retValue;
  }
}
