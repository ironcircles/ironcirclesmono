import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/login_changepassword2.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ChangePassword1 extends StatefulWidget {
  final String? username;
  //final User user;
  final int screenType;
  final UserFurnace? userFurnace;
  final bool authOnly;

  const ChangePassword1(
      {Key? key,
      required this.username,
      // this.user,
      required this.screenType,
      this.authOnly = false,
      this.userFurnace})
      : super(key: key);

  @override
  ChangePasswordState createState() {
    return ChangePasswordState();
  }
}

class ChangePasswordState extends State<ChangePassword1> {
  UserFurnace? _userFurnace;

  final _authBloc = AuthenticationBloc();
  late TextEditingController _existing;

  bool _showExisting = false;
  bool validatedOnceAlready = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String _pinText = '';
  final TextEditingController _pinController = TextEditingController();
  final StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    _userFurnace = widget.userFurnace;

    _userFurnace ??= globalState.userFurnace;

    _existing = TextEditingController();

    _authBloc.authCredentials.listen((success) {
      // globalState.user.username = _username.text;
      _authBloc.dispose();

      setState(() {
        _showSpinner = false;
      });

      if (widget.authOnly) {
        Navigator.pop(context);
        DialogNotice.showNoticeOptionalLines(
            context, AppLocalizations.of(context)!.success, AppLocalizations.of(context)!.credentialsVerified, false);
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePassword2(
                //imageProvider:
                //  const AssetImage("assets/large-image.jpg"),
                username: widget.username!,
                existingPassword: _existing.text,
                existingPin: _pinText,
                screenType: PassScreenType.CHANGE_PASSWORD,
                userFurnace: widget.userFurnace,
              ),
            ));
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _existing.dispose();
    _authBloc.dispose();
    _pinAnimationController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.of(context).size.width;
    double condensedWidth = ScreenSizes.getFormScreenWidth(width);

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: WrapperWidget(child:Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormattedText(
                        //enableInteractiveSelection: false,
                        maxLength: 65,
                        obscureText: !_showExisting,
                        labelText: (widget.screenType ==
                                    PassScreenType.CHANGE_PASSWORD ||
                                widget.screenType ==
                                    PassScreenType.PASSWORD_EXPIRED)
                            ? AppLocalizations.of(context)!.enterExistingPassword
                            : AppLocalizations.of(context)!.enterResetCode,
                        controller: _existing,
                        maxLines: 1,
                        onChanged: _revalidate,
                        validator: (value) {
                          if (value.toString().trim().isEmpty) {
                            return widget.screenType ==
                                        PassScreenType.CHANGE_PASSWORD ||
                                    widget.screenType ==
                                        PassScreenType.PASSWORD_EXPIRED
                                ? AppLocalizations.of(context)!.passwordCantEmpty
                                : AppLocalizations.of(context)!.resetCodeCantEmpty;
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: _showExisting
                            ? IconButton(
                                icon: Icon(Icons.visibility,
                                    color: globalState.theme.buttonIcon),
                                onPressed: () {
                                  setState(() {
                                    _showExisting = false;
                                  });
                                })
                            : IconButton(
                                icon: Icon(Icons.visibility,
                                    color: globalState.theme.buttonIconSplash),
                                onPressed: () {
                                  setState(() {
                                    _showExisting = true;
                                  });
                                }))
                  ]),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(top: 5, left: 25),
                          child: Text(
                            AppLocalizations.of(context)!.enterExistingPin,
                            style: TextStyle(
                                color: globalState.theme.labelTextSubtle,
                                fontSize: 18),
                          )),
                    ]),
                Padding(
                    padding:
                         EdgeInsets.only(top: 15, right:  (condensedWidth > 500 ? condensedWidth - 500 : 50), left: 50),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: !_showExisting,
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
              ])),
        ),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: ICAppBar(title: AppLocalizations.of(context)!.validateExistingPassword),
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
                    Container(
                      //  color: Colors.white,
                      padding: const EdgeInsets.all(0.0),
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ])),
          floatingActionButton: FloatingActionButton(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            backgroundColor: globalState.theme.button,
            onPressed: () {
              _next();
            },
            child: Icon(
              Icons.arrow_forward,
              color: globalState.theme.background,
            ),
          ),
        ));
  }

  void _next() {
    try {
      if (_formKey.currentState!.validate()) {
        if (_pinText.length != 4) throw (AppLocalizations.of(context)!.pinMustBe4Digits);

        setState(() {
          _showSpinner = true;
        });
        _authBloc.validatePassword(_userFurnace!, _existing.text, _pinText);
      } else {
        validatedOnceAlready = true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 4, false);

      setState(() {
        _showSpinner = false;
      });
    }
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }
}
