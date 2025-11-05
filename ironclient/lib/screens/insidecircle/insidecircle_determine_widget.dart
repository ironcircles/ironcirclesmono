import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlealbum_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlealbum_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleevent_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleevent_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlefile_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlefile_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlemessagesubtype_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlemessagesubtype_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleonetimeview_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevideo_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevideo_streaming_member_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevideo_streaming_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevideo_user_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/export_insidecircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/unknownobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleagoracall_detail.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/reactions_row.dart';

class InsideCircleDetermineWidget extends StatelessWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Circle circle;
  final List<CircleObject> circleObjects;
  final int index;
  //final List<User> ;
  final Function tapHandler;
  final Function shareObject;
  final Function unpinObject;
  final Function longPressHandler;
  final Function? scrollToIndex;
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
  final GlobalEventBloc globalEventBloc;
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

  const InsideCircleDetermineWidget({
    Key? key,
    this.scrollToIndex,
    required this.members,
    required this.reverse,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleObjects,
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
    required this.circleRecipeBloc,
    required this.circleAlbumBloc,
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

    final separator = Container(
      color: globalState.theme.background,
      height: 1,
      width: double.maxFinite,
    );

    Widget reactions(CircleObject circleObject,
        Color messageColor) {
      return ReactionsRow(
        isUser:   userFurnace.userid == circleObject.creator!.id,
        circleObject: circleObject,
        longPress: longReaction,
        showReactions: showReactions,
        shortPress: shortReaction,
        reactionChanged: reactionAdded,
        userID: userFurnace.userid!,
        replyObjects: const [],
        userFurnace: userFurnace,
        replyObjectBloc: null,
        messageColor: messageColor,
        refresh: refresh,
        maxWidth: _maxWidth,
        userCircleCache: userCircleCache,
        globalEventBloc: globalEventBloc,
        memberBloc: null,
      );
    }






    final CircleObject item = circleObjects[index];

    if (globalState.isDesktop()){
      if (item.type == CircleObjectType.CIRCLEMESSAGE){
        _maxWidth = maxWidth * 0.8;
      } else {
        _maxWidth = maxWidth / 2;
      }
    }

    CircleObject? replyObject;
    if (item.replyObjectID != null) {
      int index= circleObjects.indexWhere((element) => element.id == item.replyObjectID);
      if (index > -1) {
        replyObject = circleObjects[index];
      }
    }

    bool showAvatar = true;
    bool showDate = true;
    bool showTime = true;

    DateTime? itemDate = item.created;
    String? itemDateString = item.date;

    if (item.type == CircleObjectType.CIRCLELIST ||
        item.type == CircleObjectType.CIRCLEVOTE ||
        item.type == CircleObjectType.CIRCLERECIPE) {
      itemDate = item.lastUpdate;
      itemDateString = item.lastUpdatedDate;
    }

    if (reverse) {
      if (index < circleObjects.length - 1) {
        DateTime lastItemDate = circleObjects[index + 1].created!;

        String? lastItemDateString = circleObjects[index + 1].date;

        if (item.type == CircleObjectType.CIRCLELIST ||
            item.type == CircleObjectType.CIRCLEVOTE ||
            item.type == CircleObjectType.CIRCLERECIPE) {
          lastItemDate = circleObjects[index + 1].lastUpdate!;
          lastItemDateString = circleObjects[index + 1].lastUpdatedDate;
        }

        if (item.creator != null && circleObjects[index + 1].creator != null) {
          ///should we show the time (and username)
          if (circleObjects[index + 1].creator!.id == item.creator!.id) {
            if (itemDate!.difference(lastItemDate).inSeconds <
                InsideConstants.SUPRESSTIMEDURATION) {
              showTime = false;
            }
          }

          ///don't show time for items not saved to server
          if (item.id == null) {
            showTime = false;
          }

          ///should we show the avatar
          if (item.creator!.id == circleObjects[index + 1].creator!.id) {
            showAvatar = false;
          }
        } else {
          ///system messages
          if (circleObjects[index + 1].creator == null &&
              item.creator == null) {
            showAvatar = false;
          }
        }
        if (itemDateString == lastItemDateString) {
          showDate = false;
        }
      }
    } else {
      ///list is not in reverse

      if (index > 0) {
        ///always show the avatar for the first row

        if (item.creator!.id == circleObjects[index - 1].creator!.id) {
          showAvatar = false;
        }
      }
    }

    /*  ///alternate colors
    if (item.creator != null &&
        index > 0 &&
        circleObjects[index - 1].creator != null) {
      if (item.creator!.id != userFurnace.userid &&
          circleObjects[index - 1].creator!.id != userFurnace.userid) {
        for (int i = index - 1; i >= 0; i--) {
          if (circleObjects[i].creator != null) {
            if (circleObjects[i].creator!.id == item.creator!.id) {
              break;
            } else {
              //_increment++;

              // debugPrint('increment is : $_increment');
              break;
            }
          }
          // debugPrint('increment is : $_increment');
        }
      }
    }

   */

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
      messageColor = globalState.theme.userObjectText;
    }

    Color replyMessageColor =
        Member.getReplyMemberColor(item, userCircleCache.user!, userFurnace);

    ///Call the appropriate widget based on the object type

    if (item.oneTimeView) {
      return Column(
          key: item.globalKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            userFurnace.userid == item.creator!.id
                ? Container()
                : GestureDetector(
                    onTap: () {
                      tapHandler(item);
                    },
                    //onTapDown: storePosition,
                    child: CircleOneTimeViewMemberWidget(
                        item,
                        userFurnace,
                        showAvatar,
                        showDate,
                        showTime,
                        messageColor,
                        copyObject,
                        circle,
                        reactionAdded,
                        unpinObject,
                        refresh,
                        _maxWidth)),
            displayReactionsRow
                ? reactions(item, messageColor)
                : Container(),
            separator,
          ]);
    } else if (item.type == CircleObjectType.CIRCLECREDENTIAL) {
      return Column(
          key: item.globalKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            userFurnace.userid == item.creator!.id
                ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true,
                      edit: editObject,
                      copy: copyObject,
                      share: item.subType == SubType.LOGIN_INFO
                          ? shareObject
                          : null);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child:  CircleMessageSubtypeUserWidget(
                  refresh: refresh,
                  userFurnace: userFurnace,
                  circleObject: item,
                  showAvatar: showAvatar,
                  showDate: showDate,
                  showTime: showTime,
                  unpinObject: unpinObject,
                  maxWidth: _maxWidth,
                ))
                : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false,
                      copy: copyObject,
                      share: item.subType == SubType.LOGIN_INFO
                          ? shareObject
                          : null);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleMessageSubtypeMemberWidget(
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
                ? reactions(item, messageColor)
                : Container(),
            separator,
          ]);

    } else if (item.type == CircleObjectType.CIRCLEMESSAGE) {
      return Column(
          key: item.globalKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            userFurnace.userid == item.creator!.id
                ? GestureDetector(
                    onLongPress: () {
                      longPressHandler(item, showDate, true,
                          edit: editObject,
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
                        ? CircleMessageUserWidget(
                            userCircleCache: userCircleCache,
                            replyObject: replyObject,
                            replyObjectTapHandler: _replyObjectTapHandler,
                            refresh: refresh,
                            unpinObject: unpinObject,
                            userFurnace: userFurnace,
                            replyMessageColor: replyMessageColor,
                            circleObject: item,
                            showAvatar: showAvatar,
                            showDate: showDate,
                            showTime: showTime,
                            maxWidth: _maxWidth,
                          )
                        : CircleMessageSubtypeUserWidget(
                            refresh: refresh,
                            userFurnace: userFurnace,
                            circleObject: item,
                            showAvatar: showAvatar,
                            showDate: showDate,
                            showTime: showTime,
                            unpinObject: unpinObject,
                            maxWidth: _maxWidth,
                          ))
                : GestureDetector(
                    onLongPress: () {
                      longPressHandler(item, showDate, false,
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
                        ? CircleMessageMemberWidget(
                            item,
                            replyObject,
                            _replyObjectTapHandler,
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
                        : CircleMessageSubtypeMemberWidget(
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
                ? reactions(item, messageColor)
                : Container(),
            separator,
          ]);
    } else if (item.type == CircleObjectType.CIRCLEALBUM) {
      // if (Platform.isLinux ||
      //   Platform.isMacOS ||
      //   Platform.isWindows) {
      //   return Column(children: [
      //     UnknownObject(
      //         item,
      //         "Unsupported message type. This probably means you need to upgrade to see this message",
      //         true,
      //         false,
      //         false),
      //     separator,
      //   ]);
      // } else {
        populateAlbum(item, userFurnace, userCircleCache, circleAlbumBloc,
            circleObjectBloc);

        return Column(key: item.globalKey, children: [
          userFurnace.userid == item.creator!.id
              ? GestureDetector(
              onLongPress: () {
                longPressHandler(item, showDate, true,
                    share: shareObject, edit: editObject);
              },
              onTap: () {
                tapHandler(item);
              },
              //onTapDown: storePosition,
              child: CircleAlbumUserWidget(
                  userCircleCache,
                  userFurnace,
                  item,
                  replyObject,
                  _replyObjectTapHandler,
                  replyMessageColor,
                  showAvatar,
                  showDate,
                  showTime,
                  circle,
                  reactionAdded,
                  refresh,
                  unpinObject,
                  _maxWidth))
              : GestureDetector(
              onLongPress: () {
                longPressHandler(item, showDate, false,
                    share: shareObject);
              },
              onTap: () {
                tapHandler(item);
              },
              //onTapDown: storePosition,
              child: CircleAlbumMemberWidget(
                  userCircleCache,
                  userFurnace,
                  item,
                  replyObject,
                  _replyObjectTapHandler,
                  replyMessageColor,
                  showAvatar,
                  showDate,
                  showTime,
                  messageColor,
                  circle,
                  reactionAdded,
                  refresh,
                  unpinObject,
                  _maxWidth)),
          displayReactionsRow
              ? reactions(item, messageColor)
              : Container(),
          separator,
        ]);
      //}
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
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true,
                      share: shareObject,
                      edit: editObject,
                      openExternalBrowser: openExternalBrowser,
                      copy: copyObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleLinkUserWidget(
                    item,
                    replyObject,
                    _replyObjectTapHandler,
                    userCircleCache,
                    showAvatar,
                    showDate,
                    showTime,
                    userFurnace,
                    circle,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false,
                      share: shareObject,
                      openExternalBrowser: openExternalBrowser,
                      copy: copyObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                child: CircleLinkMemberWidget(
                    item,
                    replyObject,
                    userCircleCache,
                    _replyObjectTapHandler,
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEGIF) {
      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true,
                      share: shareObject, copy: copyObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleGifUserWidget(
                    item,
                    replyObject,
                    _replyObjectTapHandler,
                    userCircleCache,
                    userFurnace,
                    showAvatar,
                    showDate,
                    showTime,
                    circle,
                    replyMessageColor,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true,
                      share: shareObject, copy: copyObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                child: CircleGifMemberWidget(
                    item,
                    replyObject,
                    _replyObjectTapHandler,
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEVOTE) {
      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleVoteUserWidget(
                  circleObject: item,
                  userFurnace: userFurnace,
                  interactive: interactive,
                  showAvatar: showAvatar,
                  showDate: showDate,
                  showTime: showTime,
                  submitVote: submitVote,
                  user: userCircleCache.user,
                  unpinObject: unpinObject,
                  refresh: refresh,
                  maxWidth: _maxWidth,
                ))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleVoteMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLELIST) {
      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleListUserWidget(
                    item,
                    userFurnace,
                    interactive,
                    showAvatar,
                    showDate,
                    showTime,
                    updateList,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleListMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEEVENT) {
      //populateRecipeImageFile(item);

      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleEventUserWidget(
                  circleObject: item,
                  userFurnace: userFurnace,
                  showAvatar: showAvatar,
                  showDate: showDate,
                  showTime: showTime,
                  circle: circle,
                  unpinObject: unpinObject,
                  refresh: refresh,
                  maxWidth: _maxWidth,
                ))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleEventMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLERECIPE) {
      populateRecipeImageFile(item, userFurnace, userCircleCache,
          globalEventBloc, circleRecipeBloc);

      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleRecipeUserWidget(
                    item,
                    userFurnace,
                    showAvatar,
                    showDate,
                    showTime,
                    userCircleCache,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                // onTapDown: storePosition,
                child: CircleRecipeMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLELIST) {
      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                child: CircleListUserWidget(
                    item,
                    userFurnace,
                    interactive,
                    showAvatar,
                    showDate,
                    showTime,
                    updateList,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, false, share: shareObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                child: CircleListMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEFILE) {
      populateFile(item, userFurnace, userCircleCache, circleFileBloc);

      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
            onLongPress: () {
              longPressHandler(item, showDate, true,
                  share: shareObject, export: export, //edit: editObject,
                download: item.draft == false &&
                    (item.fullTransferState  == BlobState.UNKNOWN ||item.fullTransferState  == BlobState.NOT_DOWNLOADED)
                    ? downloadVideo
                    : null,
                cancel:item.draft == false &&
                    item.fullTransferState  == BlobState.DOWNLOADING
                    ? cancelTransfer
                    : null,
                deleteCache: item.draft == false && item.fullTransferState  == BlobState.READY
                    ? removeCache
                    : null,);
            },
            onTap: () {
              tapHandler(item);
            },

            child: CircleFileUserWidget(
                userCircleCache,
                interactive,
                userFurnace,
                item,
                showAvatar,
                showDate,
                showTime,
                downloadFile,
                retry,
                circle,
                unpinObject,
                refresh,
                _maxWidth))
            : GestureDetector(
            onLongPress: () {
              longPressHandler(
                item,
                showDate,
                false,
                share: shareObject, export: export,
                download: item.draft == false &&
                    (item.fullTransferState  == BlobState.UNKNOWN ||item.fullTransferState  == BlobState.NOT_DOWNLOADED)
                    ? downloadVideo
                    : null,
                cancel:item.draft == false &&
                    item.fullTransferState  == BlobState.DOWNLOADING
                    ? cancelTransfer
                    : null,
                deleteCache: item.draft == false && item.fullTransferState  == BlobState.READY
                    ? removeCache
                    : null,
              );
            },
            onTap: () {
              tapHandler(item);
            },
            // onTapDown: storePosition,
            child: CircleFileMemberWidget(
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
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);

    } else if (item.type == CircleObjectType.CIRCLEIMAGE) {
      populateImageFile(item, userFurnace, userCircleCache, circleImageBloc,
          circleObjectBloc);

      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(item, showDate, true,
                      share: shareObject, export: export, edit: editObject);
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: CircleImageUserWidget(
                    userCircleCache,
                    userFurnace,
                    _replyObjectTapHandler,
                    item,
                    replyObject,
                    showAvatar,
                    showDate,
                    showTime,
                    replyMessageColor,
                    circle,
                    retry,
                    unpinObject,
                    refresh,
                    _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(
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
                child: CircleImageMemberWidget(
                    userCircleCache,
                    _replyObjectTapHandler,
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
                    _maxWidth)),
        displayReactionsRow
            ? reactions(item, messageColor)
            : Container(),
        separator,
      ]);
    } else if (item.type == CircleObjectType.CIRCLEVIDEO) {
      if (item.video == null && (item.draft == false)) return Container();

      ChewieController? controller;

      if (item.draft ==false) {
        if (item.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          controller = videoControllerBloc.fetchController(item);
          populateVideoFile(item, userFurnace, userCircleCache, circleVideoBloc,
              videoControllerBloc, videoControllerDesktopBloc);
        }
      }

      return Column(key: item.globalKey, children: [
        userFurnace.userid == item.creator!.id
            ? GestureDetector(
                onLongPress: () {
                  longPressHandler(
                    item,
                    showDate,
                    true,
                    share: shareObject,
                    copy: copyObject,
                    edit: editObject,
                    download: item.draft == false &&
                        item.video!.streamable! && !item.video!.streamableCached
                            ? downloadVideo
                            : null,
                    cancel:item.draft == false &&
                        item.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
                            ? cancelTransfer
                            : null,
                    deleteCache: item.draft == false && (!item.video!.streamable! ||
                            item.video!.streamableCached)
                        ? item.video!.videoState == VideoStateIC.VIDEO_READY ||
                                item.video!.videoState ==
                                    VideoStateIC.NEEDS_CHEWIE
                            ? removeCache
                            : null
                        : null,
                  );
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: item.draft ? CircleVideoUserWidget(
                    userCircleCache,
                    _replyObjectTapHandler,
                    interactive,
                    userFurnace,
                    item,
                    replyObject,
                    showAvatar,
                    showDate,
                    showTime,
                    downloadVideo,
                    playVideo,
                    retry,
                    circle,
                    predispose,
                    unpinObject,
                    refresh,
                    _maxWidth)
                    : item.video!.streamable! &&
                        !item.video!.streamableCached &&
                        item.id != null
                    ? CircleVideoStreamingUserWidget(
                        userCircleCache,
                        interactive,
                        _replyObjectTapHandler,
                        userFurnace,
                        item,
                        replyObject,
                        showAvatar,
                        showDate,
                        showTime,
                        downloadVideo,
                        streamVideo,
                        item.video!.videoState == VideoStateIC.VIDEO_READY || item.video!.videoState == VideoStateIC.NEEDS_CHEWIE || item.video!.videoState == VideoStateIC.VIDEO_UPLOADED
                            ? removeCache
                            : null,
                        circle,
                        predispose,
                        unpinObject,
                        refresh,
                        _maxWidth)
                    : CircleVideoUserWidget(
                        userCircleCache,
                        _replyObjectTapHandler,
                        interactive,
                        userFurnace,
                        item,
                        replyObject,
                        showAvatar,
                        showDate,
                        showTime,
                        downloadVideo,
                        playVideo,
                        retry,
                        circle,
                        predispose,
                        unpinObject,
                        refresh,
                        _maxWidth))
            : GestureDetector(
                onLongPress: () {
                  longPressHandler(
                    item,
                    showDate,
                    false,
                    share: shareObject,
                    download:
                        item.video!.streamable! && !item.video!.streamableCached
                            ? downloadVideo
                            : null,
                    cancel:
                        item.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
                            ? cancelTransfer
                            : null,
                    deleteCache: (!item.video!.streamable! ||
                            item.video!.streamableCached)
                        ? item.video!.videoState == VideoStateIC.VIDEO_READY ||
                                item.video!.videoState ==
                                    VideoStateIC.NEEDS_CHEWIE
                            ? removeCache
                            : null
                        : null,
                  );
                },
                onTap: () {
                  tapHandler(item);
                },
                //onTapDown: storePosition,
                child: item.video!.streamable! && !item.video!.streamableCached
                    ? CircleVideoStreamingMemberWidget(
                        userCircleCache,
                        interactive,
                        _replyObjectTapHandler,
                        userFurnace,
                        item,
                        replyObject,
                        showAvatar,
                        showDate,
                        showTime,
                        downloadVideo,
                        streamVideo,
                        circle,
                        controller,
                        videoControllerBloc,
                        predispose,
                        messageColor,
                        replyMessageColor,
                        unpinObject,
                        refresh,
                        _maxWidth)
                    : CircleVideoMemberWidget(
                        userCircleCache,
                        _replyObjectTapHandler,
                        userFurnace,
                        item,
                          replyObject,
                        showAvatar,
                        showDate,
                        showTime,
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
            ? reactions(item, messageColor)
            : Container(),
      ]);
    } else if (item.type == CircleObjectType.CIRCLEAGORACALL) {
      return Column(
        key: item.globalKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          // GestureDetector(
          //   onLongPress: () {
          //     longPressHandler(item, showDate, userFurnace.userid == item.creator!.id);
          //   },
          //   onTap: () {
          //     tapHandler(item);
          //   },
          //   child: CircleAgoraCallWidget(
          //     agoraCall: item.agoraCall!,
          //     circleID: circle.id ?? '',
          //     userFurnace: userFurnace,
          //   ),
          // ),
          displayReactionsRow
              ? reactions(item, messageColor)
              : Container(),
          separator,
        ],
      );
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

  _replyObjectTapHandler(CircleObject circleObject) {
    if (circleObject.replyObjectID != null) {
      CircleObject obj = circleObjects.firstWhere((element) => element.id == circleObject.replyObjectID);
      scrollToIndex!(circleObjects.indexOf(obj));
    }
  }
}
