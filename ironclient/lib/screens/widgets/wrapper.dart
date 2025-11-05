import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';

class WrapperWidget extends StatelessWidget {
  final Widget child;

  const WrapperWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return globalState.isDesktop()
        ? Center(
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: ScreenSizes.getFormScreenWidth(width),
                    minWidth: ScreenSizes.getFormMinScreenWidth(width)), child: child))
        : Container(
            constraints: BoxConstraints(
            maxWidth: ScreenSizes.getFormScreenWidth(width),
            minWidth: ScreenSizes.getFormMinScreenWidth(width),
          ), child: child);
  }
}
