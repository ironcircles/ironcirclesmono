import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/screens/login/networkdetail.dart';
import 'package:ironcirclesapp/services/authentication_service.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/usercircle_service.dart';
import 'package:rxdart/rxdart.dart';

class UserFurnaceBloc {
  UserCircleService userCircleService = UserCircleService();

  final _authService = AuthenticationService();
  final _pushFurnaces = PublishSubject<List<UserFurnace>?>();
  final _pushFurnace = PublishSubject<UserFurnace?>();

  final _remove = PublishSubject<bool>();

  Stream<List<UserFurnace>?> get userfurnaces => _pushFurnaces.stream;
  Stream<UserFurnace?> get userFurnace => _pushFurnace.stream;
  Stream<bool> get removed => _remove.stream;

  final _linkFurnace = PublishSubject<UserFurnace>();
  Stream<UserFurnace> get linkFurnace => _linkFurnace.stream;

  final _connected = PublishSubject<FurnaceConnection>();
  Stream<FurnaceConnection?> get connected => _connected.stream;

  Future<List<UserFurnace>> requestConnected(String? userid) async {
    List<UserFurnace> furnaces;

    try {
      furnaces = await TableUserFurnace.readConnectedForUser(userid);
      _pushFurnaces.sink.add(furnaces);

      return furnaces;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserFurnaceBloc.requestConnected: $error');
      _pushFurnaces.sink.addError(error);
      rethrow;
    }
  }

  Future<List<UserFurnace>?> request(String? userid) async {
    List<UserFurnace>? furnaces;

    try {
      //debugPrint('start request time: ${DateTime.now()}');

      furnaces = await TableUserFurnace.readAllForUser(userid);

      //debugPrint('end request time: ${DateTime.now()}');

      furnaces.sort(
          (a, b) => a.alias!.toLowerCase().compareTo(b.alias!.toLowerCase()));

      //debugPrint('end sort time: ${DateTime.now()}');
      _pushFurnaces.sink.add(furnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _pushFurnaces.sink.addError(error);
    }

    return furnaces;
  }

  Future<List<UserFurnace>> requestAll() async {
    try {
      List<UserFurnace> _furnaces = await TableUserFurnace.readAll();

      return _furnaces;
      _pushFurnaces.sink.add(_furnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _pushFurnaces.sink.addError(error);
    }

    return [];
  }

  updateGuarded(UserFurnace userFurnace, bool guarded) async {
    try {
      userFurnace.guarded = guarded;
      userFurnace = await TableUserFurnace.upsert(userFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  updateTransparency(UserFurnace userFurnace, bool transparency) async {
    try {
      userFurnace.transparency = transparency;
      userFurnace = await TableUserFurnace.upsert(userFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }
  }

  reconnectLinkedAccount(BuildContext context, UserFurnace userFurnace) async {
    try {
      //sanity check
      if (userFurnace.linkedUser == null) //||
        // userFurnace.linkedUser != globalState.user.id)
        throw (AppLocalizations.of(context)!.errorGenericTitle);

      UserFurnace primary =
          await TableUserFurnace.readByUserID(userFurnace.linkedUser!);

      if (primary.connected == false) {
        throw ('${AppLocalizations.of(context)!.noLoginForLinkedAccount}: ${primary.alias}');
      }

      ///ensure user isn't locked out
      FurnaceConnection? furnaceConnection = await _authService
          .validateLinkedAccount(context, primary, userFurnace);

      if (furnaceConnection != null) {
        ///ratchet the receiving keys for this device
        AuthenticationBloc _authBloc = AuthenticationBloc();

        var userCircles = await TableUserCircleCache.readAllForUserFurnace(
            userFurnace.pk!, userFurnace.userid!);

        List<UserCircle> missing = await ForwardSecrecy.keysMissing(
            userFurnace.userid!, furnaceConnection.user.userCircles);

        _authBloc.generateCircleKeys(furnaceConnection.user, userFurnace,
            furnaceConnection.user.userCircles);

        userFurnace.connected = true;
        userFurnace = await TableUserFurnace.upsert(userFurnace);
      } else {
        throw (AppLocalizations.of(context)!.accountLocked);
      }
    } catch (err) {
      rethrow;
    }
  }

  connect(
      UserFurnace? userFurnace, bool connect, bool fromFurnaceManager) async {
    try {
      late User user;

      if (connect) {
        Device device = await UserSetting.getDeviceInfo(userFurnace: userFurnace!);

        String passwordNonce = await _authService.getNonce(userFurnace);

        String passwordHash = '';

        ///this should go away when everyone has a nonce serverside
        if (passwordNonce.isNotEmpty) {
          passwordHash = (await ForwardSecrecyUser.saltAndHashPassword(
                  userFurnace.password!, userFurnace.pin!,
                  passwordNonce: passwordNonce))
              .secretKeyString;
        }


        user = await _authService.validateCredentials(
          userFurnace,
          device,
          passwordHash,
          passwordNonce,
          userFurnace.password!,
          userFurnace.pin!,
        );

        ///get the passthrough variables, like ID and token
        userFurnace = user.userFurnace!;

        globalState.loggedOutToLanding = false;
        globalState.loggingOut = false;

        userFurnace.userid = user.id;
        userFurnace.user = user;
        userFurnace.connected = true;

        //create the user folder
        FileSystemService.makeUserPath(user.id);

        //userFurnace.token = user.token;
        userFurnace.avatar = user.avatar;

        userFurnace.autoKeychainBackup = user.autoKeychainBackup;
        userFurnace.connected = true;
        userFurnace.lastLogin = DateTime.now().millisecondsSinceEpoch;

        if (userFurnace.authServer == true) {
          userFurnace.authServerUserid = user.id;
          globalState.userFurnace = userFurnace;
          globalState.user = user;
        } else {
          userFurnace.authServerUserid = globalState.user.id;
        }

        await ForwardSecrecy.ratchetMissingServerSideKeys(
            userFurnace, user, user.userCircles);

        ///grab the users avatar
        AvatarService avatarService = AvatarService();
        avatarService.downloadAvatar(userFurnace, user);
      } else {
        userFurnace!.connected = false;
        user = User(username: userFurnace.username);
      }

      userFurnace.password = "";
      userFurnace.pin = "";

      userFurnace = await TableUserFurnace.upsert(userFurnace);

      ///remove authServer for other networks, no need to wait
      //if (userFurnace.authServer!)
      // await TableUserFurnace.clearOtherAuthServers(userFurnace);

      _connected.sink
          .add(FurnaceConnection(userFurnace: userFurnace, user: user));

      return user;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserFurnaceBloc.connect: $error');
      _connected.sink.addError(error);
    }
  }

  Future<bool> networkNameAvailable(String networkName) async {
    bool retValue = false;

    return retValue;
  }

  Future<bool> furnaceExists(UserFurnace userFurnace) async {
    //is the alias already in use?

    List<UserFurnace> furnaces =
        await TableUserFurnace.readAllForUser(globalState.user.id);

    for (UserFurnace existing in furnaces) {
      /*if (userFurnace.alias == existing.alias &&
          userFurnace.pk != existing.pk) {
        _pushFurnace.sink.addError("Furnace alias already exists");
        return true;
      }*/

      if (userFurnace.userid == existing.userid &&
          userFurnace.url == existing.url &&
          userFurnace.pk != existing.pk) {
        _pushFurnace.sink.addError("Already have a furnace with this user");
        return true;
      } /*else if (userFurnace.username == existing.username &&
          userFurnace.url == existing.url &&
          userFurnace.pk != existing.pk) {
        _pushFurnace.sink.addError("Already have a furnace with this user");
        return true;
      }*/

      /*
      if (userFurnace.userid != null) {
        if (userFurnace.userid == existing.userid &&
            userFurnace.pk != existing.pk) {
          _pushFurnace.sink.addError("Already have a furnace with this user");
          return true;
        }
      } else {
        if (userFurnace.username == existing.username &&
            userFurnace.pk != existing.pk) {
          _pushFurnace.sink.addError("Already have a furnace with this user");
          return true;
        }
      }

       */
    }

    return false;
  }

  prepUserFurnaceForRegistration(UserFurnace userFurnace, String username) {
    userFurnace.username = username.trim();

    if (kDebugMode && !Urls.testingReleaseMode) {
      userFurnace.password = '12345678';
      userFurnace.pin = '1234';
    } else {
      userFurnace.password = SecureRandomGenerator.generateString(length: 16);
      userFurnace.pin = SecureRandomGenerator.generateInt(max: 4).toString();
    }

    return userFurnace;
  }

  generateNetworkWithImages(
      GlobalEventBloc globalEventBloc,
      String networkName,
      String username,
      bool minor,
      HostedFurnaceBloc hostedNetworkBloc,
      File? networkImage,
      File? avatar,
      String? networkUrl,
      String? networkApiKey) async {
    UserFurnace userFurnace = await generateNetwork(
        networkName, username, minor,
        avatar: avatar,
        globalEventBloc: globalEventBloc,
        networkUrl: networkUrl,
        networkApiKey: networkApiKey);

    if (networkImage != null) {
      hostedNetworkBloc.updateImage(userFurnace, networkImage);
    }

    if (avatar != null) {
      AvatarService().updateAvatar(userFurnace, avatar, delete: false);
    }
  }

  generateNetwork(String networkName, String username, bool minor,
      {File? avatar,
      GlobalEventBloc? globalEventBloc,
      String? networkUrl,
      String? networkApiKey}) async {
    UserFurnace userFurnace = UserFurnace();

    if (networkUrl != null) {
      userFurnace.type = NetworkType.SELF_HOSTED;
      userFurnace.newNetwork = true;
    } else {
      userFurnace.type = NetworkType.HOSTED;
      userFurnace.newNetwork = true;
    }

    userFurnace.hostedAccessCode =
        SecureRandomGenerator.generateString(length: 12);
    userFurnace.hostedName = networkName;
    userFurnace.alias = networkName;
    userFurnace.authServer = true;
    userFurnace.enableWall = true;
    userFurnace = prepUserFurnaceForRegistration(userFurnace, username);

    if (networkUrl != null) {
      userFurnace.url = networkUrl;
      userFurnace.apikey = networkApiKey;
    } else {
      userFurnace.url = urls.spinFurnace;
      userFurnace.apikey = urls.spinFurnaceAPIKEY;
    }

    await register(userFurnace, null, minor, false,
        createNetworkName: true,
        avatar: avatar,
        globalEventBloc: globalEventBloc);

    return userFurnace;
  }

  register(
      UserFurnace userFurnace, File? _image, bool minor, bool linkedAccount,
      {bool createNetworkName = false,
      User? inviter,
      File? image,
      HostedInvitation? hostedInvitation,
      bool fromNetworkManager = false,
      File? avatar,
      GlobalEventBloc? globalEventBloc,
      UserFurnace? primaryNetwork}) async {
    try {
      if (await furnaceExists(userFurnace)) {
        return;
      }

      RatchetKey ratchetKey = await ForwardSecrecy.generateBlankKeyPair();
      ratchetKey.type = RatchetKeyType.user;

      late String backupSecret;
      late RatchetIndex backupIndex;
      late RatchetIndex userIndex;

      if (userFurnace.authServer!) {
        ///generate a backup key for multi-device login, key export, and autobackup
        backupSecret = await ForwardSecrecyUser.generateBackupSecret();

        ///encrypt the backupKey and store it serverside during registration
        backupIndex = await ForwardSecrecyUser.encryptBackupSecret(
            '', backupSecret, userFurnace.password!, userFurnace.pin!);

        userIndex = await ForwardSecrecyUser.encryptUserKey(
            backupSecret, '', ratchetKey);
      } else {
        ///reuse the auth user's backup key
        backupSecret = globalState.userSetting.backupKey;

        if (backupSecret.isEmpty) {
          //backupSecret = await SecureStorageService.readKey(
          //    KeyType.USER_KEYCHAIN_BACKUP + globalState.user.id!);

          //if (backupSecret.isEmpty) {
          //backupSecret = await ForwardSecrecyUser.generateBackupSecret();
          //keyUpdated = true;

          LogBloc.insertLog(
              'backup secret is empty during registration for: ${globalState.user.id!}',
              'UserFurnace.registration');
          //  }
        }

        ///encrypt the backupKey and later store it serverside during registration
        backupIndex = await ForwardSecrecyUser.encryptBackupSecret(
            '', backupSecret, userFurnace.password!, userFurnace.pin!);

        userIndex = await ForwardSecrecyUser.encryptUserKey(
            backupSecret, '', ratchetKey);
      }

      Device deviceAttributes = await UserSetting.getDeviceInfo(userFurnace: userFurnace);

      ///The ratchet is also used for first message of a DM, if this is from a magic link.
      ///add to receiver keychain

      await TableRatchetKeyReceiver.insert(ratchetKey);

      if (!linkedAccount) {
        UserSecret userSecret = await ForwardSecrecyUser.saltAndHashPassword(
            userFurnace.password!, userFurnace.pin!);

        userFurnace = await _authService.registerFurnace(
            userFurnace,
            userSecret.secretKeyString,
            userSecret.nonceString,
            ratchetKey,
            backupIndex,
            userIndex,
            minor,
            deviceAttributes,
            linkedAccount,
            createNetworkName: createNetworkName,
            inviter: inviter,
            image: image,
            hostedInvitation: hostedInvitation,
            fromNetworkManager: fromNetworkManager);
      } else {
        userFurnace = await _authService.registerFurnace(
          userFurnace,
          '',
          '',
          ratchetKey,
          backupIndex,
          userIndex,
          minor,
          deviceAttributes,
          linkedAccount,
          createNetworkName: createNetworkName,
          inviter: inviter,
          image: image,
          hostedInvitation: hostedInvitation,
          primaryNetwork: primaryNetwork,
        );
      }

      globalState.loggedOutToLanding = false;
      globalState.loggingOut = false;

      User user = userFurnace.user!;

      if (userFurnace.authServer!) {
        FileSystemService.makeCirclePath(
            globalState.user.id!, DeviceOnlyCircle.circleID);

        await globalState.userSetting.setFirstTimeInCircle(false);
        await globalState.userSetting.setAskedToGuardVault(false);

        //SecureStorageService.writeKey(
        //   KeyType.USER_KEYCHAIN_BACKUP + user.id!, backupSecret);

        globalState.user = user;
        await globalState.userSetting.setBackupKey(backupSecret);

        ///run a backup for the auth server
        KeychainBackupBloc.backupDevice(userFurnace, true);
      } else if (userFurnace.linkedUser != globalState.user.id!) {
        UserSetting? userSetting =
            await TableUserSetting.read(userFurnace.userid!);

        if (userSetting != null) {
          ///run a backup for the standalone network
          await userSetting.setBackupKey(backupSecret);
        }

        KeychainBackupBloc.backupDevice(userFurnace, true);
      } else if (userFurnace.linkedUser == globalState.user.id!) {
        KeychainBackupBloc.backupDevice(globalState.userFurnace!, true);

      }

      ///create the user folder
      FileSystemService.makeUserPath(user.id);

      ///code below sink.add is old
      if (avatar != null) {
        AvatarService avatarService = AvatarService();

        ///cache only
        await avatarService.updateAvatarCache(userFurnace, avatar);
      }

      _pushFurnace.sink.add(userFurnace);

      if (_image != null) {
        AvatarService avatarService = AvatarService();
        await avatarService.updateAvatar(userFurnace, _image);
      }

      if (globalEventBloc != null) {
        ///save the received UserCircles and Objects
        UserCircleBloc userCircleBloc =
            UserCircleBloc(globalEventBloc: globalEventBloc);

        await userCircleBloc.refreshCacheFromSingleFurnace(
            userFurnace, [], callbackStub, [userFurnace], true,
            registrationUserCirclesAndObjects: UserCirclesAndObjects(
                userCircles: user.userCircles,
                circleObjects: user.circleObjects));
      } else {
        userCircleService.fetchUserCircles(userFurnace, null, []);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _pushFurnace.sink.addError(error);
    }
  }

  callbackStub(List<UserFurnace> userFurnaces) {}

  refreshUserCircles(String? userid) async {
    try {
      List<UserFurnace> userFurnaces = await requestConnected(userid);

      for (UserFurnace userFurnace in userFurnaces) {
        List<String?> openGuardedIDs =
            await TableUserCircleCache.readOpenGuardedForFurnace(
                userFurnace.pk, userFurnace.userid);

        List<UserCircleCache> cachedUserCircles =
            await TableUserCircleCache.readAllForUserFurnace(
                userFurnace.pk, userFurnace.userid);

        List<CircleLastLocalUpdate> circleLastUpdates =
            await CircleLastLocalUpdate.readAll(cachedUserCircles);

        userCircleService.fetchUserCircles(
            userFurnace, openGuardedIDs, circleLastUpdates);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserFurnaceBloc.refreshUserCircles: $error');
      //_remove.sink.addError(error);
    }
  }

  remove(UserFurnace userFurnace) async {
    try {
      int row = await TableUserFurnace.delete(userFurnace.pk);

      if (row > 0)
        _remove.sink.add(true);
      else
        throw ("Could not remove furnace");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _remove.sink.addError(error);
    }
  }

  getLatestUserFurnace() {
    return TableUserFurnace.readMostRecent();
  }

  /*_refreshCacheFromSingleFurnace(
    UserFurnace userFurnace,
  ) async {
    try {
      final UserCircleService userCircleService = UserCircleService();

      List<UserCircle> userCircles =
          (await userCircleService.fetchUserCircles(userFurnace, [], []));

      for (UserCircle userCircle in userCircles) {
        if (userCircle.circle == null) {
          continue;
        }
        TableUserCircleCache.updateUserCircleCache(userCircle, userFurnace);
      }

      return userCircles;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserCircleBloc.refreshCacheFromSingleFurnace: $err');
    }
  }*/
  //
  // linkAccount(UserFurnace userFurnace) async {
  //   try {
  //     ///update the api
  //     await _authService.linkAccount(userFurnace, globalState.userFurnace!);
  //
  //     ///update the userFurnace
  //     userFurnace.linkedUser = globalState.user.id;
  //     await TableUserFurnace.upsert(userFurnace);
  //
  //     _linkFurnace.sink.add(userFurnace);
  //   } catch (error, trace) {
  //     LogBloc.insertError(error, trace);
  //     _linkFurnace.sink.addError(error);
  //   }
  // }

  dispose() async {
    await _pushFurnaces.drain();
    await _pushFurnace.drain();
    await _remove.drain();

    _pushFurnaces.close();
    _pushFurnace.close();
    _remove.close();

    await _connected.drain();
    _connected.close();
  }
}
