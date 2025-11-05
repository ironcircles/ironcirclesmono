import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';

//TODO passed in functions are not used, remove and test
class LongPressMenu extends StatefulWidget {
  final Circle? circle;
  final Function selected;
  final Color color;
  final double elevation;
  //final List<Reaction?> reactions;
  //final Color? highlightColor;
  //final Color? splashColor;
  final CircleObject? circleObject;
  final GlobalKey globalKey;
  final bool isUser; // = true;
  final bool showDate;
  final Function? copy;
  final Function? edit;
  final Function? setBackground;
  final Function? share;
  final Function? deleteCache;
  final Function? cancel;
  final Function? export;
  final Function? download;
  final Function? openExternalBrowser;
  final double keyboardSize;
  final bool wall;
  final bool enableReacting;
  final bool enablePosting;
  final ReplyObject? replyObject;

  const LongPressMenu(
      {required this.selected,
      required this.keyboardSize,
      required this.circle,
      required this.circleObject,
      required this.wall,
      required this.globalKey,
      this.color = Colors.white,
      this.elevation = 5,
      //required this.reactions,
      //this.highlightColor,
      //this.splashColor,
      required this.showDate,
      required this.isUser,
      this.copy,
      this.edit,
      this.setBackground,
      this.share,
      this.deleteCache,
      this.export,
      this.download,
      this.cancel,
      this.openExternalBrowser,
      this.enableReacting = true,
      this.enablePosting = true,
      this.replyObject});

  @override
  _LongPressMenuState createState() => _LongPressMenuState();
}

class LongPressFunction {
  static const int DELETE = 1;
  static const int CANCEL = 2;
  static const int COPY = 3;
  static const int SHARE = 4;
  static const int DELETE_CACHE = 5;
  static const int EDIT = 6;
  static const int OPEN_EXTERNAL_BROWSER = 7;
  static const int REPORT_POST = 8;
  static const int SET_BACKGROUND = 9;
  static const int EXPORT = 10;
  static const int DOWNLOAD = 11;
  static const int REPLY = 12;
  static const int HIDE = 13;
  static const int PIN = 14;
}

class _LongPressMenuState extends State<LongPressMenu>
    with TickerProviderStateMixin {
  double radius = 50;
  static const double iconFontSize = 32;
  final EdgeInsets boxPadding = const EdgeInsets.all(10);
  double boxItemsSpacing = 0;
  //Reaction? _selectedReaction;
  static double iconRadius = 10;
  static double padding = 5;
  final double _iconSize = 31;
  final double _iconPadding = 12;
  int _selectedReaction = -1;

  int _selectedFunction = -1;

  late AnimationController _scaleController;

  late Animation<double> _scaleAnimation;

  double _scale = 0;

  double _position = -1;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    final Tween<double> startTween = Tween(begin: 0, end: 1);
    _scaleAnimation = startTween.animate(_scaleController)
      ..addListener(() {
        setState(() {
          _scale = _scaleAnimation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.reverse) {
          if (widget.replyObject != null) {
            widget.selected(widget.replyObject, _selectedReaction);
          } else {
            widget.selected(widget.circleObject, _selectedReaction);
          }
          //debugPrint('popping');
          Navigator.of(context).pop(_selectedFunction);
        }
      });

    _scaleController.forward();

    /*
    _reactions = <Reaction>[
      Reaction(
        icon: Text('👍', style: TextStyle(fontSize: iconFontSize)),
      ),
      Reaction(
        icon: Text('🥰', style: TextStyle(fontSize: iconFontSize)),
      ),
      Reaction(
        icon: Text('🤣', style: TextStyle(fontSize: iconFontSize)),
      ),
      /*Reaction(
            previewIcon: Text('🙄', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),*/
      Reaction(
        icon: Text('😯', style: TextStyle(fontSize: iconFontSize)),
      ),
      Reaction(
        icon: Text('😥', style: TextStyle(fontSize: iconFontSize)),
      ),
      Reaction(
        icon: Text('😡', style: TextStyle(fontSize: iconFontSize)),
      ),
      Reaction(
        icon: Text('👎', style: TextStyle(fontSize: iconFontSize)),
      ),
    ];

     */
  }

  int getIndex(String emoji) {
    if (emoji == '👍') return 1;
    if (emoji == '🥰') return 2;
    if (emoji == '🤣') return 3;
    if (emoji == '😯') return 4;
    if (emoji == '😥') return 5;
    if (emoji == '😡') return 6;
    if (emoji == '👎') return 7;
    return 0;
  }

  Widget icon = Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Container(
          height: 29,
          padding: EdgeInsets.only(left: padding, right: padding),
          //color: globalState.theme.dropdownBackground,
          decoration: BoxDecoration(
              color: globalState.theme.userObjectBackground,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(iconRadius),
                  bottomRight: Radius.circular(iconRadius),
                  topLeft: Radius.circular(iconRadius),
                  topRight: Radius.circular(iconRadius))),
          child: Icon(
            Icons.add_reaction_outlined,
            color: globalState.theme.insertEmoji,
            size: 21,
          )));

  bool _showReply() {
    bool retValue = false;

    if (widget.replyObject != null) {
      if (widget.replyObject!.id != null && widget.enablePosting == true) {
        retValue = true;
      }
    } else if (widget.circleObject!.id != null &&
        widget.enablePosting == true) {
      if (widget.circle != null) {
        retValue = true;
      }
    }

    return retValue;
  }

  bool _showShare() {
    bool retValue = false;

    if (widget.share != null) {
      if (widget.circleObject != null && widget.circleObject!.id != null) {
        if (widget.circle != null) {
          if (widget.circleObject!.type == CircleObjectType.CIRCLEGIF) {
            retValue = true;
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLEIMAGE) {
            retValue = true;
          } else if (widget.circleObject!.type == CircleObjectType.CIRCLELINK) {
            retValue = true;
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLEVIDEO) {
            retValue = true;
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLEALBUM) {
            retValue = true;
          } else if (widget.circleObject!.type == CircleObjectType.CIRCLEFILE) {
            retValue = true;
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLERECIPE) {
            retValue = true;
          } else if (widget.circleObject!.type == CircleObjectType.CIRCLELIST) {
            retValue = true;
          } else if (widget.circleObject!.subType == SubType.LOGIN_INFO) {
            retValue = true;
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLEEVENT) {
            DateTime now = DateTime.now();
            if (DateTime(
                        widget.circleObject!.event!.endDate.year,
                        widget.circleObject!.event!.endDate.month,
                        widget.circleObject!.event!.endDate.day)
                    .compareTo(DateTime(now.year, now.month, now.day)) <
                0) {
              retValue = false;
            } else {
              retValue = true;
            }
          }
        }
      }
    }

    return retValue;
  }

  bool _showExport() {
    bool retValue = false;

    if (Platform.isAndroid ||
        Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS) {
      if (widget.share != null) {
        if (widget.circle != null && widget.circleObject != null) {
          if (widget.circleObject!.type == CircleObjectType.CIRCLEIMAGE) {
            if (widget.circle!.privacyShareImage != null) {
              if (widget.circle!.privacyShareImage! || widget.isUser)
                retValue = true;
            }
          } else if (widget.circleObject!.type ==
              CircleObjectType.CIRCLEVIDEO) {
            if (widget.circle!.privacyShareImage != null) {
              if (widget.circle!.privacyShareImage! || widget.isUser)

              //make sure it's cached
              if (widget.deleteCache != null) retValue = true;
            }
          } else if (widget.circleObject!.type == CircleObjectType.CIRCLEFILE) {
            if (widget.circle!.privacyShareImage != null) {
              if (widget.circle!.privacyShareImage! || widget.isUser)

              ///make sure it's cached
              if (widget.deleteCache != null) retValue = true;
            }
          }
        }
      }
    }

    return retValue;
  }

  bool _showSetBackground() {
    bool retValue = false;

    if (widget.share != null) {
      if (widget.circleObject != null && widget.circleObject!.id != null) {
        if (widget.circle != null && widget.circle!.dm == false) {
          if (widget.circleObject!.type == CircleObjectType.CIRCLEIMAGE) {
            if (widget.circle!.privacyShareImage != null) {
              if (widget.circle!.privacyShareImage!) retValue = true;
            }
          }
        }
      }
    }

    return retValue;
  }

  bool _showCopy() {
    bool retValue = false;

    if (widget.copy != null) {
      if (widget.circleObject != null && widget.circleObject!.id != null) {
        if (widget.circle != null) {
          if (widget.circleObject!.type == CircleObjectType.CIRCLEMESSAGE ||
              widget.circleObject!.type == CircleObjectType.CIRCLEGIF ||
              widget.circleObject!.type == CircleObjectType.CIRCLELINK) {
            if (widget.circle!.privacyCopyText != null) {
              if (widget.circle!.privacyCopyText!) retValue = true;
            }
          }
        }
      }
    }

    return retValue;
  }

  bool _showEdit() {
    bool retValue = false;

    if (widget.circleObject != null &&
        widget.circleObject!.type! == CircleObjectType.CIRCLEALBUM) {
      return retValue;
    }

    if (widget.isUser == true &&
        widget.edit != null &&
        widget.enablePosting == true) {
      if (widget.replyObject != null && widget.replyObject!.id != null) {
        retValue = true;
      } else if (widget.circleObject != null &&
          widget.circleObject!.id != null &&
          widget.circleObject!.subType == null) {
        retValue = true;
      }
    }

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) boxItemsSpacing = 2;

    return //Transform.scale(
        //scale: _scale,
        Stack(alignment: Alignment.center, children: [
      Positioned.fill(
        child: GestureDetector(
          onTapDown: (_) => _scaleController.reverse(),
          onVerticalDragUpdate: (_) => _scaleController.reverse(),
          onHorizontalDragUpdate: (_) => _scaleController.reverse(),
        ),
      ),
      Positioned(
        top: _getPosition(context),

        //alignment: Alignment.center,
        child: Transform.scale(
            scale: _scale,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ((widget.replyObject != null &&
                                  widget.replyObject!.id != null) ||
                              (widget.circleObject != null &&
                                  widget.circleObject!.id != null)) &&
                          widget.enableReacting == true
                      ? Card(
                          surfaceTintColor: Colors.transparent,
                          margin: EdgeInsets.zero,
                          shadowColor: Colors.green,
                          color: globalState.theme.background,
                          elevation: 3,
                          //clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          child: Padding(
                            padding: boxPadding,
                            child: Wrap(spacing: boxItemsSpacing, children: [
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('👍',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 1;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 1);
                                },
                              ),
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('🥰',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 2;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 2);
                                },
                              ),
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('🤣',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 3;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 3);
                                },
                              ),
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('😯',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 4;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 4);
                                },
                              ),
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('😥',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 5;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 5);
                                },
                              ),
                              InkWell(
                                splashColor: globalState
                                    .theme.buttonIconSplash, // inkwell color
                                child: const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: Text('😡',
                                        textScaler: TextScaler.linear(1.0),
                                        style:
                                            TextStyle(fontSize: iconFontSize))),
                                onTap: () {
                                  _selectedReaction = 6;
                                  _scaleController.reverse();
                                  //widget.selected(widget.circleObject, 6);
                                },
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(left: 0.0),
                                  child: InkWell(
                                      onTap: () {
                                        _selectedReaction = -2;
                                        _scaleController.reverse();
                                      },
                                      child: SizedBox(
                                          width: 35,
                                          height: 45,
                                          child: Icon(Icons.add,
                                              size: _iconSize,
                                              color: globalState
                                                  .theme.bottomIcon))))
                            ]),
                            // ),
                          ),
                        )
                      : Container(),
                  Card(
                      surfaceTintColor: Colors.transparent,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      elevation: 2,
                      shadowColor: Colors.green,
                      color: globalState.theme.longPressLower.withOpacity(.8),
                      child: SizedBox(
                          width: 332, //MediaQuery.of(context).size.width -10,
                          //height: 20,
                          child: Padding(
                              padding: const EdgeInsets.only(
                                top: 5,
                                bottom: 5,
                                left: 10,
                                right: 20,
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  //mainAxisSize: MainAxisSize.max,
                                  children: [
                                    !widget.isUser
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction
                                                          .REPORT_POST;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.report,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    !widget.isUser
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.HIDE;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.delete,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.DELETE;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.delete,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon))),
                                    widget.wall == false &&
                                            widget.circleObject != null &&
                                            widget.circleObject!.pinned ==
                                                false &&
                                            widget.circleObject!.id != null
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.PIN;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(
                                                    Icons.push_pin_rounded,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    !widget.isUser
                                        ? const Spacer()
                                        : Container(),
                                    widget.wall == false && _showSetBackground()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction
                                                          .SET_BACKGROUND;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.image,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    // widget.wall == false &&
                                    _showReply()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.REPLY;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.reply,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    _showExport()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.EXPORT;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.download,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    _showShare()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.SHARE;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.share,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    _showCopy()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.COPY;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.content_copy,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    widget.openExternalBrowser != null
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction
                                                          .OPEN_EXTERNAL_BROWSER;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(
                                                    Icons.open_in_browser,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    _showEdit()
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.EDIT;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.edit,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    widget.download != null
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction
                                                          .DOWNLOAD;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.play_for_work,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    widget.deleteCache != null
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction
                                                          .DELETE_CACHE;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(Icons.clear_rounded,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                    widget.cancel != null
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                left: _iconPadding),
                                            child: InkWell(
                                                onTap: () {
                                                  _selectedFunction =
                                                      LongPressFunction.CANCEL;
                                                  _scaleController.reverse();
                                                },
                                                child: Icon(
                                                    Icons.stop_circle_outlined,
                                                    size: _iconSize,
                                                    color: globalState
                                                        .theme.bottomIcon)))
                                        : Container(),
                                  ]))))
                ])),
        /*Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.cancel_rounded,
                color: globalState.theme.buttonDisabled),
            /*iconSize: 22,*/
            //constraints: BoxConstraints(maxHeight: 20),
            onPressed: () {
              widget.selected(widget.circleObject, -1);
              //widget.removeImage(index);
              // _openRegistration(context);
            },
          )),

       */
      )
    ]);
  }

  double _getPosition(BuildContext context) {
    // if (widget.globalKey.currentContext==null) return MediaQuery.of(context).size.height / 2;

    if (_position == -1) {
      RenderBox box =
          widget.globalKey.currentContext!.findRenderObject() as RenderBox;
      Offset offset = box.localToGlobal(Offset.zero); //this is global position

      //double position = offset.dy + 20; //* 3.3;

      double moveUp = 120;

      if (widget.circleObject != null && widget.circleObject!.id == null)
        moveUp = 40;

      if (widget.replyObject != null) moveUp = 120; //50;

      if (widget.enableReacting == false) {
        moveUp = 10;
      }

      double position = offset.dy - moveUp; //* 3.3;

      if (widget.showDate) position = position + 45;
      if (position < 100) position = 100;

      _position = position + widget.keyboardSize;
    }

    return _position;
  }
}
