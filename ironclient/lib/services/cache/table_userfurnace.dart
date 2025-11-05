import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableUserFurnace {
  static const String tableName = 'userfurnace';
  static const String pk = "pk";
  static const String id = "id";
  static const String userid = "userid";
  static const String username = "username";
  static const String avatarJson = "avatarJson";
  static const String token = "token";
  static const String forgeToken = "forgeToken";
  static const String forgeUserId = "forgeUserId";
  static const String alias = "alias";
  static const String discoverable = "discoverable";
  static const String adultOnly = "adultOnly";
  static const String memberAutonomy = "memberAutonomy";
  static const String description = "description";
  static const String link = "link";
  static const String hostedId = "hostedId";
  static const String hostedFurnaceImageId = "hostedFurnaceImageId";
  static const String hostedName = "hostedName";
  static const String hostedAccessCode = "hostedAccessCode";
  static const String url = "url";
  static const String apikey = "apikey";
  static const String furnaceJson = "furnaceJson";
  static const String authServer = "authServer";
  static const String authServerUserid = "authServerUserid";
  static const String connected = "connected";
  static const String lastLogin = "lastLogin";
  static const String guarded = "guarded";
  static const String transparency = "transparency";
  static const String invitations = "invitations";
  static const String actionsRequired = "actionsRequired";
  static const String actionsRequiredLowPriority = "actionsRequiredLowPriority";
  static const String accountType = "accountType";
  static const String role = "role";
  static const String generatedPin = "generatedPin";
  static const String generatedPassword = "generatedPassword";
  static const String linkedUser = "linkedUser";
  static const String enableWall = "enableWall";
  static const String passwordHash = "passwordHash";
  static const String passwordNonce = "passwordNonce";
  static const String type = "type";

  static final _columns = [
    pk,
    id,
    userid,
    linkedUser,
    username,
    avatarJson,
    token,
    forgeToken,
    forgeUserId,
    alias,
    discoverable,
    adultOnly,
    memberAutonomy,
    description,
    link,
    hostedId,
    hostedFurnaceImageId,
    hostedName,
    hostedAccessCode,
    url,
    apikey,
    //standalone,
    authServerUserid,
    authServer,
    furnaceJson,
    accountType,
    role,
    connected,
    guarded,
    transparency,
    invitations,
    actionsRequired,
    generatedPassword,
    generatedPin,
    actionsRequiredLowPriority,
    lastLogin,
    enableWall,
    passwordHash,
    passwordNonce,
    type,
  ];

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$userid TEXT,"
      "$linkedUser TEXT,"
      "$id TEXT,"
      "$username TEXT,"
      "$avatarJson TEXT,"
      "$token TEXT,"
      "$forgeToken TEXT,"
      "$forgeUserId TEXT,"
      "$alias TEXT,"
      "$discoverable BIT,"
      "$adultOnly BIT,"
      "$memberAutonomy BIT,"
      "$description TEXT,"
      "$link TEXT,"
      "$type INT,"
      "$hostedId TEXT,"
      "$hostedFurnaceImageId TEXT,"
      "$hostedName TEXT,"
      "$hostedAccessCode TEXT,"
      "$furnaceJson TEXT,"
      "$url TEXT,"
      "$apikey TEXT,"
      "$authServerUserid TEXT,"
      "$generatedPin TEXT,"
      "$generatedPassword TEXT,"
      "$passwordHash TEXT,"
      "$passwordNonce TEXT,"
      "$authServer BIT,"
      "$connected BIT,"
      "$guarded BIT,"
      "$transparency BIT,"
      "$invitations INTEGER,"
      "$accountType INTEGER,"
      "$role INTEGER,"
      "$enableWall BIT,"
      "$actionsRequired INTEGER,"
      "$actionsRequiredLowPriority INTEGER,"
      "$lastLogin INTEGER)";

  static Database? _database;

  TableUserFurnace._();

  static Future<bool> forgeExists(User user) async {
    try {
      int? count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userid = ? AND $alias = ?',
          [user.id, "IronForge"]));

      if (count != null && count > 0) {
        return true;
      } else
        return false;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("insertForge $err");

      rethrow;
    }
  }
  //
  // static Future<UserFurnace> insertForge(User user) async {
  //   UserFurnace? userFurnace;
  //
  //   try {
  //     int? count = Sqflite.firstIntValue(await _database!.rawQuery(
  //         'SELECT COUNT(*) FROM $tableName WHERE $userid = ? AND $alias = ?',
  //         [user.id, "IronForge"]));
  //
  //     if (count != null) {
  //       if (count > 0) {
  //         throw ('Forge already exists');
  //       }
  //     }
  //
  //     userFurnace = UserFurnace.init(user);
  //     userFurnace.authServerUserid = user.id;
  //     userFurnace.alias = "IronForge";
  //     userFurnace.id = "IronForge";
  //     userFurnace.url = urls.forge;
  //     userFurnace.apikey = urls.forgeAPIKEY;
  //     userFurnace.authServer = true;
  //     userFurnace.discoverable = false;
  //     userFurnace.enableWall = false;
  //     userFurnace.adultOnly = false;
  //     userFurnace.memberAutonomy = true;
  //     userFurnace.description = '';
  //     userFurnace.link = '';
  //     userFurnace.connected = true;
  //     userFurnace.guarded = false;
  //     userFurnace.transparency = false;
  //     userFurnace.invitations = 0;
  //     userFurnace.actionsRequired = 0;
  //     userFurnace.accountType = AccountType.FREE;
  //     userFurnace.role = Role.MEMBER;
  //     userFurnace.actionsRequiredLowPriority = 0;
  //     userFurnace.lastLogin = DateTime.now().millisecondsSinceEpoch;
  //
  //     userFurnace.furnaceJson =
  //         json.encode(userFurnace.toFurnaceJson()).toString();
  //
  //     _database = await DatabaseProvider.db.database;
  //
  //     userFurnace.pk = await _database!.insert(tableName, userFurnace.toJson());
  //
  //     return userFurnace;
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint("insertForge $err");
  //
  //     rethrow;
  //   }
  // }

  static Future<void> clearAuthAndConnectedServers() async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object> map = {
        authServer: 0,
        connected: 0,
        authServerUserid: ''
      };

      await _database!.update(tableName, map);

      //   where: "$pk != ?", whereArgs: [userFurnace.pk]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.updateAuthServer: $err");
    }

    return;
  }

  // static Future<UserFurnace> clearOtherAuthServers2(
  //     UserFurnace userFurnace) async {
  //   _database = await DatabaseProvider.db.database;
  //
  //   try {
  //     Map<String, Object> map = {
  //       authServer: 0,
  //     };
  //
  //     await _database!.update(tableName, map,
  //         where: "$pk != ?", whereArgs: [userFurnace.pk]);
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint("TableUserFurnace.updateAuthServer: $err");
  //   }
  //
  //   return userFurnace;
  // }

  static setToNewProd(String url) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, Object?> map = {'url': url};

      await _database!.update(tableName, map);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  static Future<void> upsertUserFields(UserFurnace userFurnace, User user,
      GlobalEventBloc globalEventBloc) async {
    _database = await DatabaseProvider.db.database;

    try {
      ///called often, only update if something has changed.
      if (userFurnace.accountType != user.accountType ||
          userFurnace.username != user.username ||
          userFurnace.role != user.role) {
        userFurnace.accountType = user.accountType!;
        userFurnace.role = user.role;
        userFurnace.username = user.username;
        globalEventBloc.broadcastUserFurnaceUpdate(userFurnace);

        Map<String, dynamic> map = {
          username: user.username,
          accountType: user.accountType,
          role: user.role
        };

        await _database!.update(tableName, map,
            where: "$pk = ?", whereArgs: [userFurnace.pk]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  static Future<UserFurnace> registerGenerated(UserFurnace userFurnace) async {
    _database = await DatabaseProvider.db.database;

    try {
      //int pk;
      userFurnace.lastLogin = DateTime.now().millisecondsSinceEpoch;

      userFurnace.furnaceJson =
          json.encode(userFurnace.toFurnaceJson()).toString();

      userFurnace.pk = await _database!
          .insert(tableName, userFurnace.toJsonWithGeneratedPassPin());

      return userFurnace;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.registerGenerated: $err");
      rethrow;
    }
  }

  static Future<UserFurnace> removeGenerated(UserFurnace userFurnace) async {
    _database = await DatabaseProvider.db.database;

    try {
      var map = {
        username: userFurnace.username,
        generatedPassword: '',
        generatedPin: '',
        passwordHash: userFurnace.passwordHash,
        passwordNonce: userFurnace.passwordNonce
      };

      await _database!.update(tableName, map,
          where: "$pk = ?", whereArgs: [userFurnace.pk]);

      return userFurnace;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.registerGenerated: $err");
      rethrow;
    }
  }

  static Future<UserFurnace> upsertReducedFields(
      UserFurnace userFurnace, var map) async {
    _database = await DatabaseProvider.db.database;

    try {
      await _database!.update(tableName, map,
          where: "$pk = ?", whereArgs: [userFurnace.pk]);

      return userFurnace;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  static Future<UserFurnace> upsert(UserFurnace userFurnace) async {
    _database = await DatabaseProvider.db.database;

    try {
      //int pk;
      userFurnace.lastLogin = DateTime.now().millisecondsSinceEpoch;

      userFurnace.furnaceJson =
          json.encode(userFurnace.toFurnaceJson()).toString();

      int? count = 0;

      ///try by id
      if (userFurnace.id != null) {
        count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $id = ? AND $userid = ?',
            [userFurnace.id, userFurnace.userid!]));

        if (count != 0) {
          await _database!.update(tableName, userFurnace.toJson(),
              where: "$id = ? AND $userid = ?",
              whereArgs: [userFurnace.id, userFurnace.userid!]);

          return userFurnace;
        }
      }

      ///try by Key
      if (userFurnace.pk != null)
        count = Sqflite.firstIntValue(await _database!.rawQuery(
            'SELECT COUNT(*) FROM $tableName WHERE $pk = ?', [userFurnace.pk]));

      if (count != 0) {
        await _database!.update(tableName, userFurnace.toJson(),
            where: "$pk = ?", whereArgs: [userFurnace.pk]);

        return userFurnace;
      }

      ///try by alias, this is stupid and deprecated, remove the alias query after everyone is on v91
      count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userid = ? AND $alias = ?',
          [userFurnace.userid!, userFurnace.alias]));

      if (count != 0) {
        //if (userFurnace.url == urls.forge && userFurnace.hosted == false)
        //throw ('Forge already exists');

        UserFurnace existing =
            await readByUserAndAlias(userFurnace.userid!, userFurnace.alias!);

        existing.connected = true;
        existing.token = userFurnace.token;
        existing.authServerUserid = userFurnace.authServerUserid;
        existing.authServer = userFurnace.authServer;

        existing = await upsert(existing);

        return existing;
      } else {
        ///its so insert
        userFurnace.pk =
            await _database!.insert(tableName, userFurnace.toJson());

        return userFurnace;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserFurnace.upsert: $err");
      rethrow;
    }
  }

  static Future<int> delete(int? pkToRemove) async {
    return await _database!
        .delete(tableName, where: '$pk = ?', whereArgs: [pkToRemove]);
  }

  static Future<int> deleteByUsername(String pUsername) async {
    var _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$username = ?', whereArgs: [pUsername]);
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<UserFurnace> read(int? key) async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: _columns, where: "$pk = ?", whereArgs: [key]);
    // orderBy: "$lastLogin DESC");
    if (maps.isNotEmpty) {
      UserFurnace userFurnace =
          UserFurnace.fromJson(maps.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();
      if (maps[0]["avatarJson"] != null) {
        userFurnace.avatar =
            Avatar.fromJson(json.decode(maps[0]["avatarJson"]));
      }

      return userFurnace;
    } else
      throw ('TableUserFurnace.read: Furnace not found');
  }

  static Future<UserFurnace> readByUserID(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: _columns, where: "$userid = ?", whereArgs: [pUserID]);
    if (maps.isNotEmpty) {
      UserFurnace userFurnace =
          UserFurnace.fromJson(maps.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();
      if (maps[0]["avatarJson"] != null) {
        userFurnace.avatar =
            Avatar.fromJson(json.decode(maps[0]["avatarJson"]));
      }

      return userFurnace;
    } else
      throw ('TableUserFurnace.read: Furnace not found');
  }

  static Future<UserFurnace> readByUserAndAlias(
      String pUserID, String pAlias) async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: _columns,
        where: "$userid = ? and $alias = ?",
        whereArgs: [pUserID, pAlias]);
    // orderBy: "$lastLogin DESC");
    if (maps.isNotEmpty) {
      UserFurnace userFurnace =
          UserFurnace.fromJson(maps.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();
      if (maps[0]["avatarJson"] != null) {
        userFurnace.avatar =
            Avatar.fromJson(json.decode(maps[0]["avatarJson"]));
      }

      return userFurnace;
    } else
      throw ('TableUserFurnace.read: Furnace not found');
  }

  static Future<UserFurnace?> readMostRecent() async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _columns,
        where: "$authServer = ? AND $connected = ?",
        whereArgs: [1, 1],
        orderBy: "$lastLogin DESC");
    if (results.isNotEmpty) {
      if (results.length > 1) {
        // LogBloc.insertLog('User has ${results.length} authServers}',
        //     'TableUserFurnace.readMostRecent');
      }

      UserFurnace userFurnace =
          UserFurnace.fromJson(results.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();

      //debugPrint('break');
      return userFurnace;
    }

    return null;
  }

  static Future<UserFurnace?> readUserAuth(String? readUser) async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: _columns,
        where: "$username = ? and $authServer = ?",
        whereArgs: [readUser, 1]);
    if (maps.isNotEmpty) {
      UserFurnace userFurnace =
          UserFurnace.fromJson(maps.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();
      return userFurnace;
    }

    return null;
  }

  static Future<UserFurnace?> readUserAuthByID(String userID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: _columns,
        where: "$userid = ? and $authServer = ?",
        whereArgs: [userID, 1]);
    if (maps.isNotEmpty) {
      UserFurnace userFurnace =
          UserFurnace.fromJson(maps.first as Map<String, dynamic>);
      userFurnace.populateNonColumn();
      return userFurnace;
    }

    return null;
  }

  static Future<List<UserFurnace>> readLinkedForUser(
      String linkedUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _columns,
        where: "$linkedUser = ?",
        whereArgs: [linkedUserID],
        orderBy: "$alias ASC");

    List<UserFurnace> userFurnaces = [];
    for (var result in results) {
      UserFurnace furnace =
          UserFurnace.fromJson(result as Map<String, dynamic>);
      furnace.populateNonColumn();
      userFurnaces.add(furnace);
    }

    return userFurnaces;
  }

  static Future<List<UserFurnace>> readConnectedForUser(
      String? readUserID) async {
    _database = await DatabaseProvider.db.database;

    if (readUserID == null) return [];

    List<Map> results = await _database!.query(tableName,
        columns: _columns,
        where: "$authServerUserid = ? AND $connected = ?",
        whereArgs: [readUserID, 1],
        orderBy: "$alias ASC");

    List<UserFurnace> userFurnaces = [];
    for (var result in results) {
      UserFurnace furnace =
          UserFurnace.fromJson(result as Map<String, dynamic>);
      furnace.populateNonColumn();
      userFurnaces.add(furnace);
    }

    return userFurnaces;
  }

  static Future<List<UserFurnace>> readAllForUser(String? readUserID) async {
    if (readUserID == null) return [];

    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _columns,
        where: "$authServerUserid = ?",
        whereArgs: [readUserID],
        orderBy: "$pk ASC");

    List<UserFurnace> userFurnaces = [];

    for (var result in results) {
      UserFurnace furnace =
          UserFurnace.fromJson(result as Map<String, dynamic>);
      furnace.populateNonColumn();
      userFurnaces.add(furnace);
    }

    return userFurnaces;
  }

  static Future<List<UserFurnace>> readAll() async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: _columns,
        //where: "$connected = ?",
        //whereArgs: [1],
        orderBy: "$pk ASC");

    List<UserFurnace> userFurnaces = [];
    for (var result in results) {
      UserFurnace furnace =
          UserFurnace.fromJson(result as Map<String, dynamic>);

      furnace.populateNonColumn();

      userFurnaces.add(furnace);
    }

    return userFurnaces;
  }
}
