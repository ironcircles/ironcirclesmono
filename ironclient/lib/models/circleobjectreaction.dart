// To parse this JSON data, do
//
//     final circleObject = circleObjectFromJson(jsonString);


import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/user.dart';

class CircleObjectReaction {
  final List<User> users;
  final int? index;
  final String? emoji;
  String? id;

  CircleObjectReaction({this.id, required this.index,
    required this.emoji, required this.users});

  factory CircleObjectReaction.fromJson(Map<String, dynamic> jsonMap) =>
      CircleObjectReaction(
        id: jsonMap["_id"],
        index: jsonMap["index"],
        emoji: jsonMap["emoji"],
        users: jsonMap["users"] == null ? [] : UserCollection.fromJSON(jsonMap, "users").users,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "index": index,
        "emoji": emoji,
        "users": List<dynamic>.from(users.map((x) => x)),
      };
}


class CircleObjectReactionCollection {
  final List<CircleObjectReaction> reactions;

  CircleObjectReactionCollection.fromJSON(Map<String, dynamic> json, String key)
      : reactions = (json[key] as List).map((json) => CircleObjectReaction.fromJson(json)).toList();

  CircleObjectReactionCollection.fromJSONNoKey(Map<String, dynamic> json)
      : reactions = (json as List).map((json) => CircleObjectReaction.fromJson(json)).toList();

}
