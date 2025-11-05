/*import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/themes/darktheme.dart';
import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

enum Age { tooYoung, minor, adult }

class Params {
  Age age = Age.adult;
  bool tos = false;
  String username = '';
}

class DialogUsernameAndTerms {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static show(
    BuildContext context,
    Function captured,
    String username,
    String label,
  ) async {
    Params params = Params();
    params.username = username;

    await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              "Create Free Account",
              style: TextStyle(color: globalState.theme.dialogButtons),
            ),
          ),
          contentPadding: const EdgeInsets.all(5.0),
          content: _ShowTermsAndAge(scaffoldKey, params, captured, label),
          actions: <Widget>[
            /*new TextButton(
                child: Text('CANCEL',
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  Navigator.pop(context);
                }),

             */
            /*new TextButton(
                child: Text(
                  'CONTINUE',
                  style: TextStyle(color: globalState.theme.dialogButtons),
                ),
                onPressed: () {
                  _continue(context, success, params);
                  //if (_validPassword) Navigator.pop(context);
                })*/
          ],
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class _ShowTermsAndAge extends StatefulWidget {
  final scaffoldKey;
  final Params params;
  final Function captured;
  final String label;

  _ShowTermsAndAge(this.scaffoldKey, this.params, this.captured, this.label);

  _CapturePasscode createState() => _CapturePasscode();
}

class _CapturePasscode extends State<_ShowTermsAndAge> {
  // bool _oldEnough = false;
  int? _radioValue = 2;
  TextEditingController _username = TextEditingController();
  //bool _tos = false;
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
    widget.params.tos = true;
    _username.text = widget.params.username;
  }

  @override
  Widget build(BuildContext context) {
    final _tosWidgets = Container(
      //height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 0, top: 0, bottom: 0),
        child: Column(children: [
          Row(children: <Widget>[
            Theme(
                data: ThemeData(
                    unselectedWidgetColor: globalState.theme.checkUnchecked),
                child: Checkbox(
                  activeColor: globalState.theme.dialogButtons,
                  checkColor: globalState.theme.checkBoxCheck,
                  value: widget.params.tos,
                  onChanged: (newValue) {
                    setState(() {
                      widget.params.tos = newValue!;
                    });
                  },
                )),
            ICText(
              'Agree to:  ',
              color: globalState.theme.dialogLabel,
            ),
            Expanded(
                child: InkWell(
                    onTap: _showTOS,
                    child: Text(
                      'Terms of Service',
                      style: TextStyle(
                          color: globalState.theme.dialogButtons, fontSize: 14),
                    ))),
          ]),
        ]),
      ),
    );

    Widget _ageWidgets(BuildContext context) {
      return Container(
          //color: Colors.grey[900],
          //height: 75.0,
          child: Padding(
        padding: EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
        child: Column(children: [
          Padding(
              padding: EdgeInsets.only(left: 0, top: 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ICText(
                      "Age:  ",
                      color: globalState.theme.dialogLabel,
                    ),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              activeColor: globalState.theme.dialogButtons,
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    Expanded(
                        child: InkWell(
                            onTap: () {
                              _handleRadioValueChange(1);
                            },
                            child: Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                child: Text(
                                  "16-17",
                                  textScaleFactor:
                                      globalState.messageScaleFactor,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: globalState.theme.dialogLabel),
                                )))),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              activeColor: globalState.theme.dialogButtons,
                              value: 2,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    Expanded(
                        child: InkWell(
                            onTap: () {
                              _handleRadioValueChange(2);
                            },
                            child: Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                child: Text(
                                  "18+",
                                  textScaleFactor:
                                      globalState.messageScaleFactor,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: globalState.theme.dialogLabel),
                                )))),
                  ])),
          Padding(
            padding: EdgeInsets.only(bottom: 10),
          ),
        ]),
      ));
    }

    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
        width: screenWidth -50,
        height: widget.label.isNotEmpty ? 340 : 330,
        child: Scaffold(
          backgroundColor: globalState.theme.dialogTransparentBackground,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Stack(children: [
            Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(bottom: 10)),
                  widget.label.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text(
                            widget.label,
                            style: TextStyle(color: Colors.amber),
                          ))
                      : Padding(padding: EdgeInsets.only(bottom: 10)),
                  Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 0),
                      child: FormattedText(
                        autoFocus: true,
                        controller: _username,
                        onChanged: (content) {
                          widget.params.username = content;
                        },
                        labelText: 'name for your network',
                        maxLength: 25,
                      )),
                  Padding(padding: EdgeInsets.only(bottom: 5)),
                  Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 0),
                      child: FormattedText(
                        autoFocus: true,
                        controller: _username,
                        onChanged: (content) {
                          widget.params.username = content;
                        },
                        labelText: 'create a username',
                        maxLength: 25,
                      )),
                  Padding(padding: EdgeInsets.only(bottom: 5)),
                  Row(children: <Widget>[
                    Expanded(
                      child: _tosWidgets,
                    ),
                  ]),
                  //Padding(padding: EdgeInsets.only(bottom: 10)),
                  Row(children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 5, right: 5, bottom: 0),
                    ),
                    Expanded(
                      child: _ageWidgets(context),
                    ),
                  ]),
                  GradientButton(
                    text: 'CONTINUE',
                    onPressed: _continue,
                  )
                ])
          ]),
          //_showSpinner ? spinkit : Container()]),
        ));
  }

  _handleRadioValueChange(int? value) {
    if (value != null)
      setState(() {
        _radioValue = value;
        widget.params.age = Age.values[value];
      });
  }

  void _continue() async {
    if (widget.params.tos &&
        widget.params.age != Age.tooYoung &&
        widget.params.username.trim().isNotEmpty) {
      widget.params.username.trim();

      widget.captured(widget.params.username, widget.params.age == Age.minor);
      Navigator.of(context).pop();
    }
  }

  void _showTOS() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TermsOfService(
            readOnly: true,
          ),
        ));
  }
}

 */
