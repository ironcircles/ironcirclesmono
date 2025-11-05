import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/models/circlerecipetemplateingredient.dart';

CircleRecipeIngredient circleRecipeIngredientsFromJson(String str) =>
    CircleRecipeIngredient.fromJson(json.decode(str));

String circleRecipeIngredientsToJson(CircleRecipeIngredient data) =>
    json.encode(data.toJson());

class CircleRecipeIngredient {
  String? id;
  String? name;
  int order;
  String? seed;

  //DateTime created;

  //used to manage UI only
  TextEditingController? controller; // = TextEditingController();
  bool expanded;

  CircleRecipeIngredient({
    this.id,
    this.name,
    this.controller,
    this.expanded = false,
    this.order = 0,
    this.seed,
  });

  factory CircleRecipeIngredient.fromJson(Map<String, dynamic> json) =>
      CircleRecipeIngredient(
        id: json["_id"],
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

  static List<CircleRecipeIngredient> initFromTemplateIngredients(
      List<CircleRecipeTemplateIngredient> templateList) {
    List<CircleRecipeIngredient> retValue = [];

    for (CircleRecipeTemplateIngredient item in templateList) {
      CircleRecipeIngredient recipeIngredient = CircleRecipeIngredient(
        name: item.name,
        seed: item.seed,
        order: item.order,
      );

      retValue.add(recipeIngredient);
    }

    return retValue;
  }

  static bool deepCompareChanged(
      List<CircleRecipeIngredient>? a, List<CircleRecipeIngredient>? b) {
    if (a == null && b != null && b.isNotEmpty) {
      return true;
    } else if (b == null && a != null && a.isNotEmpty) {
      return true;
    } else if (a != null && b != null) {
      if (a.length != b.length) return true;

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

  static List<CircleRecipeIngredient> deepCopy(
      List<CircleRecipeIngredient> list) {
    List<CircleRecipeIngredient> copied = [];

    for (CircleRecipeIngredient sourceTask in list) {
      CircleRecipeIngredient newTask = CircleRecipeIngredient(
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

class CircleRecipeIngredientsCollection {
  final List<CircleRecipeIngredient> circleRecipeIngredients;

  CircleRecipeIngredientsCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : circleRecipeIngredients = (json[key] as List)
            .map((json) => CircleRecipeIngredient.fromJson(json))
            .toList();
}
