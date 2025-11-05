import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/circlerecipetemplate_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class CircleRecipeTemplateBloc {
  final _circleRecipeTemplateService = CircleRecipeTemplateService();

  final _circleRecipeTemplate = PublishSubject<List<CircleRecipeTemplate>>();
  Stream<List<CircleRecipeTemplate>> get circleRecipeTemplate =>
      _circleRecipeTemplate.stream;

  final _deleted = PublishSubject<CircleRecipeTemplate>();
  Stream<CircleRecipeTemplate> get deleted => _deleted.stream;

  final _upsert = PublishSubject<CircleRecipeTemplate>();
  Stream<CircleRecipeTemplate> get upsertFinished => _upsert.stream;

  /// Initial load from a screen
  get(List<UserFurnace> userFurnaces, bool initialSync) async {
    try {
      //send the cached results first in case there is no internet
      if (initialSync) sinkCache(userFurnaces);

      List<CircleRecipeTemplate> circleRecipeTemplates =
          await _circleRecipeTemplateService.getTemplates(userFurnaces);

      if (circleRecipeTemplates.isEmpty) sinkCache(userFurnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleRecipeTemplateBloc.get: $error");
      _circleRecipeTemplate.sink.addError(error);
    }
  }

  put(CircleRecipe circleRecipe, UserFurnace userFurnace) async {
    try {
      for (CircleRecipeIngredient item in circleRecipe.ingredients!) {
        item.seed = const Uuid().v4();
      }

      for (CircleRecipeInstruction item in circleRecipe.instructions!) {
        item.seed = const Uuid().v4();
      }

      CircleRecipeTemplate circleRecipeTemplate =
          await _circleRecipeTemplateService.put(circleRecipe, userFurnace);

      _upsert.sink.add(circleRecipeTemplate);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeTemplate.put: $err');
      _upsert.sink.addError(err);
    }
  }

  /// Sink top 500 from cache
  void sinkCache(List<UserFurnace> userFurnaces) async {
    // DateTime retValue;

    try {
      // List<CircleRecipeTemplate> sinkValues =
      //     await CircleRecipeTemplate.getAll(userFurnaces);

     // if (sinkValues.isNotEmpty) _circleRecipeTemplate.sink.add(sinkValues);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleRecipeTemplateBloc._sinkCache: $error');
      throw (error);
    }
  }

  /// Delete a Recipe
  delete(CircleRecipeTemplate circleRecipeTemplate) async {
    try {
      // if (circleRecipeTemplate.id != null) {
      //   CircleRecipeTemplate.delete(circleRecipeTemplate.userFurnace!.userid!,
      //       circleRecipeTemplate.id!);
      //
      //   _deleted.sink.add(circleRecipeTemplate);
      //
      //   //delete the object from the furnace
      //   await _circleRecipeTemplateService.delete(
      //       circleRecipeTemplate.userFurnace!, circleRecipeTemplate);
      //
      //   //_deleted.sink.add(circleRecipeTemplate);
      //
      // }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleRecipeTemplateBloc.delete: $error");
      _circleRecipeTemplate.sink.addError(error);
    }
  }

  /// Delete a Recipe
  deleteAll(String userID) async {
    try {
    //  CircleRecipeTemplate.deleteAll(userID);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleRecipeTemplateBloc.deleteAll: $error");
      _circleRecipeTemplate.sink.addError(error);
    }
  }

  dispose() async {
    await _deleted.drain();
    _deleted.close();

    await _circleRecipeTemplate.drain();
    _circleRecipeTemplate.close();

    await _upsert.drain();
    _upsert.close();
  }
}
