import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class NetworkDetailHealth extends StatefulWidget {
  @override
  FurnaceHealthState createState() => FurnaceHealthState();
}

class FurnaceHealthState extends State<NetworkDetailHealth> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    //_username.text = _user.username;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    line(String text) {
      return Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 0, right:5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: ICText(
                text,
                fontSize: 16,
              )),
              Text(AppLocalizations.of(context)!.active.toUpperCase(),
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(
                      color: globalState.theme.buttonIcon,
                      fontSize: 16)),
            ],
          ));
    }

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(child:Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      line(AppLocalizations.of(context)!.end2EndEncryption),
                      line(AppLocalizations.of(context)!.encryptionTransit),
                      line(AppLocalizations.of(context)!.encryptionRest),
                      line(AppLocalizations.of(context)!.floodProtection),
                      line(AppLocalizations.of(context)!.blockMalformedRequests),
                      line(AppLocalizations.of(context)!.enforcedConnections),
                      line(AppLocalizations.of(context)!.vulnerabilityProtection),
                      line(AppLocalizations.of(context)!.blockInjectionAttacks),
                      line(AppLocalizations.of(context)!.blockFrameworksAttacks),
                      line(AppLocalizations.of(context)!.blockSimulators),
                      line(AppLocalizations.of(context)!.codeObfuscation),
                    ])))));

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          /*appBar: ICAppBar(
            title: 'Network Health',
          ),

           */
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: makeBody,
              ),
              /* Container(
                //  color: Colors.white,
                padding: EdgeInsets.all(0.0),
                child: makeBottom,
              ),*/
            ],
          ),
        ));
  }
}
