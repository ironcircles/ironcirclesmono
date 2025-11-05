import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class SwipePatternAttempt {
  Circle? circle;
  User? user;
  Device? device;
  DateTime attemptDate;
  String? guardedItemDisplayName;

  SwipePatternAttempt({
    required this.circle,
    required this.user,
    required this.device,
    required this.attemptDate,
    this.guardedItemDisplayName,
  });

  factory SwipePatternAttempt.fromJson(Map<String, dynamic> json) => SwipePatternAttempt(
    circle: json["circle"] == null ? null : json["circle"].runtimeType == String ? Circle(id: json["circle"]) : Circle.fromJson(json["circle"]),
    user: json["user"] == null ? null : json["user"].runtimeType == String ? User(id: json["user"]) : User.fromJson(json["user"]),
    device: json["device"] == null ? null : json["device"].runtimeType == String ? Device(id: json["device"]) : Device.fromMemberJson(json["device"]),
    attemptDate: DateTime.parse(json["attemptDate"]),
  );

   Map<String, dynamic> toJson() => {
    "circle": circle,
    "user": user,
    "device": device,
    "attemptDate": attemptDate.toIso8601String(),
  };
}

class SwipePatternAttemptCollection {
  final List<SwipePatternAttempt> swipePatternAttempts;

  SwipePatternAttemptCollection.fromJSON(Map<String, dynamic> json, String key)
      : swipePatternAttempts = (json[key] as List)
      .map((json) => SwipePatternAttempt.fromJson(json))
      .toList();
}
