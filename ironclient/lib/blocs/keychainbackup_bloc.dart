import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/keychainbackup_service.dart';
import 'package:rxdart/rxdart.dart';

class KeychainBackupBloc {
  final _toggleSuccess = PublishSubject<bool>();
  Stream<bool> get toggleSuccess => _toggleSuccess.stream;

  final _restoreSuccess = PublishSubject<bool>();
  Stream<bool> get restoreSuccess => _restoreSuccess.stream;

  toggle(UserFurnace userFurnace, bool autoKeychainBackup) async {
    try {
      await KeychainBackupService.toggle(userFurnace, autoKeychainBackup);

      _toggleSuccess.sink.add(autoKeychainBackup);

      if (autoKeychainBackup) backupDevice(userFurnace, true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeychainBackupBloc.toggle: $err');
      _toggleSuccess.sink.addError(err);
    }
  }

  ///backups keys for all connected furnaces
  static backupNonAuth(bool forceFull) async {
    try {
      List<UserFurnace> userFurnaces =
          await TableUserFurnace.readAllForUser(globalState.user.id!);

      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.linkedUser == null &&
            userFurnace.authServerUserid != userFurnace.userid &&
            userFurnace.connected!) {
          backupDevice(userFurnace, forceFull);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeychainBackupBloc.backup: $err');
      rethrow;
    }
  }

  ///backups keys for all connected furnaces, including the IronForge
  static Future<String> backupDevice(
      UserFurnace userFurnace, bool forceFull) async {
    try {
      //ForwardSecrecyUser.fixUserKeyMismatches();
      return await KeychainBackupService.backupDevice(userFurnace, forceFull);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeychainBackupBloc.backup: $err');
      rethrow;
    }
  }

  //backups keys for all connected furnaces, including the IronForge
  // static Future<String> backup({bool force = false}) async {
  //   try {
  //     //ForwardSecrecyUser.fixUserKeyMismatches();
  //     return await KeychainBackupService.backup(force: force);
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint('KeychainBackupBloc.backup: $err');
  //     rethrow;
  //   }
  // }

  // static Future<String> exportFurnace(UserFurnace userFurnace) async {
  //   try {
  //     String retValue = "";
  //
  //     //List<UserFurnace> userFurnaces =
  //     //  await TableUserFurnace.readConnectedForUser(globalState.user.id);
  //
  //     //for (UserFurnace userFurnace in userFurnaces)
  //     retValue = await KeychainBackupService.backup();
  //
  //     return retValue;
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint('KeychainBackupBloc.backup: $err');
  //     rethrow;
  //   }
  // }

  prepRestore(
      AuthenticationBloc authBloc, UserFurnace userFurnace, User user, bool pullExtra) async {
    //String backupKey = await SecureStorageService.readKey(
    //    KeyType.USER_KEYCHAIN_BACKUP + globalState.user.id!);

    late String backupKey;

    if (userFurnace.authServer!) {
      if (globalState.userSetting.backupKey.isNotEmpty) {
        backupKey = globalState.userSetting.backupKey;
      } else {
        ///The backup key wasn't decrypted in the authentication service
        throw ('an error has occurred');
      }
    } else {
      UserSetting? userSetting = await TableUserSetting.read(user.id!);
      backupKey = userSetting!.backupKey;
    }

    restore(userFurnace, user, backupKey, pullExtra);
  }

  restore(UserFurnace userFurnace, User user, String passcode, bool pullExtra) async {
    try {
      _restoreSuccess.sink.add(true);

      await KeychainBackupService.restore(userFurnace, user.id!, passcode, pullExtra);
      //await KeychainBackupService.restore(
      //  globalState.userFurnace!, user.id!, passcode);

      ///ratchet all the receiver keys to make sure this device has matching keys for messages

      try {
        await ForwardSecrecy.ratchetReceiverKeys(
            user, userFurnace, user.userCircles);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('KeychainBackupBloc.restore: $err');
      }

      _restoreSuccess.sink.add(false);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('KeychainBackupBloc.restore: $err');
      _restoreSuccess.sink.addError(err);
    }
  }

  dispose() async {
    await _toggleSuccess.drain();
    _toggleSuccess.close();

    await _restoreSuccess.drain();
    _restoreSuccess.close();
  }
}
