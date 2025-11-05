import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class ActionNeededService {
  static dismiss(ActionRequired actionRequired) async {
    try {
      UserFurnace userFurnace = actionRequired.userFurnace!;
      int retries = 0;
      String url =
          userFurnace.url! + Urls.ACTIONREQUIRED_DISMISS; // + '?' + memberID;

      debugPrint(url);

      while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
        try {
          UserFurnace userFurnace = actionRequired.userFurnace!;

          Map map = {
            'id': actionRequired.id,
          };

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

            // Map<String, dynamic> jsonResponse =
            // await EncryptAPITraffic.decryptJson(response.body);

            await TableActionRequiredCache.delete(actionRequired.id!);

            return;
          } else if (response.statusCode == 401) {
            await navService.logout(userFurnace);
          } else {
            debugPrint("${response.statusCode}: ${response.body}");

            Map<String, dynamic> jsonResponse = json.decode(response.body);

            throw Exception(jsonResponse['msg']);
          }
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint("ActionNeededService.dismiss: $error");
        }

        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          throw Exception('failed to hide post');

        await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
        retries++;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ActionNeededService.dismiss: ${err.toString()}');
      //rethrow;
    }
  }

  Future<int> countCircleObjectActionRequired(UserFurnace userFurnace) async {
    try {
      List<String> circles = [];

      List<UserCircleCache> userCircles =
          await TableUserCircleCache.readAllForUserFurnace(
              userFurnace.pk, userFurnace.userid);

      for (UserCircleCache userCircleCache in userCircles) {
        //add the furnace hitchhiker
        userCircleCache.furnaceObject = userFurnace;
        circles.add(userCircleCache.circle!);
      }

      List<CircleObject> objects =
          await fetchCircleObjectActionRequired(circles, userCircles);

      return objects.length;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          "ActionRequiredService.convertCircleObjectActionRequiredFromCache: $err");
    }

    return 0;
  }

  Future<List<CircleObject>> fetchCircleObjectActionRequired(
      List<String> circles, List<UserCircleCache> userCircles) async {
    try {
      List<CircleObject>? retValue = [];
      //List<CircleObjectCache> tempCache =[];

      // debugPrint('circleobject data fetch start: ${DateTime.now()}');

      List<CircleObjectCache> circleObjectCacheList =
          await TableCircleObjectCache.readActionNeeded(circles, 2000);

      //debugPrint('circleobject data fetch stop: ${DateTime.now()}');

      /* for (CircleObjectCache circleObjectCache in circleObjectCacheList) {
        //add the hitchikers
        circleObjectCache.userCircleCache = userCircleCache;
        circleObjectCache.userFurnace = userFurnace;
      }*/

      if (circleObjectCacheList.isNotEmpty) {
        //convert the cache to circleobjects
        for (CircleObjectCache circleObjectCache in circleObjectCacheList) {
          try {
            Map<String, dynamic> decode =
                json.decode(circleObjectCache.circleObjectJson!);

            CircleObject circleObject = CircleObject.fromJson(decode);

            if (circleObject.type != null) {
              if (circleObject.type == 'circlelist') {
                if (circleObject.list!.complete ||
                    !circleObject.list!.checkable) continue;

                //find the right hitchhikers
                UserCircleCache userCircleCache = userCircles.firstWhere(
                    (element) => element.circle == circleObjectCache.circleid);

                circleObject.userCircleCache = userCircleCache;
                circleObject.userFurnace = userCircleCache.furnaceObject!;
              } else if (circleObject.type == 'circlevote') {
                if (!circleObject.vote!.open!) continue;

                //find the right hitchhikers
                UserCircleCache userCircleCache = userCircles.singleWhere(
                    (element) => element.circle == circleObjectCache.circleid);

                circleObject.userCircleCache = userCircleCache;
                circleObject.userFurnace = userCircleCache.furnaceObject!;

                //debugPrint('break');

                //if (!addOpenAlreadyVoted) {
                if (CircleVote.didUserVote(
                    circleObject.vote!, circleObject.userFurnace!.userid!))
                  continue;
                //}
              }

              retValue.add(circleObject);
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
          }
        }
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          "ActionRequiredService.convertCircleObjectActionRequiredFromCache: $err");
    }

    return [];
  }
}
