import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleOneTimeViewMemberWidget extends StatelessWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color? messageColor;
  final Function copy;
  final Circle? circle;
  final Function reactionChanged;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleOneTimeViewMemberWidget(
      this.circleObject,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.copy,
      this.circle,
      this.reactionChanged,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

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
                DateWidget(
                    showDate: showDate,
                    circleObject: circleObject),
                PinnedObject(
              circleObject: circleObject,
              unpinObject: unpinObject,
              isUser: false,
                ),
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          CircleObjectMember(
                              creator: circleObject.creator!,
                              circleObject: circleObject,
                              userFurnace: userFurnace,
                              messageColor: messageColor!,
                              interactive: true,
                              showTime: showTime,
                              refresh: refresh,
                              maxWidth: maxWidth),
                          ConstrainedBox(
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
                                child: Row(children: [
                                  SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: Image.asset(
                                          'assets/images/otv.png')),
                                  Expanded(
                                      child: Text(
                                    'One Time View Message',
                                    textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                    style: TextStyle(
                                        color: messageColor,
                                        fontSize: globalState
                                            .userSetting.fontSize),
                                  ))
                                ])),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ])),
        ]));
  }
}
