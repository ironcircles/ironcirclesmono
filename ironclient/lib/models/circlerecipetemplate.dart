import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';

CircleRecipeTemplate circleListTemplateFromJson(String str) =>
    CircleRecipeTemplate.fromJson(json.decode(str));

String circleListTemplateToJson(CircleRecipe data) =>
    json.encode(data.toJson());

class CircleRecipeTemplate /*extends CircleObject*/ {
  String? id;

  String? name;

  String? owner;

  DateTime? lastUpdate;

  DateTime? created;

  bool checkable;

  String crank;

  String body;

  List<RatchetIndex> ratchetIndexes;

  List<CircleRecipeTemplateIngredient>? ingredients;

  List<CircleRecipeTemplateInstruction>? instructions;

  String? prepTime;

  String? cookTime;

  String? totalTime;

  String? servings;

  String? notes;

  String signature;

  CircleImage? image;

  static const String BOXNAME = "circlelastupdate";

  //hitchhikers
  UserFurnace? userFurnace;
  //UserCircleCache userCircleCache;

  CircleRecipeTemplate({
    this.id,
    this.name,
    this.checkable = false,
    this.owner,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.notes,
    this.servings,
    this.crank = '',
    this.signature = '',
    this.body = '',
    required this.ratchetIndexes,
    this.lastUpdate,
    this.created,
    this.instructions,
    this.ingredients,
    this.image,
  });

  factory CircleRecipeTemplate.fromJson(Map<String, dynamic> json) =>
      CircleRecipeTemplate(
        id: json["_id"],
        name: json["name"],
        owner: json["owner"],
        prepTime: json["prepTime"],
        cookTime: json["cookTime"],
        totalTime: json["totalTime"],
        servings: json["servings"],
        notes: json["notes"],
        image:
            json["image"] == null ? null : CircleImage.fromJson(json["image"]),
        instructions:
            json["instructions"] == null
                ? null
                : CircleRecipeTemplateInstructionCollection.fromJSON(
                  json,
                  "instructions",
                ).circleRecipeTemplateInstructions,
        ingredients:
            json["ingredients"] == null
                ? null
                : CircleRecipeTemplateIngredientsCollection.fromJSON(
                  json,
                  "ingredients",
                ).circleRecipeTemplateIngredients,
        body: json["body"],
        crank: json["crank"],
        signature: json["signature"],
        ratchetIndexes:
            json["ratchetIndexes"] == null
                ? []
                : RatchetIndexCollection.fromJSON(
                  json,
                  "ratchetIndexes",
                ).ratchetIndexes,
        lastUpdate:
            json["lastUpdate"] == null
                ? null
                : DateTime.parse(json["lastUpdate"]).toLocal(),
        created:
            json["created"] == null
                ? null
                : DateTime.parse(json["created"]).toLocal(),
        //userVoted: options.u

        //options: List<CircleVoteOption>.from(json["options"].map((x) => x)),
      );

  factory CircleRecipeTemplate.blank() => CircleRecipeTemplate(
    name: '',
    prepTime: '',
    cookTime: '',
    totalTime: '',
    servings: '',
    notes: '',
    instructions: [],
    ratchetIndexes: [],
    ingredients: [],
    lastUpdate: null,
    created: null,
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "owner": owner,
    "prepTime": prepTime,
    "cookTime": cookTime,
    "totalTime": totalTime,
    "servings": servings,
    "notes": notes,
    "image": image == null ? null : image!.toJson(),
    "instructions":
        instructions == null
            ? null
            : List<dynamic>.from(instructions!.map((x) => x)),
    "ingredients":
        ingredients == null
            ? null
            : List<dynamic>.from(ingredients!.map((x) => x)),
    "body": body,
    "crank": crank,
    "signature": signature,
    "ratchetIndexes":
        ratchetIndexes.isEmpty
            ? null
            : List<dynamic>.from(ratchetIndexes.map((x) => x)),
    "created": created?.toUtc().toString(),
    "lastUpdate": lastUpdate?.toUtc().toString(),
  };

  revertEncryptedFields(CircleRecipe originalRecipe) {
    name = originalRecipe.name;
    prepTime = originalRecipe.prepTime;
    cookTime = originalRecipe.cookTime;
    totalTime = originalRecipe.totalTime;
    servings = originalRecipe.servings;
    notes = originalRecipe.notes;

    for (CircleRecipeTemplateIngredient encryptedIngredient in ingredients!) {
      for (CircleRecipeIngredient originalIngredient
          in originalRecipe.ingredients!) {
        if (originalIngredient.seed == encryptedIngredient.seed) {
          encryptedIngredient.name = originalIngredient.name;
          break;
        }
      }
    }

    for (CircleRecipeTemplateInstruction encryptedInstructions
        in instructions!) {
      for (CircleRecipeInstruction originalInstructions
          in originalRecipe.instructions!) {
        if (originalInstructions.seed == encryptedInstructions.seed) {
          encryptedInstructions.name = originalInstructions.name;
          break;
        }
      }
    }
  }

  CircleRecipeTemplate returnMaskedCopy() {
    var encoded = json.encode(this.toJson()).toString();
    return CircleRecipeTemplate.fromJson(json.decode(encoded));
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      name = json["name"];
      prepTime = json["prepTime"];
      cookTime = json["cookTime"];
      totalTime = json["totalTime"];
      servings = json["servings"];
      notes = json["notes"];

      for (CircleRecipeTemplateIngredient ingredient in ingredients!) {
        ingredient.name = json["ingredients"][ingredient.seed];
      }

      for (CircleRecipeTemplateInstruction instruction in instructions!) {
        instruction.name = json["instructions"][instruction.seed];
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplate.mapDecryptedFields: $err');
      throw (err);
    }
  }

  // static Future<Box<CircleRecipeTemplate>> _openBox(String boxName) async {
  //   return await Hive.openBox<CircleRecipeTemplate>(boxName);
  // }

  // static Future<List<CircleRecipeTemplate>> getAll(
  //   List<UserFurnace> userFurnaces,
  // ) async {
  //   List<CircleRecipeTemplate> retValue = [];
  //
  //   for (UserFurnace userFurnace in userFurnaces) {
  //     if (userFurnace.connected!) {
  //       Box<CircleRecipeTemplate> box = await _openBox(
  //         BOXNAME + userFurnace.userid!,
  //       );
  //
  //       List<CircleRecipeTemplate> list = box.values.toList();
  //
  //       //Add the screen hitchhiker
  //       for (CircleRecipeTemplate template in list) {
  //         template.userFurnace = userFurnace;
  //       }
  //
  //       retValue.addAll(list);
  //     }
  //   }
  //
  //   return retValue;
  // }

//   static Future<CircleRecipeTemplate> get(
//     String userID,
//     String templateID,
//   ) async {
//     Box<CircleRecipeTemplate> box = await _openBox(BOXNAME + userID);
//
//     CircleRecipeTemplate? retValue = box.get(
//       templateID,
//       defaultValue: CircleRecipeTemplate(ratchetIndexes: []),
//     );
//
//     return retValue!;
//   }
//
//   static Future<void> put(
//     String userID,
//     CircleRecipeTemplate circleRecipeTemplate,
//   ) async {
//     Box<CircleRecipeTemplate> box = await _openBox(BOXNAME + userID);
//
//     box.put(circleRecipeTemplate.id, circleRecipeTemplate);
//
//     return;
//   }
//
//   static Future<void> delete(String userID, String templateID) async {
//     Box<CircleRecipeTemplate> box = await _openBox(BOXNAME + userID);
//     box.delete(templateID);
//
//     return;
//   }
//
//   static Future<void> deleteAll(String userID) async {
//     Hive.deleteBoxFromDisk(BOXNAME + userID);
//   }
 }

class CircleRecipeTemplateCollection {
  final List<CircleRecipeTemplate> templates;

  CircleRecipeTemplateCollection.fromJSON(Map<String, dynamic> json, String key)
    : templates =
          (json[key] as List)
              .map((json) => CircleRecipeTemplate.fromJson(json))
              .toList();
}
