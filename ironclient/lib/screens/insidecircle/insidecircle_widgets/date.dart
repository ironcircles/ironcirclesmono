import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DateWidget extends StatelessWidget {
  final bool showDate;
  final CircleObject circleObject;
  final bool editableObject;

  const DateWidget(
      {Key? key,
      required this.showDate,
      required this.circleObject,
      this.editableObject = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return showDate
        ? Container(
            padding: const EdgeInsets.only(
                top: 0, //InsideConstants.DATEPADDINGTOP,
                bottom: 0), //InsideConstants.DATEPADDINGBOTTOM),
            child: Center(
                child: Text(editableObject ? circleObject.lastUpdatedDate! : circleObject.date!,
                    textScaler:
                        TextScaler.linear(globalState.messageHeaderScaleFactor),
                    style: TextStyle(
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.date))))
        : Container();
  }
}
