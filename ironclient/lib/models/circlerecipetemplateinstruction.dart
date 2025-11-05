import 'dart:convert';

import 'package:flutter/material.dart';


CircleRecipeTemplateInstruction circleRecipeTemplateInstructionFromJson(
        String str) =>
    CircleRecipeTemplateInstruction.fromJson(json.decode(str));

String circleRecipeTemplateInstructionToJson(
        CircleRecipeTemplateInstruction data) =>
    json.encode(data.toJson());


class CircleRecipeTemplateInstruction {

  String? id;

  String? name;

  int order;

  String? seed;

  //DateTime created;

  //used to manage UI only
  TextEditingController? controller; // = TextEditingController();
  bool expanded;

  CircleRecipeTemplateInstruction({
    this.id,
    this.name,
    this.controller,
    this.expanded = false,
    this.order = 0,
    this.seed,
  });

  factory CircleRecipeTemplateInstruction.fromJson(Map<String, dynamic> json) =>
      CircleRecipeTemplateInstruction(
        id: json["_id"],
        //complete: json["complete"] == 'false' ? false : true,
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

  static List<CircleRecipeTemplateInstruction> deepCopy(
      List<CircleRecipeTemplateInstruction> list) {
    List<CircleRecipeTemplateInstruction> copied = [];

    for (CircleRecipeTemplateInstruction sourceTask in list) {
      CircleRecipeTemplateInstruction newTask = CircleRecipeTemplateInstruction(
          id: sourceTask.id,
          name: sourceTask.name,
          controller: sourceTask.controller,
          expanded: sourceTask.expanded,
          order: sourceTask.order);

      copied.add(newTask);
    }

    return copied;
  }
}

class CircleRecipeTemplateInstructionCollection {
  final List<CircleRecipeTemplateInstruction> circleRecipeTemplateInstructions;

  CircleRecipeTemplateInstructionCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : circleRecipeTemplateInstructions = (json[key] as List)
            .map((json) => CircleRecipeTemplateInstruction.fromJson(json))
            .toList();
}
