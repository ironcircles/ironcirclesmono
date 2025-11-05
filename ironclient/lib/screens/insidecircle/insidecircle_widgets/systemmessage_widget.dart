import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class SystemMessageWidget extends StatelessWidget {
  final CircleObject circleObject;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final double maxWidth;

  const SystemMessageWidget(this.circleObject, this.showAvatar, this.showTime,
      this.showDate, this.maxWidth);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding:
            EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Column(children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                showAvatar
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            const AssetImage('assets/images/ic_launcher.png'),
                        backgroundColor: globalState.theme.background,
                      )
                    : SizedBox(
                        height: 24,
                        width: 35,
                        child: Container(
                          color: globalState.theme.background,
                        ),
                      ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Notification',
                                textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                style: TextStyle(
                                    color: globalState
                                        .theme.systemMessageNotification,
                                    fontWeight: FontWeight.w600,
                                    fontSize: globalState.userSetting.fontSize),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 0.0),
                              ),
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                  child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 5,
                                      ),
                                      child: Text(
                                        '${circleObject.date!}  ${circleObject.time!}',
                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                        style: TextStyle(
                                          color: globalState.theme.time,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              globalState.userSetting.fontSize -
                                                  1,
                                        ),
                                      ))),
                            ]),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          //maxWidth: 250,
                          //height: 20,
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            //color: globalState.theme.dropdownBackground,
                            decoration: BoxDecoration(
                                color:
                                    globalState.theme.systemMessageBackground,
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0),
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0))),
                            child: Text(
                              circleObject.body ?? '',
                              textScaler: TextScaler.linear(globalState.messageScaleFactor),
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
