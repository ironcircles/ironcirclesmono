import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circlelistmaster.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CircleListService {
  Future<CircleObject> updateList(UserCircleCache userCircleCache,
      CircleObject circleObject, bool saveList, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLELIST + 'undefined';

    CircleObject encryptedCopy =
        await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

    Device device = await globalState.getDevice();

    Map map = {
      'circleid': userCircleCache.circle,
      //'name': circleObject.list!.name,
      'saveList': saveList,
      'tasks': circleObject.list!.tasks,
      'pushtoken': device.pushToken,
      'body': encryptedCopy.body,
      'crank': encryptedCopy.crank,
      'signature': encryptedCopy.signature,
      'verification': encryptedCopy.verification,
      'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
      'ratchetIndexes': encryptedCopy.ratchetIndexes,
      'circleObjectID': circleObject.id!,
    };

    debugPrint(url);

    // String jsonMap = jsonEncode(map);
    // String howBigIsThis = jsonMap.length.toString();
    // debugPrint('CircleObjectService: $howBigIsThis');
    // debugPrint(jsonMap);

    //debugPrint('encrypt map start ${DateTime.now()}');

    map = await EncryptAPITraffic.encrypt(map);

    //debugPrint('calling api at ${DateTime.now()}');

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      //debugPrint('calling response at ${DateTime.now()}');

      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      CircleObject retValue =
          CircleObject.fromJson(jsonResponse["circleobject"]);

      retValue.revertEncryptedFields(circleObject);

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

  Future<CircleObject> createList(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      bool? saveList,
      UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLELIST;

    CircleObject encryptedCopy =
        await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

    UserTemplateRatchet userTemplateRatchet =
        await ForwardSecrecyUser.encryptListTemplate(
            userFurnace.userid!, circleObject.list!);

    Device device = await globalState.getDevice();

    Map map = {
      'circleid': userCircleCache.circle,
      //'name': circleList.name,
      'saveList': saveList,
      'type': circleObject.type,
      'seed': circleObject.seed,
      'device': device.uuid,
      'template': circleObject.list!.template,
      'tasks': encryptedCopy.list!.tasks,
      'checkable': encryptedCopy.list!.checkable,
      'creator': circleObject.creator!.id,
      'owner': circleObject.creator!.id,
      'circle': circleObject.circle!.id,
      'pushtoken': device.pushToken,
      'body': encryptedCopy.body,
      'crank': encryptedCopy.crank,
      'signature': encryptedCopy.signature,
      'verification': encryptedCopy.verification,
      'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
      'userTemplateRatchet': userTemplateRatchet,
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
          CircleObject.fromJson(jsonResponse["circleobject"]);

      retValue.revertEncryptedFields(circleObject);

      retValue.circle ??= circleObject.circle;

      //flip the dates to move to bottom of sort list
      retValue.created = retValue.lastUpdate;

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, retValue);

      TableUserCircleCache.updateLastItemUpdate(
          retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

      if (jsonResponse["template"] != null) {
        CircleListTemplate template =
            CircleListTemplate.fromJson(jsonResponse["template"]);

        template.revertEncryptedFields(circleObject.list!);

        await TableCircleListMaster.upsert(template);
      }

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
