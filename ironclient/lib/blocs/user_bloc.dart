import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/officialnotification.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/table_member.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_memberdevice.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/ratchetpublickey_service.dart';
import 'package:ironcirclesapp/services/user_service.dart';
import 'package:rxdart/rxdart.dart';

class UserBloc {
  final _userService = UserService();

  final _avatarService = AvatarService();

  final _created = PublishSubject<bool>();
  Stream<bool> get createdResponse => _created.stream;

  final _membershipList = PublishSubject<List<User>>();
  Stream<List<User>> get membershipList => _membershipList.stream;

  final _usernameUpdated = PublishSubject<bool>();
  Stream<bool> get usernameUpdated => _usernameUpdated.stream;

  final _blockStatusUpdated = PublishSubject<bool>();
  Stream<bool> get blockStatusUpdated => _blockStatusUpdated.stream;

  final _usernameReserved = PublishSubject<bool>();
  Stream<bool> get usernameReserved => _usernameReserved.stream;

  final _avatarChanged = PublishSubject<bool>();
  Stream<bool> get avatarChanged => _avatarChanged.stream;

  final _passwordHelper = PublishSubject<UserHelper?>();
  Stream<UserHelper?> get passwordHelper => _passwordHelper.stream;

  final _remoteWipeHelper = PublishSubject<UserHelper?>();
  Stream<UserHelper?> get remoteWipeHelper => _remoteWipeHelper.stream;

  final _keysExported = PublishSubject<bool?>();
  Stream<bool?> get keysExported => _keysExported.stream;

  final _recoveryKey = PublishSubject<RatchetIndex>();
  Stream<RatchetIndex> get recoveryKey => _recoveryKey.stream;

  final _connectionAdded = PublishSubject<Member>();
  Stream<Member> get connectionAdded => _connectionAdded.stream;

  /*
  final _updatedResponse = PublishSubject<bool>();
  Observable<bool> get updatedResponse => _usernameUpdated.stream;

   */

  final _avatarLoaded = PublishSubject<bool>();
  Stream<bool> get avatarLoaded => _avatarLoaded.stream;

  /*Future<bool> isUserNameReserved(String username) async {
    try {
      return _userService.isUserNameReserved(username);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

   */

  setPin(pin, user, UserFurnace userFurnace) {
    try {
      if (pin != null) {
        _userService.setPin(pin, user);

        //_userService.restClearPatternFlag(userFurnace);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.setPin $err');
    }
  }

  unsetPin() {
    _userService.unsetPin();
  }

  downloadAvatar(GlobalEventBloc globalEventBloc, UserFurnace userFurnace,
      User user) async {
    try {
      if (user.avatar != null) {
        if (!globalEventBloc.genericObjectExists(user.avatar!.name)) {
          globalEventBloc.addGenericObject(user.avatar!.name);

          await _avatarService.downloadAvatar(userFurnace, user);

          _avatarLoaded.sink.add(true);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.downloadAvatar $err');
    }
  }

  dismissOfficialNotification(
      UserFurnace userFurnace, OfficialNotification notification) async {
    try {
      await _userService.dismissOfficialNotification(userFurnace, notification);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("UserBloc.dismissOfficialNotification");
    }
  }

  acceptTOS(UserFurnace userFurnace) async {
    try {
      await _userService.acceptTOS(userFurnace);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.acceptTOS $err');
    }
  }

  updateUsername(String username, UserFurnace userFurnace) async {
    try {
      await _userService.update(username, userFurnace);

      _usernameUpdated.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updateUser $err');
      _usernameUpdated.sink.addError(err);
    }
  }

  reserveUsername(UserFurnace userFurnace, bool reserved) async {
    try {
      await _userService.reserveUsername(userFurnace, reserved);

      _usernameReserved.sink.add(reserved);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updateUser $err');
      _usernameReserved.sink.addError(err);
    }
  }

  updateAvatar(UserFurnace userFurnace, File avatar) async {
    try {
      if (avatar != null) {
        AvatarService avatarService = AvatarService();
        await avatarService.updateAvatar(userFurnace, avatar, delete: true);

        _avatarChanged.sink.add(true);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updateAvatar $err');
      _avatarChanged.sink.addError(err);
    }
  }

  Future<UserHelper?> fetchRemoteWipeHelpers(
      UserFurnace userFurnace, String userID) async {
    try {
      UserHelper? helper =
          await _userService.fetchRemoteWipeHelpers(userFurnace, userID);

      _remoteWipeHelper.sink.add(helper);

      return helper;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.fetchRemoteWipeHelpers $err');
      _remoteWipeHelper.sink.addError(err);
      return null;
    }
  }

  updateRemoteWipeHelpers(
      UserFurnace userFurnace, UserHelper userHelper) async {
    try {
      if (userHelper.helpers!.isNotEmpty) {
        await _userService.updateRemoteWipeHelpers(userFurnace, userHelper);

        _remoteWipeHelper.sink.add(userHelper);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updatePasswordHelpers $err');
      _remoteWipeHelper.sink.addError(err);
    }
  }

  Future<UserHelper?> fetchPasswordHelpers(
      UserFurnace userFurnace, String userID) async {
    try {
      UserHelper? passwordHelper =
          await _userService.fetchPasswordHelpers(userFurnace, userID);

      _passwordHelper.sink.add(passwordHelper);

      return passwordHelper;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.fetchPasswordHelpers $err');
      _passwordHelper.sink.addError(err);
      return null;
    }
  }

  updatePasswordHelpers(
      UserFurnace userFurnace, UserHelper passwordHelper) async {
    try {
      if (passwordHelper.helpers!.isNotEmpty) {
        List<RatchetKey> userPublicKeys =
            await RatchetPublicKeyService.fetchMemberUserPublicKeys(
                userFurnace, passwordHelper.helpers!);

        List<RatchetIndex> ratchetIndexes = [];

        late String backupKey;

        if (userFurnace.authServer!) {
          backupKey = globalState.userSetting.backupKey;
        } else {
          UserSetting? userSetting =
              await TableUserSetting.read(userFurnace.userid!);
          backupKey = userSetting!.backupKey;
        }
        //String backupKey = await SecureStorageService.readKey(
        //     KeyType.USER_KEYCHAIN_BACKUP + userFurnace.userid!);

        List<String> keyFrags = [];

        if (userPublicKeys.length == 4) {
          keyFrags.add(backupKey.substring(0, 11));
          keyFrags.add(backupKey.substring(11, 22));
          keyFrags.add(backupKey.substring(22, 33));
          keyFrags.add(backupKey.substring(33));
        } else if (userPublicKeys.length == 3) {
          keyFrags.add(backupKey.substring(0, 14));
          keyFrags.add(backupKey.substring(14, 28));
          keyFrags.add(backupKey.substring(28));
        } else if (userPublicKeys.length == 2) {
          keyFrags.add(backupKey.substring(0, 22));
          keyFrags.add(backupKey.substring(22));
        } else if (userPublicKeys.length == 1) {
          keyFrags.add(backupKey);
        }

        int keyFragIndex = 0;

        for (RatchetKey ratchetKey in userPublicKeys) {
          Map<String, dynamic> map = {
            "backupkey": keyFrags[keyFragIndex],
          };

          RatchetIndex ratchetIndex =
              await ForwardSecrecyUser.encryptObjectForUser(
                  userFurnace, userFurnace.userid!, ratchetKey, map);

          ratchetIndexes.add(ratchetIndex);

          keyFragIndex = keyFragIndex + 1;
        }

        await _userService.updatePasswordHelpers(
            userFurnace, passwordHelper, ratchetIndexes);
      }
      _passwordHelper.sink.add(passwordHelper);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updatePasswordHelpers $err');
      _passwordHelper.sink.addError(err);
    }
  }

  updateRecoveryRatchetIndex(
      UserFurnace userFurnace, RatchetIndex ratchetIndex) async {
    try {
      await _userService.updateRecoveryRatchetIndex(userFurnace, ratchetIndex);

      _recoveryKey.sink.add(ratchetIndex);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updatePasswordHelpers $err');
      _passwordHelper.sink.addError(err);
    }
  }

  void updateKeysExported(UserFurnace? userFurnace) async {
    try {
      await _userService.keysExported(userFurnace!);

      _keysExported.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updateKeysExported $err');
      _keysExported.sink.addError(err);
    }
  }

  Future<bool> enablePasswordBeforeChange(
      UserFurnace userFurnace, bool enabled) async {
    bool success = false;

    try {
      success =
          await _userService.enablePasswordBeforeChange(userFurnace, enabled);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updatePasswordHelpers $err');
    }

    return success;
  }

  Future<List<User>> deleteAccount(
      UserFurnace userFurnace, String? transferUserID) async {
    List<User> otherMembers = [];
    try {
      bool deleteAccount = false;
      otherMembers = await _userService.prepDelete(userFurnace);

      if (otherMembers.isEmpty || transferUserID != null) {
        ///ok to delete
        deleteAccount = true;
      }
      if (deleteAccount) {
        if (userFurnace.token != null) {
          await _userService.deleteAccount(userFurnace, transferUserID);
        }

        if (userFurnace.authServer!)
          await DeviceBloc.wipeDeviceCallback('account deleted');
        else {
          await TableUserFurnace.delete(userFurnace.pk!);
          TableMember.deleteAllForUser(userFurnace.userid!);
          TableMemberCircle.deleteAllForUser(userFurnace.userid!);
          TableMemberDevice.deleteAllForUser(userFurnace.userid!);
          TableUserCircleCache.deleteAllForUser(userFurnace.userid!);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.deleteAccount $err');
    }

    return otherMembers;
  }

  updateBlockStatus(BuildContext context,
      UserFurnace userFurnace, User memberUser, bool status) async {
    try {
      bool success =
          await _userService.updateBlockStatus(userFurnace, memberUser, status);
      if (success == true) {
        _blockStatusUpdated.sink.add(status);
      }

      if (status == true) {
        ///remove from friends
        Member member = globalState.members
            .firstWhere((element) => element.memberID == memberUser.id);

        await setConnected(context, userFurnace, member, false, override: true);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserBloc.updateConnectionStatus $err');
    }
  }

  setConnected(BuildContext context, UserFurnace userFurnace, Member member, bool connected,
      {bool override = false}) async {
    try {
      if (connected == false && override == false) {
        ///don't allow a disconnect if there is a DM already (for now)
        MemberCircle? memberCircle =
            await TableMemberCircle.getDM(userFurnace.userid!, member.memberID);

        if (memberCircle != null) {
          //throw ('Cannot disconnect a member that has a DM. You must leave the DM first');
          throw (AppLocalizations.of(context)!.cannotDisconnectMember);
        }
      }

      member.connected = connected;
      await TableMember.upsert(userFurnace.userid!, member);
      await _userService.setConnected(userFurnace, member, connected);

      ///update globalState
      int index =
          globalState.members.indexWhere((m) => m.memberID == member.memberID);

      if (index == -1) {
        globalState.members.add(member);
      } else {
        globalState.members[index].connected = connected;
      }

      _connectionAdded.sink.add(member);
    } catch (err, trace) {
      _connectionAdded.sink.addError(err);
      LogBloc.insertError(err, trace);
    }
  }

  dispose() async {
    //_movieId.close();
    await _created.drain();
    _created.close();

    await _membershipList.drain();
    _membershipList.close();

    await _usernameUpdated.drain();
    _usernameUpdated.close();

    await _avatarChanged.drain();
    _avatarChanged.close();

    await _avatarLoaded.drain();
    _avatarLoaded.close();

    await _passwordHelper.drain();
    _passwordHelper.close();

    await _remoteWipeHelper.drain();
    _remoteWipeHelper.close();

    await _keysExported.drain();
    _keysExported.close();

    await _usernameReserved.drain();
    _usernameReserved.close();

    await _recoveryKey.drain();
    _recoveryKey.close();

    await _blockStatusUpdated.drain();
    _blockStatusUpdated.close();

    await _connectionAdded.drain();
    _connectionAdded.close();
  }
}
