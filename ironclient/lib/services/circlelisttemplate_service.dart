import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
//import 'package:http_retry/http_retry.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circlelistmaster.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class CircleListTemplateService {
  Future<CircleListTemplate> upsert(
      CircleList circleList, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLELISTTEMPLATE;

    UserTemplateRatchet userTemplateRatchet =
        await ForwardSecrecyUser.encryptListTemplate(
            userFurnace.userid!, circleList);

    Map map = {
      'template': circleList.template,
      'owner': userFurnace.userid,
      'tasks': circleList.tasks,
      'checkable': circleList.checkable,
      'ratchetIndexes': userTemplateRatchet.ratchetIndexes,
      'crank': userTemplateRatchet.crank,
      'signature': userTemplateRatchet.signature,
      'body': userTemplateRatchet.cipherText,
    };

    debugPrint(url);

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      CircleListTemplate template =
          CircleListTemplate.fromJson(jsonResponse["template"]);

      template.revertEncryptedFields(circleList);

      await TableCircleListMaster.upsert(template);

      return template;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);

      return CircleListTemplate(ratchetIndexes: []);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    //return circleObject;
  }

  Future<List<CircleListTemplate>> getTemplates(
      List<UserFurnace> userFurnaces) async {
    List<CircleListTemplate> retValue = [];

    try {
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;
        String url =
            userFurnace.url! + Urls.CIRCLELISTTEMPLATE + userFurnace.userid!;
        debugPrint(url);

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse = json.decode(response.body);
          //UserCircle userCircle = UserCircle.fromJson(jsonResponse["usercircle"]);

          if (jsonResponse.containsKey("templates")) {
            CircleListTemplateCollection collection =
                CircleListTemplateCollection.fromJSON(
                    jsonResponse, 'templates');

            List<CircleListTemplate> circleTemplates =
                await ForwardSecrecyUser.decryptListTemplates(
                    collection.circleListTemplates, userFurnace.userid!);

            //cache the results
            for (CircleListTemplate template in circleTemplates) {
              await TableCircleListMaster.upsert(template);
            }

            return circleTemplates;
          }
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");

          Map<String, dynamic> jsonResponse = json.decode(response.body);

          throw Exception(jsonResponse['msg']);
        }
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListMasterService.getMasterLists: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListMasterService.getMasterLists: ${err.toString()}');
      throw Exception(err);
    }

    return retValue;
  }

  Future<void> delete(
      UserFurnace userFurnace, CircleListTemplate template) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLELISTTEMPLATE + template.id!;

      debugPrint("$url ${DateTime.now().toLocal()}");

      if (await Network.isConnected()) {
        debugPrint(url);

        var client = RetryClient(http.Client(), retries: 3);

        final response = await client.delete(
          Uri.parse(url),
          headers: {'Authorization': userFurnace.token!},
          //body: map,
        );

        if (response.statusCode == 200) {
          // Map<String, dynamic>? jsonResponse = json.decode(response.body);
          return;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
        }
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListMasterService.delete: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListMasterService.delete: ${err.toString()}');
      throw Exception(err);
    }
  }
}
