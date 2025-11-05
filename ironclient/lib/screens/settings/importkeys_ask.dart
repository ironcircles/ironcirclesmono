import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class ImportKeysAsk extends StatefulWidget {
  const ImportKeysAsk();

  _ImportKeysAskState createState() => _ImportKeysAskState();
}

class _ImportKeysAskState extends State<ImportKeysAsk> {
  //bool _copied = false;
  // String _passcode = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  //UserBloc _userBloc = UserBloc();
  File? keyFile;
  //TextEditingController _passcodeController = TextEditingController();
  //bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: AppBar(
          actions: const <Widget>[],
          iconTheme: IconThemeData(
            color: globalState.theme.menuIcons, //change your color here
          ),
          backgroundColor: globalState.theme.background,
          title: Text('Import encryption keys?',
              style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
        ),
        body: Column(mainAxisSize: MainAxisSize.min,
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 20, bottom: 0),
                child: Column(children: <Widget>[
                  const Text(
                    "No encryption keys found on this device.  Would you like to import or generate keys?",
                    style: TextStyle(fontSize: 16),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 25)),
                  Flexible(
                      fit: FlexFit.loose,
                      flex: 0,
                      child: GradientButton(
                        text: 'GENERATE KEYS',
                        onPressed: () {
                          //ask

                          Navigator.of(context).pop(false);
                        },
                      )),
                  const Padding(padding: EdgeInsets.only(top: 25)),
                  Flexible(
                      fit: FlexFit.loose,
                      flex: 0,
                      child: GradientButton(
                        text: 'IMPORT KEYS',
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      )),
                ]),
              )
            ]));
  }
}
