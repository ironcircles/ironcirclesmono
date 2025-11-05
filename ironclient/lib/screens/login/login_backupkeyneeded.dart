/*import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/utils/password_strength.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class TempBackupKeyNeeded extends StatefulWidget {
  //final String? username;
  final UserFurnace userFurnace;

  TempBackupKeyNeeded({
    Key? key,
    required this.userFurnace,
    // this.username,
  }) : super(key: key);

  @override
  RegistrationState createState() {
    return RegistrationState();
  }
}

class RegistrationState extends State<TempBackupKeyNeeded> {
  final _authBloc = AuthenticationBloc();
  // TextEditingController? _username;
  TextEditingController _password = TextEditingController();
  TextEditingController _password2 = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  ScrollController _scrollController = ScrollController();

//  File? _image;

  bool _showStrength = false;
  double _strength = 0;
  String _strengthText = '';
  bool _showPassword = false;

  String _pinText = '';
  TextEditingController _pinController = TextEditingController();
  StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
    //_password = TextEditingController();
    // _password2 = TextEditingController();

    if (!kReleaseMode) {
      _password.text = '12345678';
      _password2.text = '12345678';
      //_pinText = '1234';
    }

    _authBloc.authCredentials.listen((user) {
      //1) delete all user keys from this device for this user

      //2) download and decrypt the backup key and remote userkey

      //3)

      /*Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: user,
      );

       */

      Navigator.pop(context, true);
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _password.dispose();
    _password2.dispose();
    _authBloc.dispose();
    _pinAnimationController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: <
              Widget>[
            Padding(
                padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                child: Row(children: <Widget>[
                  Expanded(
                      child: Text(
                          'This device needs to be authenticated against the password and pin you created on another device.\n\n'))
                ])),
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: FormattedText(
                    //enableInteractiveSelection: false,
                    obscureText: !_showPassword,
                    labelText: 'enter password',
                    controller: _password,
                    onChanged: _calcStrength,
                    maxLines: 1,
                    validator: (value) {
                      if (value.toString().trim().isEmpty) {
                        return 'password cannot be empty';
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
              padding:
                  const EdgeInsets.only(left: 11, right: 55, top: 0, bottom: 0),
              child: Row(children: <Widget>[
                _showStrength
                    ? Expanded(
                        child: Text(
                        _strengthText,
                        textAlign: TextAlign.end,
                        style:
                            TextStyle(color: strengthColorMap(_password.text)),
                      ))
                    : Container(),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(top: 5, left: 25),
                  child: Text(
                    'enter pin:',
                    style: TextStyle(
                        color: globalState.theme.labelTextSubtle, fontSize: 18),
                  )),
            ]),
            Padding(
                padding: const EdgeInsets.only(top: 15, right: 100, left: 50),
                child: PinCodeTextField(
                  appContext: context,
                  length: 4,
                  obscureText: !_showPassword,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  animationType: AnimationType.fade,
                  autoDismissKeyboard: false,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(5),
                    //errorBorderColor: Colors.orange,
                    inactiveColor: globalState.theme.labelTextSubtle,
                    selectedColor: globalState.theme.buttonIcon,
                    selectedFillColor: globalState.theme.menuIconsAlt,
                    fieldHeight: 35,
                    fieldWidth: 25,
                    inactiveFillColor: globalState.theme.background,
                    activeFillColor: globalState.theme.labelTextSubtle,
                  ),
                  animationDuration: Duration(milliseconds: 300),
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
          ]),
        ),
      ),
    );


    final makeBottom = Container(
      height: 75.0,
      child: Padding(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                  child: GradientButton(
                text: 'LOGIN',
                onPressed: () {
                  authenticate();
                },
              ))
            ]),
          ])),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: AppBar(
            iconTheme: IconThemeData(
              color: globalState.theme.menuIcons, //change your color here
            ),
            backgroundColor: globalState.theme.appBar,
            title: Text('Authentication Required',
                style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
          ),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: makeBody,
                    ),
                    makeBottom,
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            ),
          ),
        ));
  }

  _scrollTop() {
    _scrollController.animateTo(0,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
  }


  void _calcStrength(String value) {
    setState(() {
      if (value.isEmpty) {
        _strengthText = "";
        _strength = 0;
        _showStrength = false;
      }

      _strength = estimatePasswordStrength(value);
      _showStrength = true;

      if (_strength < .2)
        _strengthText = "password strength is weak";
      else if (_strength < .4)
        _strengthText = "password strength is weak";
      else if (_strength < .6)
        _strengthText = "password strength is average";
      else if (_strength < .8)
        _strengthText = "password strength is good";
      else if (_strength < 1)
        _strengthText = "password strength is good";
      else if (_strength == 1) _strengthText = "password strength is great";

      //_password.text = value;
    });
  }

  void authenticate() async {
    try {
      if (_formKey.currentState!.validate()) {
        /*if (_over18) {
        setState(() {
          _showSpinner = true;
        });

       */

        if (_pinText.length < 4)
          throw ('4 digit pin is required as well as password');

        setState(() {
          _showSpinner = true;
        });

        await _authBloc.authenticateCredentials(
            widget.userFurnace.username!, _password.text, _pinText);

        /*await _authBloc.encryptBackupAndUserKey(
          widget.userFurnace,
          _password.text.trimLeft().trimRight(),
          _pinText,
        );

         */

        //Navigator.pop(context, true);
      } else {
        _scrollTop();
      } /*else {
        await DialogNotice.showNotice(
            context,
            'Must be over 18',
            'You did not attest you are 18 or older.  You can enjoy this instead.',
            null,
            null,
            null);
        //FormattedSnackBar.showSnackbarWithContext(context, 'You are not over 18.  Here is something you can enjoy instead', "", 4);
        LaunchURLs.openExternalBrowserUrl(
            context, 'https://kids.britannica.com/kids/browse/subjects');
      }

    }
    */
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 4);
    }
  }
}

 */
