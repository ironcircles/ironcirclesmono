/*import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/encryption/externalkeys.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';

class ExportKeys extends StatefulWidget {
  final UserFurnace userFurnace;
  ExportKeys(this.userFurnace);

  _ExportKeysState createState() => _ExportKeysState();
}

class _ExportKeysState extends State<ExportKeys> {
  bool _copied = false;
  String _passcode = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  UserBloc _userBloc = UserBloc();

  @override
  void initState() {
    _userBloc.keysExported.listen((success) {
      if (success!) {
        FormattedSnackBar.showSnackbarWithContext(context, "keychains exported", "", 2);

        Navigator.of(context).pop();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      debugPrint("ExportKeys.initState.keysExported: $err");
    }, cancelOnError: false);

    super.initState();
    _generatePasscode();
  }

  void _continue() async {
    try {
      if (_copied == true) {
        //String passcode = _passcode.replaceAll(
        //    '-', ''); //remove the hyphens before encrypting the file

        File file = await ExternalKeys.saveToFile(
            globalState.user.id!, globalState.user.username!, _passcode, true);

        if (Platform.isIOS) {
          await Share.shareFiles([file.path],
              text: 'Store this file somewhere safe');
        } else {
          await Share.shareFiles([file.path],
              text: 'Store this file somewhere safe');
        }

        _userBloc.updateKeysExported(widget.userFurnace);

        try {
          file.delete();
        } catch (err) {
          debugPrint('ExternalKeys.saveToFile: $err');
        }
      } else {
        FormattedSnackBar.showSnackbarWithContext(context, 'passcode not copied to clipboard', "", 2);
      }
    } catch (err, trace) {
      if (!err.toString().contains('backup is up to date'))
        LogBloc.insertError(err, trace);
      debugPrint("KeychainBackupService.backup " + err.toString());

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2);
    }
  }

  void _generatePasscode() async {
    String retValue = "";

    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      var passcode = await cipher.newSecretKey();

      retValue = base64Encode(await passcode.extractBytes());

      setState(() {
        debugPrint(retValue.length.toString());
        _passcode = retValue;
      });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('DialogPasscode.generatePasscode: $err');
    }

    /*retValue = retValue.replaceAllMapped(
      RegExp(r".{4}"), (match) => "${match.group(0)}-");

    retValue = retValue.substring(0, retValue.length - 1);*/
  }

  _copyToClipBoard() async {
    await Clipboard.setData(
        ClipboardData(text: _passcode)); //copy with the hypens.  It's prettier
    FormattedSnackBar.showSnackbarWithContext(context, 'copied to clipboard', "", 2);

    setState(() {
      _copied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final makeBottom = Container(
      height: 65.0,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
        child: Column(children: <Widget>[
          Expanded(
              child: GradientButton(
            color1: _copied ? null : globalState.theme.buttonDisabled,
            color2: _copied ? null : globalState.theme.buttonDisabled,
            text: 'EXPORT',
            onPressed: () {
              _continue();
            },
          )),
        ]),
      ),
    );

    final makeBody = Container(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //Spacer(),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 0),
                  ),
                  const Text("Step 1:", style: TextStyle(fontSize: 22)),
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 5)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                  ),
                  const Expanded(
                    child: Text(
                        "Copy this passcode to a safe place, such as a password vault.",
                        style: TextStyle(fontSize: 18)),
                  )
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 20)),

                Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                      ),
                      Expanded(
                          child: Text(
                        _passcode,
                        style: TextStyle(
                            color: globalState.theme.labelHighlighted,
                            fontSize: 12),
                      ))
                    ]),
                const Padding(padding: EdgeInsets.only(bottom: 10)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(right: 3.85),
                          child: Container(
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: globalState.theme.buttonIcon,
                                shape: const CircleBorder(),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: globalState.theme.listIconForeground,
                                ),
                                color: globalState.theme.buttonText,
                                onPressed: () {
                                  _generatePasscode();
                                },
                              ),
                            ),
                          )),
                      Padding(
                          padding: const EdgeInsets.only(right: 3.85),
                          child: Container(
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: globalState.theme.buttonIcon,
                                shape: const CircleBorder(),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: globalState.theme.listIconForeground,
                                ),
                                color: globalState.theme.buttonText,
                                onPressed: () {
                                  _copyToClipBoard();
                                },
                              ),
                            ),
                          )),
                    ]),
                const Padding(padding: EdgeInsets.only(bottom: 20)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                  ),
                  const Text(
                    "Step 2:",
                    style: TextStyle(fontSize: 22),
                  ),
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 5)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                  ),
                  const Expanded(
                    child: Text(
                        "Press the export button and save the key file somewhere secure.",
                        style: TextStyle(fontSize: 18)),
                  )
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 20)),
                makeBottom,
              ]),
        )));

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: AppBar(
        actions: <Widget>[],
        iconTheme: IconThemeData(
          color: globalState.theme.menuIcons, //change your color here
        ),
        backgroundColor: globalState.theme.background,
        title: Text('Export Keychains',
            style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(child: makeBody),

          /* Container(
            //  color: Colors.white,
            padding: EdgeInsets.all(0.0),
            child: makeBottom,
          ),*/
        ],
      ),
    );
  }
}

 */
