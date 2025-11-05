import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class ForgeBoost extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Circle circle;

  const ForgeBoost(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.circle})
      : super(key: key);

  @override
  _ForgeBoostState createState() => _ForgeBoostState();
}

class _ForgeBoostState extends State<ForgeBoost> {
  UserCircleCache? _userCircleCache;
  int _retention = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _userCircleCache = widget.userCircleCache;

    _retention = widget.circle.retention!;

    super.initState();
  }

  popReturnData() {
    //Navigator.of(cont,).pop(widget.userCircleCache);
    Navigator.pop(context, widget.userCircleCache);

    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(children: <Widget>[
          Text(
            "Circle Name:  ",
            style: TextStyle(
                color: globalState.theme.labelTextSubtle, fontSize: 16),
          ),
          Flexible(
              child: Text(
            _userCircleCache!.circleName != null
                ? _userCircleCache!.circleName!
                : _userCircleCache!.prefName == null
                    ? ''
                    : _userCircleCache!.prefName!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: globalState.theme.labelReadOnlyValue, fontSize: 16),
          )),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(children: <Widget>[
          Text(
            "Network:  ",
            style: TextStyle(
                color: globalState.theme.labelTextSubtle, fontSize: 16),
          ),
          Text(
            widget.userFurnace.alias!,
            style: TextStyle(color: globalState.theme.furnace, fontSize: 16),
          ),
        ]),
      ),
      /*!kReleaseMode
          ? Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(children: <Widget>[
                Text(
                  "CircleID:  ",
                  style: TextStyle(color: globalState.theme.labelText, fontSize: 16),
                ),
                SelectableText(
                  _userCircleCache.circle,
                  style: TextStyle(
                      color: globalState.theme.labelReadOnlyValue, fontSize: 16),
                ),
              ]),
            )
          : Container(),

       */
    ]);

    bool isPressed = false;

    final body = Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 60),
        ),
        GestureDetector(
            child: InkWell(
              child: const Icon(Icons.skip_previous_rounded),
              onTap: () {
                //isPressed = true;
                _increment(10);
              },
            ),
            onLongPressStart: (_) async {
              isPressed = true;
              debugPrint('long pressed'); // for testing
              do {
                debugPrint('long pressing'); // for testing
                await Future.delayed(const Duration(milliseconds: 50));
                if (isPressed)
                  _increment(10);
                else
                  break;
              } while (isPressed);
            },
            onLongPressEnd: (_) {
              debugPrint('long pressing stopped');
              setState(() {
                isPressed = false;
              });

              //setState(() => isPressed = false);
            }),
        Row(children: [
          const Spacer(),
          Column(children: [
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: globalState.theme.textField,
                  backgroundColor: globalState.theme.tabBackground,
                ),
                onPressed: () {
                  _decrement(10);
                },
                child: const Text('-')),
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: globalState.theme.textField,
                  backgroundColor: globalState.theme.tabBackground,
                ),
                onPressed: () {
                  _decrement(100);
                },
                child: const Text('--')),
          ]),
          Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                _retention == 0
                    ? 'pass through'
                    : _retention < 1000
                        ? '$_retention GB'
                        : '${_retention / 1000} TB',
                style:
                    TextStyle(color: globalState.theme.textField, fontSize: 30),
              )),
          Column(children: [
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: globalState.theme.textField,
                  backgroundColor: globalState.theme.tabBackground,
                ),
                onPressed: () {
                  _increment(10);
                },
                child: const Text('+')),
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: globalState.theme.textField,
                  backgroundColor: globalState.theme.tabBackground,
                ),
                onPressed: () {
                  _increment(100);
                },
                child: const Text('++')),
          ]),
          const Spacer()
        ])
      ],
    );

    final topAppBar = AppBar(
      backgroundColor: globalState.theme.appBar,
      elevation: 0.1,
      //backgroundColor: Colors.black,
      title: Text("Forge Boost",
          style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
      actions: const <Widget>[],
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
    );

    final makeSubmit = Container(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: 'SUBMIT',
                onPressed: () {
                  FormattedSnackBar.showSnackbarWithContext(
                      context, "Insufficient IronCoin", "", 4,  false);
                }),
          ),
        ]),
      ),
    );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: topAppBar,
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  makeHeader,
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                  ),
                  Expanded(child: body),
                  makeSubmit,
                ],
              ))),
    );
  }

  _increment(int value) {
    setState(() {
      _retention += value;
      if (_retention > 2000) _retention = 2000;
    });
  }

  _decrement(int value) {
    setState(() {
      _retention -= value;

      if (_retention < 0) _retention = 0;
    });
  }
}
