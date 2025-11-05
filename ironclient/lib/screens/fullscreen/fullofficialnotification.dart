import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/officialnotification.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class FullOfficialNotification extends StatefulWidget {
  final OfficialNotification notification;

  const FullOfficialNotification({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  FullOfficialNotificationState createState() =>
      FullOfficialNotificationState();
}

class FullOfficialNotificationState extends State<FullOfficialNotification> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final makeBody = Container(
        color: globalState.theme.background,
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ICText(
              widget.notification.message,
              //textScaler: TextScaler.linear(globalState.cardScaleFactor),
            )
          ],
        ));

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(title: widget.notification.title),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: makeBody,
                    ),
                    Row(
                      children: [const Spacer(), GradientButtonDynamic(text: AppLocalizations.of(context)!.dismiss, onPressed: (){
                        Navigator.pop(context, true);

                      },), const Padding(padding: EdgeInsets.only(right:10),),],
                    )
                  ])
            ])));
  }
}
