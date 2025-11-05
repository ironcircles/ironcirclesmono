import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogShareMagicLink {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static shareToPopup(
    BuildContext context,
    //String magicLink,
    Function success,
  ) async {
    await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ICText(
                AppLocalizations.of(context)!.whereToShare,
                textScaleFactor: globalState.dialogScaleFactor,
                fontSize: 18,
                color: globalState.theme.textTitle,
              )),
          contentPadding: const EdgeInsets.all(10.0),
          content: ItemsToPost(scaffoldKey, success),
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
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class ItemsToPost extends StatefulWidget {
  final Key scaffoldKey;
  //String magicLink;
  final Function success;

  const ItemsToPost(
    this.scaffoldKey,
    //this.magicLink,
    this.success,
  );

  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<ItemsToPost> {
  bool _dm = true;

  @override
  void initState() {
    super.initState();
  }

  Widget _row(String text, IconData iconData, bool inside) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.success(context, inside, _dm);
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 15),
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
    final dm = Padding(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 0),
      child: Row(children: <Widget>[
        const Spacer(),
        Theme(
          data: ThemeData(
              unselectedWidgetColor: globalState.theme.checkUnchecked),
          child: Checkbox(
            activeColor: globalState.theme.buttonIcon,
            checkColor: globalState.theme.checkBoxCheck,
            value: _dm,
            onChanged: (newValue) {
              setState(() {
                _dm = newValue!;
                //_scrollBottom();
              });
            },
          ),
        ),
        ICText(
          AppLocalizations.of(context)!.autoAddToDM,
          fontSize: 14,
        ),
      ]),
    );

    return SizedBox(
        //width: 200,
        height: 150,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _row(AppLocalizations.of(context)!.shareToCircleDM, Icons.share,
                    true),
                _row(AppLocalizations.of(context)!.shareOutside,
                    Icons.share_outlined, false),
                dm,
              ]),
        ));
  }
}
