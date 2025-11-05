import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/cache_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/circles/circle_hide.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogchoosebackground.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:ironcirclesapp/utils/permissions.dart';
import 'package:provider/provider.dart';

class PersonalCircleSettings extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Function update;
  final Circle circle;
  final FirebaseBloc firebaseBloc;
  final List<UserFurnace> userFurnaces;

  const PersonalCircleSettings(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.userFurnaces,
      required this.update,
      required this.circle,
      required this.firebaseBloc})
      : super(key: key);

  @override
  PersonalCircleSettingsState createState() => PersonalCircleSettingsState();
}

class PersonalCircleSettingsState extends State<PersonalCircleSettings> {
  late UserCircleCache _userCircleCache;
  late CircleObjectBloc _circleObjectBloc;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final _prefName = TextEditingController();
  //final _password = TextEditingController();
  //final _password2 = TextEditingController();

  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  //CircleBloc _circleBloc = CircleBloc();
  UserCircle _userCircle = UserCircle(ratchetKeys: []);

  //bool? _hidden = false;
  //bool _showPassword = false;
  String? _origPrefName;
  File? _image;
  bool _guarded = false;
  bool _muted = false;
  bool _hidden = false;
  List<int> _pin = [];

  bool changed = false;
  late String _type;

  Color? _pickerColor;
  Color? _currentColor;
  bool showSpinner = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    widget.circle.type == CircleType.VAULT
        ? _type = 'Vault'
        : widget.circle.dm
            ? _type = 'DM'
            : _type = 'Circle';

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);

    _userCircleCache = widget.userCircleCache;

    _currentColor = _userCircleCache.backgroundColor;

    _prefName.text =
        _userCircleCache.prefName == null ? '' : _userCircleCache.prefName!;
    //_userCircleBloc = BlocProvider.of<UserCircleBloc>(context);

    //Listen the image loaded
    _userCircleBloc.imageLoaded.listen((refreshed) {
      if (mounted) {
        setState(() {
          // userCircleCache = refreshed;
          //_origPrefName =
        });
      }
    }, onError: (err) {
      debugPrint("UserCircleWidget.initState: $err");
    }, cancelOnError: false);

    _userCircleBloc.userCircle.listen((refreshedUserCircle) {
      if (mounted) {
        setState(() {
          if (refreshedUserCircle != null) {
            _userCircle = refreshedUserCircle;
            _userCircleCache.prefName = refreshedUserCircle.prefName;
            _userCircleCache.guarded = refreshedUserCircle.guarded;
            _userCircleCache.hidden = refreshedUserCircle.hidden;

            if (_userCircle.guarded != null) _guarded = _userCircle.guarded!;
            if (_userCircle.hidden != null) _hidden = _userCircle.hidden!;

            _userCircleCache.muted = refreshedUserCircle.muted;
            _muted = refreshedUserCircle.muted;

            _userCircle.prefName ??= '';
            _prefName.text = _userCircle.prefName!;
            _origPrefName = _userCircle.prefName;
          }
        });
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');

      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.updatedImage.listen((userCircleCache) {
      if (mounted) {
        ///refresh the file
        _hasBackground(override: true);
        setState(() {
          showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");

      setState(() {
        showSpinner = false;
      });
    }, cancelOnError: false);

    _userCircleBloc.updateResponse.listen((userCircleCache) {
      if (mounted) {
        setState(() {
          _userCircleCache.prefName = userCircleCache!.prefName;
          _userCircleCache.guarded = userCircleCache.guarded;
          _userCircleCache.muted = userCircleCache.muted;
          _userCircleCache.hidden = userCircleCache.hidden;

          _userCircleCache.background = userCircleCache.background;
          //_hidden = userCircleCache.hidden;
          //_prefName.text = userCircleCache.prefName;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.leaveCircleResponse.listen((response) {
      if (mounted) {
        if (widget.circle.type == CircleType.VAULT)
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.vaultDeleted, "", 1, false);
        else
          FormattedSnackBar.showSnackbarWithContext(context,
              "${AppLocalizations.of(context)!.left} $_type", "", 1, false);
        if (response!) _goHome();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.fetchUserCircle(_userCircleCache);

    if (_userCircle.guarded != null) _guarded = _userCircleCache.guarded!;
    if (_userCircle.hidden != null) _hidden = _userCircleCache.hidden!;
    _origPrefName =
        _userCircleCache.prefName == null ? '' : _userCircleCache.prefName!;
    _prefName.text = _origPrefName!;
    _muted = _userCircleCache.muted;

    super.initState();
  }

  _goHome() async {
    // await Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(builder: (context) => const Home()),
    //     (Route<dynamic> route) => false);
    _globalEventBloc.broadcastPopToHomeOpenTab(0);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final image = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(children: [
                InkWell(
                    onTap: () async {
                      File? cropped =
                          await ImageUtil.cropImage(context, _image);
                      if (cropped != null) {
                        setState(() {
                          _image = cropped;
                        });
                      }
                    },
                    child: Container(
                        width: ScreenSizes.getMaxImageWidth(width) -
                            ICPadding.GENERATE_BUTTONS,
                        height: ScreenSizes.getMaxImageWidth(width) -
                            ICPadding.GENERATE_BUTTONS,
                        constraints: BoxConstraints(
                            maxHeight: ScreenSizes.getMaxImageWidth(width) -
                                ICPadding.GENERATE_BUTTONS,
                            maxWidth: ScreenSizes.getMaxImageWidth(width) -
                                ICPadding.GENERATE_BUTTONS),
                        child: ClipOval(
                          child: InkWell(
                            onTap: () => _backgroundChoice(
                                context, _backgroundTypeCallback),
                            child: ClipOval(
                                child: _hasBackground()
                                    ? _image != null
                                        ? Image.file(_image!, fit: BoxFit.cover)
                                        : Image.asset(
                                            'assets/images/black.jpg',
                                            fit: BoxFit.cover,
                                          )
                                    : _pickerColor != null ||
                                            _currentColor != null
                                        ? Container(
                                            color:
                                                _pickerColor ?? _currentColor,
                                          )
                                        : widget.userCircleCache.cachedCircle!
                                                    .type ==
                                                CircleType.VAULT
                                            ? Image.asset(
                                                'assets/images/vault.jpg',
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                'assets/images/iron.jpg',
                                                fit: BoxFit.cover,
                                              )),
                          ),
                        ))),
              ]),
              const Padding(
                padding: EdgeInsets.only(
                  right: 5,
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.generateImage,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: _generate,
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 10),
                ),
                Row(children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.selectFromDevice,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      File? image = await ImageUtil.selectImage(context);

                      if (image != null) {
                        setState(() {
                          _pickerColor = null;
                          _currentColor = null;
                          _image = image;
                        });

                        _setImage();
                      }
                    },
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 10),
                ),
                Row(children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!.selectAColor,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      _pickColor();
                    },
                  ),
                ]),
              ])
            ]));

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 20),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: WrapperWidget(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(left: 0, right: 0),
                        child: Column(children: [
                          widget.circle.dm
                              ? Container()
                              : Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, bottom: 4),
                                  child: Row(children: <Widget>[
                                    Expanded(
                                      child: Focus(
                                          onFocusChange: (hasFocus) {
                                            if (!hasFocus) {
                                              _prefNameChanged();
                                            }
                                          },
                                          child: FormattedText(
                                            maxLength: 25,
                                            onChanged: _onChanged,
                                            controller: _prefName,
                                            labelText: widget.circle.type ==
                                                    CircleType.VAULT
                                                ? AppLocalizations.of(context)!
                                                    .vaultName
                                                : AppLocalizations.of(context)!
                                                    .displayName,
                                            validator: (value) {
                                              if (value.isEmpty) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .errorFieldRequired;
                                              }

                                              return null;
                                            },
                                          )
                                          // controller: _username,

                                          ),
                                    )
                                  ]),
                                ),
                          widget.circle.type != CircleType.VAULT
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(top: 0, bottom: 0),
                                  child: Row(children: <Widget>[
                                    Expanded(
                                        //flex: 12,
                                        child: SwitchListTile(
                                      inactiveThumbColor:
                                          globalState.theme.inactiveThumbColor,
                                      inactiveTrackColor:
                                          globalState.theme.inactiveTrackColor,
                                      trackOutlineColor:
                                          MaterialStateProperty.resolveWith(
                                              globalState.getSwitchColor),
                                      title: Text(
                                        '${AppLocalizations.of(context)!.mute} $_type',
                                        textScaler: TextScaler.linear(
                                            globalState.labelScaleFactor),
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: globalState
                                                .theme.textFieldText),
                                      ),
                                      value: _muted,
                                      activeColor: globalState.theme.button,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _muted = value;
                                          _userCircle.muted = value;
                                          _userCircleBloc.updateMuted(
                                              widget.userFurnace,
                                              widget.userCircleCache,
                                              _userCircle.muted);
                                        });
                                      },
                                      //secondary: const Icon(Icons.remove_red_eye),
                                    )),
                                    //new Spacer(flex: 11),
                                  ]),
                                )
                              : Container(),
                          Padding(
                            padding: const EdgeInsets.only(top: 0, bottom: 0),
                            child: Row(children: <Widget>[
                              Expanded(
                                  //flex: 12,
                                  child: SwitchListTile(
                                inactiveThumbColor:
                                    globalState.theme.inactiveThumbColor,
                                inactiveTrackColor:
                                    globalState.theme.inactiveTrackColor,
                                trackOutlineColor:
                                    MaterialStateProperty.resolveWith(
                                        globalState.getSwitchColor),
                                title: Text(
                                  '${AppLocalizations.of(context)!.guard} $_type',
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: globalState.theme.textFieldText),
                                ),
                                value: _guarded,
                                activeColor: globalState.theme.button,
                                onChanged: (bool value) {
                                  setState(() {
                                    // _guarded = value;
                                    if (value)
                                      _setCircleGuarded();
                                    else {
                                      _guarded = value;
                                      _userCircle.guarded = value;
                                      _userCircleBloc.update(widget.userFurnace,
                                          _userCircle, widget.userCircleCache);
                                    }
                                  });
                                },
                                //secondary: const Icon(Icons.remove_red_eye),
                              )),
                              //new Spacer(flex: 11),
                            ]),
                          ),
                          globalState.userSetting.allowHidden == false
                              ? Container()
                              : Padding(
                                  padding:
                                      const EdgeInsets.only(top: 0, bottom: 0),
                                  child: Row(children: <Widget>[
                                    Expanded(
                                        //flex: 12,
                                        child: SwitchListTile(
                                      inactiveThumbColor:
                                          globalState.theme.inactiveThumbColor,
                                      inactiveTrackColor:
                                          globalState.theme.inactiveTrackColor,
                                      trackOutlineColor:
                                          MaterialStateProperty.resolveWith(
                                              globalState.getSwitchColor),
                                      title: Text(
                                        '${AppLocalizations.of(context)!.hide} $_type',
                                        textScaler: TextScaler.linear(
                                            globalState.labelScaleFactor),
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: globalState
                                                .theme.textFieldText),
                                      ),
                                      value: _hidden,
                                      activeColor: globalState.theme.button,
                                      onChanged: (bool value) {
                                        setState(() {
                                          // _guarded = value;
                                          if (value)
                                            _hide();
                                          else {
                                            _unhide();
                                          }
                                        });
                                      },
                                      //secondary: const Icon(Icons.remove_red_eye),
                                    )),
                                    //new Spacer(flex: 11),
                                  ]),
                                ),
                          widget.circle.dm ? Container() : image,
                        ])),
                    const Padding(padding: EdgeInsets.only(top: 10, bottom: 0)),
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: ButtonType.getWidth(
                                MediaQuery.of(context).size.width)),
                        child: GradientButton(
                          text:
                              '${widget.circle.type == CircleType.VAULT ? AppLocalizations.of(context)!.dELETE : AppLocalizations.of(context)!.lEAVE} THIS ${_type.toUpperCase()}',
                          onPressed: () => _leave(context),
                        )),
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 0),
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: ButtonType.getWidth(
                                MediaQuery.of(context).size.width)),
                        child: GradientButton(
                            text:
                                '${AppLocalizations.of(context)!.cLEAR} ${widget.circle.getChatTypeLocalizedString(context).toUpperCase()} ${AppLocalizations.of(context)!.cACHE}',
                            onPressed: () {
                              _askToClearCache(context);
                            })),
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 0),
                    ),
                    /*globalState.user.role == Role.IC_ADMIN ||
                        kDebugMode ||
                        globalState.user.joinBeta
                    ? Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: ButtonType.getWidth(
                                MediaQuery.of(context).size.width)),
                        child: GradientButton(
                            text: 'CLEANUP',
                            onPressed: () {
                              _cleanup();
                            }))
                    : Container(),*/
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 0),
                    ),
                  ]),
            ),
          ),
        ));

    final getForm = Form(
        key: _formKey,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            key: _scaffoldKey,
            //backgroundColor: globalState.theme.scaffoldBackgroundColor,
            //appBar: topAppBar,
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                  /*  Container(
                //  color: Colors.white,
                padding: EdgeInsets.all(0.0),
                child: makeBottom,*/
                  //),
                ],
              ),
              showSpinner ? spinkit : Container()
            ])));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          // if (_prefName.text.length > 30) {
          //   DialogNotice.showNotice(
          //       context,
          //       AppLocalizations.of(context).displayNameTooLongTitle,
          //       AppLocalizations.of(context).displayNameTooLongMessage,
          //       null,
          //       null,
          //       null,
          //       false);
          // } never happens now due to text box limit

          FocusScope.of(context).requestFocus(FocusNode());

          if (changed)
            Navigator.pop(context, _userCircleCache);
          else
            Navigator.pop(
              context,
            );
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    if (_prefName.text.length > 30) {
                      DialogNotice.showNotice(
                          context,
                          AppLocalizations.of(context)!.displayNameTooLongTitle,
                          AppLocalizations.of(context)!
                              .displayNameTooLongMessage,
                          null,
                          null,
                          null,
                          false);
                    }

                    FocusScope.of(context).requestFocus(FocusNode());

                    if (changed) {
                      Navigator.pop(context, _userCircleCache);
                    } else {
                      Navigator.pop(
                        context,
                      );
                    }
                  } else if (details.velocity.pixelsPerSecond.dx < 0) {
                    DefaultTabController.of(context).animateTo(1);
                  }
                },
                child: getForm)
            : getForm);
  }

  Future<void> _leave(BuildContext context) async {
    if (widget.circle.type == CircleType.VAULT) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.confirmDeleteVaultTitle,
          AppLocalizations.of(context)!.confirmDeleteVaultMessage,
          _leaveResult,
          null,
          false);
    } else if (widget.circle.type == CircleType.OWNER &&
        widget.userFurnace.role == Role.OWNER &&
        widget.circle.memberCount! >= 1) {
      ///need to transfer ownership first
      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.ownerCantLeaveCircleTitle,
          AppLocalizations.of(context)!.ownerCantLeaveCircleMessage,
          null,
          null,
          null,
          false);
    } else {
      DialogYesNo.askYesNo(
          context,
          widget.circle.dm
              ? AppLocalizations.of(context)!.leaveDMTitle
              : AppLocalizations.of(context)!.leaveCircleTitle,
          widget.circle.dm
              ? AppLocalizations.of(context)!.leaveDMMessage
              : AppLocalizations.of(context)!.leaveCircleMessage,
          _leaveResult,
          null,
          false);
    }
  }

  _leaveResult() {
    _userCircleBloc.leaveCircle(widget.userFurnace, _userCircleCache);
  }

  _onChanged(String text) {
    UserCircle userCircle;

    userCircle = _userCircle;
    userCircle.prefName = _prefName.text;

    changed = true;

    widget.update(userCircle);

    // _userCircleBloc.update(
    //   widget.userFurnace, userCircle, _userCircleCache, null);
  }

  _prefNameChanged() {
    if (_origPrefName != _prefName.text && _prefName.text.length < 30) {
      UserCircle userCircle;

      userCircle = _userCircle;
      userCircle.prefName = _prefName.text;

      //widget.update(userCircle.prefName);

      changed = true;

      _userCircleBloc.updatePrefName(
          widget.userFurnace, userCircle, _userCircleCache);
    }
  }

  _askToClearCache(BuildContext context) {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.clearCacheQuestion,
        AppLocalizations.of(context)!.areYouSureYouWantToClearTheCache,
        _clearCircleCache,
        null,
        false);
  }

  _clearCircleCache() async {
    try {
      GlobalEventBloc globalEventBloc =
          Provider.of<GlobalEventBloc>(context, listen: false);

      await CacheBloc.clearCircleCache(globalEventBloc, _userCircleCache,
          _userCircleCache.circle!, _userCircleCache.circlePath!);

      globalEventBloc.refreshCircle(
          widget.userFurnace, _userCircleCache, widget.userCircleCache.circle!);

      //]CircleLastUpdate.delete(_userCircleCache!.circle!);

      //  Navigator.pop(context);

      // if (mounted) {
      //   Navigator.pushAndRemoveUntil(
      //       context,
      //       MaterialPageRoute(builder: (context) => const Home()),
      //       (Route<dynamic> route) => false);
      // }

      globalEventBloc.broadcastPopToHomeOpenTab(0);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('SettingsGeneral.ClearFileCache: $err');
    }
  }

  _backgroundChoice(context, callback) async {
    DialogChooseBackground.chooseBackgroundPopup(context, callback);
  }

  void changeColor(Color color) {
    setState(() {
      _pickerColor = color;
      _image = null;
    });
    _setImage();
    //_setColor(color);
  }

  _setColor(Color color) {
    _userCircleBloc.updateColor(
        widget.userFurnace, widget.userCircleCache, color);
  }

  _pickColor() {
    _pickerColor = Colors.lightBlueAccent;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        title: ICText(
          AppLocalizations.of(context)!.selectAColor,
          fontSize: 20,
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ColorPicker(
            pickerColor: _pickerColor!,
            onColorChanged: changeColor,
          ),
        ),
        actions: <Widget>[
          GradientButtonDynamic(
            /*style: ElevatedButton.styleFrom(
              backgroundColor: globalState.theme.buttonIcon,
            ),*/
            onPressed: () {
              Navigator.of(context).pop();
            },
            text: AppLocalizations.of(context)!.selectAColor,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  _selectImage() async {
    ImagePicker imagePicker = ImagePicker();

    try {
      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: ImageConstants.CIRCLEBACKGROUND_QUALITY,
      );

      if (imageFile != null) {
        setState(() {
          _image = File(imageFile.path);
          _pickerColor = null;
          _currentColor = null;
        });
        _setImage();
      }
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }
  }

  bool _hasBackground({bool override = false}) {
    bool retValue = false;

    ///They just picked a color so ignore the background image
    if (_currentColor != null || _pickerColor != null) return retValue;

    if (_image == null || override) {
      if (widget.userCircleCache.background != null) {
        if (FileSystemService.isUserCircleBackgroundCached(
            widget.userCircleCache.circlePath!,
            widget.userCircleCache.background!)) {
          _image = File(FileSystemService.returnUserCircleBackgroundPath(
              widget.userCircleCache.circlePath!,
              widget.userCircleCache.background!));
        } else {
          //request the image be cached
          _userCircleBloc.notifyWhenBackgroundReady(
              widget.userFurnace, widget.userCircleCache);
        }

        retValue = true;
      } else if (widget.userCircleCache.masterBackground != null) {
        _image = File(FileSystemService.returnCircleBackgroundPath(
            widget.userCircleCache.circlePath!,
            widget.userCircleCache.masterBackground!));
        retValue = true;
      }
    } else {
      retValue = true;
    }

    return retValue;
  }

  _setImage() {
    if (_image != null) {
      FormattedSnackBar.showSnackbarWithContext(context,
          AppLocalizations.of(context)!.updatingSettings, "", 1, false);

      _userCircleBloc.updateImage(
          widget.userFurnace, widget.userCircleCache, _image!);

      setState(() {
        showSpinner = true;
      });
    } else {
      _userCircleBloc.updateColor(
          widget.userFurnace, widget.userCircleCache, _pickerColor!);
    }
  }

  _setCircleGuarded() async {
    await DialogPatternCapture.capture(
        context, _pin1Captured, AppLocalizations.of(context)!.swipePattern);
  }

  _pin1Captured(List<int> pin) async {
    debugPrint(pin.toString());
    _pin = pin;
    await DialogPatternCapture.capture(context, _pin2Captured,
        AppLocalizations.of(context)!.pleaseReswipePattern);
  }

  _pin2Captured(List<int> pin) {
    setState(() {
      if (listEquals(pin, _pin)) {
        _guarded = true;

        //save pin
        _userCircleBloc.setPin(widget.userFurnace, widget.userCircleCache, pin);
      } else {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.patternsDoNotMatch, "", 2, false);
        _guarded = false;
      }
    });
  }
  //
  // Future<Null> _cropImage() async {
  //   if (_image == null) return;
  //
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: _image!.path,
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
  //             toolbarTitle: AppLocalizations.of(context)!.adjustImage,
  //             backgroundColor: globalState.theme.background,
  //             activeControlsWidgetColor: Colors.blueGrey[600],
  //             toolbarColor: globalState.theme.background,
  //             statusBarColor: globalState.theme.background,
  //             toolbarWidgetColor: globalState.theme.menuIcons,
  //             initAspectRatio: CropAspectRatioPreset.original,
  //             lockAspectRatio: false),
  //         IOSUiSettings(
  //           title: AppLocalizations.of(context)!.adjustImage,
  //         )
  //       ]);
  //   if (croppedFile != null) {
  //     setState(() {
  //       _image = File(croppedFile.path);
  //       //state = AppState.cropped;
  //     });
  //     _setImage();
  //   }
  // }

  _hide() async {
    String? passcode = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CircleHide(
            userCircleCache: widget.userCircleCache,
            userFurnaces: widget.userFurnaces,
          ),
        ));

    if (passcode != null) {
      if (passcode.isNotEmpty) _hideCallback(widget.userCircleCache, passcode);
    }
  }

  _hideCallback(UserCircleCache userCircleCache, String passcode) async {
    userCircleCache.hiddenOpen = true;
    userCircleCache.hidden = true;

    await _userCircleBloc.hide(
        widget.firebaseBloc, userCircleCache, true, passcode);

    // Navigate back to home screen
    _goHome();
    // Update UI to remove the hidden circle from lists
    _globalEventBloc.broadcastHideCircle(widget.userCircleCache.usercircle!);
  }

  _unhide() {
    DialogYesNo.askYesNo(
        context,
        widget.userCircleCache.dm
            ? AppLocalizations.of(context)!.unhideDMTitle
            : AppLocalizations.of(context)!.unhideCircleTitle,
        widget.userCircleCache.dm
            ? AppLocalizations.of(context)!.unhideDMMessage
            : AppLocalizations.of(context)!.unhideCircleMessage,
        _unhideConfirm,
        null,
        false,
        widget.userCircleCache);
  }

  _unhideConfirm(UserCircleCache userCircleCache) {
    userCircleCache.hiddenOpen = false;
    userCircleCache.hidden = false;

    _userCircleBloc.hide(widget.firebaseBloc, userCircleCache, false, '');

    setState(() {
      _hidden = false;
    });

    _globalEventBloc.broadcastUnhideCircle(widget.userCircleCache.usercircle!);

    //widget.update(userCircleCache);
  }

  _backgroundTypeCallback(BuildContext context, bool inside) {
    if (inside) {
      _selectImage();
    } else {
      _pickColor();
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _generate() async {
    _closeKeyboard();

    SelectedMedia? selectedMedia = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StableDiffusionWidget(
            userFurnace: globalState.userFurnace!,
            imageGenType: ImageType.circle,
            //previewScreenName: 'Preview',
            initialPrompt:
                StableDiffusionPrompt.getCirclePrompt(_prefName.text)),
      ),
    );

    if (selectedMedia != null) {
      setState(() {});
      _pickerColor = null;
      _currentColor = null;
      _image = selectedMedia.mediaCollection.media[0].file;
      _setImage();
    }
  }

  _cleanup2() {
    /*if (mounted) {
      setState(() {
        _showSpinner = true;
      });
    }

     */
    ///TODO add a spinner

    _circleObjectBloc.cleanup(widget.userFurnace);
  }
}
