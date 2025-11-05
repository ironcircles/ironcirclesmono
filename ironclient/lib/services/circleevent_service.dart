import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/circleeventrespondent.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CircleEventService {
  Future<CircleObject> createEvent(UserCircleCache userCircleCache,
      CircleObject circleObject, UserFurnace userFurnace, GlobalEventBloc globalEventBloc) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEEVENT;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      Device device = await globalState.getDevice();

      Map map = {
        'circle': userCircleCache.circle,
        'type': circleObject.type,
        'seed': circleObject.seed,
        'device': device.uuid,
        'event': encryptedCopy.event,
        //'checkable': encryptedCopy.list!.checkable,
        'creator': circleObject.creator!.id,
        'owner': circleObject.creator!.id,
        //'circle': circleObject.circle!.id,
        'pushtoken': device.pushToken,
        'body': encryptedCopy.body,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
      };

      if (circleObject.timer != null) {
        map["timer"] = circleObject.timer;
      }
      if (circleObject.scheduledFor != null) {
        String scheduled = encryptedCopy.scheduledFor.toString().substring(0, 17);
        String time = circleObject.dateIncrement.toString();
        String scheduledTime = scheduled + time;
        map["scheduledFor"] = scheduledTime;
      }

      debugPrint(url);

      //var me = json.encode(map);

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

        CircleObject retValue =
            CircleObject.fromJson(jsonResponse["circleObject"]);

        retValue.revertEncryptedFields(circleObject);

        retValue.circle ??= circleObject.circle;

        //flip the dates to move to bottom of sort list
        retValue.created = retValue.lastUpdate;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, retValue);

        TableUserCircleCache.updateLastItemUpdate(
            retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

        return retValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        if (response.body.contains(
            'You cannot post when there is an active vote to remove you from the Circle')) {
          globalEventBloc.broadcastError(
              'You cannot post when there is an active vote to remove you from the Circle');
        }

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }

    return circleObject;
  }

  Future<CircleObject> updateEvent(UserCircleCache userCircleCache,
      CircleObject circleObject, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLEEVENT + 'undefined';

    ///remove all responses that isn't the current response
    circleObject.event!.encryptedLineItems.removeWhere(
        (element) => element.ratchetIndex.user != userFurnace.userid!);

    CircleObject encryptedCopy =
        await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

    ///There could be a better way
    if (circleObject.event!.respondents[0].attending == Attending.No)
      encryptedCopy.event!.encryptedLineItems[0].ratchetIndex.device =
          Attending.No.index.toString();

    Device device = await globalState.getDevice();

    Map map = {
      'circle': userCircleCache.circle,
      'event': encryptedCopy.event,
      'pushtoken': device.pushToken,
      'device': device.uuid,
      'body': encryptedCopy.body,
      'crank': encryptedCopy.crank,
      'signature': encryptedCopy.signature,
      'verification': encryptedCopy.verification,
      'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
      'ratchetIndexes': encryptedCopy.ratchetIndexes,
      'circleObjectID': circleObject.id!,
    };

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
      CircleObject retValue =
          CircleObject.fromJson(jsonResponse["circleobject"]);

      //retValue.revertEncryptedFields(circleObject);

      List<CircleObject> decrypted = await ForwardSecrecy.decryptCircleObjects(
          userFurnace.userid!, userCircleCache.usercircle!, [retValue]);

      retValue = decrypted[0];

      //flip the dates to move to bottom of sort list
      retValue.created = retValue.lastUpdate;

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, retValue);

      TableUserCircleCache.updateLastItemUpdate(
          retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

      return retValue;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    return circleObject;
  }
}
