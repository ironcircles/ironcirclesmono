import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';

class DialogYesNo {
  static Future<void> askYesNo(BuildContext context, String title, String body,
      Function yes, Function? no, bool localize,
      [passthrough]) async {
    // flutter defined function
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
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
            style: TextStyle(color: globalState.theme.dialogButtons),
          )),
          content: Text(
            body,
            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
            style: TextStyle(color: globalState.theme.dialogLabel, fontSize: 15),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.no,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.buttonDisabled),
              ),
              onPressed: () {
                if (no != null) no();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.yes,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                if (passthrough != null) {
                  yes(passthrough);
                } else {
                  yes();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> coinsAskYesNo(BuildContext context, String title, String label, TextEditingController inputController, Function yes, Function? no, bool localize, String yourCoins, [passthrough]) async {
    return showDialog<void>(
      context: context,
        barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Text(
              title,
              textScaler: TextScaler.linear(globalState.dialogScaleFactor),
              style: TextStyle(color: globalState.theme.labelText),
            )),
          content: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.giveCoinDialogBalance, // "Your balance: ",
                style: TextStyle(
                    color: globalState.theme.buttonDisabled,
                    fontSize: 15),
                  textScaler: const TextScaler.linear(1.0)
              ),
              ClipOval(
                  child: Image.asset(
                    'assets/images/ironcoin.png',
                    height: 20,
                    width: 20,
                    fit: BoxFit.fitHeight,
                  )),
              const Padding(padding: EdgeInsets.only(right: 3)),
              Text(
                yourCoins,
                style: TextStyle(
                    color: globalState.theme.buttonDisabled,
                    fontSize: 14),
                  textScaler: const TextScaler.linear(1.0)
              )
            ]
          ),
          actions: <Widget>[
            ExpandingText(
              maxLength: 4, ///limit to 9999
              labelText: label,
              controller: inputController,
              textInputType: TextInputType.number,
            ),
            Row(children: [const Spacer(), TextButton(
              child: Text(
                AppLocalizations.of(context)!.no,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                  fontSize: 18, color: globalState.theme.buttonDisabled),
              ),
              onPressed: () {
                if (no != null) no();
                Navigator.of(context).pop();
              }
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.yes,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                  fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                if (passthrough != null) {
                  yes (passthrough);
                } else {
                  yes();
                }
              }
            )])
          ]
        );
      }
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
