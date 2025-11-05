import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/screens/login/autologin.dart';
import 'package:ironcirclesapp/screens/login/registration_short.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

class AppLink extends StatefulWidget {
  final String link;
  final bool fromApp;

  const AppLink({
    Key? key,
    required this.link,
    this.fromApp = false,
  }) : super(key: key);

  @override
  _AppLinkState createState() {
    return _AppLinkState();
  }
}

class _AppLinkState extends State<AppLink> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _userFurnaceBloc = UserFurnaceBloc();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  final ScrollController _scrollController = ScrollController();
  UserFurnace? _globalStateFurnace;
  UserFurnace? _userFurnace;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final CircleBloc _circleBloc = CircleBloc();
  HostedInvitation? _hostedInvitation;
  bool _linkedAccount = true;
  int _initialIndex = 0;
  bool _alreadyConnected = false;

  String assigned = '';

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _showSpinner = true;
    _globalStateFurnace = globalState.userFurnace;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    //print('AppLink: ${widget.link}');

    if (_globalStateFurnace == null ||
        _globalStateFurnace!.connected == false ||
        _globalStateFurnace!.userid == null ||
        globalState.loggingOut == true) _linkedAccount = false;

    _circleBloc.createdResponse.listen((response) {
      ///blank on purpose
    }, onError: (err) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );
    }, cancelOnError: false);

    _userFurnaceBloc.userFurnace.listen((success) {
      globalState.connectedHostedInvitation = _hostedInvitation;

      ///force refresh on home
      globalState.userCircleFetch = null;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );
    }, onError: (err, trace) {
      debugPrint("error $err");
      LogBloc.insertError(err, trace);
      setState(() {
        _showSpinner = false;
      });
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
            AppLocalizations.of(context)!.errorGeneric,
            null,
            null,
            null,
            false);
    }, cancelOnError: false);

    _hostedFurnaceBloc.alreadyConnected.listen((alreadyConnected) async {
      if (mounted) {
        setState(() {
          _alreadyConnected = alreadyConnected;
          _showSpinner = false;

          DialogNotice.showNotice(
              context,
              AppLocalizations.of(context)!.alreadyConnectedTitle,
              AppLocalizations.of(context)!.alreadyConnectedMessage,
              null,
              null,
              null,
              false);
        });
      }
    }, onError: (err, trace) {
      debugPrint("error $err");
      LogBloc.insertError(err, trace);
      setState(() {
        _showSpinner = false;
      });

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.errorGenericTitle,
          AppLocalizations.of(context)!.errorGeneric,
          null,
          null,
          null,
          false);
    }, cancelOnError: false);

    _hostedFurnaceBloc.hostedInvitation.listen((hostedInvitation) async {
      if (mounted) {
        setState(() {
          _hostedInvitation = hostedInvitation;
          _showSpinner = false;
        });
      }
    }, onError: (err, trace) {
      debugPrint("error $err");
      LogBloc.insertError(err, trace);
      setState(() {
        _showSpinner = false;
      });

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.errorGenericTitle,
          AppLocalizations.of(context)!.errorGeneric,
          null,
          null,
          null,
          false);
    }, cancelOnError: false);

    super.initState();

    _globalEventBloc.applicationStateChanged.listen((msg)  {
      handleAppLifecycleState(msg);
    },
        onError: (error, trace) {
          LogBloc.insertError(error, trace);
        }, cancelOnError: false);

    _hostedFurnaceBloc.validateMagicLinkToNetwork(widget.link);
  }

  @override
  void dispose() {
    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  Widget createAccount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 0,
            ),
            child: GradientButton(
                color1: Colors.teal[500],
                color2: Colors.teal[200],
                text: 'JOIN NETWORK',
                onPressed: () {
                  _register();
                }),
          )),

          //),
        ])
      ]),
    );
  }

  Widget ignore(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 5,
              right: 20,
            ),
            child: TextButton(
                child: Text(
                  'Ignore for now',
                  style: TextStyle(
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.buttonDisabled),
                ),
                onPressed: () {
                  _exit();
                }),
          ),

          //),
        ])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    globalState.setScaler(MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));

    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: ICAppBar(
          title: "",
          pop: _exit,
        ),
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        body: SafeArea(
            left: false,
            top: false,
            right: true,
            bottom: true,
            child: Stack(children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            controller: _scrollController,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 0,
                                        bottom: 20,
                                        left: 20,
                                        right: 20),
                                    child: Image.asset(
                                      'assets/images/landing.png',
                                    )),
                                _hostedInvitation != null
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                            Expanded(
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 20,
                                                            left: 20,
                                                            right: 20),
                                                    child: Text(
                                                      "You have received a network invitation to:",
                                                      textAlign:
                                                          TextAlign.center,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                              1.0),
                                                      style: TextStyle(
                                                          color: globalState
                                                              .theme.labelText,
                                                          fontSize: 18),
                                                    )))
                                          ])
                                    : Container(),
                                _hostedInvitation != null
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                            Expanded(
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 2,
                                                            left: 20,
                                                            right: 20),
                                                    child: Text(
                                                      _hostedInvitation!
                                                          .hostedFurnace.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                              1.0),
                                                      style: TextStyle(
                                                          color: globalState
                                                              .theme.buttonIcon,
                                                          fontSize: 18),
                                                    )))
                                          ])
                                    : Container(),
                                (globalState.userFurnace == null ||
                                        globalState.userFurnace!.userid ==
                                            null ||
                                        globalState.userFurnace!.connected ==
                                            false ||
                                        _hostedInvitation == null ||
                                        _alreadyConnected == true ||
                                        globalState.loggingOut == true)
                                    ? Container()
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 15),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Toggle.ToggleSwitch(
                                                minWidth: 130.0,
                                                //minHeight: 70.0,
                                                initialLabelIndex:
                                                    _initialIndex,
                                                cornerRadius: 20.0,
                                                activeFgColor: Colors.white,
                                                inactiveBgColor: Colors.grey,
                                                inactiveFgColor: Colors.white,
                                                totalSwitches: 2,
                                                radiusStyle: true,
                                                labels: const [
                                                  'Linked Account',
                                                  'Separate Account'
                                                ],
                                                customTextStyles: [
                                                  TextStyle(
                                                      fontSize: 12 /
                                                          MediaQuery
                                                                  .textScalerOf(
                                                                      context)
                                                              .scale(1)),
                                                  TextStyle(
                                                      fontSize: 12 /
                                                          MediaQuery
                                                                  .textScalerOf(
                                                                      context)
                                                              .scale(1))
                                                ],
                                                activeBgColors: const [
                                                  [
                                                    Colors.tealAccent,
                                                    Colors.teal,
                                                  ],
                                                  [Colors.yellow, Colors.orange]
                                                ],
                                                animate:
                                                    true, // with just animate set to true, default curve = Curves.easeIn
                                                curve: Curves
                                                    .bounceInOut, // animate must be set to true when using custom curve
                                                onToggle: (index) {
                                                  debugPrint(
                                                      'switched to: $index');
                                                  //_hiRes = !_hiRes;

                                                  setState(() {
                                                    _linkedAccount =
                                                        !_linkedAccount;
                                                    _initialIndex = index!;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    DialogNotice.showNoticeOptionalLines(
                                                        context,
                                                        AppLocalizations.of(
                                                                context)!
                                                            .linkExistingAccountTitle,
                                                        '${AppLocalizations.of(context)!.linkExistingAccountMessage1} ${globalState.user.username} ${AppLocalizations.of(context)!.linkExistingAccountMessage2}',
                                                        false,
                                                        line2: AppLocalizations
                                                                .of(context)!
                                                            .linkExistingAccountMessage3);
                                                  },
                                                  icon: const Icon(
                                                    Icons.help,
                                                    size: 20,
                                                  ))
                                            ])),
                                (_hostedInvitation != null &&
                                        _alreadyConnected == false)
                                    ? createAccount(context)
                                    : Container(),
                                // Padding(padding: EdgeInsets.only(bottom: 20)),
                                //createNewSocialNetwork(context),
                              ],
                            ),
                          ))),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])),
      ),
    );
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (mounted) {
          setState(() {});
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  _register() async {
    try {
      bool canAdd = false;

      if (_globalStateFurnace == null ||
          _globalStateFurnace!.connected == false ||
          _globalStateFurnace!.userid == null) {
        canAdd = true;
      } else {
        List<UserFurnace> userFurnaces = await _userFurnaceBloc
            .requestConnected(_globalStateFurnace!.userid);

        canAdd = await PremiumFeatureCheck.canAddNetwork(context, userFurnaces);
      }

      if (canAdd) {
        if (_showSpinner == false) {
          setState(() {
            _showSpinner = true;
          });

          late UserFurnace localFurnace;

          if (_hostedInvitation!.hostedFurnace.name.toLowerCase() ==
              'ironforge') {
            localFurnace = UserFurnace.initForge(false);
          } else {
            localFurnace = UserFurnace.initFurnace(
                url: urls.spinFurnace,
                apikey: urls.spinFurnaceAPIKEY,
                authServer: false);

            localFurnace.type = NetworkType.HOSTED;
            localFurnace.hostedName = _hostedInvitation!.hostedFurnace.name;
            localFurnace.hostedAccessCode =
                _hostedInvitation!.hostedFurnace.key;
            localFurnace.alias = _hostedInvitation!.hostedFurnace.name;
          }

          if (_globalStateFurnace == null ||
              _globalStateFurnace!.connected == false ||
              _globalStateFurnace!.userid == null)
            localFurnace.authServer = true;

          _userFurnace = localFurnace;

          if (_linkedAccount) {
            localFurnace.username = globalState.user.username!;
            localFurnace.password = '';
            localFurnace.pin = '';

            _userFurnaceBloc.register(
              localFurnace,
              null,
              globalState.user.minor,
              _linkedAccount,
              inviter: _hostedInvitation!.inviter,
              hostedInvitation: _hostedInvitation,
              primaryNetwork: globalState.userFurnace,
            );
          } else {
            //DialogUsernameAndTerms.show(context, _registerUser, '', '');

            await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistrationShort(
                    caller: RegistrationShortCaller.applink,
                    linkedAccount: _linkedAccount,
                    hostedInvitation: _hostedInvitation,
                    appLinkNetwork: localFurnace,
                  ),
                ));

            setState(() {
              _showSpinner = false;
            });
          }
        }
      }
    } catch (err, trace) {
      setState(() {
        LogBloc.insertError(err, trace);
        _showSpinner = false;
      });
    }
  }

  /*_registerUser(String username, bool minor) {
    setState(() {
      _showSpinner = true;
    });

    _userFurnace = _userFurnaceBloc.prepUserFurnaceForRegistration(_userFurnace!, username);

    _userFurnaceBloc.register(_userFurnace!, null, minor, false,
        fromLanding: true);
  }*/

  _exit() {
    if (widget.fromApp)
      Navigator.pop(context);
    else
      ///this pushAndRemoveUntil is ok
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AutoLogin()),
          ModalRoute.withName("/home"));
  }
}
