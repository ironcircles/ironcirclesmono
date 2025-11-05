import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableMember {
  static const String tableName = 'memberbyuser';
  static const String oldTableName = 'member';
  static const String pk = "pk";
  static const String memberID = "memberID";
  static const String userID = "userID";
  static const String alias = "alias";
  static const String username = "username";
  static const String furnaceKey = 'furnaceKey';
  static const String avatar = 'avatar';
  static const String color = "color";
  static const String accountType = "accountType";
  static const String lockedOut = "lockedOut";
  static const String blocked = "blocked";
  static const String connected = "connected";

  static var selectColumns = [
    pk,
    memberID,
    userID,
    furnaceKey,
    avatar,
    color,
    accountType,
    lockedOut,
    username,
    alias,
    blocked,
    connected
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$memberID TEXT,"
      "$userID TEXT,"
      "$username TEXT,"
      "$avatar TEXT,"
      "$furnaceKey INTEGER,"
      "$alias TEXT,"
      "$color INT,"
      "$lockedOut INT,"
      "$blocked INT,"
      "$accountType INT,"
      "$connected BIT,"
      " UNIQUE($memberID,$userID))";

  static Database? _database;

  TableMember._();

  static Future<Member> upsert(String pUserID, Member member) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $memberID = ? AND $userID = ?',
          [member.memberID, pUserID]));

      if (count == 0) {
        member.pk = await _database!.insert(tableName, member.toJson());
      } else {
        await _database!.update(tableName, member.toJson(),
            where: "$memberID = ? AND $userID = ?",
            whereArgs: [member.memberID, pUserID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return member;
  }

  ///Warning, this will update every instance of the member in the table
  ///There could be more than one if more than 2 people log into the device
  ///Can be used to set initial colors, update avatar, or username
  static Future<Member> update(Member member) async {
    _database = await DatabaseProvider.db.database;

    try {
      //don't user all the member fields, like username

      Map<String, dynamic> map = {
        color: member.color.value,
        username: member.username,
        avatar: member.avatar,
        alias: member.alias,
        accountType: member.accountType,
        blocked: member.blocked,
      };

      await _database!.update(tableName, map,
          where: "$memberID = ?", whereArgs: [member.memberID]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return member;
  }

  static Future<int> upsertBatch(List<Member> members) async {
    try {
      _database = await DatabaseProvider.db.database;

      var batch = _database!.batch();

      for (Member member in members) {
        batch.update(tableName, member.toJson(),
            where: "$memberID = ?", whereArgs: [member.memberID]);
      }

      var results = await batch.commit(noResult: false, continueOnError: true);

      return results.length;
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint('TableCircleObject.upsertListofObjects: $err');

      return 0;
    }
  }

  static Future<Member> setColor(String pUserID, Member member) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object> map = {color: member.color.value};

      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $memberID = ? AND $userID = ?',
          [member.memberID, pUserID]));

      if (count == 0) {
        member.pk = await _database!.insert(tableName, map);
      } else {
        await _database!.update(tableName, map,
            where: "$memberID = ?", whereArgs: [member.memberID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return member;
  }

  static Future<Member> setAlias(String pUserID, Member member) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object> map = {alias: member.alias};

      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $memberID = ? AND $userID = ?',
          [member.memberID, pUserID]));

      if (count == 0) {
        member.pk = await _database!.insert(tableName, map);
      } else {
        await _database!.update(tableName, map,
            where: "$memberID = ?", whereArgs: [member.memberID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return member;
  }

  static Future<Member> setBlocked(String pUserID, Member member) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object> map = {blocked: member.blocked ? 1 : 0};

      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $memberID = ? AND $userID = ?',
          [member.memberID, pUserID]));

      if (count == 0) {
        member.pk = await _database!.insert(tableName, map);
      } else {
        await _database!.update(tableName, map,
            where: "$memberID = ?", whereArgs: [member.memberID]);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
    return member;
  }

  static Future<void> setLockedOut(
      String pUserID, String pMemberID, bool pLockedOut) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object> map = {lockedOut: pLockedOut ? 1 : 0};

      await _database!.update(tableName, map,
          where: "$memberID = ? AND $userID = ?",
          whereArgs: [pMemberID, pUserID]);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return;
  }

  static Future<void> upsertCollection(
      String pUserID,
      int pFurnaceKey,
      UserCollection members,
      UserCollection connections,
      GlobalState boo,
      List<User> blockedList) async {
    try {
      _database = await DatabaseProvider.db.database;

      ///RBR TODO this should only fetch the current Network users
      List<Member> membersList = await readAll();
      List<Member> addToGlobalStateAfterKeyPopulated = [];

      var batch = _database!.batch();
      for (User user in members.users) {
        try {
          ///delete any user who removed their account
          if (user.removeFromCache != null) {
            batch.delete(tableName,
                where: "$memberID = ? AND $userID = ?",
                whereArgs: [user.id, pUserID]);

            globalState.members
                .removeWhere((element) => element.memberID == user.id);
            continue;
          }

          bool memberConnected = false;

          int connectedIndex =
              connections.users.indexWhere((element) => element.id == user.id);

          if (connectedIndex > -1) memberConnected = true;

          ///returns an empty object if not found
          late Member member; // = await read(pUserID, user.id!);
          int index = membersList.indexWhere((element) =>
              element.memberID == user.id && element.userID == pUserID);

          if (index == -1) {
            member = Member(
                connected: memberConnected,
                lockedOut: user.lockedOut,
                memberID: user.id!,
                userID: pUserID,
                furnaceKey: pFurnaceKey,
                alias: '',
                avatar: user.avatar,
                username: user.username!);

            await boo.userSetting.setLastColorIndex(
                boo.userSetting.lastColorIndex + 1,
                save: true);

            member.color =
                boo.theme.messageColorOptions![boo.userSetting.lastColorIndex];

            batch.insert(
              tableName,
              member.toJson(),
            );
          } else {
            member = membersList[index];

            ///This is from Node.js. Only fields that can change server side are the username, avatar, and accountType
            if (member.username != user.username ||
                member.accountType != user.accountType ||
                member.lockedOut != user.lockedOut ||
                avatarDirty(user, member) ||
                member.furnaceKey != pFurnaceKey ||
                member.connected != memberConnected) {
              member.username = user.username!;
              member.avatar = user.avatar;
              member.furnaceKey = pFurnaceKey;
              member.lockedOut = user.lockedOut;
              member.connected = memberConnected;

              Map<String, Object> map = {
                username: member.username,
                furnaceKey: pFurnaceKey,
                lockedOut: member.lockedOut ? 1 : 0,
                connected: member.connected ? 1 : 0
              };

              if (member.avatar != null) {
                map[avatar] = json.encode(member.avatar!.toJson()).toString();
              }

              int index =
                  blockedList.indexWhere((element) => element.id == user.id);

              if (index != -1) {
                map[blocked] = true;
              } else {
                map[blocked] = false;
              }

              if (member.accountType != user.accountType) {
                map[accountType] = user.accountType!;
              }

              batch.update(tableName, map,
                  where: "$memberID = ? AND $userID = ?",
                  whereArgs: [member.memberID, pUserID]);
            }
          }
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint('$error');
        }
      }

      await batch.commit(noResult: false, continueOnError: true);

      for (Member member in addToGlobalStateAfterKeyPopulated) {
        Member.addMember(member);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return;
  }

  static bool avatarDirty(User a, Member b) {
    if (a.avatar != null) {
      if (b.avatar == null) return true;

      if (a.avatar!.size != b.avatar!.size) return true;
    }

    return false;
  }

  /*static Future<int> delete(Member member) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$pk = ?', whereArgs: [member.pk]);
  }

  static Future<int> deleteByMemberID(String pMemberID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$memberID = ?', whereArgs: [pMemberID]);
  }

   */

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> deleteAllForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$userID = ?', whereArgs: [pUserID]);
  }

  static Future<List<Member>> getCachedMembers(
    List<UserFurnace> userFurnaces,
  ) async {
    _database = await DatabaseProvider.db.database;
    //List<int> furnaceKeys = [];
    List<String> userKeys = [];

    ///Pull these by userid since it's unique across networks
    ///This will prevent duplicates if a user logs into the same network on a single device

    List<Member> retValue = [];

    for (UserFurnace userFurnace in userFurnaces) {
      userKeys.add(userFurnace.userid!);
    }

    // String where =
    //   '$lockedOut = false AND $userID IN (${userKeys.map((e) => "'$e'").join(', ')})';

    String where = '$userID IN (${userKeys.map((e) => "'$e'").join(', ')})';

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, where: where, orderBy: "$username ASC");

    for (var result in results) {
      ///exclude the current user
      if (userKeys.contains(result[memberID])) continue;
      Member member = Member.fromJsonSQL(result as Map<String, dynamic>);
      if (result["avatar"] != null)
        member.avatar = Avatar.fromJson(json.decode(result["avatar"]));

      retValue.add(member);
    }

    return retValue;
  }

  static Future<Member> read(String pUserID, String pMemberID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: "$memberID = ? AND $userID = ?",
        whereArgs: [pMemberID, pUserID]);

    Member member = Member(memberID: '', userID: '', alias: '');

    if (results.isNotEmpty) {
      member = Member.fromJsonSQL(results.first as Map<String, dynamic>);
      if (results.first["avatar"] != null)
        member.avatar = Avatar.fromJson(json.decode(results.first["avatar"]));

      if (results.length > 1) {
        debugPrint(
            'DUPLICATE MEMBER RECORDS *********************************');
      }
    }

    return member;
  }

  static Future<List<Member>> getAll() async {
    _database = await DatabaseProvider.db.database;
    List<Member> members = [];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, orderBy: '${username.toLowerCase()} ASC');

    for (var result in results) {
      Member member = Member.fromJsonSQL(result as Map<String, dynamic>);
      members.add(member);
    }

    return members;
  }

  static Future<List<Member>> readForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;
    List<Member> members = [];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, where: "$userID = ?", whereArgs: [pUserID]);

    for (var result in results) {
      Member member = Member.fromJsonSQL(result as Map<String, dynamic>);
      members.add(member);
    }

    return members;
  }

  static Future<List<Member>> readAll() async {
    _database = await DatabaseProvider.db.database;
    List<Member> members = [];

    List<Map> results = await _database!.query(
      tableName,
      columns: selectColumns,
    );
    //where: "$userID = ?",
    //whereArgs: [pUserID]);

    for (var result in results) {
      try {
        Member member = Member.fromJsonSQL(result as Map<String, dynamic>);
        members.add(member);
      } catch (err, trace) {
        //debugPrint("Error reading member: $err. $trace");
      }
    }

    return members;
  }
}
