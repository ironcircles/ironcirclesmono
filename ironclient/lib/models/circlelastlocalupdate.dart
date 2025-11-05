import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_circlelastlocalupdate.dart';

CircleLastLocalUpdate circleLastLocalUpdateFromJson(String str) =>
    CircleLastLocalUpdate.fromJson(json.decode(str));

String circleLastUpdateToJson(CircleLastLocalUpdate data) =>
    json.encode(data.toJson());

class CircleLastLocalUpdate {
  int? pk;
  String? circleID;
  DateTime? lastFetched;

  CircleLastLocalUpdate({
    this.pk,
    this.circleID,
    this.lastFetched,
  });

  factory CircleLastLocalUpdate.fromJson(Map<String, dynamic> json) =>
      CircleLastLocalUpdate(
        pk: json["pk"],
        circleID: json["circleID"],
        lastFetched: json["lastFetched"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastFetched"])
                .toLocal(),
      );

  Map<String, dynamic> toJson() => {
        "pk": pk,
        "circleID": circleID,
        "lastFetched":
            lastFetched?.millisecondsSinceEpoch,
      };

  upsert() async {
    return TableCircleLastLocalUpdate.upsert(this);
  }

  upsertDate(DateTime lastFetched) async {
    this.lastFetched = lastFetched;
    return TableCircleLastLocalUpdate.upsert(this);
  }

  static Future<CircleLastLocalUpdate?> read(String circleID) async {
    CircleLastLocalUpdate? retValue =
        await TableCircleLastLocalUpdate.read(circleID);

    //debugPrint ('a: $circleID');

    if (retValue == null) {
      //wait _populateLastLocalAccessTables(circleID);
      retValue = await TableCircleLastLocalUpdate.read(circleID);

      //debugPrint ('read: $circleID');
    }

    return retValue;
  }

  static Future<List<CircleLastLocalUpdate>> readAll(
      List<UserCircleCache> userCircleCaches) async {
    try {
      List<CircleLastLocalUpdate> results = [];

      for (UserCircleCache userCircleCache in userCircleCaches) {
        CircleLastLocalUpdate? add = await read(userCircleCache.circle!);

        if (add == null) {
          //await _populateLastLocalAccessTables(userCircleCache.circle!);
          add = await read(userCircleCache.circle!);

          //debugPrint ('readAll: ${userCircleCache.circle!}');
        }

        if (add != null) results.add(add);
      }

      return results;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleLastLocalUpdate.readAll: $err');
      throw (err);
    }
  }

  /*
  //TODO remove this after everyone is one 27 or higher
  //fuck hive
  static _populateLastLocalAccessTables(String circleID) async {
    List<UserCircleCache> userCircleCaches =
        await TableUserCircleCache.readUserCircleCacheByCircleID(circleID);
    List<CircleLastUpdate> circleLastUpdates =
        await CircleLastUpdate.retrieveAll(userCircleCaches);

    for (CircleLastUpdate circleLastUpdate in circleLastUpdates) {
      CircleLastLocalUpdate circleLastLocalUpdate = CircleLastLocalUpdate(
          circleID: circleLastUpdate.circleID,
          lastFetched: circleLastUpdate.lastFetched);
      await circleLastLocalUpdate.upsert();
    }
  }

   */
}
