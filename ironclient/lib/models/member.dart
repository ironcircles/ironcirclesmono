import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class Member {
  int? pk;
  String memberID;
  String userID;
  String alias;
  String username;
  int furnaceKey;
  Avatar? avatar;
  Color color;
  int accountType;
  bool lockedOut;
  bool blocked;
  bool connected;

  //ui only
  bool selected;

  Member({
    required this.memberID,
    this.pk,
    required this.userID,
    required this.alias,
    this.username = '',
    this.furnaceKey = -1,
    this.avatar,
    this.color = Colors.transparent,
    this.accountType = AccountType.FREE,
    this.lockedOut = false,
    this.selected = false,
    this.blocked = false,
    this.connected = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        pk: json['pk'],
        memberID: json['memberID'],
        userID: json['userID'],
        alias: json['alias'],
        lockedOut: json['lockedOut'] ?? false,
        blocked: json['blocked'] ?? false,
        connected: json['connected'] ?? false,
        accountType: json['accountType'],
        username: json['username'] ?? '',
        furnaceKey: json['furnaceKey'] ?? -1,
        avatar: json.containsKey('avatar')
            ? json['avatar'] == null
                ? null
                : Avatar.fromJson(json['avatar'])
            : null,
      );

  factory Member.fromJsonSQL(Map<String, dynamic> json) => Member(
        pk: json['pk'],
        memberID: json['memberID'],
        userID: json['userID'],
        alias: json['alias'],
        lockedOut: json['lockedOut'] == null
            ? false
            : json['lockedOut'] == 1
                ? true
                : false,
        blocked: json['blocked'] == null
          ? false
          : json['blocked'] == 1
            ? true
            : false,
        accountType: json['accountType'] ?? 0,
        connected: json['connected'] == null
            ? false
            : json['connected'] == 1
                ? true
                : false,
        username: json['username'] ?? '',
        furnaceKey: json['furnaceKey'] ?? -1,
        color: (json['color'] == null || json['color'] == -1)
            ? Colors.red
            : Color(json['color']),
      );

  Map<String, dynamic> toJson() => {
        //'pk': pk,
        'memberID': memberID,
        'userID': userID,
        'alias': alias,
        'username': username,
        'lockedOut': lockedOut ? 1 : 0,
        'connected': connected ? 1 : 0,
        'furnaceKey': furnaceKey,
        //'avatar': avatar == null ? null : avatar!.toJson(),
        'avatar':
            avatar == null ? null : json.encode(avatar!.toJson()).toString(),
        'color': color.value,
        'accountType': accountType,
        'blocked': blocked ? 1 : 0,
      };

  static Member getMember(String id) {
    return globalState.members.firstWhere((element) => element.memberID == id,
        orElse: () => Member(memberID: '', userID: '', alias: ''));
  }

  static bool memberExists(String id) {
    //debugPrint('memberExists');
    int index =
        globalState.members.indexWhere((element) => element.memberID == id);

    if (index == -1)
      return false;
    else
      return true;
  }

  static addMember(Member member) {
    int index = globalState.members
        .indexWhere((element) => element.memberID == member.memberID);

    if (index == -1)
      globalState.members.add(member);
    else
      globalState.members[index] = member;
  }

  /*static Member getMemberByUsername(String username, List<Member> members) {
    Member member = members.firstWhere(
        (element) =>
            (element.username == username || element.alias == username),
        orElse: () => Member(memberID: '', userID: '', alias: ''));

    return member;
  }

   */

  static String returnUserID(
      String username, int furnaceKey, List<Member> members) {
    Member member = members.firstWhere(
        (element) =>
            ((element.username == username || element.alias == username) &&
                element.furnaceKey == furnaceKey),
        orElse: () => Member(memberID: '', userID: '', alias: ''));

    return member.memberID;
  }

  static String returnAlias(String memberID, List<Member> members) {
    Member member = members.firstWhere(
        (element) => element.memberID == memberID,
        orElse: () => Member(memberID: '', userID: '', alias: ''));

    return member.alias;
  }

  static Color returnColor(String memberID, List<Member> members) {
    try {
      Member member = members.firstWhere(
          (element) => element.memberID == memberID,
          orElse: () => Member(memberID: '', userID: '', alias: ''));

      if (member.color == Colors.transparent) {
        //throw ('could not find color');
        ///could not find the color, default to the last in the list
        return globalState.theme.messageColorOptions![
            globalState.theme.messageColorOptions!.length - 1];
      }

      return member.color;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }

    return Colors.red;
  }

  static Color getMemberColor(UserFurnace userFurnace, User? user) {
    try {
      if (user != null) {
        ///Should only happen for invitations or when a User joins a Circle
        if (!Member.memberExists(user.id!)) {
          //MemberBloc memberBloc = MemberBloc();
          //memberBloc.create(globalState, userFurnace, user);
        }

        return globalState.members
            .singleWhere((element) => element.memberID == user.id)
            .color;
      } else {
        return globalState.theme.sentIndicator;
      }
    } catch (err, stack) {
      debugPrint('getMemberColor $err');
      debugPrint('$stack');

      return Colors.red;
    }
  }

  static Color getReplyMemberColor(
      CircleObject circleObject, String userID, UserFurnace userFurnace) {
    try {
      Color color = Colors.red;

      if (circleObject.reply != null) {
        if (circleObject.replyUserID == userID)
          color = globalState.theme.userObjectText;
        else
          color = Member.getMemberColor(
              userFurnace, User(id: circleObject.replyUserID));
      }

      return color;
    } catch (err) {
      debugPrint('getReplyMemberColor $err');

      return Colors.red;
    }
  }

  String returnUsernameAndAlias() {
    //return username + (alias.isEmpty ? '' : ' ($alias)');
    return alias.isEmpty ? username : '$alias ($username)';
  }
}

class MemberCollection {
  final List<Member> members;

  MemberCollection.fromJSON(Map<String, dynamic> json, String key)
      : members =
            (json[key] as List).map((json) => Member.fromJson(json)).toList();
}
