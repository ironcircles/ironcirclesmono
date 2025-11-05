///This class is only called from JoinFriends now, lots of this code has been replaced

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

enum RegistrationShortCaller {
  applink,
  join_friends,
  network_manager,
  new_network
}

class RegistrationShort extends StatefulWidget {
  final String? toast;
  final RegistrationShortCaller caller;
  final UserFurnace? appLinkNetwork;
  final List<UserFurnace>? userFurnaces;

  final bool linkedAccount;
  final HostedInvitation? hostedInvitation;
  final bool fromNetworkManager;

  const RegistrationShort(
      {Key? key,
      this.toast,
      required this.caller,
      this.appLinkNetwork,
      required this.linkedAccount,
      this.fromNetworkManager = false,
      this.userFurnaces,
      this.hostedInvitation})
      : super(key: key);

  @override
  _FurnaceRegisterState createState() {
    return _FurnaceRegisterState();
  }
}

class _FurnaceRegisterState extends State<RegistrationShort> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _networkName = TextEditingController();
  final TextEditingController _accessCode = TextEditingController();
  final TextEditingController _networkUrl = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late FirebaseBloc _firebaseBloc;
  final databaseBloc = DatabaseBloc();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  String assigned = '';
  String? _toast;
  bool _showSpinner = false;
  bool _oldEnough = true;
  int? _radioValue = 1;
  bool _tos = true;
  bool validatedOnceAlready = false;
  static const double _iconPadding = 10;
  int _initialIndex = 0;
  bool _boolSelfHosted = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (Route<dynamic> route) => false,
      arguments: globalState.user,
    );
  }

  @override
  void initState() {
    //LogBloc.postLog('User opened screen', 'RegShort');

    if (kDebugMode && !Urls.testingReleaseMode) {
      _username.text = 'maven${SecureRandomGenerator.generateInt(max: 5)}';

      //_networkName.text = '${_username.text}\'s network';
      _networkName.text = 'easynetwork';
      _networkUrl.text = "https://ironfurny.herokuapp.com/";
      _accessCode.text = "easynetwork";
    }

    _radioValue = 2;
    _oldEnough = true;
    _tos = true;

    // if (widget.caller == RegistrationShortCaller.join_friends){
    //   _username.text = globalState.userFurnace.username!.username!;
    // }

    if (widget.appLinkNetwork != null) {
      _networkName.text = widget.appLinkNetwork!.alias!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    super.initState();

    globalState.globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;

    _userFurnaceBloc.userFurnace.listen((success) {
      if (widget.fromNetworkManager == false &&
          (widget.caller == RegistrationShortCaller.new_network ||
              widget.caller == RegistrationShortCaller.join_friends ||
              widget.caller == RegistrationShortCaller.applink)) {
        globalState.showHomeTutorial = true;
        globalState.showPrivateVaultPrompt = true;
      }

      _goHome();
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      LogBloc.postLog('Error:$err', 'RegistrationShort');

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(context, 'Username already exists',
            'Please select a different username', null, null, null, false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(context, 'Username is reserved',
            'Please select a different username', null, null, null, false);
      } else if (err.toString().contains('unauthorized')) {
        DialogNotice.showNotice(context, 'Please try again',
            'Network name or access code invalid', null, null, null, false);
      } else if (err.toString().toLowerCase().contains('failed last attempt')) {
        DialogNotice.showNotice(
            context,
            'Failed Last Attempt',
            'You can no longer try to join this network',
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('exceeded')) {
        DialogNotice.showNotice(context, 'Exceeded Allowed Attempts',
            'You cannot try to join this network', null, null, null, false);
      } else if (err.toString().contains('wait')) {
        String trimmedMessage =
            " ${err.message.toString().substring(4, err.message.toString().length)}";
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.joinWait1 +
                trimmedMessage +
                AppLocalizations.of(context)!.joinWait2,
            "",
            2,
            false);
      } else {
        DialogNotice.showNotice(
            context,
            'Please try again',
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            true);
      }

      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    if (widget.toast != null) _toast = widget.toast;
  }

  _showToast(BuildContext context) {
    if (_toast != null) {
      FormattedSnackBar.showSnackbarWithContext(
          context, widget.toast!, "", 2, true);
      _toast = null;
    }
  }

  @override
  void dispose() {
    _username.dispose();

    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double textScale = MediaQuery.textScalerOf(context).scale(1);

    Widget _ageWidgets(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 0, left: 15, right: 10, bottom: 0),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 10, top: 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ICText(
                      AppLocalizations.of(context)!.age, //"Age:  ",
                      color: globalState.theme.dialogLabel,
                      fontSize: 12,
                    ),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              fillColor: MaterialStateProperty.resolveWith(
                                  globalState.getRadioColor),
                              activeColor: globalState.theme.dialogButtons,
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    Expanded(
                        child: InkWell(
                            onTap: () {
                              _handleRadioValueChange(1);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: ICText("16-17",
                                  fontSize: 12,
                                  color: globalState.theme.dialogLabel),
                            ))),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              fillColor: MaterialStateProperty.resolveWith(
                                  globalState.getRadioColor),
                              activeColor: globalState.theme.dialogButtons,
                              value: 2,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    Expanded(
                        child: InkWell(
                            onTap: () {
                              _handleRadioValueChange(2);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: ICText("18+",
                                  fontSize: 12,
                                  color: globalState.theme.dialogLabel),
                            ))),
                    const Spacer()
                  ])),
          const Padding(
            padding: EdgeInsets.only(bottom: 0),
          ),
        ]),
      );
    }

    final tos = Padding(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 0),
      child: Column(children: [
        Row(children: <Widget>[
          Theme(
            data: ThemeData(
                unselectedWidgetColor: globalState.theme.checkUnchecked),
            child: Checkbox(
              activeColor: globalState.theme.buttonIcon,
              checkColor: globalState.theme.checkBoxCheck,
              value: _tos,
              onChanged: (newValue) {
                setState(() {
                  _tos = newValue!;
                  //_scrollBottom();
                });
              },
            ),
          ),
          ICText(
            AppLocalizations.of(context)!.iAgree, //'I agree:  ',
            fontSize: 12,
          ),
          Expanded(
              child: InkWell(
            onTap: _showTOS,
            child: ICText(AppLocalizations.of(context)!.termsOfService,
                color: globalState.theme.buttonIcon, fontSize: 12),
          ))
        ]),
      ]),
    );

    final desktopNextButton = Padding(
      padding: const EdgeInsets.only(left: 0, right: 10, top: 10, bottom: 12),
      child: Row(children: <Widget>[
        const Spacer(),
        SizedBox(
            height: 55,
            width: 300,
            child: GradientButton(
              text: AppLocalizations.of(context)!.next,
              // widget.caller == RegistrationShortCaller.new_network
              //   ? 'Generate Encrypted Network'
              //   : AppLocalizations.of(context)!.next,
              onPressed: _register,
            )),
      ]),
    );

    final nextButton = SizedBox(
      height: 125.0,
      child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                child: GradientButton(
                  text: widget.caller == RegistrationShortCaller.new_network
                      ? 'Generate Encrypted Network'
                      : AppLocalizations.of(context)!
                          .joinNetwork, //'Join Network',
                  onPressed: _register,
                ),
              )
            ]),
          ])),
    );

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                child: WrapperWidget(
                  child: Column(children: <Widget>[
                    widget.caller == RegistrationShortCaller.applink
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 25, top: 0, bottom: 10, right: 15),
                            child: Row(children: <Widget>[
                              const ICText(
                                'Network name: ',
                                fontSize: 16,
                              ),
                              Expanded(
                                child: ICText(
                                  widget.appLinkNetwork!.alias!,
                                  color: globalState.theme.buttonIcon,
                                  fontSize: 16,
                                ),
                              ),
                            ]))
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 0, bottom: 0, right: 15),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: FormattedText(
                                  //hintText: 'Enter a name for your network',
                                  controller: _networkName,
                                  maxLength: 50,
                                  labelText: widget.caller ==
                                          RegistrationShortCaller.new_network
                                      ? AppLocalizations.of(context)!
                                          .enterANetworkName //'Enter a name for your network'
                                      : AppLocalizations.of(context)!
                                          .enterNetworkName, //'enter network name',
                                  maxLines: 1,
                                  onChanged: _revalidate,
                                  validator: (value) {
                                    if (value.toString().endsWith(' ')) {
                                      return 'cannot end with a space';
                                    } else if (value.toString().isEmpty) {
                                      return 'cannot be empty';
                                    } else if (value
                                        .toString()
                                        .startsWith(' ')) {
                                      return 'cannot start with a space';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ])),
                    widget.caller == RegistrationShortCaller.join_friends
                        ? Align(
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
                            ))
                        : Container(),
                    widget.caller == RegistrationShortCaller.join_friends &&
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
                                      'Network URL', //'enter network name',
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
                        : const Padding(padding: EdgeInsets.only(top: 15)),
                    widget.caller == RegistrationShortCaller.join_friends
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10, right: 15),
                            child: FormattedText(
                              controller: _accessCode,
                              labelText: AppLocalizations.of(context)!
                                  .enterAccessCode6, //'enter access code (6+)',
                              maxLength: 25,
                              onChanged: _revalidate,
                              validator: (value) {
                                if (value.toString().endsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotEndWithASpace;
                                } else if (value.toString().length < 6) {
                                  return AppLocalizations.of(context)!
                                      .mustBeAtLeast6Chars;
                                } else if (value.toString().startsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotStartWithASpace;
                                }

                                return null;
                              },
                            ),
                          )
                        : Container(),
                    widget.caller == RegistrationShortCaller.join_friends
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 0, bottom: 10, right: 15),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: FormattedText(
                                  controller: _username,
                                  maxLength: 25,
                                  labelText: AppLocalizations.of(context)!
                                      .createYourUsername, //'Create your username',
                                  maxLines: 1,
                                  onChanged: _revalidate,
                                  validator: (value) {
                                    if (value.toString().endsWith(' ')) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotEndWithASpace;
                                    } else if (value.toString().isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotBeEmpty;
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
                            ]),
                          ),
                    widget.caller == RegistrationShortCaller.join_friends
                        ? Container() :  tos,
                    widget.caller == RegistrationShortCaller.join_friends
                        ? Container() :  _ageWidgets(context),
                    Platform.isMacOS || Platform.isWindows || Platform.isLinux
                        ? desktopNextButton // inside the body
                        : nextButton
                  ]),
                ))));

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
            title: widget.caller == RegistrationShortCaller.new_network
                ? AppLocalizations.of(context)!
                    .generateYourSocialNetwork //'Generate Your Social Network'
                : "${AppLocalizations.of(context)!.whichNetwork}?", //'Join Friend\'s Network',
            actions: <Widget>[
              IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  DialogNotice.showLandingFriendHelp(context);
                },
                icon: Icon(Icons.help, color: globalState.theme.menuIcons),
              )
            ]),
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
                    const Padding(padding: EdgeInsets.only(bottom: 5)),
                    Expanded(
                      child: makeBody,
                    ),
                    /*new Container(
                    padding: EdgeInsets.all(0.0),
                    child: makeBottom,
                  ),

                   */
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            )),
      ),
    );
  }

  _handleRadioValueChange(int? value) {
    setState(() {
      _radioValue = value;
      _oldEnough = true;
    });
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (mounted)
          setState(() {
            if (globalState.user.username != null) {
              _username.text = globalState.user.username!;
            }
          });
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _showTOS() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsOfService(
            readOnly: true,
          ),
        ));
  }

  void _register() async {
    try {
      if (_formKey.currentState!.validate()) {
        if (_showSpinner == true)
          return;
        else
          _showSpinner = true;

        //globalState.userSetting.setFirstTimeInCircle(false);
        //globalState.userSetting.setAskedToGuardVault(false);

        if (_networkName.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.enterANetworkName,
              "",
              2,
              false); //'please enter a name for your network', "", 2,  false);
          _showSpinner = false;
        } else if (_networkName.text.trim().toLowerCase() == 'ironforge' &&
            (widget.caller != RegistrationShortCaller.join_friends &&
                widget.caller != RegistrationShortCaller.applink)) {
          DialogNotice.showNoticeOptionalLines(
              context,
              AppLocalizations.of(context)!.nameInUse, //'Name in use',
              AppLocalizations.of(context)!.networkNameInUse,
              false); //'The network name you selected is already in use. Please choose a different name.', false);

          _showSpinner = false;
        } else if (_username.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.pleaseEnterAUsername, "", 2, false);
          _showSpinner = false;
        } else if (_tos == false) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.acceptTermsOfService, "", 2, false);
          _showSpinner = false;
        } else if (!_oldEnough) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.selectAgeOption, "", 2, false);
          _showSpinner = false;
        } else {
          FocusScope.of(context).requestFocus(FocusNode());

          setState(() {
            _showSpinner = true;
          });

          if (widget.caller == RegistrationShortCaller.new_network) {
            _userFurnaceBloc.generateNetwork(
                _networkName.text, _username.text, _radioValue == 1);
          } else if (widget.caller == RegistrationShortCaller.applink) {
            UserFurnace _userFurnace =
                _userFurnaceBloc.prepUserFurnaceForRegistration(
                    widget.appLinkNetwork!, _username.text);

            _userFurnaceBloc.register(_userFurnace, null,
                globalState.user.minor, widget.linkedAccount,
                inviter: widget.hostedInvitation!.inviter,
                hostedInvitation: widget.hostedInvitation,
                primaryNetwork: globalState.userFurnace);
          } else if (widget.caller == RegistrationShortCaller.join_friends) {
            UserFurnace userFurnace = UserFurnace(
                alias: _networkName.text, hostedName: _networkName.text);

            if (_networkName.text.toLowerCase() == IRONFORGE.toLowerCase()) {
              userFurnace.hostedName = '';
              userFurnace.type = NetworkType.FORGE;
              userFurnace.alias = 'IronForge';
              userFurnace.url = urls.forge;
              userFurnace.apikey = urls.forgeAPIKEY;
            } else if (_boolSelfHosted) {
              userFurnace.newNetwork = false;
              userFurnace.type = NetworkType.SELF_HOSTED;
              userFurnace.hostedAccessCode = _accessCode.text;
              userFurnace.url = _networkUrl.text;
              userFurnace.apikey = _accessCode.text;
            } else {
              userFurnace.type = NetworkType.HOSTED;
              userFurnace.hostedAccessCode = _accessCode.text;
              userFurnace.url = urls.spinFurnace;
              userFurnace.apikey = urls.spinFurnaceAPIKEY;
            }

            bool linkedAccount = false;
            UserFurnace? primaryNetwork;
            if (widget.fromNetworkManager) {
              userFurnace.authServer = false;

              ///If the user already has an account on this api, then link them.
              for (UserFurnace network in widget.userFurnaces!) {
                if (network.url == userFurnace.url &&
                    network.authServerUserid == network.userid) {
                  primaryNetwork = network;
                  linkedAccount = true;
                  break;
                }
              }
            } else {
              userFurnace.authServer = true;
            }

            if (linkedAccount) {
              userFurnace.username == _username.text;
              // userFurnace!.username = primaryNetwork!.username!;
              userFurnace!.password = '';
              userFurnace!.pin = '';
            }

            userFurnace = _userFurnaceBloc.prepUserFurnaceForRegistration(
                userFurnace, _username.text);

            _userFurnaceBloc.register(
                userFurnace, null, _radioValue == 1, linkedAccount,
                primaryNetwork: primaryNetwork);
          }
        }
      } else {
        validatedOnceAlready = true;
      }
    } catch (error, trace) {
      setState(() {
        _showSpinner = false;
      });
      LogBloc.postLog('Error:$error', 'RegistrationShort');
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, 'an error occurred, please try again', "", 2, false);
    }
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }
}
