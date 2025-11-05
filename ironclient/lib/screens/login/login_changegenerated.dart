import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/password_strength.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LoginChangeGenerated extends StatefulWidget {
  final String username;
  //final User user;
  final int screenType;
  final UserFurnace? userFurnace;
  final String existingPassword;
  final String existingPin;

  const LoginChangeGenerated(
      {Key? key,
      required this.username,
      // this.user,
      required this.screenType,
      required this.existingPassword,
      required this.existingPin,
      this.userFurnace})
      : super(key: key);

  @override
  ChangePasswordState createState() {
    return ChangePasswordState();
  }
}

class ChangePasswordState extends State<LoginChangeGenerated> {
  UserFurnace? _userFurnace;

  final _authBloc = AuthenticationBloc();

  bool _showPassword = true;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  bool validatedOnceAlready = false;
  bool _showStrength = false;
  String _strengthText = '';

  String _pinText = '';
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();

  final TextEditingController _pinController = TextEditingController();
  final StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();
  //UsernameGen _usernameGen = UsernameGen();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    if (kDebugMode && !Urls.testingReleaseMode) {
      _password.text = '12345678';
      _password2.text = '12345678';
      _pinText = '1234';
      _pinController.text = _pinText;
    }

    _userFurnace = widget.userFurnace;

    _username.text = widget.username;
    //_password.text = widget.existingPassword;
    //_pinText = widget.existingPin;
    //_pinController.text = widget.existingPin;

    _authBloc.passwordChanged.listen((success) {
      // globalState.user.username = _username.text;
      _authBloc.dispose();

      setState(() {
        _showSpinner = false;
      });

      debugPrint(globalState.user.username);

      if (widget.userFurnace != null) {
        Navigator.pop(context, true);
        //Navigator.pop(context, true);
      } /*else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => Login(
                      username: widget.username,
                      toast: 'password changed successfully',
                    )),
            (Route<dynamic> route) => false);
      }
      */
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
      debugPrint("error $err");

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _authBloc.dispose();
    _pinAnimationController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double condensedWidth = ScreenSizes.getFormScreenWidth(width);
    double textScale = MediaQuery.textScalerOf(context).scale(1);

    debugPrint("width $width");

    final makeBottom = SizedBox(
      height: 65,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
        child: Column(children: <Widget>[
          Expanded(
              child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: ButtonType.getWidth(
                          MediaQuery.of(context).size.width)),
                  child: GradientButton(
                    text: AppLocalizations.of(context)!.update,
                    onPressed: () {
                      _changeGeneratedValues();
                    },
                  ))),
        ]),
      ),
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child:WrapperWidget(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(
                        left: 11, top: 4, bottom: 0, right: 50),
                    child: Row(children: <Widget>[
                      Expanded(
                        child: FormattedText(
                          labelText: AppLocalizations.of(context)!.username,
                          maxLength: 25,
                          controller: _username,
                          onChanged: _revalidate,
                          validator: (value) {
                            if (value.toString().endsWith(' ')) {
                              return AppLocalizations.of(context)!.errorCannotEndWithASpace;
                            /*} else if (value.toString().length < 3) {
                              return 'must be at least 3 chars';*/
                            }else if (value.toString().startsWith(' ')) {
                              return AppLocalizations.of(context)!.errorCannotStartWithASpace;
                            }

                            return null;
                          },
                          //obscureText: !_showPassword,
                        ),
                      ),

                    ])),
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0, right: 10),
                  child: Row(children: <Widget>[
                    Expanded(
                      // flex: 20,
                      child: FormattedText(
                         maxLength: 65,
                        obscureText: !_showPassword,
                        labelText: AppLocalizations.of(context)!.password,
                        controller: _password,
                        onChanged: _calcStrength,
                        maxLines: 1,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return AppLocalizations.of(context)!.errorCannotBeEmpty;
                          } else if (value.toString().endsWith(' ')) {
                            return AppLocalizations.of(context)!.errorCannotEndWithASpace;
                          } else if (value.toString().length < 8) {
                            return AppLocalizations.of(context)!.mustBeAtLeast8Chars;
                          } else if (value.toString().startsWith(' ')) {
                            return AppLocalizations.of(context)!.errorCannotStartWithASpace;
                          }

                          return null;
                        },
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: _showPassword
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
                                    color: globalState.theme.buttonIconSplash),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = true;
                                  });
                                }))
                  ]),
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 11, top: 4, right: 50),
                    child: Row(children: <Widget>[
                      Expanded(
                        // flex: 20,
                        child: FormattedText(
                          maxLength: 65,
                          obscureText: !_showPassword,
                          labelText: AppLocalizations.of(context)!.reenterPassword,
                          controller: _password2,
                          onChanged: _revalidate,
                          maxLines: 1,
                          validator: (value) {
                            if (value.toString() != _password.text.toString()) {
                              return AppLocalizations.of(context)!.passwordsDoNotMatch;
                            }

                            return null;
                          },
                        ),
                      ),
                    ])),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 11, right: 0, top: 0, bottom: 0),
                  child: Row(children: <Widget>[
                    _showStrength
                        ? Expanded(
                            child: Text(
                            _strengthText,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: strengthColorMap(_password.text)),
                          ))
                        : Container(),
                  ]),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(top: 5, left: 25),
                          child: Text(
                            AppLocalizations.of(context)!.pin,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            style: TextStyle(
                                color: globalState.theme.labelTextSubtle,
                                fontSize: 14),
                          )),
                    ]),
                Padding(
                    padding: EdgeInsets.only(
                        top: 15,
                        // right: 50, left: 50
                        right:  (condensedWidth > 500 ? condensedWidth - 500 : 50),
                        left:  50,
                    ),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: !_showPassword,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      animationType: AnimationType.fade,
                      autoDismissKeyboard: false,
                      textStyle: TextStyle(
                          fontSize: 20 / textScale),
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
                      backgroundColor: globalState.theme.background,
                      enableActiveFill: true,
                      errorAnimationController: _pinAnimationController,
                      controller: _pinController,
                      onCompleted: (v) {
                        debugPrint("Completed");
                      },
                      onChanged: (value) {
                        debugPrint(value);
                        setState(() {
                          _pinText = value;
                        });
                      },
                      beforeTextPaste: (text) {
                        return true;
                      },
                    )),
                makeBottom,
              ]),
        ),
      )),
    );



    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: ICAppBar(title: AppLocalizations.of(context)!.setPasswordAndPin),
          body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: true,
              child: Stack(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: makeBody,
                    ),
                    /*Container(
                      //  color: Colors.white,
                      padding: const EdgeInsets.all(0.0),
                      child: makeBottom,
                    ),*/
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ]))),
        );
  }

  void _calcStrength(String value) {
    _revalidate(value);

    setState(() {
      _strengthText = getStrengthString(value);

      if (_strengthText.isNotEmpty) {
        _showStrength = true;
      } else {
        _showStrength = false;
      }
    });
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }

  void _changeGeneratedValues() {
    try {
      if (_formKey.currentState!.validate()) {
        if (_pinText.length != 4) throw (AppLocalizations.of(context)!.pinMustBe4Digits);
        //if (_pinText != _pinText2) throw ('pins do not match');

        setState(() {
          _showSpinner = true;
        });

        _authBloc.changeGeneratedValues(
            widget.username,
            _username.text,
            widget.existingPassword,
            widget.existingPin,
            _password.text,
            _pinText,
            _userFurnace!);
      } else {
        validatedOnceAlready = true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 4,  false);
    }
  }
}
