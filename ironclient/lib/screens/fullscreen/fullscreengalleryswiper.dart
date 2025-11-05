import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:media_kit/media_kit.dart' as mediakit;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

enum FullScreenSwiperCaller { library, circle, feed, vault }

class FullScreenGallerySwiper extends StatefulWidget {
  const FullScreenGallerySwiper(
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
      this.delete,
      required this.albumDownloadVideo,
      required this.circleAlbumBloc,
      this.userCircleCache,
      required this.fullScreenSwiperCaller,
      this.initialScale,
      this.userCircleCaches = const [],
      this.userFurnaces = const [],
      this.libraryObjects,
      this.basePosition = Alignment.center,
      this.albumIndex});

  final bool isSelecting;
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
  final FullScreenSwiperCaller fullScreenSwiperCaller;
  final List<UserCircleCache> userCircleCaches;
  final List<UserFurnace> userFurnaces;
  final Function? delete;
  final Function albumDownloadVideo;
  final CircleAlbumBloc circleAlbumBloc;
  final UserCircleCache? userCircleCache;
  final int? albumIndex;

  @override
  _FullScreenGallerySwiperState createState() =>
      _FullScreenGallerySwiperState();
}

class GalleryObject {
  final CircleObject circleObject;
  final AlbumItem? albumItem;
  final int albumIndex;

  GalleryObject(
      {required this.circleObject, this.albumItem, this.albumIndex = -1});
}

class _FullScreenGallerySwiperState extends State<FullScreenGallerySwiper> {
  late CircleObjectBloc _circleObjectBloc;
  late CircleVideoBloc _circleVideoBloc;
  List<GalleryObject> _galleryObjects = [];
  CircleObject? _lastVideoPlayed;
  final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();
  final VideoControllerDesktopBloc _videoControllerDesktopBloc =
      VideoControllerDesktopBloc();
  PageController pageController =
      PageController(initialPage: -1, viewportFraction: 100);
  late TransformationController _transformationController;

  //int _initialIndex = -1;
  bool justLoadedSwiper = true;
  int _currentIndex = -1;
  bool _loading = false;
  bool _hiResAvailable = false;
  bool _showThumbnail = false;
  String currentDeleting = "";
  bool _decryptingImage = false;

  AlbumItem? currentAlbumItem;

  AlbumItem? _lastItemVideoPlayed;

  // int albumIndex = -1;

  Circle? _currentCircle;
  String appBarTitle = '';

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  //CircleObject? circleObject;
  //ImageProvider? _imageProvider;

  @override
  void dispose() {
    widget.circleAlbumBloc.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoControllerBloc.disposeLast();
      _videoControllerDesktopBloc.disposeLast();
    });

    super.dispose();
  }

  @override
  void initState() {
    _currentCircle = widget.circle;
    _transformationController = TransformationController();
    widget.globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    widget.globalEventBloc.deletedObject.listen((CircleObject object) {
      if (object.id != currentDeleting) {
        if (mounted) {
          setState(() {
            _galleryObjects
                .removeWhere((element) => element.circleObject.id == object.id);
          });
          if (_galleryObjects.length == 1) {
            _currentIndex = 0;
            pageController.jumpToPage(0);
          } else if (_galleryObjects.isEmpty) {
            Navigator.pop(context);
          } else {
            _currentIndex = _currentIndex - 1;

            if (_currentIndex < 0) _currentIndex = 0;

            pageController.jumpToPage(_currentIndex - 1);
          }
        }
        currentDeleting = object.id!;
      }
    }, onError: (err) {
      debugPrint("FullScreenGallerySwiper.deletedObject.listen: $err");
    }, cancelOnError: false);

    _circleObjectBloc =
        CircleObjectBloc(globalEventBloc: widget.globalEventBloc);
    _circleVideoBloc = CircleVideoBloc(widget.globalEventBloc);

    _circleVideoBloc.streamItemAvailable.listen((albumItem) async {
      if (mounted) {
        try {
          CircleObject? album = _findAlbumObject(albumItem);
          if (album != null) {
            int index = album.album!.media
                .indexWhere((param) => param.id == albumItem.id);

            await _disposeControllers();
            await _videoControllerBloc.addItem(album.album!.media[index]);

            _lastItemVideoPlayed = album.album!.media[index];

            setState(() {
              albumItem.video!.videoState = VideoStateIC.VIDEO_READY;
            });
          }

          _loading = false;
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('InsideCircle.streamAvailable.listen: $err');
        }
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    _circleVideoBloc.itemAutoPlayReady.listen((item) async {
      if (mounted) {
        try {
          CircleObject? album = _findAlbumObject(item);
          if (album != null) {
            if (item.video!.streamable != null &&
                item.video!.streamable! &&
                item.video!.streamableCached == false) {
              _streamItemVideo(item, album);
            } else {
              _playItemVideo(item, album);
            }
          }
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint("CircleAlbumScreen.streamAvailable.listen: $error");
        }
      }
    }, onError: (error) {
      _clearSpinner();
      debugPrint("CircleAlbumScreen.listen: $error");
    }, cancelOnError: false);

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
          int index = _galleryObjects.indexWhere(
              (param) => param.circleObject.seed == circleObject.seed);

          await _disposeControllers();

          if (globalState.isDesktop()) {
            await _videoControllerDesktopBloc
                .add(_galleryObjects[index].circleObject);
          } else {
            await _videoControllerBloc.add(_galleryObjects[index].circleObject);
          }

          _lastVideoPlayed = _galleryObjects[index].circleObject;

          setState(() {
            circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
          });

          if (globalState.isDesktop()) {
            mediakit.Player? videoPlayer = _videoControllerDesktopBloc
                .fetchPlayer(_galleryObjects[index].circleObject);

            if (videoPlayer != null) {
              if (circleObject.video!.streamable == true ||
                  circleObject.video!.streamableCached == false) {
                await videoPlayer.open(mediakit.Media(
                    await _videoControllerDesktopBloc
                        .fetchVideoPath(circleObject)));
              } else {
                final mediakit.Media media = await mediakit.Media.memory(
                    circleObject.video!.videoBytes!);

                await videoPlayer.open(media);
              }

              setState(() {});
            }
          }

          _loading = false;
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
      if (mounted) {
        if (_currentIndex != 1 &&
            circleObject.id == _galleryObjects[_currentIndex].circleObject.id) {
          if (ImageCacheService.isThumbnailCached(circleObject,
              circleObject.userCircleCache!.circlePath!, circleObject.seed!)) {
            if (mounted)
              setState(() {
                _loading = false;
                _showThumbnail = true;
              });
          }
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
          if (_galleryObjects.isNotEmpty &&
              _currentIndex != -1 &&
              _galleryObjects.length > _currentIndex) {
            //_galleryObjects[_circleObjecIndex].transferPercent =
            //   circleObject.transferPercent;

            if (circleObject.id ==
                _galleryObjects[_currentIndex].circleObject.id) {
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

    ///listener for user deleting media
    widget.circleAlbumBloc.mediaDeleted.listen((media) {
      if (mounted) {
        CircleObject? album = _findAlbumObject(media[0]);
        if (album != null) {
          for (AlbumItem item in media) {
            album.album?.media.remove(item);
          }
        }
        setState(() {
          if (_galleryObjects.length == 1) {
            pageController.jumpToPage(0);
          } else if (_galleryObjects.isEmpty) {
            Navigator.pop(context);
          } else {
            pageController.jumpToPage(_currentIndex - 1);
          }
        });
      }
    });

    widget.globalEventBloc.itemProgressIndicator.listen((item) {
      if (mounted) {
        try {
          setState(() {
            if (item.type == AlbumItemType.VIDEO) {
              CircleObject? album = _findAlbumObject(item);
              if (album != null) {
                ProcessCircleObjectEvents.putAlbumVideo(
                    album, item, _circleVideoBloc);
              }
              // ProcessCircleObjectEvents.putAlbumVideo(
              //     widget.circleObject, item, _circleVideoBloc);

              // if (circleObject.transferPercent == 100) {
              //   _circleObjectBloc.sinkVaultRefresh();
              // }
            }
          });
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint(
              'FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $error');
        }
      }
    }, onError: (err) {
      _clearSpinner();
      debugPrint(
          "FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $err");
    }, cancelOnError: false);

    //Listen for the carousel load
    _circleObjectBloc.imageCarousel.listen((images) {
      if (mounted) {
        if (images == null) return;

        for (CircleObject obj in images) {
          obj.userCircleCache ??= widget.userCircleCache;

          if (obj.type == CircleObjectType.CIRCLEALBUM &&
              obj.album!.media.isNotEmpty) {
            List<AlbumItem> validItems = List.from(obj.album!.media);
            _scrubItems(validItems);
            int albumIndex = 0;

            ///dont know how to enforce sort considering way of iterating right now.
            for (AlbumItem item in validItems) {
              _galleryObjects.add(
                  GalleryObject(circleObject: obj, albumIndex: albumIndex));
              albumIndex = albumIndex + 1;
            }
          } else {
            _galleryObjects.add(GalleryObject(circleObject: obj));
          }
        }
        _scrubNotReady(_galleryObjects);

        if (widget.circleObject != null &&
            widget.circleObject!.type == CircleObjectType.CIRCLEALBUM) {
          _currentIndex = _galleryObjects.indexWhere((galleryObject) =>
              galleryObject.circleObject.seed == widget.circleObject!.seed &&
              galleryObject.albumIndex == widget.albumIndex);

          setAppBarTitle(_galleryObjects[_currentIndex].albumIndex);
        } else {
          _currentIndex = _galleryObjects.indexWhere((galleryObject) =>
              galleryObject.circleObject.seed == widget.circleObject!.seed);
        }

        setState(() {
          pageController = PageController(
            initialPage: _currentIndex,
          );
        });
      }
    }, onError: (err) {
      //TODO tell the user they are looking at the thumbnail
      debugPrint("error $err");
    }, cancelOnError: false);

    /*//Listen for the carousel load
    _circleObjectBloc.imageCarouselMore.listen((images) {
      if (mounted) {
        if (images == null) return;
        _scrubNotReady(images);
        _galleryObjects.addAll(images);

        ///sort the images
        _galleryObjects.sort((a, b) => a.lastUpdate!.compareTo(b.lastUpdate!));
      }
    }, onError: (err) {
      //TODO tell the user they are looking at the thumbnail
      debugPrint("error $err");
    }, cancelOnError: false);
     */

    if (widget.libraryObjects != null) {
      if (globalState.isDesktop()) {
        widget.libraryObjects?.removeWhere(
            (element) => element.type == CircleObjectType.CIRCLEALBUM);
      }

      for (CircleObject obj in widget.libraryObjects!) {
        if (obj.type == CircleObjectType.CIRCLEALBUM &&
            obj.album!.media.isNotEmpty) {
          List<AlbumItem> validItems = List.from(obj.album!.media);
          _scrubItems(validItems);

          int albumIndex = 0;

          ///dont know how to enforce sort considering way of iterating right now.
          for (AlbumItem item in validItems) {
            _galleryObjects
                .add(GalleryObject(circleObject: obj, albumIndex: albumIndex));
            albumIndex == albumIndex + 1;
          }
        } else {
          _galleryObjects.add(GalleryObject(circleObject: obj));
        }
      }
      _scrubNotReady(_galleryObjects);

      _currentIndex = _galleryObjects.indexWhere((galleryObject) =>
          galleryObject.circleObject.seed == widget.circleObject!.seed);

      pageController = PageController(
        initialPage: _currentIndex,
      );
    } else {
      if (widget.fullScreenSwiperCaller == FullScreenSwiperCaller.circle) {
        ///request the images
        _circleObjectBloc.sinkImageCarouselForCircle(
          widget.circleObject!,
        );
      } else if (widget.fullScreenSwiperCaller == FullScreenSwiperCaller.feed) {
        ///request the images
        _circleObjectBloc.sinkImageCarouselForFeed(
          widget.userFurnaces,
          widget.userCircleCaches,
          widget.circleObject!,
        );
      }
    }
    super.initState();
  }

  void setAppBarTitle(int index) {
    appBarTitle =
        "${index + 1}/${_galleryObjects[_currentIndex].circleObject.album!.media.length}";
  }

  void _scrubItems(List<AlbumItem> scrubThese) {
    scrubThese.removeWhere((element) => element.removeFromCache == true);

    //remove streaming videos that aren't ready
    scrubThese.removeWhere((element) => (element.video != null &&
        element.video!.streamable == true &&
        element.video!.videoState! != VideoStateIC.NEEDS_CHEWIE &&
        element.video!.videoState! != VideoStateIC.BUFFERING &&
        element.video!.videoState! != VideoStateIC.VIDEO_READY &&
        element.video!.videoState! != VideoStateIC.PREVIEW_DOWNLOADED &&
        element.video!.videoState! != VideoStateIC.VIDEO_UPLOADED &&
        element.video!.videoState! != VideoStateIC.VIDEO_DOWNLOADED));

    //remove e2ee videos that haven't been downloaded
    scrubThese.removeWhere((element) => (element.video != null &&
        element.video!.streamable == false &&
        (element.video!.videoState! != VideoStateIC.NEEDS_CHEWIE) &&
        element.video!.videoState! != VideoStateIC.VIDEO_READY &&
        element.video!.videoState! != VideoStateIC.VIDEO_DOWNLOADED &&
        element.video!.videoState! != VideoStateIC.VIDEO_UPLOADED &&
        element.fullTransferState != BlobState.READY));
  }

  void _scrubNotReady(List<GalleryObject> scrubThese) {
    //remove streaming videos that aren't ready
    scrubThese.removeWhere((element) => (element.circleObject.video != null &&
        element.circleObject.video!.streamable == true &&
        //element.video!.videoState! != VideoStateIC.UNKNOWN &&
        element.circleObject.video!.videoState! != VideoStateIC.NEEDS_CHEWIE &&
        element.circleObject.video!.videoState! != VideoStateIC.BUFFERING &&
        element.circleObject.video!.videoState! != VideoStateIC.VIDEO_READY &&
        element.circleObject.video!.videoState! !=
            VideoStateIC.PREVIEW_DOWNLOADED &&
        element.circleObject.video!.videoState! !=
            VideoStateIC.VIDEO_UPLOADED &&
        element.circleObject.video!.videoState! !=
            VideoStateIC.VIDEO_DOWNLOADED));

    //remove e2ee videos that haven't been downloaded
    scrubThese.removeWhere((element) => (element.circleObject.video != null &&
        element.circleObject.video!.streamable == false &&
        (element.circleObject.video!.videoState! !=
            VideoStateIC.NEEDS_CHEWIE) &&
        element.circleObject.video!.videoState! != VideoStateIC.VIDEO_READY &&
        element.circleObject.video!.videoState! !=
            VideoStateIC.VIDEO_DOWNLOADED &&
        element.circleObject.video!.videoState! !=
            VideoStateIC.VIDEO_UPLOADED &&
        element.circleObject.fullTransferState != BlobState.READY));
  }

  bool isCached(CircleObject circleObject) {
    bool cached = VideoCacheService.isVideoCached(
        circleObject, circleObject.userCircleCache!.circlePath!);

    if (!cached) {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.videoMustBeCachedTitle,
          AppLocalizations.of(context)!.videoMustBeCachedMessage1,
          false);
      return false;
    }
    return true;
  }

  ImageProvider? _imageProvider;
  ChewieController? controller;
  VideoController? controllerMediaKit;

  bool isItemCached(AlbumItem item, CircleObject circleObject) {
    bool cached = VideoCacheService.isAlbumVideoCached(
        circleObject, widget.userCircleCache!.circlePath!, item);

    if (!cached) {
      DialogNotice.showNoticeOptionalLines(
          context,
          AppLocalizations.of(context)!.videoMustBeCachedTitle,
          AppLocalizations.of(context)!.videoMustBeCachedMessage1,
          false);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    //var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    var width = MediaQuery.of(context).size.width;

    if (globalState.isDesktop() && _galleryObjects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepDesktopObject(_galleryObjects[_currentIndex].circleObject);
      });
    }

    var _shareIcon = _galleryObjects.isNotEmpty
        ? !_showSpinner
            ? IconButton(
                onPressed: () {
                  if (_galleryObjects[_currentIndex].albumIndex != -1) {
                    _shareItem(
                        _galleryObjects[_currentIndex].circleObject,
                        _galleryObjects[_currentIndex]
                            .circleObject
                            .album!
                            .media[_galleryObjects[_currentIndex].albumIndex]);
                  } else {
                    _share(_galleryObjects[_currentIndex].circleObject);
                  }
                },
                icon: Icon(
                  Icons.share,
                  color: globalState.theme.button,
                ),
              )
            : Container()
        : Container();

    var _downloadIcon = _galleryObjects.isNotEmpty
        ? IconButton(
            onPressed: () {
              if (_galleryObjects[_currentIndex].albumIndex != -1) {
                _downloadItem(
                    _galleryObjects[_currentIndex].circleObject,
                    _galleryObjects[_currentIndex]
                        .circleObject
                        .album!
                        .media[_galleryObjects[_currentIndex].albumIndex]);
              } else {
                _download(_galleryObjects[_currentIndex].circleObject);
              }
            },
            icon: Icon(
              Icons.download,
              color: globalState.theme.button,
            ),
          )
        : Container();

    exists() {
      bool retValue = _galleryObjects.isNotEmpty &&
          _currentIndex != -1 &&
          _galleryObjects.length > _currentIndex;

      return retValue;
    }

    var _deleteIcon = widget.delete != null &&
            _galleryObjects.isNotEmpty &&
            _currentIndex != -1 &&
            _galleryObjects[_currentIndex].circleObject.type !=
                CircleObjectType.CIRCLEALBUM
        ? IconButton(
            onPressed: () {
              widget.delete!(_galleryObjects[_currentIndex].circleObject);
            },
            icon: Icon(
              Icons.delete,
              color: globalState.theme.button,
            ),
          )
        : Container();

    var appBarWidget = PreferredSize(
        preferredSize: const Size.fromHeight(37.0),
        child: AppBar(
            title: Text(appBarTitle,
                style: TextStyle(
                  color: globalState.theme.menuIcons,
                )),
            elevation: 0,
            toolbarHeight: 45,
            centerTitle: false,
            titleSpacing: 0.0,
            iconTheme: IconThemeData(
              color: globalState.theme.menuIcons,
            ),
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            actions: _currentCircle == null
                ? null
                : widget.fullScreenSwiperCaller == FullScreenSwiperCaller.vault
                    ? Platform.isAndroid && !widget.isSelecting
                        ? [_deleteIcon, _downloadIcon, _shareIcon]
                        : Platform.isIOS && !widget.isSelecting
                            ? [_deleteIcon, _shareIcon]
                            : [_deleteIcon]
                    : (_currentCircle!.privacyShareImage == true ||
                                _currentCircle!.id! ==
                                    DeviceOnlyCircle.circleID) &&
                            !widget.circleObject!.oneTimeView &&
                            !widget.isSelecting &&
                            Platform.isAndroid
                        ? [_deleteIcon, _downloadIcon, _shareIcon]
                        : (_currentCircle!.privacyShareImage == true ||
                                    _currentCircle!.id! ==
                                        DeviceOnlyCircle.circleID) &&
                                !widget.circleObject!.oneTimeView &&
                                !widget.isSelecting &&
                                Platform.isIOS
                            ? [_deleteIcon, _shareIcon]
                            : [_deleteIcon]));

    final desktop = PopScope(
        canPop: false,
        child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.black, //globalState.theme.background,
            body: Stack(children: [
              _galleryObjects.isEmpty || _currentIndex == -1
                  ? Container()
                  : _galleryObjects[_currentIndex].circleObject.type ==
                          CircleObjectType.CIRCLEVIDEO
                      ? controllerMediaKit == null ||
                              (_galleryObjects[_currentIndex]
                                          .circleObject
                                          .video!
                                          .videoBytes ==
                                      null &&
                                  _galleryObjects[_currentIndex]
                                          .circleObject
                                          .video!
                                          .streamable ==
                                      false)
                          ? Row(children: [
                              const Spacer(),
                              Center(child: spinkit),
                              const Spacer(),
                            ])
                          : SizedBox(
                              width: width,
                              child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                        child: Video(
                                            key: GlobalKey(),
                                            controller: controllerMediaKit!))
                                  ]))
                      : _galleryObjects[_currentIndex].circleObject.type ==
                              CircleObjectType.CIRCLEGIF
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: InteractiveViewer(
                                        transformationController:
                                            _transformationController,
                                        minScale: 0.1,
                                        maxScale: 5,
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              _galleryObjects[_currentIndex]
                                                  .circleObject
                                                  .gif!
                                                  .giphy!,
                                          fit: BoxFit.contain,
                                          errorWidget: (context, url, error) =>
                                              Container(),
                                        )))
                              ],
                            )
                          : _galleryObjects[_currentIndex].circleObject.type ==
                                  CircleObjectType.CIRCLEIMAGE
                              ? _galleryObjects[_currentIndex]
                                          .circleObject
                                          .image!
                                          .imageBytes ==
                                      null
                                  ? Row(children: [
                                      const Spacer(),
                                      Center(child: spinkit),
                                      const Spacer(),
                                    ])
                                  : Row(
                                      children: [
                                        Expanded(
                                            child: InteractiveViewer(
                                                transformationController:
                                                    _transformationController,
                                                minScale: 0.1,
                                                maxScale: 5,
                                                child: Image.memory(
                                                  _galleryObjects[_currentIndex]
                                                      .circleObject
                                                      .image!
                                                      .imageBytes!,
                                                  fit: BoxFit.contain,
                                                )))
                                      ],
                                    )
                              : Container(),
              SafeArea(
                  top: true,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [appBarWidget])),
              _galleryObjects.length > 1
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_left,
                          color: globalState.theme.button,
                          size: 45,
                        ),
                        onPressed: () {
                          ///figure out the index
                          if (_currentIndex != 0) {
                            _currentIndex = _currentIndex - 1;
                            _prepDesktopObject(
                                _galleryObjects[_currentIndex].circleObject,
                                indexJustChanged: true);
                          }
                        },
                      ))
                  : Container(),
              Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_right,
                      color: globalState.theme.button,
                      size: 45,
                    ),
                    onPressed: () {
                      ///figure out the index
                      if (_currentIndex != _galleryObjects.length - 1) {
                        _currentIndex = _currentIndex + 1;
                        _prepDesktopObject(
                            _galleryObjects[_currentIndex].circleObject,
                            indexJustChanged: true);
                      }
                    },
                  )),
            ])));

    return globalState.isDesktop()
        ? desktop
        : Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.black, //globalState.theme.background,
            body: Stack(children: [
              _galleryObjects.isEmpty
                  ? Container()
                  : PhotoViewGallery.builder(
                      backgroundDecoration:
                          const BoxDecoration(color: Colors.black),
                      itemCount: _galleryObjects.length,
                      enableRotation: false,
                      //reverse: true,
                      pageController: pageController,
                      builder: (context, index) {
                        debugPrint(
                            '*********BUILDER************************ $index ***************************');

                        ImageProvider? _imageProvider;
                        ChewieController? controller;
                        VideoController? controllerMediaKit;

                        CircleObject circleObject =
                            _galleryObjects[index].circleObject;

                        if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
                          AlbumItem item = circleObject
                              .album!.media[_galleryObjects[index].albumIndex];

                          if (item.type == AlbumItemType.VIDEO) {
                            if (justLoadedSwiper) {
                              justLoadedSwiper = false;
                              _playFirstVideo();
                            } else {
                              controller = _videoControllerBloc
                                  .fetchAlbumController(item);
                            }
                          } else {
                            _imageProvider =
                                _fetchItemImage(circleObject, item);
                            _showSpinner = false;
                          }

                          ///display!
                          if (item.type == AlbumItemType.IMAGE ||
                              item.type == AlbumItemType.GIF) {
                            return _imageProvider != null //&& !_loading
                                ? PhotoViewGalleryPageOptions(
                                    minScale:
                                        PhotoViewComputedScale.contained * 0.8,
                                    // Covered = the smallest possible size to fit the whole screen
                                    // maxScale:
                                    //   PhotoViewComputedScale.covered * 2,
                                    imageProvider: _imageProvider,
                                  )
                                : PhotoViewGalleryPageOptions(
                                    maxScale: 0.5,
                                    imageProvider: AssetImage(
                                        globalState.theme.themeMode ==
                                                ICThemeMode.dark
                                            ? 'assets/images/black.jpg'
                                            : 'assets/images/white.jpg'),
                                  );
                          } else {
                            return PhotoViewGalleryPageOptions.customChild(
                              child: controller == null
                                  ? Row(children: [
                                      const Spacer(),
                                      Center(child: spinkit),
                                      const Spacer(),
                                    ])
                                  : Row(
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
                                                )),
                                          ),
                                        ]),
                            );
                          }
                        } else {
                          if (circleObject.type ==
                              CircleObjectType.CIRCLEVIDEO) {
                            if (justLoadedSwiper) {
                              justLoadedSwiper = false;
                              _playFirstVideo();
                            } else
                              controller = _videoControllerBloc
                                  .fetchController(circleObject);
                          } else {
                            _imageProvider = _fetchImage(circleObject);
                          }

                          ///display!
                          if (circleObject.type ==
                                  CircleObjectType.CIRCLEIMAGE ||
                              circleObject.type == CircleObjectType.CIRCLEGIF) {
                            return _imageProvider != null && !_loading
                                ? PhotoViewGalleryPageOptions(
                                    minScale:
                                        PhotoViewComputedScale.contained * 0.8,
                                    // Covered = the smallest possible size to fit the whole screen
                                    // maxScale:
                                    //   PhotoViewComputedScale.covered * 2,
                                    imageProvider: _imageProvider,
                                  )
                                : PhotoViewGalleryPageOptions(
                                    maxScale: 0.5,
                                    imageProvider: AssetImage(
                                        globalState.theme.themeMode ==
                                                ICThemeMode.dark
                                            ? 'assets/images/black.jpg'
                                            : 'assets/images/white.jpg'),
                                  );
                          } else {
                            return PhotoViewGalleryPageOptions.customChild(
                              child: controller == null
                                  ? Row(children: [
                                      const Spacer(),
                                      Center(child: spinkit),
                                      const Spacer(),
                                    ])
                                  : Row(
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
                                                )),
                                          ),
                                        ]),
                            );
                          }
                        }
                      },
                      onPageChanged: (int index) {
                        debugPrint(
                            '******************onPageChanged*************** $index ***************************');

                        CircleObject circleObject =
                            _galleryObjects[index].circleObject;

                        _currentIndex = index;

                        if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
                          currentAlbumItem = circleObject
                              .album!.media[_galleryObjects[index].albumIndex];
                          // int indexStart = _galleryObjects.indexOf(circleObject);
                          // int indexEnd = _galleryObjects.lastIndexOf(circleObject);
                          //
                          // if (index > _currentIndex) {
                          //   ///swipe right:
                          //   if (index == indexStart &&
                          //       _currentIndex == indexStart - 1) {
                          //     ///into album
                          //     albumIndex = 0;
                          //   } else {
                          //     ///in album
                          //     albumIndex = albumIndex + 1;
                          //   }
                          // } else if (index < _currentIndex) {
                          //   ///swipe left:
                          //   if (index == indexEnd &&
                          //       _currentIndex == indexEnd + 1) {
                          //     ///into album
                          //     albumIndex = indexEnd - indexStart;
                          //   } else {
                          //     ///in album
                          //     albumIndex = albumIndex - 1;
                          //   }
                          // }

                          // _currentIndex = index;
                          // currentAlbumItems =
                          //     List.from(circleObject.album!.media);
                          // currentAlbumItems.retainWhere(
                          //     (element) => element.removeFromCache == false);
                          // _scrubItems(currentAlbumItems);
                          // currentAlbumItem = currentAlbumItems[albumIndex];

                          setState(() {
                            setAppBarTitle(_galleryObjects[index].albumIndex);
                          });

                          if (currentAlbumItem!.type == AlbumItemType.VIDEO) {
                            ChewieController? controller = _videoControllerBloc
                                .fetchAlbumController(currentAlbumItem!);

                            if (controller == null) {
                              if (currentAlbumItem!.video!.streamable! &&
                                  currentAlbumItem!.video!.streamableCached ==
                                      false)
                                _streamItemVideo(
                                    currentAlbumItem!, circleObject);
                              else
                                PopulateMedia.populateAlbumVideoFile(
                                    circleObject,
                                    currentAlbumItem!,
                                    circleObject.userFurnace,
                                    widget.userCircleCache != null
                                        ? widget.userCircleCache!
                                        : circleObject.userCircleCache!,
                                    _circleVideoBloc,
                                    _videoControllerBloc,
                                    broadcastAutoPlay: true);
                            }
                          } else {
                            //_disposeControllers();
                            //setState(() {
                            _hiResAvailable = false;
                            _showThumbnail = false;

                            if (widget.fullScreenSwiperCaller ==
                                    FullScreenSwiperCaller.library ||
                                widget.fullScreenSwiperCaller ==
                                    FullScreenSwiperCaller.feed) {
                              _currentCircle = circleObject.circle!;
                            }
                            // });
                          }
                        } else {
                          setState(() {
                            appBarTitle = '';
                          });

                          if (circleObject.type ==
                              CircleObjectType.CIRCLEVIDEO) {
                            if (globalState.isDesktop()) {
                              VideoController? controller =
                                  _videoControllerDesktopBloc
                                      .fetchController(circleObject);

                              if (controller == null) {
                                if (circleObject.video!.streamable! &&
                                    circleObject.video!.streamableCached ==
                                        false)
                                  _streamVideo(circleObject);
                                else
                                  PopulateMedia.populateVideoFile(
                                      circleObject,
                                      circleObject.userFurnace,
                                      circleObject.userCircleCache!,
                                      _circleVideoBloc,
                                      _videoControllerBloc,
                                      _videoControllerDesktopBloc,
                                      broadcastAutoPlay: true);
                              }
                            } else {
                              ChewieController? controller =
                                  _videoControllerBloc
                                      .fetchController(circleObject);

                              if (controller == null) {
                                if (circleObject.video!.streamable! &&
                                    circleObject.video!.streamableCached ==
                                        false)
                                  _streamVideo(circleObject);
                                else
                                  PopulateMedia.populateVideoFile(
                                      circleObject,
                                      circleObject.userFurnace,
                                      circleObject.userCircleCache!,
                                      _circleVideoBloc,
                                      _videoControllerBloc,
                                      _videoControllerDesktopBloc,
                                      broadcastAutoPlay: true);
                              }
                            }
                          } else {
                            _disposeControllers();
                            //setState(() {
                            _hiResAvailable = false;
                            _showThumbnail = false;

                            if (_currentIndex != -1 &&
                                    widget.fullScreenSwiperCaller ==
                                        FullScreenSwiperCaller.library ||
                                widget.fullScreenSwiperCaller ==
                                    FullScreenSwiperCaller.feed) {
                              _currentCircle = _galleryObjects[_currentIndex]
                                  .circleObject
                                  .circle;
                            }
                            // });
                          }
                        }
                      }),
              /*_hiResAvailable && _showThumbnail
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
            : Container()*/
              SafeArea(
                  top: true,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [appBarWidget]))
            ]),
          );
  }

  ImageProvider? _fetchItemImage(CircleObject obj, AlbumItem item) {
    ImageProvider? _imageProvider;

    if (item.type == AlbumItemType.GIF) {
      _imageProvider = Image.network(
        item.gif!.giphy!,
      ).image;
    } else {
      //old versions may not have a fullimage
      if (item.image!.fullImage == null) {
        if (ImageCacheService.isAlbumThumbnailCached(
          obj,
          item,
          widget.userCircleCache != null
              ? widget.userCircleCache!.circlePath!
              : obj.userCircleCache!.circlePath!,
        )) {
          String fullPath = ImageCacheService.returnExistingAlbumImagePath(
            widget.userCircleCache != null
                ? widget.userCircleCache!.circlePath!
                : obj.userCircleCache!.circlePath!,
            obj,
            item.image!.thumbnail!,
          );
          _imageProvider = Image.file(File(fullPath)).image;
          // String fullPath = ImageCacheService.returnAlbumThumbnailPath(
          //     widget.userCircleCache.,
          //     widget.circleObject.seed);
        } else {
          /*if (!_loading) {
          _circleObjectBloc.downloadCircleImageThumbnail(
              widget.userCircleCache, widget.userFurnace, circleObject);

          _loading = true;
        }*/
        }
      } else {
        if (!_showThumbnail &&
            ImageCacheService.isAlbumFullImageCached(
              obj,
              item,
              widget.userCircleCache != null
                  ? widget.userCircleCache!.circlePath!
                  : obj.userCircleCache!.circlePath!,
              obj.seed!,
            )) {
          //String fullPath = ImageCacheService.returnAlbumFullImagePath(widget.userCircleCache.circlePath!, widget.circleObject.seed!);
          String fullPath = ImageCacheService.returnExistingAlbumImagePath(
            widget.userCircleCache != null
                ? widget.userCircleCache!.circlePath!
                : obj.userCircleCache!.circlePath!,
            obj,
            item.image!.fullImage!,
          );

          _imageProvider = Image.file(File(fullPath)).image;
        } else {
          _showSpinner = true;

          //String thumbPath = ImageCacheService.returnAlbumThumbnailPath(widget.userCircleCache.circlePath!, widget.circleObject.seed!);
          String thumbPath = ImageCacheService.returnExistingAlbumImagePath(
            widget.userCircleCache != null
                ? widget.userCircleCache!.circlePath!
                : obj.userCircleCache!.circlePath!,
            obj,
            item.image!.thumbnail!,
          );

          if (ImageCacheService.isAlbumThumbnailCached(
            obj,
            item,
            widget.userCircleCache != null
                ? widget.userCircleCache!.circlePath!
                : obj.userCircleCache!.circlePath!,
          )) {
            _showThumbnail = true;
            return Image.file(File(thumbPath)).image;
          }

          // if (!widget.globalEventBloc.thumbnailExists(circleObject)) {
          //   widget.circleImageBloc.notifyWhenThumbReady(widget.userFurnace,
          //       circleObject.userCircleCache!, circleObject, _circleObjectBloc);
          //
          //   // setState(() {
          //   _loading = true;
          //
          //   //});
          // }
        }
      }
    }

    return _imageProvider;
  }

  ImageProvider? _fetchImage(CircleObject circleObject) {
    ImageProvider? _imageProvider;

    if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
      ///do nothing. to catch when going from image to album image to prevent errors.
    } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
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

  void _shareItem(CircleObject circleObject, AlbumItem albumItem) async {
    if (albumItem.type == AlbumItemType.VIDEO) {
      if (isItemCached(albumItem, circleObject) == false) return;
    }

    //make new circle object and attach album item to it, then send?
    CircleObject sendingObject = CircleObject(
      seed: circleObject.seed,
      creator: User(
        username: widget.userFurnace.username,
        id: widget.userFurnace.userid,
        accountType: widget.userFurnace.accountType,
      ),
      body: '',
      circle: widget.userCircleCache != null
          ? widget.userCircleCache!.cachedCircle!
          : circleObject.userCircleCache!.cachedCircle!,
      //sortIndex: index,
      ratchetIndexes: [],
      created: DateTime.now(),
      type: CircleObjectType.CIRCLEALBUM,
      /*circle: Circle(
          id: userCircleCache.circle,
        )*/
    );

    if (albumItem.type == AlbumItemType.IMAGE) {
      sendingObject.image = albumItem.image;
    } else if (albumItem.type == AlbumItemType.GIF) {
      // sendingObject.gif = albumItem.gif;
    } else if (albumItem.type == AlbumItemType.VIDEO) {
      sendingObject.video = albumItem.video;
    }

    DialogShareTo.shareToPopup(
        context,
        widget.userCircleCache != null
            ? widget.userCircleCache!
            : circleObject.userCircleCache!,
        sendingObject,
        ShareCircleObject.shareToDestination);
  }

  void _share(CircleObject circleObject) async {
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      if (isCached(circleObject) == false) return;
    }

    DialogShareTo.shareToPopup(context, circleObject.userCircleCache!,
        circleObject, ShareCircleObject.shareToDestination);
  }

  _downloadItem(
    CircleObject circleObject,
    AlbumItem albumItem,
  ) async {
    if (albumItem.type == AlbumItemType.VIDEO) {
      if (isItemCached(albumItem, circleObject) == false) return;
    }

    await DialogDownload.showAndDownloadAlbumItems(
        context,
        'Downloading',
        [albumItem],
        circleObject,
        widget.userCircleCache != null
            ? widget.userCircleCache!
            : circleObject.userCircleCache!);
  }

  _download(
    CircleObject circleObject,
  ) async {
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      if (isCached(circleObject) == false) return;
    }
    await DialogDownload.showAndDownloadCircleObjects(
      context,
      'Downloading',
      [circleObject],
    );
  }

  _clearSpinner() {
    _showSpinner = false;
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        _videoControllerBloc.pauseLast();
        _videoControllerDesktopBloc.pauseLast();
        checkStayOrGo();
        break;
      case AppLifecycleState.inactive:
        _videoControllerBloc.pauseLast();
        _videoControllerDesktopBloc.pauseLast();
        checkStayOrGo();
        break;
      case AppLifecycleState.resumed:
        // if (mounted) {
        //   setState(() {});
        // }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _playVideo(CircleObject circleObject) async {
    circleObject.video!.videoFile = File(VideoCacheService.returnVideoPath(
        circleObject,
        circleObject.userCircleCache!.circlePath!,
        circleObject.video!.extension!));

    if (globalState.isDesktop()) {
      _pauseControllers();
      await _videoControllerDesktopBloc.add(circleObject);
    } else {
      await _disposeControllers();
      await _videoControllerBloc.add(circleObject);
    }

    _lastVideoPlayed = circleObject;

    if (mounted) {
      setState(() {
        circleObject.video!.videoState = VideoStateIC.VIDEO_READY;
      });
    }

    if (globalState.isDesktop()) {
      mediakit.Player? videoPlayer =
          _videoControllerDesktopBloc.fetchPlayer(circleObject);

      if (videoPlayer != null) {
        String path =
            await _videoControllerDesktopBloc.fetchVideoPath(circleObject);
        if (circleObject.video!.streamable == true) {
          await videoPlayer.open(mediakit.Media(path));
        } else {
          if (circleObject.video!.videoBytes == null) {
            ///decrypt to memory if desktop

            circleObject.video!.videoBytes =
                await EncryptBlob.decryptBlobToMemory(DecryptArguments(
              encrypted: File(path),
              nonce: circleObject.video!.fullCrank!,
              mac: circleObject.video!.fullSignature!,
              key: circleObject.secretKey,
            ));

            widget.globalEventBloc
                .broadcastMemCacheCircleObjectsAdd([circleObject]);
          }

          final mediakit.Media media =
              await mediakit.Media.memory(circleObject.video!.videoBytes!);

          await videoPlayer.open(media);
        }

        setState(() {});
      }
    }

    _loading = false;
  }

  void _streamVideo(CircleObject circleObject) async {
    //await Future.delayed(const Duration(milliseconds: 100));

    late UserFurnace userFurnace;

    if (circleObject.userFurnace != null) {
      userFurnace = circleObject.userFurnace!;
    } else {
      userFurnace = widget.userFurnace;
    }
    _circleVideoBloc.getStreamingUrl(userFurnace, circleObject);
  }

  checkStayOrGo() {
    /*if ((widget.userCircleCache.hidden! || widget.userCircleCache.guarded!) &&
        _refreshEnabled) {
      _refreshEnabled = false;
      _goHome(true);
    }

     */
  }

  void _streamItemVideo(AlbumItem item, CircleObject circleObject) async {
    late UserFurnace userFurnace;

    if (circleObject.userFurnace != null) {
      userFurnace = circleObject.userFurnace!;
    } else {
      userFurnace = widget.userFurnace;
    }
    _circleVideoBloc.getAlbumStreamingUrl(userFurnace, circleObject, item);
  }

  _playFirstVideo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CircleObject circleObject = _galleryObjects[_currentIndex].circleObject;

      if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
        AlbumItem item = circleObject.album!.media[0];

          if (item.video!.streamable! && item.video!.streamableCached == false)
            _streamItemVideo(item, circleObject);
          else
            PopulateMedia.populateAlbumVideoFile(
                circleObject,
                item,
                circleObject.userFurnace,
                widget.userCircleCache != null
                    ? widget.userCircleCache!
                    : circleObject.userCircleCache!,
                _circleVideoBloc,
                _videoControllerBloc,
                broadcastAutoPlay: true);

      } else {
        if (circleObject.video == null) return;

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
              _videoControllerDesktopBloc,
              broadcastAutoPlay: true);
      }
    });
  }

  void _playItemVideo(AlbumItem item, CircleObject obj) async {
    item.video!.videoFile = File(VideoCacheService.returnExistingAlbumVideoPath(
        widget.userCircleCache != null
            ? widget.userCircleCache!.circlePath!
            : obj.userCircleCache!.circlePath!,
        obj,
        item.video!.video!));

    await _disposeControllers();

    await _videoControllerBloc.addItem(item);
    _lastItemVideoPlayed = item;

    if (mounted) {
      setState(() {
        item.video!.videoState = VideoStateIC.VIDEO_READY;
      });
    }

    _loading = false;
  }

  _disposeControllers() async {
    if (_lastVideoPlayed != null) {
      _videoControllerBloc.pauseLast();
      _videoControllerDesktopBloc.pauseLast();

      _videoControllerBloc.predispose(_lastVideoPlayed);
      _videoControllerDesktopBloc.predispose(_lastVideoPlayed);
      setState(() {
        _lastVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoControllerBloc.disposeObject(_lastVideoPlayed);
        _videoControllerDesktopBloc.disposeObject(_lastVideoPlayed);
      });
    }
    if (_lastItemVideoPlayed != null) {
      _videoControllerBloc.pauseLast();

      _videoControllerBloc.predisposeItem(_lastItemVideoPlayed);
      setState(() {
        _lastItemVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoControllerDesktopBloc.disposeObject(_lastVideoPlayed);
        _videoControllerBloc.disposeItem(_lastItemVideoPlayed);
      });
    }
  }

  _pauseControllers() async {
    if (_lastVideoPlayed != null) {
      _videoControllerBloc.pauseLast();
      _videoControllerDesktopBloc.pauseLast();
    }
  }

  _decryptImageForDesktopTop(CircleObject circleObject) async {
    Uint8List? _imageBytes = await EncryptBlob.decryptBlobToMemory(
        DecryptArguments(
            encrypted: File(ImageCacheService.returnFullImagePath(
                circleObject.userCircleCache!.circlePath!, circleObject)),
            nonce: circleObject.image!.fullCrank!,
            mac: circleObject.image!.fullSignature!,
            key: circleObject.secretKey));

    if (_imageBytes != null) {
      if (globalState.isDesktop()) {
        circleObject.image!.imageBytes = _imageBytes;
      } else {
        circleObject.imageProvider = MemoryImage(_imageBytes);
      }
      circleObject.decryptingImage = false;
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  _prepDesktopObject(CircleObject circleObject,
      {bool indexJustChanged = false}) {
    if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
      if (justLoadedSwiper) {
        justLoadedSwiper = false;
        _playFirstVideo();
      } else {
        controllerMediaKit =
            _videoControllerDesktopBloc.fetchController(circleObject);

        if (indexJustChanged) {
          VideoController? controller =
              _videoControllerDesktopBloc.fetchController(circleObject);

          if (controller == null) {
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
                  _videoControllerDesktopBloc,
                  broadcastAutoPlay: true);
          } else {
            if (mounted) setState(() {});
            controller.player.jump(0);
            controller.player.play();
          }
        }
      }
    } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
      if (indexJustChanged) {
        _pauseControllers();
      }

      if (circleObject.decryptingImage == false &&
          circleObject.image!.imageBytes == null) {
        circleObject.decryptingImage = true;
        _decryptImageForDesktopTop(circleObject);
      } else if (indexJustChanged) {
        if (mounted) setState(() {});
      }
    }

    // else {
    //   if (circleObject.image!.imageBytes != null) {
    //     ///already decrypted
    //     return;
    //   }
    //
    //   _imageProvider = _fetchImage(circleObject);
    // }
  }

  CircleObject? _findAlbumObject(AlbumItem item) {
    for (GalleryObject obj in _galleryObjects) {
      if (obj.circleObject.type == CircleObjectType.CIRCLEALBUM) {
        for (AlbumItem albumItem in obj.circleObject.album!.media) {
          if (albumItem.id == item.id) {
            return obj.circleObject;
          }
        }
      }
    }
    return null;
  }
}
