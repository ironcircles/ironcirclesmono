import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleRecipe circleRecipeFromJson(String str) =>
    CircleRecipe.fromJson(json.decode(str));

String circleRecipeToJson(CircleRecipe data) => json.encode(data.toJson());

class CircleRecipe /*extends CircleObject*/ {
  String? name;
  String? prepTime;
  String? cookTime;
  String? totalTime;
  String? servings;
  String? notes;
  String? template;
  CircleImage? image;
  DateTime? lastUpdate;
  DateTime? created;

//  int itemChecked;
  List<CircleRecipeInstruction>? instructions = [];
  List<CircleRecipeIngredient>? ingredients = [];

  bool saveTemplate = true;
  bool imageChanged = false;

  CircleRecipe({
    this.name,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.notes,
    this.servings,
    this.instructions,
    this.ingredients,
    this.lastUpdate,
    this.created,
    this.template,
    this.image,
  });

  factory CircleRecipe.blank() => CircleRecipe(
      name: '',
      prepTime: '',
      cookTime: '',
      totalTime: '',
      servings: '',
      notes: '',
      template: '',
      instructions: [],
      ingredients: [],
      lastUpdate: null,
      image: null,
      created: null);

  factory CircleRecipe.fromJson(Map<String, dynamic> json) => CircleRecipe(
        name: json["name"],
        template: json["template"],
        prepTime: json["prepTime"],
        cookTime: json["cookTime"],
        totalTime: json["totalTime"],
        servings: json["servings"],
        notes: json["notes"] ?? '',
        image:
            json["image"] == null ? null : CircleImage.fromJson(json["image"]),
        instructions: json["instructions"] == null
            ? null
            : CircleRecipeInstructionCollection.fromJSON(json, "instructions")
                .circleRecipeInstructions,
        ingredients: json["ingredients"] == null
            ? null
            : CircleRecipeIngredientsCollection.fromJSON(json, "ingredients")
                .circleRecipeIngredients,
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.parse(json["created"]).toLocal(),
        //userVoted: options.u

        //options: Recipe<CircleVoteOption>.from(json["options"].map((x) => x)),
      );

  static bool deepCompareChanged(CircleRecipe a, CircleRecipe b) {
    if (a.name != null && a.name!.isNotEmpty && a.name != b.name)
      return true;
    else if (b.name != null && b.name!.isNotEmpty && a.name != b.name)
      return true;
    if (a.prepTime != null &&
        a.prepTime!.isNotEmpty &&
        a.prepTime != b.prepTime)
      return true;
    else if (b.prepTime != null &&
        b.prepTime!.isNotEmpty &&
        a.prepTime != b.prepTime) return true;
    if (a.cookTime != null &&
        a.cookTime!.isNotEmpty &&
        a.cookTime != b.cookTime)
      return true;
    else if (b.cookTime != null &&
        b.cookTime!.isNotEmpty &&
        a.cookTime != b.cookTime) return true;
    if (a.totalTime != null &&
        a.totalTime!.isNotEmpty &&
        a.totalTime != b.totalTime)
      return true;
    else if (b.totalTime != null &&
        b.totalTime!.isNotEmpty &&
        a.totalTime != b.totalTime) return true;
    if (a.servings != null &&
        a.servings!.isNotEmpty &&
        a.servings != b.servings)
      return true;
    else if (b.servings != null &&
        b.servings!.isNotEmpty &&
        a.servings != b.servings)
      return true;
    else if (a.notes != null && a.notes!.isNotEmpty && a.notes != b.notes)
      return true;
    else if (b.notes != null && b.notes!.isNotEmpty && a.notes != b.notes)
      return true;
    else if (a.image != b.image)
      return true;
    else if (CircleRecipeInstruction.deepCompareChanged(
        a.instructions, b.instructions))
      return true;
    else if (CircleRecipeIngredient.deepCompareChanged(
        a.ingredients, b.ingredients)) return true;

    return false;
  }

  static CircleRecipe deepCopy(CircleRecipe circleRecipe) {
    CircleRecipe? retValue;

    try {
      retValue = CircleRecipe(
          name: circleRecipe.name,
          template: circleRecipe.template,
          prepTime: circleRecipe.prepTime,
          cookTime: circleRecipe.cookTime,
          totalTime: circleRecipe.totalTime,
          servings: circleRecipe.servings,
          notes: circleRecipe.notes,
          image: circleRecipe.image == null
              ? null
              : CircleImage(
                  thumbnail: circleRecipe.image!.thumbnail,
                  thumbnailSize: circleRecipe.image!.thumbnailSize),

          //tasks: Recipe.from(circleRecipe.tasks),
          instructions: circleRecipe.instructions == null
              ? null
              : CircleRecipeInstruction.deepCopy(circleRecipe.instructions!),
          ingredients: circleRecipe.ingredients == null
              ? null
              : CircleRecipeIngredient.deepCopy(circleRecipe.ingredients!),
          lastUpdate: circleRecipe.lastUpdate,
          created: circleRecipe.created);

      retValue._initUIControls();

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipe.deepCopy: $err');
      rethrow;
    }
  }

  ingestDeepCopy(CircleRecipe circleRecipe) {
    name = circleRecipe.name;
    template = circleRecipe.template;
    prepTime = circleRecipe.prepTime;
    cookTime = circleRecipe.cookTime;
    totalTime = circleRecipe.totalTime;
    servings = circleRecipe.servings;
    notes = circleRecipe.notes;
    instructions = circleRecipe.instructions;
    ingredients = circleRecipe.ingredients;
    lastUpdate = circleRecipe.lastUpdate;
    created = circleRecipe.created;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "template": template,
        "prepTime": prepTime,
        "cookTime": cookTime,
        "totalTime": totalTime,
        "servings": servings,
        "notes": notes,
        "image": image?.toJson(),
        "instructions": instructions == null
            ? null
            : List<dynamic>.from(instructions!.map((x) => x)),
        "ingredients": ingredients == null
            ? null
            : List<dynamic>.from(ingredients!.map((x) => x)),
        "created": created?.toUtc().toString(),
        "lastUpdate":
            lastUpdate?.toUtc().toString(),
      };

  _initUIControls() {
    ingredients ??= [];

    instructions ??= [];

    for (CircleRecipeInstruction circleRecipeInstruction in instructions!) {
      circleRecipeInstruction.controller =
          TextEditingController(text: circleRecipeInstruction.name);
    }

    for (CircleRecipeIngredient circleRecipeIngredient in ingredients!) {
      circleRecipeIngredient.controller =
          TextEditingController(text: circleRecipeIngredient.name);
    }
  }

  void blankEncryptionFields() {
    name = '';
    prepTime = '';
    cookTime = '';
    totalTime = '';
    servings = '';
    notes = '';

    for (var item in ingredients!) {
      item.name = '';
    }

    for (var item in instructions!) {
      item.name = '';
    }
  }

  void revertEncryptionFields(CircleRecipe original) {
    name = original.name;
    prepTime = original.prepTime;
    cookTime = original.cookTime;
    totalTime = original.totalTime;
    servings = original.servings;
    notes = original.notes;

    for (CircleRecipeIngredient item in ingredients!) {
      for (CircleRecipeIngredient originalItem in original.ingredients!) {
        if (originalItem.seed == item.seed) {
          item.name = originalItem.name;
          break;
        }
      }
    }

    for (CircleRecipeInstruction item in instructions!) {
      for (CircleRecipeInstruction originalItem in original.instructions!) {
        if (originalItem.seed == item.seed) {
          item.name = originalItem.name;
          break;
        }
      }
    }
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      var recipe = json["recipe"];

      name = recipe["name"];
      prepTime = recipe["prepTime"];
      cookTime = recipe["cookTime"];
      totalTime = recipe["totalTime"];
      servings = recipe["servings"];
      notes = recipe["notes"] ?? '';

      for (CircleRecipeIngredient ingredient in ingredients!) {
        ingredient.name = recipe["ingredients"][ingredient.seed];
      }

      for (CircleRecipeInstruction instruction in instructions!) {
        instruction.name = recipe["instructions"][instruction.seed];
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipe.mapDecryptedFields: $err');
      rethrow;
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = <String, dynamic>{};

      retValue["name"] = name;
      retValue["prepTime"] = prepTime;
      retValue["cookTime"] = cookTime;
      retValue["totalTime"] = totalTime;
      retValue["servings"] = servings;
      retValue["notes"] = notes;

      Map<String, dynamic> reducedIngredients = <String, dynamic>{};

      for (CircleRecipeIngredient item in ingredients!) {
        reducedIngredients[item.seed!] = item.name;
      }

      retValue["ingredients"] = reducedIngredients;

      Map<String, dynamic> reducedInstructions = <String, dynamic>{};

      for (CircleRecipeInstruction item in instructions!) {
        reducedInstructions[item.seed!] = item.name;
      }

      retValue["instructions"] = reducedInstructions;

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipe.fetchFieldsToEncrypt: $err');
      rethrow;
    }
  }

  static CircleRecipe initFromTemplate(CircleRecipeTemplate template) {
    try {
      late CircleRecipe circleRecipe;

      if (template.id == null) {
        circleRecipe = CircleRecipe.blank();
      } else {
        circleRecipe = CircleRecipe(
          //TODO add image copy
          template: template.id,
          name: template.name,
          prepTime: template.prepTime,
          cookTime: template.cookTime,
          totalTime: template.totalTime,
          servings: template.servings,
          notes: template.notes,
          instructions: CircleRecipeInstruction.initFromTemplateInstructions(
              template.instructions!),
          ingredients: CircleRecipeIngredient.initFromTemplateIngredients(
              template.ingredients!),
        );
      }

      circleRecipe._initUIControls();

      return circleRecipe;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipe.initFromTemplate: $err');
      rethrow;
    }
  }

  addIngredient() {
    CircleRecipeIngredient circleRecipeIngredient = CircleRecipeIngredient(
        order: ingredients!.length + 1, controller: TextEditingController());

    ingredients!.add(circleRecipeIngredient);
  }

  addInstruction() {
    CircleRecipeInstruction circleRecipeInstruction = CircleRecipeInstruction(
        order: instructions!.length + 1, controller: TextEditingController());

    instructions!.add(circleRecipeInstruction);
  }

  init() {
    ingredients = [];
    instructions = [];

    addIngredient();
    addInstruction();
    addIngredient();
    addInstruction();

    _initUIControls();
  }

  disposeUIControls() {
    /*
    for (CircleRecipeTask circleRecipeTask in tasks) {
      if (circleRecipeTask.controller != null)
        circleRecipeTask.controller.dispose();
    }

     */
  }
}
