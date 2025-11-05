// To parse this JSON data, do
//
//     final circleAgoraCall = circleAgoraCallFromJson(jsonString);

import 'dart:convert';

CircleAgoraCall circleAgoraCallFromJson(String str) => CircleAgoraCall.fromJson(json.decode(str));

String circleAgoraCallToJson(CircleAgoraCall data) => json.encode(data.toJson());

class CircleAgoraCall {
  int? pk;
  String channelName;
  String token;
  int agoraUserID;
  bool active;
  DateTime? startTime;
  DateTime? endTime;
  String? userID;
  String? circleID;

  CircleAgoraCall({
    this.pk,
    this.active = true,
    this.agoraUserID = 0,
    this.channelName = '',
    this.token = '',
    this.startTime,
    this.endTime,
    this.userID,
    this.circleID,
  });

  factory CircleAgoraCall.fromJson(Map<String, dynamic> json) => CircleAgoraCall(
        pk: json["pk"],
        active: json["active"] ?? true,
        agoraUserID: json["agoraUserID"] ?? 0,
        channelName: json["channelName"] ?? '',
        token: json["token"] ?? '',
        startTime: json["startTime"] == null ? null : DateTime.parse(json["startTime"]).toLocal(),
        endTime: json["endTime"] == null ? null : DateTime.parse(json["endTime"]).toLocal(),
        userID: json["userID"],
        circleID: json["circleID"],
      );

  Map<String, dynamic> toJson() => {
        "pk": pk,
        "active": active,
        "agoraUserID": agoraUserID,
        "channelName": channelName,
        "token": token,
        "startTime": startTime?.toIso8601String(),
        "endTime": endTime?.toIso8601String(),
        "userID": userID,
        "circleID": circleID,
      };
}
