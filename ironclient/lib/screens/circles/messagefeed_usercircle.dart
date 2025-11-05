import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class MessageFeedUserCircleWidget extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;
  final double radius;

  const MessageFeedUserCircleWidget(this.index, this.userFurnace,
      this.userCircleBloc, this.userCircleCache, this.goInside,
      {this.radius = 75});

  @override
  _MessageFeedUserCircleWidgetState createState() =>
      _MessageFeedUserCircleWidgetState();
}

class _MessageFeedUserCircleWidgetState
    extends State<MessageFeedUserCircleWidget> {
  double _circleRadius = 75;
  double _circleRadiusBadgeVisible = 70;

  @override
  void dispose() {
    // animationController.dispose();
    //_userCircleBloc.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(MessageFeedUserCircleWidget oldWidget) {
    if (oldWidget.userCircleCache.usercircle !=
        widget.userCircleCache.usercircle)
      widget.userCircleBloc.notifyWhenBackgroundReady(
          widget.userFurnace, widget.userCircleCache);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _circleRadius = widget.radius;
    _circleRadiusBadgeVisible = _circleRadius - 5;
    //_globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    //_userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    //local mutable instance
    //userCircleCache = widget.userCircleCache;

    //Listen for the first CircleObject load
    widget.userCircleBloc.imageLoaded.listen((userCircleCache) {
      if (mounted) {
        //debugPrint('image loaded: ${userCircleCache.usercircle} : ${userCircleCache.prefName}');

        if (userCircleCache.usercircle == widget.userCircleCache.usercircle) {
          //debugPrint('SHOULD HIT THIS FREAKING BREAKPOINT');
          // debugPrint('image matches: ${userCircleCache.prefName} : ${widget.userCircleCache.prefName}');
          setState(() {
            //_imageReady = true;
          });
        }
      }
    }, onError: (err) {
      debugPrint("UserCircleWidget.initState: $err");
    }, cancelOnError: false);

    // debugPrint ('${widget.userCircleCache.prefName} init State');
    //debugPrint(widget.userCircleCache.prefName);
    widget.userCircleBloc
        .notifyWhenBackgroundReady(widget.userFurnace, widget.userCircleCache);

    //_imagePath = _getBackgroundPath();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        /*decoration: BoxDecoration(
              color: globalState.theme.circleBackground,
            ),

             */
        padding: const EdgeInsets.all(4.0),
        // color: Colors.black,
        child: Stack(alignment: Alignment.center, children: <Widget>[
          Center(
              child: ClipOval(
                  child: widget.userCircleCache.backgroundColor != null
                      ? Container(
                          height: _circleRadiusBadgeVisible,
                          width: _circleRadiusBadgeVisible,
                          color: widget.userCircleCache.backgroundColor,
                        )
                      : _getBackgroundPath() != null
                          ? (widget.userCircleBloc.isBackgroundReady(
                                  widget.userFurnace, widget.userCircleCache)
                              ? Image.file(File(_getBackgroundPath()!),
                                  height: _circleRadius,
                                  width: _circleRadius,
                                  fit: BoxFit.cover)
                              : Image.asset(
                                  'assets/images/black.jpg',
                                  height: _circleRadius,
                                  width: _circleRadius,
                                  fit: BoxFit.cover,
                                ))
                          : globalState.theme.themeMode == ICThemeMode.dark
                              ? Image.asset(
                                  'assets/images/iron.jpg',
                                  height: _circleRadiusBadgeVisible,
                                  width: _circleRadiusBadgeVisible,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/iron.jpg',
                                  height: _circleRadiusBadgeVisible,
                                  width: _circleRadiusBadgeVisible,
                                  fit: BoxFit.cover,
                                ))),
          Center(
              child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            //color: Color.fromRGBO(0, 0, 0, 0.5),
            alignment: Alignment.center,
            width: _hasBackground() ? _circleRadius : _circleRadius - 6,
            height: 44,
          )),
          Center(
              child: Container(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    widget.userCircleCache.prefName == null
                        ? ''
                        : widget.userCircleCache.prefName!,
                    textScaler: const TextScaler.linear(1.0),
                    style: ICTextStyle.getStyle(context: context, 
                        color: globalState.theme.circleText, fontSize: 15),
                  ))),
          Center(
              child: Container(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: SizedBox(
                      width: _circleRadius -20,
                      child: FittedBox(
                          alignment: Alignment.center,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.userFurnace.alias!,
                            textScaler: const TextScaler.linear(1.0),
                            style: TextStyle(
                              // color: Color(0xff0cbab8),
                              color: globalState.theme.furnace,
                              fontStyle: FontStyle.italic,
                              fontSize: 10, /*fontWeight: FontWeight.bold*/
                            ),
                          ))))),
        ]));
  }

  String? _getBackgroundPath() {
    String? retValue;

    if (widget.userCircleCache.background != null) {
      retValue = FileSystemService.returnUserCircleBackgroundPath(
          widget.userCircleCache.circlePath!,
          widget.userCircleCache.background!);
    } else if (widget.userCircleCache.masterBackground != null) {
      retValue = FileSystemService.returnCircleBackgroundPath(
          widget.userCircleCache.circlePath!,
          widget.userCircleCache.masterBackground!);
    }

    return retValue;
  }

  bool _hasBackground() {
    bool retValue = false;

    if (widget.userCircleCache.background != null ||
        widget.userCircleCache.masterBackground != null) {
      retValue = true;
    }

    return retValue;
  }
}
