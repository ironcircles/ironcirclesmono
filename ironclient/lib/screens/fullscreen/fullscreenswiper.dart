/*import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:photo_view/photo_view.dart';

import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class FullScreenSwiper extends StatefulWidget {
  FullScreenSwiper(
      {this.imageProvider,
      required this.circleImageBloc,
      required this.globalEventBloc,
      required this.circleObject,
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
  final UserFurnace userFurnace;
  final GlobalEventBloc globalEventBloc;
  final CircleImageBloc circleImageBloc;
  final List<CircleObject>? libraryObjects;

  @override
  _FullScreenImageAndVideoSwiperState createState() =>
      _FullScreenImageAndVideoSwiperState();
}

class _FullScreenImageAndVideoSwiperState extends State<FullScreenSwiper> {
  late CircleObjectBloc _circleObjectBloc;
  late CircleVideoBloc _circleVideoBloc;
  List<CircleObject> _images = [];
  CircleObject? _lastVideoPlayed;
  VideoControllerBloc _videoControllerBloc = VideoControllerBloc();

  int _currentIndex = -1;
  bool _loading = false;
  bool _hiResAvailable = false;
  bool _showThumbnail = false;

  Circle? _currentCircle;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeLast();
    });

    super.dispose();
  }

  @override
  void initState() {
    _currentCircle = widget.circle;

    handleAppLifecycleState();

    _circleObjectBloc =
        CircleObjectBloc(globalEventBloc: widget.globalEventBloc);
    _circleVideoBloc = CircleVideoBloc(widget.globalEventBloc);

    _circleVideoBloc.autoPlayReady.listen((circleObject) async {
      if (mounted) {
        try {
          if (circleObject.video!.streamable != null &&
              circleObject.video!.streamable! &&
              circleObject.video!.streamableCached == false)
            _streamVideo(circleObject);
          else
            _playVideo(circleObject);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('InsideCircle.streamAvailable.listen: $err');
        }
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    _circleVideoBloc.streamAvailable.listen((circleObject) async {
      if (mounted) {
        try {
          _images[_currentIndex].video!.streamingUrl =
              circleObject.video!.streamingUrl;

          _images[_currentIndex].video!.videoState = VideoStateIC.VIDEO_READY;
          await _videoControllerBloc.add(_images[_currentIndex]);
          _lastVideoPlayed = circleObject;

          setState(() {
            _showSpinner = false;
            _loading = false;
          });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('InsideCircle.streamAvailable.listen: $err');
        }
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

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

    //Listen for the carousel load
    _circleObjectBloc.imageCarousel.listen((images) {
      if (mounted) {
        if (images == null) return;

        images.removeWhere((element) =>
            (element.video!.videoState! != VideoStateIC.NEEDS_CHEWIE &&
                element.video!.videoState! != VideoStateIC.VIDEO_READY &&
                element.video!.videoState! != VideoStateIC.BUFFERING &&
                element.video!.videoState! != VideoStateIC.VIDEO_UPLOADED));

        _images = images.reversed.toList();

        int index = _images.indexWhere(
            (circleObject) => circleObject.seed == widget.circleObject!.seed);

        setState(() {
          _currentIndex = index;

          //if (widget.fromLibrary)
            //_currentCircle = _images[_currentIndex].circle;
        });
      }
    }, onError: (err) {
      //TODO tell the user they are looking at the thumbnail
      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.libraryObjects != null) {
      _images = widget.libraryObjects!;

      _images = _images.reversed.toList();

      int index = _images.indexWhere(
          (circleObject) => circleObject.seed == widget.circleObject!.seed);

      _currentIndex = index;

       _currentCircle = _images[_currentIndex].circle;
    } else
      //request the images
      _circleObjectBloc.sinkImageCarousel(widget.circleObject!);
    //  }
    super.initState();
  }

  void _share(CircleObject circleObject) async {
    DialogShareTo.shareToPopup(context, circleObject.userCircleCache!,
        circleObject, ShareCircleObject.shareToDestination);
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    CircleObject? circleObject;
    ImageProvider? _imageProvider;
    ChewieController? controller;

    if (_currentIndex != -1) {
      circleObject = _images[_currentIndex];
      if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
        if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          controller = _videoControllerBloc.fetchController(circleObject);

          if (!_loading && controller == null) {
            _loading = true;

            if (circleObject.video!.streamable! &&
                circleObject.video!.streamableCached == false)
              _streamVideo(circleObject);
            else
              PopulateMedia.populateVideoFile(
                  circleObject,
                  circleObject.userFurnace,
                  circleObject.userCircleCache!,
                  _circleVideoBloc,
                  _videoControllerBloc,
                  broadcastAutoPlay: true);
          }
        }
      } else {
        _imageProvider = _fetchImage(circleObject);
      }
    }

    var _shareIcon = _images.isNotEmpty
        ? !_showSpinner
            ? IconButton(
                onPressed: () {
                  _share(_images[_currentIndex]);
                },
                icon: Icon(
                  Icons.share,
                  color: globalState.theme.button,
                ),
              )
            : Container()
        : Container();

    var _downloadIcon = _images.isNotEmpty
        ? IconButton(
            onPressed: () {
              _download(_images[_currentIndex]);
            },
            icon: Icon(
              Icons.download,
              color: globalState.theme.button,
            ),
          )
        : Container();

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(30.0), // here the desired height
          child: ICAppBar(
            title: '',
            actions: _currentCircle == null
                ? null
                : (_currentCircle!.privacyShareImage == true ||
                            _currentCircle!.id! == DeviceOnlyCircle.circleID) &&
                        !widget.circleObject!.oneTimeView &&
                        !widget.isSelecting &&
                        Platform.isAndroid
                    ? [_downloadIcon, _shareIcon]
                    : (_currentCircle!.privacyShareImage == true ||
                                _currentCircle!.id! ==
                                    DeviceOnlyCircle.circleID) &&
                            !widget.circleObject!.oneTimeView &&
                            !widget.isSelecting &&
                            Platform.isIOS
                        ? [_shareIcon]
                        : null,
          )),
      backgroundColor: globalState.theme.background,
      body: Stack(children: [
        GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) => _swipe(details),
            child: _images.length > 0
                ? Container(color: globalState.theme.background,
                    constraints: BoxConstraints.expand(
                      height: double.infinity,
                      width: double.infinity,
                    ),
                    child: Column(mainAxisSize: MainAxisSize.max, children: [
                      circleObject == null
                          ? Container()
                          : circleObject.type == CircleObjectType.CIRCLEIMAGE ||
                                  circleObject.type ==
                                      CircleObjectType.CIRCLEGIF
                              ? Expanded(
                                  child: PhotoView(
                                  imageProvider: _imageProvider,
                                  minScale:
                                      PhotoViewComputedScale.contained * 0.8,
                                  backgroundDecoration: BoxDecoration(
                                      color: globalState.theme.background),
                                ))
                              : controller == null
                                  ? Expanded(
                                      child: Row(children: [
                                      Expanded(child: Center(child: spinkit))
                                    ]))
                                  : Expanded(
                                      child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                          Expanded(
                                              child: AspectRatio(
                                                  aspectRatio: controller
                                                          .aspectRatio ??
                                                      controller
                                                          .videoPlayerController
                                                          .value
                                                          .aspectRatio,
                                                  child: Chewie(
                                                    controller: controller,
                                                  )))
                                        ])),
                    ]),
                  )
                : Center(child: spinkit)),
        _hiResAvailable && _showThumbnail
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: EdgeInsets.only(bottom: 25),
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
    );
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
              circleObject.userCircleCache!.circlePath!, circleObject.seed!);

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
              circleObject.userCircleCache!.circlePath!, circleObject.seed!);

          _imageProvider = Image.file(File(fullPath)).image;
        } else {
          _showSpinner = true;

          String thumbPath = ImageCacheService.returnThumbnailPath(
              circleObject.userCircleCache!.circlePath!, circleObject.seed!);

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

  _download(
    CircleObject circleObject,
  ) async {
    await DialogDownload.showAndDownloadCircleObjects(
      context,
      'Downloading',
      [circleObject],
    );
  }

  _clearSpinner() {
    _showSpinner = false;
  }

  handleAppLifecycleState() {
    AppLifecycleState _lastLifecyleState;
      //debugPrint('SystemChannels> $msg');

      switch (msg) {
        case "AppLifecycleState.paused":
          _lastLifecyleState = AppLifecycleState.paused;

          _videoControllerBloc.pauseLast();

          checkStayOrGo();
          break;
        case "AppLifecycleState.inactive":
          _lastLifecyleState = AppLifecycleState.inactive;
          _videoControllerBloc.pauseLast();

          checkStayOrGo();
          break;
        case "AppLifecycleState.resumed":
          _lastLifecyleState = AppLifecycleState.resumed;

          break;
        case "AppLifecycleState.suspending":
          checkStayOrGo();
          break;
        default:
      }
      return Future.value(null);
    });
  }

  void _playVideo(CircleObject circleObject) async {
    circleObject.video!.videoFile = File(VideoCacheService.returnVideoPath(
        circleObject.userCircleCache!.circlePath!,
        circleObject.seed!,
        circleObject.video!.extension!));

    await _videoControllerBloc.add(circleObject);
    _lastVideoPlayed = circleObject;

    setState(() {
      circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
    });
    _loading = false;
  }

  void _streamVideo(CircleObject circleObject) {
    //setState(() {
    //   circleObject.video!.videoState = VideoStateIC.BUFFERING;
    // });
    _circleVideoBloc.getStreamingUrl(widget.userFurnace, circleObject);
  }

  checkStayOrGo() {
    /*if ((widget.userCircleCache.hidden! || widget.userCircleCache.guarded!) &&
        _refreshEnabled) {
      _refreshEnabled = false;
      _goHome(true);
    }

     */
  }

  void _disposeControllers(CircleObject circleObject) {
    _predispose(circleObject);

    _videoControllerBloc.pauseLast();

    _videoControllerBloc.predispose(circleObject);
    setState(() {
      _lastVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeObject(circleObject);
    });

    _lastVideoPlayed = null;
  }

  void _predispose(CircleObject circleObject) {
    if (circleObject.video!.videoState == VideoStateIC.VIDEO_READY) {
      _videoControllerBloc.predispose(circleObject);
      setState(() {
        circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      });
    }
  }

  void _swipe(DragEndDetails details) {
    bool goNext = false;

    if (details.primaryVelocity == null) {
      return;
    }
    if (details.primaryVelocity! < 0) {
      if (_currentIndex != 0) {
        goNext = true;
        _currentIndex = _currentIndex - 1;
      }
    }

    if (details.primaryVelocity! > 0) {
      if (_currentIndex != _images.length - 1) {
        goNext = true;
        _currentIndex = _currentIndex + 1;
      }
    }

    if (goNext) {
      if (_lastVideoPlayed != null) {
        _videoControllerBloc.pauseLast();

        _videoControllerBloc.predispose(_lastVideoPlayed);
        setState(() {
          _lastVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _videoControllerBloc.disposeObject(_lastVideoPlayed);
        });
      } else {
        setState(() {});
      }
    }
  }
}

 */
