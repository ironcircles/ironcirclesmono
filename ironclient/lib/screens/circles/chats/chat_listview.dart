/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/screens/circles/chats/chat_listview_dm.dart';
import 'package:ironcirclesapp/screens/circles/circle_add_connection.dart';
import 'package:ironcirclesapp/screens/circles/circle_manage.dart';
import 'package:ironcirclesapp/screens/circles/messagefeed_usercircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:provider/provider.dart';

import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class ChatListView extends StatefulWidget {
  final bool sortAlpha;
  final String furnaceFilter;
  final List<String> furnaces;
  final UserCircleBloc userCircleBloc;
  final bool showFeed;

  ChatListView({
    required this.sortAlpha,
    required this.furnaceFilter,
    required this.furnaces,
    required this.userCircleBloc,
    required this.showFeed,
  });

  @override
  State<StatefulWidget> createState() {
    return _ChatListViewState();
  }
}

class _ChatListViewState extends State<ChatListView> /*with TickerProviderStateMixin*/ {
  ScrollController _scrollControllerCircles = ScrollController();
  ScrollController _scrollControllerDMs = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKeyDMs =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorForMessageFeed =
      GlobalKey<RefreshIndicatorState>();

  final double _iconSize = 25;

  //late TabController _tabController;
  bool _showFeed = true;
  bool _messageFeedLoaded = false;

  List<UserFurnace>? _userFurnaces;

  late UserCircleBloc _userCircleBloc;
  late CircleObjectBloc _circleObjectBloc;
  late GlobalEventBloc _globalEventBloc;
  UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  MemberCircleBloc _memberCircleBloc = MemberCircleBloc();

  late FirebaseBloc _firebaseBloc;

  List<UserCircleCache>? _userCircles;
  List<UserCircleCache> _filteredChats = [];
  //List<UserCircleCache> _filteredUserCircles = [];
  //List<UserCircleCache> _filteredDMs = [];
  List<CircleObject> _unreadObjects = [];

  bool hiddenOpen = false;

  //Used for comparisons, move to the Constants class
  final String hiddenFilter = 'Hidden';
  final String all = 'All';
  int _tabs = 2;
  final double _floatingActionSize = 55;
  int startTab = 1;

  List<MemberCircle> _memberCircles = [];
  //List<Member> _members = [];
  List<CircleObject> _markedReadObjects = [];
  //List<User> _userMessageColors = [];

  final _spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();

  late CircleImageBloc _circleImageBloc;
  late CircleVideoBloc _circleVideoBloc;
  late CircleRecipeBloc _circleRecipeBloc;

  _scrollListenerCircles() {
    globalState.lastSelectedIndexCircles = _scrollControllerCircles.offset;
  }

  _scrollListenerDMs() {
    globalState.lastSelectedIndexDMs = _scrollControllerDMs.offset;
  }

  @override
  void initState() {
    super.initState();
    handleAppLifecycleState();

    widget.showFeed ? _tabs = 2 : _tabs = 1;
    widget.showFeed ? startTab = 1 : startTab = 0;
    _showFeed = widget.showFeed;

    //_tabController = TabController(length: _tabs, vsync: this, initialIndex: 0);

    _scrollControllerCircles.addListener(_scrollListenerCircles);
    _scrollControllerDMs.addListener(_scrollListenerDMs);

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleImageBloc = CircleImageBloc(_globalEventBloc);
    _circleVideoBloc = CircleVideoBloc(_globalEventBloc);
    _circleRecipeBloc = CircleRecipeBloc(_globalEventBloc);
    _userCircleBloc = widget.userCircleBloc;
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);

    if (globalState.lastSelectedIndexCircles != null) {
      //debugPrint('last index = ${globalState.lastSelectedIndex}');
      _scrollControllerCircles = ScrollController(
          initialScrollOffset: globalState.lastSelectedIndexCircles!);
    }

    if (globalState.lastSelectedIndexDMs != null) {
      //debugPrint('last index = ${globalState.lastSelectedIndex}');
      _scrollControllerDMs = ScrollController(
          initialScrollOffset: globalState.lastSelectedIndexDMs!);
    }

    _memberCircleBloc.loaded.listen((memberCircles) {
      if (memberCircles != _memberCircles) if (mounted) {
        setState(() {
          _memberCircles = memberCircles;
        });
      }

      _circleObjectBloc.getMessageFeed(_userFurnaces!, _userCircles!);
    });

    ///subscribe to stream that listens for circleobjects to be pulled from SQLLite
    _circleObjectBloc.messageFeed.listen((objects) {
      ///always make sure the screen is visible before calling setState
      if (mounted) {
        _messageFeedLoaded = true;

        ///setState causes the screen to refresh

        _addAll(objects!); //_unreadObjects = objects!; //.reversed.toList();
        //_loaded = true;
        //MemberColors.setMemberColors(
        //objects, _userMessageColors, globalState.user.username!);

      }
    }, onError: (err, trace) {
      LogBloc.insertError(err, trace);
    }, cancelOnError: false);

    //Listen for deleted results arrive
    _globalEventBloc.circleObjectDeleted.listen((seed) {
      if (mounted) {
        int index = _unreadObjects
            .indexWhere((circleobject) => circleobject.seed == seed);

        if (index != -1) {
          setState(() {
            _unreadObjects.removeAt(index);
          });
        }
      }

      setState(() {});
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    _userCircleBloc.allUserCircles.listen((userCircles) {
      if (mounted) {
        //rint('_userCircleBloc.allUserCircles');

        bool anyHiddenOpen = userCircles.any((item) => item.hiddenOpen == true);

        _memberCircleBloc.getForCircles(userCircles);

        ///don't set state until item above completes
        _userCircles = userCircles;

        hiddenOpen = anyHiddenOpen;
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen((refreshedUserCircleCaches) {
      if (mounted) {
        //debugPrint('_userCircleBloc.refreshedUserCircles');

        bool anyHiddenOpen =
            refreshedUserCircleCaches.any((item) => item.hiddenOpen == true);

        _memberCircleBloc.getForCircles(refreshedUserCircleCaches);

        ///don't set state until item above completes
        _userCircles = refreshedUserCircleCaches;

        hiddenOpen = anyHiddenOpen;
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.refreshHome.listen((refresh) {
      _userFurnaceBloc.requestConnected(globalState.user.id);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.updateResponse.listen((userCircleCache) {
      if (mounted) {
        if (userCircleCache!.hiddenOpen!) {
          setState(() {
            hiddenOpen = true;
          });
        }

        debugPrint('Circles. _userCircleBloc.updateResponse.listen');

        //setState(() {
        _userCircleBloc.fetchUserCircles(_userFurnaces!, true, false);
        // _startSpinner();
        // });

        // FormattedSnackBar.showSnackbarWithContext(context, "Settings Updated", "", 1);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    // _userCircleBloc.fetchUserCircles(_userFurnaces, true);

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      if (mounted) {
        setState(() {
          _userFurnaces = userFurnaces;

          debugPrint('Circles._userFurnaceBloc.userfurnaces.listen');

          _userCircleBloc.fetchUserCircles(_userFurnaces!, true, true);
          _circleObjectBloc.resendFailedCircleObjects(_globalEventBloc);

          //  _startSpinner();
        });
      }
    }, onError: (err) {
      // FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _firebaseBloc.circleEvent.listen((success) {
      _messageFeedLoaded = true;

      _userCircleBloc.sinkCache(_userFurnaces!);
      if (mounted)
        widget.userCircleBloc.fetchUserCircles(_userFurnaces!, true, false);
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.circleObjectBroadcast.listen((object) {
      _messageFeedLoaded = true;

      if (object.id != null && object.userCircleCache != null) {
        if (!object.userCircleCache!.guarded!) _addCircleObject(object);
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.timerExpired.listen((seed) async {
      if (mounted) {
        try {
          int index = _unreadObjects.indexWhere((param) => param.seed == seed);

          if (index >= 0) {
            _markedReadObjects.add(_unreadObjects[index]);
            setState(() {
              _unreadObjects.removeAt(index);
            });
          }
          //}
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('MessageFeed._globalEventBloc.timerExpired.listen: $err');
        }
      }
    }, onError: (err) {
      debugPrint("MessageFeed._globalEventBloc.timerExpired: $err");
    }, cancelOnError: false);

    ///get circleobject refreshes
    _globalEventBloc.circleObjectsRefreshed.listen((value) {
      _circleObjectBloc.getMessageFeed(_userFurnaces!, _userCircles!);
    }, onError: (err, trace) {
      LogBloc.insertError(err, trace);
    }, cancelOnError: false);

    _userFurnaceBloc.requestConnected(globalState.user.id);
  }

  @override
  void dispose() {
    //_scrollController.dispose();
    //_userCircleBloc.dispose();  //passed in
    _circleObjectBloc.dispose();
    _userFurnaceBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFeed != _showFeed) {
      widget.showFeed ? _tabs = 2 : _tabs = 1;
      _showFeed = widget.showFeed;

      //_tabController =
      // TabController(length: _tabs, vsync: this, initialIndex: 0);
    }

    //double width = MediaQuery.of(context).size.width;

    /*if (width > 1199) {
      _columns = 6;
    } else if (width > 999) {
      _columns = 5;
    } else if (width > 799) {
      _columns = 4;
    } else if (width > 550) {
      _columns = 3;
    } else {
      _columns = 2;
    }*/

    ///TODO move this to init instead of build. Shouldn't, but could cause an issue
    //_scrollController.addListener(_scrollListener);

    //filter Circles
    if (_userCircles != null) {
      _filteredChats = [];
      _filteredChats.addAll(_userCircles!);

      //furnace filter

      if (widget.furnaceFilter != all) {
        if (widget.furnaceFilter == hiddenFilter) {
          _filteredChats
              .retainWhere((userCircle) => userCircle.hiddenOpen == true);
        } else {
          _filteredChats.retainWhere((userCircle) =>
              _getUserFurnace(userCircle)!.alias == widget.furnaceFilter);
        }
      }

      if (widget.sortAlpha)
        _filteredChats.sort((a, b) =>
            a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase()));
      else
        _filteredChats
            .sort((a, b) => b.lastItemUpdate!.compareTo(a.lastItemUpdate!));
    }

    return globalState.loggingOut
        ? Container()
        : SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: (_userFurnaces != null && _userCircles != null)
                ? DefaultTabController(
                    length: _tabs,
                    initialIndex: startTab,
                    child: Scaffold(
                        key: _scaffoldKey,
                        backgroundColor: globalState.theme.background,
                        appBar: PreferredSize(
                            preferredSize: const Size(30.0, 30.0),
                            child: TabBar(
                              //controller: _tabController,
                              padding: const EdgeInsets.only(left: 3, right: 3),
                              //indicatorSize: TabBarIndicatorSize.label,
                              unselectedLabelColor:
                                  globalState.theme.unselectedLabel,
                              labelColor: globalState.theme.buttonIcon,
                              //isScrollable: true,
                              indicatorColor: Colors.black,
                              indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      10), // Creates border
                                  color:
                                      Colors.lightBlueAccent.withOpacity(.1)),
                              tabs: widget.showFeed
                                  ? [
                                      _unreadObjects.isNotEmpty
                                          ? Tab(
                                              child: Stack(
                                                  alignment: Alignment.topRight,
                                                  children: <Widget>[
                                                  const Text("Unread  ",
                                                      textScaleFactor: 1.0,
                                                      style: TextStyle(
                                                          fontSize: 16.0)),
                                                  Padding(
                                                      padding: const EdgeInsets.only(
                                                          left: 0, top: 0),
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                  left: 0,
                                                                  top: 0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: globalState
                                                                .theme
                                                                .menuIconsAlt,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          constraints:
                                                              const BoxConstraints(
                                                            maxWidth: 8,
                                                            maxHeight: 8,
                                                          ))),
                                                ]))
                                          : const Tab(
                                              child: Align(
                                              alignment: Alignment.center,
                                              child: Text("Unread",
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      fontSize: 16.0)),
                                            )),
                                      _showNewCircleMessageIndicator(
                                              _filteredChats)
                                          ? Tab(
                                              child: Stack(
                                                  alignment: Alignment.topRight,
                                                  children: <Widget>[
                                                  const Text("Chats  ",
                                                      textScaleFactor: 1.0,
                                                      style: TextStyle(
                                                          fontSize: 16.0)),
                                                  Padding(
                                                      padding: const EdgeInsets.only(
                                                          left: 0, top: 0),
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                  left: 0,
                                                                  top: 0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: globalState
                                                                .theme
                                                                .menuIconsAlt,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          constraints:
                                                              const BoxConstraints(
                                                            maxWidth: 8,
                                                            maxHeight: 8,
                                                          ))),
                                                ]))
                                          : const Tab(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text("Chats",
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontSize: 16.0)),
                                              ),
                                            ),
                                    ]
                                  : [
                                      _showNewCircleMessageIndicator(
                                              _filteredChats)
                                          ? Tab(
                                              child: Stack(
                                                  alignment: Alignment.topRight,
                                                  children: <Widget>[
                                                  const Text("Chats  ",
                                                      style: TextStyle(
                                                          fontSize: 16.0)),
                                                  Padding(
                                                      padding: const EdgeInsets.only(
                                                          left: 0, top: 0),
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                  left: 0,
                                                                  top: 0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: globalState
                                                                .theme
                                                                .menuIconsAlt,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          constraints:
                                                              const BoxConstraints(
                                                            maxWidth: 8,
                                                            maxHeight: 8,
                                                          ))),
                                                ]))
                                          : const Tab(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text("Chats",
                                                    style: TextStyle(
                                                        fontSize: 16.0)),
                                              ),
                                            ),
                                    ],
                            )),
                        body: TabBarView(
                            children:
                                widget.showFeed ? _withFeed() : _withoutFeed()

                            //bottomNavigationBar: ICBottomNavigation(),
                            )))
                : Container());
  }

  List<Widget> _withoutFeed() {
    var widgetList = <Widget>[];
    //widgetList.add(_circlesWidget());
    widgetList.add(_dmWidget());

    return widgetList;
  }

  List<Widget> _withFeed() {
    var widgetList = <Widget>[];

    widgetList.add(_messageFeedWidget());
    //widgetList.add(_circlesWidget());
    widgetList.add(_dmWidget());

    return widgetList;
  }

  Widget _dmWidget() {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: Column(mainAxisSize: MainAxisSize.min, children: [
        //_addDM,
        Expanded(
            child: RefreshIndicator(
                key: _refreshIndicatorKeyDMs,
                onRefresh: _refresh,
                color: globalState.theme.buttonIcon,
                child: _filteredChats.isNotEmpty
                    ? _buildChats()
                    : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        //physics: const AlwaysScrollableScrollPhysics(),
                        child: Container()))),
      ]),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: _floatingActionSize,
            height: _floatingActionSize,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CircleManage(
                              userFurnaces: _userFurnaces!,
                              userCircleCaches: _userCircles!,
                              userCircleBloc: _userCircleBloc,
                              circles: false,
                            )));
              },
              child: Icon(
                Icons.build,
                size: _iconSize,
                color: globalState.theme.background,
              ),
              backgroundColor: globalState.theme.buttonIcon,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8),
          ),
          Container(
            width: _floatingActionSize,
            height: _floatingActionSize,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CircleDMNew(
                              userFurnaces: _userFurnaces!,
                              userCircleCaches:
                                  _userCircles == null ? [] : _userCircles!,
                            )));
              },
              child: Icon(
                Icons.add,
                size: _iconSize + 5,
                color: globalState.theme.background,
              ),
              backgroundColor: globalState.theme.buttonIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageFeedWidget() {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: Stack(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Expanded(
              child: RefreshIndicator(
                  key: _refreshIndicatorForMessageFeed,
                  onRefresh: _refresh,
                  color: globalState.theme.buttonIcon,
                  child: (_unreadObjects.isNotEmpty &&
                          _memberCircles.isNotEmpty)
                      ? _buildMessageFeed()
                      : _messageFeedLoaded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  //reverse: true,
                                  //shrinkWrap: true,
                                  itemCount: 1,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Padding(
                                        padding: const EdgeInsets.only(top: 30),
                                        child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Text(
                                              "all read!",
                                              textScaleFactor:
                                                  globalState.labelScaleFactor,
                                              style: TextStyle(
                                                  color: globalState
                                                      .theme.labelText,
                                                  fontSize: globalState
                                                      .userSetting.fontSize),
                                            )));
                                  }))
                          : Container())),
        ]),
        _messageFeedLoaded
            ? Container()
            : _unreadObjects.isEmpty
                ? _spinkit
                : Container()
      ]),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: _floatingActionSize,
            height: _floatingActionSize,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _markAllRead();
              },
              child: Icon(
                Icons.mark_chat_read_outlined,
                size: _iconSize,
                color: globalState.theme.background,
              ),
              backgroundColor: globalState.theme.buttonIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFeed() {
    return ListView.separated(

        //itemScrollController: _itemScrollController,
        // itemPositionsListener: _itemPositionsListener,

        separatorBuilder: (context, index) {
          return Divider(
            height: 10,
            color: globalState.theme.background,
          );
        },
        physics: const AlwaysScrollableScrollPhysics(),
        //reverse: true,
        shrinkWrap: true,
        itemCount: _unreadObjects.length,
        itemBuilder: (BuildContext context, int index) {
          var row = _unreadObjects[index];

          bool showCircle = true;

          if (index != 0) {
            if (row.circle!.id == _unreadObjects[index - 1].circle!.id)
              showCircle = false;
          }

          Member? member;

          if (row.circle!.dm) {
            member = _getMember(row);
          }

          if (row.id == null) return Container();

          try {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Dismissible(
                  key: Key(row.id!),
                  //direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _dismissByCircleIndex(index);
                  },
                  child: showCircle
                      ? row.circle!.dm
                          ? Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                  Expanded(
                                      child: Container(
                                          height: 4,
                                          color:
                                              Colors.purple.withOpacity(.3))),
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: AvatarWidget(
                                        refresh: _refresh,
                                        user: User(
                                            id: member!.memberID,
                                            username: member.username,
                                            avatar: member.avatar),
                                        userFurnace: row.userFurnace!,
                                        isUser: false,
                                        radius: 60,
                                      )),
                                  Column(children: <Widget>[
                                    Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: Text(
                                          member.username.length > 20
                                              ? User(
                                                      id: member.memberID,
                                                      username: member.username,
                                                      avatar: member.avatar)
                                                  .getUsernameAndAlias(
                                                      globalState)
                                                  .substring(0, 19)
                                              : User(
                                                      id: member.memberID,
                                                      username: member.username,
                                                      avatar: member.avatar)
                                                  .getUsernameAndAlias(
                                                      globalState),
                                          textScaleFactor:
                                              globalState.nameScaleFactor,
                                          style: TextStyle(
                                              fontSize: 17,
                                              color: globalState
                                                  .theme.textFieldLabel),
                                        )),
                                  ]),
                                  Expanded(
                                      child: Container(
                                          height: 4,
                                          color:
                                              Colors.purple.withOpacity(.3))),
                                ])
                          : Row(mainAxisSize: MainAxisSize.max, children: [
                              Expanded(
                                  child: Container(
                                      height: 4,
                                      color:
                                          Colors.greenAccent.withOpacity(.3))),
                              MessageFeedUserCircleWidget(
                                  index,
                                  row.userFurnace!,
                                  widget.userCircleBloc,
                                  row.userCircleCache!,
                                  _doNothing),
                              Expanded(
                                  child: Container(
                                      height: 4,
                                      color:
                                          Colors.greenAccent.withOpacity(.3))),
                            ])
                      : Container()),
              InsideCircleDetermineWidget(
                members: globalState.members,
                interactive: false,
                reverse: false,
                userCircleCache: row.userCircleCache!,
                userFurnace: row.userFurnace!,
                circleObjects: _unreadObjects,
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
                circleObjectBloc: _circleObjectBloc,
                globalEventBloc: _globalEventBloc,
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
                populateVideoFile: PopulateMedia.populateVideoFile,
                populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
                populateImageFile: PopulateMedia.populateImageFile,
              ),
            ]);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            return Expanded(child: _spinkit);
          }
        });
  }

  Widget _buildChats() {
    return _filteredChats.isEmpty
        ? Container()
        : ListView.separated(
            itemCount: _filteredChats.length,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(right: 5, left: 5),
            controller: _scrollControllerDMs,
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return Container(
                color: globalState.theme.cardSeparator,
                //height: 1,
                width: double.maxFinite,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              UserCircleCache userCircleCache = _filteredChats[index];
              UserFurnace? userFurnace = _getUserFurnace(userCircleCache);

              if (userCircleCache.dm) {
                if (_memberCircles.isEmpty) return Container();
                UserCircleCache userCircleCache = _filteredChats[index];

                int mcIndex = _memberCircles.indexWhere(
                    (element) => element.circleID == userCircleCache.circle!);

                if (mcIndex == -1)
                  return Container();
                else {
                  MemberCircle memberCircle = _memberCircles[mcIndex];
                  Member member = globalState.members.firstWhere(
                      (element) => element.memberID == memberCircle.memberID);
                  return userFurnace == null
                      ? Container(
                          /*child: Center(child: Text("pull down refresh"))*/)
                      : Column(children: [
                          Padding(
                            padding:
                                EdgeInsets.only(top: (index == 0) ? 10 : 5),
                          ),
                    ChatListViewDM(
                              index,
                              userFurnace,
                              _userCircleBloc,
                              userCircleCache,
                              member,
                              memberCircle,
                              _memberCircles,
                              _goInside,
                              _userFurnaces!.length > 1),
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                          ),
                        ]);
                }
              } else {
                return userFurnace == null
                    ? Container(
                        /*child: Center(child: Text("pull down refresh"))*/)
                    : Column(children: [
                        Padding(
                          padding: EdgeInsets.only(top: (index == 0) ? 10 : 5),
                        ),
                        UserCircleWidget(
                          index,
                          userFurnace,
                          _userCircleBloc,
                          userCircleCache,
                          _goInside,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                        ),
                      ]);
              }
            });
  }

  UserFurnace? _getUserFurnace(UserCircleCache userCircleCache) {
    UserFurnace? retValue;

    if (_userFurnaces != null) {
      _userFurnaces!.forEach((userFurnace) {
        if (userFurnace.pk == userCircleCache.userFurnace) {
          retValue = userFurnace;
        }
      });
    }

    return retValue;
  }

  _pinCaptured(List<int> pin) {
    try {
      UserCircleCache.pinToString(pin);
      //debugPrint(pinString);

      //debugPrint(UserCircleCache.stringToPin(pinString));

      if (_clickedUserCircleCache != null) {
        if (_clickedUserCircleCache!.checkPin(pin)) {
          _goInside(_clickedUserCircleCache!, guardPinAccepted: true);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaputured: $err');
    }
  }

  UserCircleCache? _clickedUserCircleCache;

  _sinkOnly() async {
    //await _userCircleBloc.sinkOnly(_userFurnaces!, includeClosed: false);
    handleAppLifecycleState();
    _refresh();
  }

  _goInside(UserCircleCache userCircleCache,
      {bool guardPinAccepted = false}) async {
    debugPrint('go inside');

    if (userCircleCache.guarded! && !guardPinAccepted) {
      _clickedUserCircleCache = userCircleCache;

      await DialogPatternCapture.capture(
          context, _pinCaptured, 'Swipe pattern to enter');

      return;
    }
    UserFurnace userFurnace = _userFurnaces!.firstWhere(
        (userFurnace) => userCircleCache.userFurnace == userFurnace.pk);

    _firebaseBloc.removeNotification();

    _userCircleBloc.turnOffBadge(userCircleCache);
    _dismissByCircle(userCircleCache, userFurnace);

    if (mounted) {
      setState(() {
        userCircleCache.showBadge = false;
      });
    }

    globalState.sortAlpha = widget.sortAlpha;
    if (_scrollControllerCircles.hasClients)
      globalState.lastSelectedIndexCircles = _scrollControllerCircles.offset;
    if (_scrollControllerDMs.hasClients)
      globalState.lastSelectedIndexCircles = _scrollControllerDMs.offset;
    //globalState.lastSelectedIndexDMs = _scrollControllerDMs.offset;

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InsideCircle(
                markRead: markRead,
                userCircleCache: userCircleCache,
                userFurnace: userFurnace,
                hiddenOpen: hiddenOpen,
                userFurnaces: _userFurnaces,
                refresh: _sinkOnly,
                dismissByCircle: _dismissByCircle,
              )),
    );
  }

  Future<Null> _refresh() async {
    debugPrint('home _refresh:');

    _userFurnaceBloc.request(
        globalState.user.id, false); //this will invoke sink notification
  }

  handleAppLifecycleState() async {
    AppLifecycleState _lastLifecyleState;
      debugPrint('SystemChannels> $msg');

      try {
        switch (msg) {
          case "AppLifecycleState.paused":
            _lastLifecyleState = AppLifecycleState.paused;
            //_firebaseBloc.removeNotification();
            break;
          case "AppLifecycleState.inactive":
            _lastLifecyleState = AppLifecycleState.inactive;
            break;
          case "AppLifecycleState.resumed":
            _lastLifecyleState = AppLifecycleState.resumed;

            debugPrint('Circles.handleAppLifecycleState.resumed');

            //_userFurnaceBloc.request(globalState.user.id);
            _refresh();

            break;
          default:
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
 FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      }

      return Future.value(null);
    } /*as Future<String?> Function(String?)?*/);
  }

  removeBadge(String userCircleID) {
    setState(() {
      _filteredChats
          .firstWhere((element) => element.usercircle! == userCircleID)
          .showBadge = false;
    });
  }

  bool _showNewCircleMessageIndicator(List<UserCircleCache> list) {
    //debugPrint('*******************************************');
    for (var userCircleCache in list) {
      if (userCircleCache.showBadge == true) return true;
    }

    return false;
  }

  _addAll(List<CircleObject> circleObjects) {
    for (CircleObject circleObject in circleObjects) {
      _addCircleObject(circleObject);
    }
  }

  _addCircleObject(CircleObject circleObject) {
    try {
      ///validate the object has been saved
      if (circleObject.id == null ||
          circleObject.circle == null ||
          _userCircles == null) return;

      ///validate the object isn't from the current user
      for (UserFurnace userFurnace in _userFurnaces!) {
        if (circleObject.creator!.id == userFurnace.userid) {
          return;
        }
      }

      ///validate the last edit wasn't from the current user
      if (circleObject.type == CircleObjectType.CIRCLELIST) {
        if (circleObject.list!.lastEdited != null) {
          for (UserFurnace userFurnace in _userFurnaces!) {
            if (circleObject.list!.lastEdited!.id == userFurnace.userid) {
              return;
            }
          }
        }
      }

      ///Event based timing is tricky. Make sure the object is newer than the lastAccessed date
      UserCircleCache userCircleCache = _userCircles!.firstWhere(
          (element) => element.circle == circleObject.circle!.id,
          orElse: () => UserCircleCache());

      ///Make sure there is a circle
      if (userCircleCache.circle == null ||
          circleObject.lastUpdate == null ||
          userCircleCache.lastLocalAccess == null) return;

      if (circleObject.lastUpdate!
              .compareTo(userCircleCache.lastLocalAccess!) <=
          0) return;

      //if (mounted) {
      int insertIndex = _unreadObjects.length;

      ///don't add if already marked read. Given everything is event based, something slow to process could try to re-add the object
      if (_markedReadObjects
              .indexWhere((element) => element.id == circleObject.id) !=
          -1) {
        return;
      }
      Iterable<CircleObject> objectsForCircle = _unreadObjects
          .where((element) => element.circle!.id == circleObject.circle!.id);

      //debugPrint('objectsForCircle.length: ${objectsForCircle.length}');
      //debugPrint('_unreadObjects.length: ${_unreadObjects.length}');

      String lastInList = '';
      for (CircleObject object in objectsForCircle) {
        if (circleObject.created!.isBefore(object.created!)) {
          insertIndex =
              _unreadObjects.indexWhere((element) => element.id == object.id);

          //debugPrint(insertIndex);

          break;
        } /*else if (circleObject.created!.isAfter(object.created!)) {
          insertIndex =
              _unreadObjects.indexWhere((element) => element.id == object.id);
        }
        */

        lastInList = object.id!;
      }

      if (insertIndex == _unreadObjects.length) {
        insertIndex =
            _unreadObjects.indexWhere((element) => element.id == lastInList) +
                1;
      }

      ///Test for the CircleObjectID first
      int index = -1;

      if (circleObject.id != null) {
        index = _unreadObjects
            .indexWhere((circleobject) => circleobject.id == circleObject.id);
      }

      if (index == -1) {
        index = _unreadObjects.lastIndexWhere(
            (circleobject) => circleobject.seed == circleObject.seed);
      }

      if (index == -1) {
        //debugPrint('insertIndex: $insertIndex');
        _unreadObjects.insert(insertIndex, circleObject);
      } else {
        _unreadObjects[index] = circleObject;
      }

      if (mounted) setState(() {});
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._addCircleObject: $err');
      setState(() {});
    }
  }

  _doNothing() {}

  _tapHandler(CircleObject circleObject) {
    List<CircleObject> objectsForCircle = _unreadObjects
        .where((element) => element.circle!.id! == circleObject.circle!.id)
        .toList();

    _circleObjectBloc.markMultipleRead(objectsForCircle);
    _markedReadObjects.addAll(objectsForCircle);

    setState(() {
      _removeBadge(circleObject.userCircleCache!);
      _unreadObjects.removeWhere((element) =>
          element.userCircleCache!.usercircle! ==
          circleObject.userCircleCache!.usercircle);
    });

    _goInside(circleObject.userCircleCache!);
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
    CircleObject circleObject = _unreadObjects.lastWhere(
        (element) => element.circle!.id == userCircleCache.circle,
        orElse: () => CircleObject(ratchetIndexes: []));

    if (circleObject.id != null) {
      UserFurnace userFurnace = _userFurnaces!
          .firstWhere((element) => element.pk == userCircleCache.userFurnace!);

      widget.userCircleBloc.setLastAccessed(
          userFurnace, userCircleCache, circleObject.created!, true);

      _userCircles!
          .firstWhere((element) => element.circle == userCircleCache.circle)
          .lastLocalAccess = userCircleCache.lastLocalAccess;
    }
  }

  _markAllRead() {
    _firebaseBloc.removeNotification();
    for (UserCircleCache userCircleCache in _userCircles!) {
      _removeBadge(userCircleCache);
    }

    _circleObjectBloc.markMultipleRead(_unreadObjects);
    _markedReadObjects.addAll(_unreadObjects);

    setState(() {
      _unreadObjects = [];
    });
  }

  markRead(CircleObject circleObject) {
    if (circleObject.id == null) return;

    _unreadObjects.removeWhere((element) => element.id! == circleObject.id!);

    _markedReadObjects.add(circleObject);
  }

  _dismissByCircleIndex(int index) {
    UserCircleCache userCircleCache = _unreadObjects[index].userCircleCache!;

    UserFurnace userFurnace = _unreadObjects[index].userFurnace!;

    _dismissByCircle(userCircleCache, userFurnace);
  }

  _dismissByCircle(UserCircleCache userCircleCache, UserFurnace userFurnace) {
    try {
      String circleID = userCircleCache.circle!;

      List<CircleObject> objectsForCircle = _unreadObjects
          .where((element) => element.circle!.id! == circleID)
          .toList();

      _circleObjectBloc.markMultipleRead(objectsForCircle);
      _markedReadObjects.addAll(objectsForCircle);

      _unreadObjects.removeWhere((element) => element.circle!.id! == circleID);

      setState(() {});

      widget.userCircleBloc
          .setLastAccessed(userFurnace, userCircleCache, DateTime.now(), true);

      _removeBadge(userCircleCache);

      _firebaseBloc.removeNotification();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._dismissByCircle: $err');
    }

    //}
  }
}

 */
