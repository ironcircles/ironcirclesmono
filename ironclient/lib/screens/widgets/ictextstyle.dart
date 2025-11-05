import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ICTextStyle {
  /*static TextStyle getStyle({required Color color, double fontSize: 14.0, FontStyle fontStyle = FontStyle.normal}) {
    return GoogleFonts.lato(
        textStyle: TextStyle(color: color, fontSize: fontSize, fontStyle: fontStyle));
  }*/

  static double appBarFontSize = 22.0;

  static TextStyle getStyle(
      {required Color color,
      required BuildContext context,
      double fontSize = 14.0,
      FontStyle fontStyle = FontStyle.normal}) {
    return int.parse(AppLocalizations.of(context)!.language) == Language.TURKISH
        ? GoogleFonts.roboto(
            textStyle: TextStyle(
                color: color,
                fontSize: fontSize - globalState.scaleDownTextFont,
                fontStyle: fontStyle))
        : GoogleFonts.lato(
            textStyle: TextStyle(
                color: color,
                fontSize: fontSize - globalState.scaleDownTextFont,
                fontStyle: fontStyle));
  }

  static TextStyle getDropdownStyle(
      {required Color color,
      required BuildContext context,
      double fontSize = 18.0,
      FontStyle fontStyle = FontStyle.normal}) {
    return int.parse(AppLocalizations.of(context)!.language) == Language.TURKISH
        ? GoogleFonts.roboto(
            textStyle: TextStyle(
                color: color, fontSize: fontSize, fontStyle: fontStyle))
        : GoogleFonts.lato(
            textStyle: TextStyle(
                color: color,
                fontSize: fontSize - globalState.scaleDownTextFont,
                fontStyle: fontStyle));
  }
}
