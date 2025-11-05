// To parse this JSON data, do
//
//     final circleVoteOption = circleVoteOptionFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';

CircleVoteOption circleVoteOptionFromJson(String str) =>
    CircleVoteOption.fromJson(json.decode(str));

String circleVoteOptionToJson(CircleVoteOption data) =>
    json.encode(data.toJson());

class CircleVoteOption {
  String? option;
  int? voteTally;
  String? id;
  // String userVotedFor;
  List<User>? usersVotedFor;

  CircleVoteOption({
    this.id,
    this.option,
    this.voteTally,
    this.usersVotedFor,
  });

  getOption(BuildContext context, String voteType) {
    String retValue = option!;

    if (voteType == CircleVoteType.PRIVACY_SETTING ||
        voteType == CircleVoteType.SECURITY_SETTING_MODEL) {
      if (option == 'Yes') {
        return AppLocalizations.of(context)!.yes;
      } else if (option == 'No') {
        return AppLocalizations.of(context)!.no;
      }
    }

    return retValue;
  }

  static List<CircleVoteOption> deepCopy(List<CircleVoteOption> list,
      {bool includeVotes = false}) {
    List<CircleVoteOption> copied = [];

    for (CircleVoteOption sourceTask in list) {
      CircleVoteOption newItem = CircleVoteOption(
        //id: sourceTask.id,
        option: sourceTask.option,
        voteTally: includeVotes ? sourceTask.voteTally : 0,
        usersVotedFor: includeVotes ? sourceTask.usersVotedFor : null,
      );

      copied.add(newItem);
    }

    return copied;
  }

  factory CircleVoteOption.fromJson(Map<String, dynamic> json) =>
      CircleVoteOption(
        id: json["_id"],
        option: json["option"],
        voteTally: json["voteTally"],
        usersVotedFor: json["usersVotedFor"] == null
            ? null
            : UserCollection.fromJSON(json, "usersVotedFor").users,
        /*usersVotedFor: json["usersVotedFor"] == null
            ? null
            : List<String>.from(json[
                "usersVotedFor"]), */ //UserCollection.fromJSON(json, "usersVotedFor").users,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "option": option,
        "voteTally": voteTally,
        "usersVotedFor": usersVotedFor == null
            ? null
            : List<dynamic>.from(usersVotedFor!.map((x) => x)),
      };
}

class CircleVoteOptionCollection {
  final List<CircleVoteOption> circleVoteOptions;

  CircleVoteOptionCollection.fromJSON(Map<String, dynamic> json, String key)
      : circleVoteOptions = (json[key] as List)
            .map((json) => CircleVoteOption.fromJson(json))
            .toList();
}
