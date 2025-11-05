import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class GradientButton extends StatelessWidget {
  final double width;
  final double? height;
  final Function? onPressed;
  final String text;
  final Color? color1;
  final Color? color2;
  final Color? textColor;

  const GradientButton({
    Key? key,
    this.width = double.infinity,
    this.height,
    this.onPressed,
    this.color1,
    this.color2,
    this.textColor,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double padding = width == double.infinity ? 5 : ButtonType.getWidth(width);

    return Padding(
        padding: EdgeInsets.only(left: padding, right: padding, bottom: 5),
        child: Container(
          width: width,
          height: height ?? 58.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color2 == null
                ? globalState.theme.button.withOpacity(.2)
                : color2!.withOpacity(.2),
          ),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.transparent,
            ),
            //textColor: textColor == null ? Colors.white : textColor,
            //color: Colors.transparent,
            // shape:
            // RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            onPressed: onPressed as void Function()?,
            child: Text(
              text,
              textScaler: const TextScaler.linear(1.0),
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 16.0 - globalState.scaleDownButtonFont,
                fontFamily: 'Righteous',
                fontWeight: FontWeight.w700,
                color: color2 ?? globalState.theme.button,
              ),
          ),
        )));
  }
}
