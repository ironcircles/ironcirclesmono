/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/utils/permissions.dart';

import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class NewCircle extends StatefulWidget {
  // final Flutterbug flutterbug;

  // FlutterManager({Key key, this.title}) : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  NewCircleState createState() => NewCircleState();
}

class NewCircleState extends State<NewCircle> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  TextEditingController _circleName = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _password2 = TextEditingController();
  bool _hidden = false;
  //String? _furnace = '';
  List<UserFurnace>? _userFurnaces;
  String _ownershipModel = 'members';
  //List<String?> _furnaceList = [];
  //late DropDownPair _dropDownPair;
  List<DropDownPair> _furnaceList = [];
  //List<String> _ownershipModelList = <String>['members', 'owner'];
  CircleBloc _circleBloc = CircleBloc();
  UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //bool _showPassword = false;

  late DropDownPair _selected;

  File? _image;
  bool _clicked = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    _selected = DropDownPair.blank();

    _userFurnaceBloc.userfurnaces.listen((furnaces) {
      if (mounted) {
        _userFurnaces = furnaces;

        for (UserFurnace userFurnace in _userFurnaces!) {
          if (userFurnace.connected!) {
            _furnaceList.add(DropDownPair(
                id: userFurnace.pk!.toString(),
                value: StringHelper.truncate(userFurnace.alias!, 18) +
                    ' (${StringHelper.truncate(userFurnace.username!, 18)})'));
          }
        }

        setState(() {
          _selected = _furnaceList[0];
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _circleBloc.createdResponse.listen((success) {
      if (mounted) {
        if (success) {
          FormattedSnackBar.showSnackbarWithContext(
              context, "successfully created circle", "", 2);

          Navigator.pop(context);
        } else {
          FormattedSnackBar.showSnackbarWithContext(
              context, "error creating circle", "", 2);

          setState(() {
            _showSpinner = false;
            _clicked = false;
          });
        }
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      setState(() {
        _showSpinner = false;
        _clicked = false;
      });

      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.request(globalState.user.id, false);
  }

  @override
  void dispose() {
    _circleName.dispose();
    _password.dispose();
    _password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: <
              Widget>[
            Padding(
              padding:
                  const EdgeInsets.only(top: 4, bottom: 0, left: 10, right: 3),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: FormattedText(
                    labelText: 'enter circle name',
                    maxLength: 25,
                    controller: _circleName,
                    maxLines: 1,
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'name is required';
                      }
                      return null;
                    },
                  ),
                )
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Container(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: 'select a network',
                        hintStyle:
                            TextStyle(color: globalState.theme.textFieldLabel),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: globalState.theme.textField),
                        ),
                        /*enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: globalState.theme.textField),
                        ),

                         */
                      ),
                      //isEmpty: _furnace == 'first match',
                      child: DropdownButtonHideUnderline(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              canvasColor:
                                  globalState.theme.dropdownBackground),
                          child: DropdownButton<DropDownPair>(
                            value: _selected,
                            onChanged: (DropDownPair? newValue) {
                              setState(() {
                                _selected = newValue!;
                              });
                            },
                            items: _furnaceList
                                .map<DropdownMenuItem<DropDownPair>>(
                                    (DropDownPair value) {
                              return DropdownMenuItem<DropDownPair>(
                                value: value,
                                child: Container(
                                  padding: EdgeInsets.only(left: 16),
                                  child: Text(
                                    value.value,
                                    textScaleFactor:
                                        globalState.dropdownScaleFactor,
                                    style: ICTextStyle.getDropdownStyle(
                                        color: globalState.theme.dropdownText),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            /*Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormField(
                        builder: (FormFieldState<String> state) {
                          return FormattedDropdown(
                              hintText: 'select ownership model',
                              list: _ownershipModelList,
                              selected: _ownershipModel,
                              errorText:
                                  state.hasError ? state.errorText : null,
                              onChanged: (String value) {
                                setState(() {
                                  _ownershipModel = value;
                                  if (value.isEmpty) value = null;
                                  state.didChange(value);
                                });
                              });
                        },
                        validator: (value) {
                          return _ownershipModel == null
                              ? 'select an ownership model'
                              : null;
                        },
                      ),
                    ),
                  ]),
                ),*/
            /* Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 15,
                      child: Container(
                        //color: globalState.theme.textField,
                        child: SwitchListTile(
                          title: const Text(
                            'Guarded',
                            style: TextStyle(
                                fontSize: 18,
                                color: globalState.theme.textFieldLabel),
                          ),
                          value: _hidden,
                          onChanged: (bool value) {
                            setState(() {
                              _hidden = value;
                            });
                          },
                          //secondary: const Icon(Icons.remove_red_eye),
                        ),
                      ),
                    ),
                    Spacer(flex: 15),
                  ]),
                ),*/
            /*_hidden
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                              flex: 20,
                              child: FormattedText(
                                labelText: 'password',
                                controller: _password,
                                obscureText: !_showPassword,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'field is required';
                                  }
                                },
                              )),
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
                                          color:
                                              globalState.theme.buttonDisabled),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = true;
                                        });
                                      })),
                        ]),
                      )
                    : Container(),
                _hidden
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                              flex: 20,
                              child: FormattedText(
                                controller: _password2,
                                labelText: 'reenter password',
                                obscureText: !_showPassword,
                                validator: (value) {
                                  if (value != _password.text) {
                                    return 'passphrase does not match';
                                  }
                                },
                              )),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: IconButton(
                              onPressed: _doNothing,
                              icon: Icon(Icons.visibility,
                                  color: globalState.theme.background),
                            ),

                            /* Image.asset(
                        'assets/avatar.jpg',
                      ),*/
                          ),
                        ]))
                    : Container(),*/
            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 0),
                        child: InkWell(
                          onTap: _selectImage,
                          child: ClipOval(
                            child: _image == null
                                ? Image.asset(
                                    'assets/images/iron.jpg',
                                    height: 270,
                                    width: 270,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(_image!,
                                    height: 270, width: 270, fit: BoxFit.cover),
                          ),
                        )),
                    InkWell(
                        onTap: _selectImage,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 10, right: 10),
                          child: Text(
                            'SELECT BACKGROUND',
                            style: TextStyle(
                                fontSize: 14,
                                color: globalState.theme.buttonIcon),
                            textScaleFactor: globalState.labelScaleFactor,
                          ),
                        )),
                  ]),
                  _image != null
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: 10, top: 0, bottom: 0),
                          child: IconButton(
                            icon: Icon(Icons.crop),
                            onPressed: () => _cropImage(),
                          ))
                      : Container(),
                ]),
          ]),
        ),
      ),
    );

    final makeBottom = Container(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: 'CREATE',
                onPressed: () {
                  _createCircle();
                }),
          ),
        ]),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          //drawer: NavigationDrawer(),
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
                    Container(
                      //  color: Colors.white,
                      padding: EdgeInsets.all(0.0),
                      child: makeBottom,
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            ),
          ),
        ));
  }

  _createCircle() {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _showSpinner = true;
        });
        if (_clicked == false) {
          _clicked = true;

          if (_circleName.text.length > 25) {
            DialogNotice.showNotice(
              context,
              'Name is too long',
              "circle name must be 25 chars or less",
              null,
              null,
              null,
            );

            setState(() {
              _showSpinner = false;
              _clicked = false;
            });
            return;
          }

          UserFurnace userFurnace = _userFurnaces!
              .firstWhere((element) => element.pk.toString() == _selected.id);

          Circle newCircle =
              Circle(name: _circleName.text, ownershipModel: _ownershipModel);
          UserCircle userCircle = UserCircle(
              hidden: _hidden,
              hiddenPassphrase: _password.text,
              ratchetKeys: []);

          _circleBloc.create(userFurnace, newCircle, userCircle, _image);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('NewCircle._createCircle: $err');
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      _clicked = false;
    }
  }

  _selectImage() async {
    try {
      ImagePicker imagePicker = ImagePicker();

      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (imageFile != null) // debugPrint (imageFile.path);
        setState(() {
          _image = File(imageFile.path);
        });
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('NewCircle.selectImage: $err');
      }
    }
  }

  /*_goHome() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),
        (Route<dynamic> route) => false);
  }

   */

  Future<Null> _cropImage() async {
    if (_image == null) return;

    ImageCropper imageCropper = ImageCropper();

    File? croppedFile = await imageCropper.cropImage(
        sourcePath: _image!.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Adjust image',
            backgroundColor: globalState.theme.background,
            activeControlsWidgetColor: Colors.blueGrey[600],
            toolbarColor: globalState.theme.background,
            statusBarColor: globalState.theme.background,
            toolbarWidgetColor: globalState.theme.menuIcons,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Adjust image',
        ));
    if (croppedFile != null) {
      setState(() {
        _image = croppedFile;
        //state = AppState.cropped;
      });
    }
  }
}*/
