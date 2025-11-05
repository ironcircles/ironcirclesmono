import 'dart:convert';

UserCircleEnvelopeContents circleFromJson(String str) =>
    UserCircleEnvelopeContents.fromJson(json.decode(str));

String circleToJson(UserCircleEnvelopeContents data) =>
    json.encode(data.toJson());

class UserCircleEnvelopeContents {
  String circleName;
  String prefName;

  String? circleBackgroundKey;
  String? circleBackgroundSignature;
  String? circleBackgroundCrank;

  String? userCircleBackgroundKey;
  String? userCircleBackgroundSignature;
  String? userCircleBackgroundCrank;

  UserCircleEnvelopeContents({
    required this.circleName,
    required this.prefName,
    this.circleBackgroundKey,
    this.circleBackgroundSignature,
    this.circleBackgroundCrank,
    this.userCircleBackgroundKey,
    this.userCircleBackgroundSignature,
    this.userCircleBackgroundCrank,
  });

  factory UserCircleEnvelopeContents.fromJson(Map<String, dynamic> json) =>
      UserCircleEnvelopeContents(
        circleName: json["circleName"] ?? '',
        prefName: json["prefName"] ?? '',
        circleBackgroundKey: json["circleBackgroundKey"],
        circleBackgroundSignature: json["circleBackgroundSignature"],
        circleBackgroundCrank: json["circleBackgroundCrank"],
        userCircleBackgroundKey: json["userCircleBackgroundKey"],
        userCircleBackgroundSignature: json["userCircleBackgroundSignature"],
        userCircleBackgroundCrank: json["userCircleBackgroundCrank"],
      );

  Map<String, dynamic> toJson() => {
        "circleName": circleName,
        "prefName": prefName,
        "circleBackgroundKey": circleBackgroundKey,
        "circleBackgroundSignature": circleBackgroundSignature,
        "circleBackgroundCrank": circleBackgroundCrank,
        "userCircleBackgroundKey": userCircleBackgroundKey,
        "userCircleBackgroundSignature": userCircleBackgroundSignature,
        "userCircleBackgroundCrank": userCircleBackgroundCrank,
      };

  Map<String, dynamic> toJsonForInvitation() => {
        "circleName": circleName,
        "prefName":
            circleName, //this is only used for invitations, so the prefName is the circleName
        "circleBackgroundKey": circleBackgroundKey,
        "circleBackgroundSignature": circleBackgroundSignature,
        "circleBackgroundCrank": circleBackgroundCrank,
      };
}
