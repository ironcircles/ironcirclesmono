import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/models/backlog.dart';
import 'package:ironcirclesapp/models/backlogreply.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class BacklogService {
  Future<List<Backlog>> get(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.BACKLOG;

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      BacklogCollection backlog = BacklogCollection.fromJSON(jsonResponse);

      return backlog.backlog;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> vote(UserFurnace userFurnace, Backlog backlog) async {
    try {
      String url =
          userFurnace.url! + Urls.BACKLOG + backlog.id!; // + '?' + memberID;

      debugPrint(url);

      Map map = {
        'id': backlog.id,
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map),
      );

      if (response.statusCode == 200) {
        //Map<String, dynamic> jsonResponse = json.decode(response.body);

        // backlog = Backlog.fromJson(jsonResponse["backlog"]);

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
      debugPrint("BacklogService.vote: $error");
      throw (error);
    }
  }

  Future<Backlog> post(UserFurnace userFurnace, Backlog backlog) async {
    String url = userFurnace.url! + Urls.BACKLOG; //+circleID + '?' + memberID;

    debugPrint(url);

    Map map = {
      'backlog': backlog,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
      body: json.encode(map),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      backlog = Backlog.fromJson(jsonResponse["backlog"]);

      return backlog;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);

      return backlog;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<BacklogReply> reply(
      UserFurnace userFurnace, Backlog backlog, BacklogReply reply) async {
    String url =
        userFurnace.url! + Urls.BACKLOG_REPLY; //+circleID + '?' + memberID;

    debugPrint(url);

    Map map = {
      'reply': reply.reply,
      'backlogID': backlog.id,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      },
      body: json.encode(map),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      reply = BacklogReply.fromJson(jsonResponse["reply"]);

      return reply;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);

      return reply;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
