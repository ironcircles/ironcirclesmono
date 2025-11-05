import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/leftnavigation/helpcenter.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/screens/widgets/appstorelink.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

enum DialogHomeShortcutsResponse {
  doNothing,
  goInsideVault,
  showWalkthru,
  changeGenerated,
  createCircle,
  inviteFriends,
  findNetworks,
}

enum DialogMustUpgradeResponse { update }

class DialogHomeShortcuts {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static showMustUpdate(
      BuildContext context, bool changeGenerated, Function finish) async {
    final String _version = globalState.version;
    await showDialog<String>(
        barrierColor: Colors.black.withOpacity(.8),
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => _SystemPadding(
              child: AlertDialog(
                  backgroundColor: globalState.theme.dialogBackground,
                  //surfaceTintColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  title: Center(
                      child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ICText(
                            "Update Required ($_version)",
                            textScaleFactor: 1,
                            color: globalState.theme.dialogTitle,
                            fontSize: 18,
                          ))),
                  contentPadding: const EdgeInsets.all(12.0),
                  content: Text(
                      "To continue using IronCircles, please update to the latest version.\n\nYour version is $_version. The minimum version is ${globalState.minimumBuild}.\n\nThank you!",
                      textScaler:
                          TextScaler.linear(globalState.dialogScaleFactor),
                      style: TextStyle(color: globalState.theme.bottomIcon)),
                  actions: <Widget>[
                    AppStoreLink(),
                  ],
                  actionsAlignment: MainAxisAlignment.center),
            ));
  }

  static showShortcuts(BuildContext context, bool changeGenerated,
      Function finish, bool firstTime) async {
    await showDialog<String>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: firstTime
              ? Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                    ),
                    ICText(
                      AppLocalizations.of(context)!.welcomeToHome,
                      textScaleFactor: 1,
                      color: globalState.theme.dialogTitle,
                      fontSize: 23,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                    ),
                    ICText(
                      AppLocalizations.of(context)!.welcomeToHomePrompt,
                      textScaleFactor: 1,
                      color: globalState.theme.labelText,
                      fontSize: 18,
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ICText(
                        AppLocalizations.of(context)!.welcomeToHomePrompt,
                        textScaleFactor: 1,
                        color: globalState.theme.dialogTitle,
                        fontSize: 18,
                      )),
                ),
          contentPadding: const EdgeInsets.all(12.0),
          content:
              HomeShortcuts(scaffoldKey, changeGenerated, finish, firstTime),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.closeUpperCase,
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.buttonCancel,
                        fontSize: 14 - globalState.scaleDownButtonFont)),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  static showNetworkHelp(BuildContext context) async {
    await showDialog<String>(
        barrierColor: Colors.black.withOpacity(.8),
        context: context,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
                    surfaceTintColor: Colors.transparent,
                    backgroundColor:
                        globalState.theme.dialogTransparentBackground,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    title: ICText(
                      AppLocalizations.of(context)!.networkHelpTitle,
                      textScaleFactor: 1,
                      color: globalState.theme.dialogTitle,
                      fontSize: 23,
                      textAlign: TextAlign.center,
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                    content: Text(
                        AppLocalizations.of(context)!.networkHelpLine1,
                        textScaler:
                            TextScaler.linear(globalState.dialogScaleFactor),
                        style: TextStyle(color: globalState.theme.labelText)),
                    actions: <Widget>[
                  TextButton(
                      child: Text(AppLocalizations.of(context)!.closeUpperCase,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ])));
  }

  static showWallHelp(BuildContext context) async {
    await showDialog<String>(
        barrierColor: Colors.black.withOpacity(.8),
        context: context,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
                    surfaceTintColor: Colors.transparent,
                    backgroundColor:
                        globalState.theme.dialogTransparentBackground,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    title: ICText(
                      AppLocalizations.of(context)!.feedHelpTitle,
                      textScaleFactor: 1,
                      color: globalState.theme.dialogTitle,
                      fontSize: 23,
                      textAlign: TextAlign.center,
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Text(
                                  AppLocalizations.of(context)!.feedHelpLine1,
                                  textScaler: TextScaler.linear(
                                      globalState.dialogScaleFactor),
                                  style: TextStyle(
                                      color: globalState.theme.labelText))),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, top: 15),
                              child: Text(
                                  AppLocalizations.of(context)!.feedHelpLine2,
                                  textScaler: TextScaler.linear(
                                      globalState.dialogScaleFactor),
                                  style: TextStyle(
                                      color: globalState.theme.labelText))),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, top: 15),
                              child: Text(
                                  AppLocalizations.of(context)!.feedHelpLine3,
                                  textScaler: TextScaler.linear(
                                      globalState.dialogScaleFactor),
                                  style: TextStyle(
                                      color: globalState.theme.labelText))),
                        ]),
                    actions: <Widget>[
                  TextButton(
                      child: Text(AppLocalizations.of(context)!.closeUpperCase,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ])));
  }

  static showRequestPending(BuildContext context) async {
    await showDialog<String>(
        barrierColor: Colors.black.withOpacity(.8),
        context: context,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
                    surfaceTintColor: Colors.transparent,
                    backgroundColor:
                        globalState.theme.dialogTransparentBackground,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    title: ICText(
                      AppLocalizations.of(context)!.requestSubmittedTitle,
                      textScaleFactor: 1,
                      color: globalState.theme.dialogTitle,
                      fontSize: 23,
                      textAlign: TextAlign.center,
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .requestSubmittedLine1,
                                  textScaler: TextScaler.linear(
                                      globalState.dialogScaleFactor),
                                  style: TextStyle(
                                      color: globalState.theme.labelText))),
                        ]),
                    actions: <Widget>[
                  TextButton(
                      child: Text(AppLocalizations.of(context)!.closeUpperCase,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ])));
  }

  static showFriendsHelp(BuildContext context) async {
    await showDialog<String>(
        barrierColor: Colors.black.withOpacity(.8),
        context: context,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: globalState.theme.dialogBackground,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    title: ICText(
                      AppLocalizations.of(context)!.friendsHelpTitle,
                      textScaleFactor: 1,
                      color: globalState.theme.dialogTitle,
                      fontSize: 23,
                      textAlign: TextAlign.center,
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                    content: Text(
                        AppLocalizations.of(context)!.friendsHelpLine1,
                        textScaler:
                            TextScaler.linear(globalState.dialogScaleFactor),
                        style: TextStyle(color: globalState.theme.labelText)),
                    actions: <Widget>[
                  TextButton(
                      child: Text(AppLocalizations.of(context)!.closeUpperCase,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ])));
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class HomeShortcuts extends StatefulWidget {
  final Key scaffoldKey;
  final bool changeGenerated;
  final Function finish;
  final bool firstTime;

  const HomeShortcuts(
    this.scaffoldKey,
    this.changeGenerated,
    this.finish,
    this.firstTime,
  );

  @override
  HomeShortcutsState createState() => HomeShortcutsState();
}

class HomeShortcutsState extends State<HomeShortcuts> {
  @override
  void initState() {
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
        height: 340, //widget.firstTime ? 340  : 340,
        child: Scaffold(
            backgroundColor: Colors.transparent,
            key: widget.scaffoldKey,
            resizeToAvoidBottomInset: true,
            body: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        scrollDirection: Axis.vertical,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              const Padding(padding: EdgeInsets.only(top: 5)),
                              GradientButton(
                                text: widget.changeGenerated
                                    ? AppLocalizations.of(context)!
                                        .welcomeSetPassword
                                    : AppLocalizations.of(context)!
                                        .welcomeViewProfile,
                                color1: Colors.green[800],
                                color2: Colors.green[500],
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );

                                  widget.changeGenerated
                                      ? widget.finish(
                                          DialogHomeShortcutsResponse
                                              .changeGenerated)
                                      : Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Settings(),
                                          ));
                                },
                              ),
                              const Padding(padding: EdgeInsets.only(top: 5)),
                              GradientButton(
                                  text: AppLocalizations.of(context)!
                                      .welcomeInviteFriends,
                                  color1: Colors.teal[500],
                                  color2: Colors.teal[300],
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                    );

                                    widget.finish(DialogHomeShortcutsResponse
                                        .inviteFriends);
                                  }),
                              const Padding(padding: EdgeInsets.only(top: 5)),
                              GradientButton(
                                text: AppLocalizations.of(context)!
                                    .welcomeCreateCircle,
                                color1: Colors.cyan[500],
                                color2: Colors.cyan[300],
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                  widget.finish(
                                      DialogHomeShortcutsResponse.createCircle);
                                },
                              ),
                              const Padding(padding: EdgeInsets.only(top: 5)),
                              GradientButton(
                                text: AppLocalizations.of(context)!
                                    .welcomeGoToHelp,
                                color1: Colors.blue[500],
                                color2: Colors.blue[300],
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HelpCenter(),
                                      ));

                                  /*Navigator.pushReplacementNamed(
                      context,
                      '/home',
                      // arguments: user,
                    );

                     */
                                },
                              ),
                              const Padding(padding: EdgeInsets.only(top: 5)),
                              GradientButton(
                                  text: AppLocalizations.of(context)!
                                      .welcomeFindNetworks,
                                  color1: Colors.blue[800],
                                  color2: Colors.blue[500],
                                  onPressed: () {
                                    widget.finish(DialogHomeShortcutsResponse
                                        .findNetworks);
                                    Navigator.pop(context);
                                  }),
                            ]),
                      )))
            ])));
  }
}
