import 'dart:convert';

import 'package:flutter/cupertino.dart';


CircleRecipeTemplateIngredient circleRecipeTemplateIngredientsFromJson(
        String str) =>
    CircleRecipeTemplateIngredient.fromJson(json.decode(str));

String circleRecipeTemplateIngredientsToJson(
        CircleRecipeTemplateIngredient data) =>
    json.encode(data.toJson());


class CircleRecipeTemplateIngredient {

  String? id;

  String? name;

  int order;

  String? seed;

  //DateTime created;

  //used to manage UI only
  TextEditingController? controller; // = TextEditingController();
  bool expanded;

  CircleRecipeTemplateIngredient({
    this.id,
    this.name,
    this.controller,
    this.expanded = false,
    this.order = 0,
    this.seed,
  });

  factory CircleRecipeTemplateIngredient.fromJson(Map<String, dynamic> json) =>
      CircleRecipeTemplateIngredient(
        id: json["_id"],
        //complete: json["complete"] == 'false' ? false : true,
        seed: json["seed"],
        name: json["name"],

        order: json["order"] == null ? null : json["order"],

        /*created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),*/
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
    "seed": seed,
        "order": order,
        /*"created": created == null ? null : created.toUtc().toString(),*/
      };

  static List<CircleRecipeTemplateIngredient> deepCopy(
      List<CircleRecipeTemplateIngredient> list) {
    List<CircleRecipeTemplateIngredient> copied = [];

    for (CircleRecipeTemplateIngredient sourceTask in list) {
      CircleRecipeTemplateIngredient newTask = CircleRecipeTemplateIngredient(
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

class CircleRecipeTemplateIngredientsCollection {
  final List<CircleRecipeTemplateIngredient> circleRecipeTemplateIngredients;

  CircleRecipeTemplateIngredientsCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : circleRecipeTemplateIngredients = (json[key] as List)
            .map((json) => CircleRecipeTemplateIngredient.fromJson(json))
            .toList();
}
