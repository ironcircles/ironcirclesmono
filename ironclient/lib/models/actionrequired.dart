import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';


ActionRequired circleObjectFromJson(String str) =>
    ActionRequired.fromJson(json.decode(str));

String circleObjectToJson(CircleObject data) => json.encode(data.toJson());

class ActionRequired {
  String? id;
  User? user;
  User? resetUser;
  User? member;
  String? resetFragment;
  String? alert;
  int? alertType;
  DateTime? lastUpdate;
  DateTime? created;
  String? time;
  String? date;
  RatchetKey? ratchetPublicKey;
  NetworkRequest? networkRequest;

  //hitchhikers
  UserFurnace? userFurnace;

  ActionRequired({
    this.id,
    this.user,
    this.resetUser,
    this.member,
    this.resetFragment,
    this.alert,
    this.alertType,
    this.lastUpdate,
    this.ratchetPublicKey,
    this.created,
    this.date,
    this.time,
    this.networkRequest,
  });

  factory ActionRequired.fromJson(Map<String, dynamic> json) =>
      ActionRequired(
        id: json["_id"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        resetUser:
            json["resetUser"] == null ? null : User.fromJson(json["resetUser"]),
        member: json["member"] == null ? null : User.fromJson(json["member"]),
        ratchetPublicKey: json["ratchetPublicKey"] == null
            ? null
            : RatchetKey.fromJson(json["ratchetPublicKey"]),
        alert: json["alert"],
        resetFragment: json["resetFragment"],
        alertType: json["alertType"],
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),
        date: json["created"] == null
            ? null
            : DateFormat.yMMMd()
                .format(DateTime.parse(json["created"]).toLocal()),
        time: json["created"] == null
            ? null
            : DateFormat.jm().format(DateTime.parse(json["created"]).toLocal()),
        networkRequest: json["networkRequest"] == null
            ? null
            : NetworkRequest.fromJson(json["networkRequest"]),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user": user?.toJson(),
        "resetUser": resetUser?.toJson(),
        "member": member?.toJson(),
        "ratchetPublicKey":
            ratchetPublicKey?.toJson(),
        "resetFragment": resetFragment,
        "alert": alert,
        "alertType": alertType,
        "created": created?.toUtc().toString(),
        "lastUpdate":
            lastUpdate?.toUtc().toString(),
        "networkRequest":
            networkRequest?.toJson(),
      };

  String getCreatedUTC() {
    return created!.toUtc().toString();
  }
}

class ActionRequiredCollection {
  final List<ActionRequired> actionRequiredObjects;

  ActionRequiredCollection.fromJSON(Map<String, dynamic> json, String key)
      : actionRequiredObjects = (json[key] as List)
            .map((json) => ActionRequired.fromJson(json))
            .toList();
}
