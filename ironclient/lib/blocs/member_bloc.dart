import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/hostedfurnace_service.dart';
import 'package:ironcirclesapp/services/member_service.dart';
import 'package:ironcirclesapp/services/membercircles_service.dart';
import 'package:rxdart/rxdart.dart';

class MembersAndCircles{
  List<Member> members;
  List<MemberCircle> memberCircles;

  MembersAndCircles(this.members, this.memberCircles);
}

class MemberBloc {
  final _saved = PublishSubject<Member>();
  Stream<Member> get saved => _saved.stream;

  final _loaded = PublishSubject<List<Member>>();
  Stream<List<Member>> get loaded => _loaded.stream;

  final _refreshed = PublishSubject<List<Member>>();
  Stream<List<Member>> get refreshed => _refreshed.stream;

  final _refreshedMemberCircles = PublishSubject<MembersAndCircles>();
  Stream<MembersAndCircles> get refreshedMemberCircles => _refreshedMemberCircles.stream;

  void refreshNetworkMembersFromAPI(
      GlobalEventBloc globalEventBloc, UserFurnace userFurnace,
      {List<UserCircleCache>? exclude,
      String includeMemberCircles = ''}) async {
    try {

      if (userFurnace.connected == false) return;

      HostedFurnaceService hostedFurnaceService =
          HostedFurnaceService(globalEventBloc);
      await hostedFurnaceService.getMembers(userFurnace,
          includeMemberCircles: includeMemberCircles);

      List<Member> members =
          await MemberService.getCachedMembers([userFurnace]);

      List<MemberCircle> memberCircles = [];

      if (exclude != null) {
        memberCircles = await MemberCircleService.getForCircles(exclude);

        for (MemberCircle memberCircle in memberCircles) {
          members.removeWhere(
              (element) => element.memberID == memberCircle.memberID);
        }
      }
      _refreshed.sink.add(members);


      if (includeMemberCircles != '') {
        MembersAndCircles membersAndCircles = MembersAndCircles(members, memberCircles);
        _refreshedMemberCircles.sink.add(membersAndCircles);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _refreshed.sink.addError(err);
    }
  }

  void getNetworkMembersFromCache(List<UserFurnace> userFurnaces,
      {List<UserCircleCache>? exclude,
      bool includeDisconnected = false}) async {
    ///get list of users for connected furnaces
    List<Member> members = await MemberService.getCachedMembers(userFurnaces);

    ///remove the current user accounts. This will only happen if another user logs
    ///into the device, and is connect with the current user on the same network
    for (UserFurnace userFurnace in userFurnaces) {
      members.removeWhere((element) => element.memberID == userFurnace.userid);
    }

    if (exclude != null) {
      List<MemberCircle> memberCircles =
          await MemberCircleService.getForCircles(exclude);

      for (MemberCircle memberCircle in memberCircles) {
        if (includeDisconnected) {
          int index = members.indexWhere(
              (element) => element.memberID == memberCircle.memberID);
          if (index > -1 && members[index].connected == true) {
            members.removeWhere(
                (element) => element.memberID == memberCircle.memberID);
          }
        } else {
          members.removeWhere(
              (element) => element.memberID == memberCircle.memberID);
        }
      }
    }

    members.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    _loaded.sink.add(members);
  }

  void getConnectedMembers(
      List<UserFurnace> userFurnaces, List<UserCircleCache> preFilter,
      {removeDM = false, excludeOwnerCircles = true}) async {
    ///get list of users for connected furnaces
    List<Member> members = await MemberService.getCachedMembers(userFurnaces);

    ///remove the current user accounts. This will only happen if another user logs
    ///into the device, and is connect with the current user on the same network
    for (UserFurnace userFurnace in userFurnaces) {
      members.removeWhere((element) => element.memberID == userFurnace.userid);
    }

    List<UserCircleCache> filtered = preFilter;

    if (excludeOwnerCircles) {
      ///Remove Owner circles (this should really only exclude the Beta Circle)
      filtered = preFilter
          .where((element) =>
              element.cachedCircle!.ownershipModel == CircleOwnership.MEMBERS)
          .toList();
    }

    List<MemberCircle> memberCircles =
        await MemberCircleService.getForCircles(filtered);

    ///this already accounts for hidden circles by only pulling open circles
    for (MemberCircle memberCircle in memberCircles) {
      ///remove the users who already have dms
      if (memberCircle.dm == true && removeDM) {
        members.removeWhere(
            (element) => element.memberID == memberCircle.memberID);
      }

      ///remove ones that are not in the userCircleCache list (for closed and hidden circles)
      UserCircleCache userCircleCache = filtered.firstWhere(
          (element) => element.circle! == memberCircle.circleID,
          orElse: () => UserCircleCache());
      if (userCircleCache.user == null) {
        members.removeWhere(
            (element) => element.memberID == memberCircle.memberID);
      }
    }

    ///remove ones that are not in the userCircleCache list (for closed and hidden circles)
    List<Member> removeMembers = [];

    for (Member member in members) {
      MemberCircle memberCircle = memberCircles.firstWhere(
          (element) => element.memberID == member.memberID,
          orElse: () =>
              MemberCircle(memberID: '', userID: '', circleID: '', dm: false));

      if (memberCircle.memberID.isEmpty) {
        removeMembers.add(member);
      }
    }

    for (Member member in removeMembers) {
      members.remove(member);
    }

    members.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    _loaded.sink.add(members);
  }

  Member? create(
      GlobalState globalState, UserFurnace userFurnace, User circleMember) {
    try {
      Member member = Member(
          memberID: circleMember.id!,
          username: circleMember.username!,
          userID: userFurnace.userid!,
          furnaceKey: userFurnace.pk!,
          avatar: circleMember.avatar,
          alias: '');

      member.color = globalState
          .theme.messageColorOptions![globalState.userSetting.lastColorIndex];

      globalState.userSetting
          .setLastColorIndex(globalState.userSetting.lastColorIndex + 1);

      Member.addMember(member);

      _saveAndSink(userFurnace.userid!, member);

      return member;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberBloc.upsert: $err');
      _saved.sink.addError(err);
    }

    return null;
  }

  _saveAndSink(String userID, Member member) async {
    try {
      member = await MemberService.upsert(userID, member);

      _saved.sink.add(member);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberBloc.upsert: $err');
      _saved.sink.addError(err);
    }
  }

  static populateGlobalStateWithAll() async {
    try {
      List<Member> members = [];

      members = await MemberService.readAll();

      for (Member member in members) {
        ///don't add them all at once in case there are duplicates
        Member.addMember(member);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberBloc.populateGlobalState: $err');
    }
  }

  static populateGlobalState(
      GlobalState globalState, List<UserFurnace> userFurnaces) async {
    try {
      List<Member> members = [];

      for (UserFurnace userFurnace in userFurnaces) {
        members.addAll(await MemberService.readForUser(userFurnace.userid!));
      }

      for (Member member in members) {
        ///don't add them all at once in case there are duplicates
        Member.addMember(member);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MemberBloc.populateGlobalState: $err');
    }
  }

  static setInitialColors() async {
    await MemberService.setInitialColors();
  }

  setColor(
      String userID, Member member, Color color, List<Member> members) async {
    debugPrint('MemberBloc.setColor at ${DateTime.now()}');
    member.color = color;

    members.firstWhere((element) => element.memberID == member.memberID).color =
        color;

    globalState.members
        .firstWhere((element) => element.memberID == member.memberID)
        .color = color;
    await MemberService.setColor(userID, member);

    _saved.sink.add(member);
  }

  setAlias(String userID, Member member, String alias) async {
    member.alias = alias;

    globalState.members
        .firstWhere((element) => element.memberID == member.memberID)
        .alias = alias;

    MemberService.setAlias(userID, member);

    _saved.sink.add(member);
  }

  setBlocked(String userID, Member member, bool status) async {
    member.blocked = status;
    globalState.members.
      firstWhere((element) => element.memberID == member.memberID)
      .blocked = status;

    MemberService.setBlocked(userID, member);

    _saved.sink.add(member);
  }

  dispose() async {
    await _loaded.drain();
    _loaded.close();

    await _saved.drain();
    _saved.close();
  }
}
