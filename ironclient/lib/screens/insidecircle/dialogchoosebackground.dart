


import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogChooseBackground {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static chooseBackgroundPopup(
      BuildContext context,
      Function success,
      ) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _SystemPadding(
            child: AlertDialog(
              surfaceTintColor: Colors.transparent,
              backgroundColor: globalState.theme.dialogTransparentBackground,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ICText(
                    AppLocalizations.of(context)!.whatTypeOfBackground,
                    textScaleFactor: globalState.dialogScaleFactor,
                    fontSize: 18,
                    color: globalState.theme.textTitle,
                  )),
              contentPadding: const EdgeInsets.all(10.0),
              content: ItemsToPost(scaffoldKey, success),
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
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class ItemsToPost extends StatefulWidget {
  final Key scaffoldKey;
  final Function success;

  const ItemsToPost(
      this.scaffoldKey,
      this.success,
      );

  @override
  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<ItemsToPost> {
  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, IconData iconData, bool imageSelected) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(context, imageSelected);
        },
        child: Padding(
            padding: const EdgeInsets.only(
                right: 0, top: 10, bottom: 5, left: 15),
            child:
            Row(
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
                  Expanded(
                    child: ICText(text,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        textScaleFactor: globalState.dialogScaleFactor,
                        color: globalState.theme.bottomIcon,
                        fontSize: 16),
                  )
                ])
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 125,
        child: Scaffold(
            backgroundColor: Colors.transparent,
            key: widget.scaffoldKey,
            resizeToAvoidBottomInset: true,
            body: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _row(AppLocalizations.of(context)!.chooseAnImage, Icons.image, true),
                  _row(AppLocalizations.of(context)!.chooseAColor, Icons.colorize, false),
                ])
        ));
  }
}