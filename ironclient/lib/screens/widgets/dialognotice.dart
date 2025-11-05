import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogNotice {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static showNoticeOptionalLines(
    BuildContext context,
    String title,
    String? line1, bool localize, {
    //required bool localize,
    String? line2,
    String? line3,
    String? line4,
  }) async {

    // if (localize) {
    //   line1 = line1 == null ? null : NotificationLocalization.getLocalizedString(line1, context);
    //   line2 = line2 == null ? null : NotificationLocalization.getLocalizedString(line2, context);
    //   line3 = line3 == null ? null : NotificationLocalization.getLocalizedString(line3, context);
    //   line4 = line4 == null ? null : NotificationLocalization.getLocalizedString(line4, context);
    // }

    await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ICText(
                  title,
                  textScaleFactor: globalState.dialogScaleFactor,
                  color: globalState.theme.dialogButtons,
                  fontSize: 18,
                )),
          ),
          contentPadding: const EdgeInsets.only(left: 15.0, top: 10, right: 15),
          content: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 10, right: 0, left: 10),
                          child: SelectableText(
                            line1!,
                            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                            style: TextStyle(
                                fontSize: 16,
                                color: globalState.theme.dialogLabel),
                          )),
                      line2 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line2,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: globalState.theme.dialogLabel),
                              )),
                      line3 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line3,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: globalState.theme.dialogLabel),
                              )),
                      line4 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line4,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: globalState.theme.dialogLabel),
                              )),
                    ],
                  ))),
          actions: <Widget>[
            TextButton(
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                  style: TextStyle(
                    color: globalState.theme.dialogButtons,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  ///deprecated
  static showNotice(BuildContext context, String title, String? line1,
      String? line2, String? line3, String? line4, bool localize) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              title,
              textScaler: TextScaler.linear(globalState.dialogScaleFactor),
              style: TextStyle(color: globalState.theme.dialogTitle),
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 15.0, top: 15, right: 15),
          content: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 10, right: 0, left: 10),
                          child: SelectableText(
                            line1!,
                            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                            style: TextStyle(
                                fontSize: 16 - globalState.scaleDownTextFont,
                                color: globalState.theme.dialogLabel),
                          )),
                      line2 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line2,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize:
                                        16 - globalState.scaleDownTextFont,
                                    color: globalState.theme.dialogLabel),
                              )),
                      line3 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line3,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize:
                                        16 - globalState.scaleDownTextFont,
                                    color: globalState.theme.dialogLabel),
                              )),
                      line4 == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 0, left: 10),
                              child: SelectableText(
                                line4,
                                textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                style: TextStyle(
                                    fontSize:
                                        16 - globalState.scaleDownTextFont,
                                    color: globalState.theme.dialogLabel),
                              )),
                    ],
                  ))),
          actions: <Widget>[
            TextButton(
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                  style: TextStyle(
                    color: globalState.theme.dialogButtons,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  static showCircleTypeHelp(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.circleTypeHelpTitle,
              style: TextStyle(color: globalState.theme.dialogTitle),
            )
          ),
          contentPadding: const EdgeInsets.only(left: 15, top: 15, right: 15),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.circleTypeHelpLine1,
                    textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                    style: TextStyle(color: globalState.theme.labelText)
                  ),
                  Text(
                      AppLocalizations.of(context)!.circleTypeHelpLine2,
                      textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                      style: TextStyle(color: globalState.theme.labelText)
                  ),
                ]
              )
            )
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.closeUpperCase,
                textScaler: TextScaler.linear(globalState.labelScaleFactor),
                style: TextStyle(
                  color: globalState.theme.buttonCancel,
                  fontSize: 14 - globalState.scaleDownButtonFont)),
              onPressed: () {
                Navigator.pop(context);
              }
            )
          ]
        )
      )
    );
  }

  static showNewNetworkHelp(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.newNetworkHelpTitle,
              style: TextStyle(color: globalState.theme.dialogTitle),
            )
          ),
          contentPadding: const EdgeInsets.only(left: 15, top: 15, right: 15),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.newNetworkHelpLine1,
                    textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                    style: TextStyle(color: globalState.theme.labelText)
                  ),
                  Text(
                      AppLocalizations.of(context)!.newNetworkHelpLine2,
                      textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                      style: TextStyle(color: globalState.theme.labelText)
                  ),
                  Text(
                    AppLocalizations.of(context)!.newNetworkHelpLine3,
                    textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                    style: TextStyle(color: globalState.theme.labelText),
                  )
                ]
              )
            )
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.closeUpperCase,
                textScaler: TextScaler.linear(globalState.labelScaleFactor),
                style: TextStyle(
                  color: globalState.theme.buttonCancel,
                  fontSize: 14 - globalState.scaleDownButtonFont)),
              onPressed: () {
                Navigator.pop(context);
              }
            )
          ]
        )
      )
    );
  }

  static showLandingAccountHelp(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _SystemPadding(
            child: AlertDialog(
                surfaceTintColor: Colors.transparent,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Center(
                    child: Text(
                      AppLocalizations.of(context)!.landingAccountHelpTitle,
                      style: TextStyle(color: globalState.theme.dialogTitle),
                    )
                ),
                contentPadding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                content: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  AppLocalizations.of(context)!.landingAccountHelpLine1,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              ),
                              Text(
                                  AppLocalizations.of(context)!.landingAccountHelpLine2,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              )
                            ]
                        )
                    )
                ),
                actions: <Widget>[
                  TextButton(
                      child: Text(
                          AppLocalizations.of(context)!.closeUpperCase,
                          textScaler: TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }
                  )
                ]
            )
        )
    );
  }

  static showLandingNetworkHelp(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _SystemPadding(
            child: AlertDialog(
                surfaceTintColor: Colors.transparent,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Center(
                    child: Text(
                      AppLocalizations.of(context)!.landingNetworkHelpTitle,
                      style: TextStyle(color: globalState.theme.dialogTitle),
                    )
                ),
                contentPadding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                content: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  AppLocalizations.of(context)!.landingNetworkHelpLine1,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              ),
                            ]
                        )
                    )
                ),
                actions: <Widget>[
                  TextButton(
                      child: Text(
                          AppLocalizations.of(context)!.closeUpperCase,
                          textScaler: TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }
                  )
                ]
            )
        )
    );
  }

  static showLandingFriendHelp(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _SystemPadding(
            child: AlertDialog(
                surfaceTintColor: Colors.transparent,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Center(
                    child: Text(
                      AppLocalizations.of(context)!.landingNetworkHelpTitle,
                      style: TextStyle(color: globalState.theme.dialogTitle),
                    )
                ),
                contentPadding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                content: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  AppLocalizations.of(context)!.landingNetworkHelpLine1,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              ),
                              Text(
                                  AppLocalizations.of(context)!.landingAccountHelpLine1,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              ),
                              Text(
                                  AppLocalizations.of(context)!.landingAccountHelpLine2,
                                  textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                                  style: TextStyle(color: globalState.theme.labelText)
                              )
                            ]
                        )
                    )
                ),
                actions: <Widget>[
                  TextButton(
                      child: Text(
                          AppLocalizations.of(context)!.closeUpperCase,
                          textScaler: TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      }
                  )
                ]
            )
        )
    );
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
