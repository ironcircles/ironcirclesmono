import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';

BacklogReply backlogReplyFromJson(String str) =>
    BacklogReply.fromJson(json.decode(str));

class BacklogReply {
  User user;
  String? id;
  //String username;
  String reply;
  DateTime? created;
  DateTime? lastUpdate;

  //UI
  String voteLabel = '';

  BacklogReply({
    required this.user,
    this.id,
    //required this.username,
    required this.reply,
    this.created,
    this.lastUpdate,
  });

  factory BacklogReply.fromJson(Map<String, dynamic> json) => BacklogReply(
        user: User.fromJson(json["user"]),
        id: json["_id"],
        //username: json["username"],
        reply: json["reply"],
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        //"username": username,
        "reply": reply,
      };
}

class BacklogReplyCollection {
  final List<BacklogReply> backlog;

  BacklogReplyCollection.fromJSON(Map<String, dynamic> json)
      : backlog = (json['replies'] as List)
            .map((json) => BacklogReply.fromJson(json))
            .toList();
}
