import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/tutorial.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class TutorialService {
  Future<List<Topic>> get(UserFurnace userFurnace) async {
    ///Always get tutorials from the IronForge
    String url = urls.forge + Urls.TUTORIALS;
    //String url = userFurnace.url! + Urls.TUTORIALS + userFurnace.userid!;


    if (userFurnace.type == NetworkType.SELF_HOSTED){
      url = url + userFurnace.forgeUserId!;
    } else {
      url = url + userFurnace.userid!;
    }
    debugPrint(url);

    final response = await http.get(
      Uri.parse(url),
      headers: {
        //'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
        'textbased': 'true',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      TopicCollection topics = TopicCollection.fromJSON(jsonResponse);

      return topics.topics;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<Topic>> generateContent(UserFurnace userFurnace) async {
    ///Always get tutorials from the IronForge
    //String url = Urls.IRONFORGE + Urls.TUTORIALS;
    String url = userFurnace.url! + Urls.TUTORIALS_GENERATE;

    debugPrint(url);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        /*body: json.encode(map)*/);
    

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      TopicCollection topics = TopicCollection.fromJSON(jsonResponse);

      return topics.topics;
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
