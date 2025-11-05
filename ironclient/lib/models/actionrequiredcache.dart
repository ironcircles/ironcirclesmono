// To parse this JSON data, do
//
//     final circleObjectCache = circleObjectCacheFromJson(jsonString);

import 'dart:convert';

import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';

ActionRequiredCache circleObjectCacheFromJson(String str) =>
    ActionRequiredCache.fromJson(json.decode(str));

String circleObjectCacheToJson(ActionRequiredCache data) =>
    json.encode(data.toJson());

class ActionRequiredCache {
  int? pk;
  String? id;
  String? actionRequiredJson;
  DateTime? lastUpdate;
  DateTime? created;
  int? alertType;
  String? user;
  String? networkRequest;

  //hitchhikers
  UserFurnace? userFurnace;
  UserCircleCache? userCircleCache;

  ActionRequiredCache({
    this.pk,
    this.id,
    this.actionRequiredJson,
    this.user,
    this.lastUpdate,
    this.created,
    this.alertType,
    this.networkRequest,
  });

  factory ActionRequiredCache.fromJson(Map<String, dynamic> json) =>
      ActionRequiredCache(
        pk: json["pk"],
        id: json["id"],
        actionRequiredJson: json["actionRequiredJson"],
        alertType: json["alertType"],
        user: json["user"],
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["created"]).toLocal(),
        networkRequest: json['networkRequest'] == null
          ? null
          : json["networkRequest"],
      );

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "id": id,
        "actionRequiredJson":
            actionRequiredJson == null ? null : actionRequiredJson,
        "alertType": alertType,
        "user": user,
        "lastUpdate":
            lastUpdate?.millisecondsSinceEpoch,
        "created": created?.millisecondsSinceEpoch,
        "networkRequest": networkRequest == null ? null : networkRequest,
      };

  /// Convert a ActionRequiredCache list to a ActionRequired list
  static List<ActionRequired> convertFromCache(
      List<ActionRequiredCache> actionRequiredCacheList) {
    List<ActionRequired> convertValue = [];

    if (actionRequiredCacheList.isNotEmpty) {
      convertValue = [];

      //convert the cache to circleobjects
      for (ActionRequiredCache actionRequiredCache in actionRequiredCacheList) {
        // debugPrint(circleObjectCache.circleObjectJson);

        Map<String, dynamic> decode =
            json.decode(actionRequiredCache.actionRequiredJson!);

        ActionRequired actionRequired = ActionRequired.fromJson(decode);
        //add the hitchhikers
        actionRequired.userFurnace = actionRequiredCache.userFurnace;

        convertValue.add(actionRequired);
      }
    }

    return convertValue;
  }

  static ActionRequiredCache createFromObject(ActionRequired actionRequired) {
    ActionRequiredCache retValue = ActionRequiredCache(
        id: actionRequired.id,
        user: actionRequired.user!.id,
        alertType: actionRequired.alertType,
        created: actionRequired.created,
        actionRequiredJson: json.encode(actionRequired.toJson()).toString(),
        networkRequest: actionRequired.networkRequest == null ? null : actionRequired.networkRequest!.id,
        lastUpdate: actionRequired.lastUpdate);

    return retValue;
  }
}
