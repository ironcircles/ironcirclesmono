import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/login_resetpassword.dart';
import 'package:ironcirclesapp/screens/login/networkdetail.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

class Login extends StatefulWidget {
  final String? username;
  final String? toast;
  final UserFurnace userFurnace;
  final bool fromFurnaceManager;
  final bool allowChangeUser;

  const Login({
    Key? key,
    this.username,
    required this.userFurnace,
    this.allowChangeUser = true,
    this.toast,
    this.fromFurnaceManager = false,
  }) : super(key: key);

  @override
  _FurnaceLoginState createState() {
    return _FurnaceLoginState();
  }
}

class _FurnaceLoginState extends State<Login> {
  final TextEditingController _network = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _networkUrl = TextEditingController();
  final TextEditingController _networkApiKey = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  final KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();
  late GlobalEventBloc _globalEventBloc;
  late FirebaseBloc _firebaseBloc;
  final databaseBloc = DatabaseBloc();
  late UserCircleBloc _userCircleBloc;
  bool _showPassword = false;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  late UserFurnace _userFurnace;
  bool _boolSelfHosted = false;
  int _initialIndex = 0;
  String assigned = '';
  String? _toast;
  String _pinText = '';
  bool validatedOnceAlready = false;

  bool _loggingIn = false;
  final TextEditingController _pinController = TextEditingController();
  final StreamController<ErrorAnimationType> _pinAnimationController =
      StreamController<ErrorAnimationType>();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    if (kDebugMode && !Urls.testingReleaseMode) {
      _networkUrl.text = "https://ironfurny.herokuapp.com/";
      _networkApiKey.text = "J73Hpqj362J4psX7jyhXdftbxSPYkE9CrjWShz9r";
      _password.text = '12345678';

      _pinText = '1234';
      _pinController.text = _pinText;
    }

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));

    if (widget.username != null)
      _username.text = widget.username!;
    else if (widget.userFurnace.username != null &&
        widget.fromFurnaceManager == false) {
      _username.text = widget.userFurnace.username!;
    }

    super.initState();
    //handleAppLifecycleState();

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;
    globalState.loggedOutToLanding = false;

    _userFurnace = widget.userFurnace;
    _network.text = widget.userFurnace.alias!;

    if (!widget.fromFurnaceManager &&
        globalState.userFurnace != null &&
        globalState.userFurnace!.alias != null) {
      _userFurnace = globalState.userFurnace!;
      _network.text = globalState.userFurnace!.alias!;
      _username.text = globalState.userFurnace!.username!;
    } else if (widget.fromFurnaceManager) {
      if (_userFurnace.type == NetworkType.SELF_HOSTED) {
        _boolSelfHosted = true;
      }
    }

    _userCircleBloc.refreshedUserCirclesSync.listen((success) {
      if (mounted) {
        importingData!.dismiss();
        importingData = null;
        globalState.importing = false;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (Route<dynamic> route) => false,
          arguments: globalState.user,
        );
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _keychainBackupBloc.restoreSuccess.listen((show) {
      if (mounted) {
        setState(() {
          if (show) {
            if (progressDialog != null) {
              progressDialog!.dismiss();
              progressDialog = null;
            }

            progressDialog = ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .importingChatHistory, //"Importing chat history",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            progressDialog!.show();
          } else {
            progressDialog!.dismiss();
            progressDialog = null;

            //Navigator.of(context).pop(true);

            importingData = ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .decryptingData, //"Decrypting data",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            importingData!.show();

            ///import data
            globalState.importing = true;
            _userCircleBloc.fetchUserCirclesSync(true);
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(context, err, "", 2, true);
      if (progressDialog != null) {
        progressDialog!.dismiss();
        progressDialog = null;
      }
    }, cancelOnError: false);

    _authBloc.keyGenerated.listen((show) {
      if (mounted) {
        setState(() {
          if (show) {
            setState(() {
              _loggingIn = false;
              _showSpinner = false;
            });
            progressDialog ??= ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .generatingSecurityKeys, //"Generating Security Keys",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            progressDialog!.show();
          } else {
            if (progressDialog != null) {
              progressDialog!.dismiss();
              progressDialog = null;
            }

            globalState.importing = false;

            if (widget.fromFurnaceManager) {
              Navigator.pop(context);
              Navigator.pop(context);
              // Navigator.pop(context);
              // Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: globalState.user,
              );
            }
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _authBloc.resetCodeAvailable.listen((yes) {
      if (yes!) {
        _showResetCode();
      } else {
        _askPasswordReset();
      }
    }, onError: (err) {
      setState(() {
        //showPasswordReset = true;
      });

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.connected.listen((furnaceConnection) {
      if (furnaceConnection!.userFurnace.connected!) {
        if (mounted)
          setState(() {
            _loggingIn = false;
            _showSpinner = false;
          });

        if (globalState.user.autoKeychainBackup != null) {
          if (globalState.user.autoKeychainBackup!) {
            /*UserBloc userBloc = UserBloc();
            userBloc.updateKeysExported(_userFurnace);*/
          }
        }

        _determineRoute(furnaceConnection);
      }
    }, onError: (err) {
      setState(() {
        _loggingIn = false;
        _showSpinner = false;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _authBloc.resetDone.listen((success) {
      _showSent(success);
    }, onError: (err) {
      setState(() {
        //showPasswordReset = true;
      });
      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.couldNotResetTitle,
          err.toString().replaceFirst('Exception:', ''),
          null,
          null,
          null,
          true);

      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.toast != null) _toast = widget.toast;
  }

  _determineRoute(FurnaceConnection furnaceConnection) async {
    if (furnaceConnection.user.id != null) {
      ///check to see if the user has receiving keys
      List<UserCircle> missing = await ForwardSecrecy.keysMissing(
          furnaceConnection.user.id!, furnaceConnection.user.userCircles);

      if (furnaceConnection.user.keyGen == false)
        _authBloc.generateCircleKeys(
            furnaceConnection.user, _userFurnace, missing);
      else if (missing.isNotEmpty) {
        //if (furnaceConnection.user.autoKeychainBackup!) {
        if (furnaceConnection.user.autoKeychainBackup!) {

          _keychainBackupBloc.prepRestore(_authBloc, _userFurnace,furnaceConnection.user,false);
        } else {
          await Future.delayed(const Duration(milliseconds: 100));

          ///ratchet the receiving keys for this device
          _authBloc.generateCircleKeys(furnaceConnection.user, _userFurnace,
              furnaceConnection.user.userCircles);
        }
      } else {
        ///ratchet the receiving keys for this device
        _authBloc.generateCircleKeys(furnaceConnection.user, _userFurnace,
            furnaceConnection.user.userCircles);
      }
    } else {
      if (mounted)
        setState(() {
          _loggingIn = false;
          _showSpinner = false;
        });
      //_userFurnaceBloc.connect(_userFurnace, false);
    }
  }

  _showToast(BuildContext context) {
    if (_toast != null) {
      FormattedSnackBar.showSnackbarWithContext(
          context, widget.toast!, "", 2, false);
      _toast = null;
    }
  }

  _showSent(success) async {
    if (success) {
      await DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.codeFragmentsSentTitle,
          success,
          null,
          null,
          null,
          false);
      _showResetCode();
    } else {
      await DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.couldNotFindAccount,
          success,
          null,
          null,
          null,
          false);
      _showResetCode();
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

    final desktopLoginButton = Padding(
      padding: const EdgeInsets.only(left: 0, right: 10, top: 10, bottom: 12),
      child: Row(children: <Widget>[
        const Spacer(),
        SizedBox(
            height: 55,
            width: 300,
            child: GradientButton(
              text: AppLocalizations.of(context)!.loginCaps, //'LOGIN',
              onPressed: () {
                _login(context);
              },
            )),
      ]),
    );

    final loginButton = Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 12),
      child: Row(children: <Widget>[
        Expanded(
          child: GradientButton(
            text: AppLocalizations.of(context)!.loginCaps, //'LOGIN',
            onPressed: () {
              _login(context);
            },
          ),
        )
      ]),
    );

    final makeBody = Scrollbar(
        controller: _scrollController,
        //thumbVisibility: true,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollController,
            child: WrapperWidget(
              child: Column(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 11, top: 5, bottom: 10, right: 49),
                  child: Row(children: <Widget>[
                    (widget.allowChangeUser)
                        ? Expanded(
                            flex: 20,
                            child: FormattedText(
                              controller: _network,
                              labelText: AppLocalizations.of(context)!
                                  .network, //'network',
                              maxLength: 50,
                              maxLines: 1,
                              onChanged: _revalidate,
                              validator: (value) {
                                if (value.toString().endsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotStartWithASpace; //'cannot end with a space';
                                } else if (value.toString().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotBeEmpty; //'cannot be empty';
                                } else if (value.toString().startsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotStartWithASpace; //'cannot start with a space';
                                }

                                return null;
                              },
                            ),
                          )
                        : Expanded(
                            child: Row(children: <Widget>[
                            Text(
                              "${AppLocalizations.of(context)!.network}: ", //'Network: ',
                              textScaler: TextScaler.linear(
                                  globalState.textFieldScaleFactor),
                              style: TextStyle(
                                  fontSize: globalState.userSetting.fontSize,
                                  color: globalState.theme.labelText),
                            ),
                            Expanded(
                                child: Text(
                              widget.userFurnace.alias!,
                              textScaler: TextScaler.linear(
                                  globalState.textFieldScaleFactor),
                              style: TextStyle(
                                  fontSize: globalState.userSetting.fontSize,
                                  color: globalState.theme.buttonIcon),
                            ))
                          ])),
                  ]),
                ),
                widget.allowChangeUser
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
                _boolSelfHosted
                    ? Padding(
                        padding: const EdgeInsets.only(
                            left: 11, top: 15, bottom: 0, right: 15),
                        child: Row(children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: FormattedText(
                              readOnly: !widget.allowChangeUser,
                              //hintText: 'Enter a name for your network',
                              controller: _networkUrl,
                              maxLength: 50,
                              labelText: 'api url', //'enter network name',
                              maxLines: 1,
                              onChanged: _revalidate,
                              validator: (value) {
                                if (value.toString().endsWith(' ')) {
                                  return 'cannot end with a space';
                                } else if (value.toString().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotBeEmpty; //'cannot be empty';
                                } else if (value.toString().startsWith(' ')) {
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
                              readOnly: !widget.allowChangeUser,
                              //hintText: 'Enter a name for your network',
                              controller: _networkApiKey,
                              maxLength: 50,
                              labelText: 'api key', //'enter network name',
                              maxLines: 1,
                              onChanged: _revalidate,
                              validator: (value) {
                                if (value.toString().endsWith(' ')) {
                                  return 'cannot end with a space';
                                } else if (value.toString().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotBeEmpty; //'cannot be empty';
                                } else if (value.toString().startsWith(' ')) {
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

                Padding(
                  padding: const EdgeInsets.only(
                      left: 11, top: 0, bottom: 10, right: 49),
                  child: Row(children: <Widget>[
                    widget.allowChangeUser
                        ? Expanded(
                            flex: 20,
                            child: FormattedText(
                              controller: _username,
                              labelText: AppLocalizations.of(context)!
                                  .username, //'username',
                              maxLength: 25,
                              maxLines: 1,
                              onChanged: _revalidate,
                              validator: (value) {
                                if (value.toString().endsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotEndWithASpace; //'cannot end with a space';
                                } else if (value.toString().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotBeEmpty; //'cannot be empty';
                                } else if (value.toString().startsWith(' ')) {
                                  return AppLocalizations.of(context)!
                                      .errorCannotStartWithASpace; //'cannot start with a space';
                                }

                                return null;
                              },
                            ),
                          )
                        : Expanded(
                            child: Text(
                            widget.username!,
                            textScaler: TextScaler.linear(
                                globalState.textFieldScaleFactor),
                            style: TextStyle(
                                fontSize: globalState.userSetting.fontSize,
                                color: globalState.theme.buttonIcon),
                          )),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormattedText(
                        controller: _password,
                        maxLength: 65,
                        labelText: AppLocalizations.of(context)!
                            .password, //'password',
                        maxLines: 1,
                        obscureText: !_showPassword,
                        onChanged: _revalidate,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return AppLocalizations.of(context)!
                                .errorCannotBeEmpty; //'cannot be empty';
                          } /*else if (value.toString().endsWith(' ')) {
                          return 'cannot end with a space';
                        } else if (value.toString().startsWith(' ')) {
                          return 'cannot start with a space';
                        }
                        */

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
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 25),
                        child: ICText(AppLocalizations.of(context)!.pin,
                            color: globalState.theme.labelTextSubtle,
                            fontSize: 18),
                      ),
                    ]),
                Padding(
                    padding: EdgeInsets.only(
                        top: 15,
                        right:
                            (condensedWidth > 500 ? condensedWidth - 500 : 50),
                        left: 50),
                    child: PinCodeTextField(
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
                        //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                        //but you can show anything you want here, like your pop up saying wrong paste format or etc
                        return true;
                      },
                    )),

                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(left: 0, right: 10),
                          child: TextButton(
                              child: ICText(
                                AppLocalizations.of(context)!
                                    .forgotPasswordOrPin, //'Forgot Password/Pin?',
                                textAlign: TextAlign.end,
                                color: globalState.theme.buttonIcon,
                              ),
                              onPressed: () {
                                _checkResetCodeAvailable();
                              })),
                    ]),
                //Spacer(),
                Platform.isMacOS || Platform.isWindows || Platform.isLinux
                    ? desktopLoginButton
                    : loginButton
              ]),
            )));

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.login, //'Login',
        ),
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
                  const Padding(padding: EdgeInsets.only(bottom: 15)),
                  Expanded(
                    child: makeBody,
                  ),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
        ),
      ),
    );
  }

  void _login(BuildContext context) async {
    try {
      if (_username.text == 'apple27895' || _username.text == 'google32395') {
        _network.text = 'IronForge';
        _pinText = '3894';
      }

      if (_formKey.currentState!.validate()) {
        if (_network.text.isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.errornetworkRequired, "", 2, false);
          return;
        } else if (_username.text.isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.errorusernameRequired,
              "",
              2,
              false);
          return;
        } else if (_password.text.isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.errorpasswordRequired,
              "",
              2,
              false); //'password required', "", 2, false);
          return;
        } else if (_pinText.length < 4) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.errorpinRequired,
              "",
              2,
              false); //'pin required', "", 2, false);
          return;
        }

        if (!_loggingIn) {
          _loggingIn = true;

          setState(() {
            _showSpinner = true;
          });

          _userFurnace = UserFurnace(authServer: true);

          _setNetwork();

          //if (_userFurnace.userid == null)
          _userFurnace.username = _username.text;
          _userFurnace.password = _password.text;
          _userFurnace.pin = _pinText;

          if (widget.fromFurnaceManager) {
            if (await _userFurnaceBloc.furnaceExists(_userFurnace)) {
              if (_userFurnace.connected!) {
                throw (AppLocalizations.of(context)!
                    .alreadyconnectedToThisIronFurnaceWithThisUser); //'Already connected to this IronFurnace with this user');
              }
            }

            _userFurnace.authServer = false;
          }

          debugPrint(globalState.userSetting.backupKey);

          _userFurnaceBloc.connect(
              _userFurnace, true, widget.fromFurnaceManager);
        }
      } else {
        validatedOnceAlready = true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      setState(() {
        _loggingIn = false;
        _showSpinner = false;
      });

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }
  }

  /* _recoverAccount() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginAccountRecovery(
            //imageProvider:
            //  const AssetImage("assets/large-image.jpg"),
            username: _username.text,
            userFurnace: _userFurnace,
            //screenType: PassScreenType.RESET_CODE,
          ),
        ));
  }*/

  bool checkUsername() {
    if (_username.text.isEmpty) {
      FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.enterUsername,
          "",
          2,
          false); //'enter username', "", 2, false);
      return false;
    } else if (_network.text.isEmpty) {
      FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.enterNetworkName,
          "",
          2,
          false); //'enter username', "", 2, false);
      return false;
    }

    return true;
  }

  _checkResetCodeAvailable() {
    if (checkUsername()) {
      _setNetwork();

      _authBloc.checkResetCodeAvailable(_username.text, _userFurnace);
    }
  }

  void _showResetCode() {
    _setNetwork();

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPassword(
            username: _username.text,
            userFurnace: _userFurnace,
          ),
        ));
  }

  void _askPasswordReset() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!
            .askPasswordResetTitle, //'Forgot password?',
        AppLocalizations.of(context)!
            .askPasswordResetMessage, //'If you are still logged into another device you can change your password in Settings->Security.\n\nIf you are not logged into another device, you can utilize your password recovery helpers, if you set them up.\n\nThis will send fragments of a reset code to members you have assigned. Assemble the fragments and you can reset your password.\n\nWould you like to initiate a reset request?',
        _passwordResetYes,
        null,
        false);
  }

  _setNetwork() {
    _userFurnace.alias = _network.text;

    if (_boolSelfHosted) {
      _userFurnace.type = NetworkType.SELF_HOSTED;
      _userFurnace.hostedName = _network.text;
      _userFurnace.url = _networkUrl.text;
      _userFurnace.apikey = _networkApiKey.text;
    } else if (_userFurnace.alias!.trim().toLowerCase() ==
        IRONFORGE.toLowerCase()) {
      _userFurnace.type = NetworkType.FORGE;
      _userFurnace.hostedName = null;
      _userFurnace.url = urls.forge;
      _userFurnace.apikey = urls.forgeAPIKEY;
    } else {
      _userFurnace.type = NetworkType.HOSTED;
      _userFurnace.hostedName = _network.text;
      _userFurnace.url = urls.spinFurnace;
      _userFurnace.apikey = urls.spinFurnaceAPIKEY;
    }
  }

  void _passwordResetYes() {
    _setNetwork();
    _authBloc.generateResetCode(_username.text, _userFurnace);
  }
  //
  // handleAppLifecycleState() {
  //   AppLifecycleState _lastLifecyleState;
  //
  //     debugPrint('SystemChannels> $msg');
  //     try {
  //       switch (msg) {
  //         case "AppLifecycleState.paused":
  //           _lastLifecyleState = AppLifecycleState.paused;
  //           break;
  //         case "AppLifecycleState.inactive":
  //           _lastLifecyleState = AppLifecycleState.inactive;
  //           break;
  //         case "AppLifecycleState.resumed":
  //           globalState.setGlobalState();
  //           _lastLifecyleState = AppLifecycleState.resumed;
  //           if (mounted)
  //             setState(() {
  //               if (globalState.user.username != null) {
  //                 _username.text = globalState.user.username!;
  //               }
  //             });
  //           //_userCircleBloc.fetchUserCircles(globalState.userFurnaces, true);
  //           break;
  //         case "AppLifecycleState.suspending":
  //           // _lastLifecyleState = AppLifecycleState.suspending;
  //           break;
  //         default:
  //       }
  //     } catch (error, trace) {
  //       LogBloc.insertError(error, trace);
  //       debugPrint('Login.handleAppLifecycleState: $error');
  //       FormattedSnackBar.showSnackbarWithContext(
  //           context, error.toString(), "", 2, true);
  //     }
  //
  //     return Future.value(null);
  //   });
  // }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }
}
