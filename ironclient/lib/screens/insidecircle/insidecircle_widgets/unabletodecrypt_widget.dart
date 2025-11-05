import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class UnableToDecrypt extends StatelessWidget {
  final CircleObject circleObject;
  final bool showDate;
  final bool showTime;
  const UnableToDecrypt(
      {required this.circleObject,
      required this.showTime,
      required this.showDate});

  Widget build(BuildContext context) {
    return Container(
        //
        // width: 150.0,
        // height: 150.0,
        child: Column(children: <Widget>[
      Container(
          padding: showDate
              ? const EdgeInsets.only(top: 10, bottom: 20.0)
              : const EdgeInsets.all(0),
          child: Center(
              child: showDate
                  ? Text(circleObject.date!, textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.date))
                  : null)),
      Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 24.0,
              backgroundImage: const AssetImage('assets/images/ic_launcher.png'),
              backgroundColor: globalState.theme.background,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                      Text(
                        'Notification', textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                        style: TextStyle(
                            color: globalState.theme.objectTitle,
                            fontWeight: FontWeight.w600,
                            fontSize: globalState.userSetting.fontSize),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 0.0),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: 5,),
                        child: showTime || circleObject.showOptionIcons
                            ? Text(
                                circleObject.showOptionIcons
                                    ? ('${circleObject.date!}  ${circleObject.time!}')
                                    : circleObject.time!,
                                style: TextStyle(
                                  color: globalState.theme.time,
                                  fontWeight: FontWeight.w600,
                                  fontSize: globalState.userSetting.fontSize,
                                ),
                              )
                            : Container(),
                      ),
                    ]),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: InsideConstants.MESSAGEBOXSIZE),
                      //maxWidth: 250,
                      //height: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        //color: globalState.theme.dropdownBackground,
                        decoration: BoxDecoration(
                            color: globalState.theme.userObjectBackground,
                            borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10.0),
                                bottomRight: Radius.circular(10.0),
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0))),
                        child: Text(
                          circleObject.body!, textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.systemMessageText,
                              fontSize: globalState.userSetting.fontSize),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
    ]));
  }
}
