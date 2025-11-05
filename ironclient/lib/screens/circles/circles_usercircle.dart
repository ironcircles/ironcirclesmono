import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class UserCircleWidget extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;

  const UserCircleWidget(this.index, this.userFurnace, this.userCircleBloc,
      this.userCircleCache, this.goInside);

  @override
  UserCircleWidgetState createState() => UserCircleWidgetState();
}

class UserCircleWidgetState extends State<UserCircleWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  Animation<double>? animation;
  final double _circleRadius = 180;
  final double _circleRadiusBadgeVisible = 170;
  double _glowBorder = 300;

  // int tempCounter = 0;
  // UserCircleCache userCircleCache;

  // late UserCircleBloc _userCircleBloc;
  //late GlobalEventBloc _globalEventBloc;

  @override
  void dispose() {
    // animationController.dispose();
    //_userCircleBloc.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(UserCircleWidget oldWidget) {
    if (oldWidget.userCircleCache.usercircle !=
        widget.userCircleCache.usercircle)
      widget.userCircleBloc.notifyWhenBackgroundReady(
          widget.userFurnace, widget.userCircleCache);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {

    //Listen for the first CircleObject load
    widget.userCircleBloc.imageLoaded.listen((userCircleCache) {
      if (mounted) {


        if (userCircleCache.usercircle == widget.userCircleCache.usercircle) {
          setState(() {
            //_imageReady = true;
          });
        }
      }
    }, onError: (err) {
      debugPrint("UserCircleWidget.initState: $err");
    }, cancelOnError: false);

    widget.userCircleBloc
        .notifyWhenBackgroundReady(widget.userFurnace, widget.userCircleCache);

    //_imagePath = _getBackgroundPath();

    super.initState();

    //double width = MediaQuery.of(context).size.width;
    //double height = MediaQuery.of(context).size.height;

    if (Platform.isIOS) _glowBorder = 270;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    //debugPrint('usercircle build');

    if (width > height) {
      _glowBorder = 0;
    } else {
      if (Platform.isIOS)
        _glowBorder = 270;
      else
        _glowBorder = 300;
    }

    // if (width > 750) {
    //_circleRadiusBadgeVisible = 160;
    // _glowBorder = 0;
    //_circleRadius = 150;
    // }
    //debugPrint(width);
    // debugPrint(height);

    //800.0
    //I/flutter ( 4956): 1232.0

    return InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.lightBlueAccent.withOpacity(.1),
        onTap: () {
          if (mounted) {
            setState(() {
              widget.goInside(widget.userCircleCache);
            });
          }
        },
        child: Container(
            padding: const EdgeInsets.all(4.0),
            // color: Colors.black,
            child: Stack(alignment: Alignment.center, children: <Widget>[
              Center(
                  child: widget.userCircleCache.showBadge!
                      ? AvatarGlow(
                          glowCount: 2,
                          glowRadiusFactor: 0.2,
                          startDelay: const Duration(milliseconds: 1000),
                          //duration: Duration(milliseconds: 2000),
                          //repeatPauseDuration: const Duration(milliseconds: 100),
                          // endRadius: (_circleRadiusBadgeVisible +
                          // _glowBorder),
                          glowColor: globalState.theme.circleGlow,
                          repeat: true,
                          animate: true,
                          curve: Curves.slowMiddle,
                          child: Material(
                              elevation: 8.0,
                              shape: const CircleBorder(),
                              child: ClipOval(
                                  child: widget.userCircleCache
                                              .backgroundColor !=
                                          null
                                      ? Container(
                                          height: _circleRadiusBadgeVisible,
                                          width: _circleRadiusBadgeVisible,
                                          color: widget
                                              .userCircleCache.backgroundColor,
                                        )
                                      : _getBackgroundPath() != null
                                          ? (widget.userCircleBloc
                                                  .isBackgroundReady(
                                                      widget.userFurnace,
                                                      widget.userCircleCache)
                                              ? Image.file(
                                                  File(_getBackgroundPath()!),
                                                  height:
                                                      _circleRadiusBadgeVisible,
                                                  width:
                                                      _circleRadiusBadgeVisible,
                                                  fit: BoxFit.cover)
                                              : Image.asset(
                                                  'assets/images/black.jpg',
                                                  height:
                                                      _circleRadiusBadgeVisible,
                                                  width:
                                                      _circleRadiusBadgeVisible,
                                                  fit: BoxFit.cover,
                                                ))
                                          : widget.userCircleCache.cachedCircle!
                                                      .type ==
                                                  CircleType.VAULT
                                              ? Image.asset(
                                                  'assets/images/vault.jpg',
                                                  height:
                                                      _circleRadiusBadgeVisible,
                                                  width:
                                                      _circleRadiusBadgeVisible,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.asset(
                                                  'assets/images/iron.jpg',
                                                  height:
                                                      _circleRadiusBadgeVisible,
                                                  width:
                                                      _circleRadiusBadgeVisible,
                                                  fit: BoxFit.cover,
                                                ))))
                      : ClipOval(
                          child: widget.userCircleCache.backgroundColor != null
                              ? Container(
                                  height: _circleRadius,
                                  width: _circleRadius,
                                  color: widget.userCircleCache.backgroundColor,
                                )
                              : _getBackgroundPath() != null
                                  ? (widget.userCircleBloc.isBackgroundReady(
                                          widget.userFurnace,
                                          widget.userCircleCache)
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
                                  : widget.userCircleCache.cachedCircle!.type ==
                                          CircleType.VAULT
                                      ? Image.asset(
                                          'assets/images/vault.jpg',
                                          height: _circleRadius,
                                          width: _circleRadius,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/iron.jpg',
                                          height: _circleRadius,
                                          width: _circleRadius,
                                          fit: BoxFit.cover,
                                        ))),
              Center(
                  child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignment: Alignment.center,
                width: widget.userCircleCache.showBadge! ? _circleRadius - 13 : _circleRadius -
                    3, //_hasBackground() ? _circleRadius : _circleRadius - 10,
                height: 55,
              )),
              Center(
                  child: Container(
                      padding: const EdgeInsets.only(
                          bottom: 10.0, left: 15, right: 15),
                      child: Text(
                        widget.userCircleCache.prefName == null
                            ? ''
                            : widget.userCircleCache.prefName!,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.linear(globalState.nameScaleFactor),
                        style: ICTextStyle.getStyle(context: context, 
                            color: globalState.theme.circleText, fontSize: 15),
                      ))),
              Center(
                  child: Container(
                      padding:
                          const EdgeInsets.only(top: 30.0, left: 15, right: 15),
                      child: Text(widget.userFurnace.alias!,
                          textScaler: const TextScaler.linear(1.0),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: globalState.theme.furnace,
                            fontStyle: FontStyle.italic,
                            fontSize: 10, /*fontWeight: FontWeight.bold*/
                          )))),
              Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.userCircleCache.hidden!
                          ? Icon(
                              Icons.lock_rounded,
                              size: 25,
                              color: globalState.theme.menuIconsAlt,
                            )
                          : Container(),
                      widget.userCircleCache.guarded!
                          ? Icon(
                              Icons.security,
                              size: 25,
                              color: globalState.theme.menuIconsAlt,
                            )
                          : Container(),
                      widget.userCircleCache.showBadge!
                          ? Icon(
                              Icons.message,
                              size: 25,
                              color: globalState.theme.circleText,
                            )
                          : Container()
                    ],
                  )),
            ])));
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
