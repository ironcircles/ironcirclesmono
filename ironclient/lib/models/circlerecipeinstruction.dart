import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/models/circlerecipetemplateinstruction.dart';

CircleRecipeInstruction circleRecipeInstructionFromJson(String str) =>
    CircleRecipeInstruction.fromJson(json.decode(str));

String circleRecipeInstructionToJson(CircleRecipeInstruction data) =>
    json.encode(data.toJson());

class CircleRecipeInstruction {
  String? id;
  String? name;
  int order;
  String? seed;

  //DateTime created;

  //used to manage UI only
  TextEditingController? controller; // = TextEditingController();
  bool expanded;

  CircleRecipeInstruction({
    this.id,
    this.name,
    this.controller,
    this.expanded = false,
    this.order = 0,
    this.seed,
  });

  factory CircleRecipeInstruction.fromJson(Map<String, dynamic> json) =>
      CircleRecipeInstruction(
        id: json["_id"],
        seed: json["seed"],
        name: json["name"],
        order: json["order"] == null ? null : json["order"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "seed": seed,
        "order": order,
        /*"created": created == null ? null : created.toUtc().toString(),*/
      };

  static bool deepCompareChanged(
      List<CircleRecipeInstruction>? a, List<CircleRecipeInstruction>? b) {
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
        if (a[i].name != b[i].name)
          return true;
        else if (a[i].order != b[i].order)
          return true;
        else if (a[i].expanded != b[i].expanded) return true;
      }
    }

    return false;
  }

  static List<CircleRecipeInstruction> deepCopy(
      List<CircleRecipeInstruction> list) {
    List<CircleRecipeInstruction> copied = [];

    for (CircleRecipeInstruction sourceTask in list) {
      CircleRecipeInstruction newTask = CircleRecipeInstruction(
          id: sourceTask.id,
          name: sourceTask.name,
          controller: sourceTask.controller,
          expanded: sourceTask.expanded,
          order: sourceTask.order);

      copied.add(newTask);
    }

    return copied;
  }

  static List<CircleRecipeInstruction> initFromTemplateInstructions(
      List<CircleRecipeTemplateInstruction> templateList) {
    List<CircleRecipeInstruction> retValue = [];

    for (CircleRecipeTemplateInstruction item in templateList) {
      CircleRecipeInstruction recipeInstruction = CircleRecipeInstruction(
        name: item.name,
        seed: item.seed,
        order: item.order,
      );

      retValue.add(recipeInstruction);
    }

    return retValue;
  }
}

class CircleRecipeInstructionCollection {
  final List<CircleRecipeInstruction> circleRecipeInstructions;

  CircleRecipeInstructionCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : circleRecipeInstructions = (json[key] as List)
            .map((json) => CircleRecipeInstruction.fromJson(json))
            .toList();
}
