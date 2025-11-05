import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ndialog/ndialog.dart';

class ICProgressDialog {
  ProgressDialog? _progressDialog;

  show(BuildContext context, String text, {bool barrierDismissable = false}) {
    if (_progressDialog != null) {
      _progressDialog!.dismiss();
      _progressDialog = null;
    }

    _progressDialog = ProgressDialog(context,
        backgroundColor: globalState.theme.dialogTransparentBackground,
        dialogStyle: DialogStyle(
          elevation: 0,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: globalState.theme.background,
        ),
        dismissable: barrierDismissable,
        defaultLoadingWidget: SizedBox(
          height: 50,
          width: 50,
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(globalState.theme.button),
            ),
          ),
        ),
        message: Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Text(
              text,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(color: globalState.theme.labelText),
            )),
        title: Text(
          AppLocalizations.of(context)!.pleaseWait,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ));
    _progressDialog!.show();
  }

  dismiss() {
    if (_progressDialog != null) {
      _progressDialog!.dismiss();
      _progressDialog = null;
    }
  }
}
