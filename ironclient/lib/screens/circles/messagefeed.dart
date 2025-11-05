/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/screens/circles/messagefeed_usercircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_static/membercolors.dart';
import 'package:ironcirclesapp/screens/insidecircle/processcircleobjectevents.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:provider/provider.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:ironcirclesapp/models/export_models.dart';

///Purpose: This screen is a feed of messages from every open circle
///User can select one, which will open the circle and scroll to the object

///This is a stateful class, meaning in can listen for events and refresh
class MessageFeed extends StatefulWidget {
  final List<UserCircleCache> userCircleCaches;

  ///User's instance of the current Circle
  final List<UserFurnace> userFurnaces;

  ///The Furnace this Circle is connected to
  final CircleObjectBloc circleObjectBloc;
  final GlobalEventBloc globalEventBloc;
  final UserCircleBloc userCircleBloc;
  final Function removeBadge;
  final Function refresh;
  final Function goInside;
  final double iconSize;
  final double floatingActionSize;
  final List<CircleObject> unreadObjects;
  final List<CircleObject> markedReadObjects;

  MessageFeed(
      {Key? key,
      required this.userCircleCaches,
      required this.userFurnaces,
      required this.circleObjectBloc,
      required this.userCircleBloc,
      required this.globalEventBloc,
      required this.removeBadge,
      required this.refresh,
      required this.goInside,
      required this.iconSize,
      required this.floatingActionSize,
      required this.unreadObjects,
      required this.markedReadObjects})
      : super(key: key);

  _MessageFeedState createState() => _MessageFeedState();
}

///The state class that does all the work
class _MessageFeedState extends State<MessageFeed> {
  final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();
  final GlobalKey<RefreshIndicatorState> _refreshIndicator =
      GlobalKey<RefreshIndicatorState>();
  late CircleImageBloc _circleImageBloc;
  late CircleVideoBloc _circleVideoBloc;
  late CircleRecipeBloc _circleRecipeBloc;
  List<User> _userMessageColors = [];
  List<MemberCircle> _memberCircles = [];
  List<CircleObject> _circleObjects = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late FirebaseBloc _firebaseBloc;
  MemberCircleBloc _memberCircleBloc = MemberCircleBloc();

  ///spinner
  //bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  ///This function is called before the screen renders.
  ///It does not support await statements so the screen doesn't pause
  ///Instead, we subscribe to a stream and listen for the results.
  @override
  void initState() {
    ///make sure we call widget's own initState
    super.initState();
    handleAppLifecycleState();

    _circleObjects = widget.unreadObjects;

    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _circleImageBloc = CircleImageBloc(widget.globalEventBloc);
    _circleVideoBloc = CircleVideoBloc(widget.globalEventBloc);
    _circleRecipeBloc = CircleRecipeBloc(widget.globalEventBloc);

    _memberCircleBloc.loaded.listen((memberCircles) {
      if (memberCircles != _memberCircles)
        setState(() {
          _memberCircles = memberCircles;
        });
    });

    widget.globalEventBloc.refreshMessageFeed.listen((value) async {
      if (mounted) {
        setState(() {});
        //widget.refresh();
      }
    }, onError: (err) {
      debugPrint("MessageFeed._globalEventBloc.timerExpired: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        try {
          setState(() {
            if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
              ProcessCircleObjectEvents.putCircleVideo(
                  _circleObjects, circleObject, _circleVideoBloc);
            } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
              ProcessCircleObjectEvents.putCircleImage(
                  _circleObjects, circleObject, true);
            } else if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
              ProcessCircleObjectEvents.putCircleRecipe(
                  _circleObjects, circleObject);
            } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              ProcessCircleObjectEvents.putCircleAlbum(
                  _circleObjects, circleObject, true);
            }
          });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('InsideCircle._globalEventBloc.progressIndicator.listen: $err');
        }
      }
    }, onError: (err) {
      debugPrint("InsideCircle._globalEventBloc.progressIndicator.listen: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.progressThumbnailIndicator.listen((circleObject) {
      if (mounted) {
        try {
          setState(() {
            if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
              // ProcessCircleObjectEvents.putCircleVideo(
              //_circleobjects, circleObject, _circleVideoBloc);
            } else if (circleObject.type == CircleObjectType.CIRCLEIMAGE) {
              ProcessCircleObjectEvents.putCircleImage(
                  _circleObjects, circleObject, true);
            } else if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
              ProcessCircleObjectEvents.putCircleRecipe(
                  _circleObjects, circleObject);
            } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
              ProcessCircleObjectEvents.putCircleAlbum(
                  _circleObjects, circleObject, true);
            }
          });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('InsideCircle._globalEventBloc.progressIndicator.listen: $err');
        }
      }
    }, onError: (err) {
      debugPrint("InsideCircle._globalEventBloc.progressIndicator.listen: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.previewDownloaded.listen((object) {
      //find the circle object

      if (mounted) {
        try {
          CircleObject circleObject = _circleObjects.firstWhere(
              (element) => element.id == object.id,
              orElse: () => CircleObject(ratchetIndexes: []));

          if (circleObject.seed != null) {
            if (circleObject.type == CircleObjectType.CIRCLEVIDEO) {
              debugPrint('video preview listener hit');
              debugPrint(object.video!.videoState!);
              debugPrint(object.seed);
              setState(() {
                circleObject.video!.videoState = object.video!.videoState!;
              });
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('insidecircle listen _globalEvenBloc.previewDownloaded: $err');
        }
      }
    }, onError: (err) {
      debugPrint("CircleImageMemberWidget.initState: $err");
    }, cancelOnError: false);

    // _firebaseBloc = BlocProvider.of<FirebaseBloc>(context);

    ///call the function that will stream the results back (to the listener above)
    // widget.circleObjectBloc
    //  .getMessageFeed(widget.userFurnaces, widget.userCircleCaches);

    _memberCircleBloc.getForCircles(widget.userCircleCaches);

    widget.userCircleBloc.fetchUserCircles(widget.userFurnaces, true);
  }

  String lastCircle = '';

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    ///show an empty container until the results are loaded async
    final _body = RefreshIndicator(
        key: _refreshIndicator,
        onRefresh: () async {
          widget.refresh();
          //_circleObjects = [];

          return;
        },
        color: globalState.theme.buttonIcon,
        child: (_circleObjects.isNotEmpty && _memberCircles.isNotEmpty)
            ? Padding(
                padding: EdgeInsets.only(top: 5),
                child: ScrollablePositionedList.separated(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 10,
                        color: globalState.theme.background,
                      );
                    },
                    physics: const AlwaysScrollableScrollPhysics(),
                    //reverse: true,
                    //shrinkWrap: true,
                    itemCount: _circleObjects.length,
                    itemBuilder: (BuildContext context, int index) {
                      var row = _circleObjects[index];

                      bool showCircle = true;

                      if (index != 0) {
                        if (row.circle!.id ==
                            _circleObjects[index - 1].circle!.id)
                          showCircle = false;
                      }

                      Member? member;

                      if (row.circle!.dm) {
                        member = _getMember(row);
                      }

                      try {
                        return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Dismissible(
                                  key: Key(_circleObjects[index].id!),
                                  //direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _dismissByCircle(index);
                                  },
                                  child: showCircle
                                      ? row.circle!.dm
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                  Expanded(
                                                      child: Container(
                                                          height: 4,
                                                          color: Colors.purple
                                                              .withOpacity(
                                                                  .3))),
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 5),
                                                      child: AvatarWidget(
                                                        user: User(
                                                            id: member!
                                                                .memberID,
                                                            username:
                                                                member.username,
                                                            avatar:
                                                                member.avatar),
                                                        userFurnace:
                                                            row.userFurnace!,
                                                        radius: 60,
                                                        refresh:    widget.refresh,
                                                      )),
                                                  Column(children: <Widget>[
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 10),
                                                        child: Text(
                                                          member.username
                                                                      .length >
                                                                  20
                                                              ? User(
                                                                      id: member
                                                                          .memberID,
                                                                      username:
                                                                          member
                                                                              .username,
                                                                      avatar: member
                                                                          .avatar)
                                                                  .getUsernameAndAlias(
                                                                      globalState)
                                                                  .substring(
                                                                      0, 19)
                                                              : User(
                                                                      id: member
                                                                          .memberID,
                                                                      username:
                                                                          member
                                                                              .username,
                                                                      avatar: member
                                                                          .avatar)
                                                                  .getUsernameAndAlias(
                                                                      globalState),
                                                          style: TextStyle(
                                                              fontSize: 17,
                                                              color: globalState
                                                                  .theme
                                                                  .textFieldLabel),
                                                        )),
                                                  ]),
                                                  Expanded(
                                                      child: Container(
                                                          height: 4,
                                                          color: Colors.purple
                                                              .withOpacity(
                                                                  .3))),
                                                ])
                                          : Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                  Expanded(
                                                      child: Container(
                                                          height: 4,
                                                          color: Colors
                                                              .greenAccent
                                                              .withOpacity(
                                                                  .3))),
                                                  MessageFeedUserCircleWidget(
                                                      index,
                                                      row.userFurnace!,
                                                      widget.userCircleBloc,
                                                      row.userCircleCache!,
                                                      _doNothing),
                                                  Expanded(
                                                      child: Container(
                                                          height: 4,
                                                          color: Colors
                                                              .greenAccent
                                                              .withOpacity(
                                                                  .3))),
                                                ])
                                      : Container()),
                              InsideCircleDetermineWidget(
                                members: [],
                                interactive: false,
                                reverse: false,
                                userCircleCache: row.userCircleCache!,
                                userFurnace: row.userFurnace!,
                                circleObjects: _circleObjects,
                                index: index,
                                refresh: _doNothing,
                                circle: row.circle!,
                                tapHandler: _tapHandler,
                                shareObject: _doNothing,
                                unpinObject: _doNothing,
                                openExternalBrowser: _doNothing,
                                leave: _doNothing,
                                export: _doNothing,
                                cancelTransfer: _doNothing,
                                longPressHandler: _doNothing,
                                longReaction: _doNothing,
                                shortReaction: _doNothing,
                                storePosition: _doNothing,
                                copyObject: _doNothing,
                                reactionAdded: _doNothing,
                                showReactions: _doNothing,
                                videoControllerBloc: _videoControllerBloc,
                                circleObjectBloc: widget.circleObjectBloc,
                                globalEventBloc: widget.globalEventBloc,
                                circleRecipeBloc: _circleRecipeBloc,
                                circleImageBloc: _circleImageBloc,
                                circleVideoBloc: _circleVideoBloc,
                                updateList: _doNothing,
                                submitVote: _doNothing,
                                displayReactionsRow: false,
                                deleteObject: _doNothing,
                                editObject: _doNothing,
                                streamVideo: _doNothing,
                                downloadVideo: _doNothing,
                                retry: _doNothing,
                                predispose: _doNothing,
                                playVideo: _doNothing,
                                removeCache: _doNothing,
                                populateVideoFile:
                                    PopulateMedia.populateVideoFile,
                                populateRecipeImageFile:
                                    PopulateMedia.populateRecipeImageFile,
                                populateImageFile:
                                    PopulateMedia.populateImageFile,
                              ),
                            ]);
                      } catch (err, trace) {
                        LogBloc.insertError(err, trace);
                        return Expanded(child: spinkit);
                      }
                    }))
            : //_loaded ?
            Padding(
                padding: EdgeInsets.only(top: 5),
                child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    //reverse: true,
                    //shrinkWrap: true,
                    itemCount: 1,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "all read!",
                                style: TextStyle(
                                    color: globalState.theme.labelText,
                                    fontSize: globalState.userSetting.fontSize),
                              )));
                    })));

    ///Structure of the screen. In this case, an appBar (with a back button) and a body section
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: Stack(children: [
        Padding(
            padding: EdgeInsets.only(left: 20, right: 25, bottom: 5, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: _body),
              ],
            )),
        //_circleObjects.isEmpty && !_loaded ? spinkit : Container()
      ]),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: widget.floatingActionSize,
            height: widget.floatingActionSize,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _markAllRead();
              },
              child: Icon(
                Icons.mark_chat_read_outlined,
                size: widget.iconSize,
                color: globalState.theme.background,
              ),
              backgroundColor: globalState.theme.buttonIcon,
            ),
          ),
        ],
      ),
    );
  }

  _doNothing() {}

  _tapHandler(CircleObject circleObject) {
    List<CircleObject> objectsForCircle = _circleObjects
        .where((element) => element.circle!.id! == circleObject.circle!.id)
        .toList();

    widget.circleObjectBloc.markMultipleRead(objectsForCircle);
    widget.markedReadObjects.addAll(objectsForCircle);

    setState(() {
      _removeBadge(circleObject.userCircleCache!);
      _circleObjects.removeWhere((element) =>
          element.userCircleCache!.usercircle! ==
          circleObject.userCircleCache!.usercircle);
    });

    widget.goInside(circleObject.userCircleCache!);
  }

  Member _getMember(CircleObject circleObject) {
    ///There should only be one for a DM
    MemberCircle memberCircle = _memberCircles
        .firstWhere((element) => element.circleID == circleObject.circle!.id);

    Member member = globalState.members
        .firstWhere((element) => element.memberID == memberCircle.memberID);

    return member;
  }

  _removeBadge(UserCircleCache userCircleCache) {
    CircleObject circleObject = _circleObjects.lastWhere(
        (element) => element.circle!.id == userCircleCache.circle,
        orElse: () => CircleObject(ratchetIndexes: []));

    if (circleObject.id != null) {
      UserFurnace userFurnace = widget.userFurnaces
          .firstWhere((element) => element.pk == userCircleCache.userFurnace!);

      widget.userCircleBloc.setLastAccessed(
          userFurnace, userCircleCache, circleObject.created!, true);

      widget.userCircleCaches
          .firstWhere((element) => element.circle == userCircleCache.circle)
          .lastLocalAccess = userCircleCache.lastLocalAccess;
    }

    widget.removeBadge(userCircleCache.usercircle!);
  }

  _markAllRead() {
    _firebaseBloc.removeNotification();
    for (UserCircleCache userCircleCache in widget.userCircleCaches) {
      _removeBadge(userCircleCache);
    }

    widget.circleObjectBloc.markMultipleRead(_circleObjects);
    widget.markedReadObjects.addAll(_circleObjects);

    setState(() {
      _circleObjects = [];
    });
  }

  handleAppLifecycleState() {
    AppLifecycleState _lastLifecyleState;
      //debugPrint('SystemChannels> $msg');

      switch (msg) {
        case "AppLifecycleState.paused":
          break;
        case "AppLifecycleState.inactive":
          break;
        case "AppLifecycleState.resumed":
          debugPrint('message feed resumed');

          ///call the function that will stream the results back (to the listener above)
          widget.circleObjectBloc
              .getMessageFeed(widget.userFurnaces, widget.userCircleCaches);

          _memberCircleBloc.getForCircles(widget.userCircleCaches);

          widget.userCircleBloc.fetchUserCircles(widget.userFurnaces, true);
          _lastLifecyleState = AppLifecycleState.resumed;

          break;
        case "AppLifecycleState.suspending":
          break;
        default:
      }
      return Future.value(null);
    });
  }

  _dismissByCircle(int index) {
    //if (direction == DismissDirection.endToStart) {

    UserCircleCache userCircleCache = _circleObjects[index].userCircleCache!;

    UserFurnace userFurnace = _circleObjects[index].userFurnace!;

    String circleID = userCircleCache.circle!;

    List<CircleObject> objectsForCircle = _circleObjects
        .where((element) => element.circle!.id! == circleID)
        .toList();

    widget.circleObjectBloc.markMultipleRead(objectsForCircle);
    widget.markedReadObjects.addAll(objectsForCircle);

    _circleObjects.removeWhere((element) => element.circle!.id! == circleID);

    setState(() {});

    widget.userCircleBloc
        .setLastAccessed(userFurnace, userCircleCache, DateTime.now(), true);

    widget.removeBadge(userCircleCache.usercircle!);

    _firebaseBloc.removeNotification();

    //}
  }

  _dimissOneAtATime(int index) {
    //if (direction == DismissDirection.endToStart) {

    UserCircleCache userCircleCache = _circleObjects[index].userCircleCache!;

    UserFurnace userFurnace = _circleObjects[index].userFurnace!;

    String circleObjectID = _circleObjects[index].id!;

    _circleObjects.removeAt(index);

    CircleObject anybodyLeft = _circleObjects.firstWhere(
        (element) =>
            element.userCircleCache!.usercircle == userCircleCache.usercircle,
        orElse: () => CircleObject(ratchetIndexes: []));

    bool flipBadge = false;

    if (anybodyLeft.id == null) {
      flipBadge = true;
    }

    setState(() {});

    if (flipBadge) {
      widget.userCircleBloc.setLastAccessed(
          userFurnace, userCircleCache, DateTime.now(), flipBadge);

      widget.removeBadge(userCircleCache.usercircle!);
    } else {
      widget.circleObjectBloc.markRead(circleObjectID);
    }

    _firebaseBloc.removeNotification();

    //}
  }
}

 */
