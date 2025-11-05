import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/table_deleteidtracker.dart';
import 'package:sqflite/sqflite.dart';

class TableInvitation {
  static const String tableName = 'invitation';
  static const String pk = "pk";
  static const String id = "id";
  static const String invitee = "invitee";
  static const String inviteeID = "inviteeID";
  static const String inviter = "inviter";
  static const String inviterID = "inviterID";
  static const String circleID = "circleID";
  static const String status = "status";
  static const String circleName = "circleName";
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";
  static const String dm = "dm";
  static const String ratchetIndexJson = "ratchetIndexJson";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$id TEXT UNIQUE,"
      "$invitee TEXT,"
      "$inviteeID TEXT,"
      "$inviter TEXT,"
      "$inviterID TEXT,"
      "$circleID TEXT,"
      "$ratchetIndexJson TEXT,"
      "$status TEXT,"
      "$circleName TEXT,"
      "$lastUpdate INT,"
      "$dm BIT,"
      "$created INT)";

  static Database? _database;

  TableInvitation._();

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }

  static Future<bool> upsertCollection(
      InvitationCollection collection, String? pUserID) async {
    _database = await DatabaseProvider.db.database;

    bool retValue = false;

    try {
      //await deleteByUser(pUserID);

      for (Invitation invitation in collection.invitations) {
        invitation.ratchetIndexJson =
            json.encode(invitation.ratchetIndex!.toJson()).toString();

        try {
          await upsert(invitation);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint("TableInvitation.upsertCollection: $err");
        }
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableInvitation.upsertCollection: $err");
      rethrow;
    }

    return retValue;
  }

  static Future<int> invitationExists(Invitation invitation) async {
    _database = await DatabaseProvider.db.database;

    ///assume a new invitation replaces an old

    var count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $id != ? AND $circleID = ?',
        [invitation.id, invitation.circleID]));

    if (count != null && count > 0) {
      //LogBloc.insertLog("deleting existing", "invitationsExist");

      await _database!
          .delete(tableName, where: '$circleID = ? AND $inviteeID = ?', whereArgs: [circleID, invitation.inviteeID]);
    }

    count = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $id = ? OR $circleID = ?',
        [invitation.id, invitation.circleID]));

    return count ?? 0;
  }

  static Future<Invitation> upsert(Invitation invitation) async {
    _database = await DatabaseProvider.db.database;

    try {
      debugPrint('invitation.id: ${invitation.id}');

      var count = await invitationExists(invitation);

      if (count == 0) {
        await _database!.insert(tableName, invitation.toSQL());
      } else {
        Map<String, dynamic> map = invitation.toSQL();

        await _database!.update(tableName, map,
            where: "$id = ?", whereArgs: [invitation.id]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("TableInvitation.upsert: $err");
      rethrow;
    }

    return invitation;
  }

  static Future<int> delete(String pID) async {
    _database = await DatabaseProvider.db.database;

    await TableDeleteIDTracker.upsert(pID);

    int records =
        await _database!.delete(tableName, where: '$id = ?', whereArgs: [pID]);

    return records;
  }

  static Future<List<Invitation>> readForUser(String pUserID) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [
        pk,
        id,
        dm,
        invitee,
        inviteeID,
        inviter,
        inviterID,
        ratchetIndexJson,
        status,
        circleName,
        circleID,
      ],
      where: "$inviteeID = ?",
      whereArgs: [pUserID],
      orderBy: "$created ASC",
    );

    List<Invitation> collection = [];
    results.forEach((result) {
      Invitation individual =
          Invitation.fromSQL(result as Map<String, dynamic>);
      //individual.userFurnace = userFurnace;
      collection.add(individual);
    });

    return collection;
  }
}
