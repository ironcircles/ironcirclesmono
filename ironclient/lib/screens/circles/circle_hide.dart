import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CircleHide extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final List<UserFurnace> userFurnaces;

  const CircleHide({required this.userCircleCache, required this.userFurnaces});

  @override
  _HiddenCirclesPassphraseState createState() =>
      _HiddenCirclesPassphraseState();
}

class _HiddenCirclesPassphraseState extends State<CircleHide> {
  //final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  final ScrollController _scrollController = ScrollController();

  bool _vault = false;
  bool validatedOnceAlready = false;

  @override
  void initState() {
    super.initState();

    if (widget.userCircleCache.cachedCircle !=
        null) if (widget.userCircleCache.cachedCircle!.type == CircleType.VAULT)
      _vault = true;
  }

  @override
  Widget build(BuildContext context) {
    final showDisclaimer = ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, top: 10, bottom: 0, right: 10),
                child: Row(children: <Widget>[
                  Expanded(
                      flex: 20,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          _vault
                              ? AppLocalizations.of(context)!
                                  .enterAPasscodeToHideThisVault
                              : widget.userCircleCache.dm
                                  ? AppLocalizations.of(context)!
                                      .enterAPasscodeToHideThisDM
                                  : AppLocalizations.of(context)!
                                      .enterAPasscodeToHideThisCircle,
                          //'Enter a passcode to hide this ${_vault ? 'Vault' : widget.userCircleCache.dm ? 'DM' : 'Circle'}${_vault ? '' : ' (and members)'} from all screens',
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              fontSize: globalState.userSetting.fontSize,
                              color: globalState.theme.labelText),
                        ),
                      )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, top: 15, bottom: 0, right: 10),
                child: Row(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 5),
                    child: Text(
                      AppLocalizations.of(context)!.toOpenPressThe,
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.labelText),
                    ),
                  ),
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: Colors.amber,
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      AppLocalizations.of(context)!.inManageCircles,
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.labelText),
                    ),
                  )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 11, top: 15, bottom: 15, right: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 5),
                        child: Text(
                          AppLocalizations.of(context)!.toClosePressThe,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              fontSize: globalState.userSetting.fontSize,
                              color: globalState.theme.labelText),
                        ),
                      ),
                      Icon(
                        Icons.lock_rounded,
                        color: globalState.theme.buttonIcon,
                      ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          AppLocalizations.of(context)!.fromAnyScreen,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              fontSize: globalState.userSetting.fontSize,
                              color: globalState.theme.labelText),
                        ),
                      )),
                    ]),
              ),
            ]));

    final showHideCircle = ConstrainedBox(
      constraints: const BoxConstraints(),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
          child: Row(children: <Widget>[
            Expanded(
              flex: 20,
              child: FormattedText(
                obscureText: !_showPassword,
                maxLength: 25,
                labelText: AppLocalizations.of(context)!.passphrase,
                controller: _password,
                onChanged: _revalidate,
                maxLines: 1,
                validator: (value) {
                  if (value.toString().trim().isEmpty) {
                    return AppLocalizations.of(context)!.passphraseIsRequired;
                  } else if (value.toString().endsWith(' ')) {
                    return AppLocalizations.of(context)!
                        .errorCannotEndWithASpace;
                  } else if (value.toString().startsWith(' ')) {
                    return AppLocalizations.of(context)!
                        .errorCannotStartWithASpace;
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
          padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
          child: Row(children: <Widget>[
            Expanded(
              flex: 20,
              child: FormattedText(
                maxLength: 25,
                obscureText: !_showPassword,
                labelText: AppLocalizations.of(context)!.reenterPassphrase,
                maxLines: 1,
                controller: _password2,
                onChanged: _revalidate,
                validator: (value) {
                  if (value.toString().trim() != _password.text.trim()) {
                    return AppLocalizations.of(context)!
                        .errorPassphraseDoNotMatch;
                  }

                  return null;
                },
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 49))
          ]),
        ),
      ]),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            key: _scaffoldKey,
            appBar: ICAppBar(
              title:
                  '${AppLocalizations.of(context)!.hide} ${_vault ? AppLocalizations.of(context)!.vault : widget.userCircleCache.dm ? AppLocalizations.of(context)!.dm : AppLocalizations.of(context)!.circle}',
            ),
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      controller: _scrollController,
                      child: WrapperWidget(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          showDisclaimer,
                          showHideCircle,
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 30, bottom: 0),
                            child: Row(children: <Widget>[
                              Expanded(
                                child: GradientButton(
                                  text: AppLocalizations.of(context)!
                                      .hideUpperCase, //'HIDE',
                                  onPressed: () {
                                    _hide();
                                  },
                                ),
                              )
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 25, bottom: 10, right: 10),
                            child: Row(children: <Widget>[
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .canReuseTheSamePassphraseToOpenMoreThanOneAtOnce,
                                  textScaler: const TextScaler.linear(1.0),
                                  style: TextStyle(
                                      fontSize:
                                          globalState.userSetting.fontSize,
                                      color: globalState.theme.labelText),
                                ),
                              )),
                            ]),
                          ),
                        ],
                      )),
                    )))));
  }

  _hide() async {
    if (_formKey.currentState!.validate()) {
      ///check premium features

      if (await PremiumFeatureCheck.canHideCircle(context, widget.userFurnaces))
        Navigator.pop(context, _password.text);
    } else {
      validatedOnceAlready = true;
    }
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
  }
}
