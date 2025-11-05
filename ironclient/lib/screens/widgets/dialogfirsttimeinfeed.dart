import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class DialogFirstTimeInFeed {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static show(
    BuildContext context,
  ) async {
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
                AppLocalizations.of(context)!.welcomeToTheFeed,
                textScaleFactor: 1,
                color: globalState.theme.dialogTitle,
                fontSize: 23,
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(12.0),
          content: FirstTimeInFeedWidget(scaffoldKey),
          actions: <Widget>[
            TextButton(
                child: Text(AppLocalizations.of(context)!.okHalfUpper,
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

class FirstTimeInFeedWidget extends StatefulWidget {
  final Key scaffoldKey;

  const FirstTimeInFeedWidget(
    this.scaffoldKey,
  );

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<FirstTimeInFeedWidget> {
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
        height: 175,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogTransparentBackground,
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
                      AppLocalizations.of(context)!.feedHelpLine1)),
                Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 15),
                    child: ICText(
                      AppLocalizations.of(context)!.feedHelpLine2)),
              ]),
        ));
  }
}
