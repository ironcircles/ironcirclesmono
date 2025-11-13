import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogHandleFile {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static handleFilePopup(
    BuildContext context,
    CircleObject circleObject,
    Function success,
  ) async {
    //bool _validPassword = false;
    //TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: ICText(AppLocalizations.of(context)!.shareOrDownloadQuestion,
              textScaleFactor: globalState.dialogScaleFactor,
              fontSize: 18,
              color: globalState.theme.textTitle),
          contentPadding: const EdgeInsets.all(10.0),
          content: ItemsToPost(scaffoldKey, circleObject, success),
          actions: const <Widget>[
            /*new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),*/
          ],
        ),
      ),
    );
  }
}

enum HandleFile { download, inside, outside }

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
  final CircleObject circleObject;
  final Function success;
  //final TextEditingController controller;

  const ItemsToPost(
    this.scaffoldKey,
    this.circleObject,
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

  @override
  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<ItemsToPost> {
  //bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, IconData iconData, HandleFile handleFile) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(context, widget.circleObject, handleFile);
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 20),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    iconData,
                    color: globalState.theme.bottomIcon,
                    size: 35,
                  ),
                  const Padding(
                      padding: EdgeInsets.only(
                    right: 10,
                  )),
                  Expanded(
                      child: ICText(text,
                          textScaleFactor: globalState.dialogScaleFactor,
                          color: globalState.theme.bottomIcon,
                          fontSize: 16)),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalState.theme.dialogBackground,
      key: widget.scaffoldKey,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 5, bottom: 5),
                child: ICText(
                    Platform.isAndroid
                        ? AppLocalizations.of(context)!.wouldYouLikeToShareOrDownloadItInsteadQuestion
                        : AppLocalizations.of(context)!.wouldYouLikeToShareItInsteadQuestion,
                    textScaleFactor: globalState.dialogScaleFactor,
                    fontSize: 16,
                    color: globalState.theme.button),
              ),
              if (Platform.isAndroid)
                _row(AppLocalizations.of(context)!.downloadToMyDevice, Icons.download,
                    HandleFile.download),
              _row(AppLocalizations.of(context)!.shareToACircleDM, Icons.share,
                  HandleFile.inside),
              _row(
                  Platform.isAndroid
                      ? AppLocalizations.of(context)!.shareOutsideIronCircles
                      : AppLocalizations.of(context)!.shareOrDownloadOutsideIronCircles,
                  Icons.share_outlined,
                  HandleFile.outside),
            ]),
      ),
    );
  }
}
