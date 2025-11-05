import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class CircleObjectDraft extends StatelessWidget {
  final CircleObject circleObject;

  final bool showTopPadding;
  final double _topPadding = 10;

  const CircleObjectDraft({
    required this.circleObject,
    this.showTopPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return circleObject.draft == true
        ? Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  circleObject.type == CircleObjectType.CIRCLEIMAGE
                      ? Padding(
                          padding: EdgeInsets.only(
                            top: showTopPadding ? _topPadding : 0,
                          ),
                          child: Icon(
                            Icons.image,
                            color: globalState.theme.labelText,
                            size: 30,
                          ))
                      : circleObject.type == CircleObjectType.CIRCLEVIDEO
                          ? Padding(
                              padding: EdgeInsets.only(
                                top: showTopPadding ? _topPadding : 0,
                              ),
                              child: Icon(
                                Icons.movie_outlined,
                                color: globalState.theme.labelText,
                                size: 30,
                              ))
                          : circleObject.type == CircleObjectType.CIRCLEGIF
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: showTopPadding ? _topPadding : 0,
                                  ),
                                  child: Icon(
                                    Icons.gif_box,
                                    color: globalState.theme.labelText,
                                    size: 30,
                                  ))
                              : circleObject.type == CircleObjectType.CIRCLELIST
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                        top: showTopPadding ? _topPadding : 0,
                                      ),
                                      child: Icon(
                                        Icons.check_box,
                                        color: globalState.theme.labelText,
                                        size: 30,
                                      ))
                                  : circleObject.type ==
                                          CircleObjectType.CIRCLERECIPE
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            top: showTopPadding
                                                ? _topPadding
                                                : 0,
                                          ),
                                          child: Icon(
                                            Icons.restaurant,
                                            color: globalState.theme.labelText,
                                            size: 30,
                                          ))
                                      : circleObject.subType != null && circleObject.subType == SubType.LOGIN_INFO
                                          ? Padding(
                                              padding: EdgeInsets.only(
                                                top: showTopPadding
                                                    ? _topPadding
                                                    : 0,
                                              ),
                                              child: Icon(
                                                Icons.login,
                                                color:
                                                    globalState.theme.labelText,
                                                size: 30,
                                              ))
                                          : Container(),
                  Container(),
                  Padding(
                      padding: EdgeInsets.only(
                        top: showTopPadding ? _topPadding : 0,
                      ),
                      child: const ICText(
                        ' Draft',
                        fontSize: 16,
                        color: Colors.red,
                      )),
                ]))
        : Container();
  }
}
