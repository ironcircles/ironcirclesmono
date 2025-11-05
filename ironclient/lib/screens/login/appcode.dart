/*import 'dart:async';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/screens/login/autologin.dart';
import 'package:ironcirclesapp/screens/login/registration.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ndialog/ndialog.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class AppCode extends StatefulWidget {
  final bool fromFurnaceManager;
  final String? token;

  AppCode({
    Key? key,
    required this.fromFurnaceManager,
    this.token,
  }) : super(key: key);

  @override
  _AppCodeState createState() {
    return _AppCodeState();
  }
}

class _AppCodeState extends State<AppCode> {
  TextEditingController _magicCode = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  late FirebaseBloc _firebaseBloc;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  ScrollController _scrollController = ScrollController();
  UserFurnace? _userFurnace;
  HostedFurnaceBloc _hostedFurnaceBloc = HostedFurnaceBloc();
  HostedInvitation? _hostedInvitation;
  final _userFurnaceBloc = UserFurnaceBloc();
  bool _linkedAccount = true;
  int _initialIndex = 0;

  String assigned = '';

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  _getHostedInvitation() {
    String magicCode = _magicCode.text;

    if (magicCode.length != 40)
      StringHelper.getMagicCodeFromString(_magicCode.text);

    if (magicCode.isEmpty) return;
    setState(() {
      _showSpinner = true;
    });
    _hostedFurnaceBloc.getHostedInvitation(magicCode);
  }

  _checkClipBoardData() async {
    String magicCode = await StringHelper.testClipboardForMagicCode();

    if (magicCode.isNotEmpty && mounted) {
      setState(() {
        _magicCode.text = magicCode;
      });

      _getHostedInvitation();
    }
  }

  @override
  void initState() {
    handleAppLifecycleState();

    if (widget.token != null) _magicCode.text = widget.token!;

    _userFurnaceBloc.userFurnace.listen((success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(context, 'Username already exists',
            'Please select a different username', null, null, null);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(context, 'Username is reserved',
            'Please select a different username', null, null, null);
      } else
        DialogNotice.showNotice(context, 'Something went wrong',
            err.toString().replaceAll('Exception: ', ''), null, null, null);

      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _hostedFurnaceBloc.hostedInvitation.listen((hostedInvitation) async {
      if (mounted) {
        _hostedInvitation = hostedInvitation;

        setState(() {
          _magicCode.text = hostedInvitation.token;
          _showSpinner = false;
        });

        //_register();
      }
    }, onError: (err) {
      debugPrint("error $err");

      DialogNotice.showNotice(
          context, 'An issue has occurred', err.toString(), null, null, null);

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    super.initState();

    ///Did the calling page already get the token off the clipboard?
    if (widget.token != null)
      _hostedFurnaceBloc.getHostedInvitation(widget.token!);
    else
      _checkClipBoardData();
  }

  @override
  void dispose() {
    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  Widget createAccount(BuildContext context) {
    return Container(
        //color: Colors.grey[800],
        child: Padding(
      padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
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
                text: _linkedAccount ? 'JOIN NETWORK' : 'CREATE ACCOUNT',
                onPressed: () {
                  if (_hostedInvitation != null)
                    _register();
                  else
                    _getHostedInvitation();
                }),
          )),

          //),
        ])
      ]),
    ));
  }

  Widget ignore(BuildContext context) {
    return Container(
        //color: Colors.grey[800],
        child: Padding(
      padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
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
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => AutoLogin()),
                      ModalRoute.withName("/home"));
                }),
          ),

          //),
        ])
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    globalState.mediaScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: ICAppBar(title: 'Magic code'),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: Container(
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
                                          left: 11,
                                          top: 0,
                                          bottom: 10,
                                          right: 49),
                                      child: Row(children: <Widget>[
                                        Expanded(
                                          flex: 20,
                                          child: FormattedText(
                                              controller: _magicCode,
                                              labelText:
                                                  'copy and paste magic code message',
                                              // maxLength: 40,
                                              maxLines: 1),
                                        ),
                                      ]),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 0)),
                                    Padding(
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
                                                labels: [
                                                  'Linked Account',
                                                  'Separate Account'
                                                ],
                                                customTextStyles: [
                                                  TextStyle(
                                                      fontSize: 12 /
                                                          globalState
                                                              .mediaScaleFactor),
                                                  TextStyle(
                                                      fontSize: 12 /
                                                          globalState
                                                              .mediaScaleFactor)
                                                ],
                                                activeBgColors: [
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
                                                        'Link Existing Account?',
                                                        'Recommended: Link your ${globalState.user.username} account. You can still use a different username and avatar on the network if you like',
                                                        line2:
                                                            'If you want a separate account, you will manage password, pin, password helpers, and settings separately.');
                                                  },
                                                  icon: Icon(
                                                    Icons.help,
                                                    size: 20,
                                                  ))
                                            ])),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                    ),
                                    createAccount(context),
                                  ],
                                ),
                              )))),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])),
      ),
    );
  }

  handleAppLifecycleState() {
    AppLifecycleState _lastLifecyleState;
      //debugPrint('SystemChannels> $msg');

      try {
        switch (msg) {
          case "AppLifecycleState.paused":
            _lastLifecyleState = AppLifecycleState.paused;
            break;
          case "AppLifecycleState.inactive":
            _lastLifecyleState = AppLifecycleState.inactive;
            break;
          case "AppLifecycleState.resumed":
            _lastLifecyleState = AppLifecycleState.resumed;
            _checkClipBoardData();
            break;
          case "AppLifecycleState.suspending":
            // _lastLifecyleState = AppLifecycleState.suspending;
            break;
          default:
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        debugPrint('Login.handleAppLifecycleState: $error');
 FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      }

      return Future.value(null);
    });
  }

  _register() async {
    late UserFurnace localFurnace;

    if (_hostedInvitation!.hostedFurnace.name.toLowerCase() == 'ironforge') {
      localFurnace = UserFurnace.initForge(false);
    } else {
      localFurnace = UserFurnace.initFurnace(
          url: urls.spinFurnace,
          apikey: urls.spinFurnaceAPIKEY,
          authServer: false);
      localFurnace.hosted = true;
      localFurnace.hostedName = _hostedInvitation!.hostedFurnace.name;
      localFurnace.hostedAccessCode = _hostedInvitation!.hostedFurnace.key;
      localFurnace.alias = _hostedInvitation!.hostedFurnace.name;
    }

    localFurnace.authServer = !widget.fromFurnaceManager;

    if (_linkedAccount) {
      localFurnace.username = globalState.user.username!;
      localFurnace.password = '';
      localFurnace.pin = '';

      _userFurnaceBloc.register(
          localFurnace, null, globalState.user.minor, '', '', _linkedAccount);
    } else {
      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Registration(
              fromNetworkManager: widget.fromFurnaceManager,
              userFurnace: localFurnace,
              appLinkToken: _hostedInvitation!.token,
              magicCode: _magicCode.text,
              //username: _username.text,
            ),
          ));

      setState(() {
        _showSpinner = false;
      });
    }
  }
}

 */
