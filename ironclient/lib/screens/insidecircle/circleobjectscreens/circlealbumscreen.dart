import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_reorderable_grid_view/entities/order_update_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/circlealbum.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreengalleryswiper.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/imagepreviewer.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/selectgif.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogmultishareto.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/widgets/albumthumbnail.dart';
import 'package:ironcirclesapp/screens/widgets/albumvideothumbnail.dart';
import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/extendedfab.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:ironcirclesapp/utils/permissions.dart';

class CircleAlbumScreen extends StatefulWidget {
  final bool deviceOnly;
  CircleObject circleObject;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final CircleAlbumBloc circleAlbumBloc;
  final CircleObjectBloc circleObjectBloc;
  final List<UserFurnace>? wallFurnaces;
  final GlobalEventBloc globalEventBloc;
  final FullScreenSwiperCaller fullScreenSwiperCaller;
  final CircleVideoBloc circleVideoBloc;
  final CircleImageBloc circleImageBloc;
  final Function downloadVideo;
  final bool interactive;
  final bool wall;
  final List<UserCircleCache>? wallUserCircleCaches;

  CircleAlbumScreen({
    Key? key,
    required this.deviceOnly,
    required this.circleObject,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleAlbumBloc,
    required this.circleObjectBloc,
    this.wallFurnaces,
    this.wallUserCircleCaches,
    this.wall = false,
    required this.globalEventBloc,
    required this.fullScreenSwiperCaller,
    required this.circleVideoBloc,
    required this.circleImageBloc,
    required this.downloadVideo,
    required this.interactive,
  }) : super(key: key);

  @override
  CircleAlbumScreenState createState() => CircleAlbumScreenState();
}

class CircleAlbumScreenState extends State<CircleAlbumScreen> {
  bool _canEdit = false;
  bool _isReordering = false;
  bool _toggleIcons = false;
  bool _showShare = false;
  bool _showClearCache = false;
  bool _canDelete = false;

  bool _changedSort = false;

  GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final List<AlbumItem> _selectedItems = [];

  final _scrollController = ScrollController();
  GlobalKey _gridViewKey = GlobalKey();
  late List<AlbumItem> _items;

  bool _showSpinner = false;
  final spinner = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    _items = List.from(widget.circleObject.album!.media);
    _items.removeWhere((element) => element.removeFromCache == true);
    _items.sort((a, b) => a.index.compareTo(b.index));

    _showShare = widget.circleObject
        .canShare(widget.userFurnace!.userid!, widget.circleObject.circle!);


    ///uncomment to support editing
    // if (widget.circleObject.creator?.id == widget.userFurnace!.userid) {
    //   _canDelete = true;
    //   _canEdit = true;
    // } else {
    //   _canDelete = false;
    // }

    widget.globalEventBloc.itemProgressIndicator.listen((item) {
      if (mounted) {
        try {
          setState(() {
            if (item.type == AlbumItemType.VIDEO) {
              ProcessCircleObjectEvents.putAlbumVideo(
                  widget.circleObject, item, widget.circleVideoBloc);
              int index = _items.indexOf(item);
              if (index != -1) {
                _items[index].thumbnailTransferState =
                    item.thumbnailTransferState;
                _items[index].fullTransferState = item.fullTransferState;
              }
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
      //_clearSpinner();
      debugPrint(
          "FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $err");
    }, cancelOnError: false);

    ///listener for user adding / deleting media
    widget.circleAlbumBloc.currentMedia.listen((media) {
      if (mounted) {
        widget.circleObject.album!.media = media;
        setState(() {
          _showSpinner = true;
          _items.clear();
          _items = media
              .where((element) => element.removeFromCache == false)
              .toList();
          //_scaffoldKey = GlobalKey<ScaffoldState>();
        });
        setState(() {
          _showSpinner = false;
        });
      }
    });

    ///refresh for member
    widget.circleObjectBloc.saveResults.listen((result) {
      if (mounted && _canDelete != true) {
        debugPrint("reloading");
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.circleAlbumBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generatedChildren = List.generate(
        _items.length,
        (index) => Container(
            key: Key(_items[index].id!),
            child: _items[index].type == AlbumItemType.VIDEO
                ? AlbumVideoThumbnailWidget(
                    circleObject: widget.circleObject,
                    userCircleCache: widget.userCircleCache,
                    item: _items[index],
                    longPress: _longPress,
                    tap: _onTap,
                    isSelected: _selectedItems.contains(_items[index]),
                    anythingSelected: _selectedItems.isNotEmpty,
                    isReordering: _isReordering,
                    fullScreen: _fullScreen,
                    download: widget.downloadVideo,
                    play: _onTap,
                    globalEventBloc: widget.globalEventBloc)
                : AlbumThumbnailWidget(
                    circleObject: widget.circleObject,
                    userCircleCache: widget.userCircleCache,
                    item: _items[index],
                    isReordering: _isReordering,
                    longPress: _longPress,
                    tap: _onTap,
                    isSelected: _selectedItems.contains(_items[index]),
                    anythingSelected: _selectedItems.isNotEmpty,
                    fullScreen: _fullScreen,
                  )));

    final makeBody = ReorderableBuilder(
        scrollController: _scrollController,
        enableDraggable: _isReordering,
        onReorder: (List<OrderUpdateEntity> orderUpdateEntities) {
          for (final orderUpdateEntity in orderUpdateEntities) {
            final item = _items.removeAt(orderUpdateEntity.oldIndex);
            _items.insert(orderUpdateEntity.newIndex, item);
            item.index = orderUpdateEntity.newIndex;
          }
          _changedSort = true;
        },
        builder: (children) {
          return GridView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              key: _gridViewKey,
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
              ),
              children: children);
        },
        children: generatedChildren);

    Widget iconRow = _toggleIcons == true
        ? Row(children: [
            IconButton(
                color: globalState.theme.background,
                onPressed: () {
                  setState(() {
                    _selectedItems.clear();
                    _toggleIcons = false;
                  });
                },
                icon: Icon(
                  Icons.cancel,
                  color: globalState.theme.buttonIcon,
                )),
            Text(
              _selectedItems.length.toString(),
              textScaler: TextScaler.linear(globalState.labelScaleFactor),
              style:
                  TextStyle(fontSize: 16, color: globalState.theme.labelText),
            ),
            const Spacer(),

            //(_checkIfCanDelete()) // || widget.mode == "vault")
            // &&
            // widget.slideUpPanel == false
            _canDelete
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
            _showClearCache
                ? IconButton(
                    color: globalState.theme.background,
                    onPressed: () {
                      _deleteVideoCache();
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: globalState.theme.buttonIcon,
                    ))
                : Container(),
            _showShare && Platform.isAndroid
                ? IconButton(
                    color: globalState.theme.background,
                    onPressed: () {
                      _downloadMedia();
                    },
                    icon: Icon(
                      Icons.download,
                      color: globalState.theme.buttonIcon,
                    ),
                  )
                : Container(),
            //widget.slideUpPanel == false &&
            _showShare
                ? IconButton(
                    color: globalState.theme.background,
                    onPressed: () {
                      _share();
                    },
                    icon: Icon(
                      Icons.share,
                      color: globalState.theme.buttonIcon,
                    ),
                  )
                : Container(),
          ])
        : Container();

    final generate = InkWell(
        onTap: () {
          _generateImage();
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Container(
            width: 65,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: globalState.theme.buttonGenerate.withOpacity(.2),
            ),
            child: Center(
                child: ICText(
              AppLocalizations.of(context)!.generate.toLowerCase(),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: globalState.theme.buttonGenerate,
            )),
          ),
        ));

    final media = ExtendedFAB(
      label: AppLocalizations.of(context)!.fromDevice,
      color: globalState.theme.libraryFAB,
      onPressed: () {
        _pickImagesAndVideos();
      },
      icon: Icons.add,
    );

    final gif = InkWell(
        onTap: () {
          _searchGiphy();
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.withOpacity(0.85),
              ),
              child: const Center(
                child: Icon(
                  Icons.gif_box,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            )));

    final camera = InkWell(
        onTap: () {
          _captureMedia();
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.withOpacity(0.85),
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            )));

    return Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.albumTitle,
          actions: [
            _canEdit == true
                ? IconButton(
                    color: globalState.theme.background,
                    icon: Icon(
                      Icons.move_down_rounded,
                      color: _isReordering == true
                          ? globalState.theme.buttonIcon
                          : globalState.theme.textTitle,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_changedSort == true) {
                          ///update album
                          if (widget.deviceOnly) {
                            for (AlbumItem item
                                in widget.circleObject.album!.media) {
                              int placeIndex = _items.indexOf(item);
                              if (placeIndex != -1) {
                                item.index = placeIndex;
                              }
                            }
                          } else {
                            widget.circleAlbumBloc.updateAlbumOrder(
                                widget.userFurnace,
                                widget.circleObject,
                                _items);
                          }
                          _changedSort = false;
                        }
                        _isReordering = !_isReordering;
                        _toggleIcons = false;
                        _selectedItems.clear();
                      });
                    })
                : Container()
          ],
        ),
        body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refresh,
            color: globalState.theme.buttonIcon,
            child: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: _showSpinner == true
                    ? Column(children: [
                        Expanded(
                          child: spinner,
                        )
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                            iconRow,
                            widget.circleObject.body != null &&
                                    widget.circleObject.body!.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5, bottom: 5),
                                    child: Text(widget.circleObject.body!,
                                        textScaler: TextScaler.linear(
                                            globalState.messageScaleFactor),
                                        style: TextStyle(
                                            height: 1.4,
                                            //color: messageColor,
                                            fontSize: globalState
                                                .userSetting.fontSize)))
                                : Container(),
                            Expanded(child: makeBody),
                            _canEdit == true &&
                                    widget.fullScreenSwiperCaller !=
                                        FullScreenSwiperCaller.library
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 10),
                                        ),
                                        camera,
                                        gif,
                                        generate,
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                        ),
                                        const Spacer(),
                                        media,
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                        ),
                                      ])
                                : Container()
                          ]))),
        floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _canEdit == true &&
                    widget.fullScreenSwiperCaller ==
                        FullScreenSwiperCaller.library
                ? FloatingActionButton(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    backgroundColor: globalState.theme.homeFAB,
                    onPressed: () {
                      _captureMedia();
                    },
                    child: Icon(
                      Icons.camera_alt,
                      color: globalState.theme.background,
                    ))
                : Container()));
  }

  bool isCached(AlbumItem item) {
    bool cached = VideoCacheService.isAlbumVideoCached(
        widget.circleObject, widget.userCircleCache!.circlePath!, item);

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

  void _share() async {
    for (AlbumItem item in _selectedItems) {
      if (item.type == AlbumItemType.VIDEO) {
        if (isCached(item) == false) return;
      }
    }

    CircleObject sendingObject = CircleObject(
      seed: widget.circleObject.seed,
      creator: User(
        username: widget.userFurnace.username,
        id: widget.userFurnace.userid,
        accountType: widget.userFurnace.accountType,
      ),
      body: '',
      circle: widget.userCircleCache.cachedCircle,
      //sortIndex: index,
      ratchetIndexes: [],
      created: DateTime.now(),
      type: CircleObjectType.CIRCLEALBUM,
      /*circle: Circle(
          id: userCircleCache.circle,
        )*/
      album: CircleAlbum(
        media: _selectedItems,
      ),
    );

    sendingObject.userCircleCache = widget.userCircleCache;

    DialogMultiShareTo.shareToPopup(
        context, [sendingObject], ShareCircleObjects.shareToDestination);
  }

  Future<void> _refresh() async {
    debugPrint('album _refresh');

    ///wait
    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    });
  }

  _showNeedToCacheSnackbar() {
    FormattedSnackBar.showSnackbarWithContext(
        context, AppLocalizations.of(context)!.needToCacheVideo, '', 2, false);
  }

  void _showShareAndCache(AlbumItem selected) {
    bool needCache = false;
    bool showWarning = false;
    bool onlyVideo = true;

    for (AlbumItem item in _selectedItems) {
      if (_showShare) {
        if (item.video != null) {
          if (item.video!.streamable! && !item.video!.streamableCached) {
            needCache = true;
            if (item.id == selected.id) {
              showWarning = true;
            }
          } else if (item.video!.videoState != VideoStateIC.VIDEO_READY &&
              item.video!.videoState != VideoStateIC.NEEDS_CHEWIE &&
              widget.circleObject.circle!.id! != DeviceOnlyCircle.circleID) {
            needCache = true;
            if (item.id == selected.id) {
              showWarning = true;
            }
          } else {
            _showClearCache = true;
          }
        } else {
          onlyVideo = false;
        }
      }
    }

    if (needCache) {
      _selectedItems.remove(selected);
      if (showWarning) {
        _showNeedToCacheSnackbar();
      }

      _showClearCache = false;
    }

    if (!onlyVideo) {
      _showClearCache = false;
    }
  }

  _downloadMedia() async {
    await DialogDownload.showAndDownloadAlbumItems(
        context,
        AppLocalizations.of(context)!.downloadingFiles,
        _selectedItems,
        widget.circleObject,
        widget.userCircleCache);
  }

  void _delete() async {
    FocusScope.of(context).unfocus();

    if (_items.length - _selectedItems.length < 1) {
      await DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.cannotDeleteItem,
          AppLocalizations.of(context)!.mustKeepAlbumItem,
          "",
          "",
          "",
          false);
    } else {
      await DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.deleteItemsTitle,
          AppLocalizations.of(context)!.deleteItems,
          _deleteItems,
          null,
          false,
          null);
    }
  }

  _deleteItems() async {
    if (widget.deviceOnly == true) {
      await widget.circleAlbumBloc.deleteCachedMedia(
        widget.circleObject,
        widget.userCircleCache,
        widget.userFurnace!,
        _selectedItems,
      );
    } else {
      await widget.circleAlbumBloc.deleteAlbumMedia(
          widget.circleObject,
          widget.userCircleCache,
          widget.userFurnace!,
          _selectedItems,
          widget.circleObjectBloc);
    }

    setState(() {
      _selectedItems.clear();
      _toggleIcons = false;
    });
  }

  _longPress(AlbumItem item) {
    //debugPrint("long press");
    setState(() {
      if (_isReordering == false && _toggleIcons == true) {
        _selectedItems.clear();
        _toggleIcons = false;
        _showShareAndCache(item);
      } else if (_isReordering == false && _toggleIcons == false) {
        _selectedItems.add(item);
        _toggleIcons = true;
        _showShareAndCache(item);
      }
    });
  }

  _onTap(AlbumItem item) {
    //debugPrint("on tap");

    ///have a check for permissions
    if (_isReordering == false && _toggleIcons == true) {
      if (_selectedItems.isNotEmpty) {
        if (_selectedItems.contains(item)) {
          setState(() {
            _selectedItems.remove(item);

            if (_selectedItems.isEmpty) {
              _toggleIcons = false;
            } else {
              _showShareAndCache(item);
            }
          });
        } else {
          setState(() {
            _selectedItems.add(item);
            _showShareAndCache(item);
          });
        }
      }
    } else if (_isReordering == false && _toggleIcons == false) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FullScreenGallerySwiper(
                    albumDownloadVideo: widget.downloadVideo,
                    globalEventBloc: widget.globalEventBloc,
                    circleAlbumBloc: widget.circleAlbumBloc,
                    circleImageBloc: widget.circleImageBloc,
                    userCircleCache: widget.userCircleCache,
                    fullScreenSwiperCaller: widget.wall
                        ? FullScreenSwiperCaller.feed
                        : FullScreenSwiperCaller.circle,
                    //libraryObjects: [widget.circleObject],
                    //imageProvider:
                    //  const AssetImage("assets/large-image.jpg"),
                    circleObject: widget.circleObject,
                    userFurnaces:
                        widget.wallFurnaces == null ? [] : widget.wallFurnaces!,
                    userCircleCaches: widget.wallUserCircleCaches == null
                        ? []
                        : widget.wallUserCircleCaches!,
                    userFurnace: widget.wall
                        ? widget.circleObject.userFurnace!
                        : widget.userFurnace,
                    circle: widget.wall
                        ? widget.circleObject.userCircleCache!.cachedCircle!
                        : widget.circleObject.circle,
                    delete: _swiperDelete,
                    albumIndex: item.index,
                  )));
    } else {
      debugPrint("here");
    }
  }

  void doNothing() {}

  Future<void> doNothingLater() async {}

  void _pickImagesAndVideos() async {
    try {
      setState(() {
        _selectedItems.clear();
        _toggleIcons = false;
      });

      //_closeKeyboard();

      // setState(() {
      //   _showSpinner = true;
      // });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.media,
      );

      if (result != null && result.files.isNotEmpty) {
        MediaCollection mediaCollection = MediaCollection();
        await mediaCollection.populateFromFilePicker(
            result.files, MediaType.image);

        SelectedMedia? selectedImages = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImagePreviewer(
                      hiRes: false,
                      streamable: false,

                      ///until vids?
                      setTimer: doNothing,
                      setScheduled: doNothing,
                      media: mediaCollection,
                      userFurnaces: widget.wallFurnaces == null //isEmpty check
                          ? [widget.userFurnace!]
                          : widget.wallFurnaces!,
                    )));

        if (selectedImages != null) {
          if (selectedImages.mediaCollection.isNotEmpty) {
            //_previewSelectedMedia(selectedImages);
            ///download and add to album?
            widget.circleAlbumBloc.addAlbumMedia(
                widget.circleObject,
                widget.userCircleCache,
                widget.userFurnace!,
                selectedImages.mediaCollection.media,
                widget.circleObjectBloc,
                selectedImages.hiRes);
          }
        }
      }

      // setState(() {
      //   _showSpinner = false;
      // });
      // _refreshEnabled = true;
      return;
    } catch (error, trace) {
      // setState(() {
      //   _showSpinner = false;
      // });

      if (error.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(error, trace);
        debugPrint('_selectImage: $error');

        // _imagePreview = false;
        // _sendEnabled = false;
        // //_cancelEnabled = false;
        // _image = null;
        // _refreshEnabled = true;
      }
    }
  }

  void _swiperDelete(AlbumItem albumItem) async {
    FocusScope.of(context).unfocus();

    if (_items.length - 1 < 1) {
      await DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.cannotDeleteItem,
          AppLocalizations.of(context)!.mustKeepAlbumItem,
          "",
          "",
          "",
          false);
    } else {
      await DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.confirmDeleteTitle,
          AppLocalizations.of(context)!.confirmDeleteMessage,
          _swiperDeleteConfirmed,
          null,
          false,
          albumItem);
    }
  }

  _swiperDeleteConfirmed(AlbumItem item) async {
    widget.circleAlbumBloc.deleteAlbumMedia(
        widget.circleObject,
        widget.userCircleCache,
        widget.userFurnace!,
        [item],
        widget.circleObjectBloc);
  }

  _fullScreen(AlbumItem item) async {
    if (_isReordering == false && _toggleIcons == true) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FullScreenGallerySwiper(
                    albumDownloadVideo: widget.downloadVideo,
                    globalEventBloc: widget.globalEventBloc,
                    circleAlbumBloc: widget.circleAlbumBloc,
                    circleImageBloc: widget.circleImageBloc,
                    userCircleCache: widget.userCircleCache,
                    fullScreenSwiperCaller: widget.wall
                        ? FullScreenSwiperCaller.feed
                        : FullScreenSwiperCaller.circle,
                    //libraryObjects: [widget.circleObject],
                    //imageProvider:
                    //  const AssetImage("assets/large-image.jpg"),
                    circleObject: widget.circleObject,
                    userFurnaces:
                        widget.wallFurnaces == null ? [] : widget.wallFurnaces!,
                    userCircleCaches: widget.wallUserCircleCaches == null
                        ? []
                        : widget.wallUserCircleCaches!,
                    userFurnace: widget.wall
                        ? widget.circleObject.userFurnace!
                        : widget.userFurnace,
                    circle: widget.wall
                        ? widget.circleObject.userCircleCache!.cachedCircle!
                        : widget.circleObject.circle,
                    delete: _swiperDelete,
                    albumIndex: item.index,
                  )));
    }
  }

  _captureMedia() async {
    try {
      setState(() {
        _selectedItems.clear();
        _toggleIcons = false;
      });

      CapturedMediaResults? results = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CaptureMedia()),
      );

      if (results != null) {
        if (widget.deviceOnly) {
          widget.circleObject = await widget.circleAlbumBloc.addCacheMedia(
              widget.circleObject,
              results.mediaCollection.media,
              true //results.hiRes,
              );
        } else {
          SelectedMedia? selectedImages = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagePreviewer(
                  hiRes: false,
                  streamable: false,
                  setTimer: doNothing,
                  setScheduled: doNothing,
                  screenName: widget.userCircleCache.prefName ?? '',
                  userFurnaces: widget.wallFurnaces == null
                      ? [widget.userFurnace!]
                      : widget.wallFurnaces!,
                  media: results.mediaCollection,
                  redo: _captureMedia,
                ),
              ));

          if (selectedImages != null) {
            if (selectedImages.mediaCollection.isNotEmpty) {
              widget.circleAlbumBloc.addAlbumMedia(
                  widget.circleObject,
                  widget.userCircleCache,
                  widget.userFurnace!,
                  selectedImages.mediaCollection.media,
                  widget.circleObjectBloc,
                  selectedImages.hiRes);
            }
          }
        }
      }

      return;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumScreen._captureMedia: $error');
    }
  }

  _generateImage() async {
    try {
      setState(() {
        _selectedItems.clear();
        _toggleIcons = false;
      });

      // setState(() {
      //   _showSpinner = true;
      // });
      SelectedMedia? selectedImages = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StableDiffusionWidget(
            userFurnace: widget.userFurnace!,

            ///for wall, change?
            imageGenType: ImageType.image,
            //previewScreenName: widget.user,
          ),
        ),
      );

      if (selectedImages != null) {
        //_refreshEnabled = true;

        if (selectedImages.mediaCollection.isNotEmpty) {
          //if (_circle.type == CircleType.VAULT) {
          // _mediaCollection = selectedImages.mediaCollection;
          // _send(overrideButton: true);
          //} else if (widget.wall) {
          // _send(
          //     overrideButton: true,
          //     mediaCollection: selectedImages.mediaCollection);
          //} else {
          widget.circleAlbumBloc.addAlbumMedia(
              widget.circleObject,
              widget.userCircleCache,
              widget.userFurnace!,
              selectedImages.mediaCollection.media,
              widget.circleObjectBloc,
              selectedImages.hiRes);
          // }
        }
      }

      // setState(() {
      //   _showSpinner = false;
      // });
      //
      // _refreshEnabled = true;
      return;
    } catch (error, trace) {
      // setState(() {
      //   _showSpinner = false;
      // });

      if (error.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(error, trace);
        debugPrint('generateImage: $error');

        // _imagePreview = false;
        // _sendEnabled = false;
        // //_cancelEnabled = false;
        // _image = null;
        // _refreshEnabled = true;
      }
    }
  }

  _searchGiphy() async {
    setState(() {
      _selectedItems.clear();
      _toggleIcons = false;
    });

    GiphyOption? giphyOption = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectGif(
                  refresh: doNothingLater,
                )));

    if (giphyOption != null) {
      MediaCollection mediaCollection = MediaCollection();
      mediaCollection.populateFromGiphyOption(giphyOption);
      widget.circleAlbumBloc.addAlbumGif(
        widget.circleObject,
        widget.userCircleCache,
        widget.userFurnace!,
        giphyOption,
        widget.circleObjectBloc,
      );
    }
  }

  void _deleteVideoCache() async {
    FocusScope.of(context).unfocus();
    await DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.removeVideoCacheTitle,
        AppLocalizations.of(context)!.removeVideoCacheMessage,
        _deleteVideoCacheConfirmed,
        null,
        false,
        null);
  }

  _deleteVideoCacheConfirmed() async {
    for (AlbumItem item in _selectedItems) {
      if (item.video != null) {
        item.video!.streamableCached = false;
        widget.circleVideoBloc.deleteItemCache(widget.userFurnace.userid!,
            widget.userCircleCache.circlePath!, widget.circleObject, item);
      }
    }

    setState(() {
      _selectedItems.clear();
      _toggleIcons = false;
    });
  }

}
