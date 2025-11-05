import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class SearchedObject extends StatelessWidget {
  final CircleObject circleObject;
  final Function unpinObject;
  final bool isUser;

  const SearchedObject({
    required this.circleObject,
    required this.unpinObject,
    required this.isUser,
  });

  Widget build(BuildContext context) {
    return circleObject.pinned == true
        ? Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: InkWell(
            onTap: () {
              unpinObject(circleObject);
            },
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: EdgeInsets.only(
                          left: !isUser ? 40 : 0, bottom: 15)),
                  Transform.rotate(
                      angle: 45 * math.pi / 180,
                      child: const Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                      )),
                  Padding(
                      padding: EdgeInsets.only(
                          right: isUser ? 5 : 0, left: !isUser ? 5 : 0)),
                  Text(
                    "Post Searched",
                    style: TextStyle(
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.time,
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          right: isUser ? 40 : 0, bottom: 15))
                ])))
        : Container();
  }
}
