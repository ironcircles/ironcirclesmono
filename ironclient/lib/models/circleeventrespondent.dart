// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleEventRespondent circleEventRespondentFromJson(String str) =>
    CircleEventRespondent.fromJson(json.decode(str));

String circleEventRespondentToJson(CircleEventRespondent data) =>
    json.encode(data.toJson());

enum Attending { Yes, Maybe, No, NotReplied }

class CircleEventRespondent {
  //String id;
  Attending attending;
  int numOfGuests;
  User respondent;

  int order = 0; //UI only

  CircleEventRespondent({
    //this.id = '',
    this.attending = Attending.Maybe,
    this.numOfGuests = 0,
    required this.respondent,
  });

  factory CircleEventRespondent.fromJson(Map<String, dynamic> json) =>
      CircleEventRespondent(
        //id: json["_id"] == null ? '' : json["_id"],
        attending: (json["attending"] == null /*|| json["attending"] == 0*/)
            ? Attending.Maybe
            : Attending.values
                .firstWhere((element) => element.index == json["attending"]),
        numOfGuests: json["numOfGuests"] ?? 0,
        respondent: json["respondent"] == null
            ? User()
            : User.fromJson(json["respondent"]),
      );

  Map<String, dynamic> toJson() => {
        //"_id": id,
        "attending": attending.index,
        "numOfGuests": numOfGuests,
        "respondent": respondent.toJson(),
      };

  /*factory CircleEventAttendee.fromJsonSQL(Map<String, dynamic> json) =>
      CircleEventAttendee(
        id: json["id"] == null ? '' : json["id"],
        attending:
        json["attending"] == null ? Attending.Maybe : json["attending"],
        numOfGuests: json["numOfGuests"] == null ? 0 : json["numOfGuests"],
        attendee: User.fromJson(json["attendee"]),
      );

  Map<String, dynamic> toJsonSQL() => {
    "_id": id,
    "attending": attending,
    "numOfGuests": numOfGuests,
    "attendee": attendee.toJson(),
  };

   */

  void revertEncryptionFields(CircleEventRespondent original) {
    attending = original.attending;
    numOfGuests = original.numOfGuests;
    respondent = original.respondent;
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      //var eventAttendee = json["eventAttendee"];

      attending = (json["attending"] == null /*|| json["attending"] == 0*/)
          ? Attending.Maybe
          : Attending.values
              .firstWhere((element) => element.index == json["attending"]);
      numOfGuests = json["numOfGuests"];
      respondent = User.fromJson(json["respondent"]);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEventRespondent.mapDecryptedFields: $err');
      rethrow;
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = Map<String, dynamic>();

      retValue["attending"] = attending.index;
      retValue["numOfGuests"] = numOfGuests;
      retValue["respondent"] = respondent.toJson();

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEventRespondent.fetchFieldsToEncrypt: $err');
      rethrow;
    }
  }
}

class CircleEventRespondentCollection {
  final List<CircleEventRespondent> objects;

  CircleEventRespondentCollection.fromJSON(
      Map<String, dynamic> json, String key)
      : objects = (json[key] as List)
            .map((json) => CircleEventRespondent.fromJson(json))
            .toList();
}
