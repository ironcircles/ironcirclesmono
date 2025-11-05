import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class CirclesUserCircleDesktop extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;
  final double screenWidth;

  const CirclesUserCircleDesktop(this.screenWidth, this.index, this.userFurnace,
      this.userCircleBloc, this.userCircleCache, this.goInside);

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<CirclesUserCircleDesktop> {
  final double _circleRadius = 60;
  final InvitationBloc _invitationBloc = InvitationBloc();
  AnimationController? animationController;
  Animation<double>? animation;
  //final double _circleRadius = 180;
  final double _circleRadiusBadgeVisible = 60;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(CirclesUserCircleDesktop oldWidget) {
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

    super.initState();
  }

  _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stackedUserCircleImage = Container(
        padding: const EdgeInsets.all(0.0),
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
                              child: widget.userCircleCache.backgroundColor !=
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
                                              height: _circleRadiusBadgeVisible,
                                              width: _circleRadiusBadgeVisible,
                                              fit: BoxFit.cover)
                                          : Image.asset(
                                              'assets/images/black.jpg',
                                              height: _circleRadiusBadgeVisible,
                                              width: _circleRadiusBadgeVisible,
                                              fit: BoxFit.cover,
                                            ))
                                      : widget.userCircleCache.cachedCircle!
                                                  .type ==
                                              CircleType.VAULT
                                          ? Image.asset(
                                              'assets/images/vault.jpg',
                                              height: _circleRadiusBadgeVisible,
                                              width: _circleRadiusBadgeVisible,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/iron.jpg',
                                              height: _circleRadiusBadgeVisible,
                                              width: _circleRadiusBadgeVisible,
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
          // Center(
          //     child: Container(
          //   decoration: const BoxDecoration(
          //     color: Color.fromRGBO(0, 0, 0, 0.5),
          //     borderRadius: BorderRadius.all(Radius.circular(12)),
          //   ),
          //   alignment: Alignment.center,
          //   width: widget.userCircleCache.showBadge!
          //       ? _circleRadius - 13
          //       : _circleRadius -
          //           3, //_hasBackground() ? _circleRadius : _circleRadius - 10,
          //   height: _circleRadius / 2,
          // )),
          // Center(
          //     child: Container(
          //         padding:
          //             const EdgeInsets.only(bottom: 10.0, left: 15, right: 15),
          //         child: Text(
          //           widget.userCircleCache.prefName == null
          //               ? ''
          //               : widget.userCircleCache.prefName!,
          //           overflow: TextOverflow.fade,
          //           softWrap: false,
          //           textAlign: TextAlign.center,
          //           textScaler: TextScaler.linear(globalState.nameScaleFactor),
          //           style: ICTextStyle.getStyle(
          //               context: context,
          //               color: globalState.theme.circleText,
          //               fontSize: 15),
          //         ))),
          // Center(
          //     child: Container(
          //         padding:
          //             const EdgeInsets.only(top: 30.0, left: 15, right: 15),
          //         child: Text(widget.userFurnace.alias!,
          //             textScaler: const TextScaler.linear(1.0),
          //             textAlign: TextAlign.center,
          //             overflow: TextOverflow.fade,
          //             softWrap: false,
          //             style: TextStyle(
          //               color: globalState.theme.furnace,
          //               fontStyle: FontStyle.italic,
          //               fontSize: 10, /*fontWeight: FontWeight.bold*/
          //             )))),
          Padding(
              padding: const EdgeInsets.only(top: 30),
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
        ]));

   // debugPrint(widget.screenWidth.toString());

    return InkWell(
        highlightColor: Colors.lightBlueAccent.withOpacity(.1),
        onTap: () {
          if (mounted) {
            setState(() {
              widget.goInside(widget.userCircleCache);
            });
          }
          // widget.goInside(widget.userCircleCache);
        },
        child: Container(
            padding: const EdgeInsets.only(left: 5),
            //height: 58,
            decoration: BoxDecoration(
                color: globalState.theme.memberObjectBackground.withOpacity(.3),
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 0),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      stackedUserCircleImage,
                      // ClipOval(
                      //     child: widget.userCircleCache.backgroundColor != null
                      //         ? Container(
                      //             height: _circleRadius,
                      //             width: _circleRadius,
                      //             color: widget.userCircleCache.backgroundColor,
                      //           )
                      //         : _getBackgroundPath() != null
                      //             ? (widget.userCircleBloc.isBackgroundReady(
                      //                     widget.userFurnace,
                      //                     widget.userCircleCache)
                      //                 ? Image.file(File(_getBackgroundPath()!),
                      //                     height: _circleRadius,
                      //                     width: _circleRadius,
                      //                     fit: BoxFit.cover)
                      //                 : Image.asset(
                      //                     'assets/images/black.jpg',
                      //                     height: _circleRadius,
                      //                     width: _circleRadius,
                      //                     fit: BoxFit.cover,
                      //                   ))
                      //             : widget.userCircleCache.cachedCircle!.type ==
                      //                     CircleType.VAULT
                      //                 ? Image.asset(
                      //                     'assets/images/vault.jpg',
                      //                     height: _circleRadius,
                      //                     width: _circleRadius,
                      //                     fit: BoxFit.cover,
                      //                   )
                      //                 : Image.asset(
                      //                     'assets/images/iron.jpg',
                      //                     height: _circleRadius,
                      //                     width: _circleRadius,
                      //                     fit: BoxFit.cover,
                      //                   )),
                      Expanded(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Expanded(
                              //  flex: 3,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 5,
                                        ),
                                        child: ICText(
                                            widget.userCircleCache.prefName!,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                            textScaleFactor:
                                                globalState.nameScaleFactor,
                                            fontSize: 17,
                                            color: globalState.theme.labelText),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5),
                                          child: Row(children: [
                                            Expanded(
                                              flex: 1,
                                              child: ICText(
                                                  widget.userFurnace.alias!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  fontSize: 12,
                                                  textScaleFactor: 1.0,
                                                  color: globalState
                                                      .theme.furnace),
                                            ),
                                            //Spacer(),
                                          ])),
                                      Flexible(
                                          child: ICText(
                                            " ${_returnDateString(widget.userCircleCache)}",
                                            color: globalState
                                                .theme.labelTextSubtle,
                                            overflow: TextOverflow.fade,
                                            fontSize: 12,
                                            maxLines: 1,
                                            softWrap: false,
                                          ))
                                    ])),
                          ])),
                    ]))));
  }

  String _returnDateString(UserCircleCache userCircleCache) {
    DateTime now = DateTime.now();

    if (userCircleCache.lastItemUpdate!.year == now.year &&
        userCircleCache.lastItemUpdate!.month == now.month &&
        userCircleCache.lastItemUpdate!.day == now.day) {
      return DateFormat('hh:mm a').format(userCircleCache.lastItemUpdate!);
    } else {
      return DateFormat('MMM dd').format(userCircleCache.lastItemUpdate!);
    }
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
}
