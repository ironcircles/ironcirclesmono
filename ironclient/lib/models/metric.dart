import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

Metric tutorialFromJson(String str) => Metric.fromJson(json.decode(str));

class Metric {
  //String? username;
  User? user;
  int? recentMessageCount;
  DateTime? lastAccessed;
  DateTime? created;
  int? count;
  String hostedFurnaceName;
  String hostedFurnaceId;
  String? models;
  int? mostRecentBuild;

  Metric({
    this.count,
    this.user,
    this.recentMessageCount,
    this.lastAccessed,
    this.created,
    this.models,
    this.mostRecentBuild,
    this.hostedFurnaceName = 'IronForge',
    this.hostedFurnaceId = '641cc790e66565299a3bb6fa',
  });

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
        count: json["count"] ?? 0,
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        recentMessageCount: json["recentMessageCount"] ?? 0,
        created: json["created"] == null
            ? DateTime(1900)
            : DateTime.parse(json["created"]).toLocal(),
        lastAccessed: json["lastAccessed"] == null
            ? DateTime(1900)
            : DateTime.parse(json["lastAccessed"]).toLocal(),
        hostedFurnaceId: populateFurnaceId(json),
        hostedFurnaceName: populateFurnaceName(json),
        models: populateModels(json),
        mostRecentBuild: populateMostRecentBuild(json),
      );

  static String populateFurnaceName(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> user = json['user'];

      if (user['hostedFurnace'] != null) {
        Map<String, dynamic> hostedFurnace = user['hostedFurnace'];
        return hostedFurnace['name'];
      }
    } catch (err) {
      debugPrint(err.toString());
    }

    return 'IronForge';
  }

  static String populateFurnaceId(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> user = json['user'];

      if (user['hostedFurnace'] != null) {
        Map<String, dynamic> hostedFurnace = user['hostedFurnace'];
        return hostedFurnace['_id'];
      }
    } catch (err) {
      debugPrint(err.toString());
    }

    return '641cc790e66565299a3bb6fa';
  }

  static String populateModels(Map<String, dynamic> json) {
    String retValue = '';

    try {
      Map<String, dynamic> user = json['user'];

      if (user['devices'] != null) {
        for (Map<String, dynamic> device in user['devices']) {
          if (device["model"] != null) {
            if (retValue.isEmpty)
              retValue = retValue + device["model"];
            else {
              if (!retValue.contains(device["model"]))
                retValue = retValue + ', ' + device["model"];
            }
          }
        }
      }
    } catch (err) {
      debugPrint(err.toString());
    }

    return retValue;
  }

  static int populateMostRecentBuild(Map<String, dynamic> json) {
    int mostRecentBuild = -1;
    try {
      Map<String, dynamic> user = json['user'];

      if (user['devices'] != null) {
        for (Map<String, dynamic> device in user['devices']) {
          int build = device["build"];

          if (mostRecentBuild < build) mostRecentBuild = build;
        }
      }
    } catch (err) {
      debugPrint(err.toString());
    }
    return mostRecentBuild;
  }
}

class MetricsCollection {
  MetricsCollection(
      {required this.metrics,
      this.subscribedCount = 0,
      this.accountsDeleted = 0,
      this.activeInLastFourteen = 0});

  final List<Metric> metrics;

  int subscribedCount = 0;
  int accountsDeleted = 0;
  int activeInLastFourteen = 0;

  MetricsCollection.fromJSON(Map<String, dynamic> json)
      : metrics = (json['metrics'] as List)
            .map((json) => Metric.fromJson(json))
            .toList();
}
