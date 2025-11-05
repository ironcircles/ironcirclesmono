import 'dart:convert';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';

Invitation invitationFromJson(String str) =>
    Invitation.fromJson(json.decode(str));

//String invitationToJson(Invitation data) => json.encode(data.toJson());

class Invitation {
  String? id;
  //User? invitee;
  //User? inviter;

  String invitee;
  String inviteeID;
  String inviter;
  String inviterID;
  String circleID;
  String status;
  //Circle? circle;
  String circleName;
  late UserFurnace userFurnace;
  String? ratchetIndexJson;
  RatchetIndex? ratchetIndex;
  static const String created = "created";
  static const String lastUpdate = "lastUpdate";
  bool dm;

  Invitation({
    required this.id,
    required this.invitee,
    required this.inviteeID,
    required this.inviter,
    required this.inviterID,
    required this.circleID,
    required this.status,
    required this.circleName,
    this.dm = false,
    this.ratchetIndexJson,
    this.ratchetIndex,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json["_id"],
        invitee: User.fromJson(json["invitee"]).username!,
        inviteeID: User.fromJson(json["invitee"]).id!,
        inviter: User.fromJson(json["inviter"]).username!,
        inviterID: User.fromJson(json["inviter"]).id!,
        circleID: Circle.fromJson(json["circle"]).id!,
        dm: json["dm"],
        //circleName: Circle.fromJson(json["circleName"]).name!,
        circleName: '',
        status: json["status"],
        ratchetIndex: RatchetIndex.fromJson(json["ratchetIndex"]),
      );

  factory Invitation.fromSQL(Map<String, dynamic> json) => Invitation(
        id: json["id"],
        invitee: json["invitee"],
        inviteeID: json["inviteeID"],
        inviter: json["inviter"],
        inviterID: json["inviterID"],
        circleID: json["circleID"] ?? '',
        circleName: json["circleName"],
        status: json["status"],
        dm: (json["dm"] == null || json["dm"] == 0) ? false : true,
        ratchetIndexJson: json["ratchetIndexJson"],
        //ratchetIndex: RatchetIndex.fromJson(json["ratchetIndex"]),
      );

  Map<String, dynamic> toSQL() => {
        "id": id,
        "invitee": invitee,
        "inviteeID": inviteeID,
        "inviter": inviter,
        "inviterID": inviterID,
        "status": status,
        "circleID": circleID,
        "circleName": circleName,
        "dm": dm ? 1 : 0,
        "ratchetIndexJson": ratchetIndexJson,
      };
}

class InvitationCollection {
  final List<Invitation> invitations;

  InvitationCollection.fromJSON(Map<String, dynamic> json, String key)
      : invitations = (json[key] as List)
            .map((json) => Invitation.fromJson(json))
            .toList();
}
