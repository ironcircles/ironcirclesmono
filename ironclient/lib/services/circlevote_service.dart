import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class VoteService {
  Future<CircleObject> submitVote(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      CircleVoteOption selectedOption,
      UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEVOTE_SUBMIT + 'undefined';

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': userCircleCache.circle,
        //'question': circleVote.question,
        //'model': circleVote.model,
        //'options': circleVote.options,
        'pushtoken': device.pushToken,
        "option": selectedOption.option,
        "type": circleObject.vote!.type,
        "circleObjectID": circleObject.id!,
      };

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
        //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);

        CircleObject circleObject =
            CircleObject.fromJson(jsonResponse["circleobject"]);

        if (circleObject.circle != null) {
          ///it will be null if the vote was to delete the Circle
          TableUserCircleCache.updateLastItemUpdate(circleObject.circle!.id,
              circleObject.creator!.id, circleObject.lastUpdate);

          if (jsonResponse.containsKey("circle")) {
            Circle circle = Circle.fromJson(jsonResponse['circle']);

            TableCircleCache.upsert(circle);
          }
        }

        return circleObject;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return CircleObject(ratchetIndexes: []);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVoteService.submitVote: $error");
      throw (error);
    }
  }

  Future<CircleObject> createUserVote(
      UserCircleCache userCircleCache,
      CircleVote circleVote,
      UserFurnace userFurnace,
      int? timer,
      DateTime? scheduledFor,
      int? increment,
      String seed) async {
    CircleObject retValue = CircleObject(ratchetIndexes: []);

    try {
      String url = userFurnace.url! + Urls.CIRCLEVOTE;

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': userCircleCache.circle,
        'question': circleVote.question,
        'seed': seed,
        'model': circleVote.model,
        'options': circleVote.options,
        'pushtoken': device.pushToken,
        'device': device.uuid,
      };

      if (timer != null) {
        map["timer"] = timer;
      }
      if (scheduledFor != null) {
        String scheduled = scheduledFor.toString().substring(0, 17);
        String time = increment!.toString();
        String scheduledTime = scheduled + time;
        map["scheduledFor"] = scheduledTime;
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

        retValue = CircleObject.fromJson(jsonResponse["circleobject"]);
        //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVoteService.createUserVote: $error");
      rethrow;
    }

    return retValue;
  }
}
