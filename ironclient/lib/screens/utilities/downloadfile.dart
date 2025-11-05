import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:path/path.dart' as p;

class DownloadFile extends StatefulWidget {
  final File file;
  final String fileName;
  final String defaultPath;
  final String extension;

  const DownloadFile({
    Key? key,
    required this.file,
    required this.fileName,
    required this.defaultPath,
    required this.extension,
  }) : super(key: key);

  @override
  _DownloadState createState() => _DownloadState();
}

class _DownloadState extends State<DownloadFile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _fileName = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final spinkit = Center(
      child: SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  ));

  bool _showSpinner = false;

  @override
  void initState() {
    _location.text = globalState.downloadDirectory;

    _fileName.text = widget.fileName;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topAppBar = AppBar(
      backgroundColor: globalState.theme.appBar,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      elevation: 0.1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      //backgroundColor: Colors.black,
      title: Text('Save file locally',
          style: TextStyle(color: globalState.theme.textTitle)),
    );

    final submit = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: 'SAVE',
                onPressed: () {
                  _save();
                  //_connectToExisting();
                }),
          ),
        ]),
      ),
    );

    final makeBody = Container(
        // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
        padding: const EdgeInsets.only(left: 8, right: 10, top: 0, bottom: 10),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width - 75,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 4, bottom: 4, right: 10),
                              child: ExpandingText(
                                height: 75,
                                readOnly: true,
                                labelText: 'location',
                                controller: _location,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'field is required';
                                  }
                                  return null;
                                },
                              ),
                            )),
                        IconButton(
                            onPressed: _selectFolder,
                            icon: const Icon(Icons.more_horiz)),

                        // Text(globalState.downloadDirectory, style: TextStyle(color: globalState.theme.),),
                      ],
                    ),
                    Padding(
                        padding:
                            const EdgeInsets.only(top: 4, bottom: 4, right: 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 75,
                                child: ExpandingText(
                                  height: 50,
                                  //readOnly: true,
                                  labelText: 'filename',
                                  controller: _fileName,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'field is required';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 0, bottom: 6, left: 5),
                                  child: Text(widget.extension,
                                      style: const TextStyle(fontSize: 16)))
                            ]))
                  ])),
        ));

    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: topAppBar,
          body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: true,
              child: Stack(children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child: makeBody),
                      submit,
                    ]),
                _showSpinner ? spinkit : Container()
              ])),
        ));
  }

  _selectFolder() async {
    String? result = await FilePicker.platform.getDirectoryPath();

    //FilePicker.platform.

    if (result != null) {
      //SecureStorageService.writeKey(KeyType.DOWNLOAD_DIRECTORY, result);
      globalState.downloadDirectory = result;
      setState(() {
        _location.text = result;
      });

      /*
      if (circleObject.type == CircleObjectType.CIRCLEIMAGE){

        File file = File(ImageCacheService.returnFullImagePath(widget.userCircleCache.circlePath!, circleObject.seed!));

        //FormattedSnackBar.showSnackbarWithContext(context, "copying file", "", 1);

        await file.copy(p.join(result, 'test.jpg'));

        //FormattedSnackBar.showSnackbarWithContext(context, "copy complete", "", 1);

      }

       */

    }
  }

  _save() async {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _showSpinner = true;
        });

        await widget.file.copy(
            p.join(_location.text, '${_fileName.text}.${widget.extension}'));
      }

      setState(() {
        _showSpinner = false;
      });

      Navigator.pop(context, true);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);

      debugPrint('Download._save: $err');
    }
  }
}
