import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogSelectPostItems {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static selectPostItemsPopup(
    BuildContext context,
    String? username,
    Function success,
  ) async {
    await showDialog<String>(
      barrierColor: Colors.black.withOpacity(.8),
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
              title:  ICText(AppLocalizations.of(context)!.selectAnItemToPost,
                  textScaleFactor: globalState.dialogScaleFactor,
                  fontSize: 20,
                  color: globalState.theme.buttonIcon),
              contentPadding: const EdgeInsets.all(12.0),
              content: ItemsToPost(scaffoldKey, success),
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
  final Key scaffoldKey;
  final Function success;
  //final TextEditingController controller;

  const ItemsToPost(
    this.scaffoldKey,
    this.success,
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

class ItemsToPostState extends State<ItemsToPost> {
  //bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, IconData iconData, String selection) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(selection);
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 25),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    iconData,
                    color: globalState.theme.bottomIcon,
                    size: 35 - globalState.scaleDownIcons,
                  ),
                  const Padding(
                      padding: EdgeInsets.only(
                    right: 10,
                  )),
                  ICText(text,
                      textScaleFactor: globalState.dialogScaleFactor,
                      color: globalState.theme.bottomIcon,
                      fontSize: 16),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    double width = globalState.setScale(MediaQuery.of(context).size.width);

    return SizedBox(
        width: (width >= 350 ? 350 : width),
        height: 250,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /*_row(
                       'Expanded text editor', Icons.edit_note,
                       CircleObjectType.CIRCLETEXT,
                        ),*/
                        _row(
                          AppLocalizations.of(context)!.markup,
                          Icons.brush,
                          AppLocalizations.of(context)!.markup,
                        ),
                        _row(AppLocalizations.of(context)!.listOfTasks, Icons.check_box,
                            CircleObjectType.CIRCLELIST),
                        _row(AppLocalizations.of(context)!.shareARecipe, Icons.restaurant,
                            CircleObjectType.CIRCLERECIPE),
                        _row(AppLocalizations.of(context)!.voteForTheCircle, Icons.poll,
                            CircleObjectType.CIRCLEVOTE),
                        _row(AppLocalizations.of(context)!.credential, Icons.login, AppLocalizations.of(context)!.credential),
                      ]))),
        ));
  }
}
