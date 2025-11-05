// To parse this JSON data, do
//
//     final circleObjectCache = circleObjectCacheFromJson(jsonString);

import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';

CircleListMasterCache circleListMasterCacheFromJson(String str) =>
    CircleListMasterCache.fromJson(json.decode(str));

String circleListMasterCacheToJson(CircleObjectCache data) =>
    json.encode(data.toJson());

class CircleListMasterCache {
  int? pk;
  String? id;
  String? owner;
  String? name;
  String? jsonString;
  DateTime? lastUpdate;
  DateTime? created;

  //hitchhikers
  UserFurnace? userFurnace;
  //UserCircleCache userCircleCache;

  CircleListMasterCache({
    this.pk,
    this.id,
    this.owner,
    this.name,
    this.jsonString,
    this.lastUpdate,
    this.created,
  });

  factory CircleListMasterCache.fromJson(Map<String, dynamic> json) =>
      CircleListMasterCache(
        pk: json["pk"],
        id: json["id"],
        jsonString: json["jsonString"],
        owner: json["owner"],
        name: json["name"],
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["created"]).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "jsonString": jsonString == null ? null : jsonString,
        "owner": owner,
        "name": name,
        "lastUpdate":
            lastUpdate?.millisecondsSinceEpoch,
        "created": created?.millisecondsSinceEpoch,
      };
}
