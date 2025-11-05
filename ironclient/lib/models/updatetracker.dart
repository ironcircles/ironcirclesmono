import 'dart:convert';

import 'package:flutter/material.dart';

UpdateTracker updateTrackerFromJson(String str) =>
    UpdateTracker.fromJson(json.decode(str));

String logToJson(UpdateTracker data) => json.encode(data.toJson());

enum UpdateTrackerType { credentialUpgrade, wall, objectDelete, iosDeviceID }

class UpdateTracker {
  int? pk;
  UpdateTrackerType type;
  bool value;

  final GlobalKey key = GlobalKey();

  UpdateTracker({
    this.pk,
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "type": type.index,
        "value": value ? 1 : 0,
      };

  factory UpdateTracker.fromJson(Map<String, dynamic> json) => UpdateTracker(
      pk: json["pk"],
      type: UpdateTrackerType.values[json["type"]],
      value: json["value"] == 1 ? true : false);
}

class UpdateTrackerCollection {
  final List<UpdateTracker> logs;

  UpdateTrackerCollection.fromJSON(Map<String, dynamic> json, String key)
      : logs = (json[key] as List)
            .map((json) => UpdateTracker.fromJson(json))
            .toList();
}
