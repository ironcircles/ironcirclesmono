import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/externalkeys.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:path/path.dart' as p;

class KeychainBackupService {
  static final BlobGenericService _blobGenericService = BlobGenericService();
  static final BlobUrlsService _blobUrlsService = BlobUrlsService();

  static Future<bool> toggle(
      UserFurnace userFurnace, bool autoKeychainBackup) async {
    try {
      String url = userFurnace.url! + Urls.KEYCHAINBACKUP_TOGGLE;

      Map map = {
        'autoKeychainBackup': autoKeychainBackup,
      };

      debugPrint(url);

      Device device = await globalState.getDevice();
      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        //Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (autoKeychainBackup == false) {
          if (userFurnace.authServer!) {
            await globalState.userSetting
                .setLastIncremental(DateTime.parse('20200101'));
            await globalState.userSetting
                .setLastFull(DateTime.parse('20200101'));
          } else {
            UserSetting? userSetting =
                await TableUserSetting.read(userFurnace.userid!);

            if (userSetting != null) {
              userSetting.setLastIncremental(DateTime.parse('20200101'));
              userSetting.setLastFull(DateTime.parse('20200101'));

              Map<String, dynamic> reducedMap = {
                TableUserSetting.lastIncremental:
                    userSetting.lastIncremental!.millisecondsSinceEpoch,
                TableUserSetting.lastFull:
                    userSetting.lastFull!.millisecondsSinceEpoch,
              };
              await TableUserSetting.upsertReducedMap(userSetting, reducedMap);
            }
          }

          globalState.secureStorageService.writeKey(
              KeyType.LAST_KEYCHAIN_BACKUP_DEPRECATED + userFurnace.userid!,
              '');
        }

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("KeychainBackupService.toggle: $error");

      rethrow;
    }

    return false;
  }

  static Future<void> _progressIncrementalCallback(
      UserFurnace userFurnace,
      String keychain,
      String lastKeychainBackup,
      String location,
      bool upload,
      int progress) async {
    if (upload) {
      if (progress == -1) {
        //_globalEventBloc.removeOnError(circleObject);

        return;
      } else if (progress == 100) {
        /*SecureStorageService.writeKey(
            KeyType.LAST_KEYCHAIN_BACKUP + userFurnace.userid!,
            lastKeychainBackup);

         */

        _updateKeyChainBackup(userFurnace, keychain, lastKeychainBackup,
            userFurnace.url! + Urls.KEYCHAINBACKUP);

        if (userFurnace.authServer!) {
          await globalState.userSetting
              .setLastIncremental((DateTime.parse(lastKeychainBackup)));
        } else {
          UserSetting? userSetting =
              await TableUserSetting.read(userFurnace.userid!);

          if (userSetting != null) {
            userSetting
                .setLastIncremental((DateTime.parse(lastKeychainBackup)));
          }
        }

        //remove the file
        File file = File(
            p.join(await FileSystemService.getKeyChainBackupPath(), keychain));
        FileSystemService.safeDelete(file);
      }
    }
  }

  static Future<void> _progressFullCallback(
      UserFurnace userFurnace,
      String keychain,
      String lastKeychainBackup,
      String location,
      bool upload,
      int progress) async {
    try {
      if (upload) {
        if (progress == -1) {
          //_globalEventBloc.removeOnError(circleObject);

          return;
        } else if (progress == 100) {
          /*SecureStorageService.writeKey(
            KeyType.LAST_KEYCHAIN_BACKUP + userFurnace.userid!,
            lastKeychainBackup);

         */

          _updateKeyChainBackup(userFurnace, keychain, lastKeychainBackup,
              userFurnace.url! + Urls.KEYCHAINFULLBACKUP);

          if (userFurnace.authServer!) {
            await globalState.userSetting
                .setLastFull((DateTime.parse(lastKeychainBackup)));
          } else {
            UserSetting? userSetting =
                await TableUserSetting.read(userFurnace.userid!);

            if (userSetting != null) {
              userSetting.setLastFull((DateTime.parse(lastKeychainBackup)));
            }
          }

          ///remove the file
          File file = File(p.join(
              await FileSystemService.getKeyChainBackupPath(), keychain));
          FileSystemService.safeDelete(file);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static Future<bool> _updateKeyChainBackup(UserFurnace userFurnace,
      String keychain, String lastKeychainBackup, String url) async {
    try {
      //String url = userFurnace.url! + Urls.KEYCHAINBACKUP;

      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'device': device.uuid,
        'keychain': keychain,
      };

      File file = File(p.join(await globalState.getAppPath(), keychain));

      if (file.existsSync()) {
        map['size'] = file.lengthSync();
      }


      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        //Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (file.existsSync()) {
          file.delete();
        }
        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("KeychainBackupService.restore: $error");

      rethrow;
    }

    return false;
  }

  /*
  static Future<String> _backupFurnace(UserFurnace userFurnace,
      List<UserFurnace> linkedFurnaces, bool force) async {
    try {
      String url = userFurnace.url! + Urls.KEYCHAINBACKUP;

      late String backupSecret;
      late UserSetting? userSetting;

      if (userFurnace.authServer!) {
        backupSecret = await UserSetting.getSafeBackupKey(
            globalState.userSetting, userFurnace.userid!);
        userSetting = globalState.userSetting;
      } else {
        userSetting = await TableUserSetting.read(userFurnace.userid!);

        if (userSetting == null) {
          LogBloc.insertLog('UserSetting is null for: ${userFurnace.userid!} ',
              '_backupFurnace');

          ///this will only happen for users transitioning to 1.1.12 and for non auth networks

          backupSecret = await globalState.secureStorageService.readKey(
              KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED + userFurnace.userid!);

          if (backupSecret.isNotEmpty) {
            LogBloc.postLog('Should not see this!! ${userFurnace.userid!}',
                'KeyChangBackupService._backupFurnace');

            userSetting = UserSetting(
                id: userFurnace.userid!,
                username: userFurnace.username!,
                fontSize: 16,
                theme: globalState.userSetting.theme,
                backupKey: backupSecret);

            TableUserSetting.upsert(userSetting);
          } else {
            LogBloc.insertLog(
                'backup key is empty for: ${userFurnace.userid!} ',
                'backup service');

            return 'no backup key';
          }
        } else {
          backupSecret = userSetting.backupKey;
        }
      }

      if (backupSecret.isEmpty) {
        LogBloc.postLog(
            'Backup key is empty for: ${userFurnace.userid!}, checking SecureStorageService.readKey',
            'backup service');

        ///there is no backup key, so try local storage
        backupSecret = await globalState.secureStorageService.readKey(
            KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED + userFurnace.userid!);

        if (backupSecret.isNotEmpty) {
          LogBloc.postLog('Should not see this either! ${userFurnace.userid!}',
              'KeyChainBackupService._backupFurnace');

          userSetting = UserSetting(
              id: userFurnace.userid!,
              username: userFurnace.username!,
              theme: globalState.userSetting.theme,
              fontSize: 16,
              backupKey: backupSecret);

          TableUserSetting.upsert(userSetting);
        } else if (userFurnace.authServer == false) {
          ///reuse the auth server backup key if it isn't null
          backupSecret = globalState.userSetting.backupKey;

          if (backupSecret.isEmpty) {
            LogBloc.postLog(
                'backup key is empty for: ${userFurnace.userid!} and for the auth server',
                'backup service');
            return 'no backup key';
          } else {
            userSetting.setBackupKey(backupSecret);
          }
        }
      }

      String lastKeychainBackup = DateTime.now().toString();

      bool full = false;

      if (userSetting.lastFull == null) {
        LogBloc.insertLog(
            'last full is null, user: ${userSetting.id}, furnaceUser: ${userFurnace.userid}, theme: ${userSetting.theme}, fontSize: ${userSetting.fontSize}, backupKey:"${userSetting.backupKey}',
            'backup service');
      }

      if (userSetting.lastFull == null ||
          userSetting.lastFull!
              .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        ///only perform full backups on wifi
        if (await Network.isMobile() == false) {
          ///check kDebugMode because the emulator is always on mobile
          full = true;
        }
      }

      File keychainBackup = await ExternalKeys.saveToFile(
          userFurnace.userid!,
          userFurnace.username!,
          backupSecret,
          force ? force : full,
          userFurnace,
          linkedFurnaces,
          userSetting);

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(userFurnace,
          BlobType.KEYCHAIN_BACKUP, userFurnace.userid!, keychainBackup.path);

      if (urls.location == BlobLocation.S3 ||
          urls.location == BlobLocation.PRIVATE_S3 ||
          urls.location == BlobLocation.PRIVATE_WASABI) {
        url = urls.fileNameUrl;
      } else {
        debugPrint('break');
      }

      _blobGenericService.put(
          userFurnace, url, lastKeychainBackup, urls.location, keychainBackup,
          progressCallback:
              full ? _progressFullCallback : _progressIncrementalCallback);
    } catch (err, trace) {
      if (!err.toString().contains('backup is up to date'))
        LogBloc.insertError(err, trace);
      debugPrint("KeychainBackupService.backup $err");
      //throw (err);

      return err.toString();
    }

    return "backup complete";
  }*/

  static Future<String> backupDevice(UserFurnace network, bool force) async {
    try {
      String url = network.url! + Urls.KEYCHAINBACKUP;

      ///get the usersetting for the specific network
      UserSetting? userSetting = await TableUserSetting.read(network.userid!);

      if (userSetting == null) {
        throw ('UserSetting is null for: ${network.userid!}');
      }

      String backupSecret = userSetting.backupKey;

      if (backupSecret.isEmpty) {
        ///TODO
        ///create a new key
        ///may have to ask user to re-enter their passcode
      }

      String lastKeychainBackup = DateTime.now().toString();

      bool full = force;

      if (userSetting.lastFull == null) {
        LogBloc.insertLog(
            'last full is null, user: ${userSetting.id}, furnaceUser: ${network.userid}, theme: ${userSetting.theme}, fontSize: ${userSetting.fontSize}, backupKey:"${userSetting.backupKey}',
            'backup service');
      }

      if (userSetting.lastFull == null ||
          userSetting.lastFull!
              .isBefore(DateTime.now().subtract(const Duration(days:7)))) {
        ///only perform full backups on wifi
        if (await Network.isMobile() == false) {
          full = true;  ///TODO commented out full backups until we get performance working on the export
        }
      }

      File keychainBackup = await ExternalKeys.saveAllToFile(
          backupSecret, full, network, userSetting);

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(network,
          BlobType.KEYCHAIN_BACKUP, network.userid!, keychainBackup.path);

      if (urls.location == BlobLocation.S3 ||
          urls.location == BlobLocation.PRIVATE_S3 ||
          urls.location == BlobLocation.PRIVATE_WASABI) {
        url = urls.fileNameUrl;
      } else {
        debugPrint('break');
      }

      _blobGenericService.put(
          network, url, lastKeychainBackup, urls.location, keychainBackup,
          progressCallback:
              full ? _progressFullCallback : _progressIncrementalCallback);
    } catch (err, trace) {
      if (!err.toString().contains('backup is up to date'))
        LogBloc.insertError(err, trace);
      debugPrint("KeychainBackupService.backup $err");
      //throw (err);

      return err.toString();
    }

    return "backup complete";
  }
  //
  // static Future<String> backup({bool force = false}) async {
  //   try {
  //     List<UserFurnace> userFurnaces =
  //         await TableUserFurnace.readAllForUser(globalState.user.id!);
  //
  //     List<UserFurnace> authAndLinked = userFurnaces
  //         .where((element) =>
  //             element.linkedUser == globalState.user.id! &&
  //             element.connected == true)
  //         .toList();
  //     authAndLinked.add(globalState.userFurnace!);
  //
  //     await _backupFurnace(globalState.userFurnace!, authAndLinked, force);
  //
  //     ///backup other
  //     List<UserFurnace> nonLinked = userFurnaces
  //         .where((element) => (element.linkedUser != globalState.user.id! &&
  //             element.authServer == false &&
  //             element.connected == true))
  //         .toList();
  //
  //     for (UserFurnace userFurnace in nonLinked) {
  //       await _backupFurnace(userFurnace, [userFurnace], force);
  //     }
  //   } catch (err, trace) {
  //     if (!err.toString().contains('backup is up to date'))
  //       LogBloc.insertError(err, trace);
  //     debugPrint("KeychainBackupService.backup $err");
  //     //throw (err);
  //
  //     return err.toString();
  //   }
  //
  //   return "backup complete";
  // }

  static Future<bool> _restoreKeyChainFiles(UserFurnace userFurnace,
      String userID, String passcode, String keyfile, String location) async {
    try {
      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.KEYCHAIN_BACKUP, keyfile);

      //String fileName = "${globalState.getAppPath()}/$keyfile";

      String fileName = p.join(await globalState.getAppPath(), keyfile);

      await _blobGenericService.get(userFurnace, location, blobUrl.fileNameUrl,
          fileName, userFurnace.userid!,
          progressCallback: _progressIncrementalCallback);

      await ExternalKeys.putFile(userID, File('${fileName}enc'), passcode);

      return true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("KeychainBackupService._restoreKeyChainFiles: $err");
      rethrow;
    }
  }

  static Future<bool> restore(
      UserFurnace userFurnace, String userID, String passcode, bool pullExtra) async {
    try {
      String url =
          userFurnace.url! + Urls.KEYCHAINRESTORE; // + userFurnace.userid!;

      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'device': device.uuid,
        'userid': userID,
        'pullExtra': pullExtra,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        List keyFiles = jsonResponse["keychainBackups"];

        int count = 1;

        for (var keyFile in keyFiles) {
          if (count >= 13) {
            debugPrint('stop');
          }

          count = count + 1;
          try {
            await _restoreKeyChainFiles(userFurnace, userID, passcode,
                keyFile["keychain"], keyFile["location"]); //wait on the results

            /// got at least one
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('KeychainBackupService.restore: $err');
          }
        }

        TableUserSetting.setBackupKey(userID, passcode);

        UserSetting? userSetting = await TableUserSetting.read(userID);

        if (userSetting != null) {
          userSetting.setLastIncremental(DateTime.now());
          userSetting.setLastFull(DateTime.now());

          Map<String, dynamic> reducedMap = {
            TableUserSetting.lastIncremental:
                userSetting.lastIncremental!.millisecondsSinceEpoch,
            TableUserSetting.lastFull:
                userSetting.lastFull!.millisecondsSinceEpoch,
          };
          await TableUserSetting.upsertReducedMap(userSetting, reducedMap);
        }

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("KeychainBackupService.restore: $error");

      rethrow;
    }

    return false;
  }
}
