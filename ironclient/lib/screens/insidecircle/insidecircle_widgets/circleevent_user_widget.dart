import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class CircleEventUserWidget extends StatelessWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool? showDate;
  final bool? showTime;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleEventUserWidget(
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
                    circleObject: circleObject, editableObject: true,),
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
                              Stack(alignment: Alignment.topRight, children: <
                                  Widget>[
                                Align(
                                    alignment: Alignment.topRight,
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
                                              borderRadius:
                                                  const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(10.0),
                                                      bottomRight:
                                                          Radius.circular(10.0),
                                                      topLeft:
                                                          Radius.circular(10.0),
                                                      topRight:
                                                          Radius.circular(
                                                              10.0))),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        AppLocalizations.of(context)!.event,
                                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                          color: globalState
                                                              .theme.listTitle,
                                                          fontSize: globalState
                                                              .titleSize,
                                                        ),
                                                      ),
                                                    ]),
                                                circleObject.event!
                                                            .lastEdited !=
                                                        null
                                                    ? Row(crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                            ICText('${AppLocalizations.of(context)!.lastEditedBy} ',
                                                                textScaleFactor:
                                                                    globalState
                                                                        .messageHeaderScaleFactor,
                                                                color: globalState
                                                                    .theme
                                                                    .listTitle),
                                                            Expanded(child:ICText(
                                                                circleObject
                                                                    .event!
                                                                    .lastEdited!
                                                                    .getUsernameAndAlias(
                                                                        globalState),
                                                                textScaleFactor:
                                                                    globalState
                                                                        .messageHeaderScaleFactor,
                                                                color: circleObject
                                                                            .event!
                                                                            .lastEdited!
                                                                            .id ==
                                                                        userFurnace
                                                                            .userid
                                                                    ? globalState
                                                                        .theme
                                                                        .userObjectText
                                                                    : Member.getMemberColor(
                                                                        userFurnace,
                                                                        circleObject
                                                                            .event!
                                                                            .lastEdited!))),
                                                          ])
                                                    : Container(),
                                                const Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 5)),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      const SizedBox(
                                                        width: 5,
                                                        height: 25,
                                                      ),
                                                      SizedBox(
                                                          width: 70,
                                                          // height: 0,
                                                          child: Text('${AppLocalizations.of(context)!.title}:',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                color: globalState
                                                                    .theme
                                                                    .listTitle,
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                              ))),
                                                      Expanded(
                                                          child: Text(
                                                              circleObject
                                                                  .event!.title,
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                color: globalState
                                                                    .theme
                                                                    .buttonIcon,
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                                //fontSize: 16,
                                                              ))),
                                                    ]),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(
                                                        width: 5,
                                                        height: 25,
                                                      ),
                                                      SizedBox(
                                                          width: 70,
                                                          // height: 0,
                                                          child: Text(
                                                            '${AppLocalizations.of(context)!.start}: ',
                                                            textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                            style: TextStyle(
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                                color: globalState
                                                                    .theme
                                                                    .labelText),
                                                          )),
                                                      Expanded(
                                                          child: Text(
                                                              '${circleObject.event!.startDateString} @ ${circleObject.event!.startTimeString}',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                color: globalState
                                                                    .theme
                                                                    .buttonIcon,
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                              ))),
                                                    ]),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(
                                                        width: 5,
                                                        height: 25,
                                                      ),
                                                      SizedBox(
                                                          width: 70,
                                                          // height: 0,
                                                          child: Text(
                                                            '${AppLocalizations.of(context)!.end}: ',
                                                            textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                            style: TextStyle(
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                                color: globalState
                                                                    .theme
                                                                    .labelText),
                                                          )),
                                                      Expanded(
                                                          child: Text(
                                                              '${circleObject.event!.endDateString} @ ${circleObject.event!.endTimeString}',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                color: globalState
                                                                    .theme
                                                                    .buttonIcon,
                                                                fontSize: globalState
                                                                    .userSetting
                                                                    .fontSize,
                                                              ))),
                                                    ]),
                                              ])),
                                    )),
                                (circleObject.id == null ||
                                        circleObject.updating == true)
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: CircleAvatar(
                                          radius: 7.0,
                                          backgroundColor:
                                              globalState.theme.sentIndicator,
                                        ))
                                    : Container(),
                              ]),
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
