import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/services/cache/table_deleteidtracker.dart';
import 'package:ironcirclesapp/services/cache/table_invitation.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/invitations_service.dart';
import 'package:rxdart/rxdart.dart';

class InvitationBloc {
  final _invitationService = InvitationsService();

  final _invitations = PublishSubject<List<Invitation>>();
  Stream<List<Invitation>> get invitations => _invitations.stream;

  final _blockedList = PublishSubject<List<User>>();
  Stream<List<User>> get blockedList => _blockedList.stream;

  final _findUsers = PublishSubject<List<User>>();
  Stream<List<User>> get findUsers => _findUsers.stream;

  final _addToBlockedlist = PublishSubject<User>();
  Stream<User> get addToBlockedlist => _addToBlockedlist.stream;

  final _removedFromBlockedlist = PublishSubject<User>();
  Stream<User> get removedFromBlockedlist => _removedFromBlockedlist.stream;

  final _sendInviteResponse = PublishSubject<Invitation?>();
  Stream<Invitation?> get inviteResponse => _sendInviteResponse.stream;

  final _sendMultipleInvitationsResponse = PublishSubject<bool>();
  Stream<bool> get sendMultipleInvitationsResponse =>
      _sendMultipleInvitationsResponse.stream;

  final _invitationResponse = PublishSubject<Invitation>();
  Stream<Invitation> get invitationResponse => _invitationResponse.stream;

  final _dmCanceled = PublishSubject<bool>();
  Stream<bool> get dmCanceled => _dmCanceled.stream;

  sinkCache(List<UserFurnace> userFurnaces) async {
    List<Invitation> entireList = [];

    //LogBloc.insertLog("UserFurnace length: ${userFurnaces.length}", "InvitationsBloc sincCache");

    for (UserFurnace userFurnace in userFurnaces) {
      if (userFurnace.connected == true) {
        List<Invitation> subList =
            await TableInvitation.readForUser(userFurnace.userid!);

        for (Invitation invitation in subList) {
          invitation.userFurnace = userFurnace;
        }

        entireList.addAll(subList);
      }
    }

    //LogBloc.insertLog("Invitations length: ${entireList.length}", "InvitationsBloc sinkCache");

    _invitations.sink.add(entireList);
  }

  fetchInvitationsForCircle(String circleID, UserFurnace userFurnace,
      {bool force = false}) async {
    try {
      if (globalState.lastInvitationByCircleFetch != null && !force) {
        Duration duration =
            DateTime.now().difference(globalState.lastInvitationByCircleFetch!);

        if (duration.inSeconds < 20) return;
      }

      globalState.lastInvitationByCircleFetch = DateTime.now();

      debugPrint('hit fetchInvitationsForCircle');

      List<Invitation> invitations = await _invitationService
          .fetchOpenInvitationsForCircle(circleID, userFurnace);

      _invitations.sink.add(invitations);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitations.sink.addError(err);
    }
  }

  fetchInvitationsForUser(List<UserFurnace> userFurnaces,
      {bool force = false}) async {
    List<Invitation> entireList = [];

    try {
      if (globalState.lastInvitationByUserFetch != null && !force) {
        Duration duration =
            DateTime.now().difference(globalState.lastInvitationByUserFetch!);

        if (duration.inSeconds < 10) return;
      }

      globalState.lastInvitationByUserFetch = DateTime.now();

      debugPrint('hit fetchInvitationsForUser');

      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected == true) {
          try {
            //debugPrint('break');
            //keep processing even if one furnace fails
            List<Invitation> invitations = await _invitationService
                .fetchOpenInvitationsForUser(userFurnace);

            for (Invitation invitation in invitations) {
              invitation.userFurnace = userFurnace;
              entireList.add(invitation);
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InvitationsBloc.fetchInvitationsForUser.forLoop: $err');
          }
        }
      }

      _invitations.sink.add(entireList);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InvitationsBloc.fetchInvitationsForUser: $err');
      _invitations.sink.addError(entireList);
    }
  }

  findUsersByUsername(String username, List<UserFurnace> userFurnaces) async {
    try {
      List<User> users = [];

      for (UserFurnace userFurnace in userFurnaces) {
        try {
          if (userFurnace.connected!) {
            User user =
                await _invitationService.findUser(username, userFurnace);

            user.userFurnace = userFurnace;
            users.add(user);
          }
        } catch (err) {
          ///no need to log this
          debugPrint('$err');
        }
      }

      _findUsers.sink.add(users);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("invitations_bloc:findUsersByUsername $err");
      _findUsers.sink.addError(err);
    }
  }

  sendInvitationsToMember(
      User member, Iterable<UserCircleCache> userCircleCaches) async {
    try {
      for (UserCircleCache userCircleCache in userCircleCaches) {
        try {
          sendInvitationByID(member.id!, userCircleCache.circle!,
              userCircleCache, userCircleCache.furnaceObject!, false);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }

      _sendMultipleInvitationsResponse.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("invitations_bloc:sendInvitation $err");
      _sendInviteResponse.sink.addError(err);
    }
  }

  sendInvitation(String username, String? circleID,
      UserCircleCache userCircleCache, UserFurnace userFurnace, bool dm) async {
    Invitation? invitation;

    try {
      invitation = await _invitationService.sendInvitation(
          username, '', circleID, userCircleCache, userFurnace, dm);

      _sendInviteResponse.sink.add(invitation);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("invitations_bloc:sendInvitation $err");
      _sendInviteResponse.sink.addError(err);
    }
  }

  sendInvitationByID(String id, String? circleID,
      UserCircleCache userCircleCache, UserFurnace userFurnace, bool dm) async {
    Invitation? invitation;

    try {
      invitation = await _invitationService.sendInvitation(
          '', id, circleID, userCircleCache, userFurnace, dm);

      _sendInviteResponse.sink.add(invitation);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("invitations_bloc:sendInvitation $err");
      _sendInviteResponse.sink.addError(err);
    }
  }

  decline(Invitation invitation) async {
    try {
      await _invitationService.decline(invitation);

      invitation.status = InvitationStatus.DECLINED;

      _invitationResponse.sink.add(invitation);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitationResponse.sink.addError(err);
    }
  }

  cancelDM(UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      await _invitationService.cancelDM(userFurnace, userCircleCache);
      // await TableMemberCircle.deleteAll();
      if (userCircleCache.dmMember != null) {
        await TableMemberCircle.deleteDMNoCircleID(
            userFurnace.userid!, userCircleCache.dmMember!);
      } else {
        TableMemberCircle.deleteAllForCircle(userCircleCache.circle!);
      }

      _dmCanceled.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitationResponse.sink.addError(err);
    }
  }

  cancel(UserFurnace userFurnace, Invitation invitation) async {
    try {
      bool success = await _invitationService.cancel(userFurnace, invitation);

      if (success) {
        invitation.status = InvitationStatus.CANCELED;
        _invitationResponse.sink.add(invitation);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitationResponse.sink.addError(err);
    }
  }

  accept(UserCircleBloc userCircleBloc, Invitation invitation) async {
    try {
      await _invitationService.accept(userCircleBloc, invitation);

      invitation.status = InvitationStatus.ACCEPTED;

      _invitationResponse.sink.add(invitation);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitationResponse.sink.addError(err);
    }
  }

  addToBlockedListFromInvitation(Invitation invitation) async {
    try {
      await _invitationService.addToBlockedList(
          invitation.userFurnace, invitation.inviterID);

      invitation.status = "blocked";

      _invitationResponse.sink.add(invitation);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _invitationResponse.sink.addError(err);
    }
  }

  removeFromBlockedList(User user) async {
    try {
      User? retValue = await _invitationService.removeFromBlockedList(
          user.userFurnace!, user.id!);
      if (retValue != null) _removedFromBlockedlist.sink.add(user);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _removedFromBlockedlist.sink.addError(err);
    }
  }

  fetchBlockedlist(List<UserFurnace> userFurnaces) async {
    try {
      debugPrint('hit fetchBlockedlist');

      List<User> retValue = [];

      for (UserFurnace userFurnace in userFurnaces) {
        if (userFurnace.connected!) {
          User furnaceUser =
              await _invitationService.fetchBlockedList(userFurnace);

          if (furnaceUser.blockedList != null) {
            for (User user in furnaceUser.blockedList!) {
              user.userFurnace = userFurnace;
            }
          }

          if (furnaceUser.allowedList != null) {
            for (User user in furnaceUser.allowedList!) {
              user.userFurnace = userFurnace;
            }
          }

          retValue.add(furnaceUser);
        }
      }

      _blockedList.sink.add(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _blockedList.sink.addError(err);
    }
  }

  static saveInvitationFromNotification(
      GlobalEventBloc globalEventBloc, Invitation invitation) async {
    try {
      int existsCount = await TableInvitation.invitationExists(invitation);

      //LogBloc.insertLog("Invitation existsCount: $existsCount", "saveInvitationFromNotification");

      if (existsCount == 0) {
        ///make sure the user didn't deal with the invitation already
        existsCount = await TableDeleteIDTracker.exists(invitation.id!);
      }

      //LogBloc.insertLog("Invitation existsCount 2: $existsCount", "saveInvitationFromNotification");

      if (existsCount == 0) {
        RatchetKeyAndMap ratchetKeyAndMap =
            await ForwardSecrecyUser.decryptUserObject(
                invitation.ratchetIndex!, invitation.inviteeID);

        Map<String, dynamic> decrypted = ratchetKeyAndMap.map;

        UserCircleEnvelope userCircleEnvelope =
            UserCircleEnvelope.fromJsonObject(decrypted);

        invitation.circleName = userCircleEnvelope.contents.circleName;

        await TableInvitation.upsert(invitation);

        //LogBloc.insertLog("Invitation cached", "saveInvitationFromNotification");
        globalEventBloc.broadcastInvitationReceived(invitation);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  dispose() async {
    await _invitations.drain();
    _invitations.close();

    await _sendInviteResponse.drain();
    _sendInviteResponse.close();

    await _invitationResponse.drain();
    _invitationResponse.close();

    await _blockedList.drain();
    _blockedList.close();

    await _removedFromBlockedlist.drain();
    _removedFromBlockedlist.close();

    await _addToBlockedlist.drain();
    _addToBlockedlist.close();

    await _findUsers.drain();
    _findUsers.close();

    await _sendMultipleInvitationsResponse.drain();
    _sendMultipleInvitationsResponse.close();

    await _dmCanceled.drain();
    _dmCanceled.close();
  }
}
