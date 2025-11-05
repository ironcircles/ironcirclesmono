import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/officialnotification.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/services/cache/table_actionrequired.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class UserService {

   setConnected(UserFurnace userFurnace, Member member, bool connected) async {
    String url = userFurnace.url! + Urls.USER_CONNECTED;
    debugPrint(url);

    Map map = {
      'connected': connected,
      'memberID': member.memberID,
    };

    try {
      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));



      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        return;
      } else if (response.statusCode == 401) {
        LogBloc.insertLog("${response.statusCode}: ${response.body}",
            'UserService.restClearPatternFlag');
        throw Exception('Something went wrong');
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        if (jsonResponse!['err'] != null)
          throw Exception(jsonResponse['err']);
        else
          throw Exception('Something went wrong');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.restClearPatternFlag: $err');

      rethrow;
    }
  }


  unsetPin() {
    globalState.userSetting.inactivePatternPinString();
  }

  setPin(List<int> _pin, user) {
    globalState.userSetting.setPatternPinString(_pin);
  }
  //
  // Future<void> restClearPatternFlag(
  //     UserFurnace userFurnace) async {
  //   String url = userFurnace.url! + Urls.USER_CLEAR_PATTERN_FLAG;
  //   debugPrint(url);
  //
  //   Map map = {
  //     'userID': userFurnace.userid!,
  //   };
  //
  //   try {
  //     final response = await http.post(Uri.parse(url),
  //         headers: {
  //           'Authorization': userFurnace.token!,
  //           'Content-Type': "application/json",
  //         },
  //         body: json.encode(map));
  //
  //     Map<String, dynamic>? jsonResponse = json.decode(response.body);
  //
  //     if (response.statusCode == 200) {
  //       return;
  //     } else if (response.statusCode == 401) {
  //       LogBloc.insertLog("${response.statusCode}: ${response.body}",
  //           'UserService.restClearPatternFlag');
  //       throw Exception('Something went wrong');
  //     } else {
  //       debugPrint("${response.statusCode}: ${response.body}");
  //
  //       if (jsonResponse!['err'] != null)
  //         throw Exception(jsonResponse['err']);
  //       else
  //         throw Exception('Something went wrong');
  //     }
  //   } catch (err, trace) {
  //     LogBloc.insertError(err, trace);
  //     debugPrint('UserService.restClearPatternFlag: $err');
  //
  //     rethrow;
  //   }
  // }

  Future<void> updateUserIdentityKey(
      UserFurnace userFurnace, RatchetKey signatureKey) async {
    String url = userFurnace.url! + Urls.USER_IDENTITY;
    debugPrint(url);

    var device = await globalState.getDevice();

    Map map = {
      'userID': userFurnace.userid!,
      'uuid': device.uuid,
      'signatureKey': signatureKey.public!
    };

    try {

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        throw Exception(jsonResponse['msg']);
      } else if (response.statusCode == 401) {
        LogBloc.insertLog("${response.statusCode}: ${response.body}",
            'UserService.updateUserIdentityKey');
        throw Exception('Something went wrong');
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        if (jsonResponse!['err'] != null)
          throw Exception(jsonResponse['err']);
        else
          throw Exception('Something went wrong');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      rethrow;
    }
  }

  /*Future<bool> isUserNameReserved(String username) async {
    String url = urls.forge + Urls.USER_USERNAME_RESERVED;
    debugPrint(url);

    Map map = {'username': username, 'apikey': urls.forgeAPIKEY};

    try {
      final response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return false;
      } else if (response.statusCode == 401) {
        LogBloc.insertLog("${response.statusCode}: ${response.body}",
            'UserService.isUserNameReserved');
        throw Exception('Something went wrong');
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        if (jsonResponse!['err'] != null)
          throw Exception(jsonResponse['err']);
        else
          throw Exception('Something went wrong');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.deleteAccount: $err');

      rethrow;
    }
  }*/

  Future<void> dismissOfficialNotification(UserFurnace userFurnace, OfficialNotification notification) async {

    String url = userFurnace.url! + Urls.USER_DISMISS_NOTIFICATION;
    debugPrint(url);
    Map map = {
      'userID': userFurnace.userid,
      'notification': notification,
    };

    try {

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
          body: json.encode(map));

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        return;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse!['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.dismissOfficialNotification');
    }
  }

  Future<List<User>> prepDelete(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.USER_DELETE_PREP;
    debugPrint(url);

    List<User> retValue = [];

    if (userFurnace.token == null){
      return [];
    }

    try {

      Map map = {
        'userID': userFurnace.userid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map)
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse == null) throw ('failed to delete account');

        if (jsonResponse["members"] != null)
          retValue = UserCollection.fromJSON(jsonResponse, "members").users;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {

        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        if (jsonResponse!['msg'] != null)
          throw Exception(jsonResponse['msg']);
        else
          throw Exception('failed to delete account');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.deleteAccount: $err');

      rethrow;
    }

    return retValue;
  }

  Future<void> deleteAccount(
      UserFurnace userFurnace, String? transferUserID) async {
    String url = userFurnace.url! + Urls.USER_DELETE_ACCOUNT;
    debugPrint(url);

    try {
      Map map = {'userID': userFurnace.userid};

      if (transferUserID != null) map["transferUserID"] = transferUserID;

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));



      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        if (jsonResponse!['msg'] != null)
          throw Exception(jsonResponse['msg']);
        else
          throw Exception('failed to delete account');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.deleteAccount: $err');

      rethrow;
    }

    return;
  }

  Future<void> acceptTOS(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.ACCEPT_TOS + 'undefined';
    debugPrint(url);

    Map map = {
      'userID': userFurnace.userid,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },  body: json.encode(map)
    );



    if (response.statusCode == 200) {
      // Map<String, dynamic> jsonResponse =
      // await EncryptAPITraffic.decryptJson(response.body);

    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return;
  }

  Future<bool> enablePasswordBeforeChange(
      UserFurnace userFurnace, bool enabled) async {
    bool success = false;

    String url = userFurnace.url! + Urls.UPDATEUSER + 'undefined';

    Map map = {"userID": userFurnace.userid! , "passwordBeforeChange": enabled};

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      // Map<String, dynamic> jsonResponse =
      // await EncryptAPITraffic.decryptJson(response.body);

      if (userFurnace.authServer!) {
        globalState.user.passwordBeforeChange = enabled;
      }

      success = true;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return success;
  }

  Future<bool> update(String username, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.UPDATEUSER + 'undefined';

    bool retValue = false;

    Map map = Map();

    if (userFurnace.username != username) {
      map['username'] = username;

      if (globalState.user.id != null) map['authUserID'] = globalState.user.id!;
    }

    if (userFurnace.hostedAccessCode != null) {
      map['hosted'] = true;
      //map['hosted'] = true;
    }

    if (map.isEmpty) return retValue;

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));


    if (response.statusCode == 200) {

      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      var oldUsername = userFurnace.username!;

      username = jsonResponse!["username"];

      if (userFurnace.authServer!) {
        globalState.user.username = username;
        globalState.userFurnace!.username = username;
      }

      userFurnace.username = username;
      await TableUserFurnace.upsert(userFurnace);

      if (jsonResponse['linkedUsers'] != null) {
        List<User> linkedUsers =
            UserCollection.fromJSON(jsonResponse, 'linkedUsers').users;

        List<UserFurnace> linkedNetworks =
            await TableUserFurnace.readLinkedForUser(userFurnace.userid!);

        for (UserFurnace linkedNetwork in linkedNetworks) {
          if (linkedNetwork.username != oldUsername) {
            continue;
          }

          User user = linkedUsers.firstWhere(
              (element) => element.id == linkedNetwork.userid!, orElse: () {
            return User();
          });

          if (user.username != null) {
            linkedNetwork.username = user.username;
            TableUserFurnace.upsert(linkedNetwork);
          }
        }
      }

      retValue = true;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return retValue;
  }

  Future<bool> reserveUsername(UserFurnace userFurnace, bool reserved) async {
    String url = userFurnace.url! + Urls.USER_RESERVE_USERNAME;

    bool retValue = false;

    Map map = {"reserved": reserved};

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      // Map<String, dynamic> jsonResponse =
      // await EncryptAPITraffic.decryptJson(response.body);

      retValue = true;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return retValue;
  }

  Future<UserHelper?> fetchPasswordHelpers(
      UserFurnace userFurnace, String userID) async {
    String url = userFurnace.url! + Urls.PASSWORDHELPERS_GET ;
    debugPrint(url);
    UserHelper? passwordHelper;

    Map map = {
      'userID': userID,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map)
    );

    //Map<String, dynamic>? jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {

      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      passwordHelper = UserHelper(
          helpers: jsonResponse!['passwordhelpers'] == null
              ? null
              : UserCollection.fromJSON(jsonResponse, 'passwordhelpers').users,
          members: jsonResponse['members'] == null
              ? null
              : UserCollection.fromJSON(jsonResponse, 'members').users);

      if (passwordHelper.helpers != null)
        passwordHelper.helpers!.sort((a, b) =>
            a.username!.toLowerCase().compareTo(b.username!.toLowerCase()));
      else
        passwordHelper.helpers = [];

      if (passwordHelper.members != null)
        passwordHelper.members!.sort((a, b) =>
            a.username!.toLowerCase().compareTo(b.username!.toLowerCase()));
      else
        passwordHelper.members = [];

      return passwordHelper;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return passwordHelper;
  }

  Future<bool> updatePasswordHelpers(UserFurnace userFurnace,
      UserHelper passwordHelper, List<RatchetIndex> ratchetIndexes) async {
    String url = userFurnace.url! + Urls.PASSWORDHELPERS_POST;

    bool retValue = false;

    try {
      Map map = {
        "passwordHelpers": passwordHelper.helpers,
        'ratchetIndexes': ratchetIndexes,
        'build': globalState.build,
      };

      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        await TableActionRequiredCache.deleteByActionType(
            userFurnace.userid, ActionRequiredAlertType.SETUP_PASSWORD_ASSIST);

        ActionRequiredCollection actionRequiredCollection =
            ActionRequiredCollection.fromJSON(jsonResponse!, "actionrequired");
        TableActionRequiredCache.upsertCollection(
            actionRequiredCollection, userFurnace.userid);
        userFurnace.actionsRequired =
            actionRequiredCollection.actionRequiredObjects.length;
        await TableUserFurnace.upsert(userFurnace);

        globalState.user.accountRecovery = true;
        globalState.userSetting.setAccountRecovery(true);

        retValue = true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.updatePasswordHelpers: $err');

      rethrow;
    }

    return retValue;
  }

  Future<bool> updateRecoveryRatchetIndex(
      UserFurnace userFurnace, RatchetIndex ratchetIndex) async {
    String url = userFurnace.url! + Urls.USER_RECOVERYINDEX;

    bool retValue = false;

    try {
      Map map = {
        'ratchetIndex': ratchetIndex,
      };

      debugPrint(url);

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

        await TableActionRequiredCache.deleteByActionType(
            userFurnace.userid, ActionRequiredAlertType.SETUP_PASSWORD_ASSIST);

        ActionRequiredCollection actionRequiredCollection =
            ActionRequiredCollection.fromJSON(jsonResponse!, "actionrequired");
        TableActionRequiredCache.upsertCollection(
            actionRequiredCollection, userFurnace.userid);
        userFurnace.actionsRequired =
            actionRequiredCollection.actionRequiredObjects.length;
        await TableUserFurnace.upsert(userFurnace);

        globalState.user.accountRecovery = true;
        globalState.userSetting.setAccountRecovery(true);

        retValue = true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);


        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.updatePasswordHelpers: $err');

      rethrow;
    }

    return retValue;
  }

  Future<UserHelper?> fetchRemoteWipeHelpers(
      UserFurnace userFurnace, String userID) async {
    String url = userFurnace.url! + Urls.GETREMOTEWIPEHELPERS;
    debugPrint(url);
    UserHelper? remoteWipeHelper;

    Map map = {
      'userID': userID,
    };


    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
      body: json.encode(map)
    );



    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      remoteWipeHelper = UserHelper(
          helpers: jsonResponse!['helpers'] == null
              ? null
              : UserCollection.fromJSON(jsonResponse, 'helpers').users,
          members: jsonResponse['members'] == null
              ? null
              : UserCollection.fromJSON(jsonResponse, 'members').users);

      if (remoteWipeHelper.helpers != null &&
          remoteWipeHelper.helpers!.isNotEmpty)
        remoteWipeHelper.helpers!.sort((a, b) =>
            a.username!.toLowerCase().compareTo(b.username!.toLowerCase()));
      else
        remoteWipeHelper.helpers = [];

      if (remoteWipeHelper.members != null)
        remoteWipeHelper.members!.sort((a, b) =>
            a.username!.toLowerCase().compareTo(b.username!.toLowerCase()));
      else
        remoteWipeHelper.members = [];

      return remoteWipeHelper;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      debugPrint("${response.statusCode}: ${response.body}");

      throw Exception(jsonResponse!['msg']);
    }

    return remoteWipeHelper;
  }

  Future<bool> updateRemoteWipeHelpers(
      UserFurnace userFurnace, UserHelper userHelper) async {
    String url = userFurnace.url! + Urls.UPDATEREMOTEWIPEHELPERS;

    bool retValue = false;

    try {
      Map map = {
        "helpers": userHelper.helpers,
        'build': globalState.build,
      };

      debugPrint(url);

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      Map<String, dynamic>? jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        retValue = true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.updatePasswordHelpers: $err');

      rethrow;
    }

    return retValue;
  }

  Future<List<UserCircle>?> getTempPasscodeAvailable(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    String url =
        userFurnace.url! + Urls.CIRCLEMEMBERS_GET;
    debugPrint(url);

    Map map = {
      'circleID': userCircleCache.circle!,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map)
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      UserCircleCollection userCircleCollection =
          UserCircleCollection.fromJSON(jsonResponse, "usercircles");

      return userCircleCollection.userCircles;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return null;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<UserCircle>?> getMembershipList(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    String url =
        userFurnace.url! + Urls.CIRCLEMEMBERS_GET + userCircleCache.circle!;
    debugPrint(url);

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      UserCircleCollection userCircleCollection =
          UserCircleCollection.fromJSON(jsonResponse, "usercircles");

      return userCircleCollection.userCircles;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    return null;
  }

  Future<bool> updateBlockStatus(UserFurnace userFurnace, User member, bool status) async {
    String url = userFurnace.url! + Urls.USER_UPDATE_BLOCK_STATUS;
    try {

      debugPrint(url);

      Map map = {
        "userID": userFurnace.userid,
        "memberID": member.id,
        "status": status,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(response.body);
      }

    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("UserService.updateBlockStatus: $err");
    }
    return false;
  }

  Future<bool> keysExported(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.USER_KEYS_EXPORTED;

    bool retValue = false;

    try {
      debugPrint(url);

      Map map = {
        "userID": userFurnace.userid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
      );


      if (response.statusCode == 200) {

        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        await TableActionRequiredCache.deleteByActionType(
            userFurnace.userid, ActionRequiredAlertType.EXPORT_KEYS);

        ActionRequiredCollection actionRequiredCollection =
            ActionRequiredCollection.fromJSON(jsonResponse!, "actionrequired");
        TableActionRequiredCache.upsertCollection(
            actionRequiredCollection, userFurnace.userid);
        userFurnace.actionsRequired =
            actionRequiredCollection.actionRequiredObjects.length;
        await TableUserFurnace.upsert(userFurnace);

        retValue = true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);


        debugPrint("${response.statusCode}: ${response.body}");

        throw Exception(jsonResponse!['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('UserService.keysExported: $err');

      rethrow;
    }

    return retValue;
  }
}
