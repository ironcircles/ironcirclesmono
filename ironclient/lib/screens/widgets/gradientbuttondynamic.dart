import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class GradientButtonDynamic extends StatelessWidget {
  final Function? onPressed;
  final String text;
  //final Color? color1;
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final double height;
  final double opacity;

  const GradientButtonDynamic({
    Key? key,
    this.onPressed,
    this.color,
    this.textColor,
    this.fontSize = 16,
    this.height = 39,
    this.opacity = .2,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: globalState.theme.background,
        ),
        child: Container(
          padding: const EdgeInsets.all(0),///TODO this should be 4 for iOS, was it a mini problem?
          height: height,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: color == null
                  ? globalState.theme.button.withOpacity(opacity)
                  : color!.withOpacity(opacity)),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.transparent,
            ),
            onPressed: onPressed as void Function()?,
            child: Text(
              text,

              textScaler: const TextScaler.linear(1),
              style: TextStyle(overflow: TextOverflow.fade,
                fontSize: fontSize - globalState.scaleDownTextFont,
                fontFamily: 'Righteous',
                fontWeight: FontWeight.w700,
                color: textColor ?? color ?? globalState.theme.button,
              ),
            ),
          ),
        ));
  }
}