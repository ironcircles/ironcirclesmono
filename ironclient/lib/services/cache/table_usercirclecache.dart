import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:sqflite/sqflite.dart';

class TableUserCircleCache {
  static const String tableName = 'usercirclecache';
  static const String pk = "pk";
  static const String usercircle = "usercircle";
  static const String circle = "circle";
  static const String circleJson = "circleJson";
  static const String user = "user";
  static const String showBadge = "showBadge";
  static const String hidden = "hidden";
  static const String hiddenOpen = "hiddenOpen";
  static const String guarded = "guarded";
  static const String pinned = "pinnedCircle";
  static const String closed = "closed";
  static const String muted = "muted";
  static const String dm = "dm";
  static const String dmConnected = "dmConnected";
  static const String guardedOpen = "guardedOpen";
  static const String guardedPinString = "guardedPinString";
  static const String backgroundColor = "backgroundColor";
  static const String background = "background";
  static const String backgroundLocation = "backgroundLocation";
  static const String masterBackground = "masterBackground";
  static const String masterBackgroundLocation = "masterBackgroundLocation";
  static const String circlePath = "circlePath";
  static const String backgroundSize = "backgroundSize";
  static const String masterBackgroundSize = "masterBackgroundSize";
  static const String prefName = "prefName";
  static const String circleName = "circleName";
  static const String userFurnace = "userFurnace";
  static const String lastItemUpdate = "lastItemUpdate";
  static const String lastLocalAccess = "lastLocalAccess";
  static const String lastUpdate = "lastUpdate";
  static const String crank = "crank";
  static const String dmMember = "dmMember";

  //static final String jwt= "token";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$usercircle TEXT UNIQUE,"
      "$circle TEXT,"
      "$circleJson TEXT,"
      "$user TEXT,"
      "$dm BIT,"
      "$dmConnected BIT,"
      "$showBadge BIT,"
      "$hidden BIT,"
      "$hiddenOpen BIT,"
      "$guarded BIT,"
      "$muted BIT,"
      "$closed BIT,"
      "$guardedOpen BIT,"
      "$pinned BIT,"
      "$guardedPinString TEXT,"
      "$backgroundColor INT,"
      "$background TEXT,"
      "$backgroundLocation TEXT,"
      "$crank TEXT,"
      "$masterBackground TEXT,"
      "$masterBackgroundLocation TEXT,"
      "$circlePath TEXT,"
      "$backgroundSize INT,"
      "$masterBackgroundSize INT,"
      "$prefName TEXT,"
      "$circleName TEXT,"
      "$userFurnace INT,"
      "$lastUpdate INT, "
      "$lastItemUpdate INT, "
      "$lastLocalAccess INT, "
      "$dmMember TEXT)";

  static Database? _database;

  static List<String> selectColumns = [
    pk,
    usercircle,
    circle,
    circleJson,
    user,
    showBadge,
    dm,
    dmConnected,
    hidden,
    hiddenOpen,
    guarded,
    crank,
    muted,
    closed,
    guardedPinString,
    pinned,
    guardedOpen,
    backgroundColor,
    background,
    masterBackground,
    backgroundLocation,
    masterBackgroundLocation,
    circlePath,
    backgroundSize,
    masterBackgroundSize,
    prefName,
    circleName,
    userFurnace,
    lastItemUpdate,
    lastLocalAccess,
    lastUpdate,
    dmMember
  ];

  TableUserCircleCache._();

  static Future<bool> closeGuardedCircles() async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        guardedOpen: 0,
      };

      await _database!.update(tableName, map);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeGuardedCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<bool> closeHiddenCircles() async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        hiddenOpen: 0,
      };

      await _database!.update(tableName, map);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeHiddenCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<int> countRecords() async {
    var count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $tableName'));

    return count!;
  }

  static Future<bool> closeGuardedCircle(String userCircleID) async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        guardedOpen: 0,
      };

      await _database!.update(tableName, map,
          where: '$usercircle = ?', whereArgs: [userCircleID]);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeGuardedCircle: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<bool> closeHiddenCircle(String userCircleID) async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        hiddenOpen: 0,
      };

      await _database!.update(tableName, map,
          where: '$usercircle = ?', whereArgs: [userCircleID]);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeHiddenCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<bool> hideCircle(String userCircleID, bool hide) async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        hiddenOpen: 0,
        hidden: hide ? 1 : 0,
      };

      await _database!.update(tableName, map,
          where: '$usercircle = ?', whereArgs: [userCircleID]);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeHiddenCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<bool> pinnedCircle(UserCircleCache userCircleCache) async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        TableUserCircleCache.pinned: userCircleCache.pinned ? 1 : 0,
      };

      int count = await _database!.update(tableName, map,
          where: '$usercircle = ?', whereArgs: [userCircleCache.usercircle!]);

      debugPrint(count.toString());

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeHiddenCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<bool> guardCircle(
      String userCircleID, String pinString, bool guard) async {
    bool retValue = false;

    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        guardedOpen: 0,
        guarded: guard ? 1 : 0,
        guardedPinString: pinString,
      };

      await _database!.update(tableName, map,
          where: '$usercircle = ?', whereArgs: [userCircleID]);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.closeHiddenCircles: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<void> updateLastItemUpdateAndBadge(String circleID,
      String? userID, bool? pBadge, DateTime? pLastItemUpdate) async {
    _database = await DatabaseProvider.db.database;

    try {
      debugPrint(
          'updateLastItemUpdateAndBadge CALLED with showBadge $pBadge ${DateTime.now()}');

      if (pBadge != null && pBadge) {
        debugPrint('break');
      }

      Map<String, dynamic> map = {
        showBadge: pBadge == null
            ? 0
            : pBadge
                ? 1
                : 0,
        lastLocalAccess: pLastItemUpdate!.millisecondsSinceEpoch,
        lastItemUpdate: pLastItemUpdate.millisecondsSinceEpoch,
      };

      await _database!.update(tableName, map,
          where: "$circle = ? and $user = ?", whereArgs: [circleID, userID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.updateAccessAndBadge: $err");
      rethrow;
    }

    return;
  }

  static Future<void> flipShowBadge(
      String? circleID, String? userID, bool pBadge) async {
    _database = await DatabaseProvider.db.database;

    try {
      debugPrint(
          'flipShowBadge CALLED with showBadge $pBadge ${DateTime.now()}');

      if (pBadge) {
        debugPrint('break');
      }

      Map<String, dynamic> map = {showBadge: pBadge ? 1 : 0};

      await _database!.update(tableName, map,
          where: "$circle = ? and $user = ?", whereArgs: [circleID, userID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.flipShowBadge: $err");
      rethrow;
    }

    return;
  }

  static Future<void> updateLastLocalAccess(
      String? circleID, String? userID, DateTime pLastLocalAccess) async {
    _database = await DatabaseProvider.db.database;

    try {
      debugPrint(
          'updateLastLocalAccess CALLED with showBadge false ${DateTime.now()}');

      Map<String, dynamic> map = {
        showBadge: 0,
        lastLocalAccess: pLastLocalAccess.millisecondsSinceEpoch
      };

      await _database!.update(tableName, map,
          where: "$circle = ? and $user = ?", whereArgs: [circleID, userID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.updateLastLocalAccess: $err");
      rethrow;
    }

    return;
  }

  static Future<void> updateLastItemUpdate(
      String? circleID, String? userID, DateTime? pLastItemUpdate,
      {bool setLastAccessed = false}) async {
    _database = await DatabaseProvider.db.database;

    try {
      Map<String, dynamic> map = {
        lastItemUpdate: pLastItemUpdate!.millisecondsSinceEpoch
      };

      if (setLastAccessed)
        map[lastLocalAccess] = pLastItemUpdate.millisecondsSinceEpoch;

      await _database!.update(tableName, map,
          where: "$circle = ? and $user = ?", whereArgs: [circleID, userID]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableUserCircleCache.updateLastItemUpdate: $err");
      rethrow;
    }

    return;
  }

  static Future<UserCircleCache?> updateUserCircleCacheByCache(
      UserCircleCache userCircleCache, UserFurnace? userFurnace,
      [bool hiddenOpen = false]) async {
    try {
      userCircleCache.userFurnace = userFurnace!.pk;
      userCircleCache.hiddenOpen = hiddenOpen;

      await upsert(userCircleCache);

      userCircleCache.furnaceObject = userFurnace; //hitchhiking

      return userCircleCache;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('TableUserCircleCache.updateUserCircleCache: $error');
      rethrow;
    }
  }

  static batchUpdateUserCircleCaches(
      List<UserCircleCache> userCircleCaches) async {
    try {
      var batch = _database!.batch();

      for (UserCircleCache userCircleCache in userCircleCaches) {
        Map<String, dynamic> map = userCircleCache.toJson();

        ///make sure this wasn't just deleted and there is an api refresh timing issue
        if (globalState.deletedUserCircleID
            .contains(userCircleCache.usercircle!)) {
          //throw ('usercircle deleted');
          continue;
        }

        removeName(map);

        batch.update(tableName, map,
            where: "$usercircle = ?", whereArgs: [userCircleCache.usercircle]);
      }

      ///commit the batch
      var results = await batch.commit(noResult: false, continueOnError: true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static batchUpdateUserCircles(List<UserCircle> userCircles,
      List<UserCircleCache> userCircleCaches, UserFurnace? userFurnace,
      {bool hiddenOpen = false}) async {
    try {
      // debugPrint(
      //     "TableUserCircleCache.batchUpdateUserCircleCaches start: ${DateTime.now()}");
      var batch = _database!.batch();

      for (UserCircle userCircle in userCircles) {
        if (userCircle.removeFromCache == null && userCircle.circle != null) {
          UserCircleCache? userCircleCache;

          ///make sure this wasn't just deleted and there is an api refresh timing issue
          if (globalState.deletedUserCircleID.contains(userCircle.id!)) {
            throw ('usercircle deleted');
          }

          int index = userCircleCaches
              .indexWhere((element) => element.usercircle == userCircle.id);

          if (index > -1) {
            userCircleCache = userCircleCaches[index];
          }

          ///only read if null
          userCircleCache ??= await TableUserCircleCache.read(userCircle.id!);

          ///skip the ones that haven't changed
          if (userCircle.lastUpdateDate != null &&
              userCircleCache.lastUpdate != null) {
            //debugPrint('lastUpdateDate ${userCircle.lastUpdateDate} userCircleCache.lastUpdate ${userCircleCache.lastUpdate}');
            if (userCircleCache.lastUpdate!
                    .compareTo(userCircle.lastUpdateDate!) >=
                0) {
              if (userCircle.dm != null) {
                if (userCircle.dm!.id == userCircleCache.dmMember &&
                    userCircle.dmConnected == userCircleCache.dmConnected) {
                  continue;
                }
              } else {
                continue;
              }
            } /*else {
              debugPrint(
                  'DID NOT SKIP updated lastUpdateDate ${userCircle.lastUpdateDate} userCircleCache.lastUpdate ${userCircleCache.lastUpdate}');
            }
            */
          }

          userCircleCache.refreshFromUserCircle(userCircle, userFurnace!.pk);
          userCircleCache.userFurnace = userFurnace.pk;
          userCircleCache.hiddenOpen = hiddenOpen;

          Map<String, dynamic> map = userCircleCache.toJson();

          removeName(map);

          ///server doesn't not know what is going on.  Don't flip this off in this function
          if (map["hiddenOpen"] == 0) {
            map.remove("hiddenOpen");
          }

          batch.update(tableName, map,
              where: "$usercircle = ?",
              whereArgs: [userCircleCache.usercircle]);

          userCircleCache.furnaceObject = userFurnace; //hitchhiking
        }
      }

      ///commit the batch
      var results = await batch.commit(noResult: false, continueOnError: true);

      //debugPrint("TableUserCircleCache.batchUpdateUserCircleCaches: $results");
      //debugPrint(
      //   "TableUserCircleCache.batchUpdateUserCircleCaches end: ${DateTime.now()}");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static Future<UserCircleCache?> updateUserCircleCache(
      UserCircle userCircle, UserFurnace? userFurnace,
      {bool hiddenOpen = false, UserCircleCache? existingCache}) async {
    try {
      if (userCircle.circle != null && userCircle.removeFromCache == null) {
        late UserCircleCache userCircleCache;

        ///make sure this wasn't just deleted and there is an api refresh timing issue
        if (globalState.deletedUserCircleID.contains(userCircle.id!)) {
          throw ('usercircle deleted');
        }

        if (existingCache == null)
          userCircleCache = await TableUserCircleCache.read(userCircle.id!);
        else
          userCircleCache = existingCache;

        //debugPrint(
        //   'updateUserCircleCache CALLED with showBadge ${userCircleCache.showBadge} ${DateTime.now()}');

        userCircleCache.refreshFromUserCircle(userCircle, userFurnace!.pk);
        userCircleCache.userFurnace = userFurnace.pk;
        userCircleCache.hiddenOpen = hiddenOpen;

        await upsert(userCircleCache);

        userCircleCache.furnaceObject = userFurnace; //hitchhiking

        return userCircleCache;
      } else {
        await TableUserCircleCache.deleteByID(userCircle.id);

        return null;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static Map<String, dynamic> removeName(Map<String, dynamic> map) {
    //remove the name
    if (map.containsKey("prefName")) {
      if (map["prefName"] == null) map.remove("prefName");
    }

    return map;
  }

  static setName(
      String pUserCircle, String prefName, String crank, int furnaceKey) async {
    _database = await DatabaseProvider.db.database;

    try {
      //debugPrint("TableUserCircleCache.setName start: ${DateTime.now()}");

      Map<String, dynamic> map = {
        TableUserCircleCache.prefName: prefName,
        TableUserCircleCache.crank: crank,
        TableUserCircleCache.userFurnace: furnaceKey,
      };

      await _database!.update(tableName, map,
          where: "$usercircle = ?", whereArgs: [pUserCircle]);

      //debugPrint("TableUserCircleCache.setName end: ${DateTime.now()}");
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }

    return;
  }

  static Future<UserCircleCache> upsert(UserCircleCache userCircleCache) async {
    _database = await DatabaseProvider.db.database;

    try {
      // if (userCircleCache.circlePath == null) {
      userCircleCache.circlePath = await FileSystemService.makeCirclePath(
          userCircleCache.user, userCircleCache.circle);
      // }

      var existing = await read(userCircleCache.usercircle!);

      /*var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $usercircle = ?',
          [userCircleCache.usercircle]));

       */

      //debugPrint('InsideCircle:goHome firstIntValue passed ${DateTime.now()}');

      if (existing.usercircle == null) {
        userCircleCache.pk =
            await _database!.insert(tableName, userCircleCache.toJson());
      } else {
        ///make sure this wasn't just deleted and there is an api refresh timing issue
        if (globalState.deletedUserCircleID
            .contains(userCircleCache.usercircle!)) {
          throw ('usercircle deleted');
        }

        /*if (existing.lastUpdate != null && userCircleCache.lastUpdate != null) {
          //debugPrint('lastUpdateDate ${userCircle.lastUpdateDate} userCircleCache.lastUpdate ${userCircleCache.lastUpdate}');
          if (userCircleCache.lastUpdate!.compareTo(existing.lastUpdate!) >=
              0) {
            debugPrint('****************SKIPPED UPSERT*****************');
            //return userCircleCache;
          }
        }
         */

        debugPrint(
            'UPSERT CALLED with showBadge ${userCircleCache.showBadge} ${DateTime.now()}');

        Map<String, dynamic> map = userCircleCache.toJson();

        removeName(map);

        //server doesn't not know what is going on.  Don't flip this off in this function
        if (map["hiddenOpen"] == 0) {
          map.remove("hiddenOpen");
        }

        await _database!.update(tableName, map,
            where: "$usercircle = ?", whereArgs: [userCircleCache.usercircle]);

        debugPrint(
            'UPSERT FINISHED with showBadge ${userCircleCache.showBadge} ${DateTime.now()}');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      ///encode the json
      debugPrint(json.encode(userCircleCache.toJson()));
      rethrow;
    }

    return userCircleCache;
  }

  static Future<int> deleteAllForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    return await _database!
        .delete(tableName, where: '$user = ?', whereArgs: [pUserID]);
  }

  static Future<int> deleteUserCircle(String? id) async {
    _database = await DatabaseProvider.db.database;

    if (id == null) return 0;

    int number = await _database!
        .delete(tableName, where: '$usercircle = ?', whereArgs: [id]);

    debugPrint('number of usercircles deleted: $number');
    globalState.deletedUserCircleID.add(id);

    return number;
  }

  static Future<int> delete(UserCircleCache userCircleCache) async {
    int count = await deleteByID(userCircleCache.usercircle);
    globalState.deletedUserCircleID.add(userCircleCache.usercircle!);

    return count;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<int> deleteByID(String? userCircleID) async {
    _database = await DatabaseProvider.db.database;

    int count = await _database!
        .delete(tableName, where: '$usercircle = ?', whereArgs: [userCircleID]);

    globalState.deletedUserCircleID.add(userCircleID!);

    return count;
  }

  static Future<bool> openClosedForUser(String userid) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where = "$hiddenOpen=1 and $user=?";
    whereArgs = [userid];

    List<Map> results = await _database!.query(tableName,
        columns: [
          usercircle,
        ],
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    return results.isNotEmpty;
  }

  static Future<List<String?>> readOpenGuardedForFurnace(
      int? userFurnaceID, String? userid) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where = "$userFurnace = ? and $hiddenOpen=1 and $user=?";
    whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: [
          usercircle,
        ],
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    //Convert the map to a list of strings for the furnace
    List<String?> openGuardedResults = [];
    for (var result in results) {
      openGuardedResults.add(result[usercircle]);
    }

    return openGuardedResults;
  }

  static Future<List<UserCircleCache>> readAllForLibrary(
      int? userFurnaceID, String? userid,
      {UserCircleCache? userCircleCache}) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    if (userCircleCache == null) {
      where =
          "$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and $guarded=0 and $closed=0 and $user=?";
      whereArgs = [userFurnaceID, userid];
    } else {
      where =
          "$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and ($guarded=0 or $usercircle = ?) and $closed=0 and $user=?";
      whereArgs = [userFurnaceID, userCircleCache.usercircle!, userid];
    }

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static Future<List<UserCircleCache>> readHiddenForFurnace(
      int? userFurnaceID, String? userid) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where =
        where = "$userFurnace = ? and $hidden=1 and $hiddenOpen=0 and $user=?";
    whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    return userCircles;
  }

  static Future<List<UserCircleCache>> readAll() async {
    _database = await DatabaseProvider.db.database;

    // String where;
    //List whereArgs;

    //where = "$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and $user=?";
    //whereArgs = [userFurnaceID, userid];

    //debugPrint("TableUserCircleCache.readAll start: ${DateTime.now()}");

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        //where: where,
        //whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static Future<List<UserCircleCache>> readAllForCM(
      int? userFurnaceID, String? userid) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where = "$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and $user=?";
    whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static Future<List<UserCircleCache>> readAllForUserFurnaces(
      List<UserFurnace> userFurnaces) async {
    _database = await DatabaseProvider.db.database;

    ///get the ids into a string array

    List<String> userFurnaceIDs = [];
    for (var userFurnace in userFurnaces) {
      userFurnaceIDs.add(userFurnace.pk!.toString());
    }

    String where;
    List whereArgs;

    where = "($hidden=0 or $hiddenOpen=1) and $closed = 0";
    //"$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and $closed = 0 and $user=?";
    where =
        '$where and $userFurnace IN (${userFurnaceIDs.map((e) => "'$e'").join(', ')})';

    //whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        //whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    //debugPrint("TableUserCircleCache.readAllForUserFurnace end: ${DateTime.now()}");

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static Future<List<UserCircleCache>> readHiddenAndClosedDMForFurnaces(
      List<UserFurnace> userFurnaces) async {
    _database = await DatabaseProvider.db.database;

    ///get the ids into a string array
    List<String> userFurnaceIDs = [];
    for (var userFurnace in userFurnaces) {
      userFurnaceIDs.add(userFurnace.pk!.toString());
    }

    String where;

    where = "$dm = 1 AND ($hidden = 1 OR $closed = 1)";
    where =
        '$where and $userFurnace IN (${userFurnaceIDs.map((e) => "'$e'").join(', ')})';

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, where: where, orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    return userCircles;
  }

  static Future<List<UserCircleCache>> readAllForUsers(
      List<String> userIDs) async {
    _database = await DatabaseProvider.db.database;

    String where = '$user IN (${userIDs.map((e) => "'$e'").join(', ')})';

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, where: where, orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache userCircleCache =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(userCircleCache);
    }
    return userCircles;
  }

  static Future<List<UserCircleCache>> readAllForUserFurnace(
      int? userFurnaceID, String? userid) async {
    _database = await DatabaseProvider.db.database;

    //debugPrint("TableUserCircleCache.readAllForUserFurnace start: ${DateTime.now()}");

    String where;
    List whereArgs;

    where =
        "$userFurnace = ? and ($hidden=0 or $hiddenOpen=1) and $closed = 0 and $user=?";
    whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache userCircleCache =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(userCircleCache);
    }

    //debugPrint("TableUserCircleCache.readAllForUserFurnace end: ${DateTime.now()}");

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static Future<List<UserCircleCache>> readAllForBackup(
      int? userFurnaceID, String? userid) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where = "$userFurnace = ? and $user=?";
    whereArgs = [userFurnaceID, userid];

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns,
        where: where,
        whereArgs: whereArgs,
        orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    // debugPrint(userCircles.length.toString());
    return userCircles;
  }

  static restoreEncrypted(UserCircle userCircle) async {
    UserCircleCache retValue = await read(userCircle.id!);

    userCircle.prefName = retValue.prefName;
  }

  static bool _isUnique(List<UserCircleCache> existing, String name) {
    bool retValue = true;

    for (UserCircleCache userCircleCache in existing) {
      if (userCircleCache.prefName == name) {
        retValue = false;
      }
    }

    return retValue;
  }

  static Future<String> returnUniqueName(
      int furnaceID, String userID, String name) async {
    String retValue = name;

    int counter = 0;

    List<UserCircleCache> existing =
        await readAllForUserFurnace(furnaceID, userID);

    bool isUnique = false;

    do {
      isUnique = _isUnique(existing, retValue);

      counter += 1;

      if (!isUnique) retValue = '$name ($counter)';
    } while (!isUnique);

    //debugPrint('retValue');

    return retValue;
  }

  static Future<UserCircleCache> read(String usercircleID) async {
    try {
      _database = await DatabaseProvider.db.database;

      UserCircleCache retValue = UserCircleCache();

      List<Map> results = await _database!.query(tableName,
          columns: selectColumns,
          where: "$usercircle = ?",
          whereArgs: [usercircleID]);
      //orderBy: "$lastItemUpdate DESC");

      if (results.isNotEmpty) {
        retValue =
            UserCircleCache.fromJson(results.first as Map<String, dynamic>);
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<List<UserCircleCache>> readUserCircleCacheByCircleID(
      String? circleID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: selectColumns, where: "$circle = ?", whereArgs: [circleID]);
    //orderBy: "$lastItemUpdate DESC");

    List<UserCircleCache> userCircles = [];
    for (var result in results) {
      UserCircleCache furnace =
          UserCircleCache.fromJson(result as Map<String, dynamic>);
      userCircles.add(furnace);
    }

    return userCircles;
  }

  static Future<String> getUserCircleID(String userID, String circleID) async {
    try {
      UserCircleCache userCircleCache =
          await readUserCircleCacheByCircleAndUser(circleID, userID);

      if (userCircleCache.usercircle != null) {
        return userCircleCache.usercircle!;
      } else {
        return '';
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<UserCircleCache> readUserCircleCacheByCircleAndUsers(
      String circleID, List<String> userIDs) async {
    try {
      _database = await DatabaseProvider.db.database;

      late UserCircleCache retValue;

      String where =
          '$circle = ? and $user IN (${userIDs.map((e) => "'$e'").join(', ')})';

      List<Map> results = await _database!.query(tableName,
          columns: selectColumns, where: where, whereArgs: [circleID]);

      if (results.isNotEmpty) {
        retValue =
            UserCircleCache.fromJson(results.first as Map<String, dynamic>);
      } else {
        retValue = UserCircleCache();
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<UserCircleCache> readUserCircleCacheByCircleAndUser(
      String circleID, String userID) async {
    try {
      _database = await DatabaseProvider.db.database;

      if (_database == null) throw ('compute cant handle the datas');

      late UserCircleCache retValue;

      List<Map> results = await _database!.query(tableName,
          columns: selectColumns,
          where: "$circle = ? and $user = ?",
          whereArgs: [circleID, userID]);
      //orderBy: "$lastItemUpdate DESC");

      if (results.isNotEmpty) {
        retValue =
            UserCircleCache.fromJson(results.first as Map<String, dynamic>);
      } else {
        retValue = UserCircleCache();
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<int> countConnectedHiddenCircles(
      List<UserFurnace> furnaceKeys) async {
    _database = await DatabaseProvider.db.database;

    String where =
        '$userFurnace IN (${furnaceKeys.map((e) => "${e.pk}").join(', ')})';

    where =
        '$where AND $user IN (${furnaceKeys.map((e) => "'${e.userid}'").join(', ')})';

    where = '$where AND $hidden = ?';

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        user,
        hidden,
      ],
      where: where,
      whereArgs: [1],
    );

    return results.length;
  }
}
