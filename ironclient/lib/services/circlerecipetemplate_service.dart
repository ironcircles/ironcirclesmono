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
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class CircleRecipeTemplateService {
  Future<CircleRecipeTemplate> put(
      CircleRecipe circleRecipe, UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLERECIPETEMPLATE;

      UserTemplateRatchet userTemplateRatchet =
          await ForwardSecrecyUser.encryptRecipeTemplate(
              userFurnace.userid!, circleRecipe);

      Map map = {
        'templateid': circleRecipe.template,
        'owner': userFurnace.userid,
        'ratchetIndexes': userTemplateRatchet.ratchetIndexes,
        'crank': userTemplateRatchet.crank,
        'signature': userTemplateRatchet.signature,
        'body': userTemplateRatchet.cipherText,
        'instructions': circleRecipe.instructions,
        'ingredients': circleRecipe.ingredients,
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

        CircleRecipeTemplate template =
            CircleRecipeTemplate.fromJson(jsonResponse["template"]);

        template.revertEncryptedFields(circleRecipe);

        //await TableCircleListMaster.upsert(template);
        //CircleRecipeTemplate.put(userFurnace.userid!, template);

        return template;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return CircleRecipeTemplate.blank();
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplateService.upsert: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplateService.upsert: ${err.toString()}');
      throw Exception(err);
    }
  }

  Future<List<CircleRecipeTemplate>> getTemplates(
      List<UserFurnace> userFurnaces) async {
    List<CircleRecipeTemplate> retValue = [];

    try {
      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;
        String url =
            userFurnace.url! + Urls.CIRCLERECIPETEMPLATE + userFurnace.userid!;
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
            CircleRecipeTemplateCollection collection =
                CircleRecipeTemplateCollection.fromJSON(
                    jsonResponse, 'templates');

            List<CircleRecipeTemplate> circleTemplates =
                await ForwardSecrecyUser.decryptRecipeTemplates(
                    collection.templates, userFurnace.userid!);

            //cache the results
            for (CircleRecipeTemplate template in circleTemplates) {
              //CircleRecipeTemplate.put(userFurnace.userid!, template);
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
      debugPrint('CircleRecipeTemplateService.getTemplates: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplateService.getTemplates: ${err.toString()}');
      throw Exception(err);
    }

    return retValue;
  }

  Future<void> delete(
      UserFurnace userFurnace, CircleRecipeTemplate template) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLERECIPETEMPLATE + template.id!;

      debugPrint("$url ${DateTime.now().toLocal()}");

      if (await Network.isConnected()) {
        debugPrint(url);

        var client = RetryClient( http.Client(), retries: 3);

        final response = await client.delete(
          Uri.parse(url),
          headers: {'Authorization': userFurnace.token!},
          //body: map,
        );

        if (response.statusCode == 200) {
          //Map<String, dynamic>? jsonResponse = json.decode(response.body);
          return;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw Exception(response.body);
        }
      }
    } on SocketException catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplateService.delete: ${err.toString()}');
      throw Exception(err);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplateService.delete: ${err.toString()}');
      throw Exception(err);
    }
  }
}
