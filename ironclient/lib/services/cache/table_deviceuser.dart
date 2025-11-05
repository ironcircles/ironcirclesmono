
/*
class TableDeviceUser {
  static final String tableName = 'deviceuser';
  static final String pk = "pk";
  static final String userid = "userid";
  static final String lastLogin = "lastLogin";

  static final String columns = "CREATE TABLE $tableName ("
      "$pk INTEGER PRIMARY KEY,"
      "$userid TEXT,"
      "$lastLogin INTEGER)";

  static Database? _database;

  TableDeviceUser._();


  static Future<DeviceUser> upsert(DeviceUser deviceUser) async {
    _database = await DatabaseProvider.db.database;

    try {
      var count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $userid = ?', [deviceUser.userid]));

      if (count == 0) {
        deviceUser.pk = await _database!.insert(tableName, deviceUser.toJson());
      } else {
        await _database!.update(tableName, deviceUser.toJson(),
            where: "$userid = ?", whereArgs: [deviceUser.userid]);
      }
    } catch (error, trace) { LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    return deviceUser;
  }

  static Future<DeviceUser> insert(String userID) async {

    DeviceUser deviceUser = DeviceUser.init(userID);

    var now = DateTime.now();
    deviceUser.lastLogin = now.millisecondsSinceEpoch;

    _database = await DatabaseProvider.db.database;

    await _database!.insert(tableName, deviceUser.toJson());
    return deviceUser;
  }

  static Future<DeviceUser?> readMostRecent() async {
    _database = await DatabaseProvider.db.database;

    List<Map> maps = await _database!.query(tableName,
        columns: [pk, userid, lastLogin], orderBy:"$lastLogin DESC" );
    if (maps.length > 0) {
      return DeviceUser.fromJson(maps.first as Map<String, dynamic>);
    }

    return null;
  }

  static Future<int> deleteAll() async {
    _database = await DatabaseProvider.db.database;

    return await _database!.delete(tableName,);
  }
}

 */