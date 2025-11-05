import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_agoracall.dart';
import 'package:ironcirclesapp/services/cache/table_backgroundtask.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_deleteidtracker.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_member.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_memberdevice.dart';
import 'package:ironcirclesapp/services/cache/table_prompt.dart';
import 'package:ironcirclesapp/services/cache/table_purchase.dart';
import 'package:ironcirclesapp/services/cache/table_replyobject.dart';
import 'package:ironcirclesapp/services/cache/table_updatetracker.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqlite3/open.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider db = DatabaseProvider._();

  static Database? _database;

  static const version = 92;

  static deleteDatabase() async {
    String path = join(await globalState.getAppPath(), "ironcircles.db");

    await File(path).delete();
  }

  _initDB() async {
    String path = join(await globalState.getAppPath(), "ironcircles.db");

    debugPrint(path);

    ///Does the file already exist?
    bool alreadyExists = File(path).existsSync();

    String? password;

    if (!alreadyExists) {
      ///setup a password
      password = SecureRandomGenerator.generateString(
          length: 20, charset: SecureRandomGenerator.alphaNum);
      await globalState.secureStorageService.writeKey(
          kDebugMode && globalState.isDesktop() ? KeyType.DB_SECRET_KEY_DEBUG : KeyType.DB_SECRET_KEY,
          password);
    } else {
      ///was the database encrypted?
      password = await globalState.secureStorageService.readKey(
          kDebugMode && globalState.isDesktop() ? KeyType.DB_SECRET_KEY_DEBUG : KeyType.DB_SECRET_KEY);

      if (password.isEmpty) {
        password = null;
      }
    }

    debugPrint('password: $password');

    if (Platform.isWindows || Platform.isLinux) {
      final dbFactory = ffi.createDatabaseFactoryFfi(ffiInit: ffiInit);

      path = join(await globalState.getAppPath(), "ironcircles.db");

      _database = await dbFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
            version: version,
            onUpgrade: _onUpgrade,
            onConfigure: (db) async {
              /// This is the part where we pass the "password"
              await db.rawQuery("PRAGMA KEY='$password'");
            },
            onCreate: (Database db, int version) async {
              await _createTables(db);
            }),
      );
    } else {
      _database = await sqlcipher.openDatabase(path,
          version: version,
          onOpen: (db) {},
          password: password,
          onUpgrade: _onUpgrade, onCreate: (Database db, int version) async {
        await _createTables(db);
      });
    }
  }

  void ffiInit() {
    open.overrideForAll(sqlcipherOpen);
  }

  DynamicLibrary sqlcipherOpen() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('sqlcipher.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libsqlite3.so');
    } else {
      return DynamicLibrary.process();
    }
  }

  _createTables(Database db) async {
    // When creating the db, create the tables
    await db.execute(TableUserFurnace.columns);
    await db.execute(TableUserCircleCache.columns);
    await db.execute(TableCircleObjectCache.columns);
    await db.execute(TableEmojiUsage.columns);
    await db.execute(TableCircleListMaster.columns);
    await db.execute(TableActionRequiredCache.columns);
    await db.execute(TableCircleCache.columns);
    await db.execute(TableNotificationTracker.columns);
    await db.execute(TableRatchetKeyUser.columns);
    await db.execute(TableRatchetKeySender.columns);
    await db.execute(TableRatchetKeyReceiver.columns);
    await db.execute(TableCircleLastLocalUpdate.columns);
    await db.execute(TableUserCircleEnvelope.columns);
    await db.execute(TableInvitation.columns);
    await db.execute(TableLog.columns);
    await db.execute(TableMember.columns);
    await db.execute(TableMemberCircle.columns);
    await db.execute(TableUserSetting.columns);
    await db.execute(TableSubscription.columns);
    await db.execute(TableMagicCode.columns);
    await db.execute(TableDevice.columns);
    await db.execute(TableMemberDevice.columns);
    await db.execute(TableUpdateTracker.columns);
    await db.execute(TableDeleteIDTracker.columns);
    await db.execute(TablePrompt.columns);
    await db.execute(TablePurchase.columns);
    await db.execute(TableReplyObjectCache.columns);
    await db.execute(TableBackgroundTask.columns);
    await db.execute(TableAgoraCall.columns);
    await createView(db, false);
    await updateIndexes(db);
  }

  // UPGRADE DATABASE TABLES
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {

    if (oldVersion < 67) {
      try {
        await db.execute(
            "ALTER TABLE ${TableMember.tableName} ADD COLUMN ${TableMember.connected} BIT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 68) {
      try {
        await db.execute(
            "ALTER TABLE ${TableCircleCache.tableName} ADD COLUMN ${TableCircleCache.toggleEntryVote} BIT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 69) {
      try {
        await db.execute(
            "ALTER TABLE ${TableInvitation.tableName} ADD COLUMN ${TableInvitation.circleID} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 70) {
      try {
        await db.execute(TableDeleteIDTracker.columns);
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 71) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.link} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 72) {
      try {
        await db.execute(
            "ALTER TABLE ${TableMember.tableName} ADD COLUMN ${TableMember.blocked} BIT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 73) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserSetting.tableName} ADD COLUMN ${TableUserSetting.firstTimeInFeed} BIT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 74) {
      try {
        await db.execute(
            "ALTER TABLE ${TableCircleCache.tableName} ADD COLUMN ${TableCircleCache.toggleMemberPosting} BIT;");
        await db.execute(
            "ALTER TABLE ${TableCircleCache.tableName} ADD COLUMN ${TableCircleCache.toggleMemberReacting} BIT;");
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.memberAutonomy} BIT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 75) {
      try {
        await db.execute(
            "ALTER TABLE ${TableCircleCache.tableName} ADD COLUMN ${TableCircleCache.expiration} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 76) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserSetting.tableName} ADD COLUMN ${TableUserSetting.ironCoin} INT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 77) {
      try {
        await db.execute(TablePrompt.columns);
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 78) {
      try {
        await db.execute(TablePurchase.columns);
        // await db.execute(
        //     "ALTER TABLE ${TablePurchase.tableName} ADD COLUMN ${TablePurchase.quantity} INT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 79) {
      try {
        await db.execute(TableReplyObjectCache.columns);
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 80) {
      try {
        await db.execute(
            "ALTER TABLE ${TableDevice.tableName} ADD COLUMN ${TableDevice.kyberSharedSecret} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 81) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserSetting.tableName} ADD COLUMN ${TableUserSetting.sortAlpha} INT;");
        await db.execute(
            "ALTER TABLE ${TableUserSetting.tableName} ADD COLUMN ${TableUserSetting.lastAccessedDate} INT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 84) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.forgeToken} TEXT;");
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.forgeUserId} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 86) {
      try {
        // await db.execute(
        //     "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.selfHosted} INT;");
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.passwordHash} TEXT;");
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.passwordNonce} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 87) {
      try {
        await db.execute(
            "ALTER TABLE ${TableUserFurnace.tableName} ADD COLUMN ${TableUserFurnace.type} INT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 90) {
      try {
        await db.execute(
            "ALTER TABLE ${TableDevice.tableName} ADD COLUMN ${TableDevice.manufacturerID} TEXT;");
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 91) {
      try {
        await db.execute(TableBackgroundTask.columns);
      } catch (err) {
        debugPrint('$err');
      }
    }

    if (oldVersion < 92) {
      try {
        await db.execute(TableAgoraCall.columns);
      } catch (err) {
        debugPrint('$err');
      }
    }

    ///update indexes with any version change
    await updateIndexes(db);
  }

  static updateIndexes(Database db) async {
    ///start time
    debugPrint('Update indexes start: ${DateTime.now()}');

    try {
      try {
        await db.execute(
            "DROP INDEX ${TableCircleObjectCache.tableName}_circle_type_index ");
      } catch (err) {
        debugPrint('$err');
      }
      try {
        await db.execute(
            "DROP INDEX ${TableUserCircleCache.tableName}_userfurnace_index ");
      } catch (err) {
        debugPrint('$err');
      }

      try {
        await db.execute(
            "DROP INDEX ${TableRatchetKeyReceiver.tableName}_receiver_index ");
      } catch (err) {
        debugPrint('$err');
      }

      await db.execute(
          'CREATE INDEX IF NOT EXISTS ${TableUserCircleCache.tableName}_userfurnace_index ON ${TableUserCircleCache.tableName}(${TableUserCircleCache.lastItemUpdate}, ${TableUserCircleCache.userFurnace});');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS ${TableCircleObjectCache.tableName}_circle_type_index ON ${TableCircleObjectCache.tableName}(${TableCircleObjectCache.created}, ${TableCircleObjectCache.circleid}, ${TableCircleObjectCache.type});');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS ${TableRatchetKeyReceiver.tableName}_receiver_index ON ${TableRatchetKeyReceiver.tableName}(${TableRatchetKeyReceiver.created});');

      debugPrint('Update indexes end time: ${DateTime.now()}');
    } catch (err) {
      debugPrint('$err');
    }
  }

  static createView(var db, bool drop) async {
    try {
      if (drop)
        await db.execute("DROP VIEW ${TableCircleObjectCache.byCircleIDView}");
    } catch (err) {
      debugPrint('could not drop view');
    }

    await db.execute(
        "CREATE VIEW ${TableCircleObjectCache.byCircleIDView} AS SELECT ${TableCircleObjectCache.pk}, ${TableCircleObjectCache.circleid}, ${TableCircleObjectCache.circleObjectid}, ${TableCircleObjectCache.pinned}, ${TableCircleObjectCache.draft}, ${TableCircleObjectCache.read}, ${TableCircleObjectCache.circleObjectJson}, ${TableCircleObjectCache.seed}, ${TableCircleObjectCache.type}, ${TableCircleObjectCache.creator}, ${TableCircleObjectCache.thumbnailTransferState}, ${TableCircleObjectCache.fullTransferState}, ${TableCircleObjectCache.created}, ${TableCircleObjectCache.lastUpdate}, ${TableCircleObjectCache.retryDecrypt} FROM ${TableCircleObjectCache.tableName} ORDER BY ${TableCircleObjectCache.created} DESC");
  }

  Future<Database?> get database async {
    if (_database != null) {
      //debugPrint("ALREADY INITIALIZED********************");
      return _database;
    } else {
      // if _database is null we instantiate it
      await _initDB();
      //debugPrint("INITIALIZING********************");
      return _database;
    }
  }

  clearDatabase() async {
    try {
      ///Device name
      ///Fire token

      //clear last access box
      //CircleLastUpdate.deleteAll();

      ///clear sqllite in parallel
      TableUserFurnace.deleteAll();
      TableCircleObjectCache.deleteAll();
      TableUserCircleCache.deleteAll();
      TableCircleLastLocalUpdate.deleteAll();
      TableActionRequiredCache.deleteAll();
      TableUserCircleEnvelope.deleteAll();
      TableInvitation.deleteAll();
      TableLog.deleteAll();
      TableMember.deleteAll();
      TableMemberCircle.deleteAll();
      TableUserSetting.deleteAll();
      TableCircleCache.deleteAll();
      TableRatchetKeyUser.deleteAll(TableRatchetKeyUser.tableName);
      TableRatchetKeySender.deleteAll(TableRatchetKeySender.tableName);
      TableRatchetKeyReceiver.deleteAll(TableRatchetKeyReceiver.tableName);
      TableEmojiUsage.deleteAll();
      TableCircleListMaster.deleteAll();
      TableNotificationTracker.deleteAll();
      TablePurchase.deleteAll();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("clearDatabase - $err");
    }
  }

  String _red(String string) => '\x1B[31m$string\x1B[0m';

  String _yellow(String string) => '\x1B[32m$string\x1B[0m';

  DynamicLibrary openSQLCipherOnWindows({bool useOpenSSLEmbededDlls = true}) {
    const assets_package_dir =
        'data\\flutter_assets\\packages\\sqlcipher_library_windows\\assets';

    const sqlcipher_windows_dll = 'sqlcipher.dll';

    ///relative path to OpenSSL library 1
    const openssl_lib_crypto_dll = 'libcrypto-1_1-x64.dll';

    ///relative path to OpenSSL library 2
    const openssl_lib_ssl_dll = 'libssl-1_1-x64.dll';

    late DynamicLibrary library;

    String exeDirPath = File(Platform.resolvedExecutable).parent.path;
    debugPrint('executableDirectoryPath: $exeDirPath');

    String packageAssetsDirPath =
        normalize(join(exeDirPath, assets_package_dir));
    debugPrint('packageAssetsDirectoryPath: $packageAssetsDirPath');

    //OpenSSL libcryptoxxx.dll FullPath  destination
    String libCryptoDllDestFullPath =
        normalize(join(exeDirPath, openssl_lib_crypto_dll));
    //OpenSSL libsslxxx.dll FullPath  destination
    String libSSLDllDestFullPath =
        normalize(join(exeDirPath, openssl_lib_ssl_dll));

    //OpenSSL libcryptoxxx.dll FullPath  source
    String libCyptoDllSourceFullPath =
        normalize(join(packageAssetsDirPath, openssl_lib_crypto_dll));
    //OpenSSL libsslxxx.dll FullPath  source
    String libSSLDllSourceFullPath =
        normalize(join(packageAssetsDirPath, openssl_lib_ssl_dll));

    //Chek if it is needed to copy DLLs in another directory that my_app.exe could use when executing
    if (useOpenSSLEmbededDlls) {
      bool needToCopy = false;
      //Check if one of destination libraries does not exists
      if (File(libCryptoDllDestFullPath).existsSync() == false ||
          File(libSSLDllDestFullPath).existsSync() == false) {
        //Re sync both libraries
        needToCopy = true;
      } else if (File(libCryptoDllDestFullPath).existsSync() == true ||
          File(libSSLDllDestFullPath).existsSync() == true) {
        //Check if sizes are differents
        needToCopy = (File(libCryptoDllDestFullPath).lengthSync() !=
                File(libCyptoDllSourceFullPath).lengthSync()) ||
            (File(libSSLDllDestFullPath).lengthSync() !=
                File(libSSLDllSourceFullPath).lengthSync());
      }
      //Copy DLLs
      if (needToCopy) {
        File(libCyptoDllSourceFullPath).copySync(libCryptoDllDestFullPath);
        debugPrint(_yellow(
            '$openssl_lib_crypto_dll: copied from $libCyptoDllSourceFullPath to $libCryptoDllDestFullPath'));
        File(libSSLDllSourceFullPath).copySync(libSSLDllDestFullPath);
        debugPrint(_yellow(
            '$openssl_lib_ssl_dll: copied from $libSSLDllSourceFullPath to $libSSLDllDestFullPath'));
      }
    }

    //Now load the SQLCipher DLL
    try {
      String sqliteLibraryPath =
          normalize(join(packageAssetsDirPath, sqlcipher_windows_dll));
      debugPrint('SQLCipherLibraryPath: $sqliteLibraryPath');

      library = DynamicLibrary.open(sqliteLibraryPath);

      debugPrint(_yellow("SQLCipher successfully loaded"));
    } catch (e) {
      try {
        debugPrint(e.toString());
        debugPrint(_red("Failed to load SQLCipher from library file, "
            "trying loading from system..."));

        library = DynamicLibrary.open('sqlcipher.dll');

        debugPrint(_yellow("SQLCipher successfully loaded"));
      } catch (e) {
        debugPrint(e.toString());
        debugPrint(_red("Fail to load SQLCipher."));
      }
    }
    return library;
  }
}
