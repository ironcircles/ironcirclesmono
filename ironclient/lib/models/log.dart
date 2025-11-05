import 'dart:convert';

import 'package:flutter/material.dart';

Log logFromJson(String str) => Log.fromJson(json.decode(str));

String logToJson(Log data) => json.encode(data.toJson());

class Log {
  int? pk;
  String? user;
  String? circle;
  String? device;
  String type;
  String message;
  String stack;
  DateTime timeStamp;

  final GlobalKey key = GlobalKey();

  Log({
    this.pk,
    this.user,
    this.circle,
    this.device,
    this.type = 'error',
    required this.message,
    required this.stack,
    required this.timeStamp,
  });

  Map<String, dynamic> toJson() => {
        "user": user,
        "circle": circle,
        "device": device,
        "type": type,
        "message": message,
        "stack": stack,
        "timeStamp": timeStamp.toUtc().toString(),
      };

  Map<String, dynamic> toJsonSQL() => {
        "user": user,
        "circle": circle,
        "device": device,
        "type": type,
        "message": message,
        "stack": stack,
        "timeStamp": timeStamp.millisecondsSinceEpoch,
      };

  //from sqlite
  factory Log.fromJson(Map<String, dynamic> json) => Log(
        pk: json["pk"],
        user: json["user"],
        device: json["device"],
        circle: json["circle"],
        type: json["type"],
        message: json["message"],
        stack: json["stack"],
        timeStamp:
            DateTime.fromMillisecondsSinceEpoch(json["timeStamp"]).toLocal(),
      );
}

class LogCollection {
  final List<Log> logs;

  LogCollection.fromJSON(Map<String, dynamic> json, String key)
      : logs = (json[key] as List).map((json) => Log.fromJson(json)).toList();
}
