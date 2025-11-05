import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class WallMessageSubTypeWidget extends StatelessWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color? messageColor;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const WallMessageSubTypeWidget(
      this.circleObject,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.circle,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  Widget build(BuildContext context) {
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarWidget(
                          refresh: refresh,
                          userFurnace: userFurnace,
                          user: circleObject.creator,
                          showAvatar: showAvatar,
                          isUser: true),
                      Expanded(
                          child: Container(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    CircleObjectMember(
                                      creator: circleObject.creator!,
                                      circleObject: circleObject,
                                      userFurnace: userFurnace,
                                      messageColor: messageColor!,
                                      interactive: true,
                                      isWall: true,
                                      showTime: true,
                                      refresh: refresh,
                                      maxWidth: maxWidth,
                                    ),
                                  ])))
                    ]),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: <
                    Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Stack(alignment: Alignment.topLeft, children: <
                              Widget>[
                            Align(
                              alignment: Alignment.topLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                //maxWidth: 250,
                                //height: 20,
                                child: Container(
                                    padding: const EdgeInsets.all(
                                        InsideConstants.MESSAGEPADDING),
                                    //color: globalState.theme.dropdownBackground,
                                    decoration: BoxDecoration(
                                        color: globalState
                                            .theme.memberObjectBackground,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(10.0),
                                            bottomRight: Radius.circular(10.0),
                                            topLeft: Radius.circular(10.0),
                                            topRight: Radius.circular(10.0))),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  'Credential',
 textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                  style: TextStyle(
                                                    color: globalState
                                                        .theme.listTitle,
                                                    fontSize:
                                                        globalState.titleSize,
                                                  ),
                                                ),
                                              ]),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                    child: Text(
                                                  circleObject.subString1 ==
                                                          null
                                                      ? ''
                                                      : circleObject
                                                          .subString1!,
 textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                  //textAlign: TextAlign.end,
                                                  style: TextStyle(
                                                      color: globalState
                                                          .theme.userObjectText,
                                                      fontSize: globalState
                                                          .userSetting
                                                          .fontSize),
                                                ))
                                              ]),
                                          Center(
                                              child: Text(
                                            'tap to see details',
 textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                            style: TextStyle(
                                                color: globalState
                                                    .theme.listExpand),
                                          )),
                                        ])),
                              ),
                            ),
                            circleObject.updating == true ||
                                    circleObject.id == null
                                ? Align(
                                    alignment: Alignment.topRight,
                                    child: CircleAvatar(
                                      radius: 7.0,
                                      backgroundColor:
                                          globalState.theme.sentIndicator,
                                    ))
                                : Container(),
                          ])
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
