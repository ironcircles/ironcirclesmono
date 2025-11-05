import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/fullscreen/pdfviewer.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialoghandlefile.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:provider/provider.dart';

class LibraryFiles extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<CircleObject>? circleObjects;
  final GlobalEventBloc globalEventBloc;
  final bool shuffle;
  final bool slideUpPanel;
  final Function? updateSelected;

  const LibraryFiles({
    required this.circleObjects,
    required this.userFurnaces,
    required this.globalEventBloc,
    required this.shuffle,
    required this.slideUpPanel,
    this.updateSelected,
    Key? key,
  }) : super(key: key);

  @override
  LibraryFileState createState() => LibraryFileState();
}

class LibraryFileState extends State<LibraryFiles> {
  final ScrollController _scrollController = ScrollController();
  late GlobalEventBloc _globalEventBloc;
  late CircleFileBloc _circleFileBloc;
  CircleObject? _selected;
  final double _iconSize = 31;
  final double _iconPadding = 12;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool filter = false;
  List<CircleObject> _circleObjects = [];
  CircleObject? lastTapped;
  final List<CircleObject> _emptyList = [];
  bool _toggleIcons = false;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleFileBloc = CircleFileBloc(_globalEventBloc);

    widget.globalEventBloc.clear.listen((circleObject) {
      if (mounted) {
        setState(() {
          // _selected = null;
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

    _globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        try {
          setState(() {
            if (circleObject.type == CircleObjectType.CIRCLEFILE) {
              ProcessCircleObjectEvents.putCircleFile(
                  _circleObjects, circleObject, _circleFileBloc);

              if (circleObject.transferPercent == 100) {
                if (lastTapped != null &&
                    lastTapped!.seed == circleObject.seed) {
                  lastTapped = null;

                  if (circleObject.file!.extension! == 'pdf') {
                    _openPDF(circleObject, false);
                  } else {
                    _handleFile(circleObject);
                  }
                }
              }
            }
          });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'InsideCircle._globalEventBloc.progressIndicator.listen: $err');
        }
      }
    }, onError: (err) {
      debugPrint(
          "InsideCircle._globalEventBloc.progressIndicator.listen: $err");
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
    _circleObjects = [];
    _circleObjects.addAll(widget.circleObjects!);
    _circleObjects.retainWhere(
        (element) => (element.type == CircleObjectType.CIRCLEFILE));

    if (!widget.shuffle) {
      _circleObjects.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });
    }

    ListTile makeListTile(int index, CircleObject object) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0, color: globalState.theme.cardSeparator))),
            child: Icon(Icons.attach_file_rounded,
                color: globalState.theme.cardLeadingIcon),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              object.file!.name!,
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
              //circleObject.userFurnace.alias,
              style: TextStyle(
                  color: globalState.theme.cardTitle,
                  fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          object.userFurnace!.alias!,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.furnace),
                        ))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          "Circle: ",
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.cardLabel),
                        ))),
                Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          object.userCircleCache!.prefName!,
                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.textTitle),
                        ))),
              ],
            ),
          ]),
          trailing: widget.slideUpPanel
              ? null
              : Icon(Icons.keyboard_arrow_right,
                  color: globalState.theme.cardTrailingIcon, size: 30.0),
          onLongPress: () {
            _longPress(object);
          },
          onTap: () {
            //openDetail(context, userFurnace);
            _tapHandler(index, object);
          },
        );

    Card makeCard(int index, CircleObject object) => Card(
        surfaceTintColor: Colors.transparent,
        color: globalState.theme.card,
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          makeListTile(index, object),
        ]));

    final makeList = ListView.separated(
        // Let the ListView know how many items it needs to build
        itemCount: _circleObjects.length,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 1500,
        separatorBuilder: (context, index) {
          return Container(
            color: globalState.theme.background,
            height: 1,
            width: double.maxFinite,
          );
        },
        itemBuilder: (context, index) {
          final CircleObject item = _circleObjects[index];

          return InkWell(
              onLongPress: () {
                _longPress(item);
              },
              onTap: () {
                _tapHandler(index, item);
              },
              child: Stack(alignment: Alignment.topLeft, children: [
                makeCard(index, item),
                _selected != null && _selected == item
                    ? Positioned.fill(
                        child: Container(
                        color: _selected != null
                            ? const Color.fromRGBO(124, 252, 0, 0.5)
                            : Colors.transparent,
                        alignment: Alignment.center,
                      ))
                    : Container(),
                _selected == null && widget.slideUpPanel == false
                    ? const Padding(
                        padding: EdgeInsets.all(0), //5
                      )
                    : _selected == item
                        ? Padding(
                            padding: const EdgeInsets.all(0),
                            child: Icon(
                              Icons.check_circle,
                              color: globalState.theme.buttonIcon,
                            ))
                        : _selected != item
                            ? Padding(
                                padding: const EdgeInsets.all(0),
                                child: Icon(
                                  Icons.circle_outlined,
                                  color: globalState.theme.buttonIcon,
                                ))
                            : Container(),
                item.transferPercent != null &&
                        item.transferPercent != 0 &&
                        item.transferPercent != 100
                    ? Center(
                        child: CircularProgressIndicator(
                            value: item.transferPercent! / 100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                globalState.theme.button)))
                    : Container(),
              ]));
        });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      body: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
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
                              //_selectedObjects = [];
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
                      widget.slideUpPanel == false
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    ShareCircleObject.shareToDestination(
                                        context,
                                        _selected!.userCircleCache!,
                                        _selected!,
                                        true);
                                  },
                                  child: Icon(Icons.share,
                                      size: _iconSize,
                                      color: globalState.theme.buttonIcon)))
                          : Container(),
                    ])
                  : Container(),
              //header,
              // Spacer(),
              Expanded(
                child: makeList,
              ),
            ],
          )),
    );
  }

  void _tapHandler(int index, CircleObject object) async {
    if (_toggleIcons) {
      if (object != _selected) {
        setState(() {
          _selected = object;
        });
      } else if (object == _selected) {
        setState(() {
          _selected = null;
          if (widget.slideUpPanel == false) _toggleIcons = false;
        });
      }

      if (widget.updateSelected != null) {
        if (_selected != null) {
          widget.updateSelected!([_selected!]);
        } else {
          widget.updateSelected!(_emptyList);
        }
      }
    } else {
      lastTapped = object;
      if (object.file!.extension! == 'pdf') {
        _openPDF(object, true);
      } else {
        _handleFile(object);
      }
    }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons) {
        _selected = null;
        if (widget.slideUpPanel == false) _toggleIcons = false;
      } else {
        _selected = circleObject;
        _toggleIcons = !_toggleIcons;
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

  _openPDF(CircleObject circleObject, bool download) async {
    File internal = File(FileCacheService.returnFilePath(
        circleObject.userCircleCache!.circlePath!,
        '${circleObject.seed!}.${circleObject.file!.extension!}'));

    if (!internal.existsSync()) {
      if (download) {
        ///download the file
        _circleFileBloc.downloadFile(circleObject.userFurnace!,
            circleObject.userCircleCache!, circleObject);
      }

      return;
    }

    File external = File(FileCacheService.returnFilePath(
        circleObject.userCircleCache!.circlePath!, circleObject.file!.name!));

    if (external.existsSync()) {
      external.deleteSync();
    }

    internal.copySync(external.path);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PDFViewer(
                  circleObject: circleObject,
                  userCircleCache: circleObject.userCircleCache!,
                  name: circleObject.file!.name!,
                  path: external.path)));
    }
  }

  _handleFileResult(BuildContext context, CircleObject circleObject,
      HandleFile handleFile) async {
    if (mounted) {
      if (handleFile == HandleFile.download) {
        _export(circleObject);
      } else if (handleFile == HandleFile.inside) {
        ShareCircleObject.shareToDestination(
            context, circleObject.userCircleCache!, circleObject, true);
      } else if (handleFile == HandleFile.outside) {
        ShareCircleObject.shareToDestination(
            context, circleObject.userCircleCache!, circleObject, false);
      }
    }
  }

  _handleFile(CircleObject circleObject) async {
    File internal = File(FileCacheService.returnFilePath(
        circleObject.userCircleCache!.circlePath!,
        '${circleObject.seed!}.${circleObject.file!.extension!}'));

    if (!internal.existsSync()) {
      _downloadFile(circleObject);
      return;
    }

    if (mounted) {
      DialogHandleFile.handleFilePopup(
          context, circleObject, _handleFileResult);
    }
  }

  void _downloadFile(CircleObject circleObject) {
    setState(() {
      circleObject.retries = 0;
    });
    _circleFileBloc.downloadFile(
        circleObject.userFurnace!, circleObject.userCircleCache!, circleObject);
  }

  _export(
    CircleObject circleObject,
  ) async {
    circleObject.userCircleCache = circleObject.userCircleCache;

    await DialogDownload.showAndDownloadCircleObjects(
        context, 'Downloading file', [circleObject]);
    if (mounted) {
      DialogNotice.showNoticeOptionalLines(
          context, 'Download Complete', 'File download complete', false);
    }
  }
}
