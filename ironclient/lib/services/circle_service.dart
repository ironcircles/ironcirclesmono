import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/models/usercircleenvelopecontents.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_usercircleenvelope.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CircleService {
  Future<Circle?> fetch(UserFurnace userFurnace, String circleID, DateTime? lastAccessed) async {
    Circle? retValue;

    try {
      String url = userFurnace.url! + Urls.CIRCLE_GET; // + circleID;
      debugPrint(url);

      Map map = {'circleID': circleID};

      if (lastAccessed != null) {
        map["lastAccessed"] = lastAccessed.toUtc().toString();
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        retValue = Circle.fromJson(jsonResponse["circle"]);

        if (jsonResponse.containsKey("memberCount"))
          retValue.memberCount = jsonResponse["memberCount"];

        if (jsonResponse.containsKey("ratchetPublicKeys")) {
          retValue.memberSessionKeys.addAll(
              RatchetKeyCollection.fromJSON(jsonResponse, "ratchetPublicKeys")
                  .ratchetKeys);
        }

        TableCircleCache.upsert(retValue, updateKey: false);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.fetch: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.fetch: ${err.toString()}');
      throw Exception(err);
    }

    return retValue;
  }

  Future<void> updateVotingModel(
      UserFurnace userFurnace,
      String circleID,
      String modelChange,
      String message,
      Function callback,
      int settingChangeType) async {
    try {
      String url =
          userFurnace.url! + Urls.CIRCLESETTING_VOTING_MODEL + 'undefined';
      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'circleID': circleID,
        'modelchange': modelChange,
        'description': message,
        'pushtoken': device.pushToken,
        'settingchangetype': settingChangeType.toString(),
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        Circle circle = Circle.fromJson(jsonResponse["circle"]);
        String? msg = jsonResponse["msg"];
        CircleObject? retValue;

        if (jsonResponse.containsKey("circleObject")) {
          retValue = CircleObject.fromJson(jsonResponse["circleObject"]);

          await TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, retValue);
          TableUserCircleCache.updateLastItemUpdate(
              retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);
        }

        callback(circle, msg, retValue);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.updateSetting: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.updateSetting: ${err.toString()}');
      throw Exception(err);
    }
  }

  Future<void> updateTemporaryExpiration(UserFurnace userFurnace,
      String circleID, String expiration, Function callback) async {
    try {
      String url =
          userFurnace.url! + Urls.CIRCLESETTING_EXPIRATION + 'undefined';
      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'circleID': circleID,
        'expiration': expiration,
        'pushtoken': device.pushToken,
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        Circle circle = Circle.fromJson(jsonResponse["circle"]);
        String? msg = jsonResponse["msg"];

        callback(circle, msg, null);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.updateTemporaryExpiration: ${err.toString()}');
      throw Exception(err);
    }
  }

  Future<void> updateSetting(
      UserFurnace userFurnace,
      String circleID,
      List<CircleSettingValue> list,
      String message,
      Function callback,
      int settingChangeType) async {
    //Circle retValue;

    try {
      String url = userFurnace.url! + Urls.CIRCLESETTING + 'undefined';
      debugPrint(url);

      Device device = await globalState.getDevice();

      Map map = {
        'circleID': circleID,
        'settingvalues': list,
        'description': message,
        'pushtoken': device.pushToken,
        'settingchangetype': settingChangeType.toString(),
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        Circle circle = Circle.fromJson(jsonResponse["circle"]);

        await TableCircleCache.upsert(circle);

        String? msg = jsonResponse["msg"];

        CircleObject? circleObject;

        if (jsonResponse["circleObject"] != null)
          circleObject = CircleObject.fromJson(jsonResponse["circleObject"]);

        callback(circle, msg, circleObject);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.updateSetting: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleService.updateSetting: ${err.toString()}');
      throw Exception(err);
    }
  }

  Future<String> removeMember(
      UserFurnace userFurnace, String? circleID, String memberID) async {
    String url = userFurnace.url! +
        Urls.CIRCLEREMOVEMEMBER; //+circleID + '?' + memberID;

    debugPrint(url);

    Map map = {'circleid': circleID, 'memberid': memberID};

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
      },
      body: map,
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);
      //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);

      return jsonResponse["msg"];
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    return '';
  }

  Future<String> delete(String circleID, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLE + 'undefined';

    debugPrint(url);

    Map map = {'circleid': circleID};

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
      body: json.encode(map),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);
      //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);

      return jsonResponse["msg"];
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    return '';
  }

  Future<UserCircle> create(Circle circle, UserCircle userCircle, Color? color,
      UserFurnace userFurnace, DecryptArguments? args,
      {String memberID = '', String memberName = ''}) async {
    String url = userFurnace.url! + Urls.CIRCLE;

    //get a keypair to use
    RatchetKey ratchetKey =
        await ForwardSecrecy.generateKeyPair(userFurnace.userid!, '');

    UserCircleEnvelopeContents userCircleEnvelopeContents =
        UserCircleEnvelopeContents(
            circleName: circle.name!,
            prefName: userCircle.prefName == null
                ? circle.name!
                : userCircle.prefName!);

    if (args != null) {
      userCircleEnvelopeContents.circleBackgroundSignature = args.mac;
      userCircleEnvelopeContents.circleBackgroundCrank = args.nonce;
      userCircleEnvelopeContents.circleBackgroundKey =
          base64UrlEncode(args.key!);
      userCircleEnvelopeContents.userCircleBackgroundSignature = args.mac;
      userCircleEnvelopeContents.userCircleBackgroundCrank = args.nonce;
      userCircleEnvelopeContents.userCircleBackgroundKey =
          base64UrlEncode(args.key!);
    }

    RatchetIndex ratchetIndex = await ForwardSecrecyUser.encryptUserObject(
        userFurnace.userid!, userCircleEnvelopeContents.toJson());

    Device device = await globalState.getDevice();

    Map map = {
      'device': device.uuid,
      'ownershipModel': circle.ownershipModel,
      'ratchetPublicKey': ratchetKey.safePublicCopy(),
      //'ratchetPublicKey': ratchetKey.removePrivateKey(),
      'ratchetIndex': ratchetIndex,
      'dm': circle.dm,
      'dmConnected': userCircle.dmConnected,
      'circle': circle,
    };

    if (color != null) {
      map["backgroundColor"] = color.value;
    }

    if (userCircle.hidden != null) {
      map["hidden"] = userCircle.hidden == true ? 'true' : 'false';
    }

    if (userCircle.hiddenPassphrase != null) {
      map["hiddenPassphrase"] = userCircle.hiddenPassphrase;
    }

    if (circle.dm) {
      map["memberID"] = memberID;
      map["memberName"] = memberName;
    }

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

      Circle savedCircle = Circle.fromJson(jsonResponse["circle"]);
      UserCircle savedUserCircle =
          UserCircle.fromJson(jsonResponse["usercircle"]);

      //restore the name
      savedCircle.name = circle.name;
      savedUserCircle.prefName = userCircle.prefName;

      //cache
      TableCircleCache.upsert(savedCircle, updateKey: true);
      TableUserCircleEnvelope.upsert(UserCircleEnvelope(
          user: userFurnace.userid!,
          userCircle: savedUserCircle.id!,
          contents: userCircleEnvelopeContents));

      //TableUserCircleCache.updateUserCircleCache(userCircle, userFurnace);

      //await RatchetKey.saveUserKeyPair(ratchetKey, savedUserCircle.id!);
      await RatchetKey.saveReceiverKeyPair(ratchetKey, savedUserCircle.id!);

      return savedUserCircle;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return UserCircle(ratchetKeys: []);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<UserCircle>> getMembershipList(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLEMEMBERS_GET;
    debugPrint(url);

    Map map = {'circleID': userCircleCache.circle!};

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
      body: json.encode(map),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      UserCircleCollection userCircleCollection =
          UserCircleCollection.fromJSON(jsonResponse, "usercircles");

      return userCircleCollection.userCircles;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
