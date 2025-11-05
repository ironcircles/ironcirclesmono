import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class DialogFontSize {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static selectFontSize(
    BuildContext context,
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
          title: Center(
              child: Text(
            "Set Font Size",
            textScaler: TextScaler.linear(globalState.dialogScaleFactor),
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          contentPadding: const EdgeInsets.all(10.0),
          content: FontSizeWidget(scaffoldKey),
          /*actions: <Widget>[
            TextButton(
                child: Text('CANCEL',
                    style: TextStyle(color: globalState.theme.buttonCancel)),
                onPressed: () {
                  Navigator.pop(context);
                }),
            TextButton(
                child: Text('SET',
                    style: TextStyle(
                      color: globalState.theme.buttonIcon,
                    )),
                onPressed: () {
                  globalState.userSetting.fontSize = _fontSize;

                  //success(_fontSize);
                  Navigator.of(context).pop();
                  //if (_validPassword) Navigator.pop(context);
                })
          ],

           */
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

class FontSizeWidget extends StatefulWidget {
  final scaffoldKey;

  const FontSizeWidget(
    this.scaffoldKey,
  );

  _FontSizeWidgetState createState() => _FontSizeWidgetState();
}

class _FontSizeWidgetState extends State<FontSizeWidget> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();

    if (globalState.userSetting.fontSize == FontSize.SMALL)
      _sliderValue = 1;
    else if (globalState.userSetting.fontSize == FontSize.LARGE)
      _sliderValue = 3;
    else if (globalState.userSetting.fontSize == FontSize.LARGEST)
      _sliderValue = 4;
    else
      _sliderValue = 2;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //width: 200,
        height: 300,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    //Spacer(),

                    SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(children: <Widget>[
                              Text(
                                AppLocalizations.of(context)
                                    !.adjustFontSizeExample,
                                textScaler: TextScaler.linear(globalState.labelScaleFactor),
                                style: TextStyle(
                                    fontSize: globalState.userSetting.fontSize,
                                    color: globalState.theme.labelText),
                              ),
                            ]))),

                    const Padding(padding: EdgeInsets.only(top: 15)),
                    Slider(
                      activeColor: globalState.theme.buttonIcon,
                      inactiveColor: globalState.theme.labelTextSubtle,
                      min: 1,
                      max: 4.0,
                      divisions: 3,
                      value: _sliderValue,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;

                          if (value == 1)
                            globalState.userSetting.fontSize = FontSize.SMALL;
                          else if (value == 2)
                            globalState.userSetting.fontSize = FontSize.DEFAULT;
                          else if (value == 3)
                            globalState.userSetting.fontSize = FontSize.LARGE;
                          else if (value == 4)
                            globalState.userSetting.fontSize = FontSize.LARGEST;
                        });
                      },
                    ),
                    Text(
                      _getDescription(),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: 16, color: globalState.theme.buttonIcon),
                    )
                  ])),
        ));
  }

  String _getDescription() {
    if (_sliderValue == 1)
      return AppLocalizations.of(context)!.adjustFontSizeSmall;
    else if (_sliderValue == 3)
      return AppLocalizations.of(context)!.adjustFontSizeLarge;
    else if (_sliderValue == 4)
      return AppLocalizations.of(context)!.adjustFontSizeLargest;
    return AppLocalizations.of(context)!.adjustFontSizeDefault;
  }
}
