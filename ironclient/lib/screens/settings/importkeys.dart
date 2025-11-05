/*import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/externalkeys.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:provider/provider.dart';

import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';

class ImportKeys extends StatefulWidget {
  final UserFurnace userFurnace;
  ImportKeys({required this.userFurnace});


  @override
  State<StatefulWidget> createState() {
    return _ImportKeysState();
  }

}

class _ImportKeysState extends State<ImportKeys> {
  //bool _copied = false;
  // String _passcode = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  //UserBloc _userBloc = UserBloc();
  File? keyFile;
  //TextEditingController _passcodeController = TextEditingController();
  bool _showSpinner = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
  }

  void _import() async {
    try {
      //debugPrint(_passcodeController.text.length);

      String backupKey = await SecureStorageService.readKey(
          KeyType.USER_KEYCHAIN_BACKUP + widget.userFurnace.userid!);

      if (keyFile == null) {
        FormattedSnackBar.showSnackbarWithContext(context, 'file not selected', "", 2);
        /*} else if (_passcodeController.text.isEmpty ||
          _passcodeController.text.length != 44) {
        FormattedSnackBar.showSnackbarWithContext(context, 'invalid passcode', "", 2);
      */
      } else {
        setState(() {
          _showSpinner = true;
        });
        /*String passcode = _passcode.replaceAll(
          '-', ''); //remove the hyphens before encrypting the file*/

        await ExternalKeys.putFile(
            widget.userFurnace.userid!, keyFile!, backupKey);

        GlobalEventBloc _globalEventBloc =
            Provider.of<GlobalEventBloc>(context, listen: false);
        await CircleObjectBloc(globalEventBloc: _globalEventBloc)
            .retryDecryption();

        Navigator.of(context).pop(true);
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

  void _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    setState(() {
      if (result != null) {
        keyFile = File(result.files.single.path!);
      } else {
        keyFile = null;
      }
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
            color1: keyFile != null ? null : globalState.theme.buttonDisabled,
            color2: keyFile != null ? null : globalState.theme.buttonDisabled,
            text: 'IMPORT',
            onPressed: () {
              _import();
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
                const Padding(padding: EdgeInsets.only(bottom: 5)),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                  ),
                  const Expanded(
                    child: Text("Select file to import",
                        style: TextStyle(fontSize: 18)),
                  )
                ]),
                const Padding(padding: EdgeInsets.only(bottom: 20)),
                Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      keyFile == null
                          ? Container()
                          : Text(
                              FileSystemService.getFilename(keyFile!.path),
                              style: TextStyle(
                                  color: globalState.theme.buttonIcon),
                            ),
                    ]),
                const Padding(padding: EdgeInsets.only(bottom: 10)),
                Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: globalState.theme.buttonIcon,
                            shape: const CircleBorder(),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.file_copy_rounded,
                              color: globalState.theme.listIconForeground,
                            ),
                            color: globalState.theme.buttonText,
                            onPressed: () {
                              _selectFile();
                            },
                          ),
                        ),
                      )
                    ]),
                const Padding(padding: EdgeInsets.only(bottom: 10)),
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
