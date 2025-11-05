import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';

CircleListTemplate circleListTemplateFromJson(String str) =>
    CircleListTemplate.fromJson(json.decode(str));

String circleListTemplateToJson(CircleList data) => json.encode(data.toJson());

class CircleListTemplate /*extends CircleObject*/ {
  String? id;
  String? name;
  String? owner;
  DateTime? lastUpdate;
  DateTime? created;
  bool checkable;
  String crank;
  String signature;
  String body;
  List<RatchetIndex> ratchetIndexes;

//  int itemChecked;
  List<CircleListTemplateTask>? tasks;

  //hitchhikers
  UserFurnace? userFurnace;
  //UserCircleCache userCircleCache;

  CircleListTemplate({
    this.id,
    this.name,
    this.checkable = false,
    this.owner,
    this.tasks,
    this.crank = '',
    this.signature = '',
    this.body = '',
    required this.ratchetIndexes,
    this.lastUpdate,
    this.created,
  });

  factory CircleListTemplate.fromJson(Map<String, dynamic> json) =>
      CircleListTemplate(
        id: json["_id"],
        name: json["name"],
        owner: json["owner"],
        tasks: json["tasks"] == null
            ? null
            : CircleListTemplateTaskCollection.fromJSON(json, "tasks")
                .circleListTaskMasters,
        body: json["body"],
        crank: json["crank"],
        signature: json["signature"],
        ratchetIndexes: json["ratchetIndexes"] == null
            ? []
            : RatchetIndexCollection.fromJSON(json, "ratchetIndexes")
                .ratchetIndexes,
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),
        //userVoted: options.u

        //options: List<CircleVoteOption>.from(json["options"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "owner": owner,
        "tasks":
            tasks == null ? null : List<dynamic>.from(tasks!.map((x) => x)),
        "body": body,
        "crank": crank,
        "signature": signature,
        "ratchetIndexes": ratchetIndexes.isEmpty
            ? null
            : List<dynamic>.from(ratchetIndexes.map((x) => x)),
        "created": created?.toUtc().toString(),
        "lastUpdate":
            lastUpdate?.toUtc().toString(),
      };

  revertEncryptedFields(CircleList circleList) {
    name = circleList.name;

    for (CircleListTemplateTask encryptedTask in tasks!) {
      for (CircleListTask originalTask in circleList.tasks!) {
        if (originalTask.seed == encryptedTask.seed) {
          encryptedTask.name = originalTask.name;
          break;
        }
      }
    }
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    name = json["name"];

    for (CircleListTemplateTask task in tasks!) {
      task.name = json["tasks"][task.seed];
    }
  }
}

class CircleListTemplateCollection {
  final List<CircleListTemplate> circleListTemplates;

  CircleListTemplateCollection.fromJSON(Map<String, dynamic> json, String key)
      : circleListTemplates = (json[key] as List)
            .map((json) => CircleListTemplate.fromJson(json))
            .toList();
}
