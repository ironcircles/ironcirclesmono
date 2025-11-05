import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/export_insidecircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/unknownobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallalbum_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallevent_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallfile_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallgif_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallimage_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/walllink_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/walllist_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallmessage_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallmessagesubtype_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallrecipe_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallvideo_streaming_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallvideo_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallvote_widget.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/reactions_row.dart';

class InsideWallDetermineWidget extends StatelessWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Circle circle;
  final List<CircleObject> circleObjects;
  final List<ReplyObject> replyObjects;
  final int index;
  //final List<User> ;
  final Function tapHandler;
  final Function shareObject;
  final Function unpinObject;
  final Function longPressHandler;
  final Function longReaction;
  final Function shortReaction;
  final Function storePosition;
  final Function copyObject;
  final Function reactionAdded;
  final Function showReactions;
  final bool displayReactionsRow;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;
  final CircleVideoBloc circleVideoBloc;
  final CircleRecipeBloc circleRecipeBloc;
  final CircleObjectBloc circleObjectBloc;
  final CircleImageBloc circleImageBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final CircleFileBloc circleFileBloc;
  final ReplyObjectBloc replyObjectBloc;
  final GlobalEventBloc globalEventBloc;
  final MemberBloc memberBloc;
  final Function updateList;
  final Function submitVote;
  final Function deleteObject;
  final Function editObject;
  final Function streamVideo;
  final Function downloadVideo;
  final Function downloadFile;
  final Function retry;
  final Function removeCache;
  final Function predispose;
  final Function playVideo;
  final Function openExternalBrowser;
  final Function leave;
  final Function export;
  final Function cancelTransfer;
  final Function populateVideoFile;
  final Function populateRecipeImageFile;
  final Function populateImageFile;
  final Function populateAlbum;
  final Function populateFile;
  final bool interactive;
  final bool reverse;
  final List<Member> members;
  final Function refresh;
  final double maxWidth;

  const InsideWallDetermineWidget({
    Key? key,
    required this.members,
    required this.reverse,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleObjects,
    required this.replyObjects,
    required this.index,
    //required this.users,
    required this.circle,
    required this.maxWidth,
    required this.tapHandler,
    required this.shareObject,
    required this.unpinObject,
    required this.openExternalBrowser,
    required this.leave,
    required this.export,
    required this.cancelTransfer,
    required this.longPressHandler,
    required this.longReaction,
    required this.shortReaction,
    required this.storePosition,
    required this.copyObject,
    required this.reactionAdded,
    required this.showReactions,
    required this.populateFile,
    required this.videoControllerBloc,
    required this.videoControllerDesktopBloc,
    required this.globalEventBloc,
    required this.circleVideoBloc,
    required this.circleObjectBloc,
    required this.circleFileBloc,
    required this.circleImageBloc,
    required this.circleAlbumBloc,
    required this.circleRecipeBloc,
    required this.replyObjectBloc,
    required this.memberBloc,
    required this.updateList,
    required this.submitVote,
    required this.deleteObject,
    required this.editObject,
    required this.streamVideo,
    required this.downloadVideo,
    required this.downloadFile,
    required this.retry,
    required this.predispose,
    required this.playVideo,
    required this.removeCache,
    required this.populateVideoFile,
    required this.populateRecipeImageFile,
    required this.populateImageFile,
    required this.populateAlbum,
    required this.displayReactionsRow,
    required this.interactive,
    required this.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _maxWidth = maxWidth;

    Widget reactions(CircleObject circleObject, List<ReplyObject> replies,
        Color messageColor) {
      return ReactionsRow(
        isUser: false,
        circleObject: circleObject,
        longPress: longReaction,
        showReactions: showReactions,
        shortPress: shortReaction,
        reactionChanged: reactionAdded,
        userID: userFurnace.userid!,
        replyObjects: replies,
        userFurnace: userFurnace,
        replyObjectBloc: replyObjectBloc,
        messageColor: messageColor,
        refresh: refresh,
        maxWidth: _maxWidth,
        userCircleCache: userCircleCache,
        globalEventBloc: globalEventBloc,
        memberBloc: memberBloc,
        wall: true,
      );
    }

    final separator = Container(
      color: globalState.theme.background,
      height: 1,
      width: double.maxFinite,
    );

    final CircleObject item = circleObjects[index];

    if (globalState.isDesktop()) {
      if (item.type == CircleObjectType.CIRCLEMESSAGE) {
        _maxWidth = maxWidth * 0.8;
      } else {
        _maxWidth = maxWidth / 3;
      }
    }

    CircleObject? replyObject;
    if (item.replyObjectID != null) {
      replyObject = circleObjects
          .firstWhere((element) => element.id == item.replyObjectID);
    }

    bool showAvatar = true;
    bool showDate = true;
    bool showTime = true;

    if (index > 0) {
      DateTime? itemDate = item.created;
      String? itemDateString = item.date;

      if (item.type == CircleObjectType.CIRCLELIST ||
          item.type == CircleObjectType.CIRCLEVOTE ||
          item.type == CircleObjectType.CIRCLERECIPE) {
        itemDate = item.lastUpdate;
        itemDateString = item.lastUpdatedDate;
      }

      ///list is not in reverse

      DateTime lastItemDate = circleObjects[index - 1].created!;

      String? lastItemDateString = circleObjects[index - 1].date;

      if (item.type == CircleObjectType.CIRCLELIST ||
          item.type == CircleObjectType.CIRCLEVOTE ||
          item.type == CircleObjectType.CIRCLERECIPE) {
        lastItemDate = circleObjects[index - 1].lastUpdate!;
        lastItemDateString = circleObjects[index - 1].lastUpdatedDate;
      }

      if (itemDateString == lastItemDateString) {
        showDate = false;
      }
    }

    List<ReplyObject> replies = replyObjects
        .where((element) => element.circleObjectID == item.id)
        .toList();

    item.showDate = showDate;

    if (!interactive) {
      showDate = false;
      showTime = true;
      item.showOptionIcons = true;
    }

    item.interactive = interactive;

    Color messageColor = Colors.red;

    if (item.creator != null && item.creator!.id != userFurnace.userid) {
      messageColor = Member.getMemberColor(userFurnace, item.creator);
    } else {
      messageColor = globalState.theme.button;
    }

    Color replyMessageColor =
        Member.getReplyMemberColor(item, userCircleCache.user!, userFurnace);

    ///sanity check
    switch (item.type) {
      case CircleObjectType.CIRCLEFILE:
        if (item.file == null) return Container();
        break;
    }

    ///Call the appropriate widget based on the object type

    if (item.type == CircleObjectType.CIRCLECREDENTIAL) {
      return Column(
          key: item.globalKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
                onLongPress: () {
                  userFurnace.userid == item.creator!.id
                      ? longPressHandler(item, showDate, true,
                          edit: editObject,
                          copy: copyObject,
                          share: item.subType == SubType.LOGIN_INFO
                              ? shareObject
                              : null)
                      : longPressHandler(item, showDate, false,
                          copy: copyObject,
                          share: item.subType == SubType.LOGIN_INFO
                              ? shareObject
                              : null);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: WallMessageSubTypeWidget(
                    item,
                    userFurnace,
                    showAvatar,
                    showDate,
                    showTime,
                    messageColor,
                    circle,
                    unpinObject,
                    refresh,
                    _maxWidth)),
            displayReactionsRow
                ? reactions(item, replies, messageColor)
                : Container(),
            separator,
          ]);
    } else if (item.type == CircleObjectType.CIRCLEMESSAGE) {
      return Column(
          key: item.globalKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
                onLongPress: () {
                  userFurnace.userid == item.creator!.id
                      ? longPressHandler(item, showDate, true,
                          edit: editObject,
                          copy: copyObject,
                          share: item.subType == SubType.LOGIN_INFO
                              ? shareObject
                              : null)
                      : longPressHandler(item, showDate, false,
                          copy: copyObject,
                          share: item.subType == SubType.LOGIN_INFO
                              ? shareObject
                              : null);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: item.subType == null
                    ? WallMessageWidget(
                        item,
                        replyObject,
                        null,
                        userCircleCache,
                        userFurnace,
                        showAvatar,
                        showDate,
                        showTime,
                        messageColor,
                        replyMessageColor,
                        unpinObject,
                        refresh,
                        _maxWidth,
                      )
                    : WallMessageSubTypeWidget(
                        item,
                        userFurnace,
                        showAvatar,
                        showDate,
                        showTime,
                        messageColor,
                        circle,
                        unpinObject,
                        refresh,
                        _maxWidth)),
            displayReactionsRow
                ? reactions(item, replies, messageColor)
                : Container(),
            separator,
          ]);
    } else if (item.type == CircleObjectType.CIRCLEALBUM) {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        return Column(children: [
          UnknownObject(
              item,
              "Unsupported message type. This probably means you need to upgrade to see this message",
              true,
              false,
              false),
          separator,
        ]);
      } else {
        populateAlbum(item, userFurnace, userCircleCache, circleAlbumBloc,
            circleObjectBloc);

        return Column(key: item.globalKey, children: [
          GestureDetector(
              onLongPress: () {
                userFurnace.userid == item.creator!.id
                    ? longPressHandler(item, showDate, true,
                        share: shareObject, edit: editObject)
                    : longPressHandler(item, showDate, false,
                        share: shareObject, edit: editObject);
              },
              onTap: () {
                tapHandler(item);
              },
              //onTapDown: storePosition,
              child: WallAlbumWidget(
                  item,
                  replyObject,
                  null,
                  userCircleCache,
                  userFurnace,
                  showAvatar,
                  showDate,
                  showTime,
                  messageColor,
                  replyMessageColor,
                  circle,
                  unpinObject,
                  refresh,
                  maxWidth)),
          displayReactionsRow
              ? reactions(item, replies, messageColor)
              : Container(),
          separator,
        ]);
      }
    } else if (item.type == CircleObjectType.SYSTEMMESSAGE) {
      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              longPressHandler(item, showDate, false);
            },
            onTap: () {
              tapHandler(item);
            },
            //onTapDown: storePosition,
            child: SystemMessageWidget(
                item, showAvatar, showTime, showDate, _maxWidth)),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLELINK) {
      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(item, showDate, true,
                      share: shareObject,
                      edit: editObject,
                      openExternalBrowser: openExternalBrowser,
                      copy: copyObject)
                  : longPressHandler(item, showDate, false,
                      share: shareObject,
                      openExternalBrowser: openExternalBrowser,
                      copy: copyObject);
            },
            onTap: () {
              tapHandler(item);
            },
            child: WallLinkWidget(
                item,
                replyObject,
                userCircleCache,
                showAvatar,
                showDate,
                showTime,
                messageColor,
                replyMessageColor,
                userFurnace,
                circle,
                unpinObject,
                refresh,
                interactive,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEGIF) {
      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(
                      item,
                      showDate,
                      true,
                      share: shareObject,
                      copy: copyObject,
                      edit: editObject,
                    )
                  : longPressHandler(
                      item,
                      showDate,
                      true,
                      share: shareObject,
                      copy: copyObject,
                      edit: editObject,
                    );
            },
            onTap: () {
              tapHandler(item);
            },
            child: WallGifWidget(
                item,
                replyObject,
                null,
                userCircleCache,
                userFurnace,
                showAvatar,
                showDate,
                showTime,
                messageColor,
                replyMessageColor,
                circle,
                unpinObject,
                refresh,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEVOTE) {
      return Column(key: item.globalKey, children: [
        GestureDetector(
          onLongPress: () {
            userFurnace.userid == item.creator!.id
                ? longPressHandler(item, showDate, true)
                : longPressHandler(item, showDate, false);
          },
          onTap: () {
            tapHandler(item);
          },
          //onTapDown: storePosition,
          child: WallVoteWidget(
              item,
              userFurnace,
              interactive,
              showAvatar,
              showDate,
              showTime,
              submitVote,
              userCircleCache.user,
              leave,
              messageColor,
              unpinObject,
              refresh,
              _maxWidth),
        ),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLELIST) {
      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(item, showDate, true, share: shareObject)
                  : longPressHandler(item, showDate, false, share: shareObject);
            },
            onTap: () {
              tapHandler(item);
            },
            //onTapDown: storePosition,
            child: WallListWidget(
                item,
                userFurnace,
                interactive,
                showAvatar,
                showDate,
                showTime,
                updateList,
                messageColor,
                unpinObject,
                refresh,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEEVENT) {
      //populateRecipeImageFile(item);

      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(item, showDate, true, share: shareObject)
                  : longPressHandler(item, showDate, false, share: shareObject);
            },
            onTap: () {
              tapHandler(item);
            },
            //onTapDown: storePosition,
            child: WallEventWidget(
                item,
                userFurnace,
                showAvatar,
                showDate,
                showTime,
                messageColor,
                circle,
                unpinObject,
                refresh,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLERECIPE) {
      populateRecipeImageFile(item, userFurnace, userCircleCache,
          globalEventBloc, circleRecipeBloc);

      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(item, showDate, true, share: shareObject)
                  : longPressHandler(item, showDate, false, share: shareObject);
            },
            onTap: () {
              tapHandler(item);
            },
            // onTapDown: storePosition,
            child: WallRecipeWidget(
                item,
                userFurnace,
                showAvatar,
                showDate,
                showTime,
                userCircleCache,
                messageColor,
                unpinObject,
                refresh,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEFILE) {
      populateFile(item, userFurnace, userCircleCache, circleFileBloc);

      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(
                      item, showDate, true,
                      share: shareObject,
                      export: export, //edit: editObject,
                      download: item.draft == false &&
                              (item.fullTransferState == BlobState.UNKNOWN ||
                                  item.fullTransferState ==
                                      BlobState.NOT_DOWNLOADED)
                          ? downloadVideo
                          : null,
                      cancel: item.draft == false &&
                              item.fullTransferState == BlobState.DOWNLOADING
                          ? cancelTransfer
                          : null,
                      deleteCache: item.draft == false &&
                              item.fullTransferState == BlobState.READY
                          ? removeCache
                          : null,
                    )
                  : longPressHandler(
                      item,
                      showDate,
                      false,
                      share: shareObject,
                      export: export,
                      download: item.draft == false &&
                              (item.fullTransferState == BlobState.UNKNOWN ||
                                  item.fullTransferState ==
                                      BlobState.NOT_DOWNLOADED)
                          ? downloadVideo
                          : null,
                      cancel: item.draft == false &&
                              item.fullTransferState == BlobState.DOWNLOADING
                          ? cancelTransfer
                          : null,
                      deleteCache: item.draft == false &&
                              item.fullTransferState == BlobState.READY
                          ? removeCache
                          : null,
                    );
            },
            onTap: () {
              tapHandler(item);
            },
            // onTapDown: storePosition,
            child: WallFileWidget(
                userCircleCache,
                interactive,
                userFurnace,
                item,
                showAvatar,
                messageColor,
                showDate,
                showTime,
                downloadFile,
                retry,
                circle,
                unpinObject,
                refresh,
                _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEIMAGE) {
      populateImageFile(item, userFurnace, userCircleCache, circleImageBloc,
          circleObjectBloc);

      return Column(key: item.globalKey, children: [
        GestureDetector(
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(item, showDate, true,
                      share: shareObject, export: export, edit: editObject)
                  : longPressHandler(
                      item,
                      showDate,
                      false,
                      share: shareObject,
                    );
            },
            onTap: () {
              tapHandler(item);
            },
            // onTapDown: storePosition,
            child: WallImageWidget(
              globalEventBloc,
              userCircleCache,
              userFurnace,
              item,
              replyObject,
              showAvatar,
              showDate,
              showTime,
              messageColor,
              replyMessageColor,
              circle,
              retry,
              unpinObject,
              refresh,
              _maxWidth,
            )),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEVIDEO) {
      if (item.video == null && (item.draft == false)) return Container();

      ChewieController? controller;

      if (item.draft == false) {
        if (item.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          controller = videoControllerBloc.fetchController(item);
          populateVideoFile(item, userFurnace, userCircleCache, circleVideoBloc,
              videoControllerBloc, videoControllerDesktopBloc);
        }
      }

      return Column(key: item.globalKey, children: [
        GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              userFurnace.userid == item.creator!.id
                  ? longPressHandler(
                      item,
                      showDate,
                      true,
                      share: shareObject,
                      export: export,
                      edit: editObject,
                      download: item.video!.streamable! &&
                              !item.video!.streamableCached
                          ? downloadVideo
                          : null,
                      cancel: item.video!.videoState ==
                              VideoStateIC.DOWNLOADING_VIDEO
                          ? cancelTransfer
                          : null,
                      deleteCache: (!item.video!.streamable! ||
                              item.video!.streamableCached)
                          ? item.video!.videoState ==
                                      VideoStateIC.VIDEO_READY ||
                                  item.video!.videoState ==
                                      VideoStateIC.NEEDS_CHEWIE
                              ? removeCache
                              : null
                          : null,
                    )
                  : longPressHandler(
                      item,
                      showDate,
                      false,
                      share: shareObject,
                      download: item.video!.streamable! &&
                              !item.video!.streamableCached
                          ? downloadVideo
                          : null,
                      cancel: item.video!.videoState ==
                              VideoStateIC.DOWNLOADING_VIDEO
                          ? cancelTransfer
                          : null,
                      deleteCache: (!item.video!.streamable! ||
                              item.video!.streamableCached)
                          ? item.video!.videoState ==
                                      VideoStateIC.VIDEO_READY ||
                                  item.video!.videoState ==
                                      VideoStateIC.NEEDS_CHEWIE
                              ? removeCache
                              : null
                          : null,
                    );
            },
            onTap: () {
              // Only handle tap if it's not on the video controls area
              // This allows Chewie controls to receive touch events
              tapHandler(item);
            },
            //onTapDown: storePosition,
            child: item.video!.streamable! &&
                    !item.video!.streamableCached &&
                    item.id != null
                ? WallVideoStreamingWidget(
                    userCircleCache,
                    interactive,
                    userFurnace,
                    item,
                    replyObject,
                    showAvatar,
                    showDate,
                    showTime,
                    downloadVideo,
                    streamVideo,
                    item.video!.videoState == VideoStateIC.VIDEO_READY ||
                            item.video!.videoState ==
                                VideoStateIC.NEEDS_CHEWIE ||
                            item.video!.videoState ==
                                VideoStateIC.VIDEO_UPLOADED
                        ? removeCache
                        : null,
                    circle,
                    predispose,
                    unpinObject,
                    refresh,
                    _maxWidth,
                    messageColor)
                : WallVideoWidget(
                    userCircleCache,
                    userFurnace,
                    item,
                    replyObject,
                    true,
                    showDate,
                    true,
                    downloadVideo,
                    playVideo,
                    circle,
                    controller,
                    retry,
                    videoControllerBloc,
                    removeCache,
                    messageColor,
                    replyMessageColor,
                    unpinObject,
                    interactive,
                    refresh,
                    _maxWidth)),
        displayReactionsRow
            ? reactions(item, replies, messageColor)
            : Container(),
      ]);
    } else if (item.type == CircleObjectType.UNABLETODECRYPT) {
      bool suppress = false;

      if (index < circleObjects.length - 1) {
        if (circleObjects[index + 1].type == CircleObjectType.UNABLETODECRYPT)
          suppress = true;
      }

      return suppress
          ? Container()
          : Column(children: [
              UnableToDecrypt(
                  circleObject: item, showDate: false, showTime: false),
              separator,
            ]);
      //}
    } else {
      if (item.type != null) {
        return GestureDetector(
            key: item.globalKey,
            onLongPress: () {
              longPressHandler(item, showDate, false);
            },
            onTap: () {
              tapHandler(item);
            },
            //onTapDown: storePosition,
            child: CircleMessageUserWidget(
              userCircleCache: userCircleCache,
              unpinObject: unpinObject,
              circleObject: item,
              userFurnace: userFurnace,
              showAvatar: showAvatar,
              showDate: showDate,
              showTime: showTime,
              refresh: refresh,
              maxWidth: _maxWidth,
            ));
      } else {
        return Column(children: [
          UnknownObject(
              item,
              "Unsupported message type. This probably means you need to upgrade to see this message",
              true,
              false,
              false),
          separator,
        ]);
      }
    }
  }
}
