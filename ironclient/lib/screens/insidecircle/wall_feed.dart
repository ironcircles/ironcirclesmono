// import 'dart:io';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/circleevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
// import 'package:ironcirclesapp/models/circlefile.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
//
// import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
// import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_calendar.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_detail.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreen.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/imagepreviewer.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/selectgif.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/subtype_credential.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/calendar_holder.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/gallery_holder.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/vault_object_display.dart';
// import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidewall_determine_widget.dart';
// import 'package:ironcirclesapp/screens/library/library.dart';
// import 'package:ironcirclesapp/screens/utilities/midjourney.dart';
// import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
// import 'package:ironcirclesapp/screens/utilities/stablediffusion_generate.dart';
// import 'package:ironcirclesapp/screens/widgets/centralcalendar.dart';
// import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
// import 'package:ironcirclesapp/screens/widgets/extendedfab.dart';
// import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
// import 'package:ironcirclesapp/screens/widgets/ictext.dart';
// import 'package:ironcirclesapp/services/cache/videocache_service.dart';
// import 'package:ironcirclesapp/services/tenor_service.dart';
// import 'package:ironcirclesapp/utils/emojiutil.dart';
// import 'package:ironcirclesapp/utils/permissions.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//
// class WallFeedWidget extends StatefulWidget {
//   //final UserCircleCache userCircleCache;
//   //final UserFurnace userFurnace;
//   final List<UserFurnace> userFurnaces;
//   final List<UserCircleCache> userCircleCaches;
//   //final Circle circle;
//   final List<CircleObject> circleObjects;
//   final Future<void> Function() refresh;
//   final bool Function(ScrollEndNotification) onNotification;
//
//   ///final int index;
//   final Function tapHandler;
//   final Function shareObject;
//   final Function unpinObject;
//   final Function longPressHandler;
//   final Function longReaction;
//   final Function shortReaction;
//   final Function storePosition;
//   final Function copyObject;
//   final Function reactionAdded;
//   final Function showReactions;
//   final bool displayReactionsRow;
//   final VideoControllerBloc videoControllerBloc;
//   final CircleVideoBloc circleVideoBloc;
//   final CircleRecipeBloc circleRecipeBloc;
//   final CircleObjectBloc circleObjectBloc;
//   final CircleImageBloc circleImageBloc;
//   final GlobalEventBloc globalEventBloc;
//   final CircleFileBloc circleFileBloc;
//   final Function updateList;
//   final Function submitVote;
//   final Function deleteObject;
//   final Function editObject;
//   final Function streamVideo;
//   final Function downloadFile;
//   final Function downloadVideo;
//   final Function retry;
//   final Function removeCache;
//   final Function predispose;
//   final Function playVideo;
//   final Function openExternalBrowser;
//   final Function leave;
//   final Function export;
//   final Function cancelTransfer;
//   final Function populateVideoFile;
//   final Function populateRecipeImageFile;
//   final Function populateImageFile;
//   final bool interactive;
//   final bool reverse;
//   final List<Member> members;
//   final Function send;
//   final Function sendLink;
//   final Function captureMedia;
//   final Function selectMedia;
//   final Function pickFiles;
//   final Function refreshObjects;
//   final UserCircleBloc userCircleBloc;
//   final CircleListBloc circleListBloc;
//   final Function addObjects;
//   final int objectsLenght;
//
//   const WallFeedWidget({
//     Key? key,
//     required this.members,
//     required this.reverse,
//     //required this.userCircleCache,
//     //required this.userFurnace,
//     required this.userFurnaces,
//     required this.userCircleCaches,
//     required this.circleObjects,
//     required this.captureMedia,
//     required this.sendLink,
//     //required this.selectVideos,
//     required this.onNotification,
//     required this.refresh,
//     required this.objectsLenght,
//
//     ///required this.index,
//     //required this.circle,
//     required this.tapHandler,
//     required this.shareObject,
//     required this.unpinObject,
//     required this.openExternalBrowser,
//     required this.leave,
//     required this.export,
//     required this.cancelTransfer,
//     required this.longPressHandler,
//     required this.longReaction,
//     required this.shortReaction,
//     required this.storePosition,
//     required this.copyObject,
//     required this.reactionAdded,
//     required this.showReactions,
//     required this.videoControllerBloc,
//     required this.globalEventBloc,
//     required this.circleVideoBloc,
//     required this.circleObjectBloc,
//     required this.circleImageBloc,
//     required this.circleRecipeBloc,
//     required this.circleFileBloc,
//     required this.updateList,
//     required this.submitVote,
//     required this.deleteObject,
//     required this.editObject,
//     required this.streamVideo,
//     required this.downloadVideo,
//     required this.downloadFile,
//     required this.retry,
//     required this.predispose,
//     required this.playVideo,
//     required this.removeCache,
//     required this.populateVideoFile,
//     required this.populateRecipeImageFile,
//     required this.populateImageFile,
//     required this.displayReactionsRow,
//     required this.interactive,
//     required this.send,
//     required this.selectMedia,
//     required this.pickFiles,
//     required this.refreshObjects,
//     required this.userCircleBloc,
//     required this.circleListBloc,
//     required this.addObjects,
//   }) : super(key: key);
//
//   @override
//   State<WallFeedWidget> createState() => _WallWidgetState();
// }
//
// class _WallWidgetState extends State<WallFeedWidget> {
//   List<CircleObject> _selected = [];
//   List<CircleObject> _waitingOnScroller = [];
//   late ScrollController scrollController;
//   final ItemScrollController _itemScrollController = ItemScrollController();
//   final ItemPositionsListener _itemPositionsListener =
//       ItemPositionsListener.create();
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
//       GlobalKey<RefreshIndicatorState>();
//   static const int _scrollDuration = 250;
//   bool _scrollingDown = false;
//   List<UserFurnace> _wallNetworks = [];
//
//   ///This doesn't raise events directly so doesn't need to be passed into the widget
//   ///like the other blocs (it raises events in CircleObjectBloc)
//   final CircleEventBloc _circleEventBloc = CircleEventBloc();
//
//   bool _showSpinner = false;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//
//   SelectedLibraryTab _selectedTab = SelectedLibraryTab.gallery;
//
//   ///The controller of sliding up panel
//   SlidingUpPanelController panelController = SlidingUpPanelController();
//
//   double minBound = 0;
//
//   double upperBound = 1.0;
//
//   bool _expanded = false;
//
//   @override
//   void initState() {
//     ///init variables for the calendar
//     DateTime _today = DateTime(
//       DateTime.now().year,
//       DateTime.now().month,
//       DateTime.now().day,
//     );
//
//     _setEventDateTime(
//         DateTime(
//             _today.year, _today.month, _today.day, DateTime.now().hour + 1),
//         DateTime(
//             _today.year, _today.month, _today.day, DateTime.now().hour + 2));
//
//     _wallNetworks.addAll(
//         widget.userFurnaces.where((element) => element.enableWall == true));
//     widget.globalEventBloc.refreshWall.listen((refresh) async {
//       if (mounted) {
//         setState(() {});
//       }
//     }, onError: (err) {
//       //_clearSpinner();
//       debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
//     }, cancelOnError: false);
//
//     scrollController = ScrollController();
//     scrollController.addListener(() {
//       if (scrollController.offset >=
//               scrollController.position.maxScrollExtent &&
//           !scrollController.position.outOfRange) {
//         panelController.expand();
//       } else if (scrollController.offset <=
//               scrollController.position.minScrollExtent &&
//           !scrollController.position.outOfRange) {
//         panelController.anchor();
//       } else {}
//     });
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width - 10;
//     double screenHeight = MediaQuery.of(context).size.height;
//
//     return Stack(children: [
//       Container(
//           margin:
//               const EdgeInsets.only(top: 0, left: 5.0, right: 5.0, bottom: 30),
//           child: RefreshIndicator(
//               key: _refreshIndicatorKey,
//               onRefresh: widget.refresh,
//               color: globalState.theme.buttonIcon,
//               child: widget.circleObjects.isEmpty
//                   ? Center(
//                       child: Container(
//                           decoration: BoxDecoration(
//                             color: globalState.theme.background,
//                           ),
//                           child: _showSpinner ? spinkit : Container()))
//                   : NotificationListener<ScrollEndNotification>(
//                       onNotification: widget.onNotification,
//                       child: ScrollablePositionedList.separated(
//
//                           /// Let the ListView know how many items it needs to build
//                           itemCount: widget.circleObjects.length,
//                           reverse: false,
//                           itemScrollController: _itemScrollController,
//                           itemPositionsListener: _itemPositionsListener,
//                           physics: const AlwaysScrollableScrollPhysics(),
//
//                           //physics: const NeverScrollableScrollPhysics(),
//                           separatorBuilder: (context, index) {
//                             return Container(
//                               color: globalState.theme.background,
//                               //height: 1,
//                               width: double.maxFinite,
//                             );
//                           },
//                           itemBuilder: (context, index) {
//                             //debugPrint(index);
//                             CircleObject item = widget.circleObjects[index];
//
//                             return InsideWallDetermineWidget(
//                               key: GlobalKey(),
//                               members: widget.members,
//                               //members: globalState.members,
//                               reverse: false,
//                               userCircleCache: item.userCircleCache!,
//                               userFurnace: item.userFurnace!,
//                               circleObjects: widget.circleObjects,
//                               index: index,
//                               refresh: widget.refresh,
//                               circle: item.userCircleCache!.cachedCircle!,
//                               tapHandler: widget.tapHandler,
//                               shareObject: widget.shareObject,
//                               unpinObject: widget.unpinObject,
//                               openExternalBrowser: widget.openExternalBrowser,
//                               leave: widget.leave,
//                               export: widget.export,
//                               cancelTransfer: widget.cancelTransfer,
//                               longPressHandler: widget.longPressHandler,
//                               longReaction: widget.longReaction,
//                               shortReaction: widget.shortReaction,
//                               storePosition: widget.storePosition,
//                               copyObject: widget.copyObject,
//                               reactionAdded: widget.reactionAdded,
//                               showReactions: widget.showReactions,
//                               videoControllerBloc: widget.videoControllerBloc,
//                               globalEventBloc: widget.globalEventBloc,
//                               circleVideoBloc: widget.circleVideoBloc,
//                               circleImageBloc: widget.circleImageBloc,
//                               circleObjectBloc: widget.circleObjectBloc,
//                               circleRecipeBloc: widget.circleRecipeBloc,
//                               circleFileBloc: widget.circleFileBloc,
//                               updateList: widget.updateList,
//                               submitVote: widget.submitVote,
//                               deleteObject: widget.deleteObject,
//                               editObject: widget.editObject,
//                               streamVideo: widget.streamVideo,
//                               downloadVideo: widget.downloadVideo,
//                               downloadFile: widget.downloadFile,
//                               retry: widget.retry,
//                               predispose: widget.predispose,
//                               playVideo: widget.playVideo,
//                               removeCache: widget.removeCache,
//                               populateFile: PopulateMedia.populateFile,
//                               populateVideoFile:
//                                   PopulateMedia.populateVideoFile,
//                               populateRecipeImageFile:
//                                   PopulateMedia.populateRecipeImageFile,
//                               populateImageFile:
//                                   PopulateMedia.populateImageFile,
//                               displayReactionsRow: true,
//                               interactive: true,
//                               maxWidth: screenWidth,
//                             );
//                           })))),
//       _waitingOnScroller.isNotEmpty
//           ? Align(
//               alignment: Alignment.bottomCenter,
//               child: InkWell(
//                   onTap: () {
//                     _addNewAndScrollToBottom();
//                   },
//                   child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.arrow_circle_down_rounded,
//                           size: 50,
//                           color: globalState.theme.buttonIcon,
//                         ),
//                         ICText(
//                           ' new messages',
//                           color: globalState.theme.buttonIcon,
//                         )
//                       ])))
//           : _scrollingDown
//               ? Align(
//                   alignment: Alignment.bottomCenter,
//                   child: InkWell(
//                       onTap: () {
//                         _addNewAndScrollToBottom();
//                       },
//                       child: Icon(
//                         Icons.arrow_circle_down_rounded,
//                         size: 50,
//                         color: globalState.theme.buttonIcon,
//                       )))
//               : Container()
//     ]);
//   }
//
//   String _getButtonText() {
//     if (_selected.isEmpty) {
//       switch (_selectedTab) {
//         case SelectedLibraryTab.gallery:
//           return 'Upload From Device';
//
//         case SelectedLibraryTab.links:
//           return 'New Link';
//         case SelectedLibraryTab.files:
//           return 'Upload From Device';
//         case SelectedLibraryTab.recipes:
//           return 'New Recipe';
//         case SelectedLibraryTab.events:
//           return 'New Event';
//         case SelectedLibraryTab.credentials:
//           return 'New Credential';
//       }
//     } else {
//       switch (_selectedTab) {
//         case SelectedLibraryTab.gallery:
//           return 'Post Selected Media';
//         case SelectedLibraryTab.links:
//           return 'Post Selected Link';
//         case SelectedLibraryTab.files:
//           return 'Post Selected File';
//         case SelectedLibraryTab.recipes:
//           return 'Post Selected Recipe';
//         case SelectedLibraryTab.events:
//           return 'Post Selected Event';
//         case SelectedLibraryTab.credentials:
//           return 'Post Selected Credential';
//       }
//     }
//   }
//
//   _doNothing() {}
//
//   _getUserCircleCacheFromFurnace(UserFurnace userFurnace) {
//     int index = widget.userCircleCaches
//         .indexWhere((element) => element.userFurnace! == userFurnace.pk);
//
//     return widget.userCircleCaches[index];
//   }
//
//   List<UserFurnace> _selectedNetworks = [];
//
//   _setNetworkFilter(List<UserFurnace> newlySelectedNetworks) {
//     _selectedNetworks.clear();
//     _selectedNetworks.addAll(newlySelectedNetworks);
//   }
//
//   /*_setNetworkFilterAndPost(List<UserFurnace> selectedNetworks) {
//     _selectedNetworks = selectedNetworks;
//
//     if (_selectedNetworks.isNotEmpty) {
//       _postWithNetworkFilter();
//     }
//   }
//
//   _post() {
//     if (_wallNetworks.length == 1) {
//       _selectedNetworks = _wallNetworks;
//       _postWithNetworkFilter();
//     } else if (_selected.isNotEmpty) {
//       _selectNetworks();
//     } else {
//       _postWithoutNetworkFilter();
//     }
//   }
// */
//   _selectNetworks(Function callback) async {
//     if (_wallNetworks.length == 1) {
//       _selectedNetworks = _wallNetworks;
//       _selectNetworkCallback(_selectedNetworks);
//     } else {
//       DialogSelectNetworks.selectNetworks(
//           context: context,
//           networks: _wallNetworks,
//           callback: _selectNetworkCallback,
//           existingNetworksFilter: _selectedNetworks);
//     }
//   }
//
//   _selectNetworkCallback(List<UserFurnace> selectedNetworks) async {
//     _selectedNetworks = selectedNetworks;
//     switch (_selectedCopy[0].type!) {
//       case CircleObjectType.CIRCLELINK:
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, userFurnace);
//           newPost.type = CircleObjectType.CIRCLELINK;
//           newPost.link = CircleLink(
//               title: _selectedCopy[0].link!.title,
//               url: _selectedCopy[0].link!.url,
//               description: _selectedCopy[0].link!.description,
//               image: _selectedCopy[0].link!.image);
//           widget.send(vaultObject: newPost, overrideButton: true);
//         }
//
//         break;
//       case CircleObjectType.CIRCLERECIPE:
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, userFurnace);
//           newPost.type = CircleObjectType.CIRCLERECIPE;
//           newPost.recipe = CircleRecipe();
//           newPost.recipe!.ingestDeepCopy(_selectedCopy[0].recipe!);
//           newPost.body = newPost.recipe!.name!;
//           widget.circleRecipeBloc
//               .create(userCircleCache, newPost, userFurnace, false, false);
//         }
//         break;
//       case CircleObjectType.CIRCLEFILE:
//         MediaCollection mediaCollection = MediaCollection();
//         mediaCollection.populateFromCircleObjects(_selectedCopy);
//
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, userFurnace);
//           newPost.file = CircleFile();
//           newPost.type = CircleObjectType.CIRCLEFILE;
//
//           widget.circleFileBloc.uploadFiles(userCircleCache, userFurnace,
//               newPost, widget.circleObjectBloc, mediaCollection.media);
//         }
//
//         break;
//       case CircleObjectType.CIRCLEEVENT:
//
//         ///share events is not supported yet
//         break;
//       case CircleObjectType.CIRCLECREDENTIAL:
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, userFurnace);
//           newPost.type = CircleObjectType.CIRCLEMESSAGE;
//           newPost.subType = SubType.LOGIN_INFO;
//           newPost.body = _selectedCopy[0].body;
//           newPost.subString1 = _selectedCopy[0].subString1;
//           newPost.subString2 = _selectedCopy[0].subString2;
//           newPost.subString3 = _selectedCopy[0].subString3;
//           newPost.subString4 = _selectedCopy[0].subString4;
//           widget.circleObjectBloc.saveCircleObject(
//               widget.globalEventBloc, userFurnace, userCircleCache, newPost);
//         }
//         break;
//     }
//   }
//
//   List<CircleObject> _selectedCopy = [];
//
//   _post() async {
//     if (SlidingUpPanelStatus.expanded == panelController.status) {
//       widget.globalEventBloc.broadcastClear();
//       panelController.collapse();
//
//       setState(() {
//         _expanded = false;
//       });
//     }
//
//     if (_itemScrollController.isAttached) {
//       _itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: _scrollDuration),
//           curve: Curves.easeInOutCubic);
//     }
//
//     if (_selected.isNotEmpty) {
//       ///copy and clear the selected list
//       _selectedCopy = List.from(_selected);
//       _selected.clear();
//
//       switch (_selectedCopy[0].type!) {
//         case CircleObjectType.CIRCLEIMAGE:
//           _postSelectedFromGallery(_selectedCopy);
//           break;
//         case CircleObjectType.CIRCLEVIDEO:
//           _postSelectedFromGallery(_selectedCopy);
//           break;
//         case CircleObjectType.CIRCLEGIF:
//           _postSelectedFromGallery(_selectedCopy);
//           break;
//         case CircleObjectType.CIRCLELINK:
//         case CircleObjectType.CIRCLERECIPE:
//         case CircleObjectType.CIRCLEFILE:
//         case CircleObjectType.CIRCLECREDENTIAL:
//           _selectNetworks(_selectNetworkCallback);
//           break;
//         case CircleObjectType.CIRCLEEVENT:
//
//           ///share events is not supported yet
//           break;
//       }
//     } else {
//       switch (_selectedTab) {
//         case SelectedLibraryTab.gallery:
//           _pickImagesAndVideos();
//           break;
//
//         case SelectedLibraryTab.links:
//           break;
//         case SelectedLibraryTab.files:
//           _pickFiles();
//           break;
//         case SelectedLibraryTab.recipes:
//           _createRecipe();
//           break;
//         case SelectedLibraryTab.events:
//           _createEvent();
//           break;
//         case SelectedLibraryTab.credentials:
//           _createSubtypeCredential();
//           break;
//       }
//     }
//   }
//
//   Future<CircleObject> _prepNewCircleObject(
//       String caption, UserCircleCache userCircleCache, UserFurnace userFurnace,
//       {bool skipBody = false}) async {
//     String messageText = '';
//
//     if (!skipBody) messageText = caption;
//
//     CircleObject newCircleObject = CircleObject.prepNewCircleObject(
//         userCircleCache, userFurnace, messageText, 0, null);
//
//     newCircleObject.emojiOnly = await EmojiUtil.checkForOnlyEmojis(caption);
//
//     return newCircleObject;
//   }
//
//   _updateSelected(List<CircleObject> selected) {
//     setState(() {
//       _selected = selected;
//     });
//   }
//
//   _updateTab(SelectedLibraryTab selectedLibraryTab) {
//     _selected.clear();
//
//     ///change the button text if something changed
//     setState(() {
//       _selectedTab = selectedLibraryTab;
//     });
//   }
//
//   _addNewAndScrollToBottom() {
//     if (_waitingOnScroller.isNotEmpty) {
//       widget.addObjects(_waitingOnScroller, true);
//       setState(() {
//         _waitingOnScroller.clear();
//       });
//     } else if (_itemScrollController.isAttached &&
//         widget.circleObjects.isNotEmpty) {
//       _itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: _scrollDuration),
//           curve: Curves.easeInOutCubic);
//     }
//   }
//
//   int? _increment;
//
//   _createSubtypeCredential() async {
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(_selectedNetworks[0]);
//
//     CircleObject? circleObject = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => SubtypeCredential(
//                 //userFurnaces: widget.userFurnaces,
//                 globalEventBloc: widget.globalEventBloc,
//                 circleObjectBloc: widget.circleObjectBloc,
//                 userCircleCache: userCircleCache,
//                 userFurnace: _selectedNetworks[0],
//                 userCircleBloc: widget.userCircleBloc,
//                 screenMode: ScreenMode.ADD,
//                 timer: CircleDisappearingTimer.OFF,
//                 scheduledFor: null,
//                 replyObject: null,
//                 wall: true,
//                 userFurnaces: _wallNetworks,
//                 //circleRecipeBloc: _circleRecipeBloc,
//               )),
//     );
//
//     if (circleObject != null) {
//       for (UserFurnace selectedNetwork in _selectedNetworks) {
//         UserCircleCache userCircleCache =
//             _getUserCircleCacheFromFurnace(selectedNetwork);
//
//         CircleObject newPost = await _prepNewCircleObject(
//             '', userCircleCache, selectedNetwork,
//             skipBody: true);
//
//         newPost.userFurnace = selectedNetwork;
//         newPost.userCircleCache = userCircleCache;
//
//         newPost.type = CircleObjectType.CIRCLEMESSAGE;
//         newPost.subType = SubType.LOGIN_INFO;
//         newPost.subString1 = circleObject.subString1;
//         newPost.subString2 = circleObject.subString2;
//         newPost.subString3 = circleObject.subString3;
//         newPost.subString4 = circleObject.subString4;
//
//         widget.circleObjectBloc.saveCircleObject(
//           widget.globalEventBloc,
//           selectedNetwork,
//           userCircleCache,
//           newPost,
//         );
//       }
//     }
//   }
//
//   late CircleEvent _circleEvent;
//
//   _setEventDateTime(DateTime startDate, DateTime endDate) {
//     _circleEvent = CircleEvent(
//         respondents: [],
//         encryptedLineItems: [],
//         startDate: startDate,
//         endDate: endDate);
//   }
//
//   void _createEvent() async {
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(_selectedNetworks[0]);
//
//     try {
//       int dateInc = _increment != null ? _increment! + 1 : 0;
//       var circleEvent = await Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (context) => CircleEventDetail(
//                   circleObject:
//                       CircleObject(ratchetIndexes: [], event: _circleEvent),
//                   circleObjectBloc: widget.circleObjectBloc,
//                   userFurnaces: _wallNetworks,
//                   userFurnace: _selectedNetworks[0],
//                   userCircleCache: userCircleCache,
//                   replyObject: null,
//                   fromCentralCalendar: true,
//                   scheduledFor: null,
//                   isWall: true,
//                   increment: dateInc,
//                 )),
//       ); //.then(_circleObjectBloc.requestNewerThan(
//
//       if (circleEvent != null) {
//         for (UserFurnace selectedNetwork in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(selectedNetwork);
//
//           CircleEvent newEvent = CircleEvent.deepCopy(circleEvent);
//
//           _circleEventBloc.createEvent(
//               widget.circleObjectBloc,
//               userCircleCache,
//               newEvent,
//               selectedNetwork,
//               widget.globalEventBloc,
//               null,
//               null,
//               null);
//         }
//       }
//     } catch (err, trace) {
//       LogBloc.insertError(err, trace);
//       debugPrint('InsideCircle._scheduleEvent: $err');
//     }
//   }
//
//   void _createRecipe() async {
//     int dateInc = _increment != null ? _increment! + 1 : 0;
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(_selectedNetworks[0]);
//
//     CircleObject? circleObject = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => CircleRecipeScreen(
//                 userFurnaces: _wallNetworks,
//                 userFurnace: _selectedNetworks[0],
//                 screenMode: ScreenMode.ADD,
//                 userCircleCache: userCircleCache,
//                 circleRecipeBloc: widget.circleRecipeBloc,
//                 globalEventBloc: widget.globalEventBloc,
//                 circleObjectBloc: widget.circleObjectBloc,
//                 timer: CircleDisappearingTimer.OFF,
//                 scheduledFor: null,
//                 increment: dateInc,
//                 replyObject: null,
//                 wall: true,
//               )),
//     );
//
//     if (circleObject != null) {
//       for (UserFurnace selectedNetwork in _selectedNetworks) {
//         UserCircleCache userCircleCache =
//             _getUserCircleCacheFromFurnace(selectedNetwork);
//
//         CircleObject newPost =
//             await _prepNewCircleObject('', userCircleCache, selectedNetwork);
//         newPost.type = CircleObjectType.CIRCLERECIPE;
//         newPost.recipe = CircleRecipe();
//         newPost.recipe!.ingestDeepCopy(circleObject.recipe!);
//         newPost.body = newPost.recipe!.name!;
//
//         widget.circleRecipeBloc.create(
//             userCircleCache, circleObject, selectedNetwork, false, false);
//       }
//     }
//   }
//
//   void _pickFiles() async {
//     try {
//       setState(() {
//         _showSpinner = true;
//       });
//
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//           allowMultiple: true,
//           type: FileType.custom,
//           allowedExtensions: ALLOWED_FILE_TYPES);
//
//       if (result != null && result.files.isNotEmpty) {
//         MediaCollection mediaCollection = MediaCollection();
//         await mediaCollection.populateFromFilePicker(
//             result.files, MediaType.file);
//
//         if (mediaCollection.isNotEmpty) {
//           _previewMedia(mediaCollection);
//
//           setState(() {
//             _showSpinner = false;
//           });
//         }
//       }
//
//       return;
//     } catch (err, trace) {
//       setState(() {
//         _showSpinner = false;
//       });
//
//       if (err.toString().contains('photo_access_denied')) {
//         Permissions.askOpenSettings(context);
//       } else {
//         LogBloc.insertError(err, trace);
//         debugPrint('_selectImage: $err');
//       }
//     }
//   }
//
//   void _pickImagesAndVideos() async {
//     try {
//       setState(() {
//         _showSpinner = true;
//       });
//
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.media,
//       );
//       if (result != null && result.files.isNotEmpty) {
//         MediaCollection mediaCollection = MediaCollection();
//         await mediaCollection.populateFromFilePicker(
//             result.files, MediaType.image);
//
//         _previewMedia(mediaCollection);
//
//         setState(() {
//           _showSpinner = false;
//         });
//
//         return;
//       }
//     } catch (err, trace) {
//       setState(() {
//         _showSpinner = false;
//       });
//
//       if (err.toString().contains('photo_access_denied')) {
//         Permissions.askOpenSettings(context);
//       } else {
//         LogBloc.insertError(err, trace);
//         debugPrint('_selectImage: $err');
//       }
//     }
//   }
//
//   _postSelectedFromGallery(List<CircleObject> selected) async {
//     MediaCollection mediaCollection = MediaCollection();
//
//     mediaCollection.populateFromCircleObjects(selected);
//
//     _previewMedia(mediaCollection);
//   }
//
//   SelectedMedia? selectedImages;
//
//   _previewMedia(MediaCollection mediaCollection, {Function? redo}) async {
//     selectedImages = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ImagePreviewer(
//             hiRes: false,
//             streamable: false,
//             circleImageBloc: widget.circleImageBloc,
//             media: mediaCollection,
//             wall: true,
//             userFurnaces: _wallNetworks,
//             selectedNetworks: _selectedNetworks,
//             setNetworks: _setNetworkFilter,
//             redo: redo,
//           ),
//         ));
//
//     if (selectedImages == null) return;
//     _closePanel();
//
//     for (UserFurnace selectedNetwork in _selectedNetworks) {
//       UserCircleCache userCircleCache =
//           _getUserCircleCacheFromFurnace(selectedNetwork);
//
//       debugPrint(
//           'InsideCircle._previewMedia: network userid: ${selectedNetwork.userid!}, userCircleCache: ${userCircleCache.usercircle!}, circle: ${userCircleCache.circle!}');
//
//       CircleObject newPost =
//           await _prepNewCircleObject('', userCircleCache, selectedNetwork);
//       widget.send(
//           vaultObject: newPost,
//           mediaCollection: selectedImages!.mediaCollection,
//           overrideButton: true);
//     }
//   }
//
//   _searchGiphy() async {
//     GiphyOption? giphyOption = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => SelectGif(
//                 refresh: _refresh,
//               )),
//     ); //.then(_circleObjectBloc.requestNewerThan(
//
//     if (giphyOption != null) {
//       MediaCollection mediaCollection = MediaCollection();
//
//       mediaCollection.populateFromGiphyOption(giphyOption);
//
//       _previewMedia(mediaCollection);
//     }
//   }
//
//   Future<void> _refresh() async {
//     setState(() {});
//   }
//
//   _closePanel() {
//     if (SlidingUpPanelStatus.expanded == panelController.status) {
//       widget.globalEventBloc.broadcastClear();
//       panelController.collapse();
//
//       setState(() {
//         _expanded = false;
//       });
//     }
//
//     if (_itemScrollController.isAttached) {
//       _itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: _scrollDuration),
//           curve: Curves.easeInOutCubic);
//     }
//   }
//
//   _captureMedia() async {
//     try {
//       CapturedMediaResults? results = await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CaptureMedia()),
//       );
//
//       if (results != null) {
//         for (Media media in results.mediaCollection.media) {
//           if (media.mediaType == MediaType.video) {
//             media.thumbnail =
//                 (await VideoCacheService.cacheTempVideoPreview(media.path, 0))
//                     .path;
//           }
//         }
//
//         if (results.isShrunk) {
//           debugPrint('RBR WTF is this for?');
//           /*SelectedMedia selectedImages = SelectedMedia(
//               hiRes: true,
//               streamable: false,
//               mediaCollection: results.mediaCollection);
//           if (selectedImages.mediaCollection.media.isNotEmpty) {
//             _previewSelectedMedia(selectedImages);
//           }*/
//         } else {
//           _previewMedia(results.mediaCollection, redo: _captureMedia);
//         }
//       }
//     } catch (err, trace) {
//       LogBloc.insertError(err, trace);
//       debugPrint('InsideCircle._captureMedia: $err');
//     }
//   }
// }
