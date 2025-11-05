/*
import 'dart:async';
import 'package:ironcirclesapp/models/notificationtracker.dart';
import 'package:ironcirclesapp/models/userkeys.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';


class TableKeyIndex {
  static final String tableName = 'keyindex';
  static final String pk = "pk";
  static final String keyIndex = "keyindex";
  static final String userid = "userid";
  static final String generatedHere = "generatedhere";
  //static final String created = "created";

  static final String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$keyIndex TEXT, "
      "$userid TEXT, "
      "$generatedHere BIT )";
      //"$created INTEGER DEFAULT (cast(strftime('%s','now') as int)))";


  static Database? _database;

  TableKeyIndex._();

  static Future<void> upsert(KeyIndex pKeyIndex) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userid = ? AND $keyIndex = ?',
          [pKeyIndex.userid, pKeyIndex.keyIndex]));

      if (count == 0) {
        await _database!.insert(tableName, pKeyIndex.toJson());
      }
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint("TableKeyIndex.upsert: $err");
      throw (err);
    }

    return;
  }

  static Future<bool> keyExists(String user) async {
    _database = await DatabaseProvider.db.database;

    try {
      bool retValue = false;

      int? count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userid = ?', [user]));

      if (count != null && count > 0) retValue = true;

      return retValue;
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint("TableKeyIndex.keyExists: $err");
      throw (err);
    }
  }

  static Future<List<KeyIndex>> readAllForUser(String? user) async {
    _database = await DatabaseProvider.db.database;

    String where;
    List whereArgs;

    where = "$userid=?";
    whereArgs = [user];

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          userid,
          keyIndex,
          generatedHere,
        ],
        where: where,
        whereArgs: whereArgs);

    List<KeyIndex> retValue = [];
    results.forEach((result) {
      KeyIndex keyIndex = KeyIndex.fromJson(result as Map<String, dynamic>);
      retValue.add(keyIndex);
    });

    return retValue;
  }
}

 */
