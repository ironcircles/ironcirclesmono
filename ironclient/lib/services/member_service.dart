import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/table_member.dart';

class MemberService {
  static AvatarService avatarService = AvatarService();

  static Future<List<Member>> getCachedMembers(
      List<UserFurnace> userFurnaces) async {
    ///get list of cached users for furnaces
    return await TableMember.getCachedMembers(userFurnaces);
  }

  static Future<Member> upsert(String userID, Member member) async {
    try {
      //await TableMember.deleteAll();
      return await TableMember.upsert(userID, member);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.upsert: $error");

      rethrow;
    }
  }

  static Future<Member> setAlias(String userID, Member member) async {
    try {
      //await TableMember.deleteAll();
      return await TableMember.setAlias(userID, member);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.upsert: $error");

      rethrow;
    }
  }

  static Future<Member> setBlocked(String userID, Member member) async {
    try {
      return await TableMember.setBlocked(userID, member);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.upsert: $error");
      rethrow;
    }
  }

  static Future<Member> setColor(String userID, Member member) async {
    try {
      return await TableMember.setColor(userID, member);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.upsert: $error");

      rethrow;
    }
  }

  static Future<List<Member>> readForUser(String userID) async {
    try {
      return await TableMember.readForUser(userID);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.readForUser: $error");

      rethrow;
    }
  }

  static Future<List<Member>> readAll() async {
    try {
      return await TableMember.readAll();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("MemberService.readForUser: $error");

      rethrow;
    }
  }

  static Future<void> setInitialColors() async {
    List<Member> members = await TableMember.getAll();

    for (Member member in members) {
      debugPrint('MemberService.setInitialColors start at ${DateTime.now()}');

      try {
        member.color = globalState
            .theme.messageColorOptions![globalState.userSetting.lastColorIndex];

        await globalState.userSetting.setLastColorIndex(
            globalState.userSetting.lastColorIndex + 1,
            save: false);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }

    await globalState.userSetting
        .setLastColorIndex(globalState.userSetting.lastColorIndex, save: true);

    await TableMember.upsertBatch(members);

    debugPrint('MemberService.setInitialColors end at ${DateTime.now()}');
  }
}
