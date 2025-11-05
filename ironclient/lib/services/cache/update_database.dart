import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:sqflite/sqflite.dart';

class UpdateDatabase {
  static Database? db;

  /*static seedTables() async {
    try {
      //test to see if the table exists, if not add
      db = await DatabaseProvider.db.database;

      int? build = (await globalState.getDevice()).build;

      if (build != null && build = 122) {
        ///insert the first row
        Map<String, dynamic> reducedMap = {
          TableUpdateTracker.convertedCredentials: 0
        };
        await TableUpdateTracker.upsertReducedMap(reducedMap);
      }

    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UpdateDatabase.fixTables: $err');
    }
  }*/

  static fixTables() async {
    try {
      //test to see if the table exists, if not add
      db = await DatabaseProvider.db.database;


       await db!.execute("DROP TABLE ${TableBackgroundTask.tableName}");
       await db!.execute(TableBackgroundTask.columns);

      //await DatabaseProvider.updateIndexes(db!);

      /*await db!.execute(
          "ALTER TABLE ${TableUserFurnace.tableName} RENAME COLUMN ${TableUserFurnace.enableWall} TO 'NOT USED';");

      await db!.execute(
          "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.enableWall} INT;");

       */

      //await TableSubscription.deleteAll();

      // await db!.execute("DROP TABLE ${TablePrompt.tableName}");
      // await db!.execute(TablePrompt.columns);

      // await db!.execute(
      //     "ALTER TABLE ${TablePrompt.tableName} ADD COLUMN ${TablePrompt.jobID} TEXT;");

      //await db!.execute(
      //    "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.role} INT;");

      //await db!.execute("DROP TABLE ${TableUserSetting.tableName}");
      //await db!.execute(TableUserSetting.columns);

      // await db!.execute(TableMember.columns);
      // await db!.execute(
      //     "INSERT INTO ${TableMember.tableName} SELECT * FROM  ${TableMember.oldTableName};");

      //await db.execute(TableMember.columns);

      //await db.execute("DROP TABLE ${TableMember.tableName}");

      //await db!.execute(TableMemberCircle.columns);

      // await db!.execute(
      //   "ALTER TABLE ${TableMemberCircle.tableName} ADD COLUMN ${TableMemberCircle.dm} BIT;");

      /*await TableMember.deleteAll();
      await TableMemberCircle.deleteAll();
      await db!.execute(
          "ALTER TABLE ${TableMember.tableName} ADD COLUMN ${TableMember.avatar} TEXT;");

       */
      //await db!.execute("DROP TABLE ${TableMember.tableName}");
      //await db!.execute(TableMember.columns);

      //try {
      //  await db!.execute(
      //       "ALTER TABLE ${TableCircleObjectCache
      //          .tableName} ADD COLUMN ${TableCircleObjectCache.draft} BIT;");
      //  } catch(err){
//
      // }
      //DatabaseProvider.createView(db, true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UpdateDatabase.fixTables: $err');
    }
  }
}
