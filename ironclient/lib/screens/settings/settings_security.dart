import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/encryption/externalkeys.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/settings/settings_swipeattempts.dart';
import 'package:ironcirclesapp/screens/login/login_changepassword1.dart';
import 'package:ironcirclesapp/screens/login/login_changepassword2.dart';
import 'package:ironcirclesapp/screens/login/login_resetpassword.dart';
import 'package:ironcirclesapp/screens/settings/keychainview.dart';
import 'package:ironcirclesapp/screens/settings/settings_accountrecovery.dart';
import 'package:ironcirclesapp/screens/settings/settings_devices.dart';
import 'package:ironcirclesapp/screens/settings/userkeyview.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpasswordauth.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/utils/notification_localization.dart';
import 'package:path/path.dart' as P;
import 'package:provider/provider.dart';
import 'package:ndialog/ndialog.dart';

class SettingsSecurity extends StatefulWidget {
  final User user;
  final UserFurnace? userFurnace;

  const SettingsSecurity(
      {Key? key, required this.user, required this.userFurnace})
      : super(key: key);

  @override
  _SettingsSecurityState createState() => _SettingsSecurityState();
}

class _SettingsSecurityState extends State<SettingsSecurity> {
  final UserBloc _userBloc = UserBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  //bool _showPassword = false;
  final _authBloc = AuthenticationBloc();
  final _keychainBackupBloc = KeychainBackupBloc();
  late UserCircleBloc _userCircleBloc; // = UserCircleBloc();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;

  bool _showRecoveryKey = false;
  bool _guard = false;
  List<int> _pin = [];

  //late PlatformFile _platformFile;

  //User _user = globalState.user;
  UserHelper? _passwordHelper;

  final List<ListItem> _members = [];
  /*List<ListItem> _members1 =[];
  List<ListItem> _members2 =[];
  List<ListItem> _members3 =[];
  List<ListItem> _members4 =[];

   */

  ListItem? _selectedOne;
  ListItem? _selectedTwo;
  ListItem? _selectedThree;
  ListItem? _selectedFour;

  bool showThree = false;
  bool showFour = false;
  //bool? _transparency = false;
  bool _autoKeychainBackup = false;
  bool _passwordBeforeChange = false;
  bool? _showHelpers;
  double _buttonWidth = 230;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  String _recoveryKey = '';

  _loadRecoveryKey() async {
    UserSetting? userSetting =
        await TableUserSetting.read(widget.userFurnace!.userid!);
    _recoveryKey = userSetting!.backupKey;

    //_recoveryKey = await SecureStorageService.readKey(
    //    KeyType.USER_KEYCHAIN_BACKUP + widget.userFurnace!.userid!);
  }

  @override
  void initState() {
    _loadRecoveryKey();
    _members.clear();

    _userCircleBloc = UserCircleBloc(
        globalEventBloc: Provider.of<GlobalEventBloc>(context, listen: false));

    if (globalState.userSetting.patternPinString != null) {
      _guard = true;
      //_pin = globalState.userSetting.patternPinString!.split('').map((e) => int.parse(e)).toList();
      _pin = globalState.userSetting
          .stringToPin(globalState.userSetting.patternPinString!);
    }

    _members.add(ListItem(object: User(), name: ''));

    if (widget.user.autoKeychainBackup == null) {
      //if (widget.userFurnace!.autoKeychainBackup != null)
      _autoKeychainBackup = widget.userFurnace!.autoKeychainBackup!;
    } else
      _autoKeychainBackup = widget.user.autoKeychainBackup!;

    _passwordBeforeChange = widget.user.passwordBeforeChange;

    _keychainBackupBloc.toggleSuccess.listen((autoKeychainBackup) {
      setState(() {
        _autoKeychainBackup = autoKeychainBackup;
        globalState.user.autoKeychainBackup = autoKeychainBackup;
      });
      if (autoKeychainBackup) {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.chatHistoryBackupEnabled,
            "",
            2,
            false);
      } else {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.chatHistoryBackupDisabled,
            "",
            2,
            false);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _authBloc.resetCodeAvailable.listen((yes) {
      if (yes!) {
        _showResetCode();
      } else {
        _askPasswordReset();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _authBloc.resetDone.listen((success) {
      //FormattedSnackBar.showSnackbarWithContext(context, success, "", 2);
      _showSent(success);
    }, onError: (err) {
      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.couldNotResetTitle,
          NotificationLocalization.getLocalizedString(err.toString(), context),
          //err.toString(),
          null,
          null,
          null,
          true);

      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      debugPrint("error $err");
    }, cancelOnError: false);

    ///Listen for membership load
    _userBloc.passwordHelper.listen((passwordHelper) {
      if (mounted) {
        setState(() {
          _passwordHelper = passwordHelper;

          for (User user in _passwordHelper!.members!) {
            _members.add(ListItem(
                object: user, name: user.getUsernameAndAlias(globalState)));
            //_members2.add(ListItem(object: user, name: user.username));
          }

          if (passwordHelper!.helpers!.isNotEmpty)
            _showHelpers = false;
          else
            _showHelpers = true;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _userBloc.keysExported.listen((success) {
      if (success!) {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.exported.toLowerCase(), "", 2, false);

        // Navigator.of(context).pop();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("ExportKeys.initState.keysExported: $err");
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
            _userCircleBloc.fetchHistory();
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

    _userBloc.fetchPasswordHelpers(widget.userFurnace!, widget.user.id!);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
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
                          padding: const EdgeInsets.only(top: 5, bottom: 15),
                          child: Text(
                              AppLocalizations.of(context)!.passwordManagement,
                              textScaler: TextScaler.linear(
                                  globalState.labelScaleFactor),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18 - globalState.scaleDownTextFont,
                                  color: globalState.theme.labelText))),
                      Padding(
                          padding: const EdgeInsets.only(),
                          child: InkWell(
                              onTap: () {
                                _changePassword();
                              },
                              child: Row(children: <Widget>[
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: globalState
                                                .theme.menuBackground,
                                            border: Border.all(
                                                color: Colors.lightBlueAccent
                                                    .withOpacity(.1),
                                                width: 2.0),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(12.0),
                                              topRight: Radius.circular(12.0),
                                            )),
                                        padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 10,
                                            left: 15,
                                            right: 10),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  (globalState.userFurnace!
                                                                  .password !=
                                                              null &&
                                                          globalState
                                                              .userFurnace!
                                                              .password!
                                                              .isNotEmpty)
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .setPasswordAndPin
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .changePasswordAndPin,
                                                  textScaler:
                                                      const TextScaler.linear(
                                                          1.0),
                                                  style: TextStyle(
                                                    fontSize: 16 -
                                                        globalState
                                                            .scaleDownTextFont,
                                                    color: globalState
                                                        .theme.labelText,
                                                  )),
                                              Icon(Icons.keyboard_arrow_right,
                                                  color: globalState
                                                      .theme.labelText,
                                                  size: 25.0)
                                            ])))
                              ]))),
                      // globalState.userFurnace!.password !=
                      //     null ?  Padding(
                      //     padding: const EdgeInsets.only(),
                      //     child: InkWell(
                      //         onTap: () {
                      //           _changePassword();
                      //         },
                      //         child: Row(children: <Widget>[
                      //           Expanded(
                      //               child: Container(
                      //                   decoration: BoxDecoration(
                      //                       color: globalState.theme.menuBackground,
                      //                       border: Border.all(
                      //                           color: Colors.lightBlueAccent
                      //                               .withOpacity(.1),
                      //                           width: 2.0),
                      //                       borderRadius: const BorderRadius.only(
                      //                         topLeft: Radius.circular(12.0),
                      //                         topRight: Radius.circular(12.0),
                      //                       )),
                      //                   padding: const EdgeInsets.only(
                      //                       top: 10,
                      //                       bottom: 10,
                      //                       left: 15,
                      //                       right: 10),
                      //                   child: Row(
                      //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                            "Verify password/pin",
                      //                             textScaler: const TextScaler.linear(1.0),
                      //                             style: TextStyle(
                      //                               fontSize: 16 -
                      //                                   globalState.scaleDownTextFont,
                      //                               color: globalState.theme.labelText,
                      //                             )),
                      //                         Icon(Icons.keyboard_arrow_right,
                      //                             color: globalState.theme.labelText,
                      //                             size: 25.0)
                      //                       ]
                      //                   )
                      //               ))
                      //         ]))) : Container(),
                      Padding(
                          padding: const EdgeInsets.only(),
                          child: InkWell(
                              onTap: () {
                                _accountRecovery();
                              },
                              child: Row(children: <Widget>[
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              globalState.theme.menuBackground,
                                          border: Border.all(
                                              color: Colors.lightBlueAccent
                                                  .withOpacity(.1),
                                              width: 2.0),
                                        ),
                                        padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 10,
                                            left: 15,
                                            right: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                globalState.userSetting
                                                        .accountRecovery
                                                    ? AppLocalizations.of(
                                                            context)!
                                                        .editAccountRecovery
                                                    : AppLocalizations.of(
                                                            context)!
                                                        .setupAccountRecovery,
                                                textScaler:
                                                    const TextScaler.linear(
                                                        1.0),
                                                style: TextStyle(
                                                  fontSize: 16 -
                                                      globalState
                                                          .scaleDownTextFont,
                                                  color: globalState
                                                      .theme.labelText,
                                                )),
                                            Icon(Icons.keyboard_arrow_right,
                                                color:
                                                    globalState.theme.labelText,
                                                size: 25.0),
                                          ],
                                        )))
                              ]))),
                      Padding(
                          padding: const EdgeInsets.only(),
                          child: InkWell(
                              onTap: () {
                                _checkResetCodeAvailable();
                              },
                              child: Row(children: <Widget>[
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: globalState
                                                .theme.menuBackground,
                                            border: Border.all(
                                                color: Colors.lightBlueAccent
                                                    .withOpacity(.1),
                                                width: 2.0),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(12.0),
                                              bottomRight:
                                                  Radius.circular(12.0),
                                            )),
                                        padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 10,
                                            left: 15,
                                            right: 10),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .forgotPasswordOrPin, //'Forgot Password or Pin?',
                                            textScaler:
                                                const TextScaler.linear(1.0),
                                            style: TextStyle(
                                              fontSize: 16 -
                                                  globalState.scaleDownTextFont,
                                              color:
                                                  globalState.theme.labelText,
                                            ))))
                              ]))),
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
                                activeColor: globalState.theme.button,
                                contentPadding: const EdgeInsets.only(left: 10),
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .requirePpassPinBeforeChange, //'Require pass/pin before change?',
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontSize:
                                          16 - globalState.scaleDownTextFont,
                                      color: globalState.theme.textFieldLabel),
                                ),
                                value: _passwordBeforeChange,
                                onChanged: (bool value) {
                                  _askRequirePassword(value);
                                },
                              ),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? const Padding(
                              padding: EdgeInsets.only(top: 15, bottom: 5),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(
                                  AppLocalizations.of(context)!.appSecurity,
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          18 - globalState.scaleDownTextFont,
                                      color: globalState.theme.labelText)))
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? SwitchListTile(
                              inactiveThumbColor:
                                  globalState.theme.inactiveThumbColor,
                              inactiveTrackColor:
                                  globalState.theme.inactiveTrackColor,
                              trackOutlineColor:
                                  MaterialStateProperty.resolveWith(
                                      globalState.getSwitchColor),
                              activeColor: globalState.theme.button,
                              contentPadding: const EdgeInsets.only(left: 10),
                              title: Text(
                                AppLocalizations.of(context)!.patternGuardApp,
                                textScaler: TextScaler.linear(
                                    globalState.labelScaleFactor),
                                style: TextStyle(
                                    fontSize:
                                        16 - globalState.scaleDownTextFont,
                                    color: globalState.theme.textFieldLabel),
                              ),
                              value: _guard,
                              onChanged: (value) {
                                _setAppGuarded(value);
                              },
                            )
                          : Container(),

                      Padding(
                          padding: const EdgeInsets.only(),
                          child: InkWell(
                              onTap: () {
                                _openSwipeAttempts();
                              },
                              child: Row(children: <Widget>[
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: globalState
                                                .theme.menuBackground,
                                            border: Border.all(
                                                color: Colors.lightBlueAccent
                                                    .withOpacity(.1),
                                                width: 2.0),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(12.0),
                                            )),
                                        padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 10,
                                            left: 15,
                                            right: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                AppLocalizations.of(context)!
                                                    .viewFailedPatternAttempts,
                                                textScaler:
                                                    const TextScaler.linear(
                                                        1.0),
                                                style: TextStyle(
                                                  fontSize: 16 -
                                                      globalState
                                                          .scaleDownTextFont,
                                                  color: globalState
                                                      .theme.labelText,
                                                )),
                                            Icon(Icons.keyboard_arrow_right,
                                                color:
                                                    globalState.theme.labelText,
                                                size: 25.0),
                                          ],
                                        )))
                              ]))),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding: const EdgeInsets.only(),
                              child: InkWell(
                                  onTap: () {
                                    _resetKyberKey();
                                  },
                                  child: Row(children: <Widget>[
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
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(12.0),
                                                  bottomRight:
                                                      Radius.circular(12.0),
                                                )),
                                            padding: const EdgeInsets.only(
                                                top: 10,
                                                bottom: 10,
                                                left: 15,
                                                right: 10),
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .resetKyberKey, //'Forgot Password or Pin?',
                                                textScaler:
                                                    const TextScaler.linear(
                                                        1.0),
                                                style: TextStyle(
                                                  fontSize: 16 -
                                                      globalState
                                                          .scaleDownTextFont,
                                                  color: globalState
                                                      .theme.labelText,
                                                ))))
                                  ])))
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? const Padding(
                              padding: EdgeInsets.only(top: 20),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 0),
                              child: Row(children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)!.devices,
                                  textScaler: TextScaler.linear(
                                      globalState.textFieldScaleFactor),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          18 - globalState.scaleDownTextFont,
                                      color: globalState.theme.labelText),
                                ),
                              ]),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? const Padding(
                              padding: EdgeInsets.only(top: 10),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding: const EdgeInsets.only(),
                              child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsDevices(),
                                        ));
                                  },
                                  child: Row(children: <Widget>[
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
                                                    const BorderRadius.all(
                                                  Radius.circular(12.0),
                                                )),
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
                                                        .viewDeviceList,
                                                    textScaler:
                                                        const TextScaler.linear(
                                                            1.0),
                                                    style: TextStyle(
                                                      fontSize: 16 -
                                                          globalState
                                                              .scaleDownTextFont,
                                                      color: globalState
                                                          .theme.labelText,
                                                    )),
                                                Icon(Icons.keyboard_arrow_right,
                                                    color: globalState
                                                        .theme.labelText,
                                                    size: 25.0),
                                              ],
                                            )))
                                  ])))
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? const Padding(
                              padding: EdgeInsets.only(top: 20),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(
                                  AppLocalizations.of(context)!.chatHistory,
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          18 - globalState.scaleDownTextFont,
                                      color: globalState.theme.labelText)))
                          : Container(),
                      widget.userFurnace!.authServer! &&
                              widget.user.role == Role.IC_ADMIN
                          ? TextButton(
                              onPressed: () {
                                setState(() {
                                  _showRecoveryKey = !_showRecoveryKey;
                                });
                              },
                              child: Text(
                                AppLocalizations.of(context)!
                                    .showBackupKey, //'Show Backup Key',
                                style: TextStyle(
                                    fontSize:
                                        16 - globalState.scaleDownTextFont,
                                    color: globalState.theme.buttonIcon),
                              ))
                          : Container(),
                      _showRecoveryKey
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, top: 5, bottom: 5),
                              child: SelectableText(_recoveryKey,
                                  style: TextStyle(
                                    fontSize:
                                        10 - globalState.scaleDownTextFont,
                                    color: globalState.theme.labelText,
                                  )))
                          : Container(),
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
                                activeColor: globalState.theme.button,
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .backupChatHistory, //'Backup chat history?',
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  style: TextStyle(
                                      fontSize:
                                          16 - globalState.scaleDownTextFont,
                                      color: globalState.theme.textFieldLabel),
                                ),
                                value: _autoKeychainBackup,
                                onChanged: (bool value) {
                                  _enableAutoKeychainBackup(value);
                                },
                              ),
                            )
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? _autoKeychainBackup
                              ? Padding(
                                  padding: const EdgeInsets.only(),
                                  child: InkWell(
                                      onTap: () {
                                        _backupNow();
                                      },
                                      child: Row(children: <Widget>[
                                        Expanded(
                                            child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState
                                                  .theme.menuBackground,
                                              border: Border.all(
                                                  color: Colors.lightBlueAccent
                                                      .withOpacity(.1),
                                                  width: 2.0),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                              )),
                                          padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 15,
                                              right: 10),
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .backupNow, //'Backup Now',
                                              textScaler:
                                                  const TextScaler.linear(1.0),
                                              style: TextStyle(
                                                fontSize: 16 -
                                                    globalState
                                                        .scaleDownTextFont,
                                                color:
                                                    globalState.theme.labelText,
                                              )),
                                        ))
                                      ])))
                              : Container()
                          : Container(),
                      widget.userFurnace!.authServer!
                          ? _autoKeychainBackup
                              ? Padding(
                                  padding: const EdgeInsets.only(),
                                  child: InkWell(
                                      onTap: () {
                                        _restoreChatHistory();
                                      },
                                      child: Row(children: <Widget>[
                                        Expanded(
                                            child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState
                                                  .theme.menuBackground,
                                              border: Border.all(
                                                  color: Colors.lightBlueAccent
                                                      .withOpacity(.1),
                                                  width: 2.0),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(12.0),
                                                bottomRight:
                                                    Radius.circular(12.0),
                                              )),
                                          padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 15,
                                              right: 10),
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .restoreChatHistory,
                                              textScaler:
                                                  const TextScaler.linear(1.0),
                                              style: TextStyle(
                                                fontSize: 16 -
                                                    globalState
                                                        .scaleDownTextFont,
                                                color:
                                                    globalState.theme.labelText,
                                              )),
                                        ))
                                      ])))
                              : Container()
                          : Container(),
                      (globalState.user.role == Role.IC_ADMIN ||
                              globalState.user.role == Role.DEBUG)
                          ? const Padding(
                              padding: EdgeInsets.only(top: 15, bottom: 15),
                            )
                          : Container(),
                      // (globalState.user.role == Role.IC_ADMIN ||
                      //         globalState.user.role == Role.DEBUG)
                      //     ? Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //             Padding(
                      //                 padding: const EdgeInsets.only(
                      //                     top: 5, bottom: 5),
                      //                 child: Text(
                      //                     AppLocalizations.of(context)!
                      //                         .encryptionKeyManagement, //'Encryption Key Management:',
                      //                     style: TextStyle(
                      //                         fontWeight: FontWeight.bold,
                      //                         fontSize: 18 -
                      //                             globalState.scaleDownTextFont,
                      //                         color: globalState
                      //                             .theme.labelText))),
                      //             Padding(
                      //               padding: const EdgeInsets.only(
                      //                   top: 5, bottom: 0),
                      //               child: Row(children: <Widget>[
                      //                 //Expanded(flex: 1, child: Container()),
                      //                 Expanded(
                      //                   flex: 2,
                      //                   child: GradientButton(
                      //                       textColor: globalState.theme.button,
                      //                       color2: globalState
                      //                           .theme.labelTextSubtle,
                      //                       color1:
                      //                           globalState.theme.background,
                      //                       text: AppLocalizations.of(context)!
                      //                           .vIEWRAWKEYCHAINDATA,
                      //                       onPressed: () {
                      //                         _viewKeys();
                      //                         //_authenticatePasswordForKeychainView();
                      //                       }),
                      //                 ),
                      //               ]),
                      //             ),
                      //             Padding(
                      //               padding: const EdgeInsets.only(
                      //                   top: 5, bottom: 0),
                      //               child: Row(children: <Widget>[
                      //                 //Expanded(flex: 1, child: Container()),
                      //                 Expanded(
                      //                   flex: 2,
                      //                   child: GradientButton(
                      //                       textColor: globalState.theme.button,
                      //                       color1: globalState
                      //                           .theme.labelTextSubtle,
                      //                       color2: globalState
                      //                           .theme.labelTextSubtle,
                      //                       text: AppLocalizations.of(context)!
                      //                           .vIEWUSERKEYDATA,
                      //                       onPressed: () {
                      //                         _viewUserKeys();
                      //                       }),
                      //                 ),
                      //               ]),
                      //             )
                      //     //         Padding(
                      //     //           padding: const EdgeInsets.only(
                      //     //               top: 5, bottom: 0),
                      //     //           child: Row(children: <Widget>[
                      //     //             //Expanded(flex: 1, child: Container()),
                      //     //             Expanded(
                      //     //               flex: 2,
                      //     //               child: GradientButton(
                      //     //                   textColor: globalState.theme.button,
                      //     //                   color1: globalState
                      //     //                       .theme.labelTextSubtle,
                      //     //                   color2: globalState
                      //     //                       .theme.labelTextSubtle,
                      //     //                   text: AppLocalizations.of(context)!
                      //     //                       .dOWNLOADKEYCHAIN,
                      //     //                   onPressed: () {
                      //     //                     _verifyExportKeys();
                      //     //                   }),
                      //     //             ),
                      //     //           ]),
                      //     //        ),
                      //           ])
                      //      : Container()

                      /*widget.userFurnace!.authServer!
                      ? Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Divider(
                            color: globalState.theme.screenLink,
                            height: 2,
                            thickness: 2,
                            indent: 0,
                            endIndent: 0,
                          ))
                      : Container(),
                  widget.userFurnace!.authServer!
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 0),
                          child: Row(children: <Widget>[
                            Text(
                              'Enable user login audit trail?',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: globalState.theme.labelText),
                            ),
                            //secondary: const Icon(Icons.remove_red_eye),
                          ]),
                        )
                      : Container(),



                  // Spacer(flex: 1),

                  widget.userFurnace!.authServer!
                      ? Padding(
                          padding: const EdgeInsets.only(top: 0, bottom: 10),
                          child: Row(children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: Container(
                                //color: globalState.theme.textField,
                                child: SwitchListTile(
                                  title: Text(
                                    _transparency! ? "Enabled" : "Disabled",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            globalState.theme.textFieldLabel),
                                  ),
                                  value: _transparency!,
                                  onChanged: (bool value) {
                                    setState(() {
                                      if (value) {
                                        DialogPasswordAuth.passwordPopup(
                                            context,
                                            widget
                                                .userFurnace!, //globalState.userFurnace!,
                                            _success);
                                      } else
                                        _flip(false);
                                    });
                                  },
                                  //secondary: const Icon(Icons.remove_red_eye),
                                ),
                              ),
                            ),
                            _transparency!
                                ? Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 35,
                                      child: GradientButton(
                                          text: 'View users',
                                          onPressed: () {
                                            //_clearCache(context);
                                            _viewUsers(context);
                                          }),
                                    ))
                                : Spacer(flex: 2),
                          ]),
                        )
                      : Container(),

                   */
                    ]),
              ),
            )));

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          //appBar: topAppBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: makeBody,
              ),
              Container(
                padding: const EdgeInsets.all(0.0),
                //child: makeBottom,
              ),
            ],
          ),
        ));
  }

  _setShowHelpers() {
    //Navigator.of(context).pop();
    // if (mounted)
    setState(() {
      _showHelpers = true;
    });
  }

  _changePassword() {
    if (globalState.user.passwordBeforeChange)
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePassword1(
              //imageProvider:
              //  const AssetImage("assets/large-image.jpg"),
              username: widget.user.username,
              screenType: PassScreenType.CHANGE_PASSWORD,
              userFurnace: widget.userFurnace,
            ),
          ));
    else
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePassword2(
              existingPassword: '',
              existingPin: '',
              username: widget.user.username!,
              screenType: PassScreenType.CHANGE_PASSWORD,
              userFurnace: widget.userFurnace,
            ),
          ));
  }

  Future<void> _askOnlyOne(BuildContext context) async {
    DialogYesNo.askYesNo(context, AppLocalizations.of(context)!.onlyOneTitle,
        AppLocalizations.of(context)!.onlyOneMessage, _yesOne, null, false);
  }

  _yesOne() {
    _callUpdateMembers();
  }

  _callUpdateMembers() {
    _userBloc.updatePasswordHelpers(widget.userFurnace!, _passwordHelper!);
  }

  _addMember(ListItem? item) {
    if (item != null) {
      if (item.name!.isNotEmpty) {
        User user = _passwordHelper!.members!
            .firstWhere((element) => element.id == item.object.id);

        if (!_passwordHelper!.helpers!.contains(user))
          _passwordHelper!.helpers!.add(user);
      }
    }
  }

  _updateMembers() {
    try {
      if (_passwordHelper!.helpers!.isNotEmpty)
        _passwordHelper!.helpers!.clear();

      _addMember(_selectedOne);
      _addMember(_selectedTwo);
      _addMember(_selectedThree);
      _addMember(_selectedFour);

      if (_passwordHelper!.helpers!.isEmpty) {
        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.noOneSelected, "", 1, false);
      } else if (_passwordHelper!.helpers!.length == 1) {
        _askOnlyOne(context);
      } else {
        _callUpdateMembers();
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('SettingsPassword._updateMembers: $err');
    }
  }

  // void _verifyExportKeys() {
  //   _exportKeys();
  //   /*DialogPasswordAuth.passwordPopup(
  //       context,
  //       widget.userFurnace!,
  //       /*widget.userFurnace!.username*/
  //       _exportKeys);
  //
  //    */
  // }

  // void _viewKeys() async {
  //   await Future.delayed(const Duration(milliseconds: 100));
  //
  //   if (mounted) {
  //     Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => KeychainView(
  //               userFurnace: widget.userFurnace!, user: globalState.user),
  //         ));
  //   }
  // }

  void _viewUserKeys() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserKeyView(
                userFurnace: widget.userFurnace!, user: globalState.user),
          ));
    }
  }

  /*void _importKeys() async {
    await Future.delayed(const Duration(milliseconds: 100));

    bool? success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImportKeys(userFurnace: widget.userFurnace!),
        ));

    if (success != null && success)
      FormattedSnackBar.showSnackbarWithContext(
          context, "keys imported", "", 1);
  }*/
  //
  // void _exportKeys() async {
  //
  //
  //   try {
  //     bool? success;
  //
  //     //String backupKey = await SecureStorageService.readKey(
  //     //   KeyType.USER_KEYCHAIN_BACKUP + widget.userFurnace!.userid!);
  //     UserSetting? userSetting =
  //         await TableUserSetting.read(widget.userFurnace!.userid!);
  //     String backupKey = userSetting!.backupKey;
  //
  //     List<UserFurnace>? userFurnaces =
  //         await TableUserFurnace.readAllForUser(widget.userFurnace!.userid!);
  //
  //     File file = await ExternalKeys.saveToFile(
  //         globalState.user.id!,
  //         globalState.user.username!,
  //         backupKey,
  //         true,
  //         widget.userFurnace!,
  //         userFurnaces,
  //         globalState.userSetting);
  //
  //     P.extension(file.path);
  //
  //     if (Platform.isAndroid) {
  //       /*success = await Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) => DownloadFile(
  //                     file: file,
  //                     defaultPath: globalState.downloadDirectory,
  //                     extension: P.extension(file.path),
  //                     fileName: P.basenameWithoutExtension(file.path),
  //                   ))); //.then(_circleObjectBloc.requestNewerThan(
  //
  //        */
  //       if (mounted) {
  //         await DialogDownload.showAndDownloadFiles(
  //           context,
  //           AppLocalizations.of(context)!.downloadingFile,
  //           [file],
  //         );
  //
  //         success = true;
  //       }
  //     } else {
  //       Share.shareXFiles([XFile(file.path)],
  //           text: AppLocalizations.of(context)!.keychainExport);
  //       success = true;
  //     }
  //
  //     /*if (success != null && success)
  //       _userBloc.updateKeysExported(widget.userFurnace);
  //
  //      */
  //
  //     /* await Future.delayed(const Duration(milliseconds: 100));
  //
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ExportKeys(widget.userFurnace!),
  //       ));
  //
  //   */
  //   } catch (err, trace) {
  //     if (!err.toString().contains('backup is up to date'))
  //       LogBloc.insertError(err, trace);
  //     debugPrint("KeychainBackupService.backup $err");
  //
  //     FormattedSnackBar.showSnackbarWithContext(
  //         context, err.toString(), "", 2, true);
  //   }
  // }

  void _backupNow() async {
    try {
      late String result;

      if (widget.userFurnace != null &&
          (widget.userFurnace!.type == NetworkType.SELF_HOSTED ||
              widget.userFurnace!.authServer == true)) {
        result =
            await KeychainBackupBloc.backupDevice(widget.userFurnace!, true);
      } else {
        result = await KeychainBackupBloc.backupDevice(
            globalState.userFurnace!, true);
      }

      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context, result, "", 2, false);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('SettingSecurity._backupNow: $err');
    }
  }

  void _enableAutoKeychainBackup(bool enable) async {
    if (enable) {
      await Future.delayed(const Duration(milliseconds: 100));

      _keychainBackupBloc.toggle(widget.userFurnace!, enable);
    } else {
      //update the serverside config
      _keychainBackupBloc.toggle(widget.userFurnace!, enable);
    }
  }

  Future<void> _askRequirePassword(bool enable) async {
    if (globalState.userFurnace!.password != null &&
        globalState.userFurnace!.password!.isNotEmpty) {
      DialogNotice.showNoticeOptionalLines(
        context,
        AppLocalizations.of(context)!.passwordNotSetTitle,
        AppLocalizations.of(context)!.passwordNotSetMessage,
        false,
      );
    } else if (enable) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.requirePasswordTitle,
          AppLocalizations.of(context)!.requirePasswordMessage,
          _yesRequirePassword,
          null,
          false,
          enable);
    } else {
      _enablePasswordBeforeChange(enable);
    }
  }

  _yesRequirePassword(bool enable) {
    //_enablePasswordBeforeChange(enable);
    DialogPasswordAuth.passwordPopup(_scaffoldKey.currentContext!,
        widget.userFurnace!, _turnOnPasswordBeforeChange);
  }

  void _enablePasswordBeforeChange(bool enable) async {
    if (enable == true) {
      _userBloc.enablePasswordBeforeChange(widget.userFurnace!, enable);

      setState(() {
        _passwordBeforeChange = enable;
      });
    } else {
      DialogPasswordAuth.passwordPopup(_scaffoldKey.currentContext!,
          widget.userFurnace!, _turnOffPasswordBeforeChange);
    }
  }

  void _turnOnPasswordBeforeChange() async {
    _enablePasswordBeforeChange(true);
  }

  void _turnOffPasswordBeforeChange() async {
    _userBloc.enablePasswordBeforeChange(widget.userFurnace!, false);

    if (mounted) {
      setState(() {
        _passwordBeforeChange = false;
      });
    }
  }

  _checkResetCodeAvailable() {
    _authBloc.checkResetCodeAvailable(
        widget.userFurnace!.username!, widget.userFurnace!);
  }

  void _showResetCode() {
    //DialogRestCodeFragments.codeFragmentsPopup(
    //  context, _username.text, _validCodeFragments);

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPassword(
              //imageProvider:
              //  const AssetImage("assets/large-image.jpg"),
              username: widget.userFurnace!.username,
              //screenType: PassScreenType.RESET_CODE,
              userFurnace: widget.userFurnace),
        ));
  }

  _accountRecovery() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsAccountRecovery(
            userFurnace: widget.userFurnace,
            user: widget.user,
          ),
        ));

    if (mounted) setState(() {});
  }

  void _askPasswordReset() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.forgotPasswordTitle,
        AppLocalizations.of(context)!.forgotPasswordMessage,
        _passwordResetYes,
        null,
        false);
  }

  void _passwordResetYes() {
    _authBloc.generateResetCode(
        widget.userFurnace!.username, widget.userFurnace);
  }

  _showSent(success) async {
    await DialogNotice.showNotice(
        context,
        AppLocalizations.of(context)!.codeFragmentsSentTitle,
        success,
        null,
        null,
        null,
        false);
    _showResetCode();
  }

  _guardApp() {
    _guard = true;
    _userBloc.setPin(_pin, widget.user, widget.userFurnace!);
    FormattedSnackBar.showSnackbarWithContext(
        context, AppLocalizations.of(context)!.swipePatternSet, "", 2, false);
  }

  _unguardApp() {
    _guard = false;
    _pin = [];
    _userBloc.unsetPin();
    FormattedSnackBar.showSnackbarWithContext(context,
        AppLocalizations.of(context)!.swipePatternRemoved, "", 2, false);
  }

  _pinBCaptured(List<int> pin) async {
    setState(() {
      if (listEquals(pin, _pin)) {
        _guardApp();
      } else {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.patternsDoNotMatch, "", 2, false);
      }
    });
  }

  _pinACaptured(List<int> pin) async {
    debugPrint(pin.toString());
    _pin = pin;
    await DialogPatternCapture.capture(context, _pinBCaptured,
        AppLocalizations.of(context)!.pleaseReswipePattern);
  }

  _pinCaptured(List<int> pin) {
    try {
      if (listEquals(pin, _pin)) {
        setState(() {
          _unguardApp();
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaptured: $err');
    }
  }

  _setAppGuarded(value) async {
    if (value == true) {
      await DialogPatternCapture.capture(
          context, _pinACaptured, AppLocalizations.of(context)!.swipePattern);
    } else {
      DialogPatternCapture.capture(context, _pinCaptured,
          AppLocalizations.of(context)!.swipePatternToEnter);
    }
  }

  _openSwipeAttempts() async {
    var result = Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SwipeAttemptsList(
                user: widget.user, userFurnace: widget.userFurnace!)));
  }

  _resetKyberKey() async {
    DeviceBloc deviceBloc = DeviceBloc();

    await deviceBloc.updateKyberPublicKey(await globalState.getDevice());

    FormattedSnackBar.showSnackbarWithContext(
        context, AppLocalizations.of(context)!.kyberKeyReset, "", 2, false);
  }

  _restoreChatHistory() {
    ///first pull all keys down
    _keychainBackupBloc.prepRestore(
        _authBloc, widget.userFurnace!, widget.user, true);

    ///then start the usercircles when the event is received
  }
}
