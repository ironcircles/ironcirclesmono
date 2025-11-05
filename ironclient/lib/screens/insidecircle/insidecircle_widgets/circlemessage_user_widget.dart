import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';

class CircleMessageUserWidget extends StatelessWidget {
  final UserCircleCache userCircleCache;
  final CircleObject? replyObject;
  final CircleObject circleObject;
  final Function? replyObjectTapHandler;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool? showDate;
  final bool? showTime;
  final Color? replyMessageColor;
  final bool? showReactionRow;
  final double iconFontSize = 32;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleMessageUserWidget(
      {required this.circleObject,
      required this.userCircleCache,
      this.replyObjectTapHandler,
      required this.userFurnace,
      required this.showAvatar,
      this.replyObject,
      this.showReactionRow,
      this.showDate,
      this.showTime,
      this.replyMessageColor,
      required this.unpinObject,
      required this.refresh,
      required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    int addedPadding = circleObject.scheduledFor != null &&
            circleObject.scheduledFor!.isAfter(DateTime.now())
        ? 20
        : 0;
    //double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding:
          EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
      child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
        Padding(
            padding: EdgeInsets.only(
                top: SharedFunctions.calculateTopPadding(
                    circleObject, showDate!),
                bottom: SharedFunctions.calculateBottomPadding(circleObject) +
                    addedPadding),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DateWidget(showDate: showDate!, circleObject: circleObject),
                  PinnedObject(
                    circleObject: circleObject,
                    unpinObject: unpinObject,
                    isUser: true,
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(left: 5.0),
                                      ),
                                      showTime! || circleObject.showOptionIcons
                                          ? Text(
                                              circleObject.showOptionIcons
                                                  ? ('${circleObject.date!}  ${circleObject.time!}')
                                                  : circleObject.time!,
                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                              style: TextStyle(
                                                color: globalState.theme.time,
                                                fontWeight: FontWeight.w600,
                                                fontSize: globalState
                                                    .userSetting.fontSize,
                                              ),
                                            )
                                          : Container(),
                                    ]),
                                Stack(alignment: Alignment.topRight, children: <
                                    Widget>[
                                  Align(
                                      alignment: Alignment.topRight,
                                      child: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: maxWidth /*circleObject.replyObjectID == null ? maxWidth : maxWidth / 2*/),
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
                                              replyObject == null
                                                  ? CircleObjectBody(
                                                      circleObject:
                                                          circleObject,
                                                      userCircleCache:
                                                          userCircleCache,
                                                      messageColor: globalState
                                                          .theme.userObjectText,
                                                      replyMessageColor:
                                                          replyMessageColor,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      maxWidth: maxWidth,
                                                    )
                                                  : CircleObjectBody(
                                                      replyObject: replyObject,
                                                      replyObjectTapHandler:
                                                          replyObjectTapHandler,
                                                      userCircleCache:
                                                          userCircleCache,
                                                      circleObject:
                                                          circleObject,
                                                      messageColor: globalState
                                                          .theme.userObjectText,
                                                      replyMessageColor:
                                                          replyMessageColor,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      maxWidth: maxWidth,
                                                    )
                                            ])),
                                      )),
                                  circleObject.id == null
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: CircleAvatar(
                                            radius: 7.0,
                                            backgroundColor:
                                                globalState.theme.sentIndicator,
                                          ))
                                      : Container(),
                                ]),
                                CircleObjectDraft(circleObject: circleObject),
                              ],
                            ),
                          ),
                        ),
                        AvatarWidget(
                            refresh: refresh,
                            userFurnace: userFurnace,
                            user: circleObject.creator,
                            showAvatar: showAvatar,
                            isUser: true),
                      ]),
                ])),
        CircleObjectTimer(circleObject: circleObject, isMember: false),
      ]),
    );
  }
}
