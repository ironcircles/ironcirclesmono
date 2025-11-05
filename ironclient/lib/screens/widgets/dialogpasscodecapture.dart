/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DialogPasscodeCapture {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static capture(
    BuildContext context,
    Function success,
  ) async {
    TextEditingController _passcode = TextEditingController();
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Text(
              "Enter passcode",
              style: TextStyle(color: globalState.theme.bottomIcon),
            ),
          ),
          contentPadding: const EdgeInsets.all(10.0),
          content: CapturePasscode(scaffoldKey, _passcode),
          actions: <Widget>[
            TextButton(
                child: Text('CANCEL',
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  Navigator.pop(context);
                }),
            TextButton(
                child: Text(
                  'CONTINUE',
                  style: TextStyle(color: globalState.theme.buttonIcon),
                ),
                onPressed: () {
                  _continue(context, _passcode.text, success);
                  //if (_validPassword) Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }

  static void _continue(
      BuildContext context, String _passcode, Function callback) {
    String plainPasscode = _passcode.replaceAll('-', '');
    callback(plainPasscode);
    Navigator.of(context).pop();
  }

/*
  static void _validatePassphrase(BuildContext context, String passphrase1,
      String passphrase2, Function callback) {
    try {
      if (passphrase1.isEmpty) {
        FormattedSnackBar.showSnackbarWithContext(context, 'passphrase required', "", 2);
      } else if (passphrase1.length < 10) {
        FormattedSnackBar.showSnackbarWithContext(context, 'passphrase must be at least 10 characters', "", 2);
      } else if (passphrase1 != passphrase2) {
        FormattedSnackBar.showSnackbarWithContext(context, 'passphrase do not match', "", 2);
      } else {
        callback(passphrase1);
        Navigator.of(context).pop();
      }
    } catch (err, trace) { LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }
  }*/
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class CapturePasscode extends StatefulWidget {
  final scaffoldKey;
  final TextEditingController controller;

  const CapturePasscode(
    this.scaffoldKey,
    this.controller,
  );

  _CapturePasscode createState() => _CapturePasscode();
}

class _CapturePasscode extends State<CapturePasscode> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200,
        height: 255,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //Spacer(),
                Row(children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 0),
                  ),
                  Text("Enter your 32 character passcode"),
                ]),

                const Padding(padding: EdgeInsets.only(bottom: 5)),
                /*Row(children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                  ),
                  Expanded(
                      child: Text(
                          'This passcode will be needed w you  access IronCircles from a different device'))
                ]),*/
                const Padding(padding: EdgeInsets.only(bottom: 20)),

                const Padding(padding: EdgeInsets.only(bottom: 20)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 5, right: 5, bottom: 0),
                  ),
                  Expanded(
                    child: TextFormField(
                      autofocus: true,
                      controller: widget.controller,
                      //obscureText: !_showPassword,
                      decoration: const InputDecoration(
                          //labelText: 'enter password',
                          hintText: 'paste passcode'),
                    ),
                  ),
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 10)),
              ]),
        ));
  }
}

 */
