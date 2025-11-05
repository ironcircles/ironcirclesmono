// import 'dart:io';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/fullscreen/fullscreengalleryswiper.dart';
// import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
// import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
// import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
// import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
// import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
// import 'package:ironcirclesapp/screens/widgets/dialogdownload.dart';
// import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
// import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
// import 'package:ironcirclesapp/services/cache/videocache_service.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
//
// import 'package:ironcirclesapp/models/album_item.dart';
//
// class FullScreenAlbumSwiper extends StatefulWidget {
//   final CircleObject circleObject;
//   final UserFurnace userFurnace;
//   final UserCircleCache userCircleCache;
//   final Circle? circle;
//   final bool sharePermissions;
//   final bool ownerPermissions;
//   final bool downloadPermissions;
//   final List<AlbumItem> items;
//   final AlbumItem currentItem;
//   final Function delete;
//   final bool isSelecting;
//   final CircleAlbumBloc circleAlbumBloc;
//   final GlobalEventBloc globalEventBloc;
//   final FullScreenSwiperCaller fullScreenSwiperCaller;
//   final Function downloadVideo;
//   final bool interactive;
//
//   const FullScreenAlbumSwiper({
//     required this.sharePermissions,
//     required this.ownerPermissions, //delete
//     required this.downloadPermissions, //right?
//     required this.circleObject,
//     required this.userCircleCache,
//     required this.circle,
//     required this.userFurnace,
//     required this.items,
//     required this.currentItem,
//     required this.delete,
//     required this.isSelecting,
//     required this.circleAlbumBloc,
//     required this.globalEventBloc,
//     required this.fullScreenSwiperCaller,
//     required this.downloadVideo,
//     required this.interactive,
//   });
//
//   @override
//   _FullScreenAlbumSwiperState createState() => _FullScreenAlbumSwiperState();
// }
//
// class _FullScreenAlbumSwiperState extends State<FullScreenAlbumSwiper> {
//   AlbumItem? _lastVideoPlayed;
//   bool _hiResAvailable = false;
//   bool justLoadedSwiper = true;
//   bool _loading = false;
//
//   late CircleVideoBloc _circleVideoBloc;
//   final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();
//   PageController pageController =
//       PageController(initialPage: -1, viewportFraction: 100);
//   List<AlbumItem> _galleryObjects = [];
//   int _currentIndex = -1;
//
//   bool _showThumbnail = false;
//   Circle? _currentCircle;
//   String appBarTitle = '';
//
//   bool _showSpinner = false;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//
//   @override
//   void initState() {
//     _currentCircle = widget.circle;
//
//     _circleVideoBloc = CircleVideoBloc(widget.globalEventBloc);
//
//     ///listener for user deleting media
//     widget.circleAlbumBloc.mediaDeleted.listen((media) {
//       if (mounted) {
//         //does this even need to do anything?
//         for (AlbumItem item in media) {
//           widget.circleObject.album?.media.remove(item);
//         }
//         setState(() {
//           if (_galleryObjects.length == 1) {
//             pageController.jumpToPage(0);
//           } else if (_galleryObjects.isEmpty) {
//             Navigator.pop(context);
//           } else {
//             pageController.jumpToPage(_currentIndex - 1);
//           }
//         });
//       }
//     });
//
//     widget.globalEventBloc.itemProgressIndicator.listen((item) {
//       if (mounted) {
//         try {
//           setState(() {
//             if (item.type == AlbumItemType.VIDEO) {
//               ProcessCircleObjectEvents.putAlbumVideo(
//                   widget.circleObject, item, _circleVideoBloc);
//
//               // if (circleObject.transferPercent == 100) {
//               //   _circleObjectBloc.sinkVaultRefresh();
//               // }
//             }
//           });
//         } catch (error, trace) {
//           LogBloc.insertError(error, trace);
//           debugPrint(
//               'FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $error');
//         }
//       }
//     }, onError: (err) {
//       _clearSpinner();
//       debugPrint(
//           "FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $err");
//     }, cancelOnError: false);
//
//     _circleVideoBloc.streamItemAvailable.listen((albumItem) async {
//       if (mounted) {
//         try {
//           int index = _galleryObjects.indexWhere((param) => param.id == albumItem.id);
//
//           await _disposeControllers();
//
//           await _videoControllerBloc.addItem(_galleryObjects[index]);
//           _lastVideoPlayed = _galleryObjects[index];
//
//           setState(() {
//             albumItem.video!.videoState = VideoStateIC.VIDEO_READY;
//           });
//
//           _loading = false;
//         } catch (err, trace) {
//           LogBloc.insertError(err, trace);
//           debugPrint('InsideCircle.streamAvailable.listen: $err');
//         }
//       }
//     }, onError: (err) {
//       _clearSpinner();
//       debugPrint("InsideCircle.listen: $err");
//     }, cancelOnError: false);
//
//     _circleVideoBloc.itemAutoPlayReady.listen((item) async {
//       if (mounted) {
//         try {
//           if (item.video!.streamable != null &&
//               item.video!.streamable! &&
//               item.video!.streamableCached == false) {
//             _streamVideo(item, widget.circleObject);
//           } else {
//             _playVideo(item);
//           }
//         } catch (error, trace) {
//           LogBloc.insertError(error, trace);
//           debugPrint("CircleAlbumScreen.streamAvailable.listen: $error");
//         }
//       }
//     }, onError: (error) {
//       _clearSpinner();
//       debugPrint("CircleAlbumScreen.listen: $error");
//     }, cancelOnError: false);
//
//     _galleryObjects.addAll(widget.items);
//     _scrubNotReady(_galleryObjects);
//     int itemIndex = _galleryObjects.indexOf(widget.currentItem);
//     _currentIndex = itemIndex;
//
//     pageController = PageController(
//       initialPage: _currentIndex,
//     );
//
//     super.initState();
//   }
//
//   void setAppBarTitle(int index) {
//     appBarTitle =
//         "${AppLocalizations.of(context)!.albumSwiperItem}${_currentIndex + 1}/${_galleryObjects.length}";
//   }
//
//   void _scrubNotReady(List<AlbumItem> scrubThese) {
//     //remove streaming videos that aren't ready
//     scrubThese.removeWhere((element) => (element.video != null &&
//         element.video!.streamable == true &&
//         element.video!.videoState! != VideoStateIC.NEEDS_CHEWIE &&
//         element.video!.videoState! != VideoStateIC.BUFFERING &&
//         element.video!.videoState! != VideoStateIC.VIDEO_READY &&
//         element.video!.videoState! != VideoStateIC.PREVIEW_DOWNLOADED &&
//         element.video!.videoState! != VideoStateIC.VIDEO_UPLOADED &&
//         element.video!.videoState! != VideoStateIC.VIDEO_DOWNLOADED));
//
//     //remove e2ee videos that haven't been downloaded
//     scrubThese.removeWhere((element) => (element.video != null &&
//         element.video!.streamable == false &&
//         (element.video!.videoState! != VideoStateIC.NEEDS_CHEWIE) &&
//         element.video!.videoState! != VideoStateIC.VIDEO_READY &&
//         element.video!.videoState! != VideoStateIC.VIDEO_DOWNLOADED &&
//         element.video!.videoState! != VideoStateIC.VIDEO_UPLOADED &&
//         element.fullTransferState != BlobState.READY));
//   }
//
//   bool isCached(AlbumItem item) {
//     bool cached = VideoCacheService.isAlbumVideoCached(
//         widget.circleObject, widget.userCircleCache!.circlePath!, item);
//
//     if (!cached) {
//       DialogNotice.showNoticeOptionalLines(
//           context,
//           AppLocalizations.of(context)!.videoMustBeCachedTitle,
//           AppLocalizations.of(context)!.videoMustBeCachedMessage1,
//           false);
//       return false;
//     }
//     return true;
//   }
//
//   @override
//   void dispose() {
//     widget.circleAlbumBloc.dispose();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _videoControllerBloc.disposeLast();
//     });
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     setAppBarTitle(_currentIndex);
//
//     var _shareIcon = _galleryObjects.isNotEmpty
//         ? !_showSpinner
//             ? IconButton(
//                 onPressed: () {
//                   _share(_galleryObjects[_currentIndex]);
//                 },
//                 icon: Icon(
//                   Icons.share,
//                   color: globalState.theme.button,
//                 ),
//               )
//             : Container()
//         : Container();
//
//     var _downloadIcon = _galleryObjects.isNotEmpty
//         ? IconButton(
//             onPressed: () {
//               _download(_galleryObjects[_currentIndex]);
//             },
//             icon: Icon(
//               Icons.download,
//               color: globalState.theme.button,
//             ),
//           )
//         : Container();
//
//     var _deleteIcon = widget.delete != null && _galleryObjects.isNotEmpty
//         ? IconButton(
//             onPressed: () {
//               widget.delete!(_galleryObjects[_currentIndex]);
//             },
//             icon: Icon(
//               Icons.delete,
//               color: globalState.theme.button,
//             ),
//           )
//         : Container();
//
//     var appBarWidget = PreferredSize(
//         preferredSize: const Size.fromHeight(37.0),
//         child: AppBar(
//             title: Text(appBarTitle,
//                 style: TextStyle(
//                   color: globalState.theme.menuIcons,
//                 )),
//             elevation: 0,
//             toolbarHeight: 45,
//             centerTitle: false,
//             titleSpacing: 0.0,
//             iconTheme: IconThemeData(
//               color: globalState.theme.menuIcons,
//             ),
//             backgroundColor: Colors.transparent,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, size: 30),
//               onPressed: () => Navigator.pop(context),
//             ),
//             actions: _currentCircle == null
//                 ? null
//                 : (_currentCircle!.privacyShareImage == true &&
//                                 widget.ownerPermissions == true ||
//                             _currentCircle!.id! == DeviceOnlyCircle.circleID ||
//                             _currentCircle!.memberCount == null &&
//                                 widget.ownerPermissions == true) &&
//                         !widget.circleObject.oneTimeView &&
//                         !widget.isSelecting &&
//                         Platform.isAndroid
//                     ? [_deleteIcon, _downloadIcon, _shareIcon]
//
//                     ///android owner
//                     : (_currentCircle!.privacyShareImage == true &&
//                                     widget.ownerPermissions == false ||
//                                 _currentCircle!.id! ==
//                                     DeviceOnlyCircle.circleID) &&
//                             !widget.circleObject.oneTimeView &&
//                             !widget.isSelecting &&
//                             Platform.isAndroid
//                         ? [_downloadIcon, _shareIcon]
//
//                         ///android member w share permissions
//                         : (_currentCircle!.privacyShareImage == false &&
//                                         widget.ownerPermissions == false ||
//                                     _currentCircle!.id! ==
//                                         DeviceOnlyCircle.circleID) &&
//                                 !widget.circleObject.oneTimeView &&
//                                 !widget.isSelecting &&
//                                 Platform.isAndroid
//                             ? []
//
//                             ///android member w/o share permissions
//                             : (_currentCircle!.privacyShareImage == true &&
//                                             widget.ownerPermissions == true ||
//                                         _currentCircle!.id! ==
//                                             DeviceOnlyCircle.circleID) &&
//                                     !widget.circleObject.oneTimeView &&
//                                     !widget.isSelecting &&
//                                     Platform.isIOS
//                                 ? [_deleteIcon, _shareIcon]
//
//                                 /// ios owner
//                                 : (_currentCircle!.privacyShareImage == true &&
//                                             widget.ownerPermissions == false) &&
//                                         !widget.circleObject.oneTimeView &&
//                                         !widget.isSelecting &&
//                                         Platform.isIOS
//                                     ? [_shareIcon]
//
//                                     ///ios member w share permissions
//                                     : []
//
//             ///ios member w/o share permissions
//             ));
//
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       backgroundColor: Colors.black, //globalState.theme.background,
//       body: Stack(children: [
//         _galleryObjects.isEmpty
//             ? Container()
//             : PhotoViewGallery.builder(
//                 backgroundDecoration: const BoxDecoration(color: Colors.black),
//                 itemCount: _galleryObjects.length,
//                 enableRotation: false,
//                 //reverse: true,
//                 pageController: pageController,
//                 builder: (context, index) {
//                   debugPrint(
//                       '*********BUILDER************************ $index ***************************');
//
//                   ImageProvider? _imageProvider;
//                   ChewieController? controller;
//                   AlbumItem albumItem = _galleryObjects[index];
//
//                   if (albumItem.type == AlbumItemType.VIDEO) {
//                     if (justLoadedSwiper) {
//                       justLoadedSwiper = false;
//                       _playFirstVideo();
//                     } else
//                       controller =
//                           _videoControllerBloc.fetchAlbumController(albumItem);
//                   } else {
//                     _imageProvider = _fetchImage(albumItem);
//                     _showSpinner = false;
//                   }
//                   if (albumItem.type == AlbumItemType.IMAGE ||
//                       albumItem.type == AlbumItemType.GIF)
//                     return _imageProvider != null //&& !_loading
//                         ? PhotoViewGalleryPageOptions(
//                             minScale: PhotoViewComputedScale.contained * 0.8,
//                             // Covered = the smallest possible size to fit the whole screen
//                             // maxScale:
//                             //   PhotoViewComputedScale.covered * 2,
//                             imageProvider: _imageProvider,
//                           )
//                         : PhotoViewGalleryPageOptions(
//                             maxScale: 0.5,
//                             imageProvider: AssetImage(
//                                 globalState.theme.themeMode == ICThemeMode.dark
//                                     ? 'assets/images/black.jpg'
//                                     : 'assets/images/white.jpg'),
//                           );
//                   else
//                     return PhotoViewGalleryPageOptions.customChild(
//                       child: controller == null
//                           ? Row(children: [
//                               const Spacer(),
//                               Center(child: spinkit),
//                               const Spacer(),
//                             ])
//                           : Row(mainAxisSize: MainAxisSize.max, children: [
//                               Expanded(
//                                 child: AspectRatio(
//                                     aspectRatio: controller.aspectRatio ??
//                                         controller.videoPlayerController.value
//                                             .aspectRatio,
//                                     child: Chewie(
//                                       controller: controller,
//                                     )),
//                               ),
//                             ]),
//                     );
//                 },
//                 onPageChanged: (int index) {
//                   debugPrint(
//                       '******************onPageChanged*************** $index ***************************');
//                   _currentIndex = index;
//                   setState(() {
//                     setAppBarTitle(_currentIndex);
//                   });
//
//                   AlbumItem albumItem = _galleryObjects[_currentIndex];
//
//                   if (albumItem.type == AlbumItemType.VIDEO) {
//                     ChewieController? controller =
//                         _videoControllerBloc.fetchAlbumController(albumItem);
//
//                     if (controller == null) {
//                       if (albumItem.video!.streamable! &&
//                           albumItem.video!.streamableCached == false)
//                         _streamVideo(albumItem, widget.circleObject);
//                       else
//                         PopulateMedia.populateAlbumVideoFile(
//                             widget.circleObject,
//                             albumItem,
//                             widget.circleObject.userFurnace,
//                             widget.userCircleCache,
//                             _circleVideoBloc,
//                             _videoControllerBloc,
//                             broadcastAutoPlay: true);
//                     }
//                   } else {
//                     _disposeControllers();
//                     //setState(() {
//                     _hiResAvailable = false;
//                     _showThumbnail = false;
//
//                     if (widget.fullScreenSwiperCaller ==
//                             FullScreenSwiperCaller.library ||
//                         widget.fullScreenSwiperCaller ==
//                             FullScreenSwiperCaller.feed) {
//                       _currentCircle = widget.circleObject.circle!;
//                     }
//                     // });
//                   }
//                 }),
//         SafeArea(
//             top: true,
//             child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [appBarWidget]))
//       ]),
//     );
//   }
//
//   void _share(AlbumItem albumItem) async {
//     if (albumItem.type == AlbumItemType.VIDEO) {
//       if (isCached(albumItem) == false) return;
//     }
//
//     //make new circle object and attach album item to it, then send?
//     CircleObject sendingObject = CircleObject(
//       seed: widget.circleObject.seed,
//       creator: User(
//         username: widget.userFurnace.username,
//         id: widget.userFurnace.userid,
//         accountType: widget.userFurnace.accountType,
//       ),
//       body: '',
//       circle: widget.userCircleCache.cachedCircle,
//       //sortIndex: index,
//       ratchetIndexes: [],
//       created: DateTime.now(),
//       type: CircleObjectType.CIRCLEALBUM,
//       /*circle: Circle(
//           id: userCircleCache.circle,
//         )*/
//     );
//
//     if (albumItem.type == AlbumItemType.IMAGE) {
//       sendingObject.image = albumItem.image;
//     } else if (albumItem.type == AlbumItemType.GIF) {
//       // sendingObject.gif = albumItem.gif;
//     } else if (albumItem.type == AlbumItemType.VIDEO) {
//       sendingObject.video = albumItem.video;
//     }
//
//     DialogShareTo.shareToPopup(context, widget.userCircleCache, sendingObject,
//         ShareCircleObject.shareToDestination);
//   }
//
//   _download(
//     AlbumItem albumItem,
//   ) async {
//     if (albumItem.type == AlbumItemType.VIDEO) {
//       if (isCached(albumItem) == false) return;
//     }
//
//     await DialogDownload.showAndDownloadAlbumItems(context, 'Downloading',
//         [albumItem], widget.circleObject, widget.userCircleCache);
//   }
//
//   handleAppLifecycleState() {
//     AppLifecycleState _lastLifecyleState;
//     SystemChannels.lifecycle.setMessageHandler((msg) {
//       debugPrint('SystemChannels> $msg');
//
//       switch (msg) {
//         case "AppLifecycleState.paused":
//           _lastLifecyleState = AppLifecycleState.paused;
//
//           //_videoControllerBloc.pauseLast();
//
//           //checkStayOrGo();
//           break;
//         case "AppLifecycleState.inactive":
//           _lastLifecyleState = AppLifecycleState.inactive;
//           //_videoControllerBloc.pauseLast();
//
//           //checkStayOrGo();
//           break;
//         case "AppLifecycleState.resumed":
//           globalState.setGlobalState();
//           _lastLifecyleState = AppLifecycleState.resumed;
//
//           break;
//         case "AppLifecycleState.suspending":
//           //checkStayOrGo();
//           break;
//         default:
//       }
//       return Future.value(null);
//     });
//   }
//
//   void _streamVideo(AlbumItem item, CircleObject circleObject) async {
//     late UserFurnace userFurnace;
//
//     if (circleObject.userFurnace != null) {
//       userFurnace = circleObject.userFurnace!;
//     } else {
//       userFurnace = widget.userFurnace;
//     }
//     _circleVideoBloc.getAlbumStreamingUrl(userFurnace, circleObject, item);
//   }
//
//   ImageProvider? _fetchImage(AlbumItem item) {
//     ImageProvider? _imageProvider;
//
//     if (item.type == AlbumItemType.GIF) {
//       _imageProvider = Image.network(
//         item.gif!.giphy!,
//       ).image;
//     } else {
//       //old versions may not have a fullimage
//       if (item.image!.fullImage == null) {
//         if (ImageCacheService.isAlbumThumbnailCached(
//           widget.circleObject,
//           item,
//           widget.userCircleCache.circlePath!,
//         )) {
//           String fullPath = ImageCacheService.returnExistingAlbumImagePath(
//             widget.userCircleCache.circlePath!,
//             widget.circleObject,
//             item.image!.thumbnail!,
//           );
//           _imageProvider = Image.file(File(fullPath)).image;
//           // String fullPath = ImageCacheService.returnAlbumThumbnailPath(
//           //     widget.userCircleCache.,
//           //     widget.circleObject.seed);
//         } else {
//           /*if (!_loading) {
//           _circleObjectBloc.downloadCircleImageThumbnail(
//               widget.userCircleCache, widget.userFurnace, circleObject);
//
//           _loading = true;
//         }*/
//         }
//       } else {
//         if (!_showThumbnail &&
//             ImageCacheService.isAlbumFullImageCached(
//               widget.circleObject,
//               item,
//               widget.userCircleCache.circlePath!,
//               widget.circleObject.seed!,
//             )) {
//           //String fullPath = ImageCacheService.returnAlbumFullImagePath(widget.userCircleCache.circlePath!, widget.circleObject.seed!);
//           String fullPath = ImageCacheService.returnExistingAlbumImagePath(
//             widget.userCircleCache.circlePath!,
//             widget.circleObject,
//             item.image!.fullImage!,
//           );
//
//           _imageProvider = Image.file(File(fullPath)).image;
//         } else {
//           _showSpinner = true;
//
//           //String thumbPath = ImageCacheService.returnAlbumThumbnailPath(widget.userCircleCache.circlePath!, widget.circleObject.seed!);
//           String thumbPath = ImageCacheService.returnExistingAlbumImagePath(
//             widget.userCircleCache.circlePath!,
//             widget.circleObject,
//             item.image!.thumbnail!,
//           );
//
//           if (ImageCacheService.isAlbumThumbnailCached(
//             widget.circleObject,
//             item,
//             widget.userCircleCache.circlePath!,
//           )) {
//             _showThumbnail = true;
//             return Image.file(File(thumbPath)).image;
//           }
//
//           // if (!widget.globalEventBloc.thumbnailExists(circleObject)) {
//           //   widget.circleImageBloc.notifyWhenThumbReady(widget.userFurnace,
//           //       circleObject.userCircleCache!, circleObject, _circleObjectBloc);
//           //
//           //   // setState(() {
//           //   _loading = true;
//           //
//           //   //});
//           // }
//         }
//       }
//     }
//
//     return _imageProvider;
//   }
//
//   _playFirstVideo() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       AlbumItem item = _galleryObjects[_currentIndex];
//
//       if (item.video == null) return;
//
//       if (item.video!.streamable! && item.video!.streamableCached == false) {
//         _streamVideo(item, widget.circleObject);
//       } else {
//         PopulateMedia.populateAlbumVideoFile(
//             widget.circleObject,
//             item,
//             widget.circleObject.userFurnace,
//             widget.userCircleCache,
//             _circleVideoBloc,
//             _videoControllerBloc,
//             broadcastAutoPlay: true);
//       }
//     });
//   }
//
//   _disposeControllers() async {
//     if (_lastVideoPlayed != null) {
//       _videoControllerBloc.pauseLast();
//
//       _videoControllerBloc.predisposeItem(_lastVideoPlayed);
//       setState(() {
//         _lastVideoPlayed!.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
//       });
//
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _videoControllerBloc.disposeItem(_lastVideoPlayed);
//       });
//     }
//   }
//
//   void _playVideo(AlbumItem item) async {
//     item.video!.videoFile = File(VideoCacheService.returnExistingAlbumVideoPath(
//         widget.userCircleCache.circlePath!,
//         widget.circleObject,
//         item.video!.video!));
//
//     await _disposeControllers();
//
//     await _videoControllerBloc.addItem(item);
//     _lastVideoPlayed = item;
//
//     if (mounted) {
//       setState(() {
//         item.video!.videoState = VideoStateIC.VIDEO_READY;
//       });
//     }
//
//     _loading = false;
//   }
//
//   _clearSpinner() {
//     _showSpinner = false;
//   }
// }
