import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/login/network_connect_hosted.dart';
import 'package:ironcirclesapp/screens/login/registration.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

class NetworkManagerCreate extends StatefulWidget {
  // FlutterManager({Key key, this.title}) : super(key: key);
  final bool authServer;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;

  const NetworkManagerCreate({
    Key? key,
    required this.authServer,
    required this.userFurnace,
    required this.userFurnaces,
  }) : super(key: key);
  // final String title;

  @override
  _FurnaceCreateHostedState createState() => _FurnaceCreateHostedState();
}

class _FurnaceCreateHostedState extends State<NetworkManagerCreate> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _userFurnaceBloc = UserFurnaceBloc();
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final TextEditingController _networkName = TextEditingController();
  final TextEditingController _accessCode = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _networkUrl = TextEditingController();
  final TextEditingController _networkApiKey = TextEditingController();
  UserFurnace? localFurnace;
  bool _linkedAccount = true;
  int _initialIndex = 0;
  bool validatedOnceAlready = false;
  bool clicked = false;
  bool _discoverable = false;
  bool _adultOnly = false;
  bool _memberAutonomy = true;
  bool _enableFeed = true;
  bool _boolSelfHosted = false;
  File? _image;
  double radius = 200 - (globalState.scaleDownTextFont * 2);
  static const double _iconPadding = 10;
  ProgressDialog? progressDialog;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    if (kDebugMode) {
      _networkUrl.text = "https://ironfurny.herokuapp.com/";
      _networkApiKey.text = "J73Hpqj362J4psX7jyhXdftbxSPYkE9CrjWShz9r";
    }

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _userFurnaceBloc.userFurnace.listen((success) {

      if (success!= null && (success.type == NetworkType.SELF_HOSTED || success.authServer == true)){
        KeychainBackupBloc.backupDevice(success, false);
      } else{
        KeychainBackupBloc.backupDevice(globalState.userFurnace!, false);
      }



      Navigator.pop(context, success);
      Navigator.pop(context, success);

      if (_linkedAccount == false) {
        Navigator.pop(context, success);
      }

      progressDialog!.dismiss();

      /*Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (Route<dynamic> route) => false,
        arguments: globalState.user,
      );*/
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      progressDialog!.dismiss();
      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.usernameExists,
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.usernameReserved,
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.errorGenericTitle,
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            false);

      debugPrint("error $err");
      progressDialog!.dismiss();
    }, cancelOnError: false);

    super.initState();
  }

  void _cycleAccessCode() async {
    try {
      _accessCode.text = SecureRandomGenerator.generateString(length: 12);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('FurnaceAddNew.generatePasscode: $err');
    }
  }

  @override
  void dispose() {
    _userFurnaceBloc.dispose();
    _networkName.dispose();
    _networkUrl.dispose();
    _accessCode.dispose();
    _networkApiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textScale = MediaQuery.textScalerOf(context).scale(1);

    final networkImage = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0, bottom: 15),
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
                    child: SizedBox(
                        width: radius,
                        //width: 400,
                        child: ClipOval(
                            child: InkWell(
                                child: _image != null
                                    ? Image.file(_image!,
                                        height: radius,
                                        width: radius,
                                        fit: BoxFit.cover)
                                    : Image.asset(
                                        'assets/images/ios_icon.png',
                                        height: radius,
                                        width: radius,
                                        fit: BoxFit.fitHeight,
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
                      _image = await ImageUtil.selectImage(context);
                      setState(() {});
                    },
                  ),
                ]),
              ])
            ]));

    final createNewSocialNetwork = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: Row(children: <Widget>[
          Expanded(
              child: GradientButton(
                  text:
                      AppLocalizations.of(context)!.createNetwork.toUpperCase(),
                  width: screenWidth,
                  onPressed: () {
                    _createNetwork();
                  })),
        ]),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
                title: AppLocalizations.of(context)!.newNetworkHelpTitle,
                actions: <Widget>[
                  IconButton(
                    padding: const EdgeInsets.only(right: _iconPadding),
                    constraints: const BoxConstraints(),
                    iconSize: 27.0 - globalState.scaleDownIcons,
                    onPressed: () {
                      DialogNotice.showNewNetworkHelp(context);
                    },
                    icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                  )
                ]),
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: SingleChildScrollView(
                    child: WrapperWidget(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 0, left: 10, right: 49),
                          child: Row(children: <Widget>[
                            Expanded(
                              child: FormattedText(
                                labelText:
                                    AppLocalizations.of(context)!.nameOfNetwork,
                                maxLength: 50,
                                controller: _networkName,
                                onChanged: _revalidate,
                                validator: (value) {
                                  if (value.toString().endsWith(' ')) {
                                    return 'cannot end with a space';
                                  } else if (value.toString().length < 3) {
                                    return 'must be at least 3 chars';
                                  } else if (value.toString().startsWith(' ')) {
                                    return 'cannot start with a space';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ])),
                      const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 0),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 0, bottom: 0, left: 10, right: 0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FormattedText(
                                  labelText: AppLocalizations.of(context)!
                                      .createAnAccessCode,
                                  maxLength: 25,
                                  //obscureText: !_showAPIKey,
                                  controller: _accessCode,
                                  onChanged: _revalidate,
                                  validator: (value) {
                                    if (value.toString().endsWith(' ')) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotEndWithASpace;
                                    } else if (value.toString().length < 6) {
                                      return AppLocalizations.of(context)!
                                          .mustBeAtLeast6Chars; //'must be at least 6 chars';
                                    } else if (value
                                        .toString()
                                        .startsWith(' ')) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotStartWithASpace;
                                    }

                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: IconButton(
                                      icon: Icon(Icons.refresh,
                                          color: globalState.theme.buttonIcon),
                                      onPressed: () {
                                        setState(() {
                                          //_showAPIKey = false;
                                          _cycleAccessCode();
                                        });
                                      }))
                            ],
                          )),
                      Align(
                          alignment: Alignment.center,
                          child: Toggle.ToggleSwitch(
                            minWidth: 150.0,
                            //minHeight: 70.0,
                            initialLabelIndex: _initialIndex,
                            cornerRadius: 20.0,
                            activeFgColor: Colors.white,
                            inactiveBgColor: Colors.grey,
                            inactiveFgColor: Colors.white,
                            totalSwitches: 2,
                            radiusStyle: true,
                            labels: const [
                              "IronCircles hosted", "Self hosted"
                              // AppLocalizations.of(context)!.efficient,
                              // AppLocalizations.of(context)!.hires
                            ],
                            customTextStyles: [
                              TextStyle(fontSize: 12 / textScale),
                              TextStyle(fontSize: 12 / textScale)
                            ],
                            //iconSize: 30.0,
                            activeBgColors: const [
                              [
                                Colors.tealAccent,
                                Colors.teal,
                              ],
                              [Colors.yellow, Colors.orange]
                            ],
                            animate: true,
                            // with just animate set to true, default curve = Curves.easeIn
                            curve: Curves.bounceInOut,
                            // animate must be set to true when using custom curve
                            onToggle: (index) {
                              debugPrint('switched to: $index');
                              //_hiRes = !_hiRes;

                              setState(() {
                                _boolSelfHosted = !_boolSelfHosted;
                                _initialIndex = index!;
                              });
                            },
                          )),
                      _boolSelfHosted
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 11, top: 15, bottom: 0, right: 15),
                              child: Row(children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: FormattedText(
                                    //hintText: 'Enter a name for your network',
                                    controller: _networkUrl,
                                    maxLength: 50,
                                    labelText:
                                        'api url', //'enter network name',
                                    maxLines: 1,
                                    onChanged: _revalidate,
                                    validator: (value) {
                                      if (value.toString().endsWith(' ')) {
                                        return 'cannot end with a space';
                                      } else if (value.toString().isEmpty) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotBeEmpty; //'cannot be empty';
                                      } else if (value
                                          .toString()
                                          .startsWith(' ')) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotStartWithASpace;
                                        'cannot start with a space';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ]))
                          : Container(),
                      _boolSelfHosted
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 11, top: 15, bottom: 0, right: 15),
                              child: Row(children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: FormattedText(
                                    //hintText: 'Enter a name for your network',
                                    controller: _networkApiKey,
                                    maxLength: 50,
                                    labelText:
                                        'api key', //'enter network name',
                                    maxLines: 1,
                                    onChanged: _revalidate,
                                    validator: (value) {
                                      if (value.toString().endsWith(' ')) {
                                        return 'cannot end with a space';
                                      } else if (value.toString().isEmpty) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotBeEmpty; //'cannot be empty';
                                      } else if (value
                                          .toString()
                                          .startsWith(' ')) {
                                        return AppLocalizations.of(context)!
                                            .errorCannotStartWithASpace;
                                        'cannot start with a space';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ]))
                          : const Padding(
                              padding: EdgeInsets.only(top: 20, bottom: 0),
                            ),

                      // Padding(
                      //     padding: const EdgeInsets.only(
                      //         top: 0, bottom: 10, left: 10, right: 49),
                      //     child:Row(children: [Text("Optional")])),
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 0, bottom: 0, left: 10, right: 49),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                  child: Focus(
                                      child: ExpandingText(
                                          capitals: true,
                                          maxLength: 300,
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .addDescription,
                                          controller: _description,
                                          onChanged: _revalidate,
                                          validator: (value) {
                                            return null;
                                          }),
                                      onFocusChange: (hasFocus) async {
                                        if (hasFocus == false) {
                                          String newText =
                                              _description.text.trim();
                                          _description.text = newText;
                                        }
                                      })),
                            ],
                          )),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                              //flex: 12,
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10, left: 10),
                                  child: SwitchListTile(
                                    inactiveThumbColor:
                                        globalState.theme.inactiveThumbColor,
                                    inactiveTrackColor:
                                        globalState.theme.inactiveTrackColor,
                                    trackOutlineColor:
                                        MaterialStateProperty.resolveWith(
                                            globalState.getSwitchColor),
                                    title: ICText(
                                      AppLocalizations.of(context)!
                                          .makeNetworkDiscoverable,
                                      color: globalState.theme.buttonIcon,
                                      fontSize: 15,
                                    ),
                                    value: _discoverable,
                                    activeColor: globalState.theme.button,
                                    onChanged: (bool value) {
                                      if (value == true) {
                                        _setNetworkPublic();
                                      } else {
                                        _publicSet(value);
                                      }
                                    },
                                  ))),
                        ],
                      ),
                      _discoverable == true
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                    //flex: 12,
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10, left: 10),
                                        child: SwitchListTile(
                                          inactiveThumbColor: globalState
                                              .theme.inactiveThumbColor,
                                          inactiveTrackColor: globalState
                                              .theme.inactiveTrackColor,
                                          trackOutlineColor:
                                              MaterialStateProperty.resolveWith(
                                                  globalState.getSwitchColor),
                                          title: ICText(
                                            AppLocalizations.of(context)!
                                                .make18Up,
                                            color: globalState.theme.buttonIcon,
                                            fontSize: 15,
                                          ),
                                          value: _adultOnly,
                                          activeColor: globalState.theme.button,
                                          onChanged: (bool value) {
                                            if (value == true) {
                                              _setNetworkAgeRestricted();
                                            } else {
                                              _ageRestrictedSet(value);
                                            }
                                          },
                                        ))),
                              ],
                            )
                          : Container(),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 10, left: 10),
                                    child: SwitchListTile(
                                        inactiveThumbColor: globalState
                                            .theme.inactiveThumbColor,
                                        inactiveTrackColor: globalState
                                            .theme.inactiveTrackColor,
                                        trackOutlineColor:
                                            MaterialStateProperty.resolveWith(
                                                globalState.getSwitchColor),
                                        title: ICText(
                                          AppLocalizations.of(context)!
                                              .anyoneCirclesInvitesPermissions,
                                          color: globalState.theme.buttonIcon,
                                          fontSize: 15,
                                        ),
                                        value: _memberAutonomy,
                                        activeColor: globalState.theme.button,
                                        onChanged: (bool value) {
                                          if (value == true) {
                                            _setMemberAutonomy();
                                          } else {
                                            _memberAutonomySet(value);
                                          }
                                        })))
                          ]),
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                      ),
                      networkImage,
                      createNewSocialNetwork,
                    ]))))));
  }
  //
  // Future<void> _cropImage() async {
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
  //   }
  // }

  void _createNetwork() async {
    progressDialog = ProgressDialog(context,
        backgroundColor: globalState.theme.dialogTransparentBackground,
        defaultLoadingWidget: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(globalState.theme.button)),
        dialogStyle: DialogStyle(
            backgroundColor: globalState.theme.background, elevation: 0),
        dismissable: false,
        message: Text(
          AppLocalizations.of(context)!.generatingNetwork,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ),
        title: Text(
          AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(color: globalState.theme.labelText),
        ));
    if (_formKey.currentState!.validate() && clicked == false) {
      progressDialog!.show();
      clicked = true;
      try {
        if (_networkName.text.toLowerCase() == "ironforge") {
          progressDialog!.dismiss();
          clicked = false;
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.cannotNameIronForge, "", 2, false);
          return;
        }

        if (localFurnace == null) {
          localFurnace = UserFurnace.initFurnace(
            //url: 'https://ironcirclesforge.herokuapp.com/',
            url: urls.forge,
            apikey: _accessCode.text,
          );

          if (await _userFurnaceBloc.furnaceExists(localFurnace!)) {
            progressDialog!.dismiss();
            clicked = false;
            return;
          } else
            setState(() {});
        }

        bool nameAvailable = false;

        if (_boolSelfHosted) {
          String networkUrl = _networkUrl.text;

          _networkUrl.text = networkUrl.trim();

          if (!networkUrl.endsWith("/")) {
            networkUrl = "$networkUrl/";
          } else if (networkUrl.startsWith("http://")) {
            throw ("Url must contain a cert and use https");
          } else if (!networkUrl.startsWith("https://")) {
            networkUrl = "https://$networkUrl/";
          }

          nameAvailable = await _hostedFurnaceBloc.checkName(networkUrl,
              networkUrl: networkUrl, networkApiKey: _networkApiKey.text);

          localFurnace!.apikey = _networkApiKey.text;
          localFurnace!.url = networkUrl;
          localFurnace!.type = NetworkType.SELF_HOSTED;
        } else {
          nameAvailable = await _hostedFurnaceBloc.checkName(_networkName.text);
          localFurnace!.type = NetworkType.HOSTED;
        }

        //bool nameAvailable = await _hostedFurnaceBloc.checkName(_alias.text);

        if (nameAvailable) {
          localFurnace!.alias = _networkName.text;
          localFurnace!.hostedName = _networkName.text;
          //localFurnace!.type = NetworkType.HOSTED;
          localFurnace!.newNetwork = true;
          localFurnace!.apikey = urls.spinFurnaceAPIKEY;
          localFurnace!.hostedAccessCode = _accessCode.text;
          localFurnace!.authServer = widget.authServer;
          localFurnace!.discoverable = _discoverable;
          localFurnace!.adultOnly = _adultOnly;
          localFurnace!.description = _description.text;
          localFurnace!.memberAutonomy = _memberAutonomy;
          localFurnace!.enableWall = _enableFeed;

          _linkedAccount = false;

          UserFurnace? primaryNetwork;

          ///If the user already has an account on this api, then link them.
          for (UserFurnace userFurnace in widget.userFurnaces) {
            if (userFurnace.url == localFurnace!.url && userFurnace.authServerUserid == userFurnace.userid) {
              primaryNetwork = userFurnace;
              _linkedAccount = true;
              break;
            }
          }

          if (_linkedAccount) {
            localFurnace!.username = primaryNetwork!.username!;
            localFurnace!.password = '';
            localFurnace!.pin = '';

            _userFurnaceBloc.register(
                localFurnace!, null, globalState.user.minor, _linkedAccount,
                fromNetworkManager: true,
                createNetworkName: true,
                primaryNetwork: primaryNetwork,
                image: _image);
          } else {
            if (mounted) {
              progressDialog!.dismiss();
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Registration(
                      source: Source.fromNetworkManager,
                      userFurnace: localFurnace!,
                      //username: _username.text,
                    ),
                  ));
              clicked = false;
            }
          }

          //Navigator.pop(context,);
          //}

          //userFurnaceBloc.update(localFurnace, true);
        } else {
          progressDialog!.dismiss();
          clicked = false;
          if (mounted) {
            FormattedSnackBar.showSnackbarWithContext(context,
                AppLocalizations.of(context)!.networkNameExists, "", 2, false);
          }
        }
      } catch (error, trace) {
        progressDialog!.dismiss();
        clicked = false;
        LogBloc.insertError(error, trace);
        FormattedSnackBar.showSnackbarWithContext(
            context, error.toString(), "", 2, true);
      }
    } else {
      progressDialog!.dismiss();
      clicked = false;
      validatedOnceAlready = true;
    }
  }

  _generate() async {
    _closeKeyboard();

    SelectedMedia? selectedMedia = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StableDiffusionWidget(
            userFurnace: globalState.userFurnace!,
            imageGenType: ImageType.network,
            initialPrompt:
                StableDiffusionPrompt.getNetworkPrompt(_networkName.text)),
      ),
    );

    if (selectedMedia != null) {
      _image = selectedMedia.mediaCollection.media[0].file;
      setState(() {});
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _selectImage() async {
    try {
      ImagePicker imagePicker = ImagePicker();

      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (imageFile != null)
        setState(() {
          _image = File(imageFile.path);
        });
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        //Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }

  Future<void> _setMemberAutonomy() async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.setToOn,
        AppLocalizations.of(context)!.anyoneCirclesInvitesPermissionsDescrip,
        _memberAutonomySet,
        null,
        false);
  }

  _memberAutonomySet([bool autonomy = true]) {
    setState(() {
      _memberAutonomy = autonomy;
      widget.userFurnace.memberAutonomy = autonomy;
    });
    _hostedFurnaceBloc.updateMemberAutonomy(
        widget.userFurnace, _memberAutonomy);
  }

  Future<void> _setNetworkAgeRestricted() async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.setNetworkAgeRestrict,
        AppLocalizations.of(context)!.setNetworkAgeRestrictDescrip,
        _ageRestrictedSet,
        _finish,
        false);
  }

  _ageRestrictedSet([bool adultOnly = true]) {
    setState(() {
      _adultOnly = adultOnly;
    });
  }

  Future<void> _setNetworkPublic() async {
    ///check for image and description
    if (_networkName.text.isNotEmpty &&
        _description.text.isNotEmpty &&
        _image != null) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.setToDiscoverable,
          AppLocalizations.of(context)!.setToDiscoverableDescrip,
          _publicSet,
          _finish,
          false);
    } else {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.needAdditionalInfo,
          AppLocalizations.of(context)!.needAdditionalInfoDescrip,
          false);
    }
  }

  _publicSet([bool public = true]) {
    setState(() {
      _discoverable = public;
    });
  }

  _finish() {
    /// nothing
  }

/*
  void _initListeners() {
    userFurnaceBloc.userFurnace.listen((success) {
      localFurnace = success;

      if (!success!.connected!) {
        FormattedSnackBar.showSnackbarWithContext(context, "Furnace disconnected", "", 1);
        setState(() {});
      }
    }, onError: (err) {
      setState(() {
        localFurnace = null;
      });
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);

      debugPrint("error $err");
    }, cancelOnError: false);

    userFurnaceBloc.removed.listen((success) {
      FormattedSnackBar.showSnackbarWithContext(context, "Furnace removed", "", 2);

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => FurnaceManager(),
          ),
          ModalRoute.withName("/home"));
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);

      debugPrint("error $err");
    }, cancelOnError: false);
  }

 */
}

/*
class FurnaceConnection {
  final UserFurnace userFurnace;
  final User user;

  FurnaceConnection({required this.userFurnace, required this.user});
}

 */
