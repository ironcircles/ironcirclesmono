import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';

Circle circleFromJson(String str) => Circle.fromJson(json.decode(str));

String circleToJson(Circle data) => json.encode(data.toJson());

class Circle {
  String? id;
  String? name;
  String? type;
  String? ownershipModel;
  bool toggleMemberPosting;
  bool toggleMemberReacting;
  String? background;
  String? backgroundKey;
  String? backgroundSignature;
  String? backgroundCrank;
  String? backgroundCipher;
  int? backgroundSize;
  int? retention;
  String? votingModel;
  String? owner;
  String? lastUpdate;
  String? created;
  String? expiration;
  //DateTime? lastLocalUpdate;
  bool? privacyShareImage;
  bool? privacyShareURL;
  bool? privacyShareGif;
  bool? privacyCopyText;
  bool? toggleEntryVote;
  bool dm;
  String? privacyVotingModel;
  int? privacyDisappearingTimer;

  String? securityVotingModel;
  int? securityMinPassword;
  int? securityDaysPasswordValid;
  int? securityTokenExpirationDays;
  int? securityLoginAttempts;

  //bool? security2FA;

  //hijackers
  int? memberCount;

  ///Used to fetch public member keys upon opening a circle or dm
  ///Creates an encrypted session for the chat.
  ///If empty, the ForwardSecrecy algorithm will fetch from the api
  late List<RatchetKey> memberSessionKeys;

  Circle({
    this.id,
    this.name,
    this.type,
    this.ownershipModel,
    this.toggleMemberPosting = true,
    this.toggleMemberReacting = true,
    this.background,
    this.backgroundKey,
    this.backgroundSize,
    this.backgroundSignature,
    this.backgroundCrank,
    this.backgroundCipher,
    this.votingModel,
    this.owner,
    this.retention,
    this.lastUpdate,
    this.dm = false,
    //this.lastLocalUpdate,
    this.created,
    this.expiration,
    this.privacyShareImage,
    this.privacyShareURL,
    this.privacyShareGif,
    this.privacyCopyText,
    this.privacyVotingModel,
    this.securityVotingModel,
    this.privacyDisappearingTimer,
    this.toggleEntryVote,
    this.securityMinPassword,
    this.securityDaysPasswordValid,
    this.securityTokenExpirationDays,
    this.securityLoginAttempts,
    //this.ratchetKeys,
  }) {
    memberSessionKeys = [];
  }

  getChatTypeLocalizedString(BuildContext context) {
    if (dm) {
      return AppLocalizations.of(context)!.dm;
    } else if (type == CircleType.VAULT) {
      return AppLocalizations.of(context)!.vault;
    } else {
      return AppLocalizations.of(context)!.circle;
    }
  }

  factory Circle.fromJson(Map<String, dynamic> json) => Circle(
        id: json["_id"],
        name: json["name"],
        type: json["type"],
        dm: json["dm"] ?? false,
        retention: json["retention"],
        ownershipModel: json["ownershipModel"],
        toggleMemberPosting: json["toggleMemberPosting"] ?? true,
        toggleMemberReacting: json["toggleMemberReacting"] ?? true,
        background: json["background"],
        backgroundKey: json["backgroundKey"],
        backgroundSignature: json["backgroundSignature"],
        backgroundCrank: json["backgroundCrank"],
        backgroundCipher: json["backgroundCipher"],
        backgroundSize: json["backgroundSize"] ?? 0,
        votingModel: json["votingModel"],
        owner: json["owner"],
        lastUpdate: json["lastUpdate"],
        privacyDisappearingTimer: json["privacyDisappearingTimer"],
        created: json["created"],
        expiration: json["expiration"] == null
            ? null
            : DateTime.parse(json["expiration"]).toLocal().toString(),
        privacyShareImage: json["privacyShareImage"],
        privacyShareURL: json["privacyShareURL"],
        privacyShareGif: json["privacyShareGif"],
        privacyCopyText: json["privacyCopyText"],
        privacyVotingModel: json["privacyVotingModel"],
        toggleEntryVote: json["toggleEntryVote"],
        securityMinPassword: json["securityMinPassword"],
        securityDaysPasswordValid: json["securityDaysPasswordValid"],
        securityVotingModel: json["securityVotingModel"],
        securityTokenExpirationDays: json["securityTokenExpirationDays"],
        securityLoginAttempts: json["securityLoginAttempts"],
      );

  factory Circle.fromJsonSQL(Map<String, dynamic> json) => Circle(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        dm: json["dm"] == 1 ? true : false,
        ownershipModel: json["ownershipModel"],
        toggleMemberPosting: json["toggleMemberPosting"] == 1 ? true : false,
        toggleMemberReacting: json["toggleMemberReacting"] == 1 ? true : false,
        background: json["background"],
        backgroundKey: json["backgroundKey"],
        backgroundSignature: json["backgroundSignature"],
        backgroundCrank: json["backgroundCrank"],
        backgroundCipher: json["backgroundCipher"],
        backgroundSize: json["backgroundSize"] ?? 0,
        votingModel: json["votingModel"],
        owner: json["owner"],
        lastUpdate: json["lastUpdate"],
        created: json["created"],
        expiration: json["expiration"],
        retention: json["retention"],
        privacyDisappearingTimer: json["privacyDisappearingTimer"],
        privacyShareImage: json["privacyShareImage"] == 1 ? true : false,
        privacyShareURL: json["privacyShareURL"] == 1 ? true : false,
        privacyShareGif: json["privacyShareGif"] == 1 ? true : false,
        privacyCopyText: json["privacyCopyText"] == 1 ? true : false,
        toggleEntryVote: json["toggleEntryVote"] == 1 ? true : false,
        privacyVotingModel: json["privacyVotingModel"],
        securityMinPassword: json["securityMinPassword"],
        securityDaysPasswordValid: json["securityDaysPasswordValid"],
        securityVotingModel: json["securityVotingModel"],
        securityTokenExpirationDays: json["securityTokenExpirationDays"],
        securityLoginAttempts: json["securityLoginAttempts"],
        //security2FA: json["security2FA"] == 1 ? true : false,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "type": type,
        "dm": dm,
        "ownershipModel": ownershipModel,
        "toggleMemberPosting": toggleMemberPosting,
        "toggleMemberReacting": toggleMemberReacting,
        "background": background,
        //"backgroundKey": backgroundKey,  //don't send the key
        "backgroundSize": backgroundSize ?? 0,
        "votingModel": votingModel,
        "owner": owner,
        "retention": retention,
        "lastUpdate": lastUpdate,
        "created": created,
        "expiration": expiration,
        "privacyDisappearingTimer": privacyDisappearingTimer,
        "privacyShareImage": privacyShareImage,
        "privacyShareURL": privacyShareURL,
        "privacyShareGif": privacyShareGif,
        "privacyCopyText": privacyCopyText,
        "toggleEntryVote": toggleEntryVote,
        "privacyVotingModel": privacyVotingModel,
        "securityMinPassword": securityMinPassword,
        "securityDaysPasswordValid": securityDaysPasswordValid,
        "securityVotingModel": securityVotingModel,
        "securityTokenExpirationDays": securityTokenExpirationDays,
        "securityLoginAttempts": securityLoginAttempts,
        //"security2FA": security2FA
      };

  Map<String, dynamic> toJsonSQL() => {
        "id": id,
        "name": name,
        "type": type,
        "dm": dm ? 1 : 0,
        "ownershipModel": ownershipModel,
        "toggleMemberPosting": toggleMemberPosting ? 1 : 0,
        "toggleMemberReacting": toggleMemberReacting ? 1 : 0,
        "background": background,
        "backgroundKey": backgroundKey,
        "backgroundSignature": backgroundSignature,
        "backgroundCrank": backgroundCrank,
        "backgroundCipher": backgroundCipher,
        //"backgroundSize": backgroundSize == null ? 0 : backgroundSize,
        "votingModel": votingModel,
        "owner": owner,
        "retention": retention,
        "lastUpdate": lastUpdate,
        "created": created,
        "expiration": expiration,
        "privacyDisappearingTimer": privacyDisappearingTimer,
        "privacyShareImage":
            privacyShareImage == null ? 0 : (privacyShareImage! ? 1 : 0),
        "privacyShareURL":
            privacyShareURL == null ? 0 : (privacyShareURL! ? 1 : 0),
        "privacyShareGif":
            privacyShareGif == null ? 0 : (privacyShareGif! ? 1 : 0),
        "privacyCopyText":
            privacyCopyText == null ? 0 : (privacyCopyText! ? 1 : 0),
        "toggleEntryVote":
            toggleEntryVote == null ? 0 : (toggleEntryVote! ? 1 : 0),
        "privacyVotingModel": privacyVotingModel,
        "securityMinPassword": securityMinPassword,
        "securityDaysPasswordValid": securityDaysPasswordValid,
        "securityVotingModel": securityVotingModel,
        "securityTokenExpirationDays": securityTokenExpirationDays,
        "securityLoginAttempts": securityLoginAttempts,
        //"security2FA": security2FA == null ? 0 : (security2FA! ? 1 : 0),
      };

  String get endDateString {
    if (type == CircleType.TEMPORARY) {
      return DateFormat.yMMMd().format(DateTime.parse(expiration!));
    }
    return '';
  }

  String get endTimeString {
    if (type == CircleType.TEMPORARY) {
      return DateFormat.jm().format(DateTime.parse(expiration!));
    }
    return '';
  }
}
