import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';

class Dimensions{
  static double  getScreenWidth(BuildContext context){
    return  MediaQuery.of(context).size.width;
  }
  static bool  isLandscape(BuildContext context){
    return  MediaQuery.of(context).size.width > MediaQuery.of(context).size.height-ScreenSizes.maskPreviewToolbar;

  }
  static bool  isPortrait(BuildContext context){
    return  MediaQuery.of(context).size.width <= MediaQuery.of(context).size.height-ScreenSizes.maskPreviewToolbar;;
  }

  static double getSmallestSide(BuildContext context){
    return  isPortrait(context)? getScreenWidth(context):getScreenHeight(context);
  }
  static double getWidestSide(BuildContext context){
    return  isPortrait(context)? getScreenHeight(context):getScreenWidth(context);
  }
  static double   getScreenHeight(BuildContext context){
    return  MediaQuery.of(context).size.height-ScreenSizes.maskPreviewToolbar;

  }
  static double getSquareSize(BuildContext context){
    double w=getScreenWidth(context);
    double h=getScreenHeight(context);
    return    w>h?h:w;

  }

  static double getSquareImageSize(double height, double width){
    double w=width;
    double h=height;
    return    w>h?h:w;

  }
}