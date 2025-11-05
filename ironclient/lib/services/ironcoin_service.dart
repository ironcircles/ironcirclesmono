import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ironcointransaction.dart';
import 'package:ironcirclesapp/models/purchase.dart';
import 'package:ironcirclesapp/models/stablediffusionpricing.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/services/cache/table_prompt.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class IronCoinService {
  Future<StableDiffusionPricing> getCurrency() async {
    try {
      String url = urls.forge + Urls.GET_CURRENCY;
      debugPrint(url);

      Map map = {
        'currency': 'USD',
        'amount': 1,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'apikey': urls.forgeAPIKEY,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);
        return StableDiffusionPricing.fromJson(jsonResponse["matrix"]);
      } else if (response.statusCode == 401) {
        throw ("Something went wrong. Please try again.");
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService: getCurrency: $error');
      rethrow;
    }
  }

  Future<IronCoinTransaction?> processCoinPayment(
      UserFurnace userFurnace, int cost, String paymentType,
      {StableDiffusionPrompt? prompt}) async {
    IronCoinTransaction? payment;
    String url = userFurnace.url! + Urls.COIN_PAYMENT;
    debugPrint(url);

    Map map = {
      'cost': cost,
      'paymentType': paymentType,
      //'prompt': stableDiffusionAIPrompt.toJson(),
    };

    if (prompt != null) {
      map["prompt"] = prompt.toJson();
    }

    map = await EncryptAPITraffic.encrypt(map);

    try {
      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));



      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        payment = IronCoinTransaction.fromJson(jsonResponse["payment"]);
        if (jsonResponse["prompt"] != null) {
          StableDiffusionPrompt returned =
              StableDiffusionPrompt.fromJson(jsonResponse["prompt"]);

          //prompt!.deepCopy(returned);
          prompt!.created = returned.created;
          prompt.id = returned.id;
          prompt.userID = returned.userID;

          debugPrint("processCoinPayment index = ${prompt.promptType.index}");

          TablePrompt.upsert(prompt);
        }
        return payment;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService.processPayment: $error');
      rethrow;
    }
    return payment;
  }

  Future<IronCoinTransaction?> processCoinRefund(
    UserFurnace userFurnace,
    int cost,
    String paymentType,
  ) async {
    IronCoinTransaction? payment;
    String url = userFurnace.url! + Urls.COIN_PAYMENT_REFUND;
    debugPrint(url);

    Map map = {
      'cost': cost,
      'paymentType': paymentType,
    };

    map = await EncryptAPITraffic.encrypt(map);

    try {
      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            await EncryptAPITraffic.decryptJson(response.body);

        payment = IronCoinTransaction.fromJson(jsonResponse["payment"]);
        return payment;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService.processPayment: $error');
      rethrow;
    }
    return payment;
  }

  Future<List<IronCoinTransaction>?> fetchLedger(
      UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.FETCH_COIN_LEDGER;
    debugPrint(url);

    Map map = {
      'limit': 100,
    };

    map = await EncryptAPITraffic.encrypt(map);

    try {
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

        IronCoinTransactionCollection payments =
            IronCoinTransactionCollection.fromJSON(
                jsonResponse, "transactions");
        return payments.transactions;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService.fetchLedger: $error');
      rethrow;
    }
    return null;
  }

  Future<IronCoinTransaction?> giveCoins(
      UserFurnace userFurnace, User recipient, int coins) async {
    IronCoinTransaction? payment;
    String url = userFurnace.url! + Urls.GIVE_COINS;
    debugPrint(url);

    Map map = {
      'recipient': recipient,
      'coins': coins,
    };

    try {
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

        payment = IronCoinTransaction.fromJson(jsonResponse['payment']);
        return payment;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService.giveCoins: $error');
      rethrow;
    }
    return payment;
  }

  Future<bool> fetchCoins(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.GET_COINS;
    debugPrint(url);

    try {
      Map map = {
        'userID': userFurnace.userid!,
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

        globalState.updateCoinBalance(jsonResponse["coins"].toDouble());
        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return false;
      } else {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint("${response.statusCode}: ${response.body}");
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('IronCoinService.fetchCoins: $error');
      rethrow;
    }
    return false;
  }

  static Future<Purchase> purchase(
      UserFurnace userFurnace, Purchase purchase) async {
    try {
      String url = userFurnace.url! + Urls.PURCHASE_COINS;

      Map map = {
        'purchase': purchase,
        'platform': Platform.isAndroid
            ? PlatformType.ANDROID
            : Platform.isIOS
                ? PlatformType.IOS
                : ''
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
        Purchase purchase = Purchase.fromJson(jsonResponse["purchase"]);
        return purchase;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return purchase;
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
}
