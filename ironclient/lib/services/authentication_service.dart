import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/encryption/kyber/kyber.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/ironcoinwallet.dart';
import 'package:ironcirclesapp/models/officialnotification.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/screens/login/login_changepassword1.dart';
import 'package:ironcirclesapp/screens/login/networkdetail.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_updatetracker.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/device_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:ironcirclesapp/utils/notification_localization.dart';

class AuthenticationService {
  //Client client = Client();

  final String android = 'android';
  final String iOS = 'iOS';

  Future<bool> postEncryptedFragForPasscodeReset(UserFurnace userFurnace,
      String resetUserID, RatchetIndex returnIndex) async {
    String url = userFurnace.url! + Urls.ENCRYPTED_FRAG_FOR_PASSCODE_RESET;

    debugPrint(url);

    Map map = {
      'returnIndex': returnIndex,
      'resetUserID': resetUserID,
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

      return true;
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  Future<RatchetIndex> getRatchetForPasscodeReset(
      UserFurnace userFurnace, String resetUserID) async {
    String url = userFurnace.url! + Urls.RATCHET_FOR_PASSCODE_RESET;

    debugPrint(url);

    Map map = {
      'resetUserID': resetUserID,
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

      RatchetIndex ratchetIndex =
          RatchetIndex.fromJson(jsonResponse!["ratchetIndex"]);

      return ratchetIndex;
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  Future<String?> generateResetCode(
      String? username, UserFurnace userFurnace, RatchetKey ratchetKey) async {
    Map map = {
      //'apikey': Urls.APIKEY,
      'username': username,
      'build': globalState.build,
      'ratchetPublicKey': ratchetKey.safePublicCopy()
    };

    String url = '';

    if (userFurnace.url == null) {
      url = urls.forge + Urls.USER_GENERATE_RESET_CODE;
      map['apikey'] = urls.forgeAPIKEY;
    } else {
      url = userFurnace.url! + Urls.USER_GENERATE_RESET_CODE;
      map['apikey'] = userFurnace.apikey;
    }

    if (userFurnace.newNetwork ||
        userFurnace.type == NetworkType.HOSTED ||
        (userFurnace.hostedName != null &&
            userFurnace.hostedName!.isNotEmpty)) {
      map["hostedName"] = userFurnace.alias;

      if (userFurnace.hostedAccessCode != null) {
        map['key'] = userFurnace.hostedAccessCode;
      }
    }

    map = await EncryptAPITraffic.encrypt(map);

    debugPrint(url);

    final response = await http.post(Uri.parse(url),
        headers: {
          //'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      return jsonResponse!['msg'];
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw jsonResponse!['msg'];
    }
  }

  Future<User> changePassword(
      String? username,
      String existing,

      ///hash or password (legacy)
      String existingPin,
      String passwordHash,
      String passwordNonce,
      UserFurnace userFurnace,
      RatchetIndex backupIndex,
      {String newUsername = '',
      RatchetIndex? userIndex}) async {
    Map map = {
      //'apikey': Urls.APIKEY,
      'username': username,
      'passwordHash': passwordHash,
      'passwordNonce': passwordNonce,
      'existing': existing,
      'build': globalState.build,
      'existingPin': existingPin,
      'backupIndex': backupIndex,
      'authUserID': globalState.userFurnace!.userid!
    };

    if (newUsername.isNotEmpty) map['newUsername'] = newUsername;
    if (userIndex != null) map['userIndex'] = userIndex;

    String url = '';

    Map<String, String> headers = {
      'Content-Type': "application/json",
    };

    if (globalState.user.id != null &&
        globalState.user.passwordBeforeChange == false) {
      if (userFurnace.url == null) {
        ///IronForge
        url = urls.forge + Urls.CHANGEPASSWORDFROMTOKEN;
        map['apikey'] = urls.forgeAPIKEY;
      } else {
        ///self hosted
        map['apikey'] = userFurnace.apikey;
        url = userFurnace.url! + Urls.CHANGEPASSWORDFROMTOKEN;
      }

      headers['Authorization'] = userFurnace.token!;
    } else {
      if (userFurnace.url == null) {
        url = urls.forge + Urls.CHANGEPASSWORD;
        map['apikey'] = urls.forgeAPIKEY;
      } else {
        map['apikey'] = userFurnace.apikey;
        url = userFurnace.url! + Urls.CHANGEPASSWORD;
      }
    }

    if (userFurnace.hostedAccessCode != null) {
      map['hostedName'] = userFurnace.hostedName;
      map['key'] = userFurnace.hostedAccessCode;
    }

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(Uri.parse(url),
        headers: headers, body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      User user = User.fromJson(jsonResponse["user"]);

      if (userFurnace.authServer!) {
        globalState.user.username = user.username;
        globalState.userFurnace!.username = user.username;
        globalState.userFurnace!.password = null;
        globalState.userFurnace!.pin = null;
        globalState.userFurnace!.passwordHash = passwordHash;
        globalState.userFurnace!.passwordNonce = passwordNonce;
      }

      userFurnace.username = user.username;
      userFurnace.password = null;
      userFurnace.pin = null;

      ///will override the pass/pin with blanks
      ///will also update the passwordHash and passwordNonce
      await TableUserFurnace.removeGenerated(userFurnace);

      return user;
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  Future<List<RatchetIndex>> getResetCodeRatchetIndexes(
      String? username, String resetCode, UserFurnace userFurnace) async {
    Map map = {
      'username': username,
      //'password': password,
      'resetcode': resetCode,
    };

    String url = '';

    if (userFurnace.url == null) {
      url = urls.forge + Urls.USER_RESET_CODE_RATCHETINDEXES;
      map['apikey'] = urls.forgeAPIKEY;
    } else {
      url = userFurnace.url! + Urls.USER_RESET_CODE_RATCHETINDEXES;
      map['apikey'] = userFurnace.apikey;
    }

    if (userFurnace.hostedName != null) {
      map['hostedName'] = userFurnace.hostedName;
      if (userFurnace.hostedAccessCode != null) {
        map['key'] = userFurnace.hostedAccessCode;
      }
    }

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    //final response = await http.post(Uri.parse(url), body: map);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      if (jsonResponse!.containsKey("ratchetIndexes")) {
        List<RatchetIndex> recoveryIndexes =
            RatchetIndexCollection.fromJSON(jsonResponse, "ratchetIndexes")
                .ratchetIndexes;

        //RatchetIndex userIndex = RatchetIndex.fromJson(jsonResponse["userIndex"]);
        //UserBackupKey userBackupKey = UserBackupKey(userIndex: userIndex, recoveryIndexes: recoveryIndexes, assistants: []);

        return recoveryIndexes;
      } else
        throw (jsonResponse['msg']);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);
      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  Future<User> resetPasswordFromCode(
      String? username,
      String resetCode,
      String password,
      String pin,
      String passwordHash,
      String passwordNonce,
      UserFurnace userFurnace,
      RatchetIndex backupIndex) async {
    Map map = {
      'username': username,
      'passwordHash': passwordHash,
      'passwordNonce': passwordNonce,
      'resetcode': resetCode,
      'backupIndex': backupIndex,
    };

    if (userFurnace.hostedName != null) {
      map['hostedName'] = userFurnace.hostedName;
      if (userFurnace.hostedAccessCode != null) {
        map['key'] = userFurnace.hostedAccessCode;
      }
    }

    String url = '';

    if (userFurnace.url == null) {
      url = urls.forge + Urls.USER_RESET_CODE;
      map['apikey'] = urls.forgeAPIKEY;
    } else {
      url = userFurnace.url! + Urls.USER_RESET_CODE;
      map['apikey'] = userFurnace.apikey;
    }

    map = await EncryptAPITraffic.encrypt(map);

    debugPrint(url);

    final response = await http.put(Uri.parse(url),
        headers: {
          //'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      if (jsonResponse!.containsKey("user")) {
        User user = User.fromJson(jsonResponse["user"]);

        /*await navService.push(MaterialPageRoute(
          builder: (context) => Login(
                //screenType: PassScreenType.PASSWORD_EXPIRED,
                username: username,
                toast:"password reset successfully",
              )));*/

        //return null;

        return user;
      } else
        throw (jsonResponse['msg']);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  _setupFurnace(
      User user, UserFurnace userFurnace, bool createNetworkName) async {
    try {
      if (userFurnace.authServer == true) {
        //load the furnace
        UserFurnace? exists = await TableUserFurnace.readUserAuthByID(user.id!);

        if (exists != null) userFurnace = exists;

        //update the furnace
        userFurnace.token = user.token;
        userFurnace.connected = true;
        userFurnace.userid = user.id;
        userFurnace.username = user.username;
        userFurnace.autoKeychainBackup = user.autoKeychainBackup;
        userFurnace.authServerUserid = user.id;
        //userFurnace = await TableUserFurnace.updateAuthServer(userFurnace);

        if (createNetworkName)

          ///include the generated password and pin
          userFurnace = await TableUserFurnace.registerGenerated(userFurnace);
        else
          userFurnace = await TableUserFurnace.upsert(userFurnace);
        // } else {
        // userFurnace = await TableUserFurnace.insertForge(user);
        // }
      } else {
        //update the furnace
        userFurnace.token = user.token;
        userFurnace.connected = true;
        userFurnace.userid = user.id;
        userFurnace.username = user.username;
        userFurnace.autoKeychainBackup = user.autoKeychainBackup;
        userFurnace.authServer = false;
        //userFurnace = await TableUserFurnace.updateAuthServer(userFurnace);

        userFurnace.authServerUserid = globalState.user.id;

        userFurnace = await TableUserFurnace.upsert(userFurnace);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }

    return userFurnace;
  }

  Future<User?> validateCredentialsOnly(
      String? username,
      String passwordHash,
      String password,
      String pin,
      UserFurnace? userFurnace,
      Device deviceAttributes) async {
    //Map map;
    String url;

    Device device = await globalState.getDevice();

    Map map = {
      'username': username,
      'passwordHash': passwordHash,
      'uuid': device.uuid,
      'build': globalState.build,
      'pushtoken': device.pushToken,
      'platform': device.platform == null || device.platform!.isNotEmpty
          ? device.platform
          : DeviceBloc.getPlatformString(),
      'model': deviceAttributes.model,
    };

    ///deprecated
    if (passwordHash.isEmpty) {
      map['password'] = password;
      map['pin'] = pin;
    }

    if (userFurnace == null) {
      url = urls.forge + Urls.LOGIN;
      map['apikey'] = urls.forgeAPIKEY;

      userFurnace = UserFurnace();
      userFurnace.authServer = true;
      userFurnace.alias = "IronForge";
      userFurnace.url = urls.forge;
      userFurnace.apikey = urls.forgeAPIKEY;
    } else {
      url = userFurnace.url! + Urls.LOGIN;
      map['apikey'] = userFurnace.apikey;

      if (userFurnace.hostedAccessCode != null) {
        map['hostedName'] = userFurnace.hostedName;
        map['key'] = userFurnace.hostedAccessCode;
      }
    }

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(Uri.parse(url),
        headers: {
          //'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));
    // .timeout(const Duration(seconds: 5));

    Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

    if (response.statusCode == 200) {
      //did we get a token?
      if (jsonResponse!['token'] == null) {
        //is there a refresh password attribute?
        if (jsonResponse['changePassword'] != null) {
          if (jsonResponse['changePassword'] == true)
            await navService.push(MaterialPageRoute(
                builder: (context) => ChangePassword1(
                      screenType: PassScreenType.PASSWORD_EXPIRED,
                      username: username,
                    )));

          return null;
        }

        throw (jsonResponse['msg']);
      }

      if (jsonResponse["officialNotification"] != null) {
        OfficialNotification notification =
            OfficialNotification.fromJson(jsonResponse["officialNotification"]);
        globalState.notification = notification;
      }

      User user = User.fromJson(jsonResponse["user"]);

      user.token = jsonResponse['token'];
      //debugPrint(user.token);
      UserFurnace initializedFurnace =
          await _setupFurnace(user, userFurnace, false);

      late String backupSecret;

      if (initializedFurnace.authServer!) {
        globalState.userFurnace = initializedFurnace;
        globalState.user = user;

        if (jsonResponse.containsKey("latestBuild"))
          globalState.setUpdateAvailable(
              jsonResponse["latestBuild"], jsonResponse["minimumBuild"]);

        UserSetting.populateUserSettingsFromAPI(
            globalState.userSetting, user, false);

        backupSecret = globalState.userSetting.backupKey;
      } else if (initializedFurnace.linkedUser != globalState.user.id!) {
        UserSetting? userSetting =
            await TableUserSetting.read(initializedFurnace.userid!);

        if (userSetting == null) {
          LogBloc.postLog(
              'UserSetting is null for ${initializedFurnace.userid!}',
              'AuthenticationService.validateCredentialsOnly');
        }

        userSetting ??= UserSetting(
            username: initializedFurnace.username!,
            id: initializedFurnace.userid!,
            fontSize: 16);
        UserSetting.populateUserSettingsFromAPI(userSetting, user, false);

        backupSecret = userSetting.backupKey;
      }

      RatchetKey ratchetKey = await RatchetKey.getLatestUserKeyPair(user.id!);
      // String backupSecret = await SecureStorageService.readKey(
      //    KeyType.USER_KEYCHAIN_BACKUP + user.id!);

      if (ratchetKey.private.isEmpty || backupSecret.isEmpty) {
        try {
          LogBloc.insertLog('Could not find backup key, pulling from Server',
              'AuthenticationService.validateCredentialsOnly');

          await ForwardSecrecyUser.decryptBackupAndUserKeys(
              RatchetKey.fromJson(jsonResponse["ratchetPublicKey"]),
              RatchetIndex.fromJson(jsonResponse["backupIndex"]),
              RatchetIndex.fromJson(jsonResponse["userIndex"]),
              user.id!,
              password,
              pin);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('$err');
        }
      }

      if (jsonResponse['userCircles'] != null) {
        List<UserCircle> userCircles =
            UserCircleCollection.fromJSON(jsonResponse, 'userCircles')
                .userCircles;

        user.userCircles = userCircles;
      }

      await ForwardSecrecy.ratchetMissingServerSideKeys(
          initializedFurnace, user, user.userCircles);

      //if (globalState.user.autoKeychainBackup!) KeychainBackupService.backup();

      //grab the users avatar
      AvatarService avatarService = AvatarService();
      avatarService.downloadAvatar(initializedFurnace, user);

      if (jsonResponse['needRemotePublicKey'] == true) {
        //TODO This can go away once everyone has a publicRatchetKey
        await ForwardSecrecy.generateUserKey(user, initializedFurnace);
        //ForwardSecrecyUser.saveUserKeyToReceiver(user.id!);
      }

      return user;
    } else {
      debugPrint(response.statusCode.toString());
      // If that call was not successful, throw an error.
      throw Exception(jsonResponse!['err']);
    }
  }

  Future<void> registerUserOnForge(
      UserFurnace userFurnace,
      User user,
      String passwordHash,
      String passwordNonce,
      RatchetKey ratchetKey,
      RatchetIndex backupIndex,
      RatchetIndex userIndex,
      Device device,
      {bool fromNetworkManager = false}) async {
    try {
      //Map map;

      if (device.platform == null || device.platform!.isEmpty) {
        device.platform = DeviceBloc.getPlatformString();
        //TableDevice.upsert(device);
      }

      Map map = {
        "hostedName": userFurnace.id,
        'username': userFurnace.username,
        'newNetwork': userFurnace.newNetwork,
        'type': userFurnace.type.index,
        //'passwordHash': passwordHash,
        // 'passwordNonce': passwordNonce,
        'pushtoken': device.pushToken,
        'uuid': device.uuid,
        'authServer': userFurnace.authServer!,
        'build': globalState.build,
        'ratchetPublicKey': ratchetKey.safePublicCopy(),
        'backupIndex': backupIndex,
        'fromNetworkManager': fromNetworkManager,
        'platform': device.platform,
        'model': device.model,
        'apikey': urls.forgeAPIKEY,
      };

      String url = urls.forge + Urls.REGISTER_STANDALONE;

      map = await EncryptAPITraffic.encrypt(map);

      var response = await http.post(Uri.parse(url),
          headers: {
            // 'Authorization': globalState.userFurnace!.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      //Map<String, dynamic>? jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        ///did we get a token?
        if (jsonResponse!['token'] == null) {
          throw (jsonResponse['msg']);
        }

        if (jsonResponse["officialNotification"] != null) {
          OfficialNotification notification = OfficialNotification.fromJson(
              jsonResponse["officialNotification"]);
          globalState.notification = notification;
        }

        User user = User.fromJson(jsonResponse["user"]);

        userFurnace.forgeUserId = user.id;
        userFurnace.forgeToken = jsonResponse['token'];

        await TableUserFurnace.upsert(userFurnace);

        return;
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        debugPrint(response.body);
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!['err'].toString());
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.registerFurnace: ${err.toString()}');
      rethrow;
    }
  }

  Future<UserFurnace> registerFurnace(
      UserFurnace userFurnace,
      String passwordHash,
      String passwordNonce,
      RatchetKey ratchetKey,
      RatchetIndex backupIndex,
      RatchetIndex userIndex,
      bool minor,
      Device device,
      bool linkedAccount,
      {joinBeta = false,
      bool createNetworkName = false,
      User? inviter,
      HostedInvitation? hostedInvitation,
      File? image,
      bool fromNetworkManager = false,
      UserFurnace? primaryNetwork}) async {
    try {
      //Map map;
      String url;

      if (device.platform == null || device.platform!.isEmpty) {
        device.platform = DeviceBloc.getPlatformString();
        //TableDevice.upsert(device);
      }

      Map map = {
        //'apikey': Urls.APIKEY,
        'username': userFurnace.username,
        'newNetwork': userFurnace.newNetwork,
        'type': userFurnace.type.index,
        //'pin': userFurnace.pin,
        'passwordHash': passwordHash,
        'passwordNonce': passwordNonce,
        'pushtoken': device.pushToken,
        'uuid': device.uuid,
        'authServer': userFurnace.authServer!,
        'enableWall': userFurnace.enableWall,
        'minor': minor,
        'memberAutonomy': userFurnace.memberAutonomy,
        'discoverable': userFurnace.discoverable,
        'adultOnly': userFurnace.adultOnly,
        'description': userFurnace.description,
        'link': userFurnace.link,
        'joinBeta': joinBeta,
        'createNetworkName': createNetworkName,
        'build': globalState.build,
        'tos': 'true',
        'ratchetPublicKey': ratchetKey.safePublicCopy(),
        'backupIndex': backupIndex,
        'fromNetworkManager': fromNetworkManager,
        'userIndex': userIndex,
        'platform': device.platform,
        'model': device.model,
      };

      if (globalState.user.id != null) map['authUserID'] = globalState.user.id!;

      if (inviter != null) map['inviterID'] = inviter.id!;
      if (hostedInvitation != null) map['magicLink'] = hostedInvitation.link;

      if (userFurnace.type == NetworkType.HOSTED) {
        map["hostedName"] = userFurnace.alias;
        map["key"] = userFurnace.hostedAccessCode;

        ///hosted furnaces will always hit the forge
        url = urls.forge;
        map['apikey'] = urls.forgeAPIKEY;
      } else if (userFurnace.type == NetworkType.FORGE ||
          userFurnace.url == null) {
        url = urls.forge;
        map['apikey'] = urls.forgeAPIKEY;
      } else if (userFurnace.type == NetworkType.SELF_HOSTED) {
        url = userFurnace.url!;
        map['apikey'] = userFurnace.apikey;
        map["hostedName"] = userFurnace.alias;
        map["key"] = userFurnace.hostedAccessCode;
      } else {
        throw "Something went wrong";
      }

      late http.Response response;

      map = await EncryptAPITraffic.encrypt(map);

      if (linkedAccount) {
        url = url + Urls.REGISTERLINKEDACCOUNT;

        debugPrint(url);

        response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': primaryNetwork!.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));
      } else {
        url = url + Urls.REGISTER;

        debugPrint(url);

        response = await http.post(Uri.parse(url),
            headers: {
              //'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));
      }

      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      if (response.statusCode == 200) {
        //did we get a token?
        if (jsonResponse!['token'] == null) {
          throw (jsonResponse['msg']);
        }

        if (jsonResponse["officialNotification"] != null) {
          OfficialNotification notification = OfficialNotification.fromJson(
              jsonResponse["officialNotification"]);
          globalState.notification = notification;
        }

        User user = User.fromJson(jsonResponse["user"]);
        user.token = jsonResponse['token'];

        //debugPrint(user.token);

        ///get id and name from server
        var network = jsonResponse["hostedFurnace"];
        userFurnace.hostedName = network["name"];
        userFurnace.alias = network["name"];
        userFurnace.id = network["_id"];
        userFurnace.hostedId = network["id"];
        userFurnace.token = user.token;
        userFurnace.description = network["description"];
        userFurnace.link = network["link"];
        userFurnace.adultOnly = network["adultOnly"];
        userFurnace.discoverable = network["discoverable"];
        userFurnace.role = user.role;
        userFurnace.memberAutonomy = network["memberAutonomy"];
        userFurnace.passwordHash = passwordHash;
        userFurnace.passwordNonce = passwordNonce;

        if (linkedAccount) userFurnace.linkedUser = globalState.user.id!;

        UserFurnace initializedFurnace =
            await _setupFurnace(user, userFurnace, createNetworkName);

        if (initializedFurnace.authServer!) {
          globalState.userFurnace = initializedFurnace;
          globalState.user = user;
          globalState.ironCoinWallet =
              IronCoinWallet.fromJson(jsonResponse["ironCoinWallet"]);

          if (jsonResponse.containsKey("latestBuild"))
            globalState.setUpdateAvailable(jsonResponse["latestBuild"]);

          UserSetting.populateUserSettingsFromAPI(
              globalState.userSetting, user, true);
        } else if (initializedFurnace.linkedUser != globalState.user.id!) {
          UserSetting? userSetting =
              await TableUserSetting.read(initializedFurnace.userid!);

          LogBloc.postLog(
              'UserSetting is null for ${initializedFurnace.userid!}',
              'AuthenticationService.registerFurnace');

          userSetting ??= UserSetting(
              username: initializedFurnace.username!,
              id: initializedFurnace.userid!,
              fontSize: 16);
          UserSetting.populateUserSettingsFromAPI(userSetting, user, false);
        }

        if (jsonResponse['userCircles'] != null) {
          List<UserCircle> userCircles =
              UserCircleCollection.fromJSON(jsonResponse, 'userCircles')
                  .userCircles;

          user.userCircles = userCircles;
        }

        await ForwardSecrecyUser.saveUserKey(ratchetKey, user.id!);
        await ForwardSecrecyUser.saveUserKeyToReceiver(ratchetKey, user.id!);
        await ForwardSecrecyUser.createSignatureKey(userFurnace);

        await ForwardSecrecy.ratchetMissingServerSideKeys(
            initializedFurnace, user, user.userCircles);

        if (linkedAccount) {
          AvatarService avatarService = AvatarService();

          avatarService.downloadAvatar(initializedFurnace, user);
        }

        initializedFurnace.user = user;

        if (image != null) {
          ///This doesn't need listeners so no need to use Provider globalState
          GlobalEventBloc globalEventBloc = GlobalEventBloc();
          HostedFurnaceBloc hostedFurnaceBloc =
              HostedFurnaceBloc(globalEventBloc);
          hostedFurnaceBloc.updateImage(userFurnace, image);
        }

        if (userFurnace.type == NetworkType.SELF_HOSTED) {
          registerUserOnForge(userFurnace, user, passwordHash, passwordNonce,
              ratchetKey, backupIndex, userIndex, device,
              fromNetworkManager: fromNetworkManager);
        }

        return initializedFurnace;
      } else {
        debugPrint(response.statusCode.toString());
        debugPrint(response.body);
        // If that call was not successful, throw an error.
        throw Exception(response.body);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.registerFurnace: ${err.toString()}');
      rethrow;
    }
  }

  /*Future<User> putEncryptedBackupAndUserKeys(
      UserFurnace userFurnace,
      String password,
      String pin,
      RatchetIndex backupIndex,
      RatchetIndex userIndex) async {
    try {
      String url;

      Device device = await globalState.getDevice();

      Map map = {
        //'apikey': Urls.APIKEY,
        // 'username': userFurnace.username,
        'password': password,
        'pin': pin,
        // 'pushtoken': (pushToken == null ? '' : pushToken),
        'uuid': device.uuid,
        //'forge': true,
        // 'build': globalState.build,
        //'tos': 'true',
        'user': userFurnace.userid!,
        //'ratchetPublicKey': ratchetKey.safePublicCopy(),
        'backupIndex': backupIndex,
        'userIndex': userIndex,
        //'platform': Platform.isAndroid ? android : iOS,
      };

      url = userFurnace.url! + Urls.BACKUPUSERKEY;
      // map['apikey'] = userFurnace.apikey;

      debugPrint(url);

      //final response = await http.post(Uri.parse(url), body: map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        User user = User.fromJson(jsonResponse!["user"]);

        user.token = jsonResponse["token"];
        userFurnace.token = jsonResponse["token"];

        await TableUserFurnace.upsert(userFurnace);

        if (user.autoKeychainBackup == true) {
          //flip the switch, it will delete old backups and start over
          await KeychainBackupService.toggle(userFurnace, false);
          await KeychainBackupService.toggle(userFurnace, true);
          await KeychainBackupService.backup();
        }

        return user;
      } else {
        debugPrint(response.statusCode.toString());
        debugPrint(response.body);
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!['err'].toString());
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.registerFurnace: ${err.toString()}');
      throw Exception(err);
    }
  }

   */

  logout(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.LOGOUT;

      Device device = await globalState.getDevice();

      Map map = {
        'uuid': device.uuid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
            //'apikey': urls.forgeAPIKEY,
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        return;
      } else if (response.statusCode == 401) {
        //await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } on TimeoutException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.logout: ${err.toString()}');
      throw Exception(err);
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.logout: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.logout: ${err.toString()}');
      throw Exception(err);
    }
  }

  Future<bool?> checkResetCodeAvailable(
      UserFurnace userFurnace, String username) async {
    try {
      String url = '';

      if (userFurnace.url == null) {
        url = urls.forge + Urls.USER_RESET_CODE_AVAILABLE;
      } else {
        url = userFurnace.url! + Urls.USER_RESET_CODE_AVAILABLE;
      }

      Map map = {
        'username': username,
      };

      debugPrint(url);

      if (userFurnace.newNetwork || userFurnace.type == NetworkType.HOSTED) {
        map["hostedName"] = userFurnace.alias;
        map["key"] = userFurnace.hostedAccessCode;
        //url = urls.forge +
        // Urls.REGISTER; //hosted furnaces will always hit the forge
        map['apikey'] = urls.forgeAPIKEY;
      } else {
        if (userFurnace.apikey == null)
          map['apikey'] = urls.forgeAPIKEY;
        else
          map['apikey'] = userFurnace.apikey;
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http
          .post(Uri.parse(url),
              headers: {
                'Content-Type': "application/json",
              },
              body: json.encode(map))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        return jsonResponse!['resetcodeavailable'];
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } on TimeoutException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.checkResetCodeAvailable: ${err.toString()}');
      rethrow;
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.checkResetCodeAvailable: ${err.toString()}');
      rethrow;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.checkResetCodeAvailable: ${err.toString()}');
      rethrow;
    }

    return false;
  }

  /*
  Future<void> setRemotePublic2(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.SET_REMOTE_PUBLIC;

      RatchetKey publicKey =
          await ForwardSecrecyUser.getUserPublicKey(userFurnace.userid!);

      debugPrint(url);

      Map map = {
        'apikey': userFurnace.apikey,
        'ratchetPublicKey': publicKey,
      };

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));
      //.timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        return;
      } else {
        debugPrint('AuthenticationService.validateToken:' +
            response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(response.statusCode.toString());
      }
    } on SocketException catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.validateToken: ${err.toString()}');

      return;
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.setRemotePublic: ${err.toString()}');
      throw Exception(err);
    }
  }

   */


  updateKyberKey(UserFurnace userFurnace, Device device, KyberEncryptionResult kyberEncryptionResult, DeviceService deviceService) async {

    await deviceService.postCipherText(device, userFurnace.url ?? urls.forge,
        kyberEncryptionResult.cipherText.bytes);

    ///store the shared secret in encrypted storage
    device.kyberSharedSecret =
        base64UrlEncode(kyberEncryptionResult.sharedSecret.bytes);
    //List<int> testing = base64Url.decode(device.kyberSharedSecret!);

    await TableDevice.upsert(device);
    globalState.setDevice(device);

    await TableUpdateTracker.upsert(UpdateTrackerType.iosDeviceID, true);
  }


  Future<User> validateToken(
      UserFurnace userFurnace, Device deviceAttributes) async {
    try {
      String url = userFurnace.url! + Urls.AUTHTOKEN;

      Device device = await globalState.getDevice();

      debugPrint(url);

      RatchetKey ratchetKey =
          await ForwardSecrecyUser.getSignatureKey(userFurnace);

      ///TODO device needs a platform field
      if (device.platform == null || device.platform!.isEmpty) {
        device.platform = DeviceBloc.getPlatformString();
        //TableDevice.upsert(device);
      }

      Map map = {
        'apikey': userFurnace.apikey,
        'username': userFurnace.username,
        'password': userFurnace.password,
        'uuid': device.uuid,
        'build': globalState.build,
        'identity': ratchetKey.public,
        'pushtoken': device.pushToken,
        'platform': device.platform,
        'model': deviceAttributes.model,
      };

      if (await Network.isConnected()) {

        ///this will only happen the first time an ios phone is kyber reset
        if (deviceAttributes.oldID != null) {
          map["updateKyber"] = true;
          map['oldID'] = deviceAttributes.oldID;
        }



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


          if (jsonResponse["pk"] != null) {

            DeviceService deviceService = DeviceService();
            KyberEncryptionResult result = deviceService.calculateCipher(jsonResponse);
            updateKyberKey(userFurnace, device, result, deviceService);

          }

          if (jsonResponse["officialNotification"] != null) {
            OfficialNotification notification = OfficialNotification.fromJson(
                jsonResponse["officialNotification"]);
            globalState.notification = notification;
          }

          // If the call to the server was successful, parse the JSON
          User user = User.fromJson(jsonResponse["user"]);
          user.token = userFurnace.token; //TODO is this needed?

          if (user.clearPattern != null && user.clearPattern!) {
            globalState.userSetting.inactivePatternPinString();
          }

          /*if (jsonResponse.containsKey("needUserKeyBackup")) {
          if (jsonResponse["needUserKeyBackup"] == true) user.needPin = true;
        }
         */
          userFurnace.connected = true;
          userFurnace.username = user.username;
          userFurnace.avatar = user.avatar;
          userFurnace.autoKeychainBackup = user.autoKeychainBackup;
          userFurnace.accountType = user.accountType!;
          userFurnace.role = user.role;

          ///Check and set new type if HOSTED (DEFAULT)
          if (userFurnace.type == NetworkType.HOSTED) {
            if (userFurnace.url != urls.forge &&
                userFurnace.url != urls.spinFurnace) {
              userFurnace.type = NetworkType.SELF_HOSTED;
            } else if (userFurnace.hostedName!.toLowerCase() ==
                IRONFORGE.toLowerCase()) {
              userFurnace.type = NetworkType.FORGE;
            }
          }

          TableUserFurnace.upsert(userFurnace);

          if (userFurnace.authServer!) {
            //update global state
            globalState.user = user;
            globalState.userFurnace = userFurnace;
            globalState.setUpdateAvailable(
                jsonResponse["latestBuild"], jsonResponse["minimumBuild"]);

            globalState.ironCoinWallet =
                IronCoinWallet.fromJson(jsonResponse["ironCoinWallet"]);

            await UserSetting.populateUserSettingsFromAPI(
                globalState.userSetting, user, false);
          } else if (userFurnace.linkedUser != globalState.user.id!) {
            UserSetting? userSetting =
                await TableUserSetting.read(userFurnace.userid!);

            if (userSetting == null) {
              LogBloc.postLog('UserSetting is null for ${userFurnace.userid!}',
                  'AuthenticationService.validateToken');
            }

            userSetting ??= UserSetting(
                username: userFurnace.username!,
                id: userFurnace.userid!,
                fontSize: 16);

            await UserSetting.populateUserSettingsFromAPI(
                userSetting, user, false);
          }

          //grab the users avatar
          AvatarService avatarService = AvatarService();
          avatarService.downloadAvatar(userFurnace, user);

          if (globalState.userSetting.submitLogs) LogBloc.post(userFurnace);

          ///either from device change or an expired key
          if (jsonResponse["userCircles"] != null) {
            List<UserCircle> userCircles =
                UserCircleCollection.fromJSON(jsonResponse, 'userCircles')
                    .userCircles;

            user.userCircles = userCircles;
          }

          return user;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return User();
        } else {
          ///All other error types
          throw Exception('Validate token failed for non auth reasons');
        }
      }
    } on TimeoutException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.validateToken: ${err.toString()}');
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.validateToken: ${err.toString()}');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      ///no reason to rethrow. The 401 check above will look for invalid tokens, as will every subsequent api call
    }

    ///load the last user still logged in
    User user = User(
        id: userFurnace.userid,
        username: userFurnace.username,
        avatar: userFurnace.avatar,
        tos: DateTime.now());
    return user;
  }

  ///function that returns the user nonce from the api
  Future<String> getNonce(UserFurnace userFurnace) async {
    String retValue = '';

    try {
      String url = userFurnace.url! + Urls.PASSWORD_NONCE;

      Device device = await globalState.getDevice();

      Map map = {
        'apikey': userFurnace.apikey,
        'username': userFurnace.username,
        'build': globalState.build,
        'type': userFurnace.type.index,
        'pushtoken': device.pushToken,
        'uuid': device.uuid,
      };

      ///the hosted property comes though login landing, but not the FurnaceManager
      if (userFurnace.type != NetworkType.FORGE ||
          userFurnace.hostedAccessCode != null) {
        map["hostedName"] = userFurnace.alias;
        map["key"] = userFurnace.hostedAccessCode;
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            //'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse['passwordNonce'] == null) {
          throw Exception('invalid network name or credentials');
        } else {
          retValue = jsonResponse['passwordNonce'];
        }
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('AuthenticationService.getNonce: ${response.statusCode}');

        // If that call was not successful, throw an error.
        throw Exception(jsonResponse['err']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('AuthenticationService.getNonce: ${err.toString()}');
      throw Exception(err);
    }

    return retValue;
  }

  Future<User> validateCredentials(
      UserFurnace userFurnace,
      Device deviceAttributes,
      String passwordHash,
      String passwordNonce,
      String password,
      String pin) async {
    try {
      Map map;
      String url;

      url = userFurnace.url! + Urls.LOGIN;

      debugPrint(url);

      Device device = await globalState.getDevice();

      map = {
        'apikey': userFurnace.apikey,
        'username': userFurnace.username,
        'build': globalState.build,
        'type': userFurnace.type.index,
        'pushtoken': device.pushToken,
        'uuid': device.uuid,
        'platform': device.platform == null || device.platform!.isNotEmpty
            ? device.platform
            : DeviceBloc.getPlatformString(),
        'model': deviceAttributes.model,
      };

      ///if the passwordHash is empty, user hasn't changed password to upgraded to hash
      if (passwordHash.isEmpty) {
        map['password'] = password;
        map['pin'] = pin;
      } else {
        map['passwordHash'] = passwordHash;
      }

      // debugPrint('username: ${userFurnace.username}');
      // debugPrint('passwordHash: $passwordHash');
      // debugPrint('apikey: ${userFurnace.apikey}');

      ///the hosted property comes though login landing, but not the FurnaceManager
      if (userFurnace.type != NetworkType.FORGE ||
          userFurnace.hostedAccessCode != null) {
        map["hostedName"] = userFurnace.alias;
        map["key"] = userFurnace.hostedAccessCode;
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            //'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      if (response.statusCode == 200) {
        if (jsonResponse['token'] == null) {
          //TODO check for password reset required
          /*
        //is there a refresh password attribute?
        if (jsonResponse['changePassword']!=null) {
          if (jsonResponse['changePassword'] == true)
            return null;
        }

       */

          throw (jsonResponse['msg']);
        }

        if (jsonResponse["officialNotification"] != null) {
          OfficialNotification notification = OfficialNotification.fromJson(
              jsonResponse["officialNotification"]);
          globalState.notification = notification;
        }

        User user = User.fromJson(jsonResponse["user"]);

        ///set network result values
        var network = jsonResponse["network"];
        userFurnace.id = network["_id"];
        userFurnace.hostedName = network['name']; //deals with case issues
        userFurnace.alias = network['name']; //deals with case issues
        userFurnace.token = jsonResponse['token'];
        userFurnace.hostedAccessCode = network['key'];
        userFurnace.userid = user.id;
        userFurnace.passwordHash = passwordHash;
        userFurnace.passwordNonce = passwordNonce;
        userFurnace.lastLogin = DateTime.now().millisecondsSinceEpoch;

        user.userFurnace = userFurnace;

        late UserSetting userSetting;

        if (userFurnace.authServer!) {
          await UserSetting.populateUserSettingsFromAPI(
              globalState.userSetting, user, false);

          userSetting = globalState.userSetting;

          globalState.user = user;
        } else if (userFurnace.linkedUser != globalState.user.id!) {
          UserSetting? nonAuthSetting = await TableUserSetting.read(user.id!);

          LogBloc.postLog('UserSetting is null for ${userFurnace.userid!}',
              'AuthenticationService.validateFurnaceCredentials');

          nonAuthSetting ??= UserSetting(
              username: userFurnace.username!, id: user.id!, fontSize: 16);
          await UserSetting.populateUserSettingsFromAPI(
              nonAuthSetting, user, false);

          userSetting = nonAuthSetting;
        }

        RatchetKey ratchetKey = await RatchetKey.getLatestUserKeyPair(user.id!);
        String backupSecret = userSetting.backupKey;

        if (ratchetKey.private.isEmpty || backupSecret.isEmpty) {
          try {
            LogBloc.insertLog('empty private key or backup secret',
                'AuthenticationService.validateFurnaceCredentials');

            String backupKey =
                await ForwardSecrecyUser.decryptBackupAndUserKeys(
                    RatchetKey.fromJson(jsonResponse["ratchetPublicKey"]),
                    RatchetIndex.fromJson(jsonResponse["backupIndex"]),
                    RatchetIndex.fromJson(jsonResponse["userIndex"]),
                    user.id!,
                    password,
                    pin);

            userSetting.backupKey = backupKey;
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }

        await ForwardSecrecyUser.getSignatureKey(userFurnace);

        if (jsonResponse['userCircles'] != null) {
          List<UserCircle> userCircles =
              UserCircleCollection.fromJSON(jsonResponse, 'userCircles')
                  .userCircles;

          user.userCircles = userCircles;
        }

        if (jsonResponse['subscriptions'] != null) {
          List<Subscription> subscriptions =
              SubscriptionCollection.fromJSON(jsonResponse).subscriptions;

          await TableSubscription.upsertSubscriptions(subscriptions);
        }
        //missing are ratcheted in the bloc
        //same with avatar download

        await connectLinkedAccount(userFurnace, jsonResponse, user);

        return user;
      } else {
        debugPrint(
            'AuthenticationService.validateFurnaceCredentials: ${response.statusCode}');

        // If that call was not successful, throw an error.
        throw Exception(jsonResponse['err']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.validateFurnaceCredentials: ${err.toString()}');
      rethrow;
    }
  }

  connectLinkedAccount(UserFurnace primaryNetwork,
      Map<String, dynamic> jsonResponse, User primaryUser) async {
    bool limited = true;
    if (globalState.user.accountType != AccountType.FREE) {
      limited = false;
    }

    if (jsonResponse.containsKey('linkedUsers')) {
      for (var object in jsonResponse["linkedUsers"]) {
        User user = User.fromJson(object);
        //user.token = jsonResponse['token'];

        UserFurnace userFurnace = UserFurnace();

        if (object['hostedFurnace'] != null) {
          Map<String, dynamic> hostedFurnace = object['hostedFurnace'];

          ///if primary is the forge, linked must be hosted, else just use the primaries type
          if (primaryNetwork.type == NetworkType.FORGE) {
            userFurnace.type = NetworkType.HOSTED;
          } else {
            userFurnace.type = primaryNetwork.type;
          }
          userFurnace.id = hostedFurnace['_id'];
          userFurnace.alias = hostedFurnace['name'];
          userFurnace.hostedName = hostedFurnace['name'];
          userFurnace.hostedAccessCode = hostedFurnace['key'];
          userFurnace.url = primaryNetwork.url;
          userFurnace.apikey = primaryNetwork.apikey;
        } else {
          userFurnace.alias = 'IronForge';
          userFurnace.id = 'IronForge';
          userFurnace.url = urls.forge;
          userFurnace.apikey = urls.forgeAPIKEY;
          userFurnace.type == NetworkType.FORGE;
        }

        userFurnace.userid = user.id;
        userFurnace.username = user.username;
        userFurnace.user = user;
        userFurnace.authServer = false;

        //create the user folder
        FileSystemService.makeUserPath(user.id);

        userFurnace.token = object['token'];
        userFurnace.avatar = user.avatar;

        userFurnace.autoKeychainBackup = user.autoKeychainBackup;
        userFurnace.connected = true;
        if (limited == true) {
          int order = jsonResponse["linkedUsers"].indexOf(object);
          if (order >= 4) {
            userFurnace.connected = false;
          }
        }

        userFurnace.authServerUserid = globalState.user.id;
        userFurnace.linkedUser = primaryUser.id;

        RatchetKey ratchetKey = await RatchetKey.getLatestUserKeyPair(user.id!);
        //String backupSecret = await SecureStorageService.readKey(
        //    KeyType.USER_KEYCHAIN_BACKUP + user.id!);

        ///use the auth backup key since this is a linked account
        String backupSecret = globalState.userSetting.backupKey;

        if (ratchetKey.private.isEmpty || backupSecret.isEmpty) {
          try {
            await ForwardSecrecyUser.decryptUserKeysFromLinkedUser(
                RatchetKey.fromJson(object["ratchetPublicKey"]),
                RatchetIndex.fromJson(object["backupIndex"]),
                RatchetIndex.fromJson(object["userIndex"]),
                user.id!,
                primaryUser.id!);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }

        if (object['userCircles'] != null) {
          List<UserCircle> userCircles =
              UserCircleCollection.fromJSON(object, 'userCircles').userCircles;

          await ForwardSecrecy.ratchetMissingServerSideKeys(
              userFurnace, user, userCircles);
        }

        //grab the users avatar
        AvatarService avatarService = AvatarService();
        avatarService.downloadAvatar(userFurnace, user);

        userFurnace.password = "";
        userFurnace.pin = "";

        userFurnace = await TableUserFurnace.upsert(userFurnace);
      }
    }
  }

  Future<FurnaceConnection?> validateLinkedAccount(
      BuildContext context, UserFurnace primary, UserFurnace linked) async {
    try {
      String url = primary.url! + Urls.VALIDATE_LINKED_ACCOUNT;

      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'apikey': primary.apikey,
        'uuid': device.uuid,
        'build': globalState.build,
        'userID': linked.userid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': primary.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);
        linked.token = jsonResponse['token'];
        await TableUserFurnace.upsert(linked);

        User user = User.fromJson(jsonResponse['user']);

        List<UserCircle> userCircles =
            UserCircleCollection.fromJSON(jsonResponse, 'userCircles')
                .userCircles;
        user.userCircles = userCircles;
        return FurnaceConnection(userFurnace: linked, user: user);
      }
    } on TimeoutException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.validateLinkedAccount: ${err.toString()}');
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'AuthenticationService.validateLinkedAccount: ${err.toString()}');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      String localizedMessage =
          NotificationLocalization.getLocalizedString(err.toString(), context);

      throw (localizedMessage);
    }

    return null;
  }
  //
  // Future<void> linkAccount(UserFurnace userFurnace, UserFurnace primary) async {
  //   try {
  //     String url = primary.url! + Urls.LINK_ACCOUNT;
  //
  //     debugPrint(url);
  //
  //     Device device = await globalState.getDevice();
  //
  //     Map map = {
  //       'apikey': primary.apikey,
  //       'uuid': device.uuid,
  //       'build': globalState.build,
  //       'primaryID': primary.userid,
  //     };
  //
  //     final response = await http.post(Uri.parse(url),
  //         headers: {
  //           'Authorization': userFurnace.token!,
  //           'Content-Type': "application/json",
  //         },
  //         body: json.encode(map));
  //
  //     if (response.statusCode == 200) {
  //       return;
  //     }
  //   } on TimeoutException catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint(
  //         'AuthenticationService.validateLinkedAccount: ${err.toString()}');
  //   } on SocketException catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint(
  //         'AuthenticationService.validateLinkedAccount: ${err.toString()}');
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //
  //     rethrow;
  //   }
  // }
}
