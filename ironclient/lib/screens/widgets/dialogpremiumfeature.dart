import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_privacyplus.dart';

class DialogPremiumFeature {
  static Future<void> premiumFeature(
      BuildContext context, String title, String body) async {
    // flutter defined function
    return showDialog<void>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            title,
            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
            style: TextStyle(color: globalState.theme.labelText),
          )),
          content: Text(
            body,
            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
            style: TextStyle(color: globalState.theme.bottomIcon),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.cancel,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.buttonDisabled),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.premiumFeatureShowMe,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IronStorePrivacyPlus(
                              fromFurnaceManager: false,
                            )));
              },
            ),
          ],
        );
      },
    );
  }

  /*
  // user defined function
  //TODO remove this functino
  static Future<void> showYesNoDepricated(
      BuildContext context, String title, String body, Function result,
      [String? passthrough]) async {
    // flutter defined function
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: Text(body),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: Text(
                "Yes",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                if (passthrough != null) {
                  result('yes', passthrough);
                } else {
                  result('yes');
                }
              },
            ),
            TextButton(
              child: Text(
                "No",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (passthrough != null) {
                  result('no', passthrough);
                } else {
                  result('no');
                }
              },
            ),
          ],
        );
      },
    );
  }

   */
}
