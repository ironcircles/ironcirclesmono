import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleListTask circleListTaskFromJson(String str) =>
    CircleListTask.fromJson(json.decode(str));

String circleListTaskToJson(CircleListTask data) => json.encode(data.toJson());

class CircleListTask {
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
  FocusNode? focusNode;
  bool expanded;
  bool? originalComplete;

  CircleListTask(
      {this.id,
      this.seed,
      this.complete = false,
      this.completed,
      this.assignee,
      this.completedBy,
      this.name,
      this.due,
      this.controller,
      this.focusNode,
      this.expanded = false,
      this.originalComplete,
      this.order = 0});

  factory CircleListTask.fromJson(Map<String, dynamic> json) => CircleListTask(
        id: json["_id"],
        seed: json["seed"],
        //complete: json["complete"] == 'false' ? false : true,
        complete: json["complete"],
        originalComplete: json["complete"],
        assignee:
            json["assignee"] == null ? null : User.fromJson(json["assignee"]),
        completedBy: json["completedBy"] == null
            ? null
            : User.fromJson(json["completedBy"]),
        name: json["name"],
        completed: json["completed"] == null
            ? null
            : DateTime.parse(json["completed"]).toLocal(),

        order: json["order"],
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

  static bool deepCompareChanged(
      List<CircleListTask>? a, List<CircleListTask>? b) {
    if (a == null && b != null && b.isNotEmpty) {
      return true;
    } else if (b == null && a != null && a.isNotEmpty) {
      return true;
    } else if (a != null && b != null) {
      if (a.length != b.length) {
        return true;
      }

      a.sort((a, b) => a.order.compareTo(b.order));
      b.sort((a, b) => a.order.compareTo(b.order));

      for (int i = 0; i < a.length; i++) {
        int bIndex = b.indexWhere((element) => element.seed == a[i].seed);

        ///Something was removed
        if (bIndex == -1) {
          return true;
        }

        if (a[i].complete != b[bIndex].complete)
          return true;
        else if (a[i].assignee != b[bIndex].assignee)
          return true;
        else if (a[i].completedBy != b[bIndex].completedBy)
          return true;
        else if (a[i].completed != b[bIndex].completed)
          return true;
        else if (a[i].name != b[bIndex].name)
          return true;
        else if (a[i].due != b[bIndex].due)
          return true;
        else if (a[i].order != b[bIndex].order) return true;
      }
    }

    return false;
  }

  static List<CircleListTask> deepCopyTasks(List<CircleListTask> tasks) {
    List<CircleListTask> copied = [];

    for (CircleListTask sourceTask in tasks) {
      CircleListTask newTask = CircleListTask(
          id: sourceTask.id,
          seed: sourceTask.seed,
          complete: sourceTask.complete,
          originalComplete: sourceTask.complete,
          completed: sourceTask.completed,
          assignee: sourceTask.assignee,
          completedBy: sourceTask.completedBy,
          name: sourceTask.name,
          due: sourceTask.due,
          controller: sourceTask.controller,
          expanded: sourceTask.expanded,
          order: sourceTask.order);

      copied.add(newTask);
    }

    return copied;
  }

  static List<CircleListTask> initFromTemplateTaskList(
      List<CircleListTemplateTask> templateTasks) {
    List<CircleListTask> retValue = [];

    for (CircleListTemplateTask templateTask in templateTasks) {
      CircleListTask circleListTask = CircleListTask(
          name: templateTask.name,
          seed: templateTask.seed,
          order: templateTask.order,
          assignee: templateTask.assignee);

      retValue.add(circleListTask);
    }

    return retValue;
  }
}

class CircleListTaskCollection {
  final List<CircleListTask> circleListTasks;

  CircleListTaskCollection.fromJSON(Map<String, dynamic> json, String key)
      : circleListTasks = (json[key] as List)
            .map((json) => CircleListTask.fromJson(json))
            .toList();
}
