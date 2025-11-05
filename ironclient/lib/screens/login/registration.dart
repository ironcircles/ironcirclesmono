import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/screens/login/network_connect_hosted.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/password_strength.dart';
import 'package:ndialog/ndialog.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class Registration extends StatefulWidget {
  final String? toast;
  final UserFurnace userFurnace;
  final bool showChangeNetwork;
  //final String appLinkToken;
  //final bool fromNetworkManager;
  //final String magicCode;
  final HostedInvitation? hostedInvitation;
  final File? networkImage;
  final Source source;

  const Registration({
    Key? key,
    required this.userFurnace,
    this.showChangeNetwork = false,
    this.toast,
    //this.fromNetworkManager = false,
    this.networkImage,
    required this.source,
    //this.appLinkToken = '',
    //this.magicCode = '',
    this.hostedInvitation,
  }) : super(key: key);

  @override
  _FurnaceRegisterState createState() {
    return _FurnaceRegisterState();
  }
}

class _FurnaceRegisterState extends State<Registration> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final InvitationBloc _invitationBloc = InvitationBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late GlobalEventBloc _globalEventBloc;
  final CircleBloc _circleBloc = CircleBloc();
  late FirebaseBloc _firebaseBloc;
  final databaseBloc = DatabaseBloc();
  bool _showPassword = false;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  late UserFurnace _userFurnace;
  bool _showStrength = false;
  String _strengthText = '';

  String assigned = '';
  String? _toast;
  String _pinText = '';
  final TextEditingController _pinController = TextEditingController();
  final StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();

  bool _showSpinner = false;
  File? _image;
  bool _oldEnough = false;
  int? _radioValue = -1;
  bool _tos = false;
  bool validatedOnceAlready = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  _goBack() {
    ///close keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    if (widget.source == Source.fromNetworkManager) {
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      if (_userFurnace.newNetwork == false) {
        ///there is an extra screen if the user is connecting to an existing network (if asks if they have or if they need an account)
        // Navigator.pop(context);
      }
    } else if (widget.source == Source.fromNetworkRequests) {
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );
    }
  }

  @override
  void initState() {
    if (kDebugMode && !Urls.testingReleaseMode) {
      _username.text = 'maven${SecureRandomGenerator.generateInt(max: 4)}';
      _password.text = '12345678';
      _password2.text = '12345678';
      _pinText = '1234';
      _pinController.text = _pinText;
    }

    _radioValue = 2;
    _oldEnough = true;
    _tos = true;

    _userFurnace = widget.userFurnace;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));

    super.initState();

    _globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;

    _invitationBloc.inviteResponse.listen((invitation) {
      _goBack();
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _circleBloc.createdResponse.listen((response) {
      ///blank on purpose
    }, onError: (err) {
      _goBack();
    }, cancelOnError: false);

    _userFurnaceBloc.userFurnace.listen((success) {
      if (widget.source == Source.fromLanding &&
          globalState.userFurnace != null &&
          globalState.userFurnace!.connected == false) {
        globalState.showHomeTutorial = true;
        globalState.showPrivateVaultPrompt = true;
      }

      if (widget.hostedInvitation != null) {
        _circleBloc.createDirectMessageWithNewUser(globalState, _invitationBloc,
            _userFurnace, widget.hostedInvitation!.inviter);
      } else {
        _goBack();
      }
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(context, 'Username already exists',
            'Please select a different username', null, null, null, false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(context, 'Username is reserved',
            'Please select a different username', null, null, null, false);
      } else
        DialogNotice.showNotice(
            context,
            'Something went wrong',
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            true);

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
          context, widget.toast!, "", 2, false);
      _toast = null;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();

    _authBloc.dispose();
    databaseBloc.dispose();

    _pinAnimationController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.of(context).size.width;
    double condensedWidth = ScreenSizes.getFormScreenWidth(width);
    Widget _ageWidgets(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 0, left: 15, right: 10, bottom: 0),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 0, top: 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ICText(
                      "Age:  ",
                      color: globalState.theme.dialogLabel,
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
                                  fontSize: 14,
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
                                  fontSize: 14,
                                  color: globalState.theme.dialogLabel),
                            ))),
                    const Spacer()
                  ])),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
          ),
        ]),
      );
    }

    final tos = Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
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
                  _scrollBottom();
                });
              },
            ),
          ),
          const ICText(
            'I agree:  ',
          ),
          Expanded(
              child: InkWell(
                  onTap: _showTOS,
                  child: ICText(
                    AppLocalizations.of(context)!.termsOfService, //'Terms of Service',
                    color: globalState.theme.buttonIcon,
                    fontSize: 16,
                  )))
        ]),
      ]),
    );

    final makeBottom = SizedBox(
      height: 125.0,
      child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                child: GradientButton(
                  text: 'CREATE ACCOUNT',
                  onPressed: () {
                    _register();
                  },
                ),
              )
            ]),
          ])),
    );

    final makeBody = Container(
      //color: globalState.theme.body,
      // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 5),
      child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollController,
            child: WrapperWidget(child: Column(children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, top: 0, bottom: 10, right: 49),
                child: Row(children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: FormattedText(
                      controller: _username,
                      maxLength: 25,
                      labelText: 'create a username',
                      maxLines: 1,
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
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 0, bottom: 0),
                child: Row(children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: FormattedText(
                      maxLength: 65,
                      controller: _password,
                      labelText: 'create a password (8+)',
                      obscureText: !_showPassword,
                      onChanged: _calcStrength,
                      maxLines: 1,
                      validator: (value) {
                        if (value.toString().isEmpty) {
                          return 'cannot be empty';
                        } else if (value.toString().endsWith(' ')) {
                          return 'cannot end with a space';
                        } else if (value.toString().length < 8) {
                          return 'must be at least 8 chars';
                        } else if (value.toString().startsWith(' ')) {
                          return 'cannot start with a space';
                        }

                        return null;
                      },
                    ),
                  ),
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
                                  color: globalState.theme.buttonIconSplash),
                              onPressed: () {
                                setState(() {
                                  _showPassword = true;
                                });
                              }))
                ]),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, right: 50),
                  child: Row(children: <Widget>[
                    Expanded(
                      // flex: 20,
                      child: FormattedText(
                        maxLength: 65,
                        obscureText: !_showPassword,
                        labelText: 'reenter password',
                        controller: _password2,
                        onChanged: _revalidate,
                        maxLines: 1,
                        validator: (value) {
                          if (value.toString() != _password.text.toString()) {
                            return 'passwords do not match';
                          }

                          return null;
                        },
                      ),
                    ),
                  ])),
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, right: 50, top: 10, bottom: 0),
                child: Row(children: <Widget>[
                  _showStrength
                      ? Expanded(
                          child: ICText(
                          _strengthText,
                          textAlign: TextAlign.end,
                          color: strengthColorMap(_password.text),
                        ))
                      : Container(),
                ]),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 26),
                      child: ICText('create a pin:',
                          color: globalState.theme.labelTextSubtle,
                          fontSize: 18),
                    ),
                  ]),
              Padding(
                  padding: EdgeInsets.only(top: 15, right:  (condensedWidth > 500 ? condensedWidth - 500 : 50), left: 49),
                  child: PinCodeTextField(
                    enablePinAutofill: true,
                    appContext: context,
                    length: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    obscureText: !_showPassword,
                    animationType: AnimationType.fade,
                    autoDismissKeyboard: false,
                    textStyle: TextStyle(fontSize: 20 / textScale),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      //errorBorderColor: Colors.orange,
                      inactiveColor: globalState.theme.labelTextSubtle,
                      selectedColor: globalState.theme.buttonIcon,
                      selectedFillColor: globalState.theme.menuIconsAlt,
                      fieldHeight: 30,
                      fieldWidth: 30,
                      inactiveFillColor: globalState.theme.labelTextSubtle,
                      activeFillColor: globalState.theme.labelTextSubtle,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: globalState.theme.background,
                    enableActiveFill: true,
                    errorAnimationController: _pinAnimationController,
                    controller: _pinController,
                    onCompleted: (v) {
                      debugPrint("Completed");
                    },
                    onChanged: (value) {
                      debugPrint(value);
                      setState(() {
                        _pinText = value;
                      });
                    },
                    beforeTextPaste: (text) {
                      debugPrint("Allowing to paste $text");
                      return true;
                    },
                  )),
              tos,
              _ageWidgets(context),
              makeBottom,
            ]),
          )),
    ));

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: const ICAppBar(title: 'Create an account'),
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
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.only(left: 15)),
                    Text(
                      'Network: ',
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.labelText),
                      textScaler:
                          TextScaler.linear(globalState.textFieldScaleFactor),
                    ),
                    Expanded(
                        child: Text(
                      '${_userFurnace.alias} ',
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.buttonIcon),
                      textScaler:
                          TextScaler.linear(globalState.textFieldScaleFactor),
                    )),
                    widget.showChangeNetwork
                        ? Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: TextButton(
                                onPressed: () {
                                  _changeNetwork();
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        globalState.theme.buttonDisabled)),
                                child: Text(
                                  'Change Network',
                                  style: TextStyle(
                                      fontSize:
                                          globalState.userSetting.fontSize - 2,
                                      color: Colors.white),
                                  textScaler: TextScaler.linear(
                                      globalState.textFieldScaleFactor),
                                )))
                        : Container(),
                  ]),
                  const Padding(padding: EdgeInsets.only(bottom: 15)),
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
          ),
        ),
      ),
    );
  }

  _changeNetwork() async {
    _userFurnace = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkConnectHosted(
            userFurnace: widget.userFurnace,
            authServer: true,
            source: Source.fromLanding,
            //username: _username.text,
          ),
        ));

    setState(() {});
  }

  _handleRadioValueChange(int? value) {
    setState(() {
      _radioValue = value;
      _oldEnough = true;
    });

    _scrollBottom();
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

  _scrollBottom() {
    if (_oldEnough && _tos) {
      FocusScope.of(context).requestFocus(FocusNode());

      /*_scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,

          duration: Duration(milliseconds: 1),
          curve: Curves.ease);

       */
    }
  }

  void _register() async {
    try {
      if (_showSpinner == true) return;

      if (_formKey.currentState!.validate()) {
        _showSpinner = true;

        if (_username.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'username required', "", 2, false);
          _showSpinner = false;
        } else if (_password.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'password required', "", 2, false);
          _showSpinner = false;
        } else if (_password.text.length < 8) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'password must be 8 chars or longer', "", 2, false);
          _showSpinner = false;
        } else if (_pinText.length < 4) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'pin required', "", 2, true);
          _showSpinner = false;
        } else if (_tos == false) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'please review the terms of service', "", 2, false);
          _showSpinner = false;
        } else if (!_oldEnough) {
          FormattedSnackBar.showSnackbarWithContext(
              context, 'please select age option', "", 2, false);
          _showSpinner = false;
        } else {
          setState(() {
            _showSpinner = true;
          });
          _userFurnace.username = _username.text;
          _userFurnace.password = _password.text;
          _userFurnace.pin = _pinText;

          _userFurnaceBloc.register(
              _userFurnace, _image, _radioValue == 1, false,
              image: widget.networkImage,
              fromNetworkManager: (widget.source == Source.fromNetworkManager ||
                  widget.source == Source.fromActionRequired ||
                  widget.source == Source.fromNetworkRequests));
        }
      } else {
        validatedOnceAlready = true;
      }
    } catch (error, trace) {
      setState(() {
        _showSpinner = false;
      });
      LogBloc.insertError(error, trace);
      debugPrint('Registration._register: $error');
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  void _calcStrength(String value) {
    _revalidate(value);

    setState(() {
      _strengthText = getStrengthString(value);

      if (_strengthText.isNotEmpty) {
        _showStrength = true;
      } else {
        _showStrength = false;
      }
    });
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }
}
