import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class WallMessageWidget extends StatelessWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final UserCircleCache userCircleCache;
  final Function? replyObjectTapHandler;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color messageColor;
  final Color? replyMessageColor;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const WallMessageWidget(
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.userCircleCache,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.replyMessageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
        padding:
            EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomLeft, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      circleObject, showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                    circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(showDate: showDate, circleObject: circleObject),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarWidget(
                          refresh: refresh,
                          userFurnace: userFurnace,
                          user: circleObject.creator,
                          showAvatar: showAvatar,
                          isUser: false),
                      Expanded(
                          child: Container(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    CircleObjectMember(
                                      creator: circleObject.creator!,
                                      circleObject: circleObject,
                                      userFurnace: userFurnace,
                                      messageColor: messageColor,
                                      interactive: true,
                                      showTime: showTime,
                                      isWall: true,
                                      refresh: refresh,
                                      maxWidth: maxWidth,
                                    ),
                                  ])))
                    ]),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Stack(
                                  alignment: Alignment.topRight,
                                  children: <Widget>[
                                    Align(
                                        alignment: Alignment.topLeft,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: maxWidth),
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                                InsideConstants.MESSAGEPADDING),
                                            //color: globalState.theme.dropdownBackground,
                                            decoration: BoxDecoration(
                                                color: globalState.theme
                                                    .memberObjectBackground,
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
                                            child: CircleObjectBody(
                                              circleObject: circleObject,
                                              replyObject: replyObject,
                                              replyObjectTapHandler:
                                                  replyObjectTapHandler,
                                              userCircleCache: userCircleCache,
                                              messageColor: messageColor,
                                              replyMessageColor:
                                                  replyMessageColor,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              maxWidth: maxWidth,
                                            ),
                                          ),
                                        )),
                                    circleObject.id == null
                                        ? Align(
                                            alignment: Alignment.topLeft,
                                            child: CircleAvatar(
                                              radius: 7.0,
                                              backgroundColor: globalState
                                                  .theme.sentIndicator,
                                            ))
                                        : Container(),
                                  ]),
                            ],
                          ),
                        ),
                      ),
                    ]),
              ])),
          CircleObjectTimer(circleObject: circleObject, isMember: true),
        ]));
  }
}
