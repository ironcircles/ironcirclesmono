import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class SubscriptionService {
  static Future<Subscription> subscribe(
      UserFurnace userFurnace, Subscription subscription) async {
    try {
      String url = userFurnace.url! + Urls.SUBSCRIPTIONS_SUBSCRIBE;

      Map map = {
        'subscription': subscription,
        'platform': Platform.isAndroid
            ? PlatformType.ANDROID
            : Platform.isIOS
                ? PlatformType.IOS
                : ''
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

        Subscription subscription =
            Subscription.fromJson(jsonResponse["subscription"]);

        TableSubscription.upsert(subscription);

        globalState.user.accountType = AccountType.PREMIUM;
        globalState.userSetting.setAccountType(AccountType.PREMIUM);
        userFurnace.accountType = AccountType.PREMIUM;

        //no need to wait
        TableUserFurnace.upsert(userFurnace);
        return subscription;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return subscription;
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("LogService.toggle: $error");

      rethrow;
    }
  }

  static Future<bool> cancel(
      UserFurnace userFurnace, Subscription subscription) async {
    try {
      String url = userFurnace.url! + Urls.SUBSCRIPTIONS_CANCEL;

      Map map = {
        'subscription': subscription,
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

        if (jsonResponse["subscription"] != null) {
          Subscription subscription =
              Subscription.fromJson(jsonResponse["subscription"]);

          TableSubscription.upsert(subscription);
        }

        ///update the user
        globalState.userSetting.setAccountType(AccountType.FREE);
        globalState.user.accountType = AccountType.FREE;
        globalState.userFurnace!.accountType = AccountType.FREE;
        globalState.subscription = null;

        ///no need to wait
        TableUserFurnace.upsert(globalState.userFurnace!);

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
      debugPrint("LogService.cancel: $error");

      throw (error);
    }

    return false;
  }
}
