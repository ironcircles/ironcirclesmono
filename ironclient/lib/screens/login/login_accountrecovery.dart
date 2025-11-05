/*import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class LoginAccountRecovery extends StatefulWidget {
  final String username;
  final UserFurnace? userFurnace;
  final bool fromNetworkManager;

  const LoginAccountRecovery(
      {Key? key,
      required this.username,
      this.fromNetworkManager = false,
      this.userFurnace})
      : super(key: key);

  @override
  State<LoginAccountRecovery> createState() => _LoginAccountRecoveryState();
}

class _LoginAccountRecoveryState extends State<LoginAccountRecovery> {
  //UserFurnace? _userFurnace;

  final _authBloc = AuthenticationBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _recoveryCode = TextEditingController();
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

    //_userFurnace = widget.userFurnace;

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
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
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

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(children: [
                      const Expanded(
                          child: ICText(
                        'Select one of the following options',
                        fontSize: 16,
                      ))
                    ])),
                const Padding(
                    padding: EdgeInsets.only(top: 30, left: 10, bottom: 10),
                    child: ICText('Option 1:')),
                const Padding(
                  padding: EdgeInsets.only(left: 2, right: 2),
                  child: GradientButton(
                      text: 'Request Help From Friends'),
                ),
                const Padding(
                    padding: EdgeInsets.only(top: 30, left: 10, bottom: 0),
                    child: ICText('Option 2:')),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 11, top: 0, bottom: 0, right: 49),
                  child: Row(children: <Widget>[
                Expanded(

                      child: FormattedText(
                          controller: _recoveryCode,
                          labelText: 'paste recovery code',
                          //maxLength: 25,
                          maxLines: 1),
                    )

                  ]),
                ),
                const Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: GradientButton(text: 'Use Recovery Key')),
              ]),
        ),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: const ICAppBar(title: 'Account Recovery'),
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
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ])),
        ));
  }
}

 */
