import 'dart:convert'; //to convert json to maps and vice versa
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

const String DIVIDER = 'KEY_DIVIDER\n';
const String DIVIDER_NO_RETURN = 'KEY_DIVIDER';

class ExternalKeys {

  static Future<File> saveAllToFile(
      String passphrase,
      bool full,
      UserFurnace userFurnace,
      UserSetting userSetting,
      {bool encrypted = true}) async {
    try {
      if (userFurnace.userid == null || userFurnace.userid!.isEmpty) throw ('invalid userid');

      DateTime lastKeychainBackup =
      DateTime.parse('20200101'); //Beginning of IC time

      if (!full) {
        if (userSetting.lastIncremental == null) {
          ///was there a full backup?

          if (userSetting.lastFull == null) {
            ///run the full backup
            full = true;
          } else {
            lastKeychainBackup = userSetting.lastFull!;
          }
        } else {
          lastKeychainBackup = userSetting.lastIncremental!;
        }
      }

      List<RatchetKey> receiverKeys = [];
      List<RatchetKey> userKeys = [];

      ///TODO once everyone's keys have been sorted, meaning all past v98, then revert this change with the TODO below
      userKeys.addAll(await TableRatchetKeyUser.findRatchetKeysForAllUsers());

      //debugPrint(lastKeychainBackup.millisecondsSinceEpoch.toString());
      debugPrint('******************** TableRatchetKeyReceiver start time: ${DateTime.now()}');

      List<RatchetKey> keys = await TableRatchetKeyReceiver.fetchKeys(
          userFurnace.userid!, lastKeychainBackup);

      debugPrint('******************** TableRatchetKeyReceiver end time: ${DateTime.now()}');

      receiverKeys.addAll(keys);

      if (receiverKeys.isEmpty) {
        throw ('backup is up to date');
      }

      File plainFile = File(p.join(
          await FileSystemService.getKeyChainBackupPath(),
          '${const Uuid().v4()}.plain'));

      ///write the user keys
      for (RatchetKey ratchetKey in userKeys) {
        if (ratchetKey.public == null) continue;

        plainFile.writeAsStringSync(
            '${ratchetKey.keyIndex}\t${ratchetKey.private}\t${ratchetKey.public!}\n',
            mode: FileMode.append);
      }

      plainFile.writeAsStringSync(DIVIDER, mode: FileMode.append);

      //write the receiver keys
      for (RatchetKey ratchetKey in receiverKeys) {
        ratchetKey.created ??= DateTime.parse('20200102');

        plainFile.writeAsStringSync(
            '${ratchetKey.keyIndex}\t${ratchetKey.private}\t${ratchetKey.created!.millisecondsSinceEpoch}\n',
            mode: FileMode.append);
      }

      if (!encrypted) {
        return plainFile;
      } else {
        final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

        List<int> plain = plainFile.readAsBytesSync();

        var encrypted = await cipher.encrypt(plain,
            nonce: cipher.newNonce(),
            secretKey: SecretKey(base64Url.decode(passphrase)));

        //debugPrint(encrypted.cipherText);

        String fileName = p.join(
            await FileSystemService.getKeyChainBackupPath(),
            '${userFurnace.username}_${const Uuid().v4()}');

        File encryptedFile = File('$fileName.enc');

        encryptedFile.writeAsBytesSync(encrypted.nonce, mode: FileMode.append);
        encryptedFile.writeAsBytesSync(encrypted.mac.bytes,
            mode: FileMode.append);
        encryptedFile.writeAsBytesSync(encrypted.cipherText,
            mode: FileMode.append);

        FileSystemService.safeDelete(plainFile);

        return encryptedFile;
      }
    } catch (err, trace) {
      if (!err.toString().contains('backup is up to date')) {
        LogBloc.insertError(err, trace);
      }
      debugPrint('ExternalKeys.saveToFile: $err');

      rethrow;
    }
  }
  //
  // static Future<File> saveToFile(
  //     String userID,
  //     String username,
  //     String passphrase,
  //     bool full,
  //     UserFurnace userFurnace,
  //     List<UserFurnace> userFurnaces,
  //     UserSetting userSetting,
  //     {bool encrypted = true}) async {
  //   try {
  //     if (userID.isEmpty) throw ('invalid userid');
  //
  //     DateTime lastKeychainBackup =
  //         DateTime.parse('20200101'); //Beginning of IC time
  //
  //     if (!full) {
  //       if (userFurnace.authServer!) {
  //         ///it is the auth server
  //         if (globalState.userSetting.lastIncremental != null) {
  //           lastKeychainBackup = globalState.userSetting.lastIncremental!;
  //         } else {
  //           String storedDate = await globalState.secureStorageService.readKey(
  //               KeyType.LAST_KEYCHAIN_BACKUP_DEPRECATED + userID);
  //
  //           if (storedDate.isNotEmpty) {
  //             lastKeychainBackup = DateTime.parse(storedDate).toLocal();
  //           }
  //         }
  //       } else {
  //         ///not the auth server
  //         if (userSetting.lastIncremental != null) {
  //           lastKeychainBackup = userSetting.lastIncremental!;
  //         } else {
  //           String storedDate = await globalState.secureStorageService.readKey(
  //               KeyType.LAST_KEYCHAIN_BACKUP_DEPRECATED + userID);
  //
  //           if (storedDate.isNotEmpty) {
  //             lastKeychainBackup = DateTime.parse(storedDate).toLocal();
  //           }
  //         }
  //       }
  //     }
  //
  //     //List<UserFurnace>? userFurnaces =
  //     //   await TableUserFurnace.readAllForUser(authUserID);
  //
  //     //bool foundSomeKeys = false;
  //
  //     List<RatchetKey> receiverKeys = [];
  //     List<RatchetKey> userKeys = [];
  //
  //     ///TODO once everyone's keys have been sorted, meaning all past v98, then revert this change with the TODO below
  //     userKeys.addAll(await TableRatchetKeyUser.findRatchetKeysForAllUsers());
  //
  //     debugPrint(lastKeychainBackup.millisecondsSinceEpoch.toString());
  //
  //     for (UserFurnace userFurnace in userFurnaces) {
  //       /*List<UserCircleCache> userCircleCaches =
  //           await TableUserCircleCache.readAllForBackup(
  //               userFurnace.pk, userFurnace.userid!);*/
  //
  //       ///TODO once everyone's keys have been sorted, meaning all past v98, then revert this change with the TODO above
  //       //userKeys
  //       //.add(await RatchetKey.getLatestUserKeyPair(userFurnace.userid!));
  //
  //       if (userKeys.isEmpty) throw ("could not find userkey");
  //
  //       List<RatchetKey> keys = await TableRatchetKeyReceiver.fetchKeysForUser(
  //           userFurnace.userid!, lastKeychainBackup);
  //
  //       receiverKeys.addAll(keys);
  //
  //       //if (receiverKeys.isNotEmpty) foundSomeKeys = true;
  //     }
  //
  //     if (receiverKeys.isEmpty) {
  //       throw ('backup is up to date');
  //     }
  //
  //     //debugPrint('All ReceiverKeys: ${receiverKeys.length}');
  //
  //     File plainFile = File(p.join(
  //         await FileSystemService.getKeyChainBackupPath(),
  //         '${const Uuid().v4()}.plain'));
  //
  //     ///write the user keys
  //     for (RatchetKey ratchetKey in userKeys) {
  //       if (ratchetKey.public == null) continue;
  //
  //       plainFile.writeAsStringSync(
  //           '${ratchetKey.keyIndex}\t${ratchetKey.private}\t${ratchetKey.public!}\n',
  //           mode: FileMode.append);
  //     }
  //
  //     plainFile.writeAsStringSync(DIVIDER, mode: FileMode.append);
  //
  //     //write the receiver keys
  //     for (RatchetKey ratchetKey in receiverKeys) {
  //       ratchetKey.created ??= DateTime.parse('20200102');
  //
  //       plainFile.writeAsStringSync(
  //           '${ratchetKey.keyIndex}\t${ratchetKey.private}\t${ratchetKey.created!.millisecondsSinceEpoch}\n',
  //           mode: FileMode.append);
  //     }
  //
  //     if (!encrypted) {
  //       return plainFile;
  //     } else {
  //       final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
  //
  //       List<int> plain = plainFile.readAsBytesSync();
  //
  //       var encrypted = await cipher.encrypt(plain,
  //           nonce: cipher.newNonce(),
  //           secretKey: SecretKey(base64Url.decode(passphrase)));
  //
  //       //debugPrint(encrypted.cipherText);
  //
  //       String fileName = p.join(
  //           await FileSystemService.getKeyChainBackupPath(),
  //           '${username}_${const Uuid().v4()}');
  //
  //       File encryptedFile = File('$fileName.enc');
  //
  //       encryptedFile.writeAsBytesSync(encrypted.nonce, mode: FileMode.append);
  //       encryptedFile.writeAsBytesSync(encrypted.mac.bytes,
  //           mode: FileMode.append);
  //       encryptedFile.writeAsBytesSync(encrypted.cipherText,
  //           mode: FileMode.append);
  //
  //       /*********  LEAVE FOR TESTING
  //           var yep = encryptedFile.readAsBytesSync();
  //
  //           //nonce is the first 24
  //
  //           List<int> nonce = yep.sublist(0, 24);
  //           List<int> mac = yep.sublist(24, 56);
  //
  //           //debugPrint(encrypted.nonce);
  //           //debugPrint(nonce);
  //           //debugPrint(encrypted.mac.bytes);
  //           //debugPrint(mac);
  //           //debugPrint(encrypted.cipherText.length);
  //           //debugPrint((yep.length - 1) - 56);
  //
  //           SecretBox secretBox =
  //           SecretBox(yep.sublist(56, yep.length), nonce: nonce, mac: Mac(mac));
  //
  //           final decrypted = await cipher.decrypt(secretBox,
  //           secretKey: SecretKey(base64Url.decode(passphrase)));
  //
  //           File worked = File(fileName + '_decrypted');
  //           worked.writeAsStringSync(utf8.decode(decrypted));
  //
  //        */
  //
  //       FileSystemService.safeDelete(plainFile);
  //
  //       return encryptedFile;
  //     }
  //   } catch (err, trace) {
  //     if (!err.toString().contains('backup is up to date')) {
  //       LogBloc.insertError(err, trace);
  //     }
  //     debugPrint('ExternalKeys.saveToFile: $err');
  //
  //     rethrow;
  //   }
  // }

  static Future<bool> _putKeychains(
      String userID, File encryptedFile, String passcode) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      var yep = encryptedFile.readAsBytesSync();
      List<int> nonce = yep.sublist(0, 24);
      List<int> mac = yep.sublist(24, 56);

      SecretBox secretBox =
          SecretBox(yep.sublist(56, yep.length), nonce: nonce, mac: Mac(mac));

      final decrypt = await cipher.decrypt(secretBox,
          secretKey: SecretKey(
            base64Decode(passcode),
          ));

      File exportToReadLines = File(p.join(
          await FileSystemService.getKeyChainBackupPath(),
          '${const Uuid().v4()}.decryptedImport'));

      exportToReadLines.writeAsStringSync(utf8.decode(decrypt));

      var lines = await exportToReadLines.readAsLines();

      //TODO validate the file is for the logged in user, not critical, they have the file key

      ///EXPLANATION
      //The top of the file has user keys, the bottom has receiver keys
      //They are separated by a divider which equals const DIVIDER_NO_RETURN
      //The first for loop below grabs user keys until the divider
      //The second grabs receiver keys

      int indexOfDivider = 0;

      List<RatchetKey> userKeys = [];

      for (String line in lines) {
        indexOfDivider += 1;

        debugPrint(line);
        if (line == DIVIDER_NO_RETURN) {
          break;
        }

        List<String> splitLine = line.split('\t');

        //debugPrint('break');

        RatchetKey ratchetKey = RatchetKey(
            keyIndex: splitLine[0],
            private: splitLine[1],
            public: splitLine[2],
            //created:
            //DateTime.fromMillisecondsSinceEpoch(int.parse(splitLine[3]))
            // .toLocal(),
            user: '');

        if (ratchetKey.public == null) {
          debugPrint('TRIED TO IMPORT A BLANK USER KEY');
          continue;
        }

        if (ratchetKey.public!.isEmpty || ratchetKey.private.isEmpty) {
          debugPrint('TRIED TO IMPORT A BLANK USER KEY');
          continue;
        }

        userKeys.add(ratchetKey);
      }

      ///don't wait
      await RatchetKey.importUserKeys(userKeys);

      List<RatchetKey> receiverKeys = [];

      await TableRatchetKeyHelper.init();
      var batch = TableRatchetKeyHelper.database!.batch();

      for (int i = indexOfDivider; i < lines.length; i++) {
        String line = lines[i];

        debugPrint('${i.toString()} out of ${lines.length}');
        //debugPrint(line);

        List<String> splitLine = line.split('\t');

        //debugPrint('break');
        RatchetKey ratchetKey = RatchetKey(
            keyIndex: splitLine[0],
            private: splitLine[1],
            created:
                DateTime.fromMillisecondsSinceEpoch(int.parse(splitLine[2]))
                    .toLocal(),
            user: userID);

        batch.insert(
          TableRatchetKeyReceiver.tableName,
          ratchetKey.toJsonSQL(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(
        noResult: true,
        continueOnError: true,
      );

      //await RatchetKey.importReceiverKeys(receiverKeys);

      /*
      var jsonFileContent = json.decode(contents);

      late KeyExport keyExport;

      try {
        keyExport = KeyExport.fromJson(jsonFileContent);
      } catch (err, trace) { LogBloc.insertError(err, trace);
        keyExport = KeyExport(keys: []);

        OldKeys oldKeys = OldKeys.fromJson(jsonFileContent);

        keyExport.keys.add(UserKeys(
            userKeys: [oldKeys.userKey],
            senderKeys: oldKeys.senderKeys,
            receiverKeys: oldKeys.receiverKeys));
      }

      bool userMatch = false;

      for (UserKeys userKeys in keyExport.keys) {
        //chaos engineering
        //if (userKeys.userKeys.length == 0) throw "invalid backup";
        //if (userKeys.receiverKeys.length == 0) throw "invalid backup";

        if (userKeys.userKeys[0].user == userID) {
          userMatch = true;
          //import the keys
          await RatchetKey.importKeys(userKeys);
        }
      }



      return userMatch;

       */

      return false;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeyFile.putKeychains: $err');

      throw ('invalid key and file combo');
    }
  }

  static Future putFile(String userID, File file, String passcode) async {
    try {
      //make sure the file isn't crazy large
      //int size = file.lengthSync();

      //if (size > 50000) throw ('file is larger than expected');

      //KeyFile keyFile =
      //   KeyFile.fromJson(json.decode(await file.readAsString()));

      await _putKeychains(userID, file, passcode);

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ExternalKeys.putFile: $err');

      throw ('invalid key and file combo');
    }
  }
}
