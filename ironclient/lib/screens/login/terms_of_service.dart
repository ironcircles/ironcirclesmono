import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class TermsOfService extends StatefulWidget {
  final String buttonText;
  final bool readOnly;

  static List<String> violations = [
    "",
    "illegal or obscene",
    "threatening, intimidating, or harassing",
    "ethnically or racially offensive",
    "encourages illegal or inappropriate behavior",
    "violates intellectual property rights"
  ];

  const TermsOfService({
    this.buttonText = 'REGISTER',
    this.readOnly = false,
    Key? key,
  }) : super(key: key);

  @override
  TermsOfServiceState createState() {
    return TermsOfServiceState();
  }
}

class TermsOfServiceState extends State<TermsOfService> {
  final _authBloc = AuthenticationBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _acceptTerms = false;
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _authBloc.dispose();
    super.dispose();
  }

  Row header(String header) {
    return Row(children: [
      Expanded(
          child: Text(
        '\n$header',
        textScaler: TextScaler.linear(globalState.labelScaleFactor),
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: globalState.theme.labelText,
            fontSize: 16),
      ))
    ]);
  }

  Row paragraph(String body) {
    return Row(children: [
      Expanded(
          child: Text(
        '\n$body',
        textScaler: TextScaler.linear(globalState.labelScaleFactor),
        style: TextStyle(color: globalState.theme.labelText, fontSize: 14),
      ))
    ]);
  }

  Row line(String body) {
    return Row(children: [
      const SizedBox(
        width: 25,
      ),
      Expanded(
          child: Text(
        '\n$body',
        textScaler: TextScaler.linear(globalState.labelScaleFactor),
        style: TextStyle(color: globalState.theme.labelText, fontSize: 14),
      ))
    ]);
  }

  Row icon(IconData icon) {
    return Row(children: [
      const SizedBox(
        width: 0,
      ),
      Expanded(
          child: Icon(
        icon,
        color: globalState.theme.buttonIcon,
      ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final acceptTerms = Container(
      //height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 10, top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            child: Theme(
                data: ThemeData(
                    unselectedWidgetColor: globalState.theme.checkUnchecked),
                child: CheckboxListTile(
                  activeColor: globalState.theme.buttonIcon,
                  checkColor: globalState.theme.checkBoxCheck,
                  title: Text(
                    'I accept these terms',
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        fontSize: 13, color: globalState.theme.labelText),
                  ),
                  value: _acceptTerms,
                  onChanged: (newValue) {
                    setState(() {
                      _acceptTerms = newValue!;
                      _register();
                    });
                  },
                  controlAffinity:
                      ListTileControlAffinity.leading, //  <-- leading Checkbox
                )),
          )
        ]),
      ),
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: WrapperWidget(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph1),
              // "IronCircles was created to be a secure and safe place for friends to connect. Specific features were designed to ensure your connections in the application are with people you already know and trust."), // IronCircles is intentionally not a platform that makes it easy to meet folks or create large groups of people who do not know each other outside a Circle."),
              header(AppLocalizations.of(context)!.termOfServiceHeader),
              line(AppLocalizations.of(context)!.termOfServiceLine1),
              line(AppLocalizations.of(context)!.termOfServiceLine2),
              line(AppLocalizations.of(context)!.termOfServiceLine3),
              header(AppLocalizations.of(context)!.termOfServiceHeader2),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph2),
              header(AppLocalizations.of(context)!.termOfServiceHeader3),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph3),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph4),
              header(AppLocalizations.of(context)!.termOfServiceHeader4),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph5),
              line(AppLocalizations.of(context)!.termOfServiceLine4),
              line(AppLocalizations.of(context)!.termOfServiceLine5),
              line(AppLocalizations.of(context)!.termOfServiceLine6),
              line(AppLocalizations.of(context)!.termOfServiceLine7),
              line(AppLocalizations.of(context)!.termOfServiceLine8),
              header(AppLocalizations.of(context)!.termOfServiceHeader5),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph6),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph7),
              header(AppLocalizations.of(context)!.termOfServiceHeader6),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph8),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph9),
              paragraph(AppLocalizations.of(context)!.termOfServiceLine9),
              icon(Icons.report),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph10),

              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph11),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph12),
              paragraph(AppLocalizations.of(context)!.termOfServiceParagraph13),

              //makeBottom(),
              widget.readOnly ? Container() : acceptTerms
            ])),
      ),
    );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: ICAppBar(title: AppLocalizations.of(context)!.termsOfService),
      body: SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: makeBody,
                ),
              ],
            ),
            _showSpinner ? Center(child: spinkit) : Container(),
          ],
        ),
      ),
    );
  }

  void _register() async {
    if (_acceptTerms)
      Navigator.pop(context, true);
    else
      Navigator.pop(context, false);
  }
}
