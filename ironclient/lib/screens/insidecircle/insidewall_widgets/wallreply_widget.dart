import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/replyobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/replyobject_member.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/replyreactions_row.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class WallReplyWidget extends StatelessWidget {
  final ReplyObject reply;
  final List<ReplyObject> replyResponses;
  final UserFurnace userFurnace;
  final UserCircleCache userCircleCache;
  final bool isUser;
  final Function tapHandler;
  final Function longPressHandler;
  final Color messageColor;
  final Color replyMessageColor;
  final Function refresh;
  final double maxWidth;
  final Function longReaction;
  final Function shortReaction;
  final Function reactionAdded;
  final Function showReactions;

  const WallReplyWidget({
    Key? key,
    required this.reply,
    required this.replyResponses,
    required this.userFurnace,
    required this.userCircleCache,
    required this.isUser,
    required this.tapHandler,
    required this.longPressHandler,
    required this.messageColor,
    required this.replyMessageColor,
    required this.refresh,
    required this.maxWidth,
    required this.longReaction,
    required this.shortReaction,
    required this.reactionAdded,
    required this.showReactions,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      key: reply.globalKey,
      padding:
      const EdgeInsets.only(top: UIPadding.BETWEEN_MESSAGES),
      child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
        Padding(
            padding: EdgeInsets.only( top: 0,
              // top: SharedFunctions.calculateTopPadding(
              //     circleObject, showDate!),
              // bottom: SharedFunctions.calculateBottomPadding(circleObject) +
              //     addedPadding
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  //DateWidget(showDate: showDate!, circleObject: circleObject),
                  ReplyObjectMember(
                    creator: reply.creator,
                    replyObject: reply,
                    userFurnace: userFurnace,
                    interactive: true,
                    showTime: true,
                    refresh: refresh,
                    maxWidth: maxWidth,
                    isWall: false,
                  ),
                  // PinnedObject(
                  //   circleObject: circleObject,
                  //   unpinObject: unpinObject,
                  //   isUser: true,
                  // ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AvatarWidget(
                            refresh: refresh,
                            userFurnace: userFurnace,
                            user: reply.creator,
                            showAvatar: true,
                            isUser: isUser),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // const Row(
                                //     crossAxisAlignment:
                                //     CrossAxisAlignment.start,
                                //     mainAxisAlignment: MainAxisAlignment.start,
                                //     children: <Widget>[
                                //       Padding(
                                //         padding: EdgeInsets.only(left: 5.0),
                                //       ),
                                //       // showTime! || circleObject.showOptionIcons
                                //       //     ? Text(
                                //       //   circleObject.showOptionIcons
                                //       //       ? ('${circleObject.date!}  ${circleObject.time!}')
                                //       //       : circleObject.time!,
                                //       //   textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                //       //   style: TextStyle(
                                //       //     color: globalState.theme.time,
                                //       //     fontWeight: FontWeight.w600,
                                //       //     fontSize: globalState
                                //       //         .userSetting.fontSize,
                                //       //   ),
                                //       // )
                                //       //     : Container(),
                                //     ]),
                                Stack(alignment: Alignment.topRight,//Alignment.topRight,
                                    children: <
                                        Widget>[
                                      Align(
                                          alignment: Alignment.topLeft,
                                          //alignment: Alignment.topRight,
                                          child: ConstrainedBox(
                                            constraints:
                                            BoxConstraints(maxWidth: maxWidth),
                                            //maxWidth: 250,
                                            //height: 20,
                                            child: Container(
                                                padding: const EdgeInsets.all(
                                                    InsideConstants.MESSAGEPADDING),
                                                //color: globalState.theme.dropdownBackground,
                                                decoration: BoxDecoration(
                                                    color: globalState
                                                        .theme.userObjectBackground,
                                                    borderRadius: const BorderRadius
                                                        .only(
                                                        bottomLeft:
                                                        Radius.circular(10.0),
                                                        bottomRight:
                                                        Radius.circular(10.0),
                                                        topLeft:
                                                        Radius.circular(10.0),
                                                        topRight:
                                                        Radius.circular(10.0))),
                                                child: Column(children: [
                                                  ReplyObjectBody(
                                                    replyObject: reply,
                                                    tapHandler: tapHandler,
                                                    userCircleCache: userCircleCache,
                                                    messageColor:  messageColor,
                                                    replyMessageColor: replyMessageColor,
                                                    maxWidth: maxWidth,
                                                    longPressHandler: longPressHandler,
                                                    isUser: isUser,
                                                  )
                                                ])),
                                          )),
                                      reply.id == null
                                          ? Align(
                                          alignment: Alignment.topLeft,
                                          child: CircleAvatar(
                                            radius: 7.0,
                                            backgroundColor:
                                            globalState.theme.sentIndicator,
                                          ))
                                          : Container(),
                                    ]),
                                //CircleObjectDraft(circleObject: circleObject),
                              ],
                            ),
                          ),
                        ),
                      ]),
                  //displayReactionsRow ?
                  ReplyReactionsRow(
                    isUser: false,//isuser
                    replyObject: reply,
                    longPress: longReaction,
                    shortPress: shortReaction,
                    showReactions: showReactions,
                    reactionChanged: reactionAdded,
                    userID: userFurnace.userid!,
                  )
                      //: Container(),
                ])),
      ]),
    );
  }
}