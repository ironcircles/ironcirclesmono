import 'dart:async';
import 'dart:convert';

import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/subscriptions_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/encryption/kyber/kyber.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ironcoinwallet.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/services/authentication_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_updatetracker.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/keychainbackup_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:rxdart/rxdart.dart';

class AuthenticationBloc {
  final _authService = AuthenticationService();
  //final _avatarService = AvatarService();
  final _authCredentials = PublishSubject<User>();
  final _passwordChanged = PublishSubject<User>();
  final _authToken = PublishSubject<User>();
  final _registration = PublishSubject<User>();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  Stream<User> get passwordChanged => _passwordChanged.stream;
  Stream<User> get authCredentials => _authCredentials.stream;
  Stream<User> get authToken => _authToken.stream;
  Stream<User> get registerResponse => _registration.stream;

  final _resetDone = PublishSubject<String?>();
  Stream<String?> get resetDone => _resetDone.stream;

  final _resetCodeAvailable = PublishSubject<bool?>();
  Stream<bool?> get resetCodeAvailable => _resetCodeAvailable.stream;

  final _resetCodeComplete = PublishSubject<bool>();
  Stream<bool?> get resetCodeComplete => _resetCodeAvailable.stream;

  final _keyNotFound = PublishSubject<User>();
  Stream<User?> get keyNotFound => _keyNotFound.stream;

  final _keyGenerated = PublishSubject<bool>();
  Stream<bool> get keyGenerated => _keyGenerated.stream;

  logout(FirebaseBloc firebaseBloc, String userID) async {
    firebaseBloc.removeNotification();

    //await UserCircleBloc.closeHiddenCircles(firebaseBloc);
    TableUserCircleCache.closeHiddenCircles();

    globalState.hiddenOpen = false;
    globalState.lastSelectedFilter = null;
    globalState.lastSelectedIndexCircles = null;
    globalState.lastSelectedIndexDMs = null;
    globalState.loggingOut = true;
    globalState.members = [];

    if (globalState.userFurnace != null)
      globalState.userFurnace!.connected = false;

    List<UserFurnace> userFurnaces =
        await TableUserFurnace.readAllForUser(userID);

    for (UserFurnace userFurnace in userFurnaces) {
      try {
        ///Serverside needs userFurnace token and is run async, create a deep copy so the token blanking below doesn't fire first
        if (userFurnace.connected!) {
          UserFurnace deepCopy = UserFurnace.deepCopy(userFurnace);
          _authService.logout(deepCopy);
        }

        userFurnace.token = "";
        userFurnace.connected = false;
        await TableUserFurnace.upsert(userFurnace);
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        //debugPrint('AuthenticationBloc.logout: $err');
      }
    }

    await TableUserFurnace.clearAuthAndConnectedServers();
  }

  authenticateNonLinkedTokens(String userID, Device device) async {
    List<UserFurnace> userFurnaces =
        await TableUserFurnace.readAllForUser(userID);

    for (UserFurnace userFurnace in userFurnaces) {
      if (userFurnace.authServer! != true &&
          userFurnace.connected! &&
          userFurnace.linkedUser != userID) {
        try {
          _authenticateAndBackup(userFurnace, device);
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
        }
      }
    }
  }

  _authenticateAndBackup(UserFurnace userFurnace, Device device) async {
    try {
      await _authService.validateToken(userFurnace, device);
      await KeychainBackupService.backupDevice(userFurnace, false);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  _debugCircle(String userCircle, String circle) async {
    try {
      UserCircleCache? userCircleCache =
          await TableUserCircleCache.read(userCircle);
      LogBloc.postLog(
          'userCircle: $userCircle', json.encode(userCircleCache.toJson()));

      List<Map> circleObjects =
          await TableCircleObjectCache.readAmount(circle, 30);
      LogBloc.postLog('circleObjects', json.encode(circleObjects));
    } catch (error, trace) {
      LogBloc.postLog(error.toString(), trace.toString());
    }
  }

  _setBlobState(String userID, String seed) async {
    try {
      CircleObjectCache circleObjectCache =
          await TableCircleObjectCache.readBySeed(seed);

      Map<String, dynamic>? decode =
          json.decode(circleObjectCache.circleObjectJson!);

      CircleObject circleObject = CircleObject.fromJson(decode!);

      if (circleObject.video != null) {
        circleObject.fullTransferState = BlobState.NOT_DOWNLOADED;
        circleObject.thumbnailTransferState = BlobState.NOT_DOWNLOADED;
        circleObject.video!.videoState = VideoStateIC.UNKNOWN;
      } else {
        circleObject.fullTransferState = BlobState.NOT_DOWNLOADED;
        circleObject.thumbnailTransferState = BlobState.NOT_DOWNLOADED;
      }

      await TableCircleObjectCache.updateCacheSingleObject(
          userID, circleObject);
    } catch (error, trace) {
      LogBloc.postLog(error.toString(), trace.toString());
    }
  }

  _cleanup(String userID) async {
    try {
      UpdateTracker updateTracker =
          await TableUpdateTracker.read(UpdateTrackerType.objectDelete);

      if (updateTracker.pk != null) {
        return;
      }

      if (userID == '656e215f4e0a656c9abad2f9') {
        await _debugCircle(
            '656e21604e0a656c9abad309', '656e21604e0a656c9abad307');
        await _debugCircle(
            '656e215f4e0a656c9abad305', '656e215f4e0a656c9abad2ff');

        ///this will remove the last blob posted and any other associated files
        /*
        String circlePath = await FileSystemService.returnCirclesDirectory(
            userID, '656e21604e0a656c9abad307');
        await FileSystemService.deleteCircleCacheDirectly(circlePath);


        ///delete the last 3 images posted
        circlePath = await FileSystemService.returnCirclesDirectory(
            userID, '656e215f4e0a656c9abad2ff');

        await _setBlobState(userID, 'b13c536a-743a-45ad-bee4-336a9e7df304');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, 'b13c536a-743a-45ad-bee4-336a9e7df304');
        await _setBlobState(userID, 'a5385a0e-8ddf-4b1a-ae80-febf18e8c397');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, 'a5385a0e-8ddf-4b1a-ae80-febf18e8c397');
        await _setBlobState(userID, '8ad3e86b-3865-4f29-83c3-b9a20aa6acb4');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, '8ad3e86b-3865-4f29-83c3-b9a20aa6acb4');

        ///delete the last 3 videos posted
        await _setBlobState(userID, '733bdc16-ed37-4158-9233-c2324abc5aa9');
        await VideoCacheService.deleteCacheBySeed(
            circlePath, '733bdc16-ed37-4158-9233-c2324abc5aa9', 'mp4');
        await _setBlobState(userID, 'ef291dab-0d81-4056-b45d-052305ca621f');
        await VideoCacheService.deleteCacheBySeed(
            circlePath, 'ef291dab-0d81-4056-b45d-052305ca621f', 'mp4');
        await _setBlobState(userID, '39b4621d-13a2-47a7-9d32-aa1cc95640a8');
        await VideoCacheService.deleteCacheBySeed(
            circlePath, '39b4621d-13a2-47a7-9d32-aa1cc95640a8', 'mp4');

         */
      }

      if (userID == '64ae55d490c688be1579dd9e') {
        _debugCircle('64b7ecc44d877d1417e49d9c', '64b7ecc44d877d1417e49d8a');
        _debugCircle('651490cf64d467318c65b20a', '651490ce64d467318c65b1f6');

        /*
        ///this will remove the last blob posted and any other associated files
        String circlePath = await FileSystemService.returnCirclesDirectory(
            userID, '651490ce64d467318c65b1f6');
        await FileSystemService.deleteCircleCacheDirectly(circlePath);
        await _setBlobState(userID, 'fe5e6ec0-a9db-4029-b35a-dda4b36c91ca');

        ///delete the last 3 images posted
        circlePath = await FileSystemService.returnCirclesDirectory(
            userID, '64b7ecc44d877d1417e49d8a');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, '7a60dcb0-9089-4baf-9991-f8fa3dc601d8');
        await _setBlobState(userID, '7a60dcb0-9089-4baf-9991-f8fa3dc601d8');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, '4c6949c5-6d47-47ca-948a-ce4667d9f637');
        await _setBlobState(userID, '4c6949c5-6d47-47ca-948a-ce4667d9f637');
        await ImageCacheService.deleteCircleObjectImage(
            circlePath, '91582426-cf62-4fb7-a40f-b979a5445e24');
        await _setBlobState(userID, '91582426-cf62-4fb7-a40f-b979a5445e24');

        ///delete the last 3 videos posted
        await VideoCacheService.deleteCacheBySeed(
            circlePath, 'c665126c-ae9d-47f3-84da-d25af63e17ac', 'mp4');
        await _setBlobState(userID, 'c665126c-ae9d-47f3-84da-d25af63e17ac');
        await VideoCacheService.deleteCacheBySeed(
            circlePath, '77d90efa-f562-438d-adfc-ace77e424cff', 'mp4');
        await _setBlobState(userID, '77d90efa-f562-438d-adfc-ace77e424cff');
        await VideoCacheService.deleteCacheBySeed(
            circlePath, 'fd39e128-4985-43f3-91ef-cfc53463fdbf', 'mov');
        await _setBlobState(userID, 'fd39e128-4985-43f3-91ef-cfc53463fdbf');

         */
      }

      await TableUpdateTracker.upsert(UpdateTrackerType.objectDelete, true);

      LogBloc.postLog(
          'cleanup done for user $userID', 'AuthenticationBloc._cleanup');

      //int size = await FileSystemService.databaseSize();
      //LogBloc.postLog('database size', size.toString());
    } catch (error, trace) {
      LogBloc.postLog(error.toString(), trace.toString());
    }
  }

  authenticateUser() async {
    try {
      UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();

      ///did the auth server change?,
      ///TODO this won't support Docker instances
      if (userFurnace != null) {
        if (urls.forge != userFurnace.url) {
          ///TODO this can go away after everyone is on 1.0.10
          if (userFurnace.url == Urls.OLDPROD) {
            userFurnace.url = urls.forge;
            TableUserFurnace.setToNewProd(userFurnace.url!);
          } else {
            await TableUserFurnace.delete(userFurnace.pk);

            throw ("New furnace");
          }
        }
      }

      if (userFurnace == null) {
        throw Exception('No token');
      }

      if (userFurnace.token == null) {
        throw Exception('No token');
      }

      if (userFurnace.token!.isEmpty) {
        throw Exception('No token');
      }

      ///In the foreground, we know there is a token and an existing cache, just let the user in, they will get booted on the home screen if their token is invalid
      User user = User(
        id: userFurnace.userid,
        username: userFurnace.username,
        minor: globalState.userSetting.minor,
        avatar: userFurnace.avatar,
        allowClosed: globalState.userSetting.allowHidden,
        accountType: globalState.userSetting.accountType,
      );

      globalState.user = user;
      globalState.userFurnace = userFurnace;

      // ///will move user onto home screen while below processes in the background
      // _authToken.sink.add(user);
    } catch (error, trace) {
      if (!error.toString().contains('No token') &&
          !error.toString().contains('New furnace'))
        LogBloc.insertError(error, trace);
      _authToken.sink.addError(error);
    }
  }

  authenticateToken(GlobalEventBloc globalEventBloc, {oldUID = ''} ) async {
    try {
      UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();

      ///did the auth server change?,
      ///self hosted servers never match, exclude them
      if (userFurnace != null &&
          (userFurnace.type != NetworkType.SELF_HOSTED)) {
        if (urls.forge != userFurnace.url) {
          await TableUserFurnace.delete(userFurnace.pk);

          throw ("New furnace");
        }
      }

      if (userFurnace == null) {
        throw Exception('No token');
      }

      if (userFurnace.token == null) {
        throw Exception('No token');
      }

      if (userFurnace.token!.isEmpty) {
        throw Exception('No token');
      }

      Device deviceAttributes = await UserSetting.getDeviceInfo(userFurnace: userFurnace);

      ///In the foreground, we know there is a token and an existing cache, just let the user in, they will get booted on the home screen if their token is invalid
      User user = User(
        id: userFurnace.userid,
        username: userFurnace.username,
        minor: globalState.userSetting.minor,
        avatar: userFurnace.avatar,
        allowClosed: globalState.userSetting.allowHidden,
        accountType: globalState.userSetting.accountType,
      );

      globalState.ironCoinWallet = IronCoinWallet(
        balance: globalState.userSetting.ironCoin == null
            ? 0
            : globalState.userSetting.ironCoin!,
      );

      globalState.user = user;
      globalState.userFurnace = userFurnace;

      SubscriptionsBloc.listenToPurchaseUpdated(globalState.subscriptionQueue);

      ///will move user onto home screen while below processes in the background
      _authToken.sink.add(user);

      ///validate the token in the background, also check tos and whether pin is needed (v35)
      User check =
          await _authService.validateToken(userFurnace, deviceAttributes);

      ///UserCircles are only returned from the api if a public key expired
      if (check.userCircles.isNotEmpty) {
        generateCircleKeys(check, userFurnace, check.userCircles);
      }

      authenticateNonLinkedTokens(userFurnace.userid!, deviceAttributes);

      if (globalState.mustUpdate) {
        globalEventBloc.broadcastMustUpdate();
      }

      if (check.tos == null) {
        globalEventBloc.broadcastTOSReviewNeeded();
      }

      String backupKey = globalState.userSetting.backupKey;

      if (backupKey.isEmpty) {
        LogBloc.postLog(
            'Backup key is empty ${userFurnace.userid!}', 'authenticateToken');

        backupKey = await globalState.secureStorageService.readKey(
            KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED + userFurnace.userid!);

        if (backupKey.isNotEmpty) {
          globalState.userSetting.setBackupKey(backupKey);
        } else {
          LogBloc.postLog('Backup key missing for ${userFurnace.userid!}',
              'authenticateToken');
        }
      }

      if (backupKey.isNotEmpty &&
          check.autoKeychainBackup != null &&
          check.autoKeychainBackup!) {
        KeychainBackupService.backupDevice(userFurnace, false);
      } else {
        String backupKeyMissing = backupKey.isEmpty ? 'empty' : 'not empty';
        String autoKeychainBackup = check.autoKeychainBackup == null
            ? 'null'
            : check.autoKeychainBackup!
                ? 'true'
                : 'false';

        LogBloc.postLog(
            'Backup key is $backupKeyMissing for ${userFurnace.userid!} and check.autoKeychainBackup is $autoKeychainBackup',
            'authenticateToken');
      }
    } catch (error, trace) {
      if (!error.toString().contains('No token') &&
          !error.toString().contains('New furnace'))
        LogBloc.insertError(error, trace);
      _authToken.sink.addError(error);
    }
  }

  validatePassword(UserFurnace userFurnace, String password, String pin) async {
    try {
      late User? valid;

      Device deviceAttributes = await UserSetting.getDeviceInfo(userFurnace: userFurnace);

      String passwordNonce = await _authService.getNonce(userFurnace);

      String passwordHash = (await ForwardSecrecyUser.saltAndHashPassword(
              password, pin,
              passwordNonce: passwordNonce))
          .secretKeyString;

      if (userFurnace.authServer!)
        valid = await _authService.validateCredentialsOnly(userFurnace.username,
            passwordHash, password, pin, userFurnace, deviceAttributes);
      else {
        valid = await _authService.validateCredentials(userFurnace,
            deviceAttributes, passwordHash, passwordNonce, password, pin);
      }

      if (valid != null) {
        _authCredentials.sink.add(valid);
      }

      return valid;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint(error);
      _authCredentials.sink.addError(error);
    }
  }

  authenticateCredentials(String? username, String password, String pin) async {
    try {
      UserFurnace? userFurnace = await TableUserFurnace.readUserAuth(username);

      //did the auth server change?
      if (userFurnace != null) {
        if (userFurnace.hostedName != null || urls.forge != userFurnace.url) {
          await TableUserFurnace.delete(userFurnace.pk);
          userFurnace = null;
        }
      }

      Device device = await UserSetting.getDeviceInfo(userFurnace: userFurnace!);

      String passwordNonce = await _authService.getNonce(userFurnace);

      String passwordHash = (await ForwardSecrecyUser.saltAndHashPassword(
              password, pin,
              passwordNonce: passwordNonce))
          .secretKeyString;

      //await SecureStorageService.writeKey(KeyType.APPPATH, value);
      User? user = await _authService.validateCredentialsOnly(
          username, passwordHash, password, pin, userFurnace, device);

      if (user != null) {
        FileSystemService.makeCirclePath(user.id!, DeviceOnlyCircle.circleID);
        _authCredentials.sink.add(user);
      }

      return user;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      //debugPrint(error);
      _authCredentials.sink.addError(error);
    }
  }

  changePassword(String? username, String existing, String existingPin,
      String password, String pin, UserFurnace userFurnace,
      {String newUsername = ''}) async {
    try {
      late String backupSecret;
      UserSetting? userSetting;
      RatchetIndex? userIndex;

      if (userFurnace.authServer!) {
        backupSecret = globalState.userSetting.backupKey;
        userSetting = globalState.userSetting;
      } else {
        userSetting = await TableUserSetting.read(userFurnace.userid!);

        backupSecret = userSetting!.backupKey;
      }

      if (backupSecret.isEmpty) {
        backupSecret = await globalState.secureStorageService.readKey(
            KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED + userFurnace.userid!);

        if (backupSecret.isNotEmpty) {
          await userSetting.setBackupKey(backupSecret);
        } else {
          ///generate a key for Homer
          backupSecret = await ForwardSecrecyUser.generateBackupSecret();
          await userSetting.setBackupKey(backupSecret);

          RatchetKey ratchetKey = await ForwardSecrecy.generateBlankKeyPair();

          userIndex = await ForwardSecrecyUser.encryptUserKey(
              backupSecret, '', ratchetKey);

          LogBloc.postLog('generated new backup for ${userFurnace.userid!}',
              'change password');

          KeychainBackupBloc backupBloc = KeychainBackupBloc();
          await backupBloc.toggle(userFurnace, false);
          backupBloc.toggle(userFurnace, true);
        }
      }

      RatchetIndex backupIndex = await ForwardSecrecyUser.encryptBackupSecret(
          userFurnace.userid!, backupSecret, password, pin);

      UserSecret userSecret =
          await ForwardSecrecyUser.saltAndHashPassword(password, pin);

      User user = await _authService.changePassword(
          username,
          existing,
          existingPin,
          userSecret.secretKeyString,
          userSecret.nonceString,
          userFurnace,
          backupIndex,
          newUsername: newUsername,
          userIndex: userIndex);

      _passwordChanged.sink.add(user);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _passwordChanged.sink.addError(error);
    }
  }

  changeGeneratedValues(
      String username,
      String newUsername,
      String existing,
      String existingPin,
      String password,
      String pin,
      UserFurnace userFurnace) async {
    changePassword(username, existing, existingPin, password, pin, userFurnace,
        newUsername: newUsername);
  }

  resetPasswordFromCode(String? username, String resetCode, String password,
      String pin, UserFurnace? userFurnace) async {
    try {
      userFurnace ??= await TableUserFurnace.readUserAuth(username);

      userFurnace ??= globalState.userFurnace;

      ///First, see if the reset code is accurate and get the RatchetIndexes for the backup key fragment
      List<RatchetIndex> recoveryIndexes = await _authService
          .getResetCodeRatchetIndexes(username, resetCode, userFurnace!);

      String tempKey = await globalState.secureStorageService
          .readKey(KeyType.RESET_CODE_KEY);
      RatchetKey tempRatchetKey = RatchetKey.fromJson(json.decode(tempKey));

      ///loop through the beasties and assemble the backupkey secret
      String backupSecret = '';

      //ratchetIndexes.sort((a, b) => a.index.compareTo(b.index));

      for (RatchetIndex ratchetIndex in recoveryIndexes) {
        var keyFrag = await ForwardSecrecyUser.decryptObjectFromUser(
            tempRatchetKey, ratchetIndex);

        backupSecret = backupSecret + keyFrag['backupkey'];
      }

      if (backupSecret.length != 44) {
        ///revert to authUser
        backupSecret = globalState.userSetting.backupKey;
      }

      if (backupSecret.length != 44) {
        throw ('password reset failed'); //TODO this is bad news
      }

      ///Encrypt the backup key with the userkey and password
      RatchetIndex backupIndex = await ForwardSecrecyUser.encryptBackupSecret(
          '', backupSecret, password, pin);

      UserSecret userSecret =
          await ForwardSecrecyUser.saltAndHashPassword(password, pin);

      User user = await _authService.resetPasswordFromCode(
          username,
          resetCode,
          password,
          pin,
          userSecret.secretKeyString,
          userSecret.nonceString,
          userFurnace,
          backupIndex);

      TableUserSetting.setBackupKey(user.id!, backupSecret);

      ///update action required
      _userFurnaceBloc.refreshUserCircles(globalState.user.id);

      _passwordChanged.sink.add(user);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _passwordChanged.sink.addError(error);
    }
  }

  checkResetCodeAvailable(String username, UserFurnace userFurnace) async {
    try {
      //userFurnace = await TableUserFurnace.readUserAuth(username);

      //if (userFurnace == null) userFurnace = globalState.userFurnace;

      bool? response =
          await _authService.checkResetCodeAvailable(userFurnace, username);

      _resetCodeAvailable.sink.add(response);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _resetDone.sink.addError(error);
    }
  }

  // resetHelp(UserFurnace userFurnace, String resetNeededID) async {
  //   //fetch the fragment of the backup key available to responder
  //   RatchetIndex ratchetIndex = await _authService.getRatchetForPasscodeReset(
  //       userFurnace, resetNeededID);
  //
  //   RatchetKeyAndMap ratchetKeyAndMap =
  //       await ForwardSecrecyUser.decryptUserObject(
  //           ratchetIndex, userFurnace.userid!);
  //
  //   LogBloc.insertLog(json.encode(ratchetKeyAndMap.map), "resetHelp");
  //   LogBloc.insertLog(json.encode(ratchetKeyAndMap.ratchetKey), "resetHelp");
  // }

  sendEncryptedBackupKeyFragForResetCode(
      UserFurnace userFurnace, ActionRequired actionRequired) async {
    try {
      //The action required contains the requestor's temporary public key
      RatchetKey ratchetKey = actionRequired.ratchetPublicKey!;

      //fetch the fragment of the backup key available to responder
      RatchetIndex ratchetIndex = await _authService.getRatchetForPasscodeReset(
          userFurnace, actionRequired.resetUser!.id!);

      RatchetKeyAndMap ratchetKeyAndMap =
          await ForwardSecrecyUser.decryptUserObject(
              ratchetIndex, userFurnace.userid!);

      //encrypt the fragment of the users's backup key that was encrypted when this users was set to be a password helper
      RatchetIndex returnIndex =
          await ForwardSecrecyUser.encryptObjectForUserWithRatchetKey(
              userFurnace,
              userFurnace.userid!,
              ratchetKey,
              ratchetKeyAndMap.ratchetKey,
              ratchetKeyAndMap.map);

      await _authService.postEncryptedFragForPasscodeReset(
          userFurnace, actionRequired.resetUser!.id!, returnIndex);

      //Then show this user the temp reset code (different than the backup key fragment, which is never sent cleartext)
      return;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      // _resetDone.sink.addError(error);

      rethrow;
    }
  }

  generateResetCode(String? username, UserFurnace? userFurnace) async {
    try {
      userFurnace ??= await TableUserFurnace.readUserAuth(username);

      userFurnace ??= globalState.userFurnace;

      ///if there is already a key, reuse it.
      String tempKey = await globalState.secureStorageService
          .readKey(KeyType.RESET_CODE_KEY);
      late RatchetKey ratchetKey;

      if (tempKey.isNotEmpty)
        ratchetKey = RatchetKey.fromJson(json.decode(tempKey));
      else {
        ratchetKey = await ForwardSecrecy.generateBlankKeyPair();

        await globalState.secureStorageService
            .writeKey(KeyType.RESET_CODE_KEY, json.encode(ratchetKey.toJson()));
      }

      String? response = await _authService.generateResetCode(
          username, userFurnace!, ratchetKey);

      _userFurnaceBloc.refreshUserCircles(globalState.user.id);

      _resetDone.sink.add(response);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      _resetDone.sink.addError(error);
    }
  }

  generateCircleKeys(
      User user, UserFurnace userFurnace, List<UserCircle> userCircles) {
    ForwardSecrecy.generateCircleKeys(
        user, userFurnace, userCircles, keyGeneratedCallback);
  }

  keyGeneratedCallback(bool show) {
    _keyGenerated.sink.add(show);
  }

  dispose() async {
    await _authToken.drain();
    _authToken.close();

    await _authCredentials.drain();
    _authCredentials.close();

    await _registration.drain();
    _registration.close();

    await _passwordChanged.drain();
    _passwordChanged.close();

    await _resetDone.drain();
    _resetDone.close();

    await _resetCodeAvailable.drain();
    _resetCodeAvailable.close();

    await _resetCodeComplete.drain();
    _resetCodeComplete.close();

    await _keyNotFound.drain();
    _keyNotFound.close();

    await _keyGenerated.drain();
    _keyGenerated.close();
  }
}
