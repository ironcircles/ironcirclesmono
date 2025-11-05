import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class CircleObjectTimer extends StatelessWidget {
  final CircleObject circleObject;
  final bool isMember;

  const CircleObjectTimer({
    required this.circleObject,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context) {
    return circleObject.timer == null
        ? circleObject.scheduledFor != null && circleObject.scheduledFor!.isAfter(DateTime.now())
          ? isMember
            ? Container()
            : Positioned(
        bottom: circleObject.showOptionIcons ? 30 : 0,
        right: 0,
        child: Padding(
            padding: const EdgeInsets.only(
                left: 0, right: 10, top:50),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 200,
                      child: Text(
                        circleObject.scheduledFor.toString().substring(0, 16),
                        textAlign: TextAlign.end,
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            fontSize: 12,
                            color: globalState.theme.buttonIcon),
                      )),
                  Icon(Icons.timer,
                      size: 15, color: globalState.theme.buttonIcon),
                ])))
          : Container()
        : isMember
            ? Positioned(
                bottom: circleObject.showOptionIcons ? 30 : 0,
                left: 0,
                child: Padding(
                    padding: EdgeInsets.only(
                        left: isMember ? 10 : 0, right: isMember ? 0 : 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 26,
                              child: Text(
                                UserDisappearingTimerStrings.getUserTimerString(
                                    circleObject.timer!),
                                textAlign: TextAlign.end,
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: globalState.theme.buttonIcon),
                              )),
                          Icon(Icons.timer,
                              size: 15, color: globalState.theme.buttonIcon),
                        ])))
            : Positioned(
                bottom: circleObject.showOptionIcons ? 30 : 0,
                right: 0,
                child: Padding(
                    padding: EdgeInsets.only(
                        left: isMember ? 10 : 0, right: isMember ? 0 : 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 26,
                              child: Text(
                                UserDisappearingTimerStrings.getUserTimerString(
                                    circleObject.timer!),
                                textAlign: TextAlign.end,
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: globalState.theme.buttonIcon),
                              )),
                          Icon(Icons.timer,
                              size: 15, color: globalState.theme.buttonIcon),
                        ])));
  }
}
