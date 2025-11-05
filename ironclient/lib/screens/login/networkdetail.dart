import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenimagefromfile.dart';
import 'package:ironcirclesapp/screens/login/login.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_health.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_storage.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/settings/settings_general_transfer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogtwochoiceback.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:provider/provider.dart';

class NetworkDetail extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final Function refreshTabs;
  final Function refreshNetworkManager;

  const NetworkDetail(
      {Key? key,
      required this.userFurnace,
      required this.refreshTabs,
      required this.userFurnaces,
      required this.refreshNetworkManager})
      : super(key: key);

  @override
  FurnaceDetailState createState() => FurnaceDetailState();
}

class FurnaceDetailState extends State<NetworkDetail> {
  final UserBloc _userBloc = UserBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final userFurnaceBloc = UserFurnaceBloc();
  late final GlobalEventBloc _globalEventBloc;
  List _members = [];
  late HostedFurnaceBloc _hostedFurnaceBloc;
  final TextEditingController _description = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _link = TextEditingController();
  bool _showAccessCode = false;

  HostedFurnace? network;
  bool _editingPrivileges = false;

  bool _adultOnly = false;

  bool changed = false;
  late UserFurnace _userFurnace;
  UserFurnace? localFurnace;
  UserFurnace? primaryFurnace;

  bool validatedOnceAlready = false;
  bool _discoverable = false;
  bool _memberAutonomy = false;
  File? _img;
  File? _tempImg;

  bool leaving = false;

  String _originalName = '';
  String _originalCode = '';
  String _originalDescription = '';
  String _originalLink = '';

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  late List<DropDownPair> _dropDownList = [];

  StableDiffusionPrompt stableDiffusionAIParams =
      StableDiffusionPrompt(promptType: PromptType.generate);
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();

  @override
  void initState() {
    _userFurnace = widget.userFurnace;

    if (_userFurnace.linkedUser != null) {
      primaryFurnace = widget.userFurnaces
          .firstWhere((element) => element.userid == _userFurnace.linkedUser);
    }

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _dropDownList = [
        DropDownPair(
            id: BlobLocation.DEVICE_ONLY,
            value: AppLocalizations.of(context)!.hostedByIronCircles),
        //DropDownPair(id: StorageOptions.S3.toString(), value: 'Purchase Storage Upgrade'),
        DropDownPair(
            id: BlobLocation.PRIVATE_S3,
            value: AppLocalizations.of(context)!.useS3Account),
        DropDownPair(
            id: BlobLocation.PRIVATE_WASABI,
            value: AppLocalizations.of(context)!.useWasabiAccount),
      ];
    });

    _hostedFurnaceBloc.memberAutonomyChanged.listen((bool autonomy) {
      setState(() {
        widget.userFurnace.memberAutonomy = autonomy;
        _memberAutonomy = autonomy;
      });
    }, onError: (err) {
      debugPrint("memberAutonomyChanged.listen: error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.wallEnabledChanged.listen((bool wallEnabled) {
      setState(() {
        widget.userFurnace.enableWall = wallEnabled;
      });
    }, onError: (err) {
      debugPrint("wallEnabledChanged.listen: error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.ageRestrictedChanged.listen((bool adultOnly) {
      setState(() {
        _adultOnly = adultOnly;
        widget.userFurnace.adultOnly = adultOnly;
      });
    }, onError: (err) {
      debugPrint("ageRestrictedChanged.listen: error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.updatedFurnace.listen((userFurnace) {
      if (mounted) {
        setState(() {
          _userFurnace.alias = userFurnace.alias;
          _userFurnace.hostedAccessCode = userFurnace.hostedAccessCode;
          _userFurnace.description = userFurnace.description;
          _userFurnace.link = userFurnace.link;
        });

        widget.userFurnace.description = userFurnace.description;
        _originalDescription = userFurnace.description ?? '';
        widget.userFurnace.hostedAccessCode = userFurnace.hostedAccessCode;
        _originalCode = _code.text;
        widget.userFurnace.alias = _name.text;
        _originalName = _name.text;

        ///remove snackbar in case the user is changing multiple fields at once
        /*FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context).updated, "", 2, false);
         */

        ///not sure what this is but it's not used so commented out - JC
        /*if (leaving == true) {
          Navigator.pop(context);
        }*/

        widget.refreshNetworkManager();
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
        _discoverable = false;
      });
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.errorGenericTitle,
          err.toString(),
          true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.lockedOut.listen((member) {
      int index = _members.indexWhere((element) => element.id == member.id);
      if (index != -1) _members[index] = member;
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });
      }

      if (member.lockedOut)
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.lockedOut.toLowerCase(),
            "",
            2,
            false);
      else
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.unlocked.toLowerCase(), "", 2, false);
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.imageChanged.listen((userFurnace) {
      setState(() {
        _img = _tempImg;
      });
      PaintingBinding.instance.imageCache.clear();
      imageCache.clear();
    });

    _hostedFurnaceBloc.imageDownloaded.listen((userFurnace) {
      setState(() {
        _img = File(FileSystemService.returnAnyFurnaceImagePath(
            localFurnace!.userid!)!);
      });
    });

    _hostedFurnaceBloc.members.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    if (localFurnace == null) {
      localFurnace = widget.userFurnace;

      if (FileSystemService.returnAnyFurnaceImagePath(localFurnace!.userid!) !=
          null) {
        setState(() {
          _img = File(FileSystemService.returnAnyFurnaceImagePath(
              localFurnace!.userid!)!);
        });
      }

      //setup();

      if (localFurnace != null) {
        _discoverable = widget.userFurnace.discoverable;
        _memberAutonomy = widget.userFurnace.memberAutonomy;

        _adultOnly = widget.userFurnace.adultOnly;

        widget.userFurnace.description == null
            ? _description.text = ''
            : _description.text = widget.userFurnace.description!;
        _originalDescription = _description.text;

        widget.userFurnace.hostedAccessCode == null
            ? _code.text =
                'IronForge6548987' //localFurnace!.apikey! //Don't show the API key, evar
            : _code.text = localFurnace!.hostedAccessCode!;
        _originalCode = _code.text;

        widget.userFurnace.hostedAccessCode == null
            ? _name.text = widget.userFurnace.alias!
            : _name.text = widget.userFurnace.hostedName!;
        _originalName = _name.text;

        widget.userFurnace.link == null
            ? _link.text = ''
            : _link.text = widget.userFurnace.link!;
        _originalLink = _link.text;

        if (localFurnace!.connected! && widget.userFurnace.role == Role.OWNER ||
            widget.userFurnace.role == Role.ADMIN ||
            widget.userFurnace.role == Role.IC_ADMIN) {
          _editingPrivileges = true;
        }
      }
    }

    _initListeners();

    if (localFurnace!.role == Role.OWNER ||
        localFurnace!.role == Role.ADMIN ||
        localFurnace!.role == Role.IC_ADMIN) {
      _hostedFurnaceBloc.getMembers(localFurnace!);
      _showSpinner = true;
    }

    super.initState();
  }

  @override
  void dispose() {
    userFurnaceBloc.dispose();
    _description.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final networkImage = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(children: [
                InkWell(
                    onTap: () async {
                      // if (_editingPrivileges) {
                      //   File? cropped =
                      //       await ImageUtil.cropImage(context, _img);
                      //   if (cropped != null) {
                      //     setState(() {
                      //       _img = cropped;
                      //     });
                      //   }
                      // } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageFile(
                                file: _img!,
                              ),
                            ));
                     // }
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
                                child: _img != null
                                    ? Image.file(_img!, fit: BoxFit.cover)
                                    : Image.asset(
                                        'assets/images/ios_icon.png',
                                        fit: BoxFit.cover,
                                      ))))),
              ]),
              const Padding(
                padding: EdgeInsets.only(
                  right: 5,
                ),
              ),
              _editingPrivileges
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GradientButtonDynamic(
                                  text: AppLocalizations.of(context)!
                                      .generateImage,
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
                              text: AppLocalizations.of(context)!
                                  .selectFromDevice,
                              fontSize: 14,
                              color: globalState.theme.buttonGenerate,
                              onPressed: () async {
                                _tempImg = await ImageUtil.selectImage(context);
                                _setImage();
                                setState(() {});
                              },
                            ),
                          ]),
                        ])
                  : Container()
            ]));

    final makeBody = Container(
        // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
        padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 10),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: WrapperWidget(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                    networkImage,
                    Padding(
                        padding:
                            const EdgeInsets.only(top: 20, bottom: 0, right: 0),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                  child: Focus(
                                child: FormattedText(
                                    labelText: AppLocalizations.of(context)!
                                        .networkName,
                                    readOnly: _editingPrivileges == true
                                        ? false
                                        : true,
                                    controller: _name,
                                    maxLength: 50,
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
                                    }),
                                onFocusChange: (hasFocus) async {
                                  if (hasFocus == false) {
                                    if (_formKey.currentState!.validate()) {
                                      if (_name.text != _originalName) {
                                        setState(() {});

                                        widget.userFurnace.alias = _name.text;

                                        await _hostedFurnaceBloc.updateText(
                                          widget.userFurnace,
                                          description: null,
                                          name: _name.text,
                                          accessCode: null,
                                          link: null,
                                        );

                                        widget.refreshNetworkManager();

                                        _originalName = _name.text;
                                      }
                                    }
                                  }
                                },
                              ))
                            ])),
                    Padding(
                        padding: EdgeInsets.only(
                            top: 0,
                            bottom: widget.userFurnace.type !=
                                    NetworkType.SELF_HOSTED
                                ? 10
                                : 0,
                            right: 0),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                  child: widget.userFurnace.linkedUser == null
                                      ? ICText(AppLocalizations.of(context)!
                                          .primaryNetwork)
                                      : ICText(
                                          '${AppLocalizations.of(context)!.linkedNetwork} ${primaryFurnace == null ? '' : primaryFurnace!.alias!}')),
                              // widget.userFurnace.linkedUser == null && widget.userFurnace.authServer == false
                              //     ? TextButton(
                              //         onPressed: _linkAccount,
                              //         child:  ICText(AppLocalizations.of(context)!.linkAccount),
                              //       )
                              //     : Container()
                            ])),
                    widget.userFurnace.type == NetworkType.SELF_HOSTED
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 20, right: 0),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  const ICText("Network URL: "),
                                  Expanded(
                                      child: SelectableText(
                                          widget.userFurnace.url!,
                                          style: TextStyle(
                                              color: globalState.theme.button,
                                              fontSize: 16 -
                                                  globalState
                                                      .scaleDownTextFont)))
                                ]))
                        : Container(),
                    widget.userFurnace.memberAutonomy == false &&
                            widget.userFurnace.role == Role.MEMBER
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 0, left: 0),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                      child: Focus(
                                          child: FormattedText(
                                              labelText:
                                                  AppLocalizations.of(context)!
                                                      .accessCode,
                                              readOnly: widget.userFurnace
                                                              .role ==
                                                          Role.OWNER ||
                                                      widget.userFurnace.role ==
                                                          Role.ADMIN
                                                  ? false
                                                  : true,
                                              obscureText: !_showAccessCode,
                                              controller: _code,
                                              validator: (value) {
                                                if (value
                                                    .toString()
                                                    .endsWith(' ')) {
                                                  return AppLocalizations.of(
                                                          context)!
                                                      .errorCannotEndWithASpace;
                                                } else if (value
                                                        .toString()
                                                        .length <
                                                    6) {
                                                  return AppLocalizations.of(
                                                          context)!
                                                      .mustBeAtLeast6Chars;
                                                } else if (value
                                                    .toString()
                                                    .startsWith(' ')) {
                                                  return AppLocalizations.of(
                                                          context)!
                                                      .errorCannotStartWithASpace;
                                                }
                                                return null;
                                              }),
                                          onFocusChange: (hasFocus) async {
                                            if (hasFocus == false) {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                if (_code.text !=
                                                    _originalCode) {
                                                  await _hostedFurnaceBloc
                                                      .updateText(
                                                    widget.userFurnace,
                                                    description: null,
                                                    name: null,
                                                    accessCode: _code.text,
                                                    link: null,
                                                  );

                                                  _originalCode = _code.text;
                                                }
                                              }
                                            }
                                            return;
                                          })),
                                  IconButton(
                                      icon: Icon(Icons.remove_red_eye,
                                          color: _showAccessCode
                                              ? globalState.theme.buttonIcon
                                              : globalState
                                                  .theme.buttonDisabled),
                                      onPressed: () {
                                        setState(() {
                                          _showAccessCode = !_showAccessCode;
                                        });
                                      })
                                ])),
                    Padding(
                        padding: EdgeInsets.only(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            top: widget.userFurnace.memberAutonomy == false &&
                                    widget.userFurnace.role == Role.MEMBER
                                ? 10
                                : 25),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Focus(
                                  child: ExpandingText(
                                      capitals: true,
                                      labelText: AppLocalizations.of(context)!
                                          .description
                                          .toLowerCase(),
                                      maxLength: 3000,
                                      height: 300,
                                      controller: _description,
                                      readOnly: _editingPrivileges == true
                                          ? false
                                          : true,
                                      validator: (value) {
                                        return null;
                                      }),
                                  onFocusChange: (hasFocus) async {
                                    if (hasFocus == false) {
                                      String newText = _description.text.trim();
                                      _description.text = newText;
                                      if (newText != _originalDescription) {
                                        await _hostedFurnaceBloc.updateText(
                                          widget.userFurnace,
                                          description: newText,
                                          name: null,
                                          accessCode: null,
                                          link: null,
                                        );
                                      }
                                    }
                                  },
                                ),
                              )
                            ])),

                    ///removing link from build until it's linkable (clickable)
                    /*Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8, left: 0, right: 0, top: 0),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Focus(
                                  child: ExpandingText(
                                      labelText: 'link',
                                      height: 300,
                                      controller: _link,
                                      readOnly: _editingPrivileges == true
                                          ? false
                                          : true,
                                      validator: (value) {
                                        if (value.toString().startsWith(' ')) {
                                          return 'cannot start with a space';
                                        }

                                        return null;
                                      }),
                                  onFocusChange: (hasFocus) async {
                                    if (hasFocus == false) {
                                      if (_link.text != _originalLink) {
                                        await _hostedFurnaceBloc.updateText(
                                          widget.userFurnace,
                                          description: null,
                                          name: null,
                                          accessCode: null,
                                          link: _link.text,
                                        );
                                        _originalLink = _link.text;
                                      }
                                    }
                                  },
                                ),
                              )
                            ])),*/
                    _editingPrivileges == true
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Expanded(
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
                                              .enableFeed,
                                          color: globalState.theme.buttonIcon,
                                          fontSize: 15,
                                        ),
                                        value: widget.userFurnace.enableWall,
                                        activeColor: globalState.theme.button,
                                        onChanged: (bool value) {
                                          if (value == true) {
                                            _askEnableWall(value);
                                          } else {
                                            _enableWallSet(value);
                                          }
                                        }))
                              ])
                        : Container(),
                    _editingPrivileges == true
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Expanded(
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
                                              .makeNetworkDiscoverable,
                                          color: globalState.theme.buttonIcon,
                                          fontSize: 15,
                                        ),
                                        value: _discoverable,
                                        activeColor: globalState.theme.button,
                                        onChanged: (bool value) {
                                          if (value == true) {
                                            _setNetworkDiscoverable();
                                          } else {
                                            _discoverableSet(value);
                                          }
                                        }))
                              ])
                        : Container(),
                    _editingPrivileges == true &&
                            _discoverable == true &&
                            globalState.user.minor == false
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Expanded(
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
                                        }))
                              ])
                        : Container(),
                    _editingPrivileges == true
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Expanded(
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
                                            fontSize: 15),
                                        value: _memberAutonomy,
                                        activeColor: globalState.theme.button,
                                        onChanged: (bool value) {
                                          if (value == true) {
                                            _setMemberAutonomy();
                                          } else {
                                            _memberAutonomySet(value);
                                          }
                                        }))
                              ])
                        : Container(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                    ),
                    widget.userFurnace.connected!
                        ? widget.userFurnace.alias!
                                .toLowerCase()
                                .contains('ironforge')
                            ? Container()
                            : (widget.userFurnace.role == Role.OWNER ||
                                    widget.userFurnace.role == Role.ADMIN)
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                        right: 10, left: 10),
                                    child: InkWell(
                                        onTap: () {
                                          _showStorageOptions();
                                        },
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Expanded(
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                          color: globalState
                                                              .theme
                                                              .menuBackground,
                                                          border: Border.all(
                                                              color: Colors
                                                                  .lightBlueAccent
                                                                  .withOpacity(
                                                                      0.1),
                                                              width: 2.0),
                                                          borderRadius:
                                                              const BorderRadius.all(
                                                                  Radius.circular(
                                                                      12.0))),
                                                      padding: const EdgeInsets.only(
                                                          top: 10,
                                                          bottom: 10,
                                                          left: 15,
                                                          right: 10),
                                                      child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                                AppLocalizations.of(
                                                                        context)!
                                                                    .viewStorageOptions,
                                                                textScaler:
                                                                    const TextScaler
                                                                        .linear(
                                                                        1.0),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16 -
                                                                      globalState
                                                                          .scaleDownTextFont,
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
                                                          ])))
                                            ])))
                                : Container()
                        : Container(),

                    /* const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: Divider(
                          color: Colors.grey,
                          height: 2,
                          thickness: 2,
                          indent: 0,
                          endIndent: 0,
                        )),
                    Row(
                      children: [
                        GradientButton(
                          width: 225,
                          height: 37,
                          text: 'view network members',
                          onPressed: _showNetworkMembers,
                        ),
                      ],
                    ),*/

                    /*  const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                    ),
                    Row(
                      children: [
                        GradientButton(
                          width: 225,
                          height: 37,
                          onPressed: _showNetworkHealth,
                          text: 'view network health',
                        ),
                      ],
                    ),

                   */
                  ]))),
        ));

    final makeBottom = SizedBox(
      height: 55.0,
      width: globalState.isDesktop()
          ? ScreenSizes.getMaxButtonWidth(width, true) * 2
          : double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(flex: 20, child: _showDelete()),
          const Spacer(flex: 1),
          Expanded(
            flex: 20,
            child: GradientButton(
                text: _isConnected()!
                    ? AppLocalizations.of(context)!.disconnect.toUpperCase()
                    : AppLocalizations.of(context)!.connect.toUpperCase(),
                onPressed: () {
                  if (_isAuthServer()!)
                    FormattedSnackBar.showSnackbarWithContext(
                        context,
                        AppLocalizations.of(context)!
                            .cannotDisconnectFromAuthorizationNetwork,
                        "",
                        3,
                        false);
                  else if (_isConnected()!)
                    _disconnect();
                  else
                    _connect();
                }),
          )
        ]),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            // appBar: topAppBar,
            body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: true,
              child: SingleChildScrollView(
                  child: Column(
                children: <Widget>[
                  //Expanded(
                  makeBody,
                  /*const Divider(
                    color: Colors.grey,
                    height: 2,
                    thickness: 2,
                    indent: 0,
                    endIndent: 0,
                  ),*/
                  Container(
                    //  color: Colors.white,
                    padding: const EdgeInsets.only(top: 10.0),
                    child: makeBottom,
                  ),
                ],
              )),
            )));
  }

  /*setup() async {
    _hostedFurnaceBloc.initiateBloc(_globalEventBloc);
    network = await _hostedFurnaceBloc.getHostedFurnace(localFurnace);

    if (network != null) {
      if (network!.hostedFurnaceImage != null) {
        if (!FileSystemService.furnaceImageExistsSync(
            localFurnace!.userid, network!.hostedFurnaceImage)) {
          _hostedFurnaceBloc.downloadImage(
              _globalEventBloc, localFurnace!, network!);
        }
      }
    }

    if (FileSystemService.returnAnyFurnaceImagePath(localFurnace!.userid!) !=
        null) {
      setState(() {
        _img = File(FileSystemService.returnAnyFurnaceImagePath(
            localFurnace!.userid!)!);
      });
    }
  }*/

  bool? _isAuthServer() {
    if (localFurnace == null)
      return false;
    else
      return localFurnace!.authServer;
  }

  bool? _isConnected() {
    if (localFurnace == null)
      return false;
    else
      return localFurnace!.connected;
  }

  //
  // Future<void> _cropImage() async {
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: _img!.path,
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
  //       _tempImg = File(croppedFile.path);
  //       //state = AppState.cropped;
  //     });
  //     _setImage();
  //   }
  // }

  _setImage() async {
    _hostedFurnaceBloc.updateImage(widget.userFurnace, _tempImg!);

    FormattedSnackBar.showSnackbarWithContext(
        context,
        AppLocalizations.of(context)!.updatingNetworkImage.toLowerCase(),
        "",
        1,
        false);
  }

  _selectImage() async {
    try {
      ImagePicker imagePicker = ImagePicker();

      var imageFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (imageFile != null) {
        setState(() {
          _img = File(imageFile.path);
        });
        _setImage();
      }
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        //Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }
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
    _hostedFurnaceBloc.updateAgeRestricted(widget.userFurnace, adultOnly);
  }

  Future<void> _askEnableWall(bool value) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.betaFeatureTitle,
        AppLocalizations.of(context)!.enableFeedDescrip,
        _enableWallSet,
        null,
        false,
        value);
  }

  _enableWallSet(bool value) {
    setState(() {
      widget.refreshNetworkManager();
      _hostedFurnaceBloc.updateEnableWall(widget.userFurnace, value);
    });
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
    _hostedFurnaceBloc.updateMemberAutonomy(widget.userFurnace, autonomy);
  }

  Future<void> _setNetworkDiscoverable() async {
    ///check for image and description
    if (_name.text.isNotEmpty && _description.text.isNotEmpty && _img != null) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.setToDiscoverable,
          AppLocalizations.of(context)!.setToDiscoverableDescrip,
          _discoverableSet,
          null,
          false);
    } else {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.needAdditionalInfo,
          AppLocalizations.of(context)!.needAdditionalInfoDescrip,
          false);
    }
  }

  _discoverableSet([bool discoverable = true]) {
    _discoverable = discoverable;
    _hostedFurnaceBloc.updateDiscoverable(widget.userFurnace, _discoverable);
  }

  _finish() {
    /// nothing
  }

  void _deleteAccount() async {
    List<User> members =
        await _userBloc.deleteAccount(widget.userFurnace, null);

    if (members.isNotEmpty && mounted) {
      String? transferUserID = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsGeneralTransfer(
              userFurnace: widget.userFurnace,
              members: members,
            ),
          ));

      if (transferUserID != null)
        await _userBloc.deleteAccount(widget.userFurnace, transferUserID);

      if (widget.userFurnace.authServer! == false && mounted) {
        Navigator.pop(context);
      }
    } else {
      if (widget.userFurnace.authServer! == false) {
        await _userBloc.deleteAccount(widget.userFurnace, null);
        if (mounted) {
          //Navigator.pop(context);
        }
      }
    }
  }

  Widget _showDelete() {
    if (localFurnace == null || localFurnace!.pk == null)
      return Container();
    else {
      return GradientButton(
          text: AppLocalizations.of(context)!.delete,
          onPressed: () {
            DialogTwoChoiceBack.askTwoChoice(
                context,
                AppLocalizations.of(context)!.deleteAccountOrRemove,
                AppLocalizations.of(context)!.deleteAccountOrRemoveLine1,
                AppLocalizations.of(context)!.deleteAccountOrRemoveLine2,
                _deleteAccount,
                _remove);
          });
    }
  }

  void _remove() async {
    try {
      if (localFurnace!.authServer!) {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.cannotRemoveAuthorizationNetwork,
            "",
            2,
            false);
      } else
        await userFurnaceBloc.remove(localFurnace!);
      _globalEventBloc.broadcastRefreshHome();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  void _connect() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (await _hostedFurnaceBloc
            .checkIfAlreadyOnNetwork(localFurnace!.alias!)) {
          if (mounted) {
            DialogNotice.showNoticeOptionalLines(
                context,
                AppLocalizations.of(context)!.alreadyConnectedTitle,
                AppLocalizations.of(context)!.alreadyConnectedMessage,
                false);
          }

          return;
        } else {
          bool canAddNetwork = await PremiumFeatureCheck.canAddNetwork(
              context, widget.userFurnaces);

          if (canAddNetwork) {
            if (localFurnace!.linkedUser != null) {
              ///separate try because the errors are already localized
              try {
                await userFurnaceBloc.reconnectLinkedAccount(
                    context, localFurnace!);
                localFurnace!.connected = true;
                setState(() {});
              } catch (err) {
                FormattedSnackBar.showSnackbarWithContext(
                    context, err.toString(), "", 2, false);
              }
            } else {
              if (mounted) {
                var furnaceConnection = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(
                        username: localFurnace!.username,
                        userFurnace: localFurnace!,
                        allowChangeUser: false,
                        fromFurnaceManager: true,
                      ),
                    ));

                if (furnaceConnection != null) {
                  setState(() {
                    localFurnace = furnaceConnection.userFurnace;
                  });

                  _refresh(localFurnace);
                }
              }
            }
          }
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        FormattedSnackBar.showSnackbarWithContext(
            context, error.toString(), "", 2, true);
      }
    }
  }

  _refresh(UserFurnace? userFurnace) {
    try {} catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'FurnaceDetail._refresh: Stupid parent widget function became null again.  $err');
    }
  }

  void _disconnect() async {
    try {
      await userFurnaceBloc.connect(localFurnace, false, false);

      _globalEventBloc.broadcastRefreshHome();

      if (globalState.lastSelectedFilter == localFurnace!.alias) {
        globalState.lastSelectedFilter = null;
      }

      setState(() {
        localFurnace!.connected = false;
      });

      //_refresh(localFurnace);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  void _initListeners() {
    _hostedFurnaceBloc.updated.listen((hostedFurnaceUpdatedType) async {
      if (hostedFurnaceUpdatedType == HostedFurnaceUpdatedType.discoverable) {
        setState(() {
          widget.userFurnace.discoverable = _discoverable;
        });
      }
    }, onError: (err) {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.errorGenericTitle,
          err.toString().replaceFirst("Exception: ", ""),
          false);

      setState(() {
        _discoverable = !_discoverable;
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _hostedFurnaceBloc.magicLink.listen((magicLink) async {
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });

        globalState.lastCreatedMagicLink = magicLink;

        ///TODO MERGE DialogShareMagicLink.shareToPopup(context, magicLink, _shareHandler);
      }
    }, onError: (err) {
      debugPrint("error $err");

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    userFurnaceBloc.userFurnace.listen((success) {
      localFurnace = success;

      if (!success!.connected!) {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.networkDisconnected, "", 1, false);
        setState(() {});
      }
    }, onError: (err) {
      setState(() {
        localFurnace = null;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    userFurnaceBloc.removed.listen((success) {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.networkRemoved, "", 2, false);

      Navigator.pop(context);

      /*Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => FurnaceManager(),
          ),
          ModalRoute.withName("/home"));

       */
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);
  }

  // _shareHandler(BuildContext context, String magicLink, bool inside) {
  //   if (inside)
  //     _globalEventBloc.shareText(magicLink);
  //   else
  //     Share.share(magicLink);
  // }

  _showNetworkHealth() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkDetailHealth(),
        ));
  }

  _showStorageOptions() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkDetailStorage(
            hostedFurnaceBloc: _hostedFurnaceBloc,
            userFurnace: widget.userFurnace,
            dropDownList: _dropDownList,
          ),
        ));
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
            imageGenType: ImageType.network,
            initialPrompt: StableDiffusionPrompt.getNetworkPrompt(_name.text)),
      ),
    );

    if (selectedMedia != null) {
      _tempImg = selectedMedia.mediaCollection.media[0].file;
      setState(() {});
      _setImage();
    }
  }

  // _linkAccount() {
  //   ///make sure the accounts are on the same api
  //   if (globalState.userFurnace!.url != widget.userFurnace.url) {
  //     FormattedSnackBar.showSnackbarWithContext(context,
  //         AppLocalizations.of(context)!.cannotLinkDifferentAPI, "", 2, false);
  //     return;
  //   }
  //
  //   userFurnaceBloc.linkAccount(widget.userFurnace);
  // }
}

class FurnaceConnection {
  final UserFurnace userFurnace;
  final User user;

  FurnaceConnection({required this.userFurnace, required this.user});
}
