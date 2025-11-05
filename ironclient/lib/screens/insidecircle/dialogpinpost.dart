import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DialogPinPost {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static pinPost(
    BuildContext context,
    CircleObject circleObject,
    Function success,
    bool pinForAll,
  ) async {
    //bool _validPassword = false;
    //TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => Theme(
          data: ThemeData(
              dialogBackgroundColor: globalState.theme.dialogBackground),
          child: _SystemPadding(
            child: AlertDialog(
              surfaceTintColor: Colors.transparent,
              backgroundColor: globalState.theme.dialogTransparentBackground,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(
                AppLocalizations.of(context)!.pinPost, textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                style: TextStyle(
                    fontSize: 20, color: globalState.theme.buttonIcon),
              ),
              contentPadding: const EdgeInsets.all(10.0),
              content: PinPost(scaffoldKey, circleObject, success, pinForAll),
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

class PinPost extends StatefulWidget {
  final GlobalKey scaffoldKey;
  final Function success;
  final CircleObject circleObject;
  final bool pinForAll;

  //final TextEditingController controller;

  const PinPost(
    this.scaffoldKey,
    this.circleObject,
    this.success,
    this.pinForAll,

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

  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<PinPost> {

  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, int selection) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(widget.circleObject, selection);
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 0, top: 10, bottom: 15, left: 0),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                      padding: EdgeInsets.only(
                    right: 10,
                  )),
                  Text(
                    text, textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.bottomIcon,
                        fontSize: globalState.userSetting.fontSize),
                  ),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: globalState.userSetting.fontSize == FontSize.LARGE
            ? 175
            : globalState.userSetting.fontSize == FontSize.LARGEST || globalState.mediaScaleFactor > 1.0
                ? 250
                : 150,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogTransparentBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(
                        top: 20, right: 15, left: 15, bottom: 10),
                    child: Text(
                      AppLocalizations.of(context)!.wouldYouLikeToPinForQuestion, textScaler: TextScaler.linear(globalState.dialogScaleFactor),
                      style: TextStyle(
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.textTitle),
                    )),
                _row(AppLocalizations.of(context)!.myself, 0),
                widget.pinForAll == false
                  ? Container()
                  : _row(AppLocalizations.of(context)!.entireCircle, 1),
              ]),
        ));
  }
}
