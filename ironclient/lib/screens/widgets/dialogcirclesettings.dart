import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DialogCircleSettings {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static confirmChange(
      BuildContext context,
      int settingChangeType,
      Circle? circle,
      String localizedMessage,
      String apiMessage,
      Function success,
      {Function? fail}) async {
    //message = NotificationLocalization.getLocalizedString(message, context);

    await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.changeSettingsTitle,
              style: TextStyle(color: globalState.theme.bottomIcon),
            ),
          ),
          contentPadding: const EdgeInsets.all(10.0),
          content: Padding(
              padding: const EdgeInsets.only(top: 10, left: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      circle!.memberCount == 1 ||
                              circle.ownershipModel == CircleOwnership.OWNER
                          ? settingChangeType ==
                                  CircleSettingChangeType.SECURITY
                              ? circle.dm
                                  ? AppLocalizations.of(context)!
                                      .changeSettingsDMSecurityMessageSubTitle
                                  : AppLocalizations.of(context)!
                                      .changeSettingsCircleSecuritySubTitle
                              : circle.dm
                                  ? AppLocalizations.of(context)!
                                      .changeSettingsDMPrivacyMessageSubTitle
                                  : AppLocalizations.of(context)!
                                      .changeSettingsCirclePrivacySubTitle
                          : circle.securityVotingModel ==
                                  CircleVoteModel.UNANIMOUS
                              ? AppLocalizations.of(context)!
                                  .changeSettingsUnanimous
                              : AppLocalizations.of(context)!
                                  .changeSettingsMajority,
                      style:
                          TextStyle(color: globalState.theme.labelTextSubtle),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(
                          top: 15,
                          left: 5,
                        ),
                        child: Text(
                          localizedMessage,
                          //"1\n2\n3\n4\n5\n6\n7\n8",
                          style: TextStyle(
                              color: globalState.theme.circleText,
                              fontSize: 14,
                              fontStyle: FontStyle.italic),
                        ))
                  ])),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.cancelUpperCase,
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  if (fail != null) fail();
                  Navigator.pop(context);
                }),
            TextButton(
                child: Text(
                  AppLocalizations.of(context)!.continueUpperCase,
                  style: TextStyle(color: globalState.theme.buttonIcon),
                ),
                onPressed: () {
                  success(apiMessage);
                  Navigator.pop(context);
                  //if (_validPassword) Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }

  /*
  static void _login(
      BuildContext context, String user, String password, Function callback) {
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
