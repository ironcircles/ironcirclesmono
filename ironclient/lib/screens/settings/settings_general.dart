import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/circles/home.dart';
import 'package:ironcirclesapp/screens/payment/coinledger.dart';
import 'package:ironcirclesapp/screens/settings/logviewer.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/screens/settings/settings_general_transfer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/themes/darktheme.dart';
import 'package:ironcirclesapp/screens/themes/lighttheme.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpremiumfeature.dart';
import 'package:ironcirclesapp/screens/widgets/dialogupload.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:provider/provider.dart';

class SettingsGeneral extends StatefulWidget {
  final UserFurnace? userFurnace;
  final bool fromFurnaceManager;

  const SettingsGeneral({
    Key? key,
    required this.userFurnace,
    required this.fromFurnaceManager,
  }) : super(key: key);

  @override
  _SettingsGeneralState createState() => _SettingsGeneralState();
}

class _SettingsGeneralState extends State<SettingsGeneral> {
  final UserBloc _userBloc = UserBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  LogBloc logBloc = LogBloc();
  //User _user = globalState.user;
  final _username = TextEditingController();
  File? _image;
  UserFurnace? _userFurnace;

  late List<bool> themeMode;
  late GlobalEventBloc _globalEventBloc;
  bool _submitLogs = false;
  bool _showFeed = true;

  final LogBloc _logBloc = LogBloc();
  ICProgressDialog icProgressDialog = ICProgressDialog();
  bool _usernameReserved = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  bool validatedOnceAlready = false;
  bool changed = false;
  bool leaving = false;
  bool _usernameChanged = false;

  //double radius = 150 - (globalState.scaleDownTextFont * 2);
  bool _genImage = false;
  StableDiffusionPrompt stableDiffusionAIParams =
      StableDiffusionPrompt(promptType: PromptType.generate);
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  int _seed = 0;

  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    stableDiffusionAIParams.negativePrompt =
        "words, text, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft, nsfw";

    _userFurnace = widget.userFurnace;
    _showFeed = globalState.userSetting.unreadFeedOn;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    if (globalState.user.reservedUsername) _usernameReserved = true;

    _userBloc.usernameReserved.listen((reserved) {
      if (mounted) {
        setState(() {
          _usernameReserved = reserved;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.usernameNotReserved,
          AppLocalizations.of(context)!.usernameReservedByAnother,
          false);
      debugPrint("error $err");
    }, cancelOnError: false);

    _logBloc.toggleSuccess.listen((success) {
      if (mounted) {
        if (_submitLogs)
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.logSubmissionEnabled.toLowerCase(),
              "",
              1,
              false);
        else
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.logSubmissionDisabled.toLowerCase(),
              "",
              1,
              false);

        globalState.user.submitLogs = _submitLogs;
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    globalState.theme.themeMode == ICThemeMode.dark
        ? themeMode = [true, false]
        : themeMode = [false, true];

    // _transparency = globalState.userFurnace!.transparency;
    //_guarded = globalState.userFurnace!.guarded;
    if (globalState.user.submitLogs != null)
      _submitLogs = globalState.user.submitLogs!;

    if (_userFurnace == null) {
      _userFurnace = globalState.userFurnace;
      debugPrint('break');
    }

    _username.text = _userFurnace!.username!;
    stableDiffusionAIParams.setPrompt(_username.text, ImageType.avatar);
    stableDiffusionAIParams.setNegativePrompt(ImageType.avatar);

    _userBloc.usernameUpdated.listen((success) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.usernameUpdated.toLowerCase(),
            "",
            1,
            false);
      }

      _globalEventBloc.broadcastRefreshHome();

      if (leaving == true) {
        Navigator.pop(context);
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    _userBloc.avatarChanged.listen((success) {
      if (mounted) {
        //FormattedSnackBar.showSnackbarWithContext(
        //    context, "avatar updated", "", 1, false);

        _globalEventBloc.broadcastRefreshHome();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    if (FileSystemService.avatarExistsSync(
        _userFurnace!.userid!, _userFurnace!.avatar)) {
      _image = File(FileSystemService.returnAvatarPathSync(
          _userFurnace!.userid!, _userFurnace!.avatar!));
    } else if (_userFurnace!.authServer! == true &&
        FileSystemService.avatarExistsSync(
            globalState.user.id!, globalState.user.avatar)) {
      _image = File(FileSystemService.returnAvatarPathSync(
          globalState.user.id!, globalState.user.avatar!));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final avatar =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 17, top: 0, bottom: 10, right: 15),
          child: ICText(
            '${AppLocalizations.of(context)!.avatar}:',
            fontSize: 15,
            color: globalState.theme.labelTextSubtle,
          ),
        ),
      ]),
      Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(children: [
              InkWell(
                  onTap: () async {
                    File? cropped = await ImageUtil.cropImage(context, _image);
                    if (cropped != null) {
                      setState(() {
                        _image = cropped;
                      });
                      _setAvatar();
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
                              child: _image != null
                                  ? Image.file(_image!, fit: BoxFit.cover)
                                  : Image.asset(
                                      'assets/images/avatar.jpg',
                                      fit: BoxFit.cover,
                                    ))))),
            ]),
            const Padding(
              padding: EdgeInsets.only(
                right: 5,
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                GradientButtonDynamic(
                  text: AppLocalizations.of(context)!
                      .generateAvatar
                      .toLowerCase(),
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
                    _image = await ImageUtil.selectImage(context);
                    if (_image != null) {
                      setState(() {});
                      _setAvatar();
                    }
                  },
                ),
              ]),
            ])
          ])
    ]);

    final makeBody = Container(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: WrapperWidget(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                flex: 20,
                                child: Focus(
                                  child: FormattedText(
                                    controller: _username,
                                    maxLength: 25,
                                    labelText:
                                        AppLocalizations.of(context)!.username,
                                    onChanged: _revalidate,
                                    validator: (value) {
                                      if (value.toString().endsWith(' ')) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotEndWithASpace;
                                      } else if (value.toString().length < 3) {
                                        return AppLocalizations.of(context)!
                                            .mustBe3CharsError;
                                      } else if (value
                                          .toString()
                                          .startsWith(' ')) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotStartWithASpace;
                                      }

                                      return null;
                                    },
                                  ),
                                  onFocusChange: (hasFocus) {
                                    if (hasFocus == false) {
                                      if (_usernameChanged == true) {
                                        _userBloc.updateUsername(_username.text,
                                            widget.userFurnace!);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ]),
                      ),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding: const EdgeInsets.only(top: 0, bottom: 0),
                              child: SwitchListTile(
                                inactiveThumbColor:
                                    globalState.theme.inactiveThumbColor,
                                inactiveTrackColor:
                                    globalState.theme.inactiveTrackColor,
                                trackOutlineColor:
                                    MaterialStateProperty.resolveWith(
                                        globalState.getSwitchColor),
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .reserveUsernameOnAllNetworks,
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontSize:
                                          16 - globalState.scaleDownTextFont,
                                      color: globalState.theme.textFieldLabel),
                                ),
                                activeColor: globalState.theme.button,
                                value: _usernameReserved,
                                onChanged: (bool value) {
                                  _reserveUsername(value);
                                },
                              ),
                            )
                          : Container(),
                      avatar,
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                      ),
                      widget.fromFurnaceManager
                          ? Container()
                          : const Divider(
                              color: Colors.grey,
                              height: 2,
                              thickness: 2,
                              indent: 0,
                              endIndent: 0,
                            ),
                      widget.fromFurnaceManager
                          ? Container()
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 0),
                              child: Row(children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)!.colorTheme,
                                  textScaler: TextScaler.linear(
                                      globalState.textFieldScaleFactor),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: globalState.theme.labelText),
                                ),
                              ]),
                            ),
                      widget.fromFurnaceManager
                          ? Container()
                          : const Padding(
                              padding: EdgeInsets.only(top: 10),
                            ),
                      widget.fromFurnaceManager
                          ? Container()
                          : _toggleButton(
                              "",
                              AppLocalizations.of(context)!.dark,
                              AppLocalizations.of(context)!.light,
                              themeMode,
                              alignLeft: true,
                              callback: _changeTheme,
                            ),
                      widget.fromFurnaceManager
                          ? Container()
                          : const Padding(
                              padding: EdgeInsets.only(top: 10),
                            ),
                      widget.fromFurnaceManager
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 5, bottom: 5, right: 10, left: 10),
                              child: InkWell(
                                  onTap: _toggleMessageColors,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    color: globalState
                                                        .theme.menuBackground,
                                                    border: Border.all(
                                                        color: Colors
                                                            .lightBlueAccent
                                                            .withOpacity(.1),
                                                        width: 2.0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0)),
                                                padding: const EdgeInsets.only(
                                                    top: 10,
                                                    bottom: 10,
                                                    left: 15,
                                                    right: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .resetMessageTextColors,
                                                        textScaler:
                                                            const TextScaler
                                                                .linear(1.0),
                                                        style: TextStyle(
                                                          fontSize: 16 -
                                                              globalState
                                                                  .scaleDownTextFont,
                                                          color: globalState
                                                              .theme.labelText,
                                                        )),
                                                  ],
                                                ))),
                                      ]))),
                      // widget.fromFurnaceManager
                      //     ? Container()
                      //     : Padding(
                      //         padding: const EdgeInsets.only(top: 0, bottom: 0),
                      //         child: Row(children: <Widget>[
                      //           Expanded(
                      //               //flex: 12,
                      //               child: SwitchListTile(
                      //             inactiveThumbColor:
                      //                 globalState.theme.inactiveThumbColor,
                      //             inactiveTrackColor:
                      //                 globalState.theme.inactiveTrackColor,
                      //             trackOutlineColor:
                      //                 MaterialStateProperty.resolveWith(
                      //                     globalState.getSwitchColor),
                      //             title: Text(
                      //               'Show unread message feed?',
                      //               textScaler: const TextScaler.linear(1.0),
                      //               style: TextStyle(
                      //                   fontSize: 18,
                      //                   color: globalState.theme.labelText),
                      //             ),
                      //             value: _showFeed,
                      //             activeColor: globalState.theme.button,
                      //             onChanged: (bool value) {
                      //               setState(() {
                      //                 _toggleFeed();
                      //               });
                      //             },
                      //           )),
                      //         ]),
                      //       ),

                      widget.fromFurnaceManager
                          ? Container()
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: 20, bottom: 0),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .enableFeedback,
                                    textScaler: TextScaler.linear(
                                        globalState.labelScaleFactor),
                                    style: TextStyle(
                                        color: globalState.theme.labelText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  ),
                                ),
                              ])),

                      /*: Container()*/
                      widget.fromFurnaceManager
                          ? Container()
                          : Row(children: [
                              Expanded(
                                  child: SwitchListTile(
                                inactiveThumbColor:
                                    globalState.theme.inactiveThumbColor,
                                inactiveTrackColor:
                                    globalState.theme.inactiveTrackColor,
                                trackOutlineColor:
                                    MaterialStateProperty.resolveWith(
                                        globalState.getSwitchColor),
                                activeColor: globalState.theme.button,
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .submitDefectLogsQuestion,
                                  textScaler: const TextScaler.linear(1.0),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: globalState.theme.labelTextSubtle),
                                ),
                                value: _submitLogs,
                                onChanged: (bool value) {
                                  _toggleLogs(value);
                                },
                              )),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.help),
                                iconSize: 25 - globalState.scaleDownIcons,
                                color: globalState.theme.bottomIcon,
                                onPressed: () {
                                  setState(() {
                                    DialogNotice.showNotice(
                                        context,
                                        AppLocalizations.of(context)!
                                            .defectLogsTitle,
                                        AppLocalizations.of(context)!
                                            .defectLogsMessage1,
                                        AppLocalizations.of(context)!
                                            .defectLogsMessage2,
                                        AppLocalizations.of(context)!
                                            .defectLogsMessage3,
                                        '',
                                        false);
                                  });
                                },
                              ),
                            ]),
                      // globalState.user.joinBeta
                      //     ?
                      Row(children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                              ),
                              GradientButtonDynamic(
                                text: AppLocalizations.of(context)!
                                    .sendDetailedLog,
                                onPressed: () {
                                  _sendDetailedLog();
                                },
                              )
                            ]),
                         // : Container(),
                      widget.fromFurnaceManager
                          ? Container()
                          : globalState.user.role == Role.IC_ADMIN || kDebugMode
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5, bottom: 10, right: 10, left: 10),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                            child: InkWell(
                                                onTap: () {
                                                  _openLogViewer();
                                                },
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: globalState.theme
                                                            .menuBackground,
                                                        border: Border.all(
                                                            color: Colors
                                                                .lightBlueAccent
                                                                .withOpacity(
                                                                    .1),
                                                            width: 2.0),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    12.0)),
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10,
                                                            bottom: 10,
                                                            left: 15,
                                                            right: 10),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .openLogViewer,
                                                            textScaler:
                                                                const TextScaler
                                                                    .linear(
                                                                    1.0),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: globalState
                                                                  .theme
                                                                  .labelText,
                                                            )),
                                                        Icon(
                                                            Icons
                                                                .keyboard_arrow_right,
                                                            color: globalState
                                                                .theme
                                                                .labelText,
                                                            size: 25.0),
                                                      ],
                                                    )))),
                                      ]))
                              : Container(),
                      const Divider(
                        color: Colors.grey,
                        height: 2,
                        thickness: 2,
                        indent: 0,
                        endIndent: 0,
                      ),
                      globalState.user.role == Role.IC_ADMIN
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(top: 20, bottom: 5),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.adminSection,
                                    style: TextStyle(
                                        color: globalState.theme.labelText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  ),
                                ),
                              ]))
                          : Container(),
                      globalState.user.role == Role.IC_ADMIN
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10, left: 14),
                              child: Column(children: <Widget>[
                                Row(children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.pushToken} ',
                                      style: TextStyle(
                                          color: globalState.theme.labelText,
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 16.0),
                                    ),
                                  ),
                                ]),
                                Row(children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      globalState.getDevicePushTokenSync(),
                                      style: TextStyle(
                                          color:
                                              globalState.theme.labelTextSubtle,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.0),
                                    ),
                                  ),
                                ]),
                              ]))
                          : Container(),
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                        ),
                      ),
                      globalState.user.role == Role.IC_ADMIN || kDebugMode
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10, left: 14),
                              child: Column(children: <Widget>[
                                Row(children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.deviceUuid} ',
                                      textScaler: TextScaler.linear(
                                          globalState.labelScaleFactor),
                                      style: TextStyle(
                                          color: globalState.theme.labelText,
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 16.0),
                                    ),
                                  ),
                                ]),
                                Row(children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      globalState.getDeviceUUIDSync(),
                                      textScaler: TextScaler.linear(
                                          globalState.labelScaleFactor),
                                      style: TextStyle(
                                          color:
                                              globalState.theme.labelTextSubtle,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.0),
                                    ),
                                  ),
                                ]),
                              ]))
                          : Container(),
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                        ),
                      ),
                      Row(children: <Widget>[
                        /*Expanded(
                        flex: 1,
                        child:Padding(
                      padding: EdgeInsets.only(left: 1),
                    )),*/

                        Expanded(
                            child: GradientButton(
                                width: width,
                                text: 'DELETE ACCOUNT',
                                onPressed: () {
                                  _askDeleteAccount();
                                })),
                      ]),
                    ]),
              ),
            )));

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            //appBar: topAppBar,
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                  Container(
                    //  color: Colors.white,
                    padding: const EdgeInsets.all(0.0),
                    //child: makeBottom,
                  ),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
  }

  _doNothing() {}
  //Need to grab the

  _setAvatar() async {
    if (_userFurnace!.avatar != null &&
        (_image == null ||
            _image!.path ==
                FileSystemService.returnAvatarPathSync(
                    _userFurnace!.userid!, _userFurnace!.avatar!))) {
      FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.avatarNotChanged.toLowerCase(),
          "",
          1,
          false);
      return;
    }

    _userBloc.updateAvatar(_userFurnace!, _image!);

    FormattedSnackBar.showSnackbarWithContext(
        context,
        AppLocalizations.of(context)!.updatingAvatar.toLowerCase(),
        "",
        1,
        false);
  }

  void _toggleLogs(bool value) {
    setState(() {
      _submitLogs = value;

      _logBloc.toggle(widget.userFurnace!, _submitLogs);
    });
  }

  _toggleMessageColors() async {
    setState(() {
      _showSpinner = true;
    });

    await _initColorIndex();

    setState(() {
      _showSpinner = false;
    });
  }

  _initColorIndex() async {
    //New device, user cleared data, or uninstall/reinstalled app
    int colorIndex = 0;
    globalState.userSetting.setLastColorIndex(colorIndex);
    await MemberBloc.setInitialColors();
  }

  _changeTheme(String a, String b) async {
    setState(() {
      _showSpinner = true;
    });

    debugPrint("change theme start at ${DateTime.now()}");

    if (b == "dark") {
      //globalState.theme = DarkTheme();
      await globalState.userSetting.setTheme(ThemeSetting.DARK);
    } else if (b == "light") {
      //globalState.theme = LightTheme();
      await globalState.userSetting.setTheme(ThemeSetting.LIGHT);
    }

    debugPrint("_initColorIndex start at ${DateTime.now()}");

    _initColorIndex();

    if (b == "dark") {
      globalState.theme = DarkTheme();
      //await globalState.userSetting.setTheme(ThemeSetting.DARK);
    } else if (b == "light") {
      globalState.theme = LightTheme();
      //await globalState.userSetting.setTheme(ThemeSetting.LIGHT);
    }

    setState(() {
      _showSpinner = false;
    });

    debugPrint("change theme end at ${DateTime.now()}");

    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const Home(
                  )),
          (Route<dynamic> route) => false);

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Settings(
              tab: TAB.PROFILE,
            ),
          ));
    }
  }

  _sendDetailedLog() {
    logBloc.sendDetailedLog(
        globalState.userFurnace!, globalState.user, _globalEventBloc);

    DialogUpload.showUploadingBlob(
        context, AppLocalizations.of(context)!.uploadingWait, _globalEventBloc);
  }

  _openLogViewer() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogViewer(),
        ));
  }

  _openCoinLedger() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoinLedger(
            userFurnace: widget.userFurnace!,
          ),
        ));
  }

  _toggleButton(String label, String a, String b, List<bool> list,
      {bool alignLeft = false, Function? callback}) {
    return Row(children: <Widget>[
      const Padding(
          padding: EdgeInsets.only(
        left: 10,
      )),
      /*Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 15, right: 5),
              child: Text(
                label,
                textAlign: alignLeft ? TextAlign.end : TextAlign.start,
                textScaleFactor: globalState.labelScaleFactor,
                style: TextStyle(
                    fontSize: 17, color: globalState.theme.buttonText),
              ))),*/
      ToggleButtons(
        selectedBorderColor: globalState.theme.dialogTransparentBackground,
        borderColor: globalState.theme.dialogTransparentBackground,
        fillColor: Colors.lightBlueAccent.withOpacity(.1),
        onPressed: (int index) {
          setState(() {
            //return;
            for (int buttonIndex = 0;
                buttonIndex < list.length;
                buttonIndex++) {
              if (buttonIndex == index) {
                list[buttonIndex] = true;
              } else {
                list[buttonIndex] = false;
              }
            }

            if (callback != null) {
              if (list[0] == true)
                callback(b, a);
              else
                callback(a, b);
            }
          });
        },
        isSelected: list,
        //selectedColor: Colors.red, //globalState.theme.buttonIcon,
        //highlightColor: Colors.yellow,
        children: <Widget>[
          SizedBox(
              width: 80,
              child: Center(
                  child: Text(
                a,
                textScaler: TextScaler.linear(globalState.labelScaleFactor),
                style: TextStyle(
                    color: list[0]
                        ? globalState.theme.buttonIcon
                        : globalState.theme.labelTextSubtle),
              ))),
          SizedBox(
              width: 80,
              child: Center(
                  child: Text(
                b,
                textScaler: TextScaler.linear(globalState.labelScaleFactor),
                style: TextStyle(
                    color: list[1]
                        ? globalState.theme.buttonIcon
                        : globalState.theme.labelTextSubtle),
              ))),
        ],
      )
    ]);
  }

  _reserveUsername(bool reserved) {
    if (globalState.user.accountType == AccountType.FREE) {

      DialogPremiumFeature.premiumFeature(context,  AppLocalizations.of(context)!.premiumFeatureTitle,  AppLocalizations.of(context)!.premiumFeatureReserveUsername,);

      // DialogNotice.showNotice(
      //     context,
      //     AppLocalizations.of(context)!.premiumFeatureTitle,
      //     AppLocalizations.of(context)!.premiumFeatureReserveUsername,
      //     AppLocalizations.of(context)!.premiumFeatureUpgrade,
      //     null,
      //     null,
      //     false);
    } else {
      setState(() {
        _showSpinner = true;
      });

      _userBloc.reserveUsername(_userFurnace!, reserved);
    }
  }

  void _askDeleteAccount() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.deleteAccountTitle,
        AppLocalizations.of(context)!.deleteAccountMessage,
        _deleteAccountYes,
        null,
        false);
  }

  void _deleteAccountYes() async {
    List<User> members =
        await _userBloc.deleteAccount(widget.userFurnace!, null);

    if (members.isNotEmpty && mounted) {
      String? transferUserID = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsGeneralTransfer(
              userFurnace: widget.userFurnace!,
              members: members,
            ),
          ));

      if (transferUserID != null)
        await _userBloc.deleteAccount(widget.userFurnace!, transferUserID);

      if (widget.userFurnace!.authServer! == false && mounted) {
        Navigator.pop(context);
      }
    } else {
      if (widget.userFurnace!.authServer! == false && mounted) {
        Navigator.pop(context);
      }
    }
  }

  _toggleFeed() {
    setState(() {
      _showFeed = !_showFeed;
      globalState.userSetting.setUnreadFeedOn(_showFeed);

      Navigator.pushReplacementNamed(
        context,
        '/home',
        // arguments: user,
      );
    });
  }

  void _revalidate(String value) {
    ///only username
    if (_username.text != _userFurnace!.username!) {
      _usernameChanged = true;
    } else {
      _usernameChanged = false;
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
            imageGenType: ImageType.avatar,
            initialPrompt:
                StableDiffusionPrompt.getAvatarPrompt(_username.text)),
      ),
    );

    if (selectedMedia != null) {
      _image = selectedMedia.mediaCollection.media[0].file;
      if (mounted) setState(() {});
      _setAvatar();
    }
  }
}
