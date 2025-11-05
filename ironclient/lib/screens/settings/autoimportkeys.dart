/*
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/settings/importkeys.dart';
import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';

import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';

class AutoImportKeys extends StatefulWidget {
  final UserFurnace userFurnace;
  final User user;
  AutoImportKeys(this.userFurnace, this.user);

  _AutoImportKeysState createState() => _AutoImportKeysState();
}

class _AutoImportKeysState extends State<AutoImportKeys> {
  //bool _copied = false;
  // String _passcode = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();
  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;

  TextEditingController _passcodeController = TextEditingController();
  bool _showSpinner = false;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _userCircleBloc.refreshedUserCircles.listen((refreshedUserCircleCaches) {
      if (mounted) {
        importingData!.dismiss();
        importingData = null;

        Navigator.of(context).pop(true);
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _keychainBackupBloc.restoreSuccess.listen((show) {
      if (mounted) {
        setState(() {
          if (show) {
            if (progressDialog != null) {
              progressDialog!.dismiss();
              progressDialog = null;
            }

            progressDialog = ProgressDialog(context,
                message: const Text("Importing chat history"),
                title: const Text("Please wait..."));
            progressDialog!.show();
          } else {
            progressDialog!.dismiss();
            progressDialog = null;

            //Navigator.of(context).pop(true);

            importingData = ProgressDialog(context,
                message: const Text("Decrypting data"),
                title: const Text("Please wait..."));
            importingData!.show();

            //import data
            _userCircleBloc.fetchUserCirclesSync(true);
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(context, err, "", 2);
      if (progressDialog != null) {
        progressDialog!.dismiss();
        progressDialog = null;
      }
    }, cancelOnError: false);

    super.initState();
  }

  void _importFromFile1() async {
    bool success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImportKeys(userFurnace: widget.userFurnace),
        ));

    if (success) {
      //ratchet all the receiver keys to make sure this device has matching keys for messages
      await ForwardSecrecy.ratchetReceiverKeys(
          widget.user, widget.userFurnace, widget.user.userCircles);

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: widget.user,
      );
    } else
      FormattedSnackBar.showSnackbarWithContext(
          context, 'failed to import chat history', "", 2);
  }

  void _import() async {
    try {
      debugPrint(_passcodeController.text.length.toString());

      if (_passcodeController.text.isEmpty ||
          _passcodeController.text.length != 44) {
        FormattedSnackBar.showSnackbarWithContext(context, 'invalid passcode', "", 2);
      } else {
        _keychainBackupBloc.restore(
            widget.userFurnace, widget.user, _passcodeController.text);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ImportKeys._import: $err');
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);

      setState(() {
        _showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Padding(padding: EdgeInsets.only(bottom: 25)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                  ),
                  const Expanded(
                    child: Text("Enter keychain passcode",
                        style: TextStyle(fontSize: 18)),
                  )
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormattedText(
                        fontSize: 12,
                        labelText: 'passcode',
                        controller: _passcodeController,
                        maxLines: 1,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return 'passcode is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ]),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 20)),
                SizedBox(
                  height: 65.0,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 0, bottom: 0),
                    child: Column(children: <Widget>[
                      Expanded(
                          child: GradientButton(
                        text: 'IMPORT FROM AUTOBACKUP',
                        onPressed: () {
                          _import();
                        },
                      )),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 30, bottom: 30),
                  child: Row(children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: globalState.theme.textFieldLabel,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                SizedBox(
                  height: 65.0,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 0, bottom: 0),
                    child: Column(children: <Widget>[
                      Expanded(
                          child: GradientButton(
                        text: 'IMPORT FROM FILE',
                        onPressed: () {
                          _importFromFile();
                        },
                      )),
                    ]),
                  ),
                ),
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
        title: Text('Import Keychains',
            style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: makeBody),
            ],
          ),

          /* Container(
            //  color: Colors.white,
            padding: EdgeInsets.all(0.0),
            child: makeBottom,
          ),*/
          if (_showSpinner) Center(child: spinkit),
        ],
      ),
    );
  }
}

 */
