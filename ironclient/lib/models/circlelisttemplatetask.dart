import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleListTemplateTask circleListTemplateTaskFromJson(String str) =>
    CircleListTemplateTask.fromJson(json.decode(str));

String circleListTemplateTaskToJson(CircleListTask data) =>
    json.encode(data.toJson());

class CircleListTemplateTask {
  String? id;
  String? seed;
  bool? complete;
  User? assignee;
  User? completedBy;
  String? name;
  DateTime? completed;
  DateTime? due;
  int order;
  //DateTime created;

  //used to manage UI only
  TextEditingController? controller; // = TextEditingController();
  bool expanded;

  CircleListTemplateTask(
      {this.id,
      this.seed,
      this.complete = false,
      this.completed,
      this.assignee,
      this.completedBy,
      this.name,
      this.due,
      this.controller,
      this.expanded = false,
      this.order = 0});

  factory CircleListTemplateTask.fromJson(Map<String, dynamic> json) =>
      CircleListTemplateTask(
        id: json["_id"],
        seed: json["seed"],
        //complete: json["complete"] == 'false' ? false : true,
        complete: json["complete"],
        assignee:
            json["assignee"] == null ? null : User.fromJson(json["assignee"]),
        completedBy: json["completedBy"] == null
            ? null
            : User.fromJson(json["completedBy"]),
        name: json["name"],
        completed: json["completed"] == null
            ? null
            : DateTime.parse(json["completed"]).toLocal(),

        order: json["order"] == null ? null : json["order"],
        due: json["due"] == null ? null : DateTime.parse(json["due"]).toLocal(),
        /*created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),*/
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "seed": seed,
        "complete": complete,
        "assignee": assignee?.toJson(),
        "completedBy": completedBy?.toJson(),
        "name": name,
        "completed": completed?.toUtc().toString(),
        "due": due?.toUtc().toString(),
        "order": order,
        /*"created": created == null ? null : created.toUtc().toString(),*/
      };
}

class CircleListTemplateTaskCollection {
  final List<CircleListTemplateTask> circleListTaskMasters;

  CircleListTemplateTaskCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : circleListTaskMasters = (json[key] as List)
            .map((json) => CircleListTemplateTask.fromJson(json))
            .toList();
}
