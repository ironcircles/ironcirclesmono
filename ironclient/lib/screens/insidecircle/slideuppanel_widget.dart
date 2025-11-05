// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/circleevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlevote_bloc.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
// import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
// import 'package:ironcirclesapp/models/circlefile.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_detail.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_new.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreen.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlevote_new.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/imagepreviewer.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/selectgif.dart';
// import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/subtype_credential.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidewall_determine_widget.dart';
// import 'package:ironcirclesapp/screens/library/library.dart';
// import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_generate.dart';
// import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
// import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
// import 'package:ironcirclesapp/screens/widgets/extendedfab.dart';
// import 'package:ironcirclesapp/screens/widgets/ictext.dart';
// import 'package:ironcirclesapp/services/cache/videocache_service.dart';
// import 'package:ironcirclesapp/services/tenor_service.dart';
// import 'package:ironcirclesapp/utils/emojiutil.dart';
// import 'package:ironcirclesapp/utils/permissions.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//
// class SlideUpPanelWidget extends StatefulWidget {
//   //final UserCircleCache userCircleCache;
//   //final UserFurnace userFurnace;
//   final List<UserFurnace> wallFurnaces;
//   final List<UserFurnace> allFurnaces;
//   final List<UserCircleCache> userCircleCaches;
//   //final Circle circle;
//   final List<CircleObject> circleObjects;
//   final Future<void> Function() refresh;
//   final bool Function(ScrollEndNotification) onNotification;
//
//   ///final int index;
//   final Function clear;
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
//   final CircleVoteBloc circleVoteBloc;
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
//   final int objectsLength;
//   final Color tabBackgroundColor;
//   final Function scrollToIndex;
//   final Function reload;
//   final double maxWidth;
//   final bool feed;
//   final UserFurnace userFurnace;
//   final ItemScrollController itemScrollController;
//   final ItemPositionsListener itemPositionsListener;
//   final bool scrollingDown;
//   final bool wall;
//   final Function collapse;
//   final bool firstTimeLoadComplete;
//   final List<CircleObject> crossObjects;
//   final int timer;
//   final Function setTimer;
//   final Function setScheduled;
//
//   const SlideUpPanelWidget({
//     Key? key,
//     required this.clear,
//     required this.members,
//     required this.reverse,
//     required this.feed,
//     required this.scrollingDown,
//     required this.wall,
//     required this.crossObjects,
//     required this.timer,
//     required this.setTimer,
//     //required this.userCircleCache,
//     //required this.userFurnace,
//     required this.userFurnace,
//     required this.userCircleCaches,
//     required this.circleObjects,
//     required this.captureMedia,
//     required this.sendLink,
//     required this.wallFurnaces,
//     required this.allFurnaces,
//     required this.firstTimeLoadComplete,
//
//     //required this.selectVideos,
//     required this.onNotification,
//     required this.refresh,
//     required this.objectsLength,
//     required this.tabBackgroundColor,
//     required this.scrollToIndex,
//     required this.reload,
//     required this.maxWidth,
//     required this.itemScrollController,
//     required this.circleVoteBloc,
//     required this.itemPositionsListener,
//     required this.collapse,
//     required this.setScheduled,
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
//   State<SlideUpPanelWidget> createState() => _WallWidgetState();
// }
//
// class _WallWidgetState extends State<SlideUpPanelWidget> {
//   List<CircleObject> _selected = [];
//   final List<CircleObject> _waitingOnScroller = [];
//   // late ScrollController scrollController;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
//       GlobalKey<RefreshIndicatorState>();
//   static const int _scrollDuration = 250;
//   //bool _scrollingDown = false;
//   final List<UserFurnace> _wallNetworks = [];
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
//   double upperBound = 1;
//
//   String _message = '';
//
//   @override
//   void dispose() {
//     super.dispose();
//     panelController.dispose();
//   }
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
//         widget.wallFurnaces.where((element) => element.enableWall == true));
//
//     widget.globalEventBloc.refreshWall.listen((refresh) async {
//       if (mounted) {
//         setState(() {});
//       }
//     }, onError: (err) {
//       //_clearSpinner();
//       debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
//     }, cancelOnError: false);
//
//     widget.globalEventBloc.openSlidingPanel.listen((message) async {
//       _message = message;
//       if (mounted) {
//         panelController.expand();
//       }
//     }, onError: (err) {
//       //_clearSpinner();
//       debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
//     }, cancelOnError: false);
//
//     widget.globalEventBloc.openSlidingPanelWithShareTo.listen(
//         (sharedMediaHolder) async {
//       _message = sharedMediaHolder.message;
//
//       if (mounted) {
//         panelController.expand();
//
//         ///null out the values so the share doesn't happen again
//         SharedMediaHolder copy = SharedMediaHolder(
//             sharedText: sharedMediaHolder.sharedText,
//             sharedMedia: sharedMediaHolder.sharedMedia,
//             sharedGif: sharedMediaHolder.sharedGif,
//             sharedVideo: sharedMediaHolder.sharedVideo,
//             message: sharedMediaHolder.message);
//         sharedMediaHolder.clear();
//
//         if (copy.sharedMedia != null) {
//           Media first = copy.sharedMedia!.media[0];
//           if (first.mediaType == MediaType.recipe ||
//               first.mediaType == MediaType.credential ||
//               first.mediaType == MediaType.list ||
//               first.mediaType == MediaType.event) {
//             _selected.clear();
//             _selected.add(copy.sharedMedia!.media[0].object!);
//
//             if (first.mediaType == MediaType.recipe) {
//               _selected[0].type = CircleObjectType.CIRCLERECIPE;
//             } else if (first.mediaType == MediaType.credential) {
//               _selected[0].type = CircleObjectType.CIRCLECREDENTIAL;
//               _selected[0].subType = SubType.LOGIN_INFO;
//             } else if (first.mediaType == MediaType.list) {
//               _selected[0].type = CircleObjectType.CIRCLELIST;
//             } else if (first.mediaType == MediaType.event) {
//               _selected[0].type = CircleObjectType.CIRCLEEVENT;
//             }
//             _post();
//           } else {
//             _previewMedia(copy.sharedMedia!);
//           }
//         }
//       }
//     }, onError: (err) {
//       //_clearSpinner();
//       debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
//     }, cancelOnError: false);
//
//     widget.globalEventBloc.closeSlidingPanel.listen((value) async {
//       if (mounted) {
//         if (value == false) widget.collapse();
//         _closePanel(rebroadcast: value);
//       }
//     }, onError: (err) {
//       //_clearSpinner();
//       debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
//     }, cancelOnError: false);
//
//     // scrollController = ScrollController();
//     // scrollController.addListener(() {
//     //   if (scrollController.offset >=
//     //           scrollController.position.maxScrollExtent &&
//     //       !scrollController.position.outOfRange) {
//     //     panelController.expand();
//     //   } else if (scrollController.offset <=
//     //           scrollController.position.minScrollExtent &&
//     //       !scrollController.position.outOfRange) {
//     //     panelController.anchor();
//     //   } else {}
//     // });
//
//     panelController.hide();
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width - 10;
//     double screenHeight = MediaQuery.of(context).size.height;
//
//     Stack makeChat = Stack(children: [
//       Container(
//           margin: const EdgeInsets.only(top: 0, left: 5.0, right: 5.0),
//           child: RefreshIndicator(
//               key: _refreshIndicatorKey,
//               onRefresh: _refresh,
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
//                           reverse: true,
//                           itemScrollController: widget.itemScrollController,
//                           itemPositionsListener: widget.itemPositionsListener,
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
//
//                             return InsideCircleDetermineWidget(
//                               members: widget.members,
//                               //members: globalState.members,
//                               reverse: true,
//                               scrollToIndex: widget.scrollToIndex,
//                               userCircleCache: widget.userCircleCaches[0],
//                               userFurnace: widget.userFurnace,
//                               circleObjects: widget.circleObjects,
//                               index: index,
//                               refresh: widget.reload,
//                               circle: widget.userCircleCaches[0].cachedCircle!,
//                               shareObject: widget.shareObject,
//                               unpinObject: widget.unpinObject,
//                               openExternalBrowser: widget.openExternalBrowser,
//                               leave: widget.leave,
//                               export: widget.export,
//                               cancelTransfer: widget.cancelTransfer,
//                               longPressHandler: widget.longPressHandler,
//                               longReaction: widget.longReaction,
//                               shortReaction: widget.shortReaction,
//                               tapHandler: widget.tapHandler,
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
//                               maxWidth: widget.maxWidth,
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
//           : widget.scrollingDown
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
//
//     Stack makeFeed = Stack(children: [
//       Container(
//           margin:
//               const EdgeInsets.only(top: 0, left: 5.0, right: 5.0, bottom: 0),
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
//                           itemScrollController: widget.itemScrollController,
//                           itemPositionsListener: widget.itemPositionsListener,
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
//                               circle: widget.userCircleCaches.length == 1
//                                   ? widget.userCircleCaches[0].cachedCircle!
//                                   : item.userCircleCache!.cachedCircle!,
//
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
//                           ///Feed scroll is in reverse so this is an up arrow
//                           Icons.arrow_circle_up_rounded,
//                           size: 50,
//                           color: globalState.theme.buttonIcon,
//                         ),
//                         ICText(
//                           ' new messages',
//                           color: globalState.theme.buttonIcon,
//                         )
//                       ])))
//           : widget.scrollingDown
//               ? Align(
//                   alignment: Alignment.bottomCenter,
//                   child: InkWell(
//                       onTap: () {
//                         _addNewAndScrollToBottom();
//                       },
//                       child: Icon(
//                         ///Feed scroll is in reverse so this is an up arrow
//                         Icons.arrow_circle_up_rounded,
//                         size: 50,
//                         color: globalState.theme.buttonIcon,
//                       )))
//               : Container()
//     ]);
//
//     final media = ExtendedFAB(
//       label: 'From device',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//
//     final file = ExtendedFAB(
//       label: 'New file',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//
//     /*final link = ExtendedFAB(
//       label: 'New link',
//       onPressed: _post,
//       icon: Icons.add,
//     );*/
//
//     final recipe = ExtendedFAB(
//       label: 'New recipe',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//
//     final calendar = ExtendedFAB(
//       label: 'New event',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//     final credential = ExtendedFAB(
//       label: 'New credential',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//     final list = ExtendedFAB(
//       label: 'New list',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//     final vote = ExtendedFAB(
//       label: 'New vote',
//       color: globalState.theme.libraryFAB,
//       onPressed: _post,
//       icon: Icons.add,
//     );
//
//     final generate = Padding(
//         padding: const EdgeInsets.only(right: 10, bottom: 10),
//         child: InkWell(
//             onTap: _generate,
//             child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8.0),
//                   color:Colors.blue[200]!.withOpacity(.8),
//                 ),
//                 child: Center(
//                   child: Container(
//                       width: 26,
//                       height: 26,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(4.0),
//                         color: Colors.white,
//                       ),
//                       child: Center(
//                           child: ICText(
//                         'AI',
//                         fontSize: 10,
//                         fontWeight: FontWeight.w800,
//                         color: Colors.grey[500],
//                       ))),
//                 ))));
//
//     final camera = InkWell(
//         onTap: _captureMedia,
//         child: Padding(
//             padding: const EdgeInsets.only(right: 10, bottom: 10),
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8.0),
//                 color: Colors.grey.withOpacity(0.85),
//               ),
//               child: const Center(
//                 child: Icon(
//                   Icons.camera_alt,
//                   size: 34,
//                   color: Colors.white,
//                 ),
//               ),
//             )));
//
//     final gif = InkWell(
//         onTap: _searchGiphy,
//         child: Padding(
//             padding: const EdgeInsets.only(right: 10, bottom: 10),
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8.0),
//                 color: Colors.grey.withOpacity(0.85),
//               ),
//               child: const Center(
//                 child: Icon(
//                   Icons.gif_box,
//                   size: 34,
//                   color: Colors.white,
//                 ),
//               ),
//             )));
//
//     return Stack(
//       children: [
//         widget.circleObjects.isEmpty &&
//                 widget.feed &&
//                 widget.firstTimeLoadComplete
//             ? const Column(
//                 children: [
//                   Expanded(child: Center(child: ICText('No Content')))
//                 ],
//               )
//             : widget.feed
//                 ? makeFeed
//                 : makeChat,
//         SlidingUpPanelWidget(
//             panelStatus: SlidingUpPanelStatus.hidden,
//             controlHeight: panelController.status == SlidingUpPanelStatus.hidden
//                 ? 0
//                 : 65.0,
//             anchor: .5,
//             minimumBound: minBound,
//             upperBound: upperBound,
//             panelController: panelController,
//             onTap: () {
//               debugPrint('onTap:  ${panelController.status}');
//
//               ///Customize the processing logic
//               if (panelController.status == SlidingUpPanelStatus.expanded) {
//                 widget.collapse();
//                 _closePanel(rebroadcast: false);
//               } else {
//                 panelController.expand();
//               }
//             },
//             enableOnTap: false,
//             //Enable the onTap callback for control bar.
//             dragDown: (details) {
//               debugPrint('dragDown: ${panelController.status}');
//             },
//             dragStart: (details) {
//               debugPrint('dragStart');
//             },
//             dragCancel: () {
//               debugPrint('dragCancel:  ${panelController.status}');
//             },
//             dragUpdate: (details) {
//               debugPrint(
//                   'dragUpdate,${panelController.status == SlidingUpPanelStatus.dragging ? 'dragging' : ''}');
//             },
//             dragEnd: (details) {
//               debugPrint('dragEnd: ${panelController.status}');
//               //debugPrint('dragEnd: ${panelController.value}');
//               if (panelController.status == SlidingUpPanelStatus.collapsed) {
//                 widget.collapse();
//                 _closePanel(rebroadcast: false);
//               }
//             },
//             child: Container(
//               //margin: const EdgeInsets.symmetric(horizontal: 15.0),
//               decoration: ShapeDecoration(
//                 color: widget.tabBackgroundColor,
//                 shadows: const [
//                   BoxShadow(
//                       blurRadius: 5.0,
//                       spreadRadius: 2.0,
//                       color: Color(0x11000000))
//                 ],
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(10.0),
//                     topRight: Radius.circular(10.0),
//                   ),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   InkWell(
//                       onTap: () {
//                         widget.collapse();
//                         _closePanel(rebroadcast: false);
//                       },
//                       child: Container(
//                         alignment: Alignment.center,
//                         height: 35.0,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: <Widget>[
//                             const Spacer(),
//                             Icon(
//                               Icons.drag_handle,
//                               color: globalState.theme.buttonIcon,
//                             ),
//                             const Spacer(),
//                           ],
//                         ),
//                       )),
//                   Divider(
//                     height: 0.5,
//                     color: globalState.theme.background.withOpacity(.2),
//                   ),
//                   Flexible(
//                       child: Stack(children: [
//                     Container(
//                       color: globalState.theme.background.withOpacity(.2),
//                       child: LibraryScreen(
//                         //key: GlobalKey(),
//                         filteredFurnace: null,
//                         userFurnaces: widget.allFurnaces,
//                         refreshCallback: _doNothing,
//                         slideUpPanel: true,
//                         showFilter: false,
//                         updateSelected: _updateSelected,
//                         updateTab: _updateTab,
//                         setEventDateTime: _setEventDateTime,
//                         crossObjects: widget.crossObjects,
//                       ),
//                     ),
//                     Align(
//                         alignment: Alignment.bottomRight,
//                         child: _selected.isEmpty
//                             ? Padding(
//                                 padding: const EdgeInsets.only(
//                                     bottom: 21, right: 10),
//                                 child:
//                                     _selectedTab == SelectedLibraryTab.gallery
//                                         ? Row(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.end,
//                                             children: [
//                                                 const Padding(
//                                                   padding:
//                                                       EdgeInsets.only(left: 17),
//                                                 ),
//                                                 camera,
//                                                 gif,
//                                                 generate,
//                                                 const Spacer(),
//                                                 media
//                                               ])
//                                         : Row(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.end,
//                                             children: [
//                                                 _selectedTab ==
//                                                         SelectedLibraryTab.files
//                                                     ? file
//                                                     : _selectedTab ==
//                                                             SelectedLibraryTab
//                                                                 .recipes
//                                                         ? recipe
//                                                         : _selectedTab ==
//                                                                 SelectedLibraryTab
//                                                                     .links
//                                                             ? Container() //link
//                                                             : _selectedTab ==
//                                                                     SelectedLibraryTab
//                                                                         .events
//                                                                 ? calendar
//                                                                 : _selectedTab ==
//                                                                         SelectedLibraryTab
//                                                                             .credentials
//                                                                     ? credential
//                                                                     : _selectedTab ==
//                                                                             SelectedLibraryTab
//                                                                                 .lists
//                                                                         ? list
//                                                                         : _selectedTab ==
//                                                                                 SelectedLibraryTab.votes
//                                                                             ? vote
//                                                                             : Container(),
//                                               ]))
//                             : Padding(
//                                 padding: const EdgeInsets.only(
//                                     bottom: 21, right: 10),
//                                 child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       ExtendedFAB(
//                                         color: globalState.theme.libraryFAB,
//                                         label: _getButtonText(),
//                                         onPressed: _post,
//                                         icon: Icons.add,
//                                       ),
//                                       // GradientButtonDynamic(
//                                       //   onPressed: _post,
//                                       //   text: _getButtonText(),
//                                       //   //opacity: .9,
//                                       //   color: globalState.theme.button,
//                                       //   //textColor: globalState.theme.buttonText,
//                                       // )
//                                     ]))),
//                   ])),
//                 ],
//               ),
//             ))
//       ],
//     );
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
//         case SelectedLibraryTab.lists:
//           return 'New List';
//         case SelectedLibraryTab.votes:
//           return 'New Vote';
//       }
//     } else {
//       switch (_selectedTab) {
//         case SelectedLibraryTab.gallery:
//           return 'Preview Selection (${_selected.length})';
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
//         case SelectedLibraryTab.lists:
//           return 'Post Selected List';
//         case SelectedLibraryTab.votes:
//           return 'Post Selected Vote';
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
//   _setSelectedNetworks(List<UserFurnace> newlySelectedNetworks) {
//     _selectedNetworks.clear();
//     _selectedNetworks.addAll(newlySelectedNetworks);
//   }
//
//   _selectNetworks(Function callback) async {
//     if (widget.wall == false) {
//       _selectedNetworks = [widget.userFurnace];
//       _selectNetworkCallback(_selectedNetworks);
//     } else if (_wallNetworks.length == 1) {
//       _selectedNetworks = _wallNetworks;
//       _selectNetworkCallback(_selectedNetworks);
//     } else {
//       ///clear the selected networks
//       _selectedNetworks.clear();
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
//
//     if (_selectedNetworks.isNotEmpty) {
//       _closePanel(rebroadcast: true);
//
//       ///copy and clear the selected list
//       _selectedCopy = List.from(_selected);
//       _selected.clear();
//
//       ///scroll the library widget to the top
//       widget.globalEventBloc.broadcastScrollLibraryToTop();
//     } else {
//       return;
//     }
//
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
//           widget.send(
//               vaultObject: newPost,
//               overrideButton: true,
//               message: _selectedCopy[0].link!.url);
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
//       case CircleObjectType.CIRCLELIST:
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, userFurnace);
//           newPost.type = CircleObjectType.CIRCLELIST;
//           newPost.list = CircleList.deepCopy(_selectedCopy[0].list!);
//
//           widget.circleListBloc.createList(userCircleCache, newPost, true,
//               userFurnace, widget.globalEventBloc);
//         }
//         break;
//       case CircleObjectType.CIRCLEVOTE:
//         for (UserFurnace userFurnace in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(userFurnace);
//           CircleVote? circleVote = CircleVote.deepCopy(_selectedCopy[0].vote!);
//
//           if (circleVote != null) {
//             widget.circleVoteBloc.createVote(userCircleCache, circleVote,
//                 userFurnace, null, null, userCircleCache.cachedCircle!, null);
//           }
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
//     if (widget.itemScrollController.isAttached) {
//       widget.itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: _scrollDuration),
//           curve: Curves.easeInOutCubic);
//     }
//
//     if (_selected.isNotEmpty) {
//       switch (_selected[0].type!) {
//         case CircleObjectType.CIRCLEIMAGE:
//         case CircleObjectType.CIRCLEVIDEO:
//         case CircleObjectType.CIRCLEGIF:
//         case CircleObjectType.CIRCLEFILE:
//
//           ///copy and clear the selected list
//           _selectedCopy = List.from(_selected);
//           _selected.clear();
//
//           ///scroll the library widget to the top
//           widget.globalEventBloc.broadcastScrollLibraryToTop();
//           _postSelectedFromGallery(_selectedCopy);
//           break;
//         case CircleObjectType.CIRCLELINK:
//         case CircleObjectType.CIRCLERECIPE:
//         case CircleObjectType.CIRCLECREDENTIAL:
//         case CircleObjectType.CIRCLELIST:
//         case CircleObjectType.CIRCLEVOTE:
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
//         case SelectedLibraryTab.lists:
//           _createList();
//           break;
//         case SelectedLibraryTab.votes:
//           _createVote();
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
//     } else if (widget.itemScrollController.isAttached &&
//         widget.circleObjects.isNotEmpty) {
//       widget.itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: _scrollDuration),
//           curve: Curves.easeInOutCubic);
//     }
//   }
//
//   int? _increment;
//
//   _createSubtypeCredential() async {
//     UserFurnace stageFurnace = getStageFurnace();
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(stageFurnace);
//
//     CircleObject? circleObject = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => SubtypeCredential(
//                 //userFurnaces: widget.userFurnaces,
//                 globalEventBloc: widget.globalEventBloc,
//                 circleObjectBloc: widget.circleObjectBloc,
//                 userCircleCache: userCircleCache,
//                 setNetworks: _setSelectedNetworks,
//                 userFurnace: stageFurnace,
//                 userCircleBloc: widget.userCircleBloc,
//                 screenMode: ScreenMode.ADD,
//                 timer: CircleDisappearingTimer.OFF,
//                 scheduledFor: null,
//                 replyObject: null,
//                 wall: widget.wall,
//                 userFurnaces: _wallNetworks,
//                 //circleRecipeBloc: _circleRecipeBloc,
//               )),
//     );
//
//     if (circleObject != null) {
//       if (SlidingUpPanelStatus.expanded == panelController.status) {
//         _closePanel(rebroadcast: true);
//       }
//
//       ///scroll the library widget to the top
//       widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//       if (widget.wall) {
//         for (UserFurnace selectedNetwork in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(selectedNetwork);
//
//           CircleObject newPost = await _prepNewCircleObject(
//               '', userCircleCache, selectedNetwork,
//               skipBody: true);
//
//           newPost.userFurnace = selectedNetwork;
//           newPost.userCircleCache = userCircleCache;
//
//           newPost.type = CircleObjectType.CIRCLECREDENTIAL;
//           newPost.subType = SubType.LOGIN_INFO;
//           newPost.subString1 = circleObject.subString1;
//           newPost.subString2 = circleObject.subString2;
//           newPost.subString3 = circleObject.subString3;
//           newPost.subString4 = circleObject.subString4;
//
//           widget.circleObjectBloc.saveCircleObject(
//             widget.globalEventBloc,
//             selectedNetwork,
//             userCircleCache,
//             newPost,
//           );
//         }
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
//     UserFurnace stageFurnace = getStageFurnace();
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(stageFurnace);
//
//     try {
//       int dateInc = _increment != null ? _increment! + 1 : 0;
//
//       ///create an new instance in the event the user posts one after the other, clears out non date fields
//       _circleEvent = CircleEvent(
//           respondents: [],
//           encryptedLineItems: [],
//           startDate: _circleEvent.startDate,
//           endDate: _circleEvent.endDate);
//
//       var circleEvent = await Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (context) => CircleEventDetail(
//                   circleObject:
//                       CircleObject(ratchetIndexes: [], event: _circleEvent),
//                   circleObjectBloc: widget.circleObjectBloc,
//                   userFurnaces:
//                       widget.wall ? _wallNetworks : [widget.userFurnace],
//                   userFurnace: stageFurnace,
//                   userCircleCache: userCircleCache,
//                   setNetworks: _setSelectedNetworks,
//                   replyObject: null,
//                   fromCentralCalendar: true,
//                   scheduledFor: null,
//                   wall: widget.wall,
//                   increment: dateInc,
//                 )),
//       ); //.then(_circleObjectBloc.requestNewerThan(
//
//       if (circleEvent != null) {
//         if (SlidingUpPanelStatus.expanded == panelController.status) {
//           _closePanel(rebroadcast: true);
//         }
//
//         ///scroll the library widget to the top
//         widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//         if (widget.wall) {
//           for (UserFurnace selectedNetwork in _selectedNetworks) {
//             UserCircleCache userCircleCache =
//                 _getUserCircleCacheFromFurnace(selectedNetwork);
//
//             CircleEvent newEvent = CircleEvent.deepCopy(circleEvent);
//
//             _circleEventBloc.createEvent(
//                 widget.circleObjectBloc,
//                 userCircleCache,
//                 newEvent,
//                 selectedNetwork,
//                 widget.globalEventBloc,
//                 null,
//                 null,
//                 null);
//           }
//         }
//       }
//     } catch (err, trace) {
//       LogBloc.insertError(err, trace);
//       debugPrint('InsideCircle._scheduleEvent: $err');
//     }
//   }
//
//   UserFurnace getStageFurnace() {
//     late UserFurnace furnace;
//
//     if (widget.wall == false) {
//       furnace = widget.userFurnace;
//     } else if (_selectedNetworks.isNotEmpty) {
//       ///default to the auth furnace if it is wall enabled
//       int index =
//           _selectedNetworks.indexWhere((element) => element.authServer == true);
//
//       if (index != -1) {
//         furnace = _selectedNetworks[index];
//       } else {
//         furnace = _selectedNetworks[0];
//       }
//     } else {
//       furnace = widget.userFurnace;
//     }
//
//     return furnace;
//   }
//
//   void _createVote() async {
//     int dateInc = _increment != null ? _increment! + 1 : 0;
//
//     UserFurnace stageFurnace = getStageFurnace();
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(stageFurnace);
//
//     CircleVote? circleVote = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => NewVote(
//                 userCircleCache: userCircleCache,
//                 userFurnaces: _wallNetworks,
//                 userFurnace: stageFurnace,
//                 timer: CircleDisappearingTimer.OFF,
//                 circleVoteBloc: widget.circleVoteBloc,
//                 scheduledFor: null,
//                 circle: userCircleCache.cachedCircle!,
//                 increment: dateInc,
//                 setNetworks: _setSelectedNetworks,
//                 wall: widget.wall,
//               )),
//     );
//
//     if (circleVote != null) {
//       if (SlidingUpPanelStatus.expanded == panelController.status) {
//         _closePanel(rebroadcast: true);
//       }
//
//       ///scroll the library widget to the top
//       widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//       if (widget.wall) {
//         for (UserFurnace selectedNetwork in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(selectedNetwork);
//
//           // CircleVote circleVote = circleObject.vote!;
//
//           widget.circleVoteBloc.createVote(userCircleCache, circleVote,
//               selectedNetwork, null, null, userCircleCache.cachedCircle!, null);
//         }
//       }
//     }
//   }
//
//   void _createList() async {
//     int dateInc = _increment != null ? _increment! + 1 : 0;
//
//     UserFurnace stageFurnace = getStageFurnace();
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(stageFurnace);
//
//     CircleObject? circleObject = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => CircleListNew(
//                 circleListBloc: widget.circleListBloc,
//                 increment: dateInc,
//                 userFurnaces: _wallNetworks,
//                 userFurnace: stageFurnace,
//                 userCircleCache: userCircleCache,
//                 setNetworks: _setSelectedNetworks,
//                 //globalEventBloc: widget.globalEventBloc,
//                 circleObjectBloc: widget.circleObjectBloc,
//                 timer: CircleDisappearingTimer.OFF,
//                 scheduledFor: null,
//                 replyObject: null,
//                 wall: widget.wall,
//               )),
//     );
//
//     if (circleObject != null) {
//       if (SlidingUpPanelStatus.expanded == panelController.status) {
//         _closePanel(rebroadcast: true);
//       }
//
//       ///scroll the library widget to the top
//       widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//       if (widget.wall) {
//         for (UserFurnace selectedNetwork in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(selectedNetwork);
//
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, selectedNetwork);
//           newPost.type = CircleObjectType.CIRCLELIST;
//           newPost.list = CircleList.deepCopy(circleObject.list!);
//
//           widget.circleListBloc.createList(userCircleCache, newPost, true,
//               selectedNetwork, widget.globalEventBloc);
//         }
//       }
//     }
//   }
//
//   void _createRecipe() async {
//     int dateInc = _increment != null ? _increment! + 1 : 0;
//
//     UserFurnace stageFurnace = getStageFurnace();
//
//     UserCircleCache userCircleCache =
//         _getUserCircleCacheFromFurnace(stageFurnace);
//
//     CircleObject? circleObject = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => CircleRecipeScreen(
//                 userFurnaces:
//                     widget.wall ? _wallNetworks : [widget.userFurnace],
//                 userFurnace: stageFurnace,
//                 screenMode: ScreenMode.ADD,
//                 userCircleCache: userCircleCache,
//                 circleRecipeBloc: widget.circleRecipeBloc,
//                 setNetworks: _setSelectedNetworks,
//                 globalEventBloc: widget.globalEventBloc,
//                 circleObjectBloc: widget.circleObjectBloc,
//                 timer: CircleDisappearingTimer.OFF,
//                 scheduledFor: null,
//                 increment: dateInc,
//                 replyObject: null,
//                 wall: widget.wall,
//               )),
//     );
//
//     if (circleObject != null) {
//       if (SlidingUpPanelStatus.expanded == panelController.status) {
//         _closePanel(rebroadcast: true);
//       }
//
//       ///scroll the library widget to the top
//       widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//       if (widget.wall) {
//         for (UserFurnace selectedNetwork in _selectedNetworks) {
//           UserCircleCache userCircleCache =
//               _getUserCircleCacheFromFurnace(selectedNetwork);
//
//           CircleObject newPost =
//               await _prepNewCircleObject('', userCircleCache, selectedNetwork);
//           newPost.type = CircleObjectType.CIRCLERECIPE;
//           newPost.recipe = CircleRecipe();
//           newPost.recipe!.ingestDeepCopy(circleObject.recipe!);
//           newPost.body = newPost.recipe!.name!;
//
//           widget.circleRecipeBloc
//               .create(userCircleCache, newPost, selectedNetwork, false, false);
//         }
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
//         ///scroll the library widget to the top
//         widget.globalEventBloc.broadcastScrollLibraryToTop();
//
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
//     if (widget.wall == false || widget.wallFurnaces.length == 1) {
//       _selectedNetworks.clear();
//       _selectedNetworks.add(widget.userFurnace);
//     }
//
//     selectedImages = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ImagePreviewer(
//               caption: _message,
//               hiRes: false,
//               streamable: false,
//               setScheduled: widget.setScheduled,
//               timer: widget.timer,
//               setTimer: widget.setTimer,
//               media: mediaCollection,
//               showCaption: true,
//               wall: widget.wall,
//               userFurnaces: widget.wall ? _wallNetworks : [widget.userFurnace],
//               //selectedNetworks: _selectedNetworks,
//               setNetworks: _setSelectedNetworks,
//               redo: redo,
//               screenName: widget.wall
//                   ? "Feed"
//                   : _getUserCircleCacheFromFurnace(widget.userFurnace)
//                       .prefName),
//         ));
//
//     if (selectedImages == null ||
//         selectedImages!.mediaCollection.media.isEmpty) {
//       return;
//     } else {
//       _postMedia();
//     }
//   }
//
//   _postMedia() async {
//     ///scroll the library widget to the top
//     widget.globalEventBloc.broadcastScrollLibraryToTop();
//
//     _closePanel(rebroadcast: true);
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
//           overrideButton: true,
//           message: selectedImages!.caption,
//           hiRes: selectedImages!.hiRes,
//           streamable: selectedImages!.streamable);
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
//   _closePanel({bool rebroadcast = true}) {
//     //if (SlidingUpPanelStatus.expanded == panelController.status) {
//     if (widget.itemScrollController.isAttached) {
//       widget.itemScrollController.scrollTo(
//           index: 0,
//           duration: const Duration(milliseconds: 1),
//           curve: Curves.easeInOutCubic);
//     }
//
//     panelController.collapse();
//     panelController.hide();
//     if (rebroadcast) {
//       widget.clear();
//       widget.globalEventBloc.broadcastClear();
//     }
//
//     // }
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
//
//   _generate() async {
//     if (widget.wall == false || widget.wallFurnaces.length == 1) {
//       _selectedNetworks.clear();
//       _selectedNetworks.add(widget.userFurnace);
//     }
//
//     selectedImages = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => StableDiffusionWidget(
//               userFurnace: widget.userFurnace,
//               previewScreenName: widget.userCircleCaches.length == 1
//                   ? widget.userCircleCaches[0].prefName!
//                   : 'Network Feed',
//               wall: widget.wall,
//               userFurnaces: widget.wall ? _wallNetworks : [widget.userFurnace],
//               //selectedNetworks: _selectedNetworks,
//               setNetworks: _setSelectedNetworks,
//               //redo: widget.redo,
//               imageGenType: ImageType.image),
//         ));
//
//     if (selectedImages != null) {
//       _postMedia();
//     }
//   }
// }
