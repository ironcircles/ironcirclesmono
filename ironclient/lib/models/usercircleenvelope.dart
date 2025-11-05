import 'dart:convert';

import 'package:ironcirclesapp/models/usercircleenvelopecontents.dart';

UserCircleEnvelope circleFromJson(String str) =>
    UserCircleEnvelope.fromJson(json.decode(str));

String circleToJson(UserCircleEnvelope data) => json.encode(data.toJson());

class UserCircleEnvelope {
  int? pk;
  String user;
  String userCircle;
  UserCircleEnvelopeContents contents;

  UserCircleEnvelope({
    this.pk,
    required this.user,
    required this.userCircle,
    required this.contents,
  });

  factory UserCircleEnvelope.fromJson(Map<String, dynamic> jsonMap) =>
      UserCircleEnvelope(
        pk: jsonMap["pk"],
        user: jsonMap["user"],
        userCircle: jsonMap["userCircle"],
        contents: UserCircleEnvelopeContents.fromJson(
            json.decode(jsonMap["contents"]!)),
      );

  factory UserCircleEnvelope.fromJsonObject(Map<String, dynamic> jsonMap) =>
      UserCircleEnvelope(
          pk: jsonMap["pk"],
          user: jsonMap["user"],
          userCircle: jsonMap["userCircle"],
          //contents: UserCircleEnvelopeContents.fromJson(json.decode(jsonMap["contents"])),
          contents: UserCircleEnvelopeContents.fromJson(jsonMap["contents"]));

  Map<String, dynamic> toJson() => {
        //"pk": pk,  //upsert statement uses user and userCircle in where clause, don't need pk
        "user": user,
        "userCircle": userCircle,
        "contents":
            json.encode(contents.toJson()).toString(), //contents.toJson(),
      };

  Map<String, dynamic> toJsonObject() => {
        //"pk": pk,  //upsert statement uses user and userCircle in where clause, don't need pk
        "user": user,
        "userCircle": userCircle,
        "contents": contents.toJson(), //contents.toJson(),
      };

  Map<String, dynamic> toJsonForInvitation() => {
        "user": '',
        "userCircle": '',
        "contents": contents.toJsonForInvitation(),
      };
}
