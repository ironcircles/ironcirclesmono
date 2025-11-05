import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/circle_hide.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

enum DialogFirstTimeInCircleResponse {
  didNothing,
  members,
  magicLink,
  guard,
  hide,
}

class DialogFirstTimeInCircle {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static showShortcuts(
      BuildContext context,
      UserCircleCache userCircleCache,
      List<UserFurnace> userFurnaces,
      UserFurnace userFurnace,
      UserCircleBloc userCircleBloc,
      FirebaseBloc firebaseBloc,
      Function finish) async {
    await showDialog<String>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10),
              ),
              ICText(
                AppLocalizations.of(context)!.welcomeToCircle,
                textScaleFactor: 1,
                color: globalState.theme.dialogTitle,
                fontSize: 23,
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(12.0),
          content: PrivateVaultOptions(scaffoldKey, userCircleCache,
              userFurnaces, userFurnace, userCircleBloc, firebaseBloc, finish),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.maybeLaterUpperCase,
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.buttonCancel,
                        fontSize: 16 - globalState.scaleDownButtonFont)),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300), child: child);
  }
}

class PrivateVaultOptions extends StatefulWidget {
  final Key scaffoldKey;
  final UserCircleCache userCircleCache;
  //final UserCircle userCircle;
  final List<UserFurnace> userFurnaces;
  final UserFurnace userFurnace;
  final UserCircleBloc userCircleBloc;
  final FirebaseBloc firebaseBloc;
  final Function finish;

  const PrivateVaultOptions(
    this.scaffoldKey,
    this.userCircleCache,
    //this.userCircle,
    this.userFurnaces,
    this.userFurnace,
    this.userCircleBloc,
    this.firebaseBloc,
    this.finish,
  );

  @override
  HomeShortcutsState createState() => HomeShortcutsState();
}

class HomeShortcutsState extends State<PrivateVaultOptions> {
  bool _guarded = false;
  bool _hidden = false;
  List<int> _pin = [];

  @override
  void initState() {
    if (widget.userCircleCache.guarded != null)
      _guarded = widget.userCircleCache.guarded!;
    if (widget.userCircleCache.hidden != null)
      _hidden = widget.userCircleCache.hidden!;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = globalState.setScale(MediaQuery.of(context).size.width);

    return SizedBox(
        width: (width >= 350 ? 350 : width),
        /*height: globalState.userSetting.allowHidden == false ||
                globalState.user.allowClosed == false
            ? 266
            : globalState.mediaScaleFactor > 1.5
                ? 345
                : 290, //widget.firstTime ? 340  : 340,

         */
        height: 266,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                 Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: ICText(
                      AppLocalizations.of(context)!.welcomeToCircleDescription)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                ),
                GradientButton(
                    text: AppLocalizations.of(context)!.welcomeToCircleInvitePeople,
                    color1: Colors.green[800],
                    color2: Colors.green[500],
                    onPressed: () {
                      Navigator.pop(context);
                      widget.finish(DialogFirstTimeInCircleResponse.members);
                    }),
                GradientButton(
                    text: AppLocalizations.of(context)!.welcomeToCircleInviteToNetwork,
                    color1: Colors.teal[500],
                    color2: Colors.teal[300],
                    onPressed: () {
                      Navigator.pop(context);
                      widget.finish(DialogFirstTimeInCircleResponse.magicLink);
                    }),
                const Padding(padding: EdgeInsets.only(top: 5)),
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                        //flex: 12,
                        child: SwitchListTile(
                          inactiveThumbColor: globalState.theme.inactiveThumbColor,
                          inactiveTrackColor: globalState.theme.inactiveTrackColor,
                      trackOutlineColor: MaterialStateProperty.resolveWith(globalState.getSwitchColor),
                      title: Text(
                        AppLocalizations.of(context)!.welcomeGuardWithPattern,
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            fontSize: 14, color: globalState.theme.labelText),
                      ),
                      value: _guarded,
                      activeColor: globalState.theme.button,
                      onChanged: (bool value) {
                        setState(() {
                          // _guarded = value;
                          if (value)
                            _setCircleGuarded();
                          else {
                            _guarded = value;
                            widget.userCircleCache.guarded = value;
                            //widget.userCircleBloc.update(widget.userFurnace,
                            //  widget.userCircle, widget.userCircleCache);
                            widget.userCircleBloc.unguard(
                                widget.userFurnace, widget.userCircleCache);
                          }
                        });
                      },
                      //secondary: const Icon(Icons.remove_red_eye),
                    )),
                    //new Spacer(flex: 11),
                  ]),
                ),
                /*globalState.userSetting.allowHidden == false ||
                        globalState.user.allowClosed == false
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                              //flex: 12,
                              child: SwitchListTile(
                            inactiveThumbColor:
                                globalState.theme.sliderInactive,
                            inactiveTrackColor:
                                globalState.theme.menuBackground,
                            title: Text(
                              AppLocalizations.of(context).welcomeHideFromHome,
                              textScaleFactor: 1,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: globalState.theme.labelText),
                            ),
                            value: _hidden,
                            activeColor: globalState.theme.button,
                            onChanged: (bool value) {
                              setState(() {
                                // _guarded = value;
                                if (value)
                                  _hide();
                                else {
                                  _unhide();
                                }
                              });
                            },
                            //secondary: const Icon(Icons.remove_red_eye),
                          )),
                          //new Spacer(flex: 11),
                        ]),
                      ),*/
              ]),
        ));
  }

  _setCircleGuarded() async {
    await DialogPatternCapture.capture(
      context,
      _pin1Captured,
      AppLocalizations.of(context)!.swipePattern,
    );
  }

  _pin1Captured(List<int> pin) async {
    debugPrint(pin.toString());
    _pin = pin;
    await DialogPatternCapture.capture(
      context,
      _pin2Captured,
      AppLocalizations.of(context)!.pleaseReswipePattern,
    );
  }

  _pin2Captured(List<int> pin) {
    setState(() {
      if (listEquals(pin, _pin)) {
        _guarded = true;

        ///save pin
        widget.userCircleBloc
            .setPin(widget.userFurnace, widget.userCircleCache, pin);

        Navigator.pop(context);
      } else {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.patternsDoNotMatch, "", 2, false);
        _guarded = false;
      }
    });
  }

  _hide() async {
    String? passcode = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CircleHide(
            userCircleCache: widget.userCircleCache,
            userFurnaces: widget.userFurnaces,
          ),
        ));

    if (passcode != null) {
      if (passcode.isNotEmpty) _hideCallback(widget.userCircleCache, passcode);
    }
  }

  _hideCallback(UserCircleCache userCircleCache, String passcode) async {
    userCircleCache.hiddenOpen = true;
    userCircleCache.hidden = true;

    await widget.userCircleBloc
        .hide(widget.firebaseBloc, userCircleCache, true, passcode);

    globalState.globalEventBloc.broadcastPopToHomeOpenTab(0);
  }

  _unhide() {
    DialogYesNo.askYesNo(
        context,
        widget.userCircleCache.dm
            ? AppLocalizations.of(context)!.unhideDMTitle
            : AppLocalizations.of(context)!.unhideCircleTitle,
        widget.userCircleCache.dm
            ? AppLocalizations.of(context)!.unhideDMMessage
            : AppLocalizations.of(context)!.unhideCircleMessage,
        _unhideConfirm,
        null,
        false,
        widget.userCircleCache);
  }

  _unhideConfirm(UserCircleCache userCircleCache) {
    userCircleCache.hiddenOpen = false;
    userCircleCache.hidden = false;

    widget.userCircleBloc.hide(widget.firebaseBloc, userCircleCache, false, '');

    setState(() {
      _hidden = false;
    });

    //widget.update(userCircleCache);
  }

  // _goHome() async {
  //   await Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (context) => Home()),
  //       (Route<dynamic> route) => false);
  // }
}
