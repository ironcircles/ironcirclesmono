import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/utils/notification_localization.dart';

class FormattedSnackBar {
  /*static void showSnackbar(context, String message, String actionText, int duration) {
    final snackBar = SnackBar(
        backgroundColor:globalState.theme.messageBackground, content: Text(message.replaceAll("Exception: ", "",), textScaleFactor: globalState.labelScaleFactor,
            style: TextStyle(color: globalState.theme.snackbarText, fontSize: 14.0)),
        duration: Duration(seconds: duration),
        action: actionText.isNotEmpty
            ? SnackBarAction(
                label: actionText,
                textColor: Colors.white,
                onPressed: () {
                  // Some code to undo the change!
                },
              )
            : null, );

    scaffoldKey.currentState.showSnackBar(snackBar);
  }

   */

  static void showSnackbarWithContext(BuildContext context, String message,
      String actionText, int duration, bool localize) {
    message = message.replaceAll(
      "Exception: ",
      "",
    );

    if (localize) {
      message = NotificationLocalization.getLocalizedString(message, context);
    }

    final snackBar = SnackBar(
      backgroundColor: globalState.theme.messageBackground,
      content: Text(message,
          textScaler: TextScaler.linear(globalState.labelScaleFactor),
          style:
              TextStyle(color: globalState.theme.snackbarText, fontSize: 14.0)),
      duration: Duration(seconds: duration),
      action: actionText.isNotEmpty
          ? SnackBarAction(
              label: actionText,
              textColor: Colors.white,
              onPressed: () {
                // Some code to undo the change!
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
