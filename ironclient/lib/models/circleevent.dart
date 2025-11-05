// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circleeventrespondent.dart';
import 'package:ironcirclesapp/models/circleobjectlineitem.dart';
import 'package:ironcirclesapp/models/user.dart';

CircleEvent circleEventFromJson(String str) =>
    CircleEvent.fromJson(json.decode(str));

String circleEventToJson(CircleEvent data) => json.encode(data.toJson());

class CircleEvent {
  String title;
  String description;
  String location;
  DateTime startDate;
  DateTime endDate;
  User? lastEdited;

  List<CircleEventRespondent> respondents;
  List<CircleObjectLineItem> encryptedLineItems;

  CircleEvent({
    this.title = '',
    this.description = '',
    this.location = '',
    required this.respondents,
    required this.encryptedLineItems,
    required this.startDate,
    required this.endDate,
    this.lastEdited,
  });

  sortAttendees() {}

  int get attendingYesCount {
    int retValue = 0;
    for (CircleEventRespondent circleEventRespondent in respondents) {
      if (circleEventRespondent.attending == Attending.Yes) {
        // retValue++;
        retValue += circleEventRespondent.numOfGuests;
      }
    }

    return retValue;
  }

  int get attendingNoCount {
    int retValue = 0;
    for (CircleEventRespondent circleEventRespondent in respondents) {
      if (circleEventRespondent.attending == Attending.No) {
        // retValue++;
        retValue += circleEventRespondent.numOfGuests;
      }
    }

    return retValue;
  }

  int get attendingMaybeCount {
    int retValue = 0;
    for (CircleEventRespondent circleEventRespondent in respondents) {
      if (circleEventRespondent.attending == Attending.Maybe) {
        //retValue++;
        retValue += circleEventRespondent.numOfGuests;
      }
    }

    return retValue;
  }

  String get startDateString {
    return DateFormat.yMMMd().format(startDate);
  }

  String get endDateString {
    return DateFormat.yMMMd().format(endDate);
  }

  String get startTimeString {
    return DateFormat.jm().format(startDate);
  }

  String get endTimeString {
    return DateFormat.jm().format(endDate);
  }

  factory CircleEvent.fromJson(Map<String, dynamic> json) => CircleEvent(
      title: json["title"] ?? '',
      description: json["description"] ?? '',
      location: json["location"] ?? '',
      respondents: json["respondents"] == null
          ? []
          : CircleEventRespondentCollection.fromJSON(json, "respondents")
              .objects,
      encryptedLineItems: json["encryptedLineItems"] == null
          ? []
          : CircleObjectLineItemCollection.fromJSON(json, "encryptedLineItems")
              .objects,
      startDate: json["startDate"] == null
          ? DateTime.now()
          : DateTime.parse(json["startDate"]).toLocal(),
      lastEdited:
          json["lastEdited"] == null ? null : User.fromJson(json["lastEdited"]),
      endDate: json["endDate"] == null
          ? DateTime.now()
          : DateTime.parse(json["endDate"]).toLocal());

  Map<String, dynamic> toJson() => {
        "title": title,
        "description": description.isEmpty ? null : description,
        "location": location.isEmpty ? null : location,
        "startDate": startDate.toUtc().toString(),
        "endDate": endDate.toUtc().toString(),
        "encryptedLineItems":
            List<dynamic>.from(encryptedLineItems.map((x) => x)),
        "respondents": List<dynamic>.from(respondents.map((x) => x)),
        "lastEdited": lastEdited?.toJson(),
      };

  /*factory CircleEvent.fromJsonSQL(Map<String, dynamic> json) => CircleEvent(
        title: json["title"] == null ? '' : json["title"],
        description: json["description"] == null ? '' : json["description"],
        location: json["location"] == null ? '' : json["location"],
        respondents: json["respondents"] == null
            ? []
            : CircleEventRespondentCollection.fromJSON(json, "respondents")
                .objects,
        encryptedLineItems: [],
        startDate: json["startDate"] == null
            ? DateTime.now()
            : DateTime.parse(json["startDate"]).toLocal(),
        endDate: json["endDate"] == null
            ? DateTime.now()
            : DateTime.parse(json["endDate"]).toLocal(),
      );

  Map<String, dynamic> toJsonSQL() => {
        "title": title,
        "description": description.isEmpty ? null : description,
        "location": location.isEmpty ? null : location,
        "startDate": startDate.toUtc().toString(),
        "endDate": endDate.toUtc().toString(),
      };

  */

  void revertEncryptionFields(CircleEvent original) {
    title = original.title;
    description = original.description;
    location = original.location;
    startDate = original.startDate;
    endDate = original.endDate;
    respondents = original.respondents;
  }

  void blankEncryptionFields() {
    title = '';
    description = '';
    location = '';
    //DateTime startDate;
    endDate = DateTime.now();

    respondents = [];
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      var event = json["event"];

      title = event["title"];
      description = event["description"];
      location = event["location"] ?? '';
      startDate = DateTime.parse(event["startDate"]).toLocal();
      endDate = DateTime.parse(event["endDate"]).toLocal();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEvent.mapDecryptedFields: $err');
      rethrow;
    }
  }

  static CircleEvent deepCopy(CircleEvent circleEvent) {
    return CircleEvent(
      title: circleEvent.title,
      description: circleEvent.description,
      location: circleEvent.location,
      startDate: circleEvent.startDate,
      endDate: circleEvent.endDate,
      lastEdited: circleEvent.lastEdited,
      respondents: circleEvent.respondents,
      encryptedLineItems: circleEvent.encryptedLineItems
    );
  }

  static CircleEvent deepCopyForShare(CircleEvent circleEvent) {
    return CircleEvent(
        title: circleEvent.title,
        description: circleEvent.description,
        location: circleEvent.location,
        startDate: circleEvent.startDate,
        endDate: circleEvent.endDate,
        encryptedLineItems: [],
        respondents: [],
    );
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = Map<String, dynamic>();

      retValue["title"] = title;
      retValue["description"] = description;
      retValue["location"] = location;
      retValue["startDate"] = startDate.toUtc().toString();
      retValue["endDate"] = endDate.toUtc().toString();

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleEvent.fetchFieldsToEncrypt: $err');
      rethrow;
    }
  }
}
