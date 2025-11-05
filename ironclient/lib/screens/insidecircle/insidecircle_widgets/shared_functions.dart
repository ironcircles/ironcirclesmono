import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/circle.dart';
import 'package:ironcirclesapp/models/circleobject.dart';

class SharedFunctions {
  static const double iconPadding = 10;

  static double addIconsPadding(
    Circle? circle,
    CircleObject circleObject,
    bool isUser,
    Function? deleteCache,
    Function? cancel,
  ) {
    //check for delete
    if (isUser) return iconPadding;

    //check open external
    if (circle != null) {
      if (circleObject.type == CircleObjectType.CIRCLELINK) return iconPadding;
    }

    //check share
    if (circle != null) {
      if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
        if (circle.privacyShareImage != null) {
          if (circle.privacyShareImage!) return iconPadding;
        } else if (circleObject.type == CircleObjectType.CIRCLELINK) {
          if (circle.privacyShareURL != null) {
            if (circle.privacyShareURL!) return iconPadding;
          }
        } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
          if (circle.privacyShareGif != null) {
            if (circle.privacyShareGif!) return iconPadding;
          }
        }
      }
    }

    //Check functions
    if (deleteCache != null || cancel != null) {
      return iconPadding;
    }

    //check copy
    if (circle != null) {
      if (circleObject.type == CircleObjectType.CIRCLEMESSAGE) {
        if (circle.privacyCopyText != null) {
          if (circle.privacyCopyText!) return iconPadding;
        }
      }
    }

    return 0;
  }

  static double calculateTopPadding(CircleObject circleObject, bool showDate) {
    double retValue = 0;

    if (circleObject.showOptionIcons && circleObject.id != null) {
      if (showDate)
        retValue = retValue + 35;
      else
        retValue = retValue + 70;
    }

    return 0;
  }

  static double calculateBottomPadding(CircleObject circleObject) {
    double retValue = 0;

    if (circleObject.timer != null) retValue = 5;

    if (circleObject.scheduledFor != null
      && circleObject.scheduledFor!.isAfter(DateTime.now())) {
      if (circleObject.subType == SubType.LOGIN_INFO) {
        retValue = 20;
      } else if (circleObject.type != CircleObjectType.CIRCLEMESSAGE) {
        retValue = 20;
      }
    }

    return retValue;
  }
}
