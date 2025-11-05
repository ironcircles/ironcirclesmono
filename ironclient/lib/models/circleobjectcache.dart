// To parse this JSON data, do
//
//     final circleObjectCache = circleObjectCacheFromJson(jsonString);

import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';

CircleObjectCache circleObjectCacheFromJson(String str) =>
    CircleObjectCache.fromJson(json.decode(str));

String circleObjectCacheToJson(CircleObjectCache data) =>
    json.encode(data.toJson());

class CircleObjectCache {
  int? pk;
  String? circleid;
  String? circleObjectid;
  String? circleObjectJson;
  DateTime? lastUpdate;
  DateTime? created;
  String? seed;
  String? type;
  String? creator;
  bool ableToDecrypt;
  bool pinned;
  int? thumbnailTransferState;
  int? fullTransferState;
  bool read = false;
  bool draft;
  int retryDecrypt;

  //hitchhikers
  UserFurnace? userFurnace;
  UserCircleCache? userCircleCache;

  CircleObjectCache(
      {this.pk,
      this.circleid,
      this.circleObjectid,
      this.circleObjectJson,
      this.lastUpdate,
      this.created,
      this.seed,
      this.pinned = false,
      this.type,
      this.creator,
      this.thumbnailTransferState,
      this.fullTransferState,
      this.ableToDecrypt = false,
      this.retryDecrypt = 0,
      this.read = false,
      this.draft = false});

  factory CircleObjectCache.fromJson(Map<String, dynamic> json) =>
      CircleObjectCache(
        pk: json["pk"],
        circleid: json["circle"],
        circleObjectid: json["circleObject"],
        circleObjectJson: json["circleObjectJson"],
        seed: json["seed"],
        pinned: json["pinned"] == 1 ? true : false,
        draft: json["draft"] == 1 ? true : false,
        read: json["read"] == 1 ? true : false,
        retryDecrypt: json["retryDecrypt"] ?? 0,
        type: json["type"],
        creator: json["creator"],
        thumbnailTransferState: json["thumbnailTransferState"],
        fullTransferState: json["fullTransferState"],
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["created"]).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "circle": circleid,
        "circleObject": circleObjectid,
        "circleObjectJson": circleObjectJson,
        "seed": seed,
        "pinned": pinned ? 1 : 0,
        "draft": draft ? 1 : 0,
        "read": read ? 1 : 0,
        "type": type,
        "retryDecrypt": retryDecrypt,
        "creator": creator,
        "thumbnailTransferState": thumbnailTransferState,
        "fullTransferState": fullTransferState,
        "lastUpdate":
            lastUpdate?.millisecondsSinceEpoch,
        "created": created?.millisecondsSinceEpoch,
      };
}
