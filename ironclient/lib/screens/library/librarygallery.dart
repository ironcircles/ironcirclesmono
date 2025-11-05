import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreengalleryswiper.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlealbumscreen.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogmultishareto.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/album_widget.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/thumbnail.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

class LibraryGallery extends StatefulWidget {
  final List<CircleObject>? circleObjects;
  final GlobalEventBloc globalEventBloc;
  final bool shuffle;
  final Function captureMedia;
  final String mode;
  final UserFurnace? userFurnace;
  final UserCircleCache? userCircleCache;
  final CircleObjectBloc circleObjectBloc;
  final bool Function(ScrollEndNotification) onNotification;
  final Future<void> Function() refresh;
  final bool slideUpPanel;
  final Function? updateSelected;

  const LibraryGallery({
    this.userCircleCache,
    this.userFurnace,
    this.circleObjects,
    required this.globalEventBloc,
    required this.shuffle,
    required this.captureMedia,
    required this.circleObjectBloc,
    required this.onNotification,
    required this.refresh,
    required this.slideUpPanel,
    this.updateSelected,
    Key? key,
    required this.mode,
  }) : super(key: key);

  @override
  LibraryGalleryState createState() => LibraryGalleryState();
}

class LibraryGalleryState extends State<LibraryGallery> {
  final ScrollController _scrollController = ScrollController();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late CircleImageBloc _circleImageBloc;
  late CircleVideoBloc _circleVideoBloc; // = CircleVideoBloc(globalEventBloc)
  late CircleAlbumBloc _circleAlbumBloc;
  late GlobalEventBloc _globalEventBloc;
  GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<CircleObject> _circleObjects = [];
  final List<CircleObject> _selectedObjects = [];

  bool filter = false;
  bool _toggleIcons = false;
  bool _showShare = false;
  bool _showClearCache = false;

  @override
  void initState() {
    try {
      if (widget.userFurnace != null &&
          widget.userFurnace!.userid == '64ae55d490c688be1579dd9e') {
        //LogBloc.insertLog('made it to gallery', 'LibraryGallery.initState');
      }

      _circleImageBloc = CircleImageBloc(widget.globalEventBloc);
      _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
      //_circleVideoBloc = CircleVideoBloc(_globalEventBloc);
      _circleVideoBloc = CircleVideoBloc(_globalEventBloc);
      _circleAlbumBloc = CircleAlbumBloc(_globalEventBloc);

      // if (widget.slideUpPanel) {
      //   _globalEventBloc.openSlidingPanel.listen((message) async {
      //     if (mounted) {
      //       setState(() {
      //         _toggleIcons = true;
      //       });
      //     }
      //   }, onError: (err) {
      //     //_clearSpinner();
      //     debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
      //   }, cancelOnError: false);
      // }

      //if (widget.slideUpPanel == false) {
      widget.globalEventBloc.cacheDeletedStream.listen((circleObject) {
        if (mounted) {
          try {
            int index = _circleObjects
                .indexWhere((param) => param.seed == circleObject.seed);

            if (index >= 0) {
              setState(() {
                CircleObject old = _circleObjects[index];

                ProcessCircleObjectEvents.putCircleVideo(
                    _circleObjects, circleObject, _circleVideoBloc);

                //CircleObject old = _circleObjects[index];
                circleObject.userCircleCache = old.userCircleCache;
                circleObject.userFurnace = old.userFurnace;
                circleObject.circle = old.circle;
              });
            }
            //}
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('InsideCircle.cacheDeleted.listen: $err');
          }
        }
      }, onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.progressIndicator.listen((circleObject) {
        if (mounted) {
          try {
            if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
              int index = _circleObjects
                  .indexWhere((param) => param.seed == circleObject.seed);

              if (index >= 0) {
                setState(() {
                  CircleObject old = _circleObjects[index];

                  ProcessCircleObjectEvents.putCircleVideo(
                      _circleObjects, circleObject, _circleVideoBloc);

                  //CircleObject old = _circleObjects[index];
                  circleObject.userCircleCache = old.userCircleCache;
                  circleObject.userFurnace = old.userFurnace;
                  circleObject.circle = old.circle;

                  //_circleObjects[index] = circleObject;
                });
              }
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
                'LibraryVideo._globalEventBloc.videoProgressIndicator.listen: $err');
          }
        }
      }, onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.previewDownloaded.listen((object) {
        //find the circle object

        if (mounted) {
          try {
            CircleObject circleObject = _circleObjects.firstWhere(
                (element) => element.id == object.id,
                orElse: () => CircleObject(ratchetIndexes: []));

            if (circleObject.seed != null) {
              if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
                setState(() {
                  circleObject.video!.videoState = object.video!.videoState!;
                  /*circleObject.video!.previewFile = File(
                    VideoCacheService.returnPreviewPath(
                        circleObject.userCircleCache!.circlePath!,
                        circleObject.seed!));

                 */
                });
              }
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
                'insidecircle listen _globalEvenBloc.previewDownloaded: $err');
          }
        }
      }, onError: (err) {
        debugPrint("CircleImageMemberWidget.initState: $err");
      }, cancelOnError: false);
      //} else {
      /*widget.globalEventBloc.refreshWall.listen((refresh) async {
        if (mounted) {
          setState(() {});
        }
      }, onError: (err) {
        //_clearSpinner();
        debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
      }, cancelOnError: false);

       */
      // }

      _globalEventBloc.clear.listen((circleObject) {
        if (mounted) {
          setState(() {
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
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 1),
                  curve: Curves.easeInOut);
            }
          });
        }
      }, onError: (err) {
        debugPrint("InsideCircle.listen: $err");
      }, cancelOnError: false);

      super.initState();

      if (widget.mode == "vault") {
        widget.circleObjectBloc.refreshVault.listen((refresh) async {
          if (mounted) {
            setState(() {
              _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
            });
          }
        }, onError: (err) {
          //_clearSpinner();
          debugPrint("LibraryGallery.circleObjectBloc.refreshVault: $err");
        }, cancelOnError: false);
      }

      // if (widget.userFurnace != null &&
      //     widget.userFurnace!.userid == '64ae55d490c688be1579dd9e') {
      //   LogBloc.insertLog(
      //       'made it to past listeners', 'LibraryGallery.initState');
      // }

      if (widget.slideUpPanel) {
        _toggleIcons = true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  _showGif(double width, double height, CircleObject circleObject,
      bool isAnythingSelected, bool isSelected) {
    //return Container();
    return Expanded(
        child: InkWell(
            onLongPress: () {
              _longPress(circleObject);
            },
            onTap: () {
              _shortPress(circleObject, null);
            },
            child: Padding(
                padding: EdgeInsets.all(isSelected ? 1 : 0),
                child: Stack(children: [
                  Container(
                    width: width,
                    height: height,
                    color: globalState.theme.userObjectBackground,
                    child: circleObject.gif != null
                        ? CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: circleObject.gif!.giphy!,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : spinner,
                  ),
                  isSelected
                      ? Container(
                          color: const Color.fromRGBO(124, 252, 0, 0.5),
                          alignment: Alignment.center,
                          width: width,
                          height: height,
                        )
                      : Container(),
                  isSelected
                      ? Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.check_circle,
                            color: globalState.theme.buttonIcon,
                          ))
                      : isAnythingSelected
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.circle_outlined,
                                color: globalState.theme.buttonDisabled,
                              ))
                          : Container(),
                  isSelected
                      ? Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _showFullScreenSwiperForSelected(circleObject);
                            },
                          ))
                      : Container()
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    _circleObjects = [];
    _circleObjects.addAll(widget.circleObjects!);
    _circleObjects.retainWhere((element) =>
        (element.type == CircleObjectType.CIRCLEIMAGE ||
            element.type == CircleObjectType.CIRCLEGIF ||
            element.type == CircleObjectType.CIRCLEVIDEO ||
            element.type == CircleObjectType.CIRCLEALBUM));

    _circleObjects.removeWhere((element) =>
        (element.type == CircleObjectType.CIRCLEALBUM &&
            element.album == null));

    // if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    //   _circleObjects.removeWhere((element) =>
    //   (element.type == CircleObjectType.CIRCLEALBUM));
    // }

    _circleObjects.removeWhere((element) =>
        (element.type == CircleObjectType.CIRCLEVIDEO &&
            element.video == null));

    _circleObjects.removeWhere((element) =>
        (element.type == CircleObjectType.CIRCLEVIDEO &&
            element.video!.videoState == VideoStateIC.FAILED));

    _circleObjects.removeWhere((element) =>
        (element.type == CircleObjectType.CIRCLEIMAGE &&
            element.image == null));

    _circleObjects.removeWhere((element) =>
        (element.type == CircleObjectType.CIRCLEVIDEO &&
            element.fullTransferState == BlobState.BLOB_DOWNLOAD_FAILED));

    if (!widget.shuffle) {
      _circleObjects.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });
    }

    ///print the contents of the array to the console
    // for (var circleObject in _circleObjects) {
    //   debugPrint("${circleObject.id!} : ${circleObject.seed!}");
    // }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        //appBar: widget.mode == "vault" ? ICAppBar(title: 'Media'): null,
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0, bottom: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /*widget.slideUpPanel
                        ? InkWell(
                            onTap: () {
                              /*Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Invites(
                                            userFurnaces: _userFurnaces!,
                                            invitations: _invitations,
                                            refreshCallback:
                                                _refreshInvitations,
                                            userCircleBloc: _userCircleBloc,
                                          )));

                               */
                            },
                            child: Container(
                                height: 35,

                                ///round corners
                                decoration: BoxDecoration(
                                    color: globalState.theme.urgentAction
                                        .withOpacity(.2),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Spacer(),
                                      ICText(
                                        'SELECT FROM DEVICE',
                                        color: globalState.theme.urgentAction,
                                      ),
                                      const Spacer(),
                                    ])))
                        : Container(),*/
                    _toggleIcons && widget.slideUpPanel == false
                        ? Row(children: [
                            IconButton(
                              color: globalState.theme.background,
                              onPressed: () {
                                if (widget.slideUpPanel == false) {
                                  setState(() {
                                    _selectedObjects.clear();
                                    _toggleIcons = false;
                                  });

                                  if (widget.updateSelected != null) {
                                    widget.updateSelected!(_selectedObjects);
                                  }
                                }
                              },
                              icon: Icon(
                                Icons.cancel,
                                color: globalState.theme.buttonIcon,
                              ),
                            ),
                            Text(
                              _selectedObjects.length.toString(),
                              textScaler: TextScaler.linear(
                                  globalState.labelScaleFactor),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: globalState.theme.labelText),
                            ),
                            const Spacer(),
                            (_checkIfCanDelete() || widget.mode == "vault") &&
                                    widget.slideUpPanel == false
                                ? IconButton(
                                    color: globalState.theme.background,
                                    onPressed: () {
                                      _delete();
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: globalState.theme.buttonIcon,
                                    ),
                                  )
                                : Container(),
                            widget.slideUpPanel == false && _showClearCache
                                ? IconButton(
                                    color: globalState.theme.background,
                                    onPressed: () {
                                      _deleteVideoCache();
                                    },
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: globalState.theme.buttonIcon,
                                    ),
                                  )
                                : Container(),
                            widget.slideUpPanel == false &&
                                    _showShare &&
                                    !Platform.isIOS
                                ? IconButton(
                                    color: globalState.theme.background,
                                    onPressed: () {
                                      _downloadObjects();
                                    },
                                    icon: Icon(
                                      Icons.download,
                                      color: globalState.theme.buttonIcon,
                                    ),
                                  )
                                : Container(),
                            widget.slideUpPanel == false && _showShare
                                ? IconButton(
                                    color: globalState.theme.background,
                                    onPressed: () {
                                      _shareObjects();
                                    },
                                    icon: Icon(
                                      Icons.share,
                                      color: globalState.theme.buttonIcon,
                                    ),
                                  )
                                : Container(),
                          ])
                        : Container(),
                    Expanded(
                        child: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: widget.refresh,
                            color: globalState.theme.buttonIcon,
                            child: NotificationListener<ScrollEndNotification>(
                                onNotification: widget.onNotification,
                                child: _circleObjects.isEmpty
                                    ? Container()
                                    : MasonryGridView.count(
                                        controller: _scrollController,
                                        itemCount: _circleObjects.length,
                                        crossAxisCount:
                                            InsideConstants.getGalleryWidth(
                                                screenWidth),
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 2,
                                        itemBuilder: (context, index) {
                                          try {
                                            CircleObject circleObject =
                                                _circleObjects[index];
                                            circleObject.userCircleCache ??=
                                                widget.userCircleCache;
                                            circleObject.userFurnace ??=
                                                widget.userFurnace;
                                            double width;
                                            double height;
                                            if (circleObject.type ==
                                                CircleObjectType.CIRCLEIMAGE) {
                                              width = circleObject.image!.width!
                                                  .toDouble();
                                              height = circleObject
                                                  .image!.height!
                                                  .toDouble();
                                            } else if (circleObject.type ==
                                                CircleObjectType.CIRCLEGIF) {
                                              width = circleObject.gif!.width!
                                                  .toDouble();
                                              height = circleObject.gif!.height!
                                                  .toDouble();
                                            } else if (circleObject.type ==
                                                CircleObjectType.CIRCLEALBUM) {
                                              width = 250;
                                              height = 250;
                                            } else {
                                              if (circleObject.video!.width ==
                                                  null) {
                                                width = 150;
                                                height = 150;
                                              } else {
                                                width = circleObject
                                                    .video!.width!
                                                    .toDouble();
                                                height = circleObject
                                                    .video!.height!
                                                    .toDouble();
                                              }
                                            }

                                            int columns =
                                                InsideConstants.getGalleryWidth(
                                                    screenWidth);
                                            double newWidth =
                                                screenWidth / columns;
                                            double ratio = width / newWidth;
                                            double newHeight = height / ratio;

                                            try {
                                              return Row(children: [
                                                circleObject.type ==
                                                        CircleObjectType
                                                            .CIRCLEIMAGE
                                                    ? ThumbnailWidget(
                                                        //key: GlobalKey(),
                                                        width: newWidth,
                                                        height: newHeight,
                                                        longPress: _longPress,
                                                        shortPress: _shortPress,
                                                        anythingSelected: widget
                                                                .slideUpPanel
                                                            ? true
                                                            : _selectedObjects
                                                                .isNotEmpty,
                                                        isSelected:
                                                            _selectedObjects
                                                                .contains(
                                                                    circleObject),
                                                        circleObject:
                                                            circleObject,
                                                        libraryObjects:
                                                            _circleObjects,
                                                        fullScreen:
                                                            _showFullScreenSwiperForSelected,
                                                        isSelecting: widget
                                                                .slideUpPanel
                                                            ? true
                                                            : _selectedObjects
                                                                .isNotEmpty,
                                                      )
                                                    : circleObject.type ==
                                                            CircleObjectType
                                                                .CIRCLEGIF
                                                        ? _showGif(
                                                            newWidth,
                                                            newHeight,
                                                            circleObject,
                                                            widget.slideUpPanel
                                                                ? true
                                                                : _selectedObjects
                                                                    .isNotEmpty,
                                                            _selectedObjects
                                                                .contains(
                                                                    circleObject))
                                                        : circleObject.type ==
                                                                CircleObjectType
                                                                    .CIRCLEALBUM
                                                            ? AlbumWidget(
                                                                width: newWidth,
                                                                height:
                                                                    newHeight,
                                                                userCircleCache:
                                                                    circleObject
                                                                        .userCircleCache!,
                                                                longPress:
                                                                    _longPress,
                                                                shortPress:
                                                                    _shortPress,
                                                                anythingSelected: widget
                                                                        .slideUpPanel
                                                                    ? true
                                                                    : _selectedObjects
                                                                        .isNotEmpty,
                                                                isSelected:
                                                                    _selectedObjects
                                                                        .contains(
                                                                            circleObject),
                                                                circleObject:
                                                                    circleObject,
                                                                libraryObjects:
                                                                    _circleObjects,
                                                                fullScreen:
                                                                    _openAlbum,
                                                                circleObjectBloc:
                                                                    widget
                                                                        .circleObjectBloc,
                                                                isSelecting: widget
                                                                        .slideUpPanel
                                                                    ? true
                                                                    : _selectedObjects
                                                                        .isNotEmpty,
                                                              )
                                                            : VideoGallery(
                                                                width: newWidth,
                                                                height:
                                                                    newHeight,
                                                                download:
                                                                    _downloadVideo,
                                                                userCircleCache:
                                                                    circleObject
                                                                        .userCircleCache!,
                                                                longPress:
                                                                    _longPress,
                                                                play:
                                                                    _showFullScreenSwiper,
                                                                shortPress:
                                                                    _shortPress,
                                                                anythingSelected: widget
                                                                        .slideUpPanel
                                                                    ? true
                                                                    : _selectedObjects
                                                                        .isNotEmpty,
                                                                isSelected:
                                                                    _selectedObjects
                                                                        .contains(
                                                                            circleObject),
                                                                circleObject:
                                                                    circleObject,
                                                                libraryObjects:
                                                                    _circleObjects,
                                                                fullScreen:
                                                                    _showFullScreenSwiperForSelected,
                                                                isSelecting: widget
                                                                        .slideUpPanel
                                                                    ? true
                                                                    : _selectedObjects
                                                                        .isNotEmpty,
                                                              )
                                              ]);
                                            } catch (err, trace) {
                                              LogBloc.insertError(err, trace);
                                              return spinner;
                                            }
                                          } catch (err, trace) {
                                            LogBloc.insertError(err, trace);
                                            return Container();
                                          }
                                        }))))
                  ],
                ))),
        floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: globalState.isDesktop() == false &&
                    widget.mode != "vault" &&
                    widget.slideUpPanel != true
                ? FloatingActionButton(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    backgroundColor: globalState.theme.homeFAB,
                    onPressed: () {
                      widget.captureMedia();
                    },
                    child: Icon(
                      Icons.camera_alt,
                      color: globalState.theme.background,
                    ))
                : Container()));
  }

  _shortPress(CircleObject circleObject, Circle? circle) {
    if (_selectedObjects.isNotEmpty || widget.slideUpPanel) {
      if (_selectedObjects.contains(circleObject)) {
        setState(() {
          _selectedObjects.remove(circleObject);

          if (_selectedObjects.isEmpty && widget.slideUpPanel == false) {
            _toggleIcons = false;
          } else {
            _showShareAndCache(circleObject);
          }
        });
      } else if (widget.mode == CircleType.VAULT) {
        setState(() {
          _selectedObjects.add(circleObject);
          _showShareAndCache(circleObject);
        });
      } else if (circleObject.canShare(
          circleObject.userFurnace!.userid!, circleObject.circle!)) {
        setState(() {
          _selectedObjects.add(circleObject);
          _showShareAndCache(circleObject);
        });
      } else
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.circleDoesNotAllowMediaSharing,
            "",
            2,
            false);
    } else {
      if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
        _openAlbum(circleObject);
      } else {
        _showFullScreenSwiper(circleObject);
      }
    }

    if (widget.updateSelected != null) {
      widget.updateSelected!(_selectedObjects);
    }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons && widget.slideUpPanel == false) {
        _selectedObjects.clear();
        _toggleIcons = false;
      } else {
        if (widget.mode == CircleType.VAULT) {
          _selectedObjects.add(circleObject);
          _toggleIcons = !_toggleIcons;
          _showShareAndCache(circleObject);
        } else if (circleObject.canShare(
            circleObject.userFurnace!.userid!, circleObject.circle!)) {
          _selectedObjects.add(circleObject);
          _showShareAndCache(circleObject);
          if (widget.slideUpPanel) _toggleIcons = !_toggleIcons;
          if (widget.slideUpPanel == false) _toggleIcons = true;
        } else
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.circleDoesNotAllowImageSharing,
              "",
              2,
              false);
      }
    });

    if (widget.updateSelected != null) {
      widget.updateSelected!(_selectedObjects);
    }
  }

  void _showFullScreenSwiperForSelected(CircleObject circleObject) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenGallerySwiper(
            libraryObjects:
                _selectedObjects.isNotEmpty ? _selectedObjects : [circleObject],
            globalEventBloc: _globalEventBloc,
            fullScreenSwiperCaller: widget.mode == "vault"
                ? FullScreenSwiperCaller.vault
                : FullScreenSwiperCaller.library,
            circleImageBloc: _circleImageBloc,
            circleObject: circleObject,
            userFurnace: circleObject.userFurnace!,
            circle: circleObject.circle,
            albumDownloadVideo: _albumDownloadVideo,
            circleAlbumBloc: _circleAlbumBloc,
            userCircleCache: widget.userCircleCache,
          ),
        ));
  }

  void _showFullScreenSwiper(CircleObject circleObject) {
    if (_selectedObjects.isEmpty)
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenGallerySwiper(
              libraryObjects: _circleObjects,
              globalEventBloc: _globalEventBloc,
              fullScreenSwiperCaller: widget.mode == "vault"
                  ? FullScreenSwiperCaller.vault
                  : FullScreenSwiperCaller.library,
              circleImageBloc: _circleImageBloc,
              circleObject: circleObject,
              userFurnace: circleObject.userFurnace!,
              circle: circleObject.circle,
              delete: _swiperDelete,
              albumDownloadVideo: _albumDownloadVideo,
              circleAlbumBloc: _circleAlbumBloc,
              userCircleCache: widget.userCircleCache,
            ),
          ));
    else
      _shortPress(circleObject, circleObject.circle!);
  }

  _checkIfCanDelete() {
    // for (var circleObject in _selectedObjects) {
    //   if (circleObject.circle!.id != DeviceOnlyCircle.circleID) return false;
    // }

    return true;
  }

  void _swiperDelete(CircleObject circleObject) async {
    FocusScope.of(context).unfocus();

    String title = AppLocalizations.of(context)!.deleteForYouTitle;
    String description = AppLocalizations.of(context)!.deleteForYouQuestion;

    if (circleObject.circle!.id == DeviceOnlyCircle.circleID) {
      description = AppLocalizations.of(context)!.deleteCachedQuestion;
    } else if (circleObject.creator?.id == circleObject.userFurnace!.userid) {
      ///Is this a vault?
      if (circleObject.circle!.type == CircleType.VAULT) {
        title = AppLocalizations.of(context)!.deleteItemsTitleVault;
        description = AppLocalizations.of(context)!.deleteItemsVault;
      } else {
        title = AppLocalizations.of(context)!.deleteForEveryoneTitle;
        description = AppLocalizations.of(context)!.confirmDeleteMessage;
      }
    }

    await DialogYesNo.askYesNo(context, title, description,
        _swiperDeleteConfirmed, null, false, circleObject);
  }

  _swiperDeleteConfirmed(CircleObject circleObject) async {
    List<CircleObject> isUserObject = [];
    List<CircleObject> isDeviceObject = [];

    setState(() {
      if (circleObject.circle!.id == DeviceOnlyCircle.circleID) {
        isDeviceObject.add(circleObject);
      } else if (circleObject.creator?.id == circleObject.userFurnace?.userid) {
        isUserObject.add(circleObject);
      } else {
        widget.circleObjectBloc.hideCircleObject(circleObject.userCircleCache!,
            circleObject.userFurnace!, circleObject);
        _globalEventBloc.broadcastDelete(circleObject);
      }
    });

    ///for device only objects
    if (isDeviceObject.isNotEmpty) {
      await _circleImageBloc.removeFromDeviceCache(isDeviceObject);
      _globalEventBloc.broadcastDelete(isDeviceObject.single);
    }

    ///for user's objects
    if (isUserObject.isNotEmpty) {
      await widget.circleObjectBloc.deleteLibraryObjects(isUserObject);
      _globalEventBloc.broadcastDelete(isUserObject.single);
    }
  }

  void _delete() async {
    FocusScope.of(context).unfocus();

    if (widget.mode == CircleType.VAULT) {
      await DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.deleteItemsTitleVault,
          AppLocalizations.of(context)!.deleteItemsVault,
          _deleteConfirmed,
          null,
          false,
          null);
    } else {
      await DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.deleteItemsTitle,
          AppLocalizations.of(context)!.deleteItems,
          _deleteFromCacheConfirmed,
          null,
          false,
          null);
    }
  }

  _deleteFromCacheConfirmed() async {
    List<CircleObject> isUserObject = [];
    List<CircleObject> isDeviceObject = [];

    setState(() {
      for (CircleObject circleObject in _selectedObjects) {
        if (circleObject.circle!.id == DeviceOnlyCircle.circleID) {
          isDeviceObject.add(circleObject);
        } else if (circleObject.creator?.id ==
            circleObject.userFurnace?.userid) {
          isUserObject.add(circleObject);
        } else {
          widget.circleObjectBloc.hideCircleObject(
              circleObject.userCircleCache!,
              circleObject.userFurnace!,
              circleObject);
        }
        widget.circleObjects!.remove(circleObject);
      }

      _selectedObjects.clear();
      _toggleIcons = false;
      _scaffoldKey = GlobalKey<ScaffoldState>();
    });

    ///for device only objects
    if (isDeviceObject.isNotEmpty) {
      await _circleImageBloc.removeFromDeviceCache(isDeviceObject);
    }

    ///for user's objects
    if (isUserObject.isNotEmpty) {
      await widget.circleObjectBloc.deleteLibraryObjects(isUserObject);
    }
  }

  _deleteConfirmed() async {
    await widget.circleObjectBloc!.deleteObjects(
        widget.userFurnace, widget.userCircleCache, _selectedObjects);

    //await _circleImageBloc.removeFromDeviceCache(_selectedObjects);

    setState(() {
      for (CircleObject circleObject in _selectedObjects) {
        widget.circleObjects!.remove(circleObject);
      }

      _selectedObjects.clear();
      _toggleIcons = false;
      _scaffoldKey = GlobalKey<ScaffoldState>();
    });
  }

  void _deleteVideoCache() async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
        context,
        'Remove video cache?',
        'If you want to free up space, you can clear this cache and download again sometime later.',
        _deleteVideoCacheConfirmed,
        null,
        false,
        null);
  }

  _deleteVideoCacheConfirmed() async {
    for (CircleObject circleObject in _selectedObjects) {
      if (circleObject.video != null) {
        circleObject.video!.streamableCached = false;

        _circleVideoBloc.deleteCache(circleObject.userFurnace!.userid!,
            circleObject.userCircleCache!.circlePath!, circleObject);
      }
    }

    setState(() {
      _selectedObjects.clear();
      _toggleIcons = false;
    });
  }

  // _cacheToFileForDesktop(List<CircleObject> selectedObjects) async {
  //
  //   for(CircleObject circleObject in selectedObjects){
  //     if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
  //       if (circleObject.video!.streamable! &&
  //           !circleObject.video!.streamableCached) {
  //         ///streamable, but not cached
  //          continue;
  //       } else if (circleObject.video!.streamable! &&
  //           circleObject.video!.streamableCached) {
  //         ///streamable and cached, proceed with unencrypted file
  //         continue;
  //       }else  {
  //         String filePath = await FileSystemService.returnTempPathAndImageFile();
  //
  //         File? file = await FileUtil.writeBytesToFile(
  //             filePath, circleObject.video!.videoBytes!);
  //
  //
  //       }
  //     } else  if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
  //
  //     } else  if (circleObject.type == CircleObjectType.CIRCLEFILE) {
  //
  //     }
  //
  //     ///don't need to check other types
  //   }
  //
  //   String filePath = await FileSystemService.returnTempPathAndImageFile();
  //   File? image = await FileUtil.writeBytesToFile(
  //       filePath, _preview.object!.image!.imageBytes!);
  //
  //   if (image == null) {
  //     return;
  //   } else {
  //     _preview.file = image;
  //     _preview.object = null;
  //   }
  // }

  _shareObjects() {
    if (globalState.isDesktop()) {
      // _cacheToFileForDesktop(_selectedObjects);
      ShareCircleObjects.shareToDestination(context, _selectedObjects, true);
    } else {
      DialogMultiShareTo.shareToPopup(
          context, _selectedObjects, ShareCircleObjects.shareToDestination);
    }
  }

  _downloadObjects() async {
    await DialogDownload.showAndDownloadCircleObjects(
      context,
      AppLocalizations.of(context)!.downloadFiles,
      _selectedObjects,
    );

    if (mounted) {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.downloadDone,
          AppLocalizations.of(context)!.downloadDoneStatement,
          false);
    }
  }

  void _showShareAndCache(CircleObject selected) {
    bool needCache = false;
    bool showWarning = false;
    bool onlyVideo = true;

    for (var circleObject in _selectedObjects) {
      _showShare = circleObject.canShare(
          circleObject.userFurnace!.userid!, circleObject.circle!);

      if (_showShare) {
        if (circleObject.video != null) {
          if (circleObject.video!.streamable! &&
              !circleObject.video!.streamableCached) {
            needCache = true;
            if (circleObject.seed == selected.seed) {
              showWarning = true;
            }
            //break;
          } else if (circleObject.video!.videoState !=
                  VideoStateIC.VIDEO_READY &&
              circleObject.video!.videoState != VideoStateIC.NEEDS_CHEWIE &&
              circleObject.circle!.id! != DeviceOnlyCircle.circleID) {
            needCache = true;
            if (circleObject.seed == selected.seed) {
              showWarning = true;
            }
            //break;
          } else {
            _showClearCache = true;
          }
        } else {
          onlyVideo = false;
        }
      }
    }

    if (needCache) {
      _selectedObjects.remove(selected);
      if (showWarning) {
        _showNeedToCacheSnackbar();
      }

      _showShare = false;
      _showClearCache = false;
    }

    if (!onlyVideo) {
      _showClearCache = false;
    }
  }

  void _downloadVideo(CircleObject circleObject) {
    setState(() {
      circleObject.retries = 0;
    });

    _circleVideoBloc.downloadVideo(
        circleObject.userFurnace!, circleObject.userCircleCache!, circleObject);

    //circleObject.circle = await TableCircleCache.read(circleObject.circle!.id!);
  }

  _showNeedToCacheSnackbar() {
    FormattedSnackBar.showSnackbarWithContext(
        context, AppLocalizations.of(context)!.needToCacheVideo, '', 2, false);
  }

  void _openAlbum(CircleObject circleObject) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CircleAlbumScreen(
                  deviceOnly:
                      circleObject.circle!.id == DeviceOnlyCircle.circleID,
                  circleObject: circleObject,
                  userCircleCache: circleObject.userCircleCache!,
                  userFurnace: circleObject.userFurnace!,
                  circleAlbumBloc: _circleAlbumBloc,
                  circleObjectBloc: widget.circleObjectBloc,
                  globalEventBloc: _globalEventBloc,
                  fullScreenSwiperCaller:
                      widget.mode == 'vault' || widget.slideUpPanel == true
                          ? FullScreenSwiperCaller.circle
                          : FullScreenSwiperCaller.library,
                  circleVideoBloc: _circleVideoBloc,
                  circleImageBloc: _circleImageBloc,
                  downloadVideo: _albumDownloadVideo,
                  interactive: true,
                )));
  }

  void _albumDownloadVideo(AlbumItem item, CircleObject object) {
    setState(() {
      object.retries = 0;
      item.retries = 0;
    });
    _circleVideoBloc.downloadAlbumVideo(
        widget.userFurnace!, widget.userCircleCache!, object, item);
  }
}
