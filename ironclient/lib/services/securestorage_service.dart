import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyType {

  //static const String PUSHTOKEN = 'pushtoken';
  //static const String DEVICEID_DEPRECATED = 'deviceid';
  static const String DB_SECRET_KEY = 'dbsecretkey';
  static const String DB_SECRET_KEY_DEBUG = 'dbsecretkeydebug';
  static const String HIDDEN_PASSPHRASE = 'hiddenpassphrase';
  static const String RESET_CODE_KEY = 'resetcodekey';


  ///deprecated, do not use (used only in main to upgrade existing users
  static const String USER_KEYCHAIN_BACKUP_DEPRECATED = 'userkeychainbackup';
  static const String LAST_KEYCHAIN_BACKUP_DEPRECATED = 'lastkeychainbackup27';
  static const String FREE_COINS = 'freeCoins';

  ///TODO deprecated, replaced with UserSettings table
  //static const String THEME = 'theme';
  //static const String LASTCOLORINDEX = 'lastcolorindex';
  //static const String MESSAGEFEED = 'messagefeed';

  //static const String LAST_LOG_SUBMISSION = 'lastlogsubmission';
  //static const String LAST_SHARED_TO_FURNACE = 'lastsharedtofurnace';
  //static const String LAST_SHARED_TO_CIRCLE = 'lastsharedtocircle';
  //static const String ALLOW_LAST_SHARED_TO_CIRCLE = 'allowlastsharedtocircle';
  //static const String ALLOW_HIDDEN = 'allowhidden';
  //static const String MINOR = 'minor';
  //static const String FONTSIZE = 'fontsize';
  //static const String ACCOUNTTYPE = 'accounttype';
  //static const String SUBMITLOGS = 'submitlogs';
  //static const String CRYPTOGRAPHY_VERSION = 'cryptographyversion';
}

class SecureStorageService {
  late FlutterSecureStorage _storage;

  SecureStorageService() {
    if (Platform.isAndroid) {
      AndroidOptions _getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      _storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    }
    _storage = const FlutterSecureStorage();
  }

  Future debugPrintKey(String keyType) async {
    String? value = await _storage.read(key: keyType);

    if (value == null) {
      debugPrint("$keyType: EMPTY");
    } else {
      debugPrint("$keyType:$value");
    }
  }

  Future<bool> keyExists(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<String> readKey(String keyType) async {
    try {
      // ///Secure storage not available on desktop
      // if (Platform.isMacOS || Platform.isWindows) {
      //   return '';
      // }

      String? retValue = await _storage.read(key: keyType);

      if (retValue == null)
        return '';
      else
        return retValue;
    } catch (err) {
      return '';
    }
  }

  Future<int> readIntKey(String keyType) async {
    String? retValue = await _storage.read(key: keyType);

    if (retValue == null)
      return -1;
    else
      return int.parse(retValue);
  }

  Future writeKey(String keyType, String value) async {
    await _storage.write(key: keyType, value: value);
  }
}
