import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';

class DialogDisappearing {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static setTimer(
    BuildContext context,
    Function success,
    Function scheduled,
  ) async {
    //bool _validPassword = false;
    //TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => Theme(
          data: ThemeData(
              dialogBackgroundColor: globalState.theme.dialogTransparentBackground),
          child: _SystemPadding(
            child: AlertDialog(
              backgroundColor: globalState.theme.dialogTransparentBackground,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              contentPadding: const EdgeInsets.all(5.0),
              content: ItemsToPost(scaffoldKey, success, scheduled),
              surfaceTintColor: Colors.transparent,
              /*actions: <Widget>[
                /*new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),*/
              ],

               */
            ),
          )),
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

class ItemsToPost extends StatefulWidget {
  final GlobalKey scaffoldKey;
  final Function success;
  final Function scheduled;
  //final TextEditingController controller;

  const ItemsToPost(
    this.scaffoldKey,
    this.success,
    this.scheduled,
    //this.controller,
    /* this.circleObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.userFurnace,
      this.copy,
      this.share,*/
  );

  @override
  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<ItemsToPost> {
  //bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _buttonRow(String text, int? selection, color1, color2) {
    return Padding(
        padding: const EdgeInsets.only(right: 0),
        child: Row(children: [
          Expanded(
              child: GradientButton(
                  text: text,
                  color1: color1,
                  color2: color2,
                  onPressed: () {
                    Navigator.pop(context);
                    if (selection == UserDisappearingTimer.ONE_TIME_VIEW) {
                      widget.success(selection);
                    } else {
                      widget.scheduled();
                    }
                  }))
        ]));
  }

  Widget _row(String text, int? selection) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(selection);
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 0),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                      padding: EdgeInsets.only(
                    right: 10,
                  )),
                  Text(
                    text,
                    textScaler:
                        TextScaler.linear(globalState.dialogScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.bottomIcon, fontSize: 16),
                  ),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: 450,
        child: Scaffold(
            backgroundColor: globalState.theme.dialogTransparentBackground,
            key: widget.scaffoldKey,
            resizeToAvoidBottomInset: true,
            body: Scrollbar(
                //thumbVisibility: true,
                child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    _buttonRow(
                      AppLocalizations.of(context)!.scheduleMessageSend,
                      UserDisappearingTimer.SCHEDULED,
                      Colors.blue[500],
                      Colors.blue[300],
                    ),
                    _buttonRow(
                      AppLocalizations.of(context)!.sendOneTimeViewMessage,
                      UserDisappearingTimer.ONE_TIME_VIEW,
                      Colors.cyan[500],
                      Colors.cyan[300],
                    ),
                    Padding(
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 5, left: 5, right: 5),
                        child: Divider(
                          color: globalState.theme.labelTextSubtle,
                          height: 1,
                        )),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          AppLocalizations.of(context)!
                              .disappearingMessageTimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: globalState.theme.textTitle),
                        )),
                    _row(AppLocalizations.of(context)!
                        .off, UserDisappearingTimer.OFF),
                    _row(AppLocalizations.of(context)!
                        .seconds10, UserDisappearingTimer.TEN_SECONDS),
                    _row(AppLocalizations.of(context)!
                        .seconds30, UserDisappearingTimer.THIRTY_SECONDS),
                    _row(AppLocalizations.of(context)!
                        .minutes1, UserDisappearingTimer.ONE_MINUTE),
                    _row(AppLocalizations.of(context)!
                        .minutes5, UserDisappearingTimer.FIVE_MINUTES),
                    _row(AppLocalizations.of(context)!
                        .hours1, UserDisappearingTimer.ONE_HOUR),
                    _row(AppLocalizations.of(context)!
                        .hours8, UserDisappearingTimer.EIGHT_HOURS),
                    _row(AppLocalizations.of(context)!
                        .day1, UserDisappearingTimer.ONE_DAY),
                  ]),
            ))));
  }
}
