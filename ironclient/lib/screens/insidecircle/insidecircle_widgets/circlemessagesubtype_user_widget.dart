import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class CircleMessageSubtypeUserWidget extends StatelessWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool? showDate;
  final bool? showTime;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleMessageSubtypeUserWidget(
      {required this.circleObject,
      required this.userFurnace,
      required this.showAvatar,
      this.showDate,
      this.showTime,
      this.circle,
      required this.unpinObject,
      required this.refresh,
      required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding:
            EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      circleObject, showDate!),
                  bottom: SharedFunctions.calculateBottomPadding(
                    circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(
                    showDate: showDate!,
                    circleObject: circleObject),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              Stack(
                                  alignment: Alignment.topRight,
                                  children: <Widget>[
                                    Align(
                                        alignment: Alignment.topRight,
                                        child: circleObject.draft
                                            ? Container()
                                            : ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: maxWidth,
                                                ),
                                                //maxWidth: 250,
                                                //height: 20,
                                                child: Container(
                                                    padding: const EdgeInsets.all(
                                                        InsideConstants
                                                            .MESSAGEPADDING),
                                                    //color: globalState.theme.dropdownBackground,
                                                    decoration: BoxDecoration(
                                                        color: globalState.theme
                                                            .userObjectBackground,
                                                        borderRadius: const BorderRadius.only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    10.0),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    10.0),
                                                            topLeft:
                                                                Radius.circular(
                                                                    10.0),
                                                            topRight:
                                                                Radius.circular(
                                                                    10.0))),
                                                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                      Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Text(
                                                              'Credential',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .listTitle,
                                                                  fontSize:
                                                                      globalState
                                                                          .titleSize),
                                                            ),
                                                          ]),
                                                      Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Expanded(
                                                              child: ICText(
                                                                  circleObject.subString1 ==
                                                                          null
                                                                      ? ''
                                                                      : circleObject
                                                                          .subString1!,
                                                                  textScaleFactor:
                                                                      globalState
                                                                          .messageScaleFactor,
                                                                  //textAlign: TextAlign.end,
                                                                  color: globalState
                                                                      .theme
                                                                      .userObjectText,
                                                                  fontSize: 14),
                                                            )
                                                          ]),
                                                      Center(
                                                          child: ICText(
                                                        'tap to see details',
                                                        textScaleFactor: globalState
                                                            .messageHeaderScaleFactor,
                                                        color: globalState
                                                            .theme.listExpand,
                                                      )),
                                                    ])),
                                              )),
                                    circleObject.id == null
                                        ? Align(
                                            alignment: Alignment.topRight,
                                            child: CircleAvatar(
                                              radius: 7.0,
                                              backgroundColor: globalState
                                                  .theme.sentIndicator,
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
        ]));
  }
}
