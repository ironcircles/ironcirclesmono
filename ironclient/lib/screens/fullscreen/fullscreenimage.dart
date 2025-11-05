import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullScreenImage extends StatefulWidget {
  const FullScreenImage(
      {this.imageProvider,
      required this.circleImageBloc,
      required this.globalEventBloc,
      required this.circleObject,
      //required this.userCircleCache,
      required this.userFurnace,
      required this.circle,
      this.isSelecting = false,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      this.fromLibrary = false,
      this.initialScale,
      this.libraryObjects,
      this.messageColor,
      this.basePosition = Alignment.center});

  final bool isSelecting;
  final bool fromLibrary;
  final Circle? circle;
  final ImageProvider? imageProvider;
  final Widget? loadingChild;
  final Decoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
  final Alignment basePosition;
  final CircleObject? circleObject;
  //final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final GlobalEventBloc globalEventBloc;
  final CircleImageBloc circleImageBloc;
  final List<CircleObject>? libraryObjects;
  final Color? messageColor;

  @override
  FullScreenImageState createState() => FullScreenImageState();
}

class FullScreenImageState extends State<FullScreenImage> {
  //ImageProvider _imageProvider;

  late CircleObjectBloc _circleObjectBloc;
  List<CircleObject> _images = [];

  late int _currentIndex;
  bool _loading = false;
  bool _showSpinner = false;
  //bool _imageLoaded = false;

  bool _hiResAvailable = false;
  bool _showThumbnail = false;

  PageController pageController = PageController(initialPage: -1);

  Circle? _currentCircle;
  //int _circleObjecIndex = 0;

  enableScreenshot(bool enable) async {
    if (Platform.isAndroid) {
      if (enable == false) {
        //await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        //await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  @override
  void initState() {
    _currentCircle = widget.circle;

    enableScreenshot(false);
    _circleObjectBloc =
        CircleObjectBloc(globalEventBloc: widget.globalEventBloc);

    widget.globalEventBloc.progressThumbnailIndicator.listen((circleObject) {
      if (circleObject.id == _images[_currentIndex].id) {
        if (ImageCacheService.isThumbnailCached(circleObject,
            circleObject.userCircleCache!.circlePath!, circleObject.seed!)) {
          if (mounted)
            setState(() {
              _loading = false;
              _showThumbnail = true;
            });
        }
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });

      debugPrint(
          "InsideCircle._globalEventBloc.progressIndicator.listen: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        try {
          if (_images.isNotEmpty) {
            //_images[_circleObjecIndex].transferPercent =
            //   circleObject.transferPercent;

            if (circleObject.id == _images[_currentIndex].id) {
              /* if (_loading) {
                if (ImageCacheService.isThumbnailCached(widget.circleObject,
                    widget.userCircleCache.circlePath!, circleObject.seed!)) {
                  setState(() {
                    _loading = false;
                  });
                }
              }*/

              if (circleObject.transferPercent == 100) {
                if (mounted)
                  setState(() {
                    //_imageLoaded = true;
                    _showSpinner = false;
                    _loading = false;
                    _hiResAvailable = true;
                  });
              } else {
                if (_showSpinner != true) {
                  if (mounted)
                    setState(() {
                      //if (_showSpinner == false) {
                      //only refresh on load    setState(() {
                      _showSpinner = true;
                    });
                }
              }

              // }
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'InsideCircle._globalEventBloc.progressIndicator.listen: $err');
        }
      }
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });

      debugPrint(
          "InsideCircle._globalEventBloc.progressIndicator.listen: $err");
    }, cancelOnError: false);

    /*bool cached = FileSystemService.isThumbnailCached(
          widget.userCircleCache.circlePath, widget.circleObject.seed);

      if (cached == false) {
        //request the object be cached
        //  _circleObjectBloc.downloadCircleImage(
        //     widget.userCircleCache, widget.userFurnace, widget.circleObject);
      }*/

    //Listen for the carousel load
    _circleObjectBloc.imageCarousel.listen((images) {
      if (mounted) {
        int index = images!.indexWhere(
            (circleObject) => circleObject.seed == widget.circleObject!.seed);

        setState(() {
          pageController = PageController(initialPage: index);

          _currentIndex = index;
          _images = images;

          if (widget.fromLibrary)
            _currentCircle = _images[_currentIndex].circle;
        });
      }
    }, onError: (err) {
      //_loading = false;
      //TODO tell the user they are looking at the thumbnail
      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.libraryObjects != null) {
      _images = widget.libraryObjects!;

      int index = _images.indexWhere(
          (circleObject) => circleObject.seed == widget.circleObject!.seed);

      pageController = PageController(initialPage: index);

      _currentIndex = index;

      if (widget.fromLibrary) _currentCircle = _images[_currentIndex].circle;
    } else
      //request the images
      _circleObjectBloc.sinkImageCarouselForCircle(
          widget.circleObject!);
    //  }
    super.initState();
  }

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  void _share(CircleObject circleObject) async {
    DialogShareTo.shareToPopup(context, circleObject.userCircleCache!,
        circleObject, ShareCircleObject.shareToDestination);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = globalState.setScaler(
        MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));
    double maxWidth = InsideConstants.getDisappearingMessagesWidth(screenWidth);

    var _downloadIcon = _images.isNotEmpty
        ? !_showSpinner
            ? FloatingActionButton(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30.0))),
                heroTag: "download",
                backgroundColor: globalState.theme.button,
                onPressed: () {
                  _download(_images[_currentIndex]);
                },
                child: Icon(
                  Icons.download,
                  color: globalState.theme.background,
                ),
              )
            : Container()
        : Container();

    var _shareIcon = _images.isNotEmpty
        ? !_showSpinner
            ? FloatingActionButton(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30.0))),
                heroTag: "share",
                backgroundColor: globalState.theme.button,
                onPressed: () {
                  _share(_images[_currentIndex]);
                },
                child: Icon(
                  Icons.share,
                  color: globalState.theme.background,
                ),
              )
            : Container()
        : Container();

    return Scaffold(
        /*appBar: AppBar(
          iconTheme: IconThemeData(
            color: globalState.theme.menuIcons, //change your color here
          ),
          //title: Text("Title"),
        ),

         */

        body: Stack(children: [
          SingleChildScrollView(
              child: Column(children: [
            Container(
                constraints: BoxConstraints.expand(
                  height: widget.circleObject!.body == ""
                      ? MediaQuery.of(context).size.height
                      : MediaQuery.of(context).size.height - 30,
                ),
                child: _images.isNotEmpty
                    ? Stack(
                        alignment: Alignment.bottomRight,
                        children: <Widget>[
                          PhotoViewGallery.builder(
                            backgroundDecoration: BoxDecoration(
                                color: globalState.theme.background),
                            itemCount: _images.length,
                            enableRotation: false,
                            pageController: pageController,
                            builder: (context, index) {
                              CircleObject circleObject = _images[index];
                              ImageProvider? _imageProvider =
                                  _fetchImage(circleObject);
                              return _imageProvider != null && !_loading
                                  ? PhotoViewGalleryPageOptions(
                                      minScale:
                                          PhotoViewComputedScale.contained *
                                              0.8,
                                      imageProvider: _imageProvider,
                                    )
                                  : PhotoViewGalleryPageOptions(
                                      maxScale: 0.5,
                                      imageProvider: AssetImage(
                                          globalState.theme.themeMode == ICThemeMode.dark
                                              ? 'assets/images/black.jpg'
                                              : 'assets/images/white.jpg'),
                                    );
                            },
                            loadingBuilder: (context, progress) =>
                                Center(child: spinkit),
                            onPageChanged: (int index) {
                              setState(() {
                                _currentIndex = index;
                                _showSpinner = false;
                                _hiResAvailable = false;
                                _showThumbnail = false;

                                if (widget.fromLibrary)
                                  _currentCircle =
                                      _images[_currentIndex].circle;
                              });
                            },
                          ),
                          _showSpinner
                              ? SpinKitThreeBounce(
                                  size: 12,
                                  color: globalState.theme.threeBounce,
                                )
                              : Container()
                        ],
                      )
                    : Center(child: spinkit)),
            widget.circleObject!.body == ""
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(
                        top: 10, left: 20, right: 20, bottom: 20),
                    child: SizedBox(
                        width: maxWidth,
                        child: Text(
                          widget.circleObject!.body!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: widget.messageColor),
                        )))
          ])),
          Align(
              alignment: Alignment.topLeft,
              child: Padding(
                  padding: const EdgeInsets.only(top: 45, left: 0),
                  child: FloatingActionButton(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(30.0))),
                      heroTag: "back",
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Icon(Icons.arrow_back,
                              size: 25, color: globalState.theme.menuIcons))))),
          _hiResAvailable && _showThumbnail
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: TextButton(
                        child: Text(
                          'hi-res',
                          style: TextStyle(color: globalState.theme.buttonIcon),
                        ),
                        onPressed: () {
                          setState(() {
                            _showThumbnail = false;
                            _hiResAvailable = false;
                            _showSpinner = false;
                          });
                        },
                      )))
              : Container()
        ]),
        floatingActionButton: Platform.isIOS
            ? _images.isEmpty
                ? Container()
                : _currentCircle == null
                    ? Container()
                    : (_currentCircle!.privacyShareImage == true ||
                                _currentCircle!.id! ==
                                    DeviceOnlyCircle.circleID) &&
                            !widget.circleObject!.oneTimeView &&
                            !widget.isSelecting
                        ? _shareIcon
                        : Container()
            : _images.isEmpty
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _currentCircle == null
                              ? Container()
                              : (_currentCircle!.privacyShareImage == true ||
                                          _currentCircle!.id! ==
                                              DeviceOnlyCircle.circleID) &&
                                      !widget.circleObject!.oneTimeView &&
                                      !widget.isSelecting
                                  ? _downloadIcon
                                  : Container(),
                          const Padding(
                            padding: EdgeInsets.only(left: 20),
                          ),
                          _currentCircle == null
                              ? Container()
                              : (_currentCircle!.privacyShareImage == true ||
                                          _currentCircle!.id! ==
                                              DeviceOnlyCircle.circleID) &&
                                      !widget.circleObject!.oneTimeView &&
                                      !widget.isSelecting
                                  ? _shareIcon
                                  : Container(),
                        ])));
  }

  ImageProvider? _fetchImage(CircleObject circleObject) {
    ImageProvider? _imageProvider;

    if (circleObject.type == CircleObjectType.CIRCLEGIF) {
      _imageProvider = Image.network(
        circleObject.gif!.giphy!,
      ).image;
    } else {
      //old versions may not have a fullimage
      if (circleObject.image!.fullImage == null) {
        if (ImageCacheService.isThumbnailCached(circleObject,
            circleObject.userCircleCache!.circlePath!, circleObject.seed!)) {
          String fullPath = ImageCacheService.returnThumbnailPath(
              circleObject.userCircleCache!.circlePath!, circleObject);

          _imageProvider = Image.file(File(fullPath)).image;
        } else {
          /*if (!_loading) {
          _circleObjectBloc.downloadCircleImageThumbnail(
              widget.userCircleCache, widget.userFurnace, circleObject);

          _loading = true;
        }*/
        }
      } else {
        if (!_showThumbnail &&
            ImageCacheService.isFullImageCached(
                circleObject,
                circleObject.userCircleCache!.circlePath!,
                circleObject.seed!)) {
          String fullPath = ImageCacheService.returnFullImagePath(
              circleObject.userCircleCache!.circlePath!, circleObject);

          _imageProvider = Image.file(File(fullPath)).image;
        } else {
          _showSpinner = true;

          String thumbPath = ImageCacheService.returnThumbnailPath(
              circleObject.userCircleCache!.circlePath!, circleObject);

          if (ImageCacheService.isThumbnailCached(circleObject,
              circleObject.userCircleCache!.circlePath!, circleObject.seed!)) {
            _showThumbnail = true;
            return Image.file(File(thumbPath)).image;
          }

          if (!widget.globalEventBloc.thumbnailExists(circleObject)) {
            widget.circleImageBloc.notifyWhenThumbReady(widget.userFurnace,
                circleObject.userCircleCache!, circleObject, _circleObjectBloc);

            // setState(() {
            _loading = true;

            //});
          }
        }
      }
    }

    return _imageProvider;
  }

/*
  _nextImage(){

    if (_timer) {
      setState(() {
        _showSpinner = false;
        _hiResAvailable = false;
        _showThumbnail = false;
      });
    }


  }

 */
  _download(
    CircleObject circleObject,
  ) async {
    /*await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Download(
                  circleObject: circleObject,
                  userCircleCache: circleObject.userCircleCache!,
                )));
                //.then(_circleObjectBloc.requestNewerThan(
     */

    await DialogDownload.showAndDownloadCircleObjects(
      context,
      'Downloading image',
      [circleObject],
    );
  }
}
