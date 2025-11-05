/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';


CircleLastUpdate circleLastUpdateFromJson(String str) =>
    CircleLastUpdate.fromJson(json.decode(str));

String userCircleToJson(CircleLastUpdate data) => json.encode(data.toJson());

@HiveType(typeId: 4)
class CircleLastUpdate {
  static const String BOXNAME = "circlelastupdate";

  DateTime lastFetched;
  String circleID;

  CircleLastUpdate({
    //required this.userID,
    required this.lastFetched,
    required this.circleID,
  });

  factory CircleLastUpdate.fromJson(Map<String, dynamic> json) =>
      CircleLastUpdate(
        // userID: json["userID"],
        lastFetched: json["lastFetched"],
        circleID: json["circleID"],
      );

  Map<String, dynamic> toJson() => {
        //"userID": userID,
        "lastFetched": lastFetched.toUtc().toString(),
        "circleID": circleID,
      };

  upsert(DateTime lastObjectDate) async {
    //lastFetched = DateTime.now().toUtc();
    lastFetched = lastObjectDate;

    var box = await _openBox(BOXNAME);
    box.put(circleID, this); //upsert

    lastFetched = lastFetched.toLocal();

    return;
  }

  /*
  static upsert(CircleLastUpdate circleLastUpdate) async {
    circleLastUpdate.lastFetched = DateTime.now();

    var box = await _openBox(BOXNAME);

    // if (box.containsKey(userCircleAccessed.userCircleID)){
    box.put(circleLastUpdate.circleID, circleLastUpdate); //upsert

    return;
  }

   */

  static Future<Box<CircleLastUpdate>> _openBox(String boxName) async {
    return await Hive.openBox<CircleLastUpdate>(boxName);
  }

  /*static Future<CircleLastUpdate> retrieve(String circleID) async {
    try {
      Box<CircleLastUpdate> box = await _openBox(BOXNAME);

      CircleLastUpdate? retValue = box.get(circleID,
          defaultValue:
              CircleLastUpdate(lastFetched: DateTime.now(), circleID: ''));

      retValue!.lastFetched = retValue.lastFetched.toLocal();

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleLastuUpdate.retrieve: $err');
      throw (err);
    }
  }

  static Future<List<CircleLastUpdate>> retrieveAl2(
      List<UserCircleCache> userCircleCaches) async {
    try {
      List<CircleLastUpdate> results = [];

      for (UserCircleCache userCircleCache in userCircleCaches) {
        results.add(await retrieve(userCircleCache.circle!));
      }

      return results;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleLastuUpdate.retrieve: $err');
      throw (err);
    }
  }

   */

  static Future<void> delete(String circleID) async {
    Box<CircleLastUpdate> box = await _openBox(BOXNAME);
    box.delete(circleID);

    return;
  }

  static Future<void> deleteAll() async {
    Hive.deleteBoxFromDisk(BOXNAME);
  }
}

 */
