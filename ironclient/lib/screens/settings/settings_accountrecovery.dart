import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptstring.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpasswordauth.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SettingsAccountRecovery extends StatefulWidget {
  final User user;
  final UserFurnace? userFurnace;

  const SettingsAccountRecovery(
      {Key? key, required this.user, required this.userFurnace})
      : super(key: key);

  @override
  _SettingsAccountRecoveryState createState() =>
      _SettingsAccountRecoveryState();
}

class _SettingsAccountRecoveryState extends State<SettingsAccountRecovery> {
  final UserBloc _userBloc = UserBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  UserHelper? _passwordHelper;

  final List<ListItem> _members = [];
  ListItem? _selectedOne;
  ListItem? _selectedTwo;
  ListItem? _selectedThree;
  ListItem? _selectedFour;

  bool showThree = false;
  bool showFour = false;
  bool? _showHelpers;

  bool _showSpinner = false;
  final _spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  String _recoveryKey = '';

  @override
  void initState() {
    _members.clear();
    _members.add(ListItem(object: User(), name: ''));

    //Listen for membership load
    _userBloc.recoveryKey.listen((ratchetIndex) async {
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });

        await Clipboard.setData(ClipboardData(
            text: _recoveryKey)); //copy with the hypens.  It's prettier
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.copiedToClipboard, "", 2,  false);
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    //Listen for membership load
    _userBloc.passwordHelper.listen((passwordHelper) {
      if (mounted) {
        setState(() {
          _passwordHelper = passwordHelper;
          _showSpinner = false;

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
      setState(() {
        _showSpinner = false;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _userBloc.fetchPasswordHelpers(widget.userFurnace!, widget.user.id!);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final addResetMember = Padding(
        padding: const EdgeInsets.only(right: 0),
        child: Ink(
          decoration: ShapeDecoration(
            color: globalState.theme.buttonIcon,
            shape: const CircleBorder(),
          ),
          child: IconButton(
            iconSize: 25,
            icon: const Icon(Icons.add),
            color: globalState.theme.background,
            onPressed: () {
              setState(() {
                if (!showThree)
                  showThree = true;
                else
                  showFour = true;

                //show = true;
              });
            },
          ),
        ));

    final makeHelpers = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
                flex: 1,
                child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 70, bottom: 10),
                    child: FormattedDropdownObject(
                      hintText: AppLocalizations.of(context)!.helper1, //'helper #1',
                      selected: _selectedOne ?? _members[0],
                      list: _members,
                      // selected: _selectedOne,
                      underline: globalState.theme.bottomHighlightIcon,
                      onChanged: (ListItem? value) {
                        setState(() {
                          _selectedOne = value;
                        });
                      },
                    ))),
          ]),
          Row(children: <Widget>[
            Expanded(
                flex: 1,
                child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom:10),
                    child: FormattedDropdownObject(
                      hintText: AppLocalizations.of(context)!.helper2, //'helper #2',
                      selected: _selectedTwo ?? _members[0],
                      list: _members,
                      // selected: _selectedOne,
                      underline: globalState.theme.bottomHighlightIcon,
                      onChanged: (ListItem? value) {
                        setState(() {
                          _selectedTwo = value;
                        });
                      },
                    ))),
            showThree
                ? const Padding(
                    padding: EdgeInsets.only(left: 0, right: 50, bottom: 0),
                  )
                : addResetMember,
          ]),
          showThree
              ? Row(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10),
                          child: FormattedDropdownObject(
                            hintText: AppLocalizations.of(context)!.helper3, //'helper #3',
                            selected: _selectedThree ?? _members[0],
                            list: _members,
                            // selected: _selectedOne,
                            underline: globalState.theme.bottomHighlightIcon,
                            onChanged: (ListItem? value) {
                              setState(() {
                                _selectedThree = value;
                              });
                            },
                          ))),
                  showFour
                      ? const Padding(
                          padding:
                              EdgeInsets.only(left: 0, right: 50, bottom: 0),
                        )
                      : addResetMember
                ])
              : Container(),
          showFour
              ? Row(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 0),
                          child: FormattedDropdownObject(
                            hintText: AppLocalizations.of(context)!.helper4, //'helper #4',
                            selected: _selectedFour ?? _members[0],
                            list: _members,
                            // selected: _selectedOne,
                            underline: globalState.theme.bottomHighlightIcon,
                            onChanged: (ListItem? value) {
                              setState(() {
                                _selectedFour = value;
                              });
                            },
                          ))),
                  const Padding(
                    padding: EdgeInsets.only(left: 0, right: 50, bottom: 0),
                  ),
                ])
              : Container(),
          const Padding(
            padding: EdgeInsets.only(left: 0, right: 0, bottom: 10),
          ),
          Row(children: <Widget>[
            Expanded(
              flex: 20,
              child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: ButtonType.getWidth(
                          MediaQuery.of(context).size.width)),
                  child: GradientButton(
                      text: AppLocalizations.of(context)!.updateHelpers, //'UPDATE HELPERS',
                      onPressed: () {
                        _updateMembers();
                      })),
            ),
          ]),
        ]);

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 20),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(
                          AppLocalizations.of(context)!.accountRecoveryText, //'To project your privacy, IronCircles cannot reset your password. To recover your account in the event you lose your device or forget your pass/pin, please assign helpers.', //please do at least one of the following:',
                          textScaler: TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              fontSize: 16,
                              color: globalState.theme.labelText))),
                  const Divider(
                    color: Colors.grey,
                    height: 2,
                    thickness: 2,
                    indent: 0,
                    endIndent: 0,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 10, bottom: 0),
                    child: Row(children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.assignHelpers, //'Assign Helpers',
                        textScaler: TextScaler.linear(globalState.textFieldScaleFactor),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: globalState.theme.labelText),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: IconButton(
                            icon: const Icon(Icons.help),
                            iconSize: 25,
                            color: globalState.theme.bottomIcon,
                            onPressed: () {
                              setState(() {
                                DialogNotice.showNotice(
                                  context,
                                  AppLocalizations.of(context)
                                      !.accountRecoveryHelpersTitle,
                                  AppLocalizations.of(context)
                                      !.accountRecoveryHelpersMessage1,
                                  AppLocalizations.of(context)
                                      !.accountRecoveryHelpersMessage3,
                                  AppLocalizations.of(context)
                                      !.accountRecoveryHelpersMessage3,
                                  '',
                                  false,
                                );
                              });
                            },
                          )),
                      const Spacer(),
                      //secondary: const Icon(Icons.remove_red_eye),
                    ]),
                  ),
                  _showHelpers == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          child: Center(child: _spinkit))
                      : _showHelpers!
                          ? makeHelpers
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                  const Padding(
                                      padding:
                                          EdgeInsets.only(top: 10, bottom: 0)),
                                  Center(
                                      child: Row(children: <Widget>[
                                    const Padding(
                                        padding: EdgeInsets.only(left: 30)),
                                    Expanded(
                                        child: ICText(
                                            AppLocalizations.of(context)!.recoveryHelpersSet,
                                            textAlign: TextAlign.start,
                                            fontSize: 18,
                                            color:
                                                globalState.theme.labelText)),
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: ClipOval(
                                            child: Material(
                                          color: globalState
                                              .theme.buttonIcon, // button color
                                          child: SizedBox(
                                              width: 25,
                                              height: 25,
                                              child: Icon(
                                                Icons.check,
                                                color: globalState
                                                    .theme.background,
                                              )),
                                        )))
                                  ])),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        TextButton(
                                            child: ICText(
                                                AppLocalizations.of(context)!.resetAssistMembers,
                                                textAlign: TextAlign.end,
                                                color: globalState
                                                    .theme.buttonIcon),
                                            onPressed: () {
                                              if (globalState.userSetting
                                                  .passwordBeforeChange)
                                                _authenticatePassword();
                                              else
                                                _setShowHelpers();
                                              //_showHelpers = true;
                                            })

                                        /// })
                                      ]),
                                  const Padding(
                                      padding:
                                          EdgeInsets.only(top: 0, bottom: 10)),
                                ]),
                ]),
          ),
        ));

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: ICAppBar(
            title: AppLocalizations.of(context)!.accountRecovery, //'Account Recovery',
          ),
          body: Stack(children: [
            Column(
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
            _showSpinner ? _spinkit : Container(),
          ]),
        ));
  }

  _authenticatePassword() async {
    DialogPasswordAuth.passwordPopup(
        _scaffoldKey.currentContext!, widget.userFurnace!, _setShowHelpers);

    /*
    if (success != null) {
      setState(() {
        _showHelpers = true;
      });
    }*/
  }

  _setShowHelpers() {
    //Navigator.of(context).pop();
    // if (mounted)
    setState(() {
      _showHelpers = true;
    });
  }

  Future<void> _askOnlyOne(BuildContext context) async {
    DialogYesNo.askYesNo(context, AppLocalizations.of(context)!.onlyOneTitle,
        AppLocalizations.of(context)!.onlyOneMessage, _yesOne, null, false);
  }

  _yesOne() {
    _callUpdateMembers();
  }

  _callUpdateMembers() {
    setState(() {
      _showSpinner = true;
    });
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
            context, AppLocalizations.of(context)!.noOneSelected, "", 1,  false);
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

  _generateRecoveryKey() async {
    try {
      setState(() {
        _showSpinner = true;
      });

      _recoveryKey = base64UrlEncode((await ForwardSecrecy.genSecretKey()));

      RatchetIndex ratchetIndex = await EncryptString.encryptString(
          _recoveryKey, widget.userFurnace!.userid!);

      _userBloc.updateRecoveryRatchetIndex(widget.userFurnace!, ratchetIndex);
    } catch (err, trace) {
      setState(() {
        _showSpinner = false;
      });
      LogBloc.insertError(err, trace);
      debugPrint('SettingsPassword._updateMembers: $err');
    }
  }
}
