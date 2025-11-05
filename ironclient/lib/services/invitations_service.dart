import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/services/actionneeded_service.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/member_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:uuid/uuid.dart';

class InvitationsService {
  Future<bool> cancel(UserFurnace userFurnace, Invitation invitation) async {
    // List<Invitation> invitations;

    try {
      String url = userFurnace.url! + Urls.INVITATIONS + 'undefined';

      debugPrint(url);

      Map map = {
        'invitationID': invitation.id!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.delete(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);
        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.cancel: $err');
      throw Exception(err);
    }

    return false;
  }

  Future<bool> cancelDM(
      UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      String url = userFurnace.url! + Urls.INVITATIONS_CANCEL_DM;

      debugPrint(url);

      Map map = {
        'userCircleCacheID': userCircleCache.usercircle!,
      };

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

        await TableUserCircleCache.delete(userCircleCache);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.cancel: $err');
      throw Exception(err);
    }

    return false;
  }

  Future<bool> decline(Invitation invitation) async {
    // List<Invitation> invitations;

    //bool retValue = false;

    try {
      String url =
          invitation.userFurnace.url! + Urls.INVITATIONS_DECLINE + 'undefined';

      debugPrint(url);

      Map map = {
        'invitationID': invitation.id!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.delete(Uri.parse(url),
          headers: {
            'Authorization': invitation.userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse!["invitationcount"] != null) {
          invitation.userFurnace.invitations = jsonResponse["invitationcount"];
          await TableUserFurnace.upsert(invitation.userFurnace);
        }

        ///delete the invitation from the cache
        await TableInvitation.delete(invitation.id!);
      } else if (response.statusCode == 401) {
        await navService.logout(invitation.userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.decline: $err');
    }

    return true;
  }

  Future<bool> accept(
      UserCircleBloc userCircleBloc, Invitation invitation) async {
    // List<Invitation> invitations;

    bool retValue = false;

    try {
      String url =
          invitation.userFurnace.url! + Urls.INVITATIONS_ACCEPT + 'undefined';

      debugPrint(url);

      //get a keypair to use
      RatchetKey ratchetKey = await ForwardSecrecy.generateKeyPair(
          invitation.userFurnace.userid!, '');

      String tempPrivate = ratchetKey.private;
      Device device = await globalState.getDevice();

      Map map = {
        'ratchetPublicKey':
            ratchetKey.removePrivateKey(), //do not include private key
        'device': device.uuid,
        'invitationID': invitation.id!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': invitation.userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      //Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {

        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        ratchetKey.private = tempPrivate;
        await RatchetKey.saveReceiverKeyPair(ratchetKey, jsonResponse["id"]);

        ///update the count
        int? invyCount = jsonResponse["invitationcount"];
        if (invyCount != null) {
          invitation.userFurnace.invitations = jsonResponse["invitationcount"];
          await TableUserFurnace.upsert(invitation.userFurnace);
        }

        try {
          ///save the usercircle
          if (jsonResponse.containsKey('usercircle')) {
            UserCircle userCircle =
                UserCircle.fromJson(jsonResponse['usercircle']);

            UserCircleCache? userCircleCache =
                await TableUserCircleCache.updateUserCircleCache(
              userCircle,
              invitation.userFurnace,
            );

            ///decrypt the name start the background download
            if (userCircleCache != null) {
              if (jsonResponse.containsKey('circleObject')) {
                CircleObject circleObject =
                    CircleObject.fromJson(jsonResponse['circleObject']);

                ///cache the user added message
                CircleObjectBloc(
                        globalEventBloc: userCircleBloc.globalEventBloc)
                    .updateCache(invitation.userFurnace, userCircle.circle!.id!,
                        [circleObject], true);
              }

              userCircleBloc.processUserCircleObject(invitation.userFurnace,
                  userCircle, userCircleCache, true, false);
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }

        ///delete the invitation from the cache
        await TableInvitation.delete(invitation.id!);

        retValue = true;

        return retValue;
      } else if (response.statusCode == 401) {
        await navService.logout(invitation.userFurnace);

        return false;
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.accept: $err');
      rethrow;
    }

    // return retValue;
  }

  Future<void> updateInvitationCount(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.INVITATIONS_GETCOUNT;

      debugPrint(url);

      Map map = {
        'userID': userFurnace.userid!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse!["invitationcount"] != null) {
          userFurnace.invitations = jsonResponse["invitationcount"];
          await TableUserFurnace.upsert(userFurnace);
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.updateInvitationCount: $err');
    }
    return;
  }

  static decryptInvitationCollection(UserFurnace userFurnace,
      InvitationCollection invitationCollection) async {
    try {
      List<Invitation> existing =
          await TableInvitation.readForUser(userFurnace.userid!);

      List<Invitation> deleted = [];

      //Remove any action required no longer on the server

      for (Invitation object in existing) {
        bool found = false;

        for (Invitation newObject in invitationCollection.invitations) {
          if (object.id == newObject.id) {
            found = true;
            break;
          }
        }

        if (!found) {
          TableInvitation.delete(object.id!);
          deleted.add(object);
        } //async should be ok
      }

      //remove them from the list
      for (Invitation object in deleted) {
        existing.removeWhere((element) => element.id == object.id);
      }

      //don't decrypt these if they are already here
      for (Invitation object in invitationCollection.invitations) {
        //int index = existing.indexOf(object);

        int index = existing.indexWhere((element) => object.id == element.id);

        if (index == -1) {
          RatchetKeyAndMap ratchetKeyAndMap =
              await ForwardSecrecyUser.decryptUserObject(
                  object.ratchetIndex!, userFurnace.userid!);

          Map<String, dynamic> decrypted = ratchetKeyAndMap.map;

          UserCircleEnvelope userCircleEnvelope =
              UserCircleEnvelope.fromJsonObject(decrypted);

          object.circleName = userCircleEnvelope.contents.circleName;

          TableInvitation.upsert(object);
        } else {
          object.circleName = existing[index].circleName;

          ///check to see if the user changed their name
          if (object.inviter != existing[index].inviter)
            TableInvitation.upsert(object);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.decryptInvitationCollection: $err');
      rethrow;
    }
  }

  Future<List<Invitation>> fetchOpenInvitationsForUser(
      UserFurnace userFurnace) async {
    // List<Invitation> invitations = [];

    try {
      //debugPrint('hit fetchOpenInvitationsForUserService');

      String url = userFurnace.url! + Urls.INVITATIONS_ALL_FOR_USER;

      debugPrint(url);

      Map map = {
        'userID': userFurnace.userid!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse!["invitations"] != null) {
          InvitationCollection invitationCollection =
              InvitationCollection.fromJSON(jsonResponse, "invitations");

          decryptInvitationCollection(userFurnace, invitationCollection);

          //update the furnace count
          userFurnace.invitations = invitationCollection.invitations.length;
          await TableUserFurnace.upsert(userFurnace);
          return invitationCollection.invitations;
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.fetchOpenInvitationsForUser: $err');
    }

    return [];
  }

  Future<List<Invitation>> fetchOpenInvitationsForCircle(
      String circleID, UserFurnace userFurnace) async {
    //List<Invitation> invitations;

    try {
      String url = userFurnace.url! + Urls.INVITATIONS_ALL_FOR_CIRCLE;

      debugPrint(url);

      Map map = {
        'circleID': circleID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json"
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        late InvitationCollection invitationCollection;

        if (jsonResponse["invitations"] != null) {
          invitationCollection =
              InvitationCollection.fromJSON(jsonResponse, "invitations");
        }

        return invitationCollection.invitations;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint(response.statusCode.toString());

        // If that call was not successful, throw an error.
        //throw Exception('Could not connect to furnace' + response.statusCode.toString());
        return [];
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.fetchOpenInvitationsForCircle: $err');
    }

    return [];
  }

  Future<User> findUser(String username, UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.INVITATIONS_FINDUSER;

      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'inviteeUsername': username,
        'inviteeID': '',
        'apikey': userFurnace.apikey,
        'circleID': '',
        'device': device.uuid,
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

        User retValue = User.fromJson(jsonResponse["user"]);

        return retValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint(response.statusCode.toString());

        if (jsonResponse.containsKey("msg"))
          throw (jsonResponse["msg"]);
        else
          throw ("could not find user");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.sendInvitation: $err');
      rethrow;
    }

    throw ("could not find user");
  }

  Future<RatchetKey> findUserPublic(String username, String id,
      String? circleID, UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.INVITATIONS_FINDUSER;

      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'inviteeUsername': username,
        'inviteeID': id,
        'apikey': userFurnace.apikey,
        'circleID': circleID,
        'device': device.uuid,
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

        //return invitationCollection.invitations;
        RatchetKey retValue =
            RatchetKey.fromJson(jsonResponse["ratchetPublicKey"]);

        return retValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());

        if (jsonResponse.containsKey("msg"))
          throw (jsonResponse["msg"]);
        else
          throw ("Failed to send invite");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.sendInvitation: $err');
      rethrow;
    }

    throw ("could not find user");
  }

  Future<Invitation?> sendInvitation(
      String username,
      String id,
      String? circleID,
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      bool dm) async {
    try {
      String url = userFurnace.url! + Urls.INVITATIONS;

      var uuid = Uuid();
      String seed = uuid.v4();

      UserCircleEnvelope userCircleEnvelope = await TableUserCircleEnvelope.get(
          userCircleCache.usercircle!, userCircleCache.user!);

      ///The Circle name should be the name of inviter if it's a DM
      if (dm)
        userCircleEnvelope.contents.circleName = userFurnace.username!;
      else if (userCircleCache.prefName != null &&
          userCircleCache.prefName!.isNotEmpty)
        userCircleEnvelope.contents.circleName = userCircleCache.prefName!;
      /*else if (userCircleEnvelope.contents.circleName.isEmpty) { //test to see if it's empty
        if (userCircleCache.prefName != null &&
            userCircleCache.prefName!.isNotEmpty)
          userCircleEnvelope.contents.circleName = userCircleCache.prefName!;
      }*/

      RatchetKey ratchetKey =
          await findUserPublic(username, id, circleID, userFurnace);

      //debugPrint(userCircleEnvelope.toJsonForInvitation());

      RatchetIndex ratchetIndex = await ForwardSecrecyUser.encryptObjectForUser(
          userFurnace,
          userFurnace.userid!,
          ratchetKey,
          userCircleEnvelope
              .toJsonForInvitation()); //removes fields specific to this user

      debugPrint(url);

      debugPrint(globalState.lastCreatedMagicLink);

      Map map = {
        'inviteeUsername': username,
        'inviteeID': id,
        'apikey': userFurnace.apikey,
        'circleID': circleID,
        "ratchetIndex": ratchetIndex,
        'seed': seed,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        //return invitationCollection.invitations;

        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        Invitation invitation =
            Invitation.fromJson(jsonResponse!["invitation"]);

        Member memberExists = globalState.members.firstWhere(
            (element) => element.memberID == invitation.inviteeID,
            orElse: () => Member(memberID: '', userID: '', alias: ''));

        ///add the member to globalState
        if (memberExists.memberID.isEmpty) {
          Member member = Member(
              memberID: invitation.inviteeID,
              userID: userFurnace.userid!,
              username: memberExists.username,
              alias: '');

          member.color = globalState.theme
              .messageColorOptions![globalState.userSetting.lastColorIndex];

          globalState.members.add(member);

          globalState.userSetting
              .setLastColorIndex(globalState.userSetting.lastColorIndex + 1);

          await MemberService.upsert(userFurnace.userid!, member);
        }

        List<ActionRequired> actionRequireds =
            await TableActionRequiredCache.readForUserAndType(
                userFurnace.userid!,
                ActionRequiredAlertType.USER_JOINED_NETWORK);

        for (ActionRequired actionRequired in actionRequireds) {
          if (actionRequired.member!.id == memberExists.memberID) {
            actionRequired.userFurnace = userFurnace;
            await ActionNeededService.dismiss(actionRequired);
            break;
          }
        }

        return invitation;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());

        if (jsonResponse!.containsKey("msg"))
          throw (jsonResponse["msg"]);
        else
          throw ("Failed to send invite");
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.sendInvitation: $err');
      rethrow;
    }

    return null;
  }

  Future<User> addToBlockedList(UserFurnace userFurnace, String? userID) async {
    // List<Invitation> invitations;

    User retValue = User();
    try {
      String url = userFurnace.url! + Urls.BLOCKEDLIST;

      debugPrint(url);

      Map map = {
        'userid': userID,
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

        if (jsonResponse!["user"] != null) {
          retValue = User.fromJson(jsonResponse["user"]);
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.addToBlockedList: $err');
    }
    //debugPrint('temp');
    return retValue;
  }

  Future<User?> removeFromBlockedList(
      UserFurnace userFurnace, String userID) async {
    // List<Invitation> invitations;

    try {
      String url = userFurnace.url! + Urls.BLOCKEDLIST + 'undefined';

      debugPrint(url);

      Map map = {
        'userID': userID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.delete(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        if (jsonResponse!["user"] != null) {
          return User.fromJson(jsonResponse["user"]);
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.removeFromBlockedList: $err');
    }

    return null;
  }

  Future<User> fetchBlockedList(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.BLOCKEDLIST_GET + 'undefined';

      Map map = {
        'userID': userFurnace.userid!,
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

        if (jsonResponse!["user"] != null) {
          return User.fromJson(jsonResponse["user"]);
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic>? jsonResponse = json.decode(response.body);

        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception(jsonResponse!["msg"]);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsService.fetchBlockedList: $err');
    }

    return User();
  }
}
