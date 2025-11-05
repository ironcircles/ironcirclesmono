import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:provider/provider.dart';

class SetCircleBackground extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final File image;
  final String buttonText;

  SetCircleBackground({
    Key? key,
    required this.userCircleCache,
    required this.userFurnace,
    required this.image,
    required this.buttonText,
  }) : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  _SetCircleBackgroundState createState() => _SetCircleBackgroundState();
}

class _SetCircleBackgroundState extends State<SetCircleBackground> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  late File _image;

  String? _furnace = '';
  String? _userCircleName = ' ';

  //String _ownershipModel = '';
  List<String?> _furnaceList = [];
  List<String?> _userCircleList = [];
  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  List<UserFurnace>? _userFurnaces;
  late List<UserCircleCache> _userCircles;
  List<String?> _filteredUserCircleList = [];

  bool checkedMatch = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    _image = widget.image;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _userFurnaceBloc.userfurnaces.listen((furnaces) {
      if (mounted) {
        _userFurnaces = furnaces;
        _userCircleBloc.sinkCache(_userFurnaces!);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen((refreshedUserCircleCaches) {
      if (mounted) {
        setState(() {
          _furnaceList = [];

          for (UserFurnace userFurnace in _userFurnaces!) {
            if (userFurnace.connected!) _furnaceList.add(userFurnace.alias);
          }

          _furnaceList
              .sort((a, b) => a!.toLowerCase().compareTo(b!.toLowerCase()));

          _furnace = _furnaceList[0];

          _userCircles = refreshedUserCircleCaches;

          _userCircleList = [];
          _userCircleList.add(' ');

          for (UserCircleCache userCircleCache in _userCircles) {
            if (userCircleCache.prefName!.length > 50)
              _userCircleList.add(userCircleCache.prefName!.substring(0, 49));
            else
              _userCircleList.add(userCircleCache.prefName);
          }

          _userCircleList
              .sort((a, b) => a!.toLowerCase().compareTo(b!.toLowerCase()));
          //_filteredUserCircleList = _userCircleList;

          _populateCirclesByFurnace(_furnace, true);
        });
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      debugPrint("error $err");
    }, cancelOnError: false);

    _filteredUserCircleList.add(' ');

    _userFurnaceBloc.request(globalState.user.id);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _populateCirclesByFurnace(String? furnace, bool loading) async {
    String? lastFurnace;
    String? lastCircle;

    if (loading) {
      lastFurnace = widget.userFurnace.alias;

      lastCircle = widget.userCircleCache.prefName;

      if (_furnaceList.contains(lastFurnace)) {
        _furnace = lastFurnace;
        furnace = lastFurnace;
        if (_filteredUserCircleList.contains(lastCircle)) {
          _userCircleName = lastCircle;
        }

        //checkedMatch = true;

      }
    }

    setState(() {
      if (furnace == 'all') {
        //_filteredUserCircleList = _userCircleList;
      } else {
        late UserFurnace userFurnace;

        for (UserFurnace testFurnace in _userFurnaces!) {
          if (testFurnace.alias == furnace) {
            userFurnace = testFurnace;
            break;
          }
        }

        _filteredUserCircleList = [];
        _filteredUserCircleList.add(' ');

        for (UserCircleCache userCircleCache in _userCircles) {
          if (userCircleCache.userFurnace ==
              userFurnace.pk) if (userCircleCache.prefName!.length > 50)
            _filteredUserCircleList
                .add(userCircleCache.prefName!.substring(0, 49));
          else
            _filteredUserCircleList.add(userCircleCache.prefName);
        }
        _filteredUserCircleList
            .sort((a, b) => a!.toLowerCase().compareTo(b!.toLowerCase()));
      }

      _userCircleName = ' ';

      if (loading) {
        if (_furnaceList.contains(lastFurnace)) {
          _furnace = lastFurnace;
          if (_filteredUserCircleList.contains(lastCircle)) {
            _userCircleName = lastCircle;
          }

          //checkedMatch = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: <
              Widget>[
            const Padding(
              padding: EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Text('Furnace filter:'),
                ),
              ]),
            ),
            _furnaceList.isEmpty
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 20,
                        child: Container(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: 'select a furnace',
                              hintStyle: TextStyle(
                                  color: globalState.theme.textFieldLabel),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: globalState.theme.textField),
                                //borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: globalState.theme.textField),
                                //borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            //isEmpty: _furnace == 'first match',
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                    canvasColor:
                                        globalState.theme.dropdownBackground),
                                child: DropdownButton<String>(
                                  value: _furnace,
                                  onChanged: (String? newValue) {
                                    _furnace = newValue;
                                    _populateCirclesByFurnace(newValue, false);
                                  },
                                  items: _furnaceList
                                      .map<DropdownMenuItem<String>>(
                                          (String? value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value!,
                                        style: TextStyle(
                                            color: globalState
                                                .theme.dropdownText),
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
            const Padding(
              padding: EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Text('Select a Circle'),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 25),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Container(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: 'select a circle',
                        hintStyle:
                            TextStyle(color: globalState.theme.textFieldLabel),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: globalState.theme.textField),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: globalState.theme.textField),
                        ),
                      ),
                      //isEmpty: _furnace == 'first match',
                      child: DropdownButtonHideUnderline(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              canvasColor:
                                  globalState.theme.dropdownBackground),
                          child: DropdownButton<String>(
                            value: _userCircleName,
                            onChanged: (String? newValue) {
                              setState(() {
                                _userCircleName = newValue;
                              });
                            },
                            items: _filteredUserCircleList
                                .map<DropdownMenuItem<String>>((String? value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Container(
                                  child: Text(
                                    value!,
                                    style: TextStyle(
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
            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.file(_image,
                        height: 270, width: 270, fit: BoxFit.cover),
                  ),
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 10, top: 0, bottom: 0),
                      child: IconButton(
                        icon: const Icon(Icons.crop),
                        onPressed: () => _cropImage(),
                      )),
                ])
          ]),
        ),
      ),
    );

    final makeBottom = Container(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: widget.buttonText, //'SET BACKGROUND',
                onPressed: () {
                  _setBackground();
                }),
          ),
        ]),
      ),
    );
    final topAppBar = AppBar(
      backgroundColor: globalState.theme.background,
      elevation: 0.1,
      actions: const <Widget>[],
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      title: const Text("Select Circle"),
      //actions: <Widget>[IconButton(icon: Icon(Icons.home), onPressed: _goHome)],
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            key: _scaffoldKey,
            appBar: topAppBar,
            //drawer: NavigationDrawer(),
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
                        padding: const EdgeInsets.all(0.0),
                        child: makeBottom,
                      ),
                    ],
                  ),
                  _showSpinner ? Center(child: spinkit) : Container(),
                ]))));
  }

  _setBackground() async {
    try {
      setState(() {
        _showSpinner = true;
      });

      late UserFurnace userFurnace;

      for (UserFurnace testFurnace in _userFurnaces!) {
        if (testFurnace.alias == _furnace) {
          userFurnace = testFurnace;
          break;
        }
      }

      late UserCircleCache userCircleCache;

      for (UserCircleCache possibleUserCircleCache in _userCircles) {
        if (possibleUserCircleCache.prefName == _userCircleName &&
            possibleUserCircleCache.userFurnace! == userFurnace.pk) {
          userCircleCache = possibleUserCircleCache;
          break;
        }
      }

      //userCircleCache.furnaceObject= userFurnace;  //hitchiker

      await _userCircleBloc.updateImage(userFurnace, userCircleCache, _image);

      Navigator.pop(context, userCircleCache);
    } catch (err) {
      debugPrint('SelectCircleBackground._setBackground: $err');
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);

      setState(() {
        _showSpinner = false;
      });
    }
  }

  Future<void> _cropImage() async {

    File? croppedFile = await ImageUtil.cropImage(context, _image);

    if (croppedFile != null) {
      setState(() {
        _image = croppedFile;
        //state = AppState.cropped;
      });
    }
  }
  //
  // Future<Null> _cropImage() async {
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: _image.path,
  //       aspectRatioPresets: Platform.isAndroid
  //           ? [
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio16x9
  //             ]
  //           : [
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio5x3,
  //               CropAspectRatioPreset.ratio5x4,
  //               CropAspectRatioPreset.ratio7x5,
  //               CropAspectRatioPreset.ratio16x9
  //             ],
  //       uiSettings: [
  //         AndroidUiSettings(
  //             toolbarTitle: 'Adjust image',
  //             backgroundColor: globalState.theme.background,
  //             activeControlsWidgetColor: Colors.blueGrey[600],
  //             toolbarColor: globalState.theme.background,
  //             statusBarColor: globalState.theme.background,
  //             toolbarWidgetColor: globalState.theme.menuIcons,
  //             initAspectRatio: CropAspectRatioPreset.original,
  //             lockAspectRatio: false),
  //         IOSUiSettings(
  //           title: 'Adjust image',
  //         )]
  //   );
  //   if (croppedFile != null) {
  //     setState(() {
  //       _image = File(croppedFile.path);
  //       //state = AppState.cropped;
  //     });
  //   }
  // }
}
