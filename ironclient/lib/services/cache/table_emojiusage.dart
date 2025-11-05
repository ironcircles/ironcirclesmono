import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/emojiusage.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TableEmojiUsage {
  static const String tableName = 'emojiusage';
  static const String pk = "pk";
  static const String emoji = "emoji";
  static const String usage = "usage";

  static const String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$emoji TEXT,"
      "$usage INTEGER)";

  static Database? _database;

  TableEmojiUsage._();

  static Future<EmojiUsage?> incrementCount(String pEmoji) async {
    _database = await DatabaseProvider.db.database;
    EmojiUsage? incrementEmoji;

    try {
      incrementEmoji = await readEmoji(pEmoji);

      if (incrementEmoji == null) {
        incrementEmoji = EmojiUsage(emoji: pEmoji, usage: 1);
        incrementEmoji.pk =
            await _database!.insert(tableName, incrementEmoji.toJson());
      } else {
        incrementEmoji.usage++;
        await _database!.update(tableName, incrementEmoji.toJson(),
            where: "$emoji = ?", whereArgs: [incrementEmoji.emoji]);
      }
    } catch (error, trace) { LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return incrementEmoji;
  }

  static Future<EmojiUsage?> readEmoji(String pEmoji) async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(
      tableName,
      columns: [pk, emoji, usage],
      where: "$emoji = ?",
      whereArgs: [pEmoji],
    );

    if (results.isNotEmpty) {
      return EmojiUsage.fromJson(results.first as Map<String, dynamic>);
    } else
      return null;
  }

  static Future<List<EmojiUsage>> readHighestUsage() async {
    _database = await DatabaseProvider.db.database;

    List<Map> results = await _database!.query(tableName,
        columns: [
          pk,
          emoji,
          usage,
        ],
        orderBy: "$usage DESC",
        limit: 21);

    List<EmojiUsage> collection = [];
    results.forEach((result) {
      EmojiUsage individual = EmojiUsage.fromJson(result as Map<String, dynamic>);
      collection.add(individual);
    });

    return collection;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(
      tableName,
    );
  }
}
