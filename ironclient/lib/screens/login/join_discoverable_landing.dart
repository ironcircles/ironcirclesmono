import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class JoinDiscoverableLanding extends StatefulWidget {
  final UserFurnace? userFurnace;
  final String? toast;
  final HostedFurnace network;

  const JoinDiscoverableLanding({
    Key? key,
    this.toast,
    this.userFurnace,
    required this.network,
  }) : super(key: key);

  @override
  _JoinDiscoverableLandingState createState() =>
      _JoinDiscoverableLandingState();
}

class _JoinDiscoverableLandingState extends State<JoinDiscoverableLanding> {
  UserFurnace? localFurnace;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _message = TextEditingController();

  final TextEditingController _username = TextEditingController();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  ICProgressDialog icProgressDialog = ICProgressDialog();

  int? _radioValue = 1;
  bool _oldEnough = true;
  bool _tos = true;
  bool validatedOnceAlready = false;
  final double _iconPadding = 12;

  final _formKey = GlobalKey<FormState>();

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
    super.initState();

    _radioValue = 2;
    _oldEnough = true;
    _tos = true;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _hostedFurnaceBloc.requestsError.listen((error) {
      if (error == true) {
        globalState.requestedFromLanding = true;
        icProgressDialog.dismiss();
        _goHome();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context,
          "You can no longer request to join this network", "", 3, false);
      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.userFurnace.listen((success) {
      globalState.showHomeTutorial = true;
      globalState.showPrivateVaultPrompt = true;

      _makeRequest();
    }, onError: (err) {
      LogBloc.postLog('Error:$err', 'RegistrationShort');

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .usernameExists, //'Username already exists',
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
      } else if (err.toString().contains('unauthorized')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.tryAgain,
            AppLocalizations.of(context)!.invalidNetworkNameOrCode,
            null,
            null,
            null,
            false);
      } else if (err.toString().toLowerCase().contains('failed last attempt')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .errorFailedLastAttempt, //'Failed Last Attempt',
            AppLocalizations.of(context)!
                .canNoLongerTryToJoinThisNetwork, //'You can no longer try to join this network',
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('exceeded')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .exceededAllowedAttempts, //'Exceeded Allowed Attempts',
            AppLocalizations.of(context)!.cannotTryToJoinThisNetwork,
            null,
            null,
            null,
            false);
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
            AppLocalizations.of(context)!.tryAgain,
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            true);
      }

      debugPrint("error $err");
      setState(() {
        //_showSpinner = false;
      });
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Widget _networkApplyWidgets(BuildContext context, double screenWidth) {
    return Column(
      children: [
        Padding(
            padding:
                const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: ICText(
                      AppLocalizations.of(context)!.requestToJoinNetwork,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.buttonIcon),
                )
              ]),
              const Padding(
                padding: EdgeInsets.only(top: 10),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 20),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                            child: ExpandingText(
                                height: 300,
                                labelText: 'enter request',
                                controller: _message,
                                maxLength: 1000,
                                validator: (value) {
                                  return null;
                                }))
                      ]))
            ]))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    Widget _ageWidgets(BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
            top: 0,
            left: 15,
            right: globalState.isDesktop() ? ScreenSizes.formRightMargin : 10,
            bottom: 0),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 10, top: 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Spacer(),
                    ICText(
                      AppLocalizations.of(context)!.age,
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
                              activeColor: globalState.theme.dialogButtons,
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                          right: 10,
                        )),
                    InkWell(
                        onTap: () {
                          _handleRadioValueChange(1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20),
                          child: ICText("16-17",
                              fontSize: 12,
                              color: globalState.theme.dialogLabel),
                        )),
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
                              activeColor: globalState.theme.dialogButtons,
                              value: 2,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                          right: 10,
                        )),
                    InkWell(
                        onTap: () {
                          _handleRadioValueChange(2);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: ICText("18+",
                              fontSize: 12,
                              color: globalState.theme.dialogLabel),
                        )),
                  ])),
        ]),
      );
    }

    final tos = Padding(
      padding: EdgeInsets.only(
          left: 10,
          right: globalState.isDesktop() ? ScreenSizes.formRightMargin : 10,
          top: 0,
          bottom: 0),
      child: Column(children: [
        Row(children: <Widget>[
          const Spacer(),
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
            AppLocalizations.of(context)!.iAgree,
            fontSize: 12,
          ),
          const Padding(padding: EdgeInsets.only(left: 5)),
          InkWell(
            onTap: _showTOS,
            child: ICText(AppLocalizations.of(context)!.termsOfService,
                color: globalState.theme.buttonIcon, fontSize: 12),
          ),
        ]),
      ]),
    );

    final requestConnectButton =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Spacer(),
      Padding(
          padding:
              const EdgeInsets.only(left: 5, top: 20, bottom: 20, right: 5),
          child: GradientButtonDynamic(
              text: AppLocalizations.of(context)!.requestToJoinButton,
              onPressed: () {
                _requestConnectToNetwork(widget.network);
              }))
    ]);

    final _usernameWidget = Padding(
        padding: const EdgeInsets.only(
            //left: 11, top: 5, bottom: 10, right: 15
            left: 10,
            top: 0,
            bottom: 5,
            right: 10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: ICText('Create your account',
                  fontSize: globalState.userSetting.fontSize,
                  color: globalState.theme.buttonIcon),
            )
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 10),
          ),
          Padding(
              padding: const EdgeInsets.only(left: 10, right: 20),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                        child: ExpandingText(
                            controller: _username,
                            height: 300,
                            labelText: AppLocalizations.of(context)!
                                .createAnAnonymousUsername,
                            //maxLines: 1,
                            maxLength: 25,
                            onChanged: _revalidate,
                            validator: (value) {
                              if (value.toString().endsWith(' ')) {
                                return AppLocalizations.of(context)!
                                    .errorCannotEndWithASpace;
                              } else if (value.toString().isEmpty) {
                                return AppLocalizations.of(context)!
                                    .errorCannotBeEmpty;
                              } else if (value.toString().startsWith(' ')) {
                                return AppLocalizations.of(context)!
                                    .errorCannotStartWithASpace;
                              }

                              return null;
                            }))
                  ]))
        ]));

    return Form(
        key: _formKey,
        child: Scaffold(
            appBar: ICAppBar(
                title: AppLocalizations.of(context)!.joinAPublicNetwork,
                actions: <Widget>[
                  IconButton(
                    padding: EdgeInsets.only(right: _iconPadding),
                    constraints: const BoxConstraints(),
                    iconSize: 27 - globalState.scaleDownIcons,
                    onPressed: () {
                      DialogNotice.showLandingAccountHelp(context);
                    },
                    icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                  )
                ]),
            backgroundColor: globalState.theme.background,
            body: SafeArea(
                left: false,
                top: true,
                right: false,
                bottom: true,
                child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5, right: 5, bottom: 5, top: 0),
                        child: Column(children: [
                          Expanded(
                              child: SingleChildScrollView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  controller: _scrollController,
                                  child: WrapperWidget(
                                      child:Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        _networkApplyWidgets(
                                            context, screenWidth),
                                        _usernameWidget,
                                        tos,
                                        _ageWidgets(context),
                                        requestConnectButton,
                                      ]))))
                        ])))));
  }

  _makeRequest() async {
    String message = _message.text;
    NetworkRequest request = NetworkRequest(
        status: 0,
        hostedFurnace: widget.network,
        user: globalState.user,
        description: message);
    setState(() {
      _hostedFurnaceBloc.makeRequest(globalState.userFurnace!, request);
    });
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

  _handleRadioValueChange(int? value) {
    setState(() {
      _radioValue = value;
      _oldEnough = true;
    });
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }

  _requestConnectToNetwork(HostedFurnace network) async {
    try {
      if (_formKey.currentState!.validate()) {
        if (_username.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.pleaseEnterAUsername, "", 2, false);
        } else if (_tos == false) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.acceptTermsOfService, "", 2, false);
        } else if (!_oldEnough) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.selectAgeOption, "", 2, false);
        } else {
          _closeKeyboard();

          ///show network loading spinner
          icProgressDialog.show(
              context, AppLocalizations.of(context)!.generatingNetwork);

          ///create network
          UserFurnace _userFurnace = UserFurnace();
          String networkBase = _username.text.trim();
          String networkName = "$networkBase's network";
          var available = await _hostedFurnaceBloc.checkName(networkName);
          while (available == false) {
            networkName =
                '$networkBase${SecureRandomGenerator.generateInt(max: 5)}\'s network';

            ///see if the name is already in use
            available = await _hostedFurnaceBloc.checkName(networkName);
          }
          if (available) {
            _userFurnace.alias = networkName;
            _userFurnaceBloc.generateNetwork(
                networkName, _username.text.trim(), _oldEnough);
          }
        }
      } else {
        validatedOnceAlready = true;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
