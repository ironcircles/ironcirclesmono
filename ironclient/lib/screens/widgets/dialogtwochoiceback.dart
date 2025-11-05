import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/globalstate.dart';

class DialogTwoChoiceBack {
  static Future<void> askTwoChoice(BuildContext context,
      String title,
      String line1,
      String line2,
      Function option1,
      Function option2) async {
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
          content:
          Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10, right: 0, left: 10),
                    child: SelectableText(
                      line1,
                      textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                      style: TextStyle(
                        fontSize: 16,
                        color: globalState.theme.dialogLabel),
                    )),
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 20, right: 0, left: 10),
                      child: SelectableText(
                        line2,
                        textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                        style: TextStyle(
                            fontSize: 16,
                            color: globalState.theme.dialogLabel),
                      )),
                ]
              )
            )
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  AppLocalizations.of(context)!.back,
                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                  style: TextStyle(
                      fontSize: 18, color: globalState.theme.buttonDisabled),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                }
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.deleteAccount,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                  fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                option1();
                Navigator.of(context).pop();
              }
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.removeNetwork,
                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 18, color: globalState.theme.bottomIcon),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                option2();
              },
            )
          ]
        );
      }
    );
  }
 }