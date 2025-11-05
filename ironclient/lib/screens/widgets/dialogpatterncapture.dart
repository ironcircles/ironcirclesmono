import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:pattern_lock/pattern_lock.dart';

class DialogPatternCapture {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static capture(BuildContext context, Function success, String title,
      {UserCircleCache? userCircleCache,
      Function? cancel,
      bool dismissible = true,
      User? user,
      int? notificationType}) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ICText(
                  title,
                  textScaleFactor: globalState.dialogScaleFactor,
                  color: globalState.theme.bottomIcon,
                  fontSize: 20,
                )),
          ),
          contentPadding: const EdgeInsets.all(5.0),
          content: SizedBox(
              height: 250,
              width: 200,
              child: PatternLock(
                  showInput: true,
                  notSelectedColor: Colors.grey,
                  selectedColor: globalState.theme.dialogPattern,
                  pointRadius: 12,
                  onInputComplete: (List<int> input) {
                    //_result = input;

                    Navigator.pop(context);

                    if (input.isNotEmpty) {
                      if (userCircleCache != null) {
                        success(input, userCircleCache);
                      } else if (notificationType != null && user != null) {
                        success(input, user, notificationType: notificationType);
                      } else if (user != null) {
                        success(input, user);
                      } else {
                        success(input);
                      }
                    }
                  })),
          actions: <Widget>[
            user == null
                ? TextButton(
                    child: ICText(
                      AppLocalizations.of(context)!.cancelUpperCase,
                      color: globalState.theme.buttonCancel,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (cancel != null) cancel();
                    })
                : Container(),
            /*new TextButton(
                child: Text(
                  'CONTINUE',
                  style: TextStyle(color: globalState.theme.button),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (_result.isNotEmpty) {
                    if (userCircleCache != null)
                      success(_result, userCircleCache);
                    else
                      success(_result);
                  }
                })   */
          ],
        ),
      ),
    );
  }

/*
  static void _login(
      BuildContext context, String? user, String password, Function callback) {
    try {
      //debugPrint("Before");

      AuthenticationBloc authBloc = AuthenticationBloc();

      if (password.isEmpty) {
        //displaySnackBar("password required");
        FormattedSnackBar.showSnackbarWithContext(context, 'password required', "", 2);

        return;
      }

      authBloc.authCredentials.listen((success) {
        // Navigator.pushReplacementNamed(context, '/home');
        //_authBloc.dispose();
        callback();
        //Navigator.pop(context);
        Navigator.of(context).pop();

        authBloc.dispose();
      }, onError: (err) {
        String message = err.toString();
        if (message == 'Exception: Invalid username or password')
          message = 'invalid password';
        FormattedSnackBar.showSnackbarWithContext(context, message, "", 2);
        debugPrint("error $err");
      }, cancelOnError: true);

      authBloc.authenticateCredentials(user, password);
    } catch (err, trace) { LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }
  }

   */
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}
