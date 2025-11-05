import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';

class DialogRestCodeFragments {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static codeFragmentsPopup(
    BuildContext context,
    String username,
    Function success,
  ) async {
    //bool _validPassword = false;
    TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            "${AppLocalizations.of(context)!.resetCodePrompt} $username",
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          contentPadding: const EdgeInsets.all(10.0),
          content: PasswordValidator(scaffoldKey, _password),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.cancelUpperCase,
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  Navigator.pop(context);
                }),
            TextButton(
                child: Text(AppLocalizations.of(context)!.continueUpperCase,
                    style: TextStyle(
                      color: globalState.theme.buttonIcon,
                    )),
                onPressed: () {
                  _login(
                    context,
                    username,
                    _password.text,
                    success,
                  );
                  //if (_validPassword) Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }

  static void _login(
      BuildContext context, String user, String password, Function callback) {
    try {
      //debugPrint("Before");

      AuthenticationBloc authBloc = AuthenticationBloc();

      if (password.isEmpty) {
        //displaySnackBar("password required");
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.resetCodeRequired, "", 2,  false);

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
        if (message == 'Exception: Invalid rest code') {
          message = AppLocalizations.of(context)!.invalidResetCode;
          FormattedSnackBar.showSnackbarWithContext(
              context, message, "", 2,  false);
        } else {
          FormattedSnackBar.showSnackbarWithContext(
              context, message, "", 2,  true);
        }
        debugPrint("error $err");
      }, cancelOnError: true);

      authBloc.authenticateCredentials(user, password, '');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2,  true);
    }
  }
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

class PasswordValidator extends StatefulWidget {
  final scaffoldKey;
  final TextEditingController controller;

  const PasswordValidator(
    this.scaffoldKey,
    this.controller,
    /* this.circleObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.userFurnace,
      this.copy,
      this.share,*/
  );

  PasswordValidatorState createState() => PasswordValidatorState();
}

class PasswordValidatorState extends State<PasswordValidator> {
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: 110,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //Spacer(),

                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                  ),
                  Expanded(
                    child: TextFormField(
                      cursorColor: globalState.theme.textField,
                      autofocus: true,
                      controller: widget.controller,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        //labelText: 'enter password',
                        hintText: AppLocalizations.of(context)!.resetCodeHint,
                      ),
                    ),
                  ),
                  _showPassword
                      ? IconButton(
                          icon: Icon(Icons.visibility,
                              color: globalState.theme.buttonIcon),
                          onPressed: () {
                            setState(() {
                              _showPassword = false;
                            });
                          })
                      : IconButton(
                          icon: Icon(Icons.visibility,
                              color: globalState.theme.buttonDisabled),
                          onPressed: () {
                            setState(() {
                              _showPassword = true;
                            });
                          })
                ]),
              ]),
        ));
  }
}
