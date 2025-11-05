import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ICText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final Color? backgroundColor;
  final double? textScaleFactor;
  final TextAlign textAlign;
  final FontStyle fontStyle;
  final TextDecoration textDecoration;
  final int? maxLines;
  final TextOverflow? overflow;
  final String fontFamily;
  final bool softWrap;

  const ICText(this.text,
      {this.fontSize = 14,
      this.fontWeight = FontWeight.normal,
      this.color,
      this.backgroundColor,
      this.textAlign = TextAlign.left,
      this.textScaleFactor,
      this.maxLines,
      this.fontFamily = 'Roboto',
      this.fontStyle = FontStyle.normal,
      this.textDecoration = TextDecoration.none,
      this.softWrap = true,
      this.overflow});

  @override
  Widget build(BuildContext context) {
    late Color textColor;

    if (color == null)
      textColor = globalState.theme.labelText;
    else
      textColor = color!;

    late double scaleFactor;

    if (textScaleFactor == null)
      scaleFactor = globalState.textFieldScaleFactor;
    else
      scaleFactor = textScaleFactor!;

    return Text(
      text,
      textScaler: TextScaler.linear(scaleFactor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
          backgroundColor: backgroundColor,
          fontWeight: fontWeight,
          decoration: textDecoration,
          color: textColor,
          fontFamily: fontFamily,
          fontSize: fontSize - globalState.scaleDownTextFont),
    );
  }
}

class ICSelectableText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final Color? backgroundColor;
  final double? textScaleFactor;
  final TextAlign textAlign;
  final TextDecoration textDecoration;
  final String fontFamily;

  const ICSelectableText(this.text,
      {this.fontSize = 14,
      this.fontWeight = FontWeight.normal,
      this.color,
      this.backgroundColor,
      this.textAlign = TextAlign.left,
      this.fontFamily = 'Roboto',
      this.textDecoration = TextDecoration.none,
      this.textScaleFactor});

  @override
  Widget build(BuildContext context) {
    late Color textColor;

    if (color == null)
      textColor = globalState.theme.labelText;
    else
      textColor = color!;

    late double scaleFactor;

    if (textScaleFactor == null)
      scaleFactor = globalState.textFieldScaleFactor;
    else
      scaleFactor = textScaleFactor!;

    return SelectableText(
      text,
      textScaler: TextScaler.linear(scaleFactor),
      textAlign: textAlign,
      style: TextStyle(
          decoration: textDecoration,
          backgroundColor: backgroundColor,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          color: textColor,
          fontSize: fontSize - globalState.scaleDownTextFont),
    );
  }
}
