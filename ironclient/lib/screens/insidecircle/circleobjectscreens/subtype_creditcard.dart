import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SubtypeCreditCard extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserCircleBloc userCircleBloc;
  final CircleObjectBloc circleObjectBloc;
  final CircleObject? circleObject;
  final UserFurnace userFurnace;
  final int screenMode;
  final GlobalEventBloc globalEventBloc;
  final CircleObject? replyObject;

  const SubtypeCreditCard(
      {Key? key,
      this.circleObject,
      required this.userCircleCache,
      required this.userCircleBloc,
      required this.circleObjectBloc,
      required this.globalEventBloc,
      required this.userFurnace,
      required this.screenMode,
      required this.replyObject})
      : super(key: key);

  @override
  _CredentialState createState() => _CredentialState();
}

class _CredentialState extends State<SubtypeCreditCard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  TextEditingController _subString1 = TextEditingController();
  TextEditingController _subString2 = TextEditingController();
  TextEditingController _subString3 = TextEditingController();
  TextEditingController _subString4 = TextEditingController();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    if (widget.screenMode == ScreenMode.EDIT ||
        widget.screenMode == ScreenMode.READONLY) {
      _subString1.text = widget.circleObject!.subString1!;

      if (widget.circleObject!.subString2 != null)
        _subString2.text = widget.circleObject!.subString2!;
      if (widget.circleObject!.subString3 != null)
        _subString3.text = widget.circleObject!.subString3!;
      if (widget.circleObject!.subString4 != null)
        _subString4.text = widget.circleObject!.subString4!;
    }

    widget.circleObjectBloc.saveResults.listen((circleObject) {
      if (mounted) {
        Navigator.of(context).pop(circleObject);
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 35, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        "Card nickname:",
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: ExpandingLineText(
                        labelText: "enter nickname",
                        maxLines: 4,
                        controller: _subString1,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return 'required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        "Card number:",
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: ExpandingLineText(
                        labelText: "enter url",
                        //maxLines: 4,
                        controller: _subString2,
                        /*validator: (value) {
                          if (value.toString().isEmpty) {
                            return 'required';
                          }
                        },

                         */
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        "Expiration date:",
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: ExpandingLineText(
                        labelText: "enter date",
                        maxLines: 1,
                        controller: _subString3,
                        /* validator: (value) {
                          if (value.toString().isEmpty) {
                            return 'required';
                          }
                        },

                        */
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        "Pin:",
                        style: TextStyle(
                            fontSize: 18, color: globalState.theme.labelText),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: ExpandingLineText(
                        labelText: "enter pin",
                        maxLines: 1,
                        controller: _subString4,
                        /*validator: (value) {
                          if (value.toString().isEmpty) {
                            return 'required';
                          }
                        },

                         */
                      ),
                    ),
                  ]),
                ),
              ]),
        ),
      ),
    );

    final makeBottom = Container(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: widget.screenMode == ScreenMode.ADD ? 'POST' : 'UPDATE',
                onPressed: () {
                  _create();
                }),
          ),
        ]),
      ),
    );
    final topAppBar = AppBar(
      backgroundColor: globalState.theme.appBar,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      elevation: 0.1,
      //backgroundColor: Colors.black,
      title: Text(
          widget.screenMode == ScreenMode.ADD ? "New Credential" : 'Credential',
          style: ICTextStyle.getStyle(
              context: context,
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      actions: const <Widget>[],
    );

    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: topAppBar,
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      makeBody,
                      _showSpinner ? Center(child: spinkit) : Container(),
                    ],
                  ),
                ),
                Container(
                  //  color: Colors.white,
                  padding: const EdgeInsets.all(0.0),
                  child: widget.screenMode == ScreenMode.EDIT ||
                          widget.screenMode == ScreenMode.ADD
                      ? makeBottom
                      : Container(),
                ),
              ],
            )),
      ),
    );
  }

  _create() {
    try {
      if (_formKey.currentState!.validate()) {
        if (widget.screenMode == ScreenMode.ADD) {
          //TODO build options list from textcontroller array

          CircleObject newCircleObject = CircleObject.prepNewCircleObject(
              widget.userCircleCache,
              widget.userFurnace,
              '',
              0,
              widget.replyObject,
              type: CircleObjectType.CIRCLEMESSAGE);

          //newCircleObject.type = CircleObjectType.CIRCLEMESSAGE;
          newCircleObject.subType = SubType.LOGIN_INFO;
          newCircleObject.subString1 = _subString1.text.toString();
          newCircleObject.subString2 = _subString2.text.toString();
          newCircleObject.subString3 = _subString3.text.toString();
          newCircleObject.subString4 = _subString4.text.toString();

          newCircleObject.emojiOnly = false;

          widget.circleObjectBloc.saveCircleObject(
            widget.globalEventBloc,
            widget.userFurnace,
            widget.userCircleCache,
            newCircleObject,
          );
        } else if (widget.screenMode == ScreenMode.EDIT) {
          widget.circleObject!.subString1 = _subString1.text.toString();
          widget.circleObject!.subString2 = _subString2.text.toString();
          widget.circleObject!.subString3 = _subString3.text.toString();
          widget.circleObject!.subString4 = _subString4.text.toString();

          widget.circleObjectBloc.updateCircleObject(
            widget.circleObject!,
            widget.userFurnace,
          );
        }

        setState(() {
          _showSpinner = true;
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Credentials._create: $err');
    }
  }
}
