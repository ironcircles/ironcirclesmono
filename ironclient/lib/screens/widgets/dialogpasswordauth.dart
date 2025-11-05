import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class DialogPasswordAuth {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static passwordPopup(
    BuildContext context,
    //String? username,
    UserFurnace userFurnace,
    Function success,
  ) async {
    //bool _validPassword = false;
    TextEditingController _password = TextEditingController();
    TextEditingController _pinController = TextEditingController();
    TextEditingController _pinControllerValue = TextEditingController();
    //String _pinText = '';

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.enterPasswordPin,
              textScaler: TextScaler.linear(globalState.dialogScaleFactor),
              style: TextStyle(color: globalState.theme.bottomIcon),
            ),
          ),
          contentPadding: const EdgeInsets.all(10.0),
          content: PasswordValidator(
              scaffoldKey, _password, _pinController, _pinControllerValue),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.cancelUpperCase,
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  Navigator.pop(context);
                }),
            TextButton(
                child: Text(
                  AppLocalizations.of(context)!.continueUpperCase,
                  textScaler: TextScaler.linear(globalState.labelScaleFactor),
                  style: TextStyle(color: globalState.theme.buttonIcon),
                ),
                onPressed: () {
                  _login(
                    context,
                    userFurnace,
                    _password.text,
                    _pinControllerValue.text,
                    success,
                  );
                  //if (_validPassword) Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }

  static void _login(BuildContext context, UserFurnace userFurnace,
      String password, String pin, Function callback) {
    try {
      //debugPrint("Before");

      AuthenticationBloc authBloc = AuthenticationBloc();

      if (password.isEmpty) {
        //displaySnackBar("password required");
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.errorpasswordRequired, "", 2, false);

        return;
      }

      if (pin.length != 4) {
        //displaySnackBar("password required");
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.errorpinRequired, "", 2, false);

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
        if (message == 'Exception: Invalid username or password') {
          message = AppLocalizations.of(context)!.invalidPassword;
          FormattedSnackBar.showSnackbarWithContext(
              context, message, "", 2, false);
        } else {
          FormattedSnackBar.showSnackbarWithContext(
              context, message, "", 2, true);
        }
        debugPrint("error $err");
      }, cancelOnError: true);

      //authBloc.authenticateCredentials(user, password, pin);
      authBloc.validatePassword(userFurnace, password, pin);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
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
  final TextEditingController pinController;
  final TextEditingController pinControllerValue;
  //final String pinText;

  const PasswordValidator(
    this.scaffoldKey,
    this.controller,
    this.pinController,
    this.pinControllerValue,
    /* this.circleObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.userFurnace,
      this.copy,
      this.share,*/
  );

  @override
  PasswordValidatorState createState() => PasswordValidatorState();
}

class PasswordValidatorState extends State<PasswordValidator> {
  bool _showPassword = false;

  final StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // _pinController.dispose();
    _pinAnimationController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.of(context).size.width;
    double condensedWidth = ScreenSizes.getFormScreenWidth(width);

    return SizedBox(
        //width: 200,
        height: 168,
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
                      maxLength: 65,
                      style: TextStyle(
                          fontSize: (18 / globalState.mediaScaleFactor) *
                              globalState.textFieldScaleFactor,
                          color: globalState.theme.textFieldText),
                      autofocus: true,
                      controller: widget.controller,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                          //labelText: 'enter password',
                          hintText: AppLocalizations.of(context)!
                              .enterPasswordHintText),
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
                Padding(
                    padding: EdgeInsets.only(
                        top: 15, right:  (condensedWidth > 500 ? condensedWidth - 500 : 50), left: 25),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      obscureText: !_showPassword,
                      animationType: AnimationType.fade,
                      autoDismissKeyboard: false,
                      textStyle: TextStyle(fontSize: 20 / textScale),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(5),
                        //errorBorderColor: Colors.orange,
                        inactiveColor: globalState.theme.labelTextSubtle,
                        selectedColor: globalState.theme.buttonIcon,
                        selectedFillColor: globalState.theme.menuIconsAlt,
                        fieldHeight: 30,
                        fieldWidth: 30,
                        inactiveFillColor: globalState.theme.labelTextSubtle,
                        activeFillColor: globalState.theme.labelTextSubtle,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: globalState.theme.dialogBackground,
                      enableActiveFill: true,
                      errorAnimationController: _pinAnimationController,
                      controller: widget.pinController,
                      onCompleted: (v) {
                        debugPrint("Completed");
                      },
                      onChanged: (value) {
                        debugPrint(value);
                        setState(() {
                          widget.pinControllerValue.text = value;
                        });
                      },
                      beforeTextPaste: (text) {
                        debugPrint("Allowing to paste $text");
                        //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                        //but you can show anything you want here, like your pop up saying wrong paste format or etc
                        return true;
                      },
                    )),
              ]),
        ));
  }
}
