import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/circlelastlocalupdate.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/swipepatternattempt.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_actionrequired.dart';
import 'package:ironcirclesapp/services/cache/table_member.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_memberdevice.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_usercircleenvelope.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/invitations_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class UserCirclesAndObjects {
  List<UserCircle> userCircles = [];
  List<CircleObject> circleObjects = [];

  UserCirclesAndObjects(
      {required this.userCircles, required this.circleObjects});
}

class UserCircleService {
  AvatarService avatarService = AvatarService();

  Future<UserCircle> hide(UserFurnace userFurnace,
      UserCircleCache userCircleCache, bool hide, String passcode) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLE + 'undefined';

      Device device = await globalState.getDevice();

      Map map = {
        'prefName': userCircleCache.prefName,
        'hidden': hide ? 'true' : 'false',
        'hiddenPassphrase': passcode,
        'device': device.uuid,
        'id': userCircleCache.circle!,
      };

      if (passcode.isNotEmpty) {
        map["hiddenPassphrase"] = passcode;
      }

      if (hide) map["hiddenOpen"] = 'false';

      //map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        final response = await http.put(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.hide: $error');
      rethrow;
    }
    return UserCircle(ratchetKeys: []);
  }

  Future<UserCircle> updateClosed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, bool closed) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLECLOSED + 'undefined';

      Map map = {
        'closed': closed,
        'id': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
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

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          //debugPrint('service: ${userCircle.closed}');

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return UserCircle(ratchetKeys: []);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      } else {
        throw ("connection not detected");
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateClosed: $error');
      throw Exception(error);
    }
  }

  Future<UserCircle?> updateMuted(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    bool muted,
  ) async {
    try {
      Device device = await globalState.getDevice();
      String url = userFurnace.url! + Urls.USERCIRCLEMUTED + 'undefined';

      Map map = {
        'muted': muted,
        'id': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
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

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateMuted: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<UserCircleCache?> updateColor(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    try {
      Device device = await globalState.getDevice();

      String url =
          userFurnace.url! + Urls.USERCIRCLEBACKGROUNDCOLOR + 'undefined';

      Map map = {
        'backgroundColor': userCircleCache.backgroundColor!.value,
        'id': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
        debugPrint(url);

        map = await EncryptAPITraffic.encrypt(map);

        final response = await http.put(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          //Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (userCircleCache.background != null) {
            if (FileSystemService.isUserCircleBackgroundCached(
                userCircleCache.circlePath!, userCircleCache.background!)) {
              File delete = File(
                  FileSystemService.returnUserCircleBackgroundPath(
                      userCircleCache.circlePath!,
                      userCircleCache.background!));

              FileSystemService.safeDelete(delete);
            }

            userCircleCache.background = null;
          }

          await TableUserCircleCache.upsert(userCircleCache);

          return userCircleCache;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }

      return null;
    } catch (error, trace) {
      debugPrint(trace.toString());
      debugPrint('UserCircleService.updateColor: $error');
      rethrow;
      //throw Exception(error);
    }
  }

  Future<UserCircle?> updateEncryptedFields(UserCircleCache userCircleCache,
      UserFurnace userFurnace, DecryptArguments? args) async {
    try {
      Device device = await globalState.getDevice();
      String url = userFurnace.url! + Urls.USERCIRCLE + 'undefined';

      //debugPrint('break');

      UserCircleEnvelope userCircleEnvelope = await TableUserCircleEnvelope.get(
          userCircleCache.usercircle!, userCircleCache.user!);

      userCircleEnvelope.contents.prefName = userCircleCache.prefName!;

      ///If there is also a background change
      if (args != null) {
        userCircleEnvelope.contents.userCircleBackgroundSignature = args.mac;
        userCircleEnvelope.contents.userCircleBackgroundCrank = args.nonce;
        userCircleEnvelope.contents.userCircleBackgroundKey =
            base64UrlEncode(args.key!);
      }

      RatchetIndex ratchetIndex = await ForwardSecrecyUser.encryptUserObject(
          userFurnace.userid!, userCircleEnvelope.toJsonObject());

      Map map = {
        'setPrefName': 'true',
        'ratchetIndex': ratchetIndex,
        'id': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
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
          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          await TableUserCircleCache.setName(
              userCircle.id!,
              //userCircleCache.circleName == !,
              userCircleCache.prefName!,
              ratchetIndex.crank,
              userFurnace.pk!);

          //async ok
          TableUserCircleEnvelope.upsert(userCircleEnvelope);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      debugPrint(trace.toString());
      debugPrint('UserCircleService.updateEncryptedFields: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<UserCircle?> unguard(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    try {
      Device device = await globalState.getDevice();
      String url = userFurnace.url! + Urls.USERCIRCLE + 'undefined';

      Map map = {
        'guarded': false,
        'id': userCircleCache.circle!,
      };

      if (await Network.isConnected()) {
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

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<UserCircle?> setPin(UserCircleCache userCircleCache,
      UserFurnace userFurnace, List<int> pin) async {
    try {
      Device device = await globalState.getDevice();
      String url = userFurnace.url! + Urls.USERCIRCLE + 'undefined';

      Map map = {
        'guarded': userCircleCache.guarded == true ? 'true' : 'false',
        'id': userCircleCache.circle!,
      };

      if (userCircleCache.guardedPin != null) {
        map["guardedPin"] = pin;
        map["guardedOpen"] = 'false';
      }

      if (await Network.isConnected()) {
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
          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<UserCircle?> setLastAccessed(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    try {
      //String url = userFurnace.url! + Urls.USERCIRCLE + userCircleCache.circle!;

      String url = userFurnace.url! + Urls.USERCIRCLE_SET_LAST_ACCESSED;
      Map map = {
        'circleID': userCircleCache.circle!,
        'lastAccessed': userCircleCache.lastLocalAccess!.toUtc().toString(),
      };

      //Device device = await globalState.getDevice();
      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        if (userFurnace.token == null) {
          LogBloc.insertLog('userFurnace.token: ${userFurnace.token}',
              'UserCircleService setLastAccessed');
          return null;
        }

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<UserCircle?> updateUserCircle(UserCircle userCircle,
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    try {
      Device device = await globalState.getDevice();

      String url = userFurnace.url! + Urls.USERCIRCLE + 'undefined';

      Map map = {
        'prefName': userCircle.prefName,
        'id': userCircleCache.circle!,
      };

      if (userCircle.hidden != null) {
        map["hidden"] = userCircle.hidden == true ? 'true' : 'false';
      }

      if (userCircle.hiddenPassphrase != null) {
        map["hiddenPassphrase"] = userCircle.hiddenPassphrase;
        map["hiddenOpen"] = 'false';
      }

      if (userCircle.guarded != null) {
        map["guarded"] = userCircle.guarded == true ? 'true' : 'false';
      }

      //map["muted"] = userCircle.muted == true ? 'true' : 'false';

      if (userCircle.guardedPin != null) {
        map["guardedPin"] = userCircle.guardedPin;
        map["guardedOpen"] = 'false';
      }

      if (await Network.isConnected()) {
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

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return null;
  }

  Future<bool> leaveCircle(String circleID, UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLE + circleID;
      debugPrint(url);

      if (await Network.isConnected()) {
        final response = await http.delete(Uri.parse(url),
            headers: {'Authorization': userFurnace.token!});

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse = json.decode(response.body);

          //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);

          bool msg = jsonResponse["msg"];
          return msg;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return false;
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          return false;
        }
      }
    } catch (error, trace) {
      debugPrint(trace.toString());
      debugPrint('UserCircleService.leaveCircle: $error');

      rethrow;
    }

    return false;
  }

  Future<UserCircle?> fetchUserCircle(
      String circleID, UserFurnace userFurnace) async {
    // Map body;

    try {
      String url = userFurnace.url! + Urls.USERCIRCLE;

      if (await Network.isConnected()) {
        Device device = await globalState.getDevice();
        Map map = {
          'uuid': device.uuid,
          'circleID': circleID,
        };
        map = await EncryptAPITraffic.encrypt(map);

        debugPrint(url);

        var client = RetryClient(http.Client(), retries: RETRIES.HTTP_RETRY);

        final response = await client.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          UserCircle userCircle =
              UserCircle.fromJson(jsonResponse["usercircle"]);

          await TableUserCircleCache.restoreEncrypted(userCircle);

          return userCircle;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return null;
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          return null;
        }
      } else
        throw ("Connection not detected");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService: fetchUserCircle: $error');
      return null;
    }
  }

  Future<UserCirclesAndObjects> fetchUserCircles(
      UserFurnace userFurnace,
      List<String?>? openGuarded,
      List<CircleLastLocalUpdate> circleLastUpdates) async {
    // Map body;

    try {
      ///CO-REMOVE
      //return UserCirclesAndObjects(userCircles: [], circleObjects: []);

      if (userFurnace.url == null) throw ("url is null");

      String url = userFurnace.url! +
          Urls.USERCIRCLE_BY_USERID; // + userFurnace.userid!;

      openGuarded ??= [];

      Device device = await globalState.getDevice();

      if (await Network.isConnected()) {
        debugPrint('$url ${userFurnace.userid}: ${userFurnace.username}');

        Map map = {
          'userid': userFurnace.userid!,
          'deviceid': device.uuid,
          //'openguarded': openGuarded.toString(),
          //'circlelastupdates': circleLastUpdates,
        };

        if (openGuarded.isNotEmpty) {
          map["openguarded"] = openGuarded.toString();
        }

        if (circleLastUpdates.isNotEmpty) {
          map["circlelastupdates"] = circleLastUpdates;
        }

        map = await EncryptAPITraffic.encrypt(map);

        var client = RetryClient(http.Client(), retries: 3);

        final response = await client.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          UserCircleCollection userCircleCollection =
              UserCircleCollection.fromJSON(jsonResponse, "usercircles");

          List<CircleObject> circleObjects = [];
          /*CircleObjectCollection circleObjectCollection =
              CircleObjectCollection.fromJSON(jsonResponse,
                  key: "circleobjects");

           */

          for (var individual in jsonResponse['circleobjects']) {
            try {
              if (individual.containsKey(
                  "ratchetIndexes") /*&& individual["type"] != 'deleted'*/) {
                if (individual["type"] != CircleObjectType.SYSTEMMESSAGE &&
                    individual["type"] != CircleObjectType.CIRCLEVOTE) {
                  if (individual["ratchetIndexes"].length == 0) continue;

                  if (individual["ratchetIndexes"][0] == null) continue;
                }
              }

              circleObjects.add(CircleObject.fromJson(individual));
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
              debugPrint('refresh crash');
              //rethrow;
            }
          }

          InvitationCollection invitationCollection =
              InvitationCollection.fromJSON(jsonResponse, "invitations");

          InvitationsService.decryptInvitationCollection(
              userFurnace, invitationCollection);

          ActionRequiredCollection actionRequiredCollection =
              ActionRequiredCollection.fromJSON(jsonResponse, "actionrequired");
          try {
            await TableActionRequiredCache.upsertCollection(
                actionRequiredCollection, userFurnace.userid);
            // userFurnace.actionsRequired =
            // actionRequiredCollection.actionRequiredObjects.length;
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
                'UserCircleService.fetchUserCircles - actionRequired Upsert: $err');
          }

          User updatedUser = User.fromJson(jsonResponse["user"]);

          try {
            ///see if the user avatar is different than the furnace
            bool changed = false;

            if (userFurnace.avatar == null && updatedUser.avatar != null) {
              changed = true;
            } else if (updatedUser.avatar != null &&
                (updatedUser.avatar!.name != userFurnace.avatar!.name ||
                    userFurnace.avatar!.size != updatedUser.avatar!.size)) {
              changed = true;
            }

            if (changed) {
              userFurnace.avatar = updatedUser.avatar;
              await TableUserFurnace.upsert(userFurnace);
            }
          } catch (error, trace) {
            LogBloc.insertError(error, trace);
          }

          UserCollection userCollection =
              UserCollection.fromJSON(jsonResponse, "members");
          MemberCircleCollection memberCircleCollection =
              MemberCircleCollection.fromJSON(jsonResponse, "memberCircles");
          UserCollection connections =
              UserCollection.fromJSON(jsonResponse, "userConnections");

          await _updateMembers(
              userFurnace,
              userCollection,
              memberCircleCollection,
              connections,
              updatedUser.blockedList!); //async is fine

          ///update user
          if (userFurnace.authServer != null) {
            if (userFurnace.authServer!) {
              if (userCircleCollection.userCircles.isNotEmpty) {
                //User user = userCircleCollection.userCircles[0].user!;

                UserSetting.populateUserSettingsFromAPI(
                    globalState.userSetting, updatedUser, false);

                globalState.user = updatedUser;
              }

              if (jsonResponse.containsKey("latestBuild"))
                globalState.setUpdateAvailable(jsonResponse["latestBuild"]);
            }
          }

          ///update hosted network fields
          HostedFurnace? hostedFurnace;

          if (jsonResponse["user"].containsKey("hostedFurnace")) {
            hostedFurnace =
                HostedFurnace.fromJson(jsonResponse["user"]["hostedFurnace"]);
          }

          await _updateHostedNetworkFields(
              userFurnace, updatedUser, hostedFurnace);

          UserCirclesAndObjects userCirclesAndObjects = UserCirclesAndObjects(
              userCircles: userCircleCollection.userCircles,
              circleObjects: circleObjects);

          if (userFurnace.authServer != null &&
              userFurnace.authServer! &&
              jsonResponse["coins"] != null) {
            globalState.ironCoinWallet.balance =
                jsonResponse["coins"].toDouble();
          }

          return userCirclesAndObjects;
        } else if (response.statusCode == 401) {
          debugPrint(response.reasonPhrase);
          await navService.logout(userFurnace);
        } else {
          debugPrint(response.statusCode.toString());
          debugPrint(response.reasonPhrase);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.fetchUserCircles: $error');
    }

    return UserCirclesAndObjects(userCircles: [], circleObjects: []);
  }

  Future<List<UserCircle>> fetchHistory(
    UserFurnace userFurnace,
  ) async {
    try {
      if (userFurnace.url == null) throw ("url is null");

      Device device = await globalState.getDevice();

      String url =
          userFurnace.url! + Urls.USERCIRCLE_HISTORY; // + userFurnace.userid!;

      if (await Network.isConnected()) {
        debugPrint('$url ${userFurnace.userid}: ${userFurnace.username}');

        Map map = {
          'userid': userFurnace.userid!,
        };

        map = await EncryptAPITraffic.encrypt(map);

        var client = RetryClient(http.Client(), retries: 3);

        final response = await client.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          User updatedUser = User.fromJson(jsonResponse["user"]);

          UserCircleCollection userCircleCollection =
              UserCircleCollection.fromJSON(jsonResponse, "usercircles");

          UserCollection userCollection =
              UserCollection.fromJSON(jsonResponse, "members");
          MemberCircleCollection memberCircleCollection =
              MemberCircleCollection.fromJSON(jsonResponse, "memberCircles");
          UserCollection connections =
              UserCollection.fromJSON(jsonResponse, "userConnections");

          await _updateMembers(
              userFurnace,
              userCollection,
              memberCircleCollection,
              connections,
              updatedUser.blockedList!); //async is fine

          return userCircleCollection.userCircles;
        } else if (response.statusCode == 401) {
          debugPrint(response.reasonPhrase);
          await navService.logout(userFurnace);
        } else {
          debugPrint(response.statusCode.toString());
          debugPrint(response.reasonPhrase);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.fetchUserCircles: $error');
    }

    return [];
  }

  Future<List<UserCircle>> validateHiddenPassphrase(
      String hiddenPassphrase, UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLE_HIDDENCIRCLE;

      if (await Network.isConnected()) {
        debugPrint(url);

        Device device = await globalState.getDevice();

        debugPrint('PUSHTOKEN: ${device.pushToken}');

        Map map = {
          'passphrase': hiddenPassphrase,
          'device': device.uuid,
        };

        map = await EncryptAPITraffic.encrypt(map);

        var client =
            RetryClient(http.Client(), retries: RETRIES.MAX_HIDDEN_RETRIES);

        final response = await client.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          //debugPrint(jsonResponse["success"]);

          if (jsonResponse["found"] == false) {
            //return null;
            throw ('no match');
          } else {
            UserCircleCollection userCircleCollection =
                UserCircleCollection.fromJSON(jsonResponse, "usercircles");

            return userCircleCollection.userCircles;
          }
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error) {
      //LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.validateHiddenPassphrase: $error');
      rethrow;
    }

    return [];
  }

  setTempOpen(UserFurnace userFurnace, String hiddenPassphrase,
      List<UserCircleCache> list) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLE_TEMPOPEN;

      List<String> ids = [];

      Device device = await globalState.getDevice();

      for (UserCircleCache userCircleCache in list) {
        ids.add(userCircleCache.usercircle!);
      }

      if (await Network.isConnected()) {
        debugPrint(url);

        Map map = {
          'userid': userFurnace.userid!,
          'passphrase': hiddenPassphrase,
          'device': device.uuid,
          'usercircles': ids,

          //'openguarded': openGuarded.toString(),
          //'circlelastupdates': circleLastUpdates,
        };


        map = await EncryptAPITraffic.encrypt(map);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.validateHiddenPassphrase: $error');
      rethrow;
    }

    return;
  }

  Future<bool> closeOpenHidden(UserFurnace userFurnace) async {
    try {
      String url = '${userFurnace.url!}${Urls.USERCIRCLECLOSEOPENHIDDEN}a';

      if (await Network.isConnected()) {
        debugPrint(url);

        Device device = await globalState.getDevice();

        Map map = {
          'device': device.uuid,
        };

        var client =
            RetryClient(http.Client(), retries: RETRIES.MAX_HIDDEN_RETRIES);

        map = await EncryptAPITraffic.encrypt(map, device: device);

        final response = await client.put(
            //final response = await http.put(
            Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          return true;
        } else if (response.statusCode == 401) {
          debugPrint("${response.statusCode}: ${response.body}");
          //intentionally not redirecting user to login
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return false;
  }

  Future<void> _updateMembers(
      UserFurnace userFurnace,
      UserCollection members,
      MemberCircleCollection memberCircleCollection,
      UserCollection connections,
      List<User> blockedList) async {
    if (members.users.isNotEmpty) {
      await TableMember.upsertCollection(userFurnace.userid!, userFurnace.pk!,
          members, connections, globalState, blockedList);

      TableMemberDevice.upsertCollection(userFurnace.userid!, members.users);

      avatarService.validateCurrentAvatarsByUser(
          userFurnace, members); //this is async on purpose
    }
    await TableMemberCircle.upsertCollection(
        userFurnace.userid!, memberCircleCollection);
  }

  _updateHostedNetworkFields(
      UserFurnace userFurnace, User user, HostedFurnace? hostedFurnace) async {
    bool changed = false;

    ///this is a fix for the role not being updated when creating a linked network
    if (userFurnace.role != user.role) {
      changed = true;
      userFurnace.role = user.role;
    }

    if (hostedFurnace != null) {
      ///RBR
      // if (userFurnace.type == NetworkType.FORGE){
      //   userFurnace.type = NetworkType.HOSTED;
      //   changed = true;
      // }

      if (hostedFurnace.discoverable != userFurnace.discoverable) {
        userFurnace.discoverable = hostedFurnace.discoverable;
        changed = true;
      }
      if (hostedFurnace.memberAutonomy != userFurnace.memberAutonomy) {
        userFurnace.memberAutonomy = hostedFurnace.memberAutonomy;
        changed = true;
      }
      if (hostedFurnace.name != userFurnace.alias ||
          hostedFurnace.name != userFurnace.hostedName) {
        userFurnace.alias = hostedFurnace.name;
        userFurnace.hostedName = hostedFurnace.name;
        changed = true;
      }
      if (hostedFurnace.key != userFurnace.hostedAccessCode) {
        userFurnace.hostedAccessCode = hostedFurnace.key;
        changed = true;
      }
      if (hostedFurnace.adultOnly != userFurnace.adultOnly) {
        userFurnace.adultOnly = hostedFurnace.adultOnly;
        changed = true;
      }
      if (hostedFurnace.description != userFurnace.description) {
        userFurnace.description = hostedFurnace.description;
        changed = true;
      }
      if (hostedFurnace.link != userFurnace.link) {
        userFurnace.link = hostedFurnace.link;
        changed = true;
      }
      if (hostedFurnace.enableWall != userFurnace.enableWall) {
        userFurnace.enableWall = hostedFurnace.enableWall;
        changed = true;
      }

      if (changed) {
        await TableUserFurnace.upsert(userFurnace);
      }
    }
  }

  /*
  _updateHostedNetworkFields(
      UserFurnace userFurnace, List<dynamic> userCircles) async {
    for (var userCircle in userCircles) {
      ///only need to process one
      if (userCircle['user']['hostedFurnace'] != null) {
        bool changed = false;

        if (userCircle['user']['hostedFurnace']['discoverable'] !=
            userFurnace.discoverable) {
          userFurnace.discoverable =
              userCircle['user']['hostedFurnace']['discoverable'];
          changed = true;
        }
        if (userCircle['user']['hostedFurnace']["name"] != userFurnace.alias ||
            userCircle['user']['hostedFurnace']["name"] !=
                userFurnace.hostedName) {
          userFurnace.alias = userCircle['user']['hostedFurnace']["name"];
          userFurnace.hostedName = userCircle['user']['hostedFurnace']["name"];
          changed = true;
        }
        if (userCircle['user']['hostedFurnace']["key"] !=
            userFurnace.hostedAccessCode) {
          userFurnace.hostedAccessCode =
              userCircle['user']['hostedFurnace']["key"];
          changed = true;
        }
        if (userCircle['user']['hostedFurnace']['adultOnly'] !=
            userFurnace.adultOnly) {
          userFurnace.adultOnly =
              userCircle['user']['hostedFurnace']['adultOnly'];
          changed = true;
        }
        if (userCircle['user']['hostedFurnace']['description'] !=
            userFurnace.description) {
          userFurnace.description =
              userCircle['user']['hostedFurnace']['description'];
          changed = true;
        }
        if (userCircle['user']['hostedFurnace']['enableWall'] != null &&
            userCircle['user']['hostedFurnace']['enableWall'] !=
                userFurnace.enableWall) {
          userFurnace.enableWall =
              userCircle['user']['hostedFurnace']['enableWall'];
          changed = true;
        }

        if (changed) {
          await TableUserFurnace.upsert(userFurnace);
        }
      }
      break;
    }

    return;
  }*/

  Future<bool> saveSwipePatternAttempt(
      UserFurnace userFurnace, String? circle) async {
    try {
      String url = '${userFurnace.url!}${Urls.USERCIRCLE_SWIPE_ATTEMPT}';

      if (await Network.isConnected()) {
        debugPrint(url);

        Device device = await globalState.getDevice();

        Map map = {
          'circle': circle,
          'user': globalState.user.id,
          'device': device.id,
          'attemptDate': DateTime.now().toIso8601String(),
        };

        map = await EncryptAPITraffic.encrypt(map, device: device);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));
        if (response.statusCode == 200) {
          return true;
        } else if (response.statusCode == 401) {
          debugPrint("${response.statusCode}: ${response.body}");
          //intentionally not redirecting user to login
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('UserCircleService.updateUserCircle: $error');
      //throw Exception(error);
    }

    return false;
  }

  Future<List<SwipePatternAttempt>?> fetchSwipePatternAttempts(
      UserFurnace userFurnace, String? user) async {
    String url = userFurnace.url! + Urls.USERCIRCLE_SWIPE_ATTEMPTS;

    if (await Network.isConnected()) {
      debugPrint(url);

      Map map = {
        'userID': user!,
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

        SwipePatternAttemptCollection swipePatternAttemptCollection =
            SwipePatternAttemptCollection.fromJSON(
                jsonResponse, "swipePatternAttempts");

        return swipePatternAttemptCollection.swipePatternAttempts;
      } else if (response.statusCode == 401) {
        debugPrint("${response.statusCode}: ${response.body}");
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(response.body);
      }
    }
    return null;
  }
}
