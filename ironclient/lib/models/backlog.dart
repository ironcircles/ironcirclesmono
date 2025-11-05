import 'dart:convert';

import 'package:ironcirclesapp/models/backlogreply.dart';
import 'package:ironcirclesapp/models/export_models.dart';

Backlog tutorialFromJson(String str) => Backlog.fromJson(json.decode(str));

class Backlog {
  User? creator;
  String? id;
  String summary;
  String description;
  String type;
  List<User>? upVotes;
  bool hideReplies;
  int? upVotesCount;
  int? version;
  String? status;
  List<BacklogReply> replies;

  //UI
  String voteLabel = '';

  Backlog({
    this.creator,
    this.upVotes,
    this.id,
    required this.summary,
    required this.description,
    required this.type,
    required this.replies,
    this.version,
    this.hideReplies = false,
    this.upVotesCount,
    this.status,
  });

  factory Backlog.fromJson(Map<String, dynamic> json) => Backlog(
        creator:
            json["creator"] == null ? null : User.fromJson(json["creator"]),
        upVotes: json["upVotes"] == null
            ? null
            : UserCollection.fromJSON(json, "upVotes").users,
        id: json["_id"],
        summary: json["summary"],
        hideReplies: json["hideReplies"] ?? false,
        description: json["description"],
        replies: json["replies"] == null
            ? []
            : BacklogReplyCollection.fromJSON(json).backlog,
        type: json["type"],
        version: json["version"],
        status: json["status"],
        upVotesCount: json["upVotesCount"],
      );

  Map<String, dynamic> toJson() => {
        "summary": summary,
        "type": type,
        "description": description,
      };


}

class BacklogCollection {
  final List<Backlog> backlog;

  BacklogCollection.fromJSON(Map<String, dynamic> json)
      : backlog = (json['backlog'] as List)
            .map((json) => Backlog.fromJson(json))
            .toList();
}
