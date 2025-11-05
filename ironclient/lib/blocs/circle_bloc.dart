import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circlecache.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/circle_background_service.dart';
import 'package:ironcirclesapp/services/circle_service.dart';
import 'package:ironcirclesapp/services/membercircles_service.dart';
import 'package:rxdart/rxdart.dart';

class CircleBloc {
  static const String CIRCLE_DELETED = 'circle deleted';
  static const String DM_DELETED = 'dm deleted';
  static const String CIRCLE_DELETE_VOTE_CREATED =
      'Vote to delete'; //'created vote';

  final _circleService = CircleService();
  //final _blobService = CircleBackgroundService();
  final _circleBackgroundService = CircleBackgroundService();

  final _fetched = PublishSubject<Circle>();
  Stream<Circle> get fetchedResponse => _fetched.stream;

  final _created = PublishSubject<bool>();
  Stream<bool> get createdResponse => _created.stream;

  final _createdUserCircleCache = PublishSubject<UserCircleCache>();
  Stream<UserCircleCache> get createdUserCircleCache =>
      _createdUserCircleCache.stream;

  final _createdWithInvites = PublishSubject<bool>();
  Stream<bool> get createdWithInvites => _createdWithInvites.stream;

  final PublishSubject<List<User?>> _membershipList =
      PublishSubject<List<User>>();
  Stream<List<User?>> get membershipList => _membershipList.stream;

  final _settingsUpdated = PublishSubject<Circle>();
  Stream<Circle> get settingsUpdated => _settingsUpdated.stream;

  final _deleteResponse = PublishSubject<String?>();
  Stream<String?> get deleteResponse => _deleteResponse.stream;

  final _removeMember = PublishSubject<String?>();
  Stream<String?> get removeMemberResponse => _removeMember.stream;

  final _membersNeedsRefresh = PublishSubject<bool>();
  Stream<bool> get membersNeedsRefresh => _membersNeedsRefresh.stream;

  final _settingsUpdatedMessage = PublishSubject<String>();
  Stream<String> get settingsUpdatedMessage => _settingsUpdatedMessage.stream;

  final _settingsVoteCreated = PublishSubject<CircleObject>();
  Stream<CircleObject> get settingsVoteCreated => _settingsVoteCreated.stream;

  final _keysGenerated = PublishSubject<bool>();
  Stream<bool> get keysGenerated => _keysGenerated.stream;

  fetchCircle(UserFurnace userFurnace, String circleID, DateTime? lastAccessed) async {
    try {
      Circle? retValue;

      _sinkCache(circleID);

      retValue = await _circleService.fetch(userFurnace, circleID, lastAccessed);

      if (retValue != null) _fetched.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc.fetchCircle + $error');
      _fetched.sink.addError(error);
    }
  }

  _sinkCache(String circleID) async {
    try {
      Circle? sinkValue = await TableCircleCache.read(circleID);

      if (sinkValue != null) _fetched.sink.add(sinkValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc.sinkCache + $error');
      _fetched.sink.addError(error);
    }
  }

  updateTemporaryExpiration(
      UserFurnace userFurnace, String circleID, String expiration) async {
    try {
      await _circleService.updateTemporaryExpiration(
          userFurnace, circleID, expiration, _updateSettingResponse);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc.updateTemporaryExpiration + $error');
      _settingsUpdated.sink.addError(error);
    }
  }

  updateVotingModel(UserFurnace userFurnace, String circleID, String change,
      String message, int settingChangeType) async {
    try {
      await _circleService.updateVotingModel(userFurnace, circleID, change,
          message, _updateSettingResponse, settingChangeType);

      //if (retValue != null) _settingsUpdated.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc.updateSetting + $error');
      _settingsUpdated.sink.addError(error);
    }
  }

  updateSetting(
      UserFurnace userFurnace,
      String circleID,
      List<CircleSettingValue> list,
      String message,
      int settingChangeType) async {
    try {
      await _circleService.updateSetting(userFurnace, circleID, list, message,
          _updateSettingResponse, settingChangeType);

      //if (retValue != null) _settingsUpdated.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc.updateSetting + $error');
      _settingsUpdated.sink.addError(error);
    }
  }

  _updateSettingResponse(
      Circle circle, String response, CircleObject? circleObject) {
    try {
      _settingsUpdated.sink.add(circle);
      _settingsUpdatedMessage.sink.add(response);

      if (circleObject != null) _settingsVoteCreated.sink.add(circleObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleBloc._updateSettingResponse + $error');
      _settingsUpdated.sink.addError(error);
    }
  }

  deleteCache(
      GlobalEventBloc globalEventBloc, UserCircleCache userCircleCache) async {
    try {
      await _deleteCircleFromCache(userCircleCache);

      TableMemberCircle.deleteAllForCircle(userCircleCache.circle!);

      globalEventBloc.removeObjectsForCircle(userCircleCache.circle!);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.deleteCache + $err');
      _deleteResponse.sink.addError(err);
    }
  }

  delete(GlobalEventBloc globalEventBloc, UserFurnace userFurnace,
      UserCircleCache userCircleCache) async {
    try {
      String? response =
          await _circleService.delete(userCircleCache.circle!, userFurnace);

      if (response == CIRCLE_DELETED || response == DM_DELETED) {
        await _deleteCircleFromCache(userCircleCache);

        ///also delete the MemberCircle
        TableMemberCircle.deleteAllForCircle(userCircleCache.circle!);
      }

      _deleteResponse.sink.add(response);
      globalEventBloc.removeObjectsForCircle(userCircleCache.circle!);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.delete + $err');
      _deleteResponse.sink.addError(err);
    }
  }

  removeMember(UserFurnace userFurnace, UserCircleCache userCircleCache,
      String memberID) async {
    try {
      String? response = await _circleService.removeMember(
          userFurnace, userCircleCache.circle, memberID);

      //TODO remove the removed usercache from the requesting device - low priority

      if (response == "") {
        _membersNeedsRefresh.sink.add(true);
      } else {
        _removeMember.sink.add(response);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.removeMember + $err');
      _removeMember.sink.addError(err);
    }
  }

  _deleteCircleFromCache(UserCircleCache userCircleCache) async {
    if (userCircleCache.circlePath != null)
      await FileSystemService.deleteCircleCache(userCircleCache.circlePath!);
    if (userCircleCache.circle != null) {
      await TableCircleObjectCache.deleteAllForCircle(userCircleCache.circle);
      MemberCircleService.deleteAllForCircle(userCircleCache.circle!);
    }
    if (userCircleCache.usercircle != null)
      await TableUserCircleCache.deleteUserCircle(userCircleCache.usercircle);
  }

  createAndSentInvitations(UserFurnace userFurnace, Circle circle, File? image,
      List<Member> members, Color? color) async {
    try {
      InvitationBloc invitationBloc = InvitationBloc();

      UserCircle userCircle = UserCircle(ratchetKeys: []);

      circle.dm = false;
      userCircle.prefName = circle.name;
      userCircle.hidden = false;

      UserCircleCache userCircleCache =
          await create(userFurnace, circle, userCircle, image, color);

      for (Member member in members) {
        try {
          if (member.selected)
            invitationBloc.sendInvitation(member.username,
                userCircleCache.circle!, userCircleCache, userFurnace, false);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('CircleBloc.createAndSentInvitations + $err');
        }
      }

      _createdWithInvites.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.createAndSentInvitations + $err');
      _created.sink.addError(err);
    }
  }

  create(UserFurnace userFurnace, Circle circle, UserCircle userCircle,
      File? image, Color? color) async {
    try {
      DecryptArguments? fullArgs;
      String thumbnail = '';

      circle.name = await TableUserCircleCache.returnUniqueName(
          userFurnace.pk!, userFurnace.userid!, circle.name!);
      userCircle.prefName = circle.name;

      if (image != null) {
        thumbnail = await ImageCacheService.compressImage(
            image, await FileSystemService.returnTempPathAndImageFile(), 20);

        if (!File(thumbnail).existsSync()) throw ('image compression failed');

        fullArgs = await EncryptBlob.encryptBlob(thumbnail);
      }

      userCircle = await _circleService.create(
          circle, userCircle, color, userFurnace, fullArgs);

      UserCircleCache userCircleCache = UserCircleCache();
      userCircleCache.refreshFromUserCircle(userCircle, userFurnace.pk);

      userCircleCache.circleName = circle.name;
      userCircleCache.prefName = circle.name;
      userCircleCache.crank = userCircle.ratchetIndex!.crank;

      await TableUserCircleCache.upsert(userCircleCache);

      if (thumbnail.isNotEmpty) {
        await uploadBackground(
            userFurnace, userCircleCache, File(thumbnail), fullArgs!);

        //delete the encrypted version and the cache
        //FileSystemService.safeDelete(fullArgs.encrypted);  //handled in the service
        FileSystemService.safeDelete(image!);
        FileSystemService.safeDelete(File(thumbnail));
      }

      _created.sink.add(true);

      return userCircleCache;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.create + $err');
      _created.sink.addError(err);
    }
  }

  createDirectMessageWithNewUser(GlobalState globalState,
      InvitationBloc invitationBloc, UserFurnace userFurnace, User user) async {
    try {
      MemberBloc memberBloc = MemberBloc();

      Member member = globalState.members
          .firstWhere((element) => element.memberID == user.id!, orElse: () {
        return Member(alias: '', memberID: '', userID: '');
      });

      AvatarService avatarService = AvatarService();
      avatarService.downloadAvatar(userFurnace, user);

      if (member.userID.isEmpty) {
        member = memberBloc.create(globalState, userFurnace, user)!;
      }

      ///no need to wait
      createDirectMessage(invitationBloc, userFurnace, member);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.createDirectMessageWithNewUser + $err');
      _created.sink.addError(err);
    }
  }

  createDirectMessage(InvitationBloc invitationBloc, UserFurnace userFurnace,
      Member member) async {
    try {
      Circle circle = Circle();
      UserCircle userCircle = UserCircle(ratchetKeys: []);

      circle.dm = true;
      circle.ownershipModel = CircleOwnership.MEMBERS;

      circle.name = "${member.username} / ${userFurnace.username!}";
      userCircle.prefName = member.username;
      userCircle.hidden = false;
      userCircle.dmConnected = false;

      ///set the defaults
      circle.privacyDisappearingTimer = 0;
      circle.privacyCopyText = true;
      circle.privacyShareGif = true;
      circle.privacyShareImage = true;
      circle.privacyShareURL = true;

      userCircle = await _circleService.create(
          circle, userCircle, null, userFurnace, null,
          memberID: member.memberID, memberName: member.username);

      UserCircleCache userCircleCache = UserCircleCache();
      userCircleCache.refreshFromUserCircle(userCircle, userFurnace.pk);

      circle.name = "${member.username} / ${userFurnace.username!}";
      userCircle.prefName = member.username;
      userCircleCache.crank = userCircle.ratchetIndex!.crank;

      await TableUserCircleCache.upsert(userCircleCache);

      await MemberCircleService.upsert(MemberCircle(
          memberID: member.memberID,
          userID: userFurnace.userid!,
          circleID: userCircleCache.circle!,
          dm: true));

      ///if an invitation was already pending (refresh issue), the user was auto-joined so don't send an invitation
      if (!userCircle.dmConnected) {
        ///Send the invite
        await invitationBloc.sendInvitation(member.username,
            userCircle.circle!.id!, userCircleCache, userFurnace, true);
      }

      _createdUserCircleCache.sink.add(userCircleCache);
      _created.sink.add(true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.create + $err');
      _created.sink.addError(err);
      _createdUserCircleCache.sink.addError(err);
    }
  }

  getMembershipList(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    List<User> retValue = [];

    try {
      List<UserCircle> userCircles =
          await _circleService.getMembershipList(userCircleCache, userFurnace);

      for (UserCircle userCircle in userCircles) {
        retValue.add(userCircle.user!);
      }

      retValue.sort((a, b) {
        return a.username!.toLowerCase().compareTo(b.username!.toLowerCase());
      });

      _membershipList.sink.add(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.getMembershipList + $err');
      _membershipList.sink.addError(err);
    }
  }

  /*
  replaceBackground(UserFurnace userFurnace, UserCircleCache userCircleCache,
      File image) async {
    await _blobService.uploadCircleBackground(
        userFurnace, userCircleCache, image);

    _circlewideUpdate.sink.add(true);
  }
  */

  uploadBackground(UserFurnace userFurnace, UserCircleCache userCircleCache,
      File compressed, DecryptArguments args) async {
    try {
      await _circleBackgroundService.uploadCircleBackground(
          userFurnace, userCircleCache, compressed, args);

      //debugPrint('hold');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.uploadBackground + $err');
    }
  }

  /*
  voteRemoveMember(UserFurnace userFurnace, String removeUserid) async {
    await _blobService.uploadCircleBackground(
        userFurnace, userCircleCache, image);
  }

  removeMember(UserFurnace userFurnace, String removeUserid) async {
    await _blobService.uploadCircleBackground(
        userFurnace, userCircleCache, image);
  }
*/

  downloadBackground(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
  ) async {
    try {
      await _circleBackgroundService.downloadCircleBackground(
          userFurnace, userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBloc.downloadBackground + $err');
    }
  }

  dispose() async {
    await _created.drain();
    _created.close();

    await _membershipList.drain();
    _membershipList.close();

    await _settingsUpdated.drain();
    _settingsUpdated.close();

    await _deleteResponse.drain();
    _deleteResponse.close();

    await _removeMember.drain();
    _removeMember.close();

    await _fetched.drain();
    _fetched.close();

    await _settingsUpdatedMessage.drain();
    _settingsUpdatedMessage.close();

    await _keysGenerated.drain();
    _keysGenerated.close();

    await _settingsVoteCreated.drain();
    _settingsVoteCreated.close();

    await _createdWithInvites.drain();
    _createdWithInvites.close();

    await _createdUserCircleCache.drain();
    _createdUserCircleCache.close();

    await _membersNeedsRefresh.drain();
    _membersNeedsRefresh.close();
  }
}
