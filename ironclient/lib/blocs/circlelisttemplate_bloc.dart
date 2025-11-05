// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circlelistmaster.dart';
import 'package:ironcirclesapp/services/circlelisttemplate_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class CircleListTemplateBloc {
  final _circleListTemplateService = CircleListTemplateService();

  final _circleListTemplate = PublishSubject<List<CircleListTemplate>>();
  Stream<List<CircleListTemplate>> get circleListTemplate =>
      _circleListTemplate.stream;

  final _deleted = PublishSubject<CircleListTemplate>();
  Stream<CircleListTemplate> get deleted => _deleted.stream;

  final _upsert = PublishSubject<CircleListTemplate>();
  Stream<CircleListTemplate> get upsertFinished => _upsert.stream;

  upsert(CircleList circleList, UserFurnace userFurnace) async {
    try {
      for (CircleListTask task in circleList.tasks!) {
        task.seed = const Uuid().v4();
      }

      CircleListTemplate circleListTemplate =
          await _circleListTemplateService.upsert(circleList, userFurnace);

      _upsert.sink.add(circleListTemplate);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleListTemplate.upsert: $err');
      _upsert.sink.addError(err);
    }
  }

  /// Initial load from a screen
  initalLoad(List<UserFurnace> userFurnaces, bool initialSync) async {
    try {
      //send the cached results first in case there is no internet
      if (initialSync) sinkCache(userFurnaces);

      List<CircleListTemplate> circleListTemplates =
          await _circleListTemplateService.getTemplates(userFurnaces);

      if (circleListTemplates.isEmpty) sinkCache(userFurnaces);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleListTemplateBloc.initalLoad: " + error.toString());
      _circleListTemplate.sink.addError(error);
    }
  }

  /// Sink top 500 from cache
  void sinkCache(List<UserFurnace> userFurnaces) async {
    // DateTime retValue;

    try {
      List<CircleListMasterCache>? circleListTemplatesCache;

      //grab Template lists
      circleListTemplatesCache =
          await TableCircleListMaster.readForUser(userFurnaces);

      List<CircleListTemplate> sinkValues =
          _convertFromCache(circleListTemplatesCache);

      if (sinkValues.isNotEmpty) _circleListTemplate.sink.add(sinkValues);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleListTemplateBloc._sinkCache: $error');
      throw (error);
    }
  }

  /// Convert a CircleObjectCache list to a CircleObject list
  List<CircleListTemplate> _convertFromCache(
      List<CircleListMasterCache>? circleListTemplateCacheList) {
    List<CircleListTemplate> convertList = [];

    if (circleListTemplateCacheList != null) {
      if (circleListTemplateCacheList.isNotEmpty) {
        //convert the cache to CircleListTemplate
        for (CircleListMasterCache circleListTemplateCache
            in circleListTemplateCacheList) {
          Map<String, dynamic> decode =
              json.decode(circleListTemplateCache.jsonString!);

          CircleListTemplate circleListTemplate =
              CircleListTemplate.fromJson(decode);

          //add the hitchihikers
          circleListTemplate.userFurnace = circleListTemplateCache.userFurnace;

          if (circleListTemplate.name != null)
            convertList.add(
                circleListTemplate); //decryption could fail this and error on the sort below
        }
      }
    }

    if (convertList.isNotEmpty)
      convertList.sort(
          (a, b) => (a.name!.toLowerCase().compareTo(b.name!.toLowerCase())));

    return convertList;
  }

  /// Delete a list
  delete(CircleListTemplate circleListTemplate) async {
    try {
      //CircleObject sinkValue;

      await TableCircleListMaster.delete(circleListTemplate.id);

      if (circleListTemplate.id != null) {
        //delete the object from the furnace
        await _circleListTemplateService.delete(
            circleListTemplate.userFurnace!, circleListTemplate);
      }

      _deleted.sink.add(circleListTemplate);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleListTemplateBloc.delete: " + error.toString());
      _circleListTemplate.sink.addError(error);
    }
  }

  dispose() async {
    await _deleted.drain();
    _deleted.close();

    await _circleListTemplate.drain();
    _circleListTemplate.close();

    await _upsert.drain();
    _upsert.close();
  }
}
