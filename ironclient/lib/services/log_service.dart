import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class LogService {
  static Future<bool> toggle(UserFurnace userFurnace, bool submitLogs) async {
    try {
      String url = userFurnace.url! + Urls.LOGS_TOGGLE;

      Map map = {
        'submitLogs': submitLogs,
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

        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        /*if (submitLogs == false)
          globalState.userSetting.setLastLogSubmission(lastLogSubmission);
          SecureStorageService.writeKey(
              KeyType.LAST_LOG_SUBMISSION + userFurnace.userid!, '');

         */

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("LogService.toggle: $error");

      throw (error);
    }

    return false;
  }

  static Future<bool> post(UserFurnace userFurnace, List<Log> logs) async {
    //return true;

    String url = userFurnace.url! + Urls.LOGS; //+circleID + '?' + memberID;

    debugPrint(url);

    Map map = {
      'logs': logs,
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

      return true;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);

      return false;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  static Future<bool> postToForge(List<Log> logs) async {
    //return true;
    Device device = await globalState.getDevice();

    String url = urls.forge + Urls.LOGS_FORGE; //+circleID + '?' + memberID;

    debugPrint(url);

    Map map = {
      'logs': logs,
      'apikey': urls.forgeAPIKEY,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': "application/json",
      },
      body: json.encode(map),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      throw ('401 error from LogService.postToForge');
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
