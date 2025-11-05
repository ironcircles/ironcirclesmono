// To parse this JSON data, do
//
//     final circleObject = circleObjectFromJson(jsonString);

import 'dart:convert';

NotificationTracker notificationTrackerFromJson(String str) =>
    NotificationTracker.fromJson(json.decode(str));

String notificationTrackerToJson(NotificationTracker data) =>
    json.encode(data.toJson());

class NotificationTracker {
  String? id;
  DateTime? loggedDate;

  NotificationTracker({
    this.id,
    this.loggedDate,
  }) {
    if (loggedDate == null) loggedDate = DateTime.now();
  }

  factory NotificationTracker.fromJson(Map<String, dynamic> json) =>
      NotificationTracker(
        id: json["id"],
        loggedDate: json["loggedDate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["loggedDate"]).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "loggedDate":
            loggedDate?.millisecondsSinceEpoch,
      };
}

class NotificationTrackerCollection {
  final List<NotificationTracker> notificationTrackerObjects;

  NotificationTrackerCollection.fromJSON(Map<String, dynamic> json, String key)
      : notificationTrackerObjects = (json[key] as List)
            .map((json) => NotificationTracker.fromJson(json))
            .toList();
}
