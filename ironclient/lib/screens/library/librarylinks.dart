import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/link_widget.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';

class LibraryLinks extends StatefulWidget {
  //final List<UserFurnace> userFurnaces;
  final List<CircleObject>? circleObjects;
  final GlobalEventBloc globalEventBloc;
  final bool shuffle;
  final bool slideUpPanel;
  final Function? updateSelected;

  const LibraryLinks({
    this.circleObjects,
    required this.shuffle,
    this.slideUpPanel = false,
    required this.globalEventBloc,
    this.updateSelected,
    Key? key,
  }) : super(key: key);

  @override
  LibraryLinksState createState() => LibraryLinksState();
}

class LibraryLinksState extends State<LibraryLinks> {
  //ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CircleObject? _selected;
  //late GlobalEventBloc _globalEventBloc;
  final double _iconSize = 31;
  final double _iconPadding = 12;
  List<CircleObject> _circleObjects = [];
  final List<CircleObject> _emptyList = [];
  bool filter = false;
  final ScrollController _scrollController = ScrollController();
  bool _toggleIcons = false;

  @override
  void initState() {
    widget.globalEventBloc.clear.listen((circleObject) {
      if (mounted) {
        setState(() {
          //_selected = null;
          if (widget.slideUpPanel == false) _toggleIcons = false;
        });
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.scrollLibraryToTop.listen((value) {
      if (mounted) {
        setState(() {
          if (_scrollController.hasClients) {
            _selected = null;
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 1),
                curve: Curves.easeInOut);
          }
        });
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    if (widget.slideUpPanel) {
      _toggleIcons = true;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    _circleObjects = [];
    _circleObjects.addAll(widget.circleObjects!);
    _circleObjects
        .retainWhere((element) => element.type == CircleObjectType.CIRCLELINK);

    if (!widget.shuffle) {
      _circleObjects.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });
    }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding:
                  const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _toggleIcons && widget.slideUpPanel == false
                      ? Row(children: [
                          IconButton(
                            color: globalState.theme.background,
                            onPressed: () {
                              if (widget.slideUpPanel == false) {
                                setState(() {
                                  _selected = null;
                                  _toggleIcons = false;
                                });

                                if (widget.updateSelected != null) {
                                  widget.updateSelected!(_emptyList);
                                }
                              }
                            },
                            icon: Icon(
                              Icons.cancel,
                              color: globalState.theme.buttonIcon,
                            ),
                          ),
                          const Spacer(),
                          _selected != null &&
                                  _selected!.circle!.privacyShareURL! &&
                                  widget.slideUpPanel == false
                              ? Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: InkWell(
                                      onTap: () {
                                        DialogShareTo.shareToPopup(
                                            context,
                                            _selected!.userCircleCache!,
                                            _selected!,
                                            ShareCircleObject
                                                .shareToDestination);
                                      },
                                      child: Icon(Icons.share,
                                          size: _iconSize,
                                          color: globalState.theme.bottomIcon)))
                              : Container(),
                          widget.slideUpPanel == false
                              ? Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: InkWell(
                                      onTap: () {
                                        LaunchURLs.openExternalBrowser(
                                            context, _selected!);
                                      },
                                      child: Icon(Icons.open_in_browser,
                                          size: _iconSize,
                                          color: globalState.theme.bottomIcon)))
                              : Container(),
                          _selected != null &&
                                  _selected!.circle!.privacyShareURL! &&
                                  widget.slideUpPanel == false
                              ? Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: _selected!.link!.url!));
                                      },
                                      child: Icon(Icons.content_copy,
                                          size: _iconSize,
                                          color: globalState.theme.bottomIcon)))
                              : Container(),
                        ])
                      : Container(),
                  Expanded(
                      child: ListView.separated(
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 10,
                              color: globalState.theme.background,
                            );
                          },
                          itemCount: _circleObjects.length,
                          controller: _scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            CircleObject circleObject = _circleObjects[index];

                            return Stack(children: [
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Container(
                                            alignment: Alignment.topRight,
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                                color: globalState.theme.card,
                                                borderRadius: const BorderRadius
                                                        .only(
                                                    bottomLeft:
                                                        Radius.circular(10.0),
                                                    bottomRight:
                                                        Radius.circular(10.0),
                                                    topLeft:
                                                        Radius.circular(10.0),
                                                    topRight:
                                                        Radius.circular(10.0))),
                                            child: InkWell(
                                                // onTap: () => LaunchURLs.launchURLForCircleObject(
                                                //     context, circleObject),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: <Widget>[
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          top: index == 0
                                                              ? 0
                                                              : 15,
                                                          bottom: Library
                                                              .getPadding(
                                                                  width)),
                                                      child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            LinkWidget(
                                                              longPress:
                                                                  _longPress,
                                                              shortPress:
                                                                  _shortPress,
                                                              anythingSelected: widget
                                                                      .slideUpPanel
                                                                  ? true
                                                                  : _selected !=
                                                                      null, // > 0, _selectedObjects.length == 1
                                                              isSelected:
                                                                  _selected ==
                                                                      circleObject, //.contains(circleObject)
                                                              circleObject:
                                                                  circleObject,
                                                              libraryObjects:
                                                                  _circleObjects,
                                                              isSelecting: widget
                                                                      .slideUpPanel
                                                                  ? true
                                                                  : _selected !=
                                                                      null, //.length == 1
                                                            )
                                                          ]))
                                                ])))
                                      ])),
                            ]);
                          })),
                ],
              )),
        ));
  }

  _shortPress(CircleObject circleObject, Circle? circle) {
    if (_toggleIcons) {
      if (circleObject == _selected) {
        setState(() {
          _selected = null;
          if (widget.slideUpPanel == false) _toggleIcons = false;
        });
      } else if (circleObject != _selected) {
        setState(() {
          _selected = circleObject;
        });
      }

      if (widget.updateSelected != null) {
        if (_selected != null) {
          widget.updateSelected!([_selected!]);
        } else {
          widget.updateSelected!(_emptyList);
        }
      }
    } else if (_toggleIcons == false) {
      LaunchURLs.launchURLForCircleObject(context, circleObject);
      widget.updateSelected!(_emptyList);
    }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons) {
        _selected = null;
        if (widget.slideUpPanel == false) _toggleIcons = false;
      } else {
        if (circleObject.canShare(
            circleObject.userFurnace!.userid!, circleObject.circle!)) {
          _selected = circleObject;
          _toggleIcons = !_toggleIcons;
        } else
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.circleDoesNotAllowImageSharing, "", 2,  false);
      }
    });

    if (widget.updateSelected != null) {
      if (_selected != null) {
        widget.updateSelected!([_selected!]);
      } else {
        widget.updateSelected!(_emptyList);
      }
    }
  }
}
