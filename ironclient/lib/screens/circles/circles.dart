import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/subscriptions_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/circles/circle_add_connection.dart';
import 'package:ironcirclesapp/screens/circles/circle_friend.dart';
import 'package:ironcirclesapp/screens/circles/circle_friend_desktop.dart';
import 'package:ironcirclesapp/screens/circles/circle_manage.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_name.dart';
import 'package:ironcirclesapp/screens/circles/circles_desktop.dart';
import 'package:ironcirclesapp/screens/circles/circles_desktop_splitscreen.dart';
import 'package:ironcirclesapp/screens/circles/messagefeed_usercircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_container.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
import 'package:ironcirclesapp/screens/invitations/invitations_invites.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/walkthroughs/export_walkthroughs.dart';
import 'package:ironcirclesapp/screens/widgets/blinkingicon.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/extendedfab.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

class Circles extends StatefulWidget {
  final bool sortAlpha;
  final bool sortName;
  final String circleNameFilter;
  final String furnaceFilter;
  final String circleTypeFilter;
  final List<String> furnaces;
  final UserCircleBloc userCircleBloc;
  final bool showFeed;
  final HomeWalkthrough walkthrough;
  final List<MemberCircle> memberCircles;
  final CircleVideoBloc circleVideoBloc;
  final List<Invitation> invitations;
  final Function refreshInvitations;
  //final int startTab;
  final SharedMediaHolder? sharedMediaHolder;
  final List<CircleObject> memCacheObjects;
  final List<ReplyObject> replyObjects;
  final UserCircleCacheAndShare? enterCircle;
  final List<ListItem> circleTypeList;
  final Function filterHome;

  const Circles({
    required this.sortAlpha,
    required this.sortName,
    required this.circleNameFilter,
    required this.furnaceFilter,
    required this.circleTypeFilter,
    // required this.startTab,
    required this.furnaces,
    required this.userCircleBloc,
    required this.showFeed,
    required this.walkthrough,
    required this.memberCircles,
    required this.circleVideoBloc,
    required this.invitations,
    required this.refreshInvitations,
    this.sharedMediaHolder,
    required this.memCacheObjects,
    required this.replyObjects,
    required this.enterCircle,
    required this.circleTypeList,
    required this.filterHome,
  });

  @override
  State<StatefulWidget> createState() {
    return CirclesState();
  }
}

class CirclesState extends State<Circles> with TickerProviderStateMixin {
  static const double _iconPadding = 10;
  ScrollController _scrollControllerCircles = ScrollController();
  ScrollController _scrollControllerDMs = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKeyCircles =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKeyDMs =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorForMessageFeed =
      GlobalKey<RefreshIndicatorState>();

  final ScrollController _scrollControllerDesktopCircles = ScrollController();
  final ScrollController _scrollControllerDesktopFriends = ScrollController();
  // final List<LeftSideItem> _leftSideItemCircles = [];
  // final List<LeftSideItem> _leftSideItemFriends = [];

  late TabController _tabController;

  final double _iconSize = 25;
  final double _floatingActionSize = 55;

  bool _messageFeedLoaded = false;

  List<UserFurnace>? _userFurnaces;

  late UserCircleBloc _userCircleBloc;
  late CircleObjectBloc _circleObjectBloc;
  late GlobalEventBloc _globalEventBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  final MemberCircleBloc _memberCircleBloc = MemberCircleBloc();

  late FirebaseBloc _firebaseBloc;

  List<UserCircleCache>? _userCircles;
  List<UserCircleCache> _filteredUserCircles = [];
  List<UserCircleCache> _hiddenAndClosed = [];
  List<UserCircleCache> _filteredDMs = [];
  List<UserCircleCache> _filteredWallUserCircleCaches = [];
  List<UserFurnace> _wallFurnaces = [];
  List<CircleObject> _unreadObjects = [];
  List<Member> sortedMembers = [];

  int _tabFontSize = 16;
  final double _tabHeight = 50;

  bool hiddenOpen = false;

  ///Used for comparisons, move to the Constants class
  final String hiddenFilter = 'Hidden';
  final String all = 'All';

  //int startTab = 1;
  bool _showFeed = true;
  int _columns = 2;
  int _tabs = 3;

  bool scrolledCircles = true;
  bool scrolledDMs = true;

  bool _firstPull = true;
  bool _handedPendingPurchasesCheck = false;
  //List<MemberCircle> _memberCircles = [];
  final List<CircleObject> _markedReadObjects = [];

  UserCircleCacheAndShare? _enterDM;
  UserCircleCacheAndShare? _enterCircle;
  UserCircleCacheAndShare? _enterAfterPin;
  bool _loaded = false;

  StreamSubscription? applicationStateChangedStream;
  StreamSubscription? openFeedStream;
  StreamSubscription? refreshCirclesStream;
  StreamSubscription? hideCircleStream;
  StreamSubscription? memCacheCircleObjectsRemoveAllHiddenStream;
  StreamSubscription? userFurnaceUpdatedStream;
  StreamSubscription? circleObjectDeletedStream;
  StreamSubscription? refreshHomeStream;
  StreamSubscription? circleObjectBroadcastStream;
  StreamSubscription? circleEventStream;
  StreamSubscription? circleObjectsRefreshedStream;

  final _spinkit = SpinKitDualRing(
    color: globalState.theme.buttonIcon,
    size: 60,
  );

  bool _showSpinner = false;

  final VideoControllerBloc _videoControllerBloc = VideoControllerBloc();
  final VideoControllerDesktopBloc _videoControllerDesktopBloc =
      VideoControllerDesktopBloc();

  late CircleAlbumBloc _circleAlbumBloc;
  late CircleImageBloc _circleImageBloc;
  late CircleRecipeBloc _circleRecipeBloc;
  late CircleFileBloc _circleFileBloc;
  final CircleBloc _circleBloc = CircleBloc();
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();

  bool _desktopShowFeed = true;
  bool _desktopShowUnread = false;
  UserCircleCache? _desktopSelectUserCircleCache;
  Member? _desktopMember;
  SharedMediaHolder? _desktopSharedMediaHolder;
  UserFurnace? _stageUserFurnace;
  UserCircleCache? _stageUserCircleCache;
  double _lastWidth = 0;
  static const double _splitScreenDefault = .2;
  double _splitScreenRatio = _splitScreenDefault;

  _scrollListenerCircles() {
    if (scrolledCircles == false) {
      if (_scrollControllerCircles.offset !=
          globalState.lastSelectedIndexCircles) {
        scrolledCircles = true;
      }
    }
    globalState.lastSelectedIndexCircles = _scrollControllerCircles.offset;
  }

  _scrollListenerDMs() {
    if (scrolledDMs == false) {
      if (_scrollControllerDMs.offset != globalState.lastSelectedIndexDMs) {
        scrolledDMs = true;
      }
    }
    globalState.lastSelectedIndexDMs = _scrollControllerDMs.offset;
  }

  _iOSColdStart() {
    if (Platform.isIOS && globalState.coldStart) {
      globalState.coldStart = false;

      ///_showSpinner = true;
    }
  }

  _handleTimeout() {
    if (mounted) {
      setState(() {
        _showSpinner = false;
      });
    }
  }

  _checkForRemoteMessage() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      if (globalState.handledRemoteNotificationCheck == false) {
        ///there is a firebase messaging bug where notification payload isn't delivered.
        ///This tries after a second
        await Future.delayed(const Duration(seconds: 1));

        RemoteMessage? initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();

        if (initialMessage != null) {
          globalState.handledRemoteNotificationCheck = true;

          globalState.messageReceived = initialMessage;

          try {
            await _globalEventBloc.processInteractedMessage(
              initialMessage,
              false,
            );
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
          }
        }
      }
    }
  }

  @override
  void initState() {
    //_memberCircles = widget.memberCircles;

    super.initState();
    if (Platform.isIOS) _tabFontSize = 14;

    // widget.showFeed ? _tabs = 3 : _tabs = 2;
    // widget.showFeed ? startTab = 1 : startTab = 0;
    // _showFeed = widget.showFeed;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleImageBloc = CircleImageBloc(_globalEventBloc);
    _circleAlbumBloc = CircleAlbumBloc(_globalEventBloc);
    _circleRecipeBloc = CircleRecipeBloc(_globalEventBloc);
    _circleFileBloc = CircleFileBloc(_globalEventBloc);
    _userCircleBloc = widget.userCircleBloc;
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    if (globalState.isDesktop()) {
      _tabController = TabController(
        length: 2,
        initialIndex: globalState.selectedCircleTabIndex,
        vsync: this,
      );
    } else {
      _tabController = TabController(
        length: 3,
        initialIndex: globalState.selectedCircleTabIndex,
        vsync: this,
      );

      // startTab = globalState.selectedCircleIndex;
      _tabController.index = globalState.selectedCircleTabIndex;
    }

    //LogBloc.insertLog("widget.startTab ${widget.startTab}", "circles");
    //LogBloc.insertLog(
    //    "globalState.selectedCirclesIndex ${globalState.selectedCircleIndex}",
    //   "circles");

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _markFeedRead();
      } else {
        _closeKeyboard();
      }

      if (_tabController.indexIsChanging == false) {
        if (_tabController.index == 1) {
          if (scrolledCircles == false &&
              globalState.lastSelectedIndexCircles != null) {
            _scrollControllerCircles.jumpTo(
              globalState.lastSelectedIndexCircles!,
            );
          }
        } else if (_tabController.index == 2) {
          if (scrolledDMs == false &&
              globalState.lastSelectedIndexDMs != null) {
            _scrollControllerDMs.jumpTo(globalState.lastSelectedIndexDMs!);
          }
        }
      } else {
        globalState.selectedCircleTabIndex = _tabController.index;
      }
    });

    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);

    if (globalState.lastSelectedIndexCircles != null) {
      _scrollControllerCircles = ScrollController(
        initialScrollOffset: globalState.lastSelectedIndexCircles!,
      );
    }

    if (globalState.lastSelectedIndexDMs != null) {
      _scrollControllerDMs = ScrollController(
        initialScrollOffset: globalState.lastSelectedIndexDMs!,
      );
    }

    _scrollControllerCircles.addListener(_scrollListenerCircles);
    _scrollControllerDMs.addListener(_scrollListenerDMs);

    _userCircleBloc.attemptedNetworkConnection.listen((success) {
      _showSpinner = false;
    });

    _globalEventBloc.closeHiddenCircles.listen(
      (value) {
        setState(() {
          hiddenOpen = false;
        });
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    applicationStateChangedStream = _globalEventBloc.applicationStateChanged
        .listen(
          (msg) {
            handleAppLifecycleState(msg);
          },
          onError: (error, trace) {
            LogBloc.insertError(error, trace);
          },
          cancelOnError: false,
        );

    openFeedStream = _globalEventBloc.openFeed.listen(
      (value) {
        globalState.selectedCircleTabIndex = 0;

        _tabController.index = globalState.selectedCircleTabIndex;

        ///reset the default
        if (globalState.isDesktop()) {
          globalState.selectedCircleTabIndex = 0;
        } else {
          globalState.selectedCircleTabIndex = 1;
        }

        _enterCircle = globalState.enterCircle;
        debugPrint(
          "******************* FROM HOME Circles._globalEventBloc.openFeed: globalState.enterCircle: ${globalState.enterCircle == null}, _enterCircle: ${_enterCircle == null}",
        );

        if (mounted) {
          setState(() {});
          //LogBloc.insertLog("mounted", "Circles._globalEventBloc.openFeed");
        } else {
          //LogBloc.insertLog("not mounted", "Circles._globalEventBloc.openFeed");
        }
      },
      onError: (err) {
        debugPrint("Circle.listen.userFurnaceUpdated: $err");
      },
      cancelOnError: false,
    );

    refreshCirclesStream = _globalEventBloc.refreshCircles.listen(
      (value) {
        //startTab = globalState.selectedCircleIndex;

        _tabController.index = globalState.selectedCircleTabIndex;

        ///reset the default
        if (globalState.isDesktop()) {
          globalState.selectedCircleTabIndex = 0;
        } else {
          globalState.selectedCircleTabIndex = 1;
        }

        //LogBloc.insertLog(
        //    "globalState.selectedCirclesIndex ${globalState.selectedCircleIndex}",
        //    "_globalEventBloc.refreshCircles");

        // debugPrint(
        //     "refreshCircles selectedCircleIndex:${globalState.selectedCircleIndex}");
        // debugPrint("refreshCircles startTab:$startTab");

        if (mounted) {
          setState(() {});
        }
      },
      onError: (err) {
        debugPrint("Circle.listen.userFurnaceUpdated: $err");
      },
      cancelOnError: false,
    );

    hideCircleStream = _globalEventBloc.unhideCircle.listen(
      (userCircleID) {
        if (_userCircles != null) {
          int index = _userCircles!.indexWhere(
            (element) => element.usercircle! == userCircleID,
          );

          if (index != -1) {
            _userCircles![index].hidden = false;
          }
        }

        if (mounted) {
          setState(() {});
        }
      },
      onError: (err) {
        debugPrint("Circle.listen.userFurnaceUpdated: $err");
      },
      cancelOnError: false,
    );

    hideCircleStream = _globalEventBloc.hideCircle.listen(
      (userCircleID) {
        if (_userCircles != null) {
          _userCircles!.removeWhere(
            (element) => element.usercircle! == userCircleID,
          );
        }
        _filteredUserCircles.removeWhere(
          (element) => element.usercircle! == userCircleID,
        );
        _hiddenAndClosed.removeWhere(
          (element) => element.usercircle! == userCircleID,
        );
        _filteredDMs.removeWhere(
          (element) => element.usercircle! == userCircleID,
        );
        _filteredWallUserCircleCaches.removeWhere(
          (element) => element.usercircle! == userCircleID,
        );

        if (_desktopSelectUserCircleCache != null) {
          if (_desktopSelectUserCircleCache!.usercircle == userCircleID) {
            _desktopSelectUserCircleCache = null;
          }
        }

        if (mounted) {
          setState(() {});
        }
      },
      onError: (err) {
        debugPrint("Circle.listen.userFurnaceUpdated: $err");
      },
      cancelOnError: false,
    );

    memCacheCircleObjectsRemoveAllHiddenStream = _globalEventBloc
        .memCacheCircleObjectsRemoveAllHidden
        .listen(
          (success) async {
            if (_userCircles != null) {
              _userCircles!.removeWhere((item) => item.hidden == true);
            }

            _filteredUserCircles.removeWhere((item) => item.hidden == true);
            _hiddenAndClosed.removeWhere((item) => item.hidden == true);
            _filteredDMs.removeWhere((item) => item.hidden == true);
            _filteredWallUserCircleCaches.removeWhere(
              (item) => item.hidden == true,
            );
          },
          onError: (err) {
            debugPrint("error $err");
          },
          cancelOnError: false,
        );

    _circleBloc.createdUserCircleCache.listen(
      (userCircleCache) {
        if (mounted) {
          int index = _userCircles!.indexWhere(
            (element) => element.usercircle == userCircleCache.usercircle,
          );

          setState(() {
            if (index == -1) {
              _userCircles!.add(userCircleCache);
            } else {
              _userCircles![index] = userCircleCache;
            }

            _showSpinner = false;
          });
        }
      },
      onError: (err) {
        debugPrint("error $err");
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          '',
          2,
          true,
        );
        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    ///subscribe to stream that listens for circleobjects to be pulled from SQLLite
    _circleObjectBloc.messageFeed.listen(
      (objects) {
        ///always make sure the screen is visible before calling setState
        if (mounted) {
          _messageFeedLoaded = true;

          ///setState causes the screen to refresh
          _addAll(objects!); //_unreadObjects = objects!; //.reversed.toList();

          ///see if there is a pending purchase that failed
          if (_handedPendingPurchasesCheck == false) {
            _handedPendingPurchasesCheck = true;
            SubscriptionsBloc.checkPendingPurchases();
            IronCoinBloc.checkPendingPurchases();
          }
        }
      },
      onError: (err, trace) {
        LogBloc.insertError(err, trace);

        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    SubscriptionsBloc.purchaseComplete.listen(
      (subscription) {
        //SubscriptionsBloc.liveActivateSubscription();

        if (mounted) setState(() {});
      },
      onError: (err) {
        //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 1);
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    //Listen for userfurnace changes
    userFurnaceUpdatedStream = _globalEventBloc.userFurnaceUpdated.listen(
      (userFurnace) {
        if (mounted) {
          int index = _userFurnaces!.indexWhere(
            (furnace) => userFurnace.pk == furnace.pk,
          );

          if (index != -1) {
            setState(() {
              _userFurnaces![index] = userFurnace;
            });
          }
        }
      },
      onError: (err) {
        debugPrint("Circle.listen.userFurnaceUpdated: $err");
      },
      cancelOnError: false,
    );

    ///Listen for deleted results arrive
    circleObjectDeletedStream = _globalEventBloc.circleObjectDeleted.listen(
      (seed) {
        if (mounted) {
          int index = _unreadObjects.indexWhere(
            (circleobject) => circleobject.seed == seed,
          );

          if (index != -1) {
            setState(() {
              _unreadObjects.removeAt(index);
            });
          }

          ///this is to make sure the lastItemUpdate date is reset to whatever the server set
          _userCircleBloc.fetchUserCircles(
            _userFurnaces!,
            true,
            true,
            overrideLastItemUpdate: true,
          );

          setState(() {});
        }
      },
      onError: (err) {
        debugPrint("Circle.listen: $err");
      },
      cancelOnError: false,
    );

    _userCircleBloc.allUserCircles.listen(
      (userCircles) {
        debugPrint(
          '################################ Circles.allUserCircles received ALL usercircles at: ${DateTime.now()}',
        );
        //debugPrint('CIRCLES - _userCircleBloc.allUserCircles');

        bool anyHiddenOpen = userCircles.any((item) => item.hiddenOpen == true);

        //_memberCircleBloc.getForCircles(userCircles);
        //don't set state until item above completes

        _userCircles = userCircles;
        hiddenOpen = anyHiddenOpen;
        _loaded = true;

        if (_stageUserFurnace == null) {
          _stageUserFurnace = _getStageWallNetwork();
          if (_stageUserFurnace != null) {
            _stageUserCircleCache = _getUserCircleCacheFromFurnace(
              _stageUserFurnace!,
            );
          }
        }
        if (mounted) {
          setState(() {});
        }

        if (_userFurnaces != null) {
          List<UserFurnace> wallEnabled =
              _userFurnaces!
                  .where((element) => element.enableWall == true)
                  .toList();

          if (wallEnabled.isEmpty || globalState.isDesktop()) {
            _circleObjectBloc.getMessageFeed(_userFurnaces!, _userCircles!);
          }
        }
      },
      onError: (err) {
        debugPrint("error $err");

        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    _userCircleBloc.refreshedUserCircles.listen(
      (refreshedUserCircleCaches) {
        if (mounted) {
          debugPrint(
            '################################Circles.refreshedUserCircles - received usercircles at: ${DateTime.now()}',
          );
          //_showSpinner = false;

          bool anyHiddenOpen = refreshedUserCircleCaches.any(
            (item) => item.hiddenOpen == true,
          );

          _memberCircleBloc.getForCircles(refreshedUserCircleCaches);

          ///don't set state until item above completes
          _userCircles = refreshedUserCircleCaches;

          hiddenOpen = anyHiddenOpen;
        }
      },
      onError: (err) {
        debugPrint("error $err");

        setState(() {
          _showSpinner = false;
        });
      },
      cancelOnError: false,
    );

    refreshHomeStream = _globalEventBloc.refreshHome.listen(
      (refresh) {
        debugPrint(
          '################################Circles.refreshHome at: ${DateTime.now()}',
        );
        _userFurnaceBloc.requestConnected(globalState.user.id);
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    _userCircleBloc.updateResponse.listen(
      (userCircleCache) {
        if (mounted) {
          if (userCircleCache!.hiddenOpen!) {
            setState(() {
              hiddenOpen = true;
            });
          }

          debugPrint('Circles. _userCircleBloc.updateResponse.listen');
          _userCircleBloc.fetchUserCircles(_userFurnaces!, true, false);
        }
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    circleEventStream = _firebaseBloc.circleEvent.listen(
      (success) async {
        _messageFeedLoaded = true;

        if (_tabController.index == 0) {
          await _markFeedRead();
        }
        _userCircleBloc.sinkCache(_userFurnaces!);
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    circleObjectBroadcastStream = _globalEventBloc.circleObjectBroadcast.listen(
      (object) {
        _messageFeedLoaded = true;

        if (object.id != null && object.userCircleCache != null) {
          if (!object.userCircleCache!.guarded!) _addCircleObject(object);
        }
      },
      onError: (err) {
        debugPrint("Circle.listen: $err");
      },
      cancelOnError: false,
    );

    _globalEventBloc.timerExpired.listen(
      (seed) async {
        if (mounted) {
          try {
            int index = _unreadObjects.indexWhere(
              (param) => param.seed == seed,
            );

            if (index >= 0) {
              _markedReadObjects.add(_unreadObjects[index]);
              setState(() {
                _unreadObjects.removeAt(index);
              });
            }
            //}
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
              'MessageFeed._globalEventBloc.timerExpired.listen: $err',
            );
          }
        }
      },
      onError: (err) {
        debugPrint("MessageFeed._globalEventBloc.timerExpired: $err");
      },
      cancelOnError: false,
    );

    ///get circleobject refreshes
    circleObjectsRefreshedStream = _globalEventBloc.circleObjectsRefreshed
        .listen(
          (value) {
            if (_userCircles != null)
              _circleObjectBloc.getMessageFeed(_userFurnaces!, _userCircles!);
          },
          onError: (err, trace) {
            LogBloc.insertError(err, trace);
          },
          cancelOnError: false,
        );

    _userCircleBloc.hiddenAndClosed.listen(
      (userCircleCaches) {
        _hiddenAndClosed = userCircleCaches;
      },
      onError: (err, trace) {
        LogBloc.insertError(err, trace);
      },
      cancelOnError: false,
    );

    _userFurnaceBloc.userfurnaces.listen(
      (userFurnaces) {
        if (mounted) {
          setState(() {
            debugPrint(
              '################################Circles.userfurnaces Received userFurnaces at: ${DateTime.now()}',
            );

            _userFurnaces = userFurnaces;

            //('Circles._userFurnaceBloc.userfurnaces.listen');

            _userCircleBloc.readHiddenAndClosedDMForFurnaces(userFurnaces!);

            //debugPrint('Requesting usercircles at: ${DateTime.now()}');
            _userCircleBloc.fetchUserCircles(
              _userFurnaces!,
              true,
              _firstPull ? true : false,
              overrideLastItemUpdate: _firstPull,
            );

            if (Platform.isIOS) {
              ///only wait 3 seconds before timing the spinner out
              Timer(const Duration(seconds: 3), _handleTimeout);
            }

            _firstPull = false;
            _circleObjectBloc.resendFailedCircleObjects(
              _globalEventBloc,
              _userFurnaces!,
            );
          });
        }
      },
      onError: (err) {
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    debugPrint('Requesting userFurnaces at: ${DateTime.now()}');
    _userFurnaceBloc.requestConnected(globalState.user.id);

    if (globalState.enterDM != null) {
      if (globalState.isDesktop()) {
        globalState.selectedCircleTabIndex = 1;
      } else {
        globalState.selectedCircleTabIndex = 2;
      }
    }

    _iOSColdStart();
    _ironCoinBloc.fetchCoins();

    ///check for race condition on firebase message
    _checkForRemoteMessage();
  }

  void _checkEnter() async {
    if (_loaded) {
      if (globalState.enterDM != null) {
        _enterDM = globalState.enterDM;
        globalState.enterDM = null;

        _goInside(
          _enterDM!.userCircleCache,
          sharedMediaHolder: _enterDM!.sharedMediaHolder,
        );
      } else if (globalState.enterCircle != null) {
        _enterCircle = globalState.enterCircle;
        globalState.enterCircle = null;

        if (_enterCircle!.userCircleCache.cachedCircle!.type !=
            CircleType.WALL) {
          _goInside(
            _enterCircle!.userCircleCache,
            sharedMediaHolder: _enterCircle!.sharedMediaHolder,
          );
        }
      }
      // } else if (_enterCircle != null){
      //   if (_enterCircle!.userCircleCache.cachedCircle!.type !=
      //       CircleType.WALL) {
      //     _goInside(_enterCircle!.userCircleCache,
      //         sharedMediaHolder: _enterCircle!.sharedMediaHolder);
      //   }
      // }
    }
  }

  @override
  void dispose() {
    _circleObjectBloc.dispose();
    _userFurnaceBloc.dispose();
    _globalEventBloc.dispose();
    _circleImageBloc.dispose();
    _circleRecipeBloc.dispose();
    _circleFileBloc.dispose();

    applicationStateChangedStream?.cancel();
    openFeedStream?.cancel();
    refreshCirclesStream?.cancel();
    hideCircleStream?.cancel();
    memCacheCircleObjectsRemoveAllHiddenStream?.cancel();
    userFurnaceUpdatedStream?.cancel();
    circleObjectDeletedStream?.cancel();
    refreshHomeStream?.cancel();
    circleObjectBroadcastStream?.cancel();
    circleEventStream?.cancel();
    circleObjectsRefreshedStream?.cancel();

    super.dispose();
  }

  String lastNetworkFilter = "";

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEnter();
    });

    // debugPrint(
    //     "refreshCircles selectedCircleIndex:${globalState.selectedCircleIndex}");
    // debugPrint("refreshCircles startTab:$startTab");

    double width = MediaQuery.of(context).size.width;

    if (globalState.isDesktop()) {
      if (_lastWidth != width) {
        _splitScreenRatio = _splitScreenDefault;
        _lastWidth = width;
      }
    } else {
      if (widget.showFeed != _showFeed) {
        widget.showFeed ? _tabs = 3 : _tabs = 2;
        _showFeed = widget.showFeed;

        //_tabController =
        // TabController(length: _tabs, vsync: this, initialIndex: 0);
      }
      if (width > 1199) {
        _columns = 6;
      } else if (width > 999) {
        _columns = 5;
      } else if (width > 799) {
        _columns = 4;
      } else if (width > 550) {
        _columns = 3;
      } else {
        _columns = 2;
      }
    }

    ///filter Circles
    if (_userCircles != null && _userFurnaces != null) {
      // Remember to fix the IronForge always having a wall enabled when this is uncommented
      _wallFurnaces =
          _userFurnaces!
              .where((element) => element.enableWall == true)
              .toList();

      _filteredWallUserCircleCaches = [];
      _filteredWallUserCircleCaches =
          _userCircles!
              .where((element) => element.cachedCircle!.type == CircleType.WALL)
              .toList();

      try {
        ///there is an edge case where logging in with the feed on, then logging off, and loggin on with it on throughs an error
        //get the networks that don't have a wall enabled
        Iterable<UserFurnace> noWall = _userFurnaces!.where(
          (element) => element.enableWall == false,
        );

        if (noWall.isNotEmpty) {
          for (UserFurnace userFurnace in noWall) {
            _filteredWallUserCircleCaches.removeWhere(
              (userCircleCache) =>
                  userCircleCache.userFurnace == userFurnace.pk,
            );
          }
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
      }

      _filteredUserCircles = [];
      _filteredUserCircles.addAll(
        _userCircles!.where(
          (element) =>
              element.dm == false &&
              element.cachedCircle!.type != CircleType.WALL,
        ),
      );

      //(widget.furnaceFilter);
      //debugPrint(lastNetworkFilter);

      ///furnace filter
      if (widget.furnaceFilter != all) {
        if (widget.furnaceFilter == hiddenFilter) {
          _filteredUserCircles.retainWhere(
            (userCircle) => userCircle.hiddenOpen == true,
          );
        } else {
          _filteredUserCircles.retainWhere(
            (userCircle) =>
                _getUserFurnaceAlias(userCircle) == widget.furnaceFilter,
          );

          _filteredWallUserCircleCaches.retainWhere(
            (userCircle) =>
                _getUserFurnaceAlias(userCircle) == widget.furnaceFilter,
          );

          _wallFurnaces.retainWhere(
            (furnace) => furnace.alias == widget.furnaceFilter,
          );

          if (globalState.isDesktop() &&
              lastNetworkFilter != widget.furnaceFilter) {
            lastNetworkFilter = widget.furnaceFilter;
            if (_desktopSelectUserCircleCache != null) {
              int index = _filteredWallUserCircleCaches.indexWhere(
                (element) =>
                    element.userFurnace ==
                    _desktopSelectUserCircleCache!.userFurnace!,
              );

              if (index == -1) {
                _desktopSelectUserCircleCache = null;
              }
            } else if (_desktopShowFeed && _wallFurnaces.isNotEmpty) {
              _stageUserFurnace = _wallFurnaces.firstWhere(
                (furnace) => furnace.alias == widget.furnaceFilter,
              );
              _stageUserCircleCache = _getUserCircleCacheFromFurnace(
                _stageUserFurnace!,
              );

              debugPrint(_stageUserFurnace!.alias!);
              debugPrint(_stageUserCircleCache!.prefName!);
            }
          }
        }
      } else if (globalState.isDesktop() &&
          _desktopShowFeed &&
          lastNetworkFilter != widget.furnaceFilter) {
        String filter = lastNetworkFilter;

        lastNetworkFilter = widget.furnaceFilter;
        _filteredWallUserCircleCaches =
            _userCircles!
                .where(
                  (element) => element.cachedCircle!.type == CircleType.WALL,
                )
                .toList();

        ///InsideCircle won't refresh unless we force a change to the stage network / usercirclecache
        UserFurnace? userFurnace = _getStageWallNetwork();

        if (_filteredWallUserCircleCaches.length > 1 &&
            userFurnace != null &&
            userFurnace.alias == filter) {
          ///Its the same stage network, even though the filter changed.
          /// so pick the second, since stage is always index 0

          _stageUserFurnace = _wallFurnaces[1];
        } else {
          _stageUserFurnace = userFurnace;
        }
        if (_stageUserFurnace != null) {
          _stageUserCircleCache = _getUserCircleCacheFromFurnace(
            _stageUserFurnace!,
          );
        }
      }

      if (widget.circleTypeFilter != all) {
        if (widget.circleTypeFilter == 'hidden') {
          _filteredUserCircles.retainWhere(
            (userCircle) => userCircle.hiddenOpen == true,
          );
        } else {
          _filteredUserCircles.retainWhere(
            (a) => a.cachedCircle!.type == widget.circleTypeFilter,
          );
        }
      }

      if (widget.sortName) {
        _filteredUserCircles.retainWhere(
          (a) => a.prefName!.toLowerCase().contains(
            widget.circleNameFilter.toLowerCase(),
          ),
        );
      }

      if (widget.sortAlpha) {
        _filteredUserCircles.sort(
          (a, b) =>
              a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase()),
        );
      } else
        _filteredUserCircles.sort(
          (a, b) => b.lastItemUpdate!.compareTo(a.lastItemUpdate!),
        );

      ///Filter DMs
      _filteredDMs = [];
      _filteredDMs.addAll(_userCircles!.where((element) => element.dm == true));

      sortedMembers = [];
      for (UserCircleCache userCircleCache in _filteredDMs) {
        try {
          ///exclude closed and hidden
          if (userCircleCache.hidden == true &&
              userCircleCache.hiddenOpen == false) {
            continue;
          }

          int memberIndex = -1;

          if (userCircleCache.dmMember == null &&
              userCircleCache.prefName != null) {
            ///it is a pending invite, need to lookup by name and network
            memberIndex = globalState.members.indexWhere(
              (element) =>
                  element.username.toLowerCase() ==
                      userCircleCache.prefName!.toLowerCase() &&
                  element.furnaceKey == userCircleCache.userFurnace,
            );
          } else {
            memberIndex = globalState.members.indexWhere(
              (element) => element.memberID == userCircleCache.dmMember,
            );
          }

          if (memberIndex != -1) {
            if (globalState.members[memberIndex].lockedOut != true) {
              sortedMembers.add(globalState.members[memberIndex]);
            }
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }

      /*globalState.members.sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));

       */

      globalState.members.sort((a, b) {
        int cmp = a.username.toLowerCase().compareTo(b.username.toLowerCase());
        if (cmp != 0) return cmp;
        return a.userID.compareTo(b.userID);
      });

      for (Member member in globalState.members) {
        //debugPrint('member: ${member.username} : ${member.lockedOut}');
        if (member.connected &&
            member.lockedOut != true &&
            sortedMembers.indexWhere(
                  (element) => element.memberID == member.memberID,
                ) ==
                -1) {
          ///exclude closed and hidden
          int index = _hiddenAndClosed.indexWhere(
            (element) => element.dmMember == member.memberID,
          );
          if (index != -1) {
            index = _filteredDMs.indexWhere(
              (element) => element.dmMember == member.memberID,
            );
            if (index == -1) {
              ///it's not open so exclude it
              continue;
            }
          }

          sortedMembers.add(member);
        }
      }

      ///filter members by furnace
      if (widget.furnaceFilter != all && _userFurnaces != null) {
        try {
          UserFurnace userFurnace = _userFurnaces!.firstWhere(
            (element) => element.alias == widget.furnaceFilter,
          );
          sortedMembers.retainWhere(
            (element) => element.furnaceKey == userFurnace.pk,
          );
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
        }
      }

      ///furnace filter
      if (widget.furnaceFilter != all) {
        if (widget.furnaceFilter == hiddenFilter) {
          _filteredDMs.retainWhere(
            (userCircle) => userCircle.hiddenOpen == true,
          );
        } else {
          _filteredDMs.retainWhere(
            (userCircle) =>
                _getUserFurnaceAlias(userCircle) == widget.furnaceFilter,
          );
        }
      }

      if (widget.sortAlpha)
        sortedMembers.sort((a, b) {
          int cmp = a.username.toLowerCase().compareTo(
            b.username.toLowerCase(),
          );
          if (cmp != 0) return cmp;
          return a.userID.compareTo(b.userID);
        });
    } else {
      _filteredUserCircles = [];
      _filteredDMs = [];
    }

    // if (globalState.isDesktop()) {
    //   _leftSideItemCircles.clear();
    //   _leftSideItemFriends.clear();
    //
    //   _leftSideItemCircles
    //       .add(LeftSideItem(ItemType.circleLabel, name: "Circles"));
    //   _leftSideItemFriends.add(LeftSideItem(ItemType.dmLabel, name: "Friends"));
    //
    //   for (UserCircleCache userCircleCache in _filteredUserCircles) {
    //     _leftSideItemCircles.add(LeftSideItem(ItemType.circle,
    //         userCircleCache: userCircleCache, name: userCircleCache.prefName!));
    //   }
    //
    //   for (Member member in sortedMembers) {
    //     _leftSideItemFriends
    //         .add(LeftSideItem(ItemType.dm, member: member, name: member.alias));
    //   }
    // }

    Widget _menuItem({
      required Color color,
      required String text,
      required IconData iconData,
      required ItemType itemType,
      double extraPadding = 0,
      required Function onTap,
    }) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color:
              (_desktopShowFeed == true && itemType == ItemType.feed)
                  ? globalState.theme.desktopSelectedItem
                  : (_desktopShowUnread == true && itemType == ItemType.unread)
                  ? globalState.theme.desktopSelectedItem
                  : globalState.theme.background,
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        child: InkWell(
          hoverColor: globalState.theme.desktopSelectedItem,
          onTap: () {
            onTap(itemType);
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 20 + extraPadding,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                Icon(iconData),
                //const SizedBox(width: 10),
                ///Add spaces instead of sized box so the screen will resize
                Expanded(
                  child: ICText(
                    "  $text",
                    color: color,
                    fontSize: 18,
                    maxLines: 1,
                    textScaleFactor: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final _leftSideFriends = Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.blueGrey.shade800),
          trackColor: MaterialStateProperty.all(
            globalState.theme.buttonIconHighlight,
          ),
        ),
      ),
      child: Scrollbar(
        controller: _scrollControllerDesktopFriends,
        thumbVisibility: true,
        child:
            sortedMembers.isEmpty
                ? Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _newDesktop(ItemType.dmLabel);
                          },
                          icon: Icon(
                            Icons.add,
                            color: globalState.theme.button,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : ListView.builder(
                  itemCount: sortedMembers.length,
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  controller: _scrollControllerDesktopFriends,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    var member = sortedMembers[index];

                    ///furnaces must be loaded
                    if (_userFurnaces == null) return Container();

                    // Member member = item.member!;

                    if (member.connected == false) return Container();

                    int furnaceIndex = _userFurnaces!.indexWhere(
                      (element) => element.pk == member.furnaceKey,
                    );

                    ///furnaces must be connected
                    if (furnaceIndex == -1) return Container();

                    UserFurnace userFurnace = _userFurnaces![furnaceIndex];

                    ///can't be the current user
                    if (member.memberID == userFurnace.userid)
                      return Container();

                    UserCircleCache? userCircleCache;
                    int dmIndex = -1;

                    dmIndex = _filteredDMs.indexWhere(
                      (element) => element.dmMember == member.memberID,
                    );

                    ///print the username and member number
                    // debugPrint(
                    //     'username: ${member.username} member: ${member.memberID}');

                    if (dmIndex != -1) {
                      userCircleCache = _filteredDMs[dmIndex];
                    } else {
                      List<UserCircleCache> filterOutNullPrefName =
                          _filteredDMs
                              .where((element) => element.prefName != null)
                              .toList();

                      ///check by name if it's an open invitation
                      dmIndex = filterOutNullPrefName.indexWhere(
                        (element) =>
                            element.prefName!.toLowerCase() ==
                                member.username.toLowerCase() &&
                            element.userFurnace == userFurnace.pk,
                      );
                      if (dmIndex != -1) {
                        userCircleCache = filterOutNullPrefName[dmIndex];
                      }
                    }

                    Invitation? invitation;

                    if (userCircleCache == null) {
                      ///check to see if there is a DM invitation from
                      Iterable<Invitation> invitations = widget.invitations
                          .where(
                            (element) => element.inviterID == member.memberID,
                          );

                      for (Invitation invitationCheck in invitations) {
                        if (invitationCheck.dm == true) {
                          invitation = invitationCheck;
                          break;
                        }
                      }
                    }

                    return Column(
                      children: [
                        index == 0
                            ? Row(
                              children: [
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    _newDesktop(ItemType.dmLabel);
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: globalState.theme.button,
                                  ),
                                ),
                              ],
                            )
                            : Container(),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color:
                              _desktopSelectUserCircleCache != null &&
                                      _desktopSelectUserCircleCache ==
                                          userCircleCache
                                  ? globalState.theme.desktopSelectedItem
                                  : globalState.theme.background,
                          child: CircleFriendDesktopWidget(
                            GlobalKey(),
                            index,
                            userFurnace,
                            _userCircleBloc,
                            _circleBloc,
                            userCircleCache,
                            member,
                            _memberCircleBloc,
                            _goInside,
                            _userFurnaces!.length > 1,
                            _dmCanceled,
                            _startSpinner,
                            invitation,
                            widget.refreshInvitations,
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );

    final _leftSideCircles = Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.blueGrey.shade800),
          trackColor: MaterialStateProperty.all(
            globalState.theme.buttonIconHighlight,
          ),
        ),
      ),
      child: Scrollbar(
        controller: _scrollControllerDesktopCircles,
        thumbVisibility: true,
        child:
            _filteredUserCircles.isEmpty
                ? Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _newDesktop(ItemType.circleLabel);
                          },
                          icon: Icon(
                            Icons.add,
                            color: globalState.theme.button,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : ListView.builder(
                  itemCount: _filteredUserCircles.length,
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  controller: _scrollControllerDesktopCircles,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    var item = _filteredUserCircles[index];

                    UserFurnace? userFurnace = _getUserFurnace(item);

                    return Column(
                      children: [
                        index == 0
                            ? Row(
                              children: [
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    _newDesktop(ItemType.circleLabel);
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: globalState.theme.button,
                                  ),
                                ),
                              ],
                            )
                            : Container(),
                        userFurnace == null
                            ? Container()
                            : Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color:
                                      _desktopSelectUserCircleCache != null &&
                                              _desktopSelectUserCircleCache!
                                                      .usercircle ==
                                                  item.usercircle
                                          ? globalState
                                              .theme
                                              .desktopSelectedItem
                                          : globalState.theme.background,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                ),
                                child: CirclesUserCircleDesktop(
                                  width,
                                  index,
                                  userFurnace!,
                                  _userCircleBloc,
                                  item,
                                  _goInside,
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
      ),
    );

    List<Widget> _leftSideCirclesAndFriends() {
      var widgetList = <Widget>[];
      widgetList.add(_leftSideCircles);
      widgetList.add(_leftSideFriends);

      return widgetList;
    }

    final _leftSide = Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Column(
        children: [
          widget.invitations.isNotEmpty &&
                  globalState.dismissInvitations == false
              ? InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => Invites(
                            userFurnaces: _userFurnaces!,
                            invitations: widget.invitations,
                            refreshCallback: widget.refreshInvitations,
                            userCircleBloc: _userCircleBloc,
                          ),
                    ),
                  );
                },
                child: Container(
                  height: 35,

                  ///round corners
                  decoration: BoxDecoration(
                    color: globalState.theme.urgentAction.withOpacity(.2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10),
                      topRight: const Radius.circular(10),
                      bottomLeft: Radius.circular(
                        globalState.notification != null ? 0 : 10,
                      ),
                      bottomRight: Radius.circular(
                        globalState.notification != null ? 0 : 10,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      ICText(
                        '${AppLocalizations.of(context)!.newInvitations}: ${widget.invitations.length}',
                        color: globalState.theme.urgentAction,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              )
              : Container(),
          const SizedBox(height: 5),
          widget.showFeed == false || _wallFurnaces.isEmpty
              ? Container()
              : _menuItem(
                iconData: Icons.dynamic_feed,
                color: globalState.theme.labelText,
                itemType: ItemType.feed,
                text:
                    AppLocalizations.of(
                      context,
                    )!.networkFeeds, //AppLocalizations.of(context)!.networkFeeds,
                onTap: _handleDesktopTap,
              ),
          _menuItem(
            iconData: Icons.message,
            color: globalState.theme.labelText,
            itemType: ItemType.unread,
            text:
                AppLocalizations.of(
                  context,
                )!.unreadMessages, //AppLocalizations.of(context)!.unreadMessages,
            onTap: _handleDesktopTap,
          ),
          Divider(color: globalState.theme.divider),
          Row(
            children: [
              const Spacer(),
              hiddenOpen
                  ? IconButton(
                    padding: const EdgeInsets.only(right: _iconPadding),
                    constraints: const BoxConstraints(),
                    iconSize: 27 - globalState.scaleDownIcons,
                    onPressed: () {
                      setState(() {
                        _desktopSelectUserCircleCache = null;
                      });
                      _globalEventBloc.broadcastCloseHiddenCircles();
                    },
                    icon: Icon(
                      Icons.lock_rounded,
                      color: globalState.theme.button,
                    ),
                  )
                  : Container(),
              IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  widget.filterHome();
                },
                icon: Icon(
                  Icons.filter_list_rounded,
                  color:
                      (widget.circleTypeFilter == all &&
                              widget.furnaceFilter == all &&
                              widget.sortAlpha == false &&
                              widget.sortName == false)
                          ? globalState.theme.menuIcons
                          : globalState.theme.menuIconsAlt,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CircleManage(
                            userFurnaces: _userFurnaces!,
                            memberCircles: widget.memberCircles,
                            userCircleCaches: _userCircles!,
                            userCircleBloc: _userCircleBloc,
                            circles: true,
                          ),
                    ),
                  );
                },
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                icon: Icon(Icons.tune, color: globalState.theme.menuIcons),
              ),
            ],
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              initialIndex: 0,
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: globalState.theme.background,
                appBar: PreferredSize(
                  preferredSize: const Size(30.0, 30.0),
                  child: TabBar(
                    dividerHeight: 0.0,
                    controller: _tabController,
                    padding: const EdgeInsets.only(left: 3, right: 3),
                    unselectedLabelColor: globalState.theme.unselectedLabel,
                    labelColor: globalState.theme.buttonIcon,
                    indicatorColor: Colors.black,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Creates border
                      color: Colors.lightBlueAccent.withOpacity(.1),
                    ),
                    tabs: [
                      _showNewCircleMessageIndicator(_filteredUserCircles)
                          ? Tab(
                            height: _tabHeight,
                            child: Align(
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: <Widget>[
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.circlesWithSpaces,
                                    key: widget.walkthrough.circlesTab,
                                    textScaler: const TextScaler.linear(1.0),
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 0,
                                      top: 0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 0,
                                        top: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: globalState.theme.menuIconsAlt,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 8,
                                        maxHeight: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Tab(
                            height: _tabHeight,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.circles,
                                textScaler: const TextScaler.linear(1.0),
                                key: widget.walkthrough.circlesTab,
                                style: const TextStyle(fontSize: 15.0),
                              ),
                            ),
                          ),
                      _showNewCircleMessageIndicator(_filteredDMs)
                          ? Tab(
                            height: _tabHeight,
                            child: Align(
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: <Widget>[
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.friendsWithSpaces,
                                    textScaler: const TextScaler.linear(1.0),
                                    key: widget.walkthrough.dmTab,
                                    style: TextStyle(
                                      fontSize: _tabFontSize.toDouble(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 0,
                                      top: 0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 0,
                                        top: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: globalState.theme.menuIconsAlt,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 8,
                                        maxHeight: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Tab(
                            height: _tabHeight,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.friends,
                                textScaler: const TextScaler.linear(1.0),
                                key: widget.walkthrough.dmTab,
                                style: TextStyle(
                                  fontSize: _tabFontSize.toDouble(),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: _leftSideCirclesAndFriends(),
                  //bottomNavigationBar: ICBottomNavigation(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final _rightSide = Container(
      color: globalState.theme.background,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child:
            _desktopSelectUserCircleCache != null
                ? InsideCircle(
                  replyObjects: widget.replyObjects,
                  key: _desktopSelectUserCircleCache!.getGlobalKey(),
                  markRead: markRead,
                  userCircleCache: _desktopSelectUserCircleCache!,
                  userFurnace: _getUserFurnace(_desktopSelectUserCircleCache!)!,
                  resetDesktopUI: _resetDesktopUI,
                  hiddenOpen: hiddenOpen,
                  memCacheObjects: widget.memCacheObjects,
                  userFurnaces: _userFurnaces,
                  sharedMediaHolder:
                      _desktopSharedMediaHolder ??
                      _enterCircle?.sharedMediaHolder,
                  refresh: _sinkOnly,
                  dismissByCircle: _dismissAfterInsideCircle,
                  dmMember: _desktopMember,
                )
                : _desktopShowFeed && _stageUserCircleCache != null
                ? InsideCircle(
                  replyObjects: widget.replyObjects,
                  key: _stageUserCircleCache!.getGlobalKey(),
                  userCircleCache: _stageUserCircleCache!,
                  userFurnace: _stageUserFurnace!,
                  userFurnaces: _userFurnaces,
                  //_wallFurnaces,
                  wall: true,
                  // wallUserCircleCaches: lastNetworkFilter == all
                  //     ? _filteredWallUserCircleCaches
                  //     : _filteredWallUserCircleCaches
                  //     .where((element) =>
                  // element.userFurnace ==
                  //     _stageUserFurnace!.pk)
                  //     .toList(),
                  // wallFurnaces: lastNetworkFilter == all
                  //     ? _wallFurnaces
                  //     : [
                  //   _wallFurnaces.firstWhere((element) =>
                  //   element.alias == lastNetworkFilter)
                  // ],
                  wallUserCircleCaches: _filteredWallUserCircleCaches,
                  wallFurnaces: _wallFurnaces,
                  markRead: markRead,
                  hiddenOpen: hiddenOpen,
                  memCacheObjects: widget.memCacheObjects,
                  refresh: _sinkOnly,
                  dismissByCircle: _dismissAfterInsideCircle,
                  sharedMediaHolder:
                      widget.sharedMediaHolder ??
                      ((globalState.enterCircle != null &&
                              globalState.enterCircle!.sharedMediaHolder !=
                                  null)
                          ? globalState.enterCircle!.sharedMediaHolder!
                          : _enterCircle?.sharedMediaHolder),
                  dmMember: null,
                )
                : _desktopShowUnread
                ? showUnread()
                : Container(),
      ),
    );

    // final _desktop = Scaffold(
    //     key: _scaffoldKey,
    //     drawer: ICNavigationDrawer(
    //         userFurnaces: _userFurnaces ?? [], userCircleBloc: _userCircleBloc),
    //     body: Column(children: [
    //       Expanded(
    //           child: Row(
    //         mainAxisAlignment: MainAxisAlignment.start,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: <Widget>[
    //           _leftSide,
    //           _rightSide,
    //         ],
    //       )),
    //     ]));

    final _desktop = VerticalSplitView(
      ratio: _splitScreenRatio,
      left: _leftSide,
      right: _rightSide,
    );

    return globalState.loggingOut
        ? Container()
        : SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child:
              (_userFurnaces != null && _userCircles != null)
                  ? Stack(
                    children: [
                      globalState.isDesktop()
                          ? _desktop
                          : DefaultTabController(
                            length: _tabs,
                            initialIndex: globalState.selectedCircleTabIndex,
                            child: Scaffold(
                              key: _scaffoldKey,
                              backgroundColor: globalState.theme.background,
                              appBar: PreferredSize(
                                preferredSize: const Size(30.0, 30.0),
                                child: TabBar(
                                  dividerHeight: 0.0,
                                  controller: _tabController,
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    right: 3,
                                  ),
                                  //indicatorSize: TabBarIndicatorSize.label,
                                  unselectedLabelColor:
                                      globalState.theme.unselectedLabel,
                                  labelColor: globalState.theme.buttonIcon,
                                  //isScrollable: true,
                                  indicatorColor: Colors.black,
                                  indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // Creates border
                                    color: Colors.lightBlueAccent.withOpacity(
                                      .1,
                                    ),
                                  ),
                                  tabs:
                                      widget.showFeed
                                          ? [
                                            _wallFurnaces.isEmpty
                                                ? _unreadObjects.isNotEmpty
                                                    ? Tab(
                                                      height: _tabHeight,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Stack(
                                                          alignment:
                                                              Alignment
                                                                  .topRight,
                                                          children: <Widget>[
                                                            Text(
                                                              "Unread  ",
                                                              key:
                                                                  widget
                                                                      .walkthrough
                                                                      .unreadMessagesTab,
                                                              textScaler:
                                                                  const TextScaler.linear(
                                                                    1.0,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize:
                                                                    _tabFontSize -
                                                                    globalState
                                                                        .scaleDownTextFont,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    left: 0,
                                                                    top: 0,
                                                                  ),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      left: 0,
                                                                      top: 0,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      globalState
                                                                          .theme
                                                                          .menuIconsAlt,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      maxWidth:
                                                                          8,
                                                                      maxHeight:
                                                                          8,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    : Tab(
                                                      height: _tabHeight,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.unreadMessage,
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .unreadMessagesTab,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          style: TextStyle(
                                                            fontSize:
                                                                _tabFontSize -
                                                                globalState
                                                                    .scaleDownTextFont,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                : _showNewCircleMessageIndicator(
                                                  _filteredWallUserCircleCaches,
                                                )
                                                ? Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: <Widget>[
                                                        Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.feedWithSpaces,
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .unreadMessagesTab,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          style: TextStyle(
                                                            fontSize:
                                                                _tabFontSize -
                                                                globalState
                                                                    .scaleDownTextFont,
                                                          ),
                                                        ),
                                                        BlinkIcon(),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.feed,
                                                      key:
                                                          widget
                                                              .walkthrough
                                                              .unreadMessagesTab,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                            1.0,
                                                          ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            _tabFontSize -
                                                            globalState
                                                                .scaleDownTextFont,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            _showNewCircleMessageIndicator(
                                                  _filteredUserCircles,
                                                )
                                                ? Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: <Widget>[
                                                        Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.circlesWithSpaces,
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .circlesTab,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          style: TextStyle(
                                                            fontSize:
                                                                _tabFontSize -
                                                                globalState
                                                                    .scaleDownTextFont,
                                                          ),
                                                        ),
                                                        BlinkIcon(),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.circles,
                                                      key:
                                                          widget
                                                              .walkthrough
                                                              .circlesTab,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                            1.0,
                                                          ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            _tabFontSize -
                                                            globalState
                                                                .scaleDownTextFont,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            _showNewCircleMessageIndicator(
                                                  _filteredDMs,
                                                )
                                                ? Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: <Widget>[
                                                        Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.friendsWithSpaces,
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .dmTab,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          style: TextStyle(
                                                            fontSize:
                                                                _tabFontSize -
                                                                globalState
                                                                    .scaleDownTextFont,
                                                          ),
                                                        ),
                                                        BlinkIcon(),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.friends,
                                                      key:
                                                          widget
                                                              .walkthrough
                                                              .dmTab,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                            1.0,
                                                          ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            _tabFontSize -
                                                            globalState
                                                                .scaleDownTextFont,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ]
                                          : [
                                            _showNewCircleMessageIndicator(
                                                  _filteredUserCircles,
                                                )
                                                ? Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: <Widget>[
                                                        Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.circlesWithSpaces,
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .circlesTab,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16.0,
                                                              ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 0,
                                                                top: 0,
                                                              ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  left: 0,
                                                                  top: 0,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  globalState
                                                                      .theme
                                                                      .menuIconsAlt,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 8,
                                                                  maxHeight: 8,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.circles,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                            1.0,
                                                          ),
                                                      key:
                                                          widget
                                                              .walkthrough
                                                              .circlesTab,
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            _showNewCircleMessageIndicator(
                                                  _filteredDMs,
                                                )
                                                ? Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: <Widget>[
                                                        Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.friendsWithSpaces,
                                                          textScaler:
                                                              const TextScaler.linear(
                                                                1.0,
                                                              ),
                                                          key:
                                                              widget
                                                                  .walkthrough
                                                                  .dmTab,
                                                          style: TextStyle(
                                                            fontSize:
                                                                _tabFontSize
                                                                    .toDouble(),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 0,
                                                                top: 0,
                                                              ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  left: 0,
                                                                  top: 0,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  globalState
                                                                      .theme
                                                                      .menuIconsAlt,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 8,
                                                                  maxHeight: 8,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Tab(
                                                  height: _tabHeight,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.friends,
                                                      textScaler:
                                                          const TextScaler.linear(
                                                            1.0,
                                                          ),
                                                      key:
                                                          widget
                                                              .walkthrough
                                                              .dmTab,
                                                      style: TextStyle(
                                                        fontSize:
                                                            _tabFontSize
                                                                .toDouble(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ],
                                ),
                              ),
                              body: TabBarView(
                                controller: _tabController,
                                children:
                                    widget.showFeed
                                        ? _withFeed()
                                        : _withoutFeed(),
                                //bottomNavigationBar: ICBottomNavigation(),
                              ),
                            ),
                          ),
                      _showSpinner ? _spinkit : Container(),
                    ],
                  )
                  : Container(),
        );
  }

  List<Widget> _withoutFeed() {
    var widgetList = <Widget>[];
    widgetList.add(_circlesWidget());
    widgetList.add(_dmWidget());

    return widgetList;
  }

  List<Widget> _withFeed() {
    var widgetList = <Widget>[];

    widgetList.add(_messageFeedWidget());
    widgetList.add(_circlesWidget());
    widgetList.add(_dmWidget());

    return widgetList;
  }

  Widget _circlesWidget() {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: RefreshIndicator(
        key: _refreshIndicatorKeyCircles,
        onRefresh: _refreshServer,
        color: globalState.theme.buttonIcon,
        child:
            _filteredUserCircles.isNotEmpty
                ? _buildCircles()
                : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  //physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(),
                ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 5),
        child: FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          label: ICText(
            AppLocalizations.of(context)!.addCircle,
            color: globalState.theme.background,
            fontWeight: FontWeight.bold,
          ),
          key: widget.walkthrough.add,
          heroTag: null,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CircleNewWizardName(
                      userFurnaces: _userFurnaces!,
                      circleTypeList: widget.circleTypeList,
                    ),
              ),
            );

            _refreshServer();
          },
          backgroundColor: globalState.theme.homeFAB,
          icon: Icon(
            Icons.add,
            size: _iconSize + 5 - globalState.scaleDownIcons,
            color: globalState.theme.background,
          ),
        ),
      ),
    );
  }

  Widget _dmWidget() {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //_addDM,
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKeyDMs,
              onRefresh: _refreshServer,
              color: globalState.theme.buttonIcon,
              child:
                  _filteredUserCircles.isNotEmpty
                      ? _buildDMs()
                      : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        //physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(),
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: ExtendedFAB(
        label: AppLocalizations.of(context)!.addFriend,
        color: globalState.theme.homeFAB,
        onPressed: () {
          List<UserFurnace> filteredFurnaces = [];
          filteredFurnaces.addAll(_userFurnaces!);

          if (widget.furnaceFilter.isNotEmpty &&
              widget.furnaceFilter != "All") {
            filteredFurnaces.retainWhere(
              (furnace) => furnace.alias == widget.furnaceFilter,
            );
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CircleAddConnection(
                    userFurnaces: filteredFurnaces,
                    userCircleCaches: _userCircles == null ? [] : _userCircles!,
                  ),
            ),
          );
        },
        icon: Icons.add,
      ),
    );
  }

  UserCircleCache? _getUserCircleCacheFromFurnace(UserFurnace userFurnace) {
    int index = _filteredWallUserCircleCaches.indexWhere(
      (element) => element.userFurnace! == userFurnace.pk,
    );

    if (index == -1 && _userCircles != null) {
      index = _userCircles!.indexWhere(
        (element) =>
            element.userFurnace! == userFurnace.pk &&
            element.cachedCircle!.type == CircleType.WALL,
      );

      if (index != -1) {
        return _userCircles![index];
      } else {
        return null;
      }
    } else {
      return _filteredWallUserCircleCaches[index];
    }
  }

  UserFurnace? _getStageWallNetwork() {
    ///default to the auth furnace if it is wall enabled
    int index = _wallFurnaces.indexWhere(
      (element) => element.authServer == true,
    );

    if (index != -1) {
      return _wallFurnaces[index];
    } else if (_wallFurnaces.isNotEmpty) {
      return _wallFurnaces[0];
    }
  }

  // _getUserCircleCacheFromStageFurnace() {
  //   int index = _filteredWallUserCircleCaches.indexWhere(
  //       (element) => element.userFurnace! == _getStageWallNetwork().pk);
  //
  //   return _filteredWallUserCircleCaches[index];
  // }

  Widget showUnread() {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorForMessageFeed,
                  onRefresh: _refreshServer,
                  color: globalState.theme.buttonIcon,
                  child:
                      (_unreadObjects.isNotEmpty &&
                              widget.memberCircles.isNotEmpty)
                          ? _buildMessageFeed()
                          : _messageFeedLoaded
                          ? Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              //reverse: true,
                              //shrinkWrap: true,
                              itemCount: 1,
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      AppLocalizations.of(context)!.allRead,
                                      textScaler: TextScaler.linear(
                                        globalState.labelScaleFactor,
                                      ),
                                      style: TextStyle(
                                        color: globalState.theme.labelText,
                                        fontSize:
                                            globalState.userSetting.fontSize,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : Container(),
                ),
              ),
            ],
          ),
          _messageFeedLoaded
              ? Container()
              : _unreadObjects.isEmpty
              ? _spinkit
              : Container(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 5),
        child: FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          label: ICText(
            AppLocalizations.of(context)!.clearUnread,
            color: globalState.theme.background,
            fontWeight: FontWeight.bold,
          ),
          heroTag: null,
          onPressed: () {
            _markAllRead();
          },
          backgroundColor: globalState.theme.homeFAB,
          icon: Icon(
            Icons.mark_chat_read_outlined,
            size: _iconSize - globalState.scaleDownIcons,
            color: globalState.theme.background,
          ),
        ),
      ),
    );
  }

  Widget _messageFeedWidget() {
    if (_userFurnaces == null) {
      return Container();
    } else {
      if (_wallFurnaces.isNotEmpty) {
        ///Will only happen immediately after registration
        if (_filteredWallUserCircleCaches.isEmpty) {
          return Container();
        }

        ///show the wall feed
        // UserFurnace userFurnace = _userFurnaces!.firstWhere((userFurnace) =>
        //     _filteredWallUserCircleCaches[0].userFurnace == userFurnace.pk);

        UserFurnace? userFurnace = _getStageWallNetwork();

        if (userFurnace == null) {
          return Container();
        }

        UserCircleCache? userCircleCache = _getUserCircleCacheFromFurnace(
          userFurnace,
        );

        // debugPrint(
        //     "*************************** widget.shareMediaHolder: ${widget.sharedMediaHolder == null}, _enterCircle: ${_enterCircle == null}, _enterCircle.sharedMediaHolder: ${_enterCircle?.sharedMediaHolder}");

        if (userCircleCache == null) {
          return Container();
        } else {
          return InsideCircle(
            // userCircleCache: _filteredWallUserCircleCaches[0],
            replyObjects: widget.replyObjects,
            userCircleCache: userCircleCache,
            userFurnace: userFurnace,
            userFurnaces: _userFurnaces,
            //_wallFurnaces,
            wall: true,
            wallUserCircleCaches: _filteredWallUserCircleCaches,
            wallFurnaces: _wallFurnaces,
            markRead: markRead,
            hiddenOpen: hiddenOpen,
            memCacheObjects: widget.memCacheObjects,
            refresh: _sinkOnly,
            dismissByCircle: _dismissAfterInsideCircle,
            sharedMediaHolder:
                widget.sharedMediaHolder ??
                ((globalState.enterCircle != null &&
                        globalState.enterCircle!.sharedMediaHolder != null)
                    ? globalState.enterCircle!.sharedMediaHolder!
                    : _enterCircle?.sharedMediaHolder),
            dmMember: null,
          );
        }
      } else {
        ///show the unread messages
        return showUnread();
      }
    }
  }

  Widget _buildMessageFeed() {
    double maxWidth = InsideConstants.getCircleObjectSize(
      MediaQuery.of(context).size.width,
    );
    return ListView.separated(
      //itemScrollController: _itemScrollController,
      // itemPositionsListener: _itemPositionsListener,
      separatorBuilder: (context, index) {
        return Divider(height: 10, color: globalState.theme.background);
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Dismissible(
                key: Key(row.id!),
                //direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _dismissByCircleIndex(index);
                },
                child:
                    showCircle
                        ? row.circle!.dm
                            ? Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    color: Colors.purple.withOpacity(.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: AvatarWidget(
                                    refresh: _refreshCache,
                                    user: User(
                                      id: member!.memberID,
                                      username: member.username,
                                      avatar: member.avatar,
                                    ),
                                    userFurnace: row.userFurnace!,
                                    isUser: false,
                                    radius: 60,
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        member.username.length > 20
                                            ? User(
                                                  id: member.memberID,
                                                  username: member.username,
                                                  avatar: member.avatar,
                                                )
                                                .getUsernameAndAlias(
                                                  globalState,
                                                )
                                                .substring(0, 19)
                                            : User(
                                              id: member.memberID,
                                              username: member.username,
                                              avatar: member.avatar,
                                            ).getUsernameAndAlias(globalState),
                                        textScaler: TextScaler.linear(
                                          globalState.nameScaleFactor,
                                        ),
                                        style: TextStyle(
                                          fontSize: 17,
                                          color:
                                              globalState.theme.textFieldLabel,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    color: Colors.purple.withOpacity(.3),
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    color: Colors.greenAccent.withOpacity(.3),
                                  ),
                                ),
                                MessageFeedUserCircleWidget(
                                  index,
                                  row.userFurnace!,
                                  widget.userCircleBloc,
                                  row.userCircleCache!,
                                  _doNothing,
                                ),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    color: Colors.greenAccent.withOpacity(.3),
                                  ),
                                ),
                              ],
                            )
                        : Container(),
              ),
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
                videoControllerDesktopBloc: _videoControllerDesktopBloc,
                circleObjectBloc: _circleObjectBloc,
                globalEventBloc: _globalEventBloc,
                circleRecipeBloc: _circleRecipeBloc,
                circleImageBloc: _circleImageBloc,
                circleVideoBloc: widget.circleVideoBloc,
                circleFileBloc: _circleFileBloc,
                circleAlbumBloc: _circleAlbumBloc,
                updateList: _doNothing,
                submitVote: _doNothing,
                displayReactionsRow: false,
                deleteObject: _doNothing,
                editObject: _doNothing,
                streamVideo: _doNothing,
                downloadVideo: _doNothing,
                downloadFile: _doNothing,
                retry: _doNothing,
                predispose: _doNothing,
                playVideo: _doNothing,
                removeCache: _doNothing,
                populateVideoFile: PopulateMedia.populateVideoFile,
                populateFile: PopulateMedia.populateFile,
                populateRecipeImageFile: PopulateMedia.populateRecipeImageFile,
                populateImageFile: PopulateMedia.populateImageFile,
                populateAlbum: PopulateMedia.populateAlbum,
                maxWidth: maxWidth,
              ),
            ],
          );
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          return Expanded(child: _spinkit);
        }
      },
    );
  }

  Widget _buildCircles() {
    return GridView.builder(
      itemCount: _filteredUserCircles.length,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(right: 5, left: 5),
      controller: _scrollControllerCircles,
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
      ),
      itemBuilder: (BuildContext context, int index) {
        UserCircleCache userCircleCache = _filteredUserCircles[index];

        UserFurnace? userFurnace = _getUserFurnace(userCircleCache);

        return userFurnace == null
            ? Center(child: Text(AppLocalizations.of(context)!.pullDownRefresh))
            : UserCircleWidget(
              index,
              userFurnace,
              _userCircleBloc,
              userCircleCache,
              _goInside,
            );
      },
    );
  }

  Widget _buildDMs() {
    return sortedMembers.isEmpty
        ? Container()
        : Column(
          children: [
            Expanded(
              flex: 20,
              child: ListView.separated(
                itemCount: sortedMembers.length,
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
                  ///furnaces must be loaded
                  if (_userFurnaces == null) return Container();

                  Member member = sortedMembers[index];

                  if (member.connected == false) return Container();

                  int furnaceIndex = _userFurnaces!.indexWhere(
                    (element) => element.pk == member.furnaceKey,
                  );

                  ///furnaces must be connected
                  if (furnaceIndex == -1) return Container();

                  UserFurnace userFurnace = _userFurnaces![furnaceIndex];

                  ///can't be the current user
                  if (member.memberID == userFurnace.userid) return Container();

                  UserCircleCache? userCircleCache;
                  int dmIndex = -1;

                  dmIndex = _filteredDMs.indexWhere(
                    (element) => element.dmMember == member.memberID,
                  );

                  ///print the username and member number
                  // debugPrint(
                  //     'username: ${member.username} member: ${member.memberID}');

                  if (dmIndex != -1) {
                    userCircleCache = _filteredDMs[dmIndex];
                  } else {
                    List<UserCircleCache> filterOutNullPrefName =
                        _filteredDMs
                            .where((element) => element.prefName != null)
                            .toList();

                    ///check by name if it's an open invitation
                    dmIndex = filterOutNullPrefName.indexWhere(
                      (element) =>
                          element.prefName!.toLowerCase() ==
                              member.username.toLowerCase() &&
                          element.userFurnace == userFurnace.pk,
                    );
                    if (dmIndex != -1) {
                      userCircleCache = filterOutNullPrefName[dmIndex];
                    }
                  }

                  int mcIndex = 0;

                  //debugPrint('index: $index');

                  Invitation? invitation;

                  if (userCircleCache == null) {
                    ///check to see if there is a DM invitation from
                    Iterable<Invitation> invitations = widget.invitations.where(
                      (element) => element.inviterID == member.memberID,
                    );

                    for (Invitation invitationCheck in invitations) {
                      if (invitationCheck.dm == true) {
                        invitation = invitationCheck;
                        break;
                      }
                    }
                  }

                  if (mcIndex == -1)
                    return Container(
                      /*
                    child: Center(child: Text("pull down refresh"))*/
                    );
                  else {
                    //MemberCircle memberCircle = _memberCircles[mcIndex];
                    //Member member = globalState.members.firstWhere(
                    //   (element) => element.memberID == memberCircle.memberID);
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: (index == 0) ? 10 : 5),
                        ),
                        CircleFriendWidget(
                          GlobalKey(),
                          index,
                          userFurnace,
                          _userCircleBloc,
                          _circleBloc,
                          userCircleCache,
                          member,
                          _memberCircleBloc,
                          _goInside,
                          _userFurnaces!.length > 1,
                          _dmCanceled,
                          _startSpinner,
                          invitation,
                          widget.refreshInvitations,
                        ),
                        const Padding(padding: EdgeInsets.only(top: 5)),
                      ],
                    );
                  }
                },
              ),
            ),
            //Spacer(flex: 1),
            /*Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: GradientButton(
                //width: screenWidth - 20,
                onPressed: _getMagicLink,
                text: "ADD FRIENDS TO A NETWORK",
              ),
            )*/
          ],
        );
  }

  _startSpinner() {
    setState(() {
      _showSpinner = true;
    });
  }

  _dmCanceled(UserCircleCache userCircleCache) {
    _userCircles!.removeWhere(
      (element) => element.usercircle! == userCircleCache.usercircle!,
    );

    if (mounted) {
      setState(() {});
    }
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

    if (retValue == null || retValue!.alias == null) {
      debugPrint('retvalue is null');
    }

    return retValue;
  }

  String _getUserFurnaceAlias(UserCircleCache userCircleCache) {
    String retValue = '';

    if (_userFurnaces != null) {
      for (var userFurnace in _userFurnaces!) {
        if (userFurnace.pk == userCircleCache.userFurnace) {
          retValue = userFurnace.alias ?? '';
          break;
        }
      }
    }

    return retValue;
  }

  _pinCaptured(List<int> pin) {
    try {
      UserCircleCache.pinToString(pin);
      //debugPrint(pinString);

      //debugPrint(UserCircleCache.stringToPin(pinString));

      if (_clickedUserCircleCache!.checkPin(pin)) {
        _enterCircle = _enterAfterPin;
        _goInside(_clickedUserCircleCache!, guardPinAccepted: true);
      } else {
        UserFurnace userFurnace = _userFurnaces!.firstWhere(
          (userFurnace) =>
              _clickedUserCircleCache!.userFurnace == userFurnace.pk,
        );

        //capture invalid attempt
        _userCircleBloc.saveSwipePatternAttempt(
          userFurnace,
          _clickedUserCircleCache!.circle,
        );

        DialogPatternCapture.capture(
          context,
          _pinCaptured,
          AppLocalizations.of(context)!.swipePatternToEnter,
        );
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaptured: $err');
    }
  }

  UserCircleCache? _clickedUserCircleCache;

  _sinkOnly() async {
    debugPrint(
      '############################## Circles sinkCache called: ${DateTime.now()}',
    );

    _refreshCache();
    //_backupChatHistory();
  }

  _backupChatHistory() async {
    await KeychainBackupBloc.backupDevice(globalState.userFurnace!, false);
    KeychainBackupBloc.backupNonAuth(false);
  }

  _goInside(
    UserCircleCache userCircleCache, {
    bool guardPinAccepted = false,
    Member? member,
    SharedMediaHolder? sharedMediaHolder,
  }) async {
    if (_showSpinner) return;

    debugPrint('go inside: ${DateTime.now()}');

    if (userCircleCache.guarded! && !guardPinAccepted) {
      _clickedUserCircleCache = userCircleCache;
      _enterAfterPin = _enterCircle;
      _enterCircle = null;

      await DialogPatternCapture.capture(
        context,
        _pinCaptured,
        AppLocalizations.of(context)!.swipePatternToEnter,
      );

      return;
    }
    UserFurnace userFurnace = _userFurnaces!.firstWhere(
      (userFurnace) => userCircleCache.userFurnace == userFurnace.pk,
    );

    _firebaseBloc.removeNotification();

    ///sync call
    _dismissByCircle(userCircleCache, userFurnace, refresh: false);

    if (mounted) {
      setState(() {
        userCircleCache.showBadge = false;
      });
    }

    globalState.userSetting.sortAlpha = widget.sortAlpha;

    if (_scrollControllerCircles.hasClients) {
      ///going inside circle/vault, set index for after pop
      globalState.lastSelectedIndexCircles = _scrollControllerCircles.offset;
    }
    if (_scrollControllerDMs.hasClients) {
      ///going inside dm, set index for after pop
      globalState.lastSelectedIndexDMs = _scrollControllerDMs.offset;
    }

    if (globalState.isDesktop()) {
      _desktopShowUnread = false;
      _desktopShowFeed = false;

      _desktopSelectUserCircleCache = userCircleCache;
      _desktopMember = member;
      _desktopSharedMediaHolder = sharedMediaHolder;

      setState(() {});
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InsideCircleContainer(
                markRead: markRead,
                userCircleCache: userCircleCache,
                userFurnace: userFurnace,
                hiddenOpen: hiddenOpen,
                memCacheObjects: widget.memCacheObjects,
                userFurnaces: _userFurnaces,
                sharedMediaHolder:
                    sharedMediaHolder ?? _enterCircle?.sharedMediaHolder,
                refresh: _sinkOnly,
                dismissByCircle: _dismissAfterInsideCircle,
                dmMember: member,
              ),
        ),
      );
    }
  }

  _testing() {
    ///try to keep these commented out before release
    ///kDebug is just a fall back

    if (kDebugMode) {
      ///show Circle and DM popups
      //globalState.userSetting.firstTimeInCircle = false;
      //globalState.userSetting.askedToGuardVault = false;

      ///Remove the user's backup key
      //globalState.userSetting.setBackupKey('');
      //SecureStorageService.writeKey(
      //   KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED + globalState.user.id!, '');
    }
  }

  Future<void> _refreshCache() async {
    //debugPrint('circles _refresh:');

    ///ensure correct index after pop
    if (_scrollControllerCircles.hasClients &&
        globalState.lastSelectedIndexCircles != null) {
      _scrollControllerCircles.jumpTo(globalState.lastSelectedIndexCircles!);
      scrolledCircles = false;
    }
    if (_scrollControllerDMs.hasClients &&
        globalState.lastSelectedIndexDMs != null) {
      _scrollControllerDMs.jumpTo(globalState.lastSelectedIndexDMs!);
      scrolledDMs = false;
    }

    _testing();

    ///CO-Remove
    _userCircleBloc.sinkCache(_userFurnaces!);

    ///wait
    //await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _refreshServer() async {
    debugPrint('circles _refresh:');

    _testing();

    if (_userFurnaces == null) return;
    _userCircleBloc.sinkCache(_userFurnaces!);

    ///wait
    await Future.delayed(const Duration(milliseconds: 250));

    ///this will invoke sink notification
    _userFurnaceBloc.request(globalState.user.id);
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _refreshServer();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  removeBadge(String userCircleID) {
    setState(() {
      _filteredUserCircles
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
          _userCircles == null)
        return;

      ///validate the object isn't from the current user
      if (circleObject.type == CircleObjectType.CIRCLELIST) {
        late String userID;

        if (circleObject.list!.lastEdited != null) {
          userID = circleObject.list!.lastEdited!.id!;
        } else {
          userID = circleObject.creator!.id!;
        }

        for (UserFurnace userFurnace in _userFurnaces!) {
          ///make sure the last change wasn't from the current user
          if (userID == userFurnace.userid) {
            return;
          }
        }
      } else if (circleObject.type != CircleObjectType.SYSTEMMESSAGE) {
        for (UserFurnace userFurnace in _userFurnaces!) {
          ///don't show from the creator
          if (circleObject.creator!.id! == userFurnace.userid) {
            return;
          }
        }
      }
      /*
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

 */

      ///validate the last edit wasn't a reaction
      if (circleObject.lastReactedDate != null) {
        if (circleObject.lastReactedDate == circleObject.lastUpdate) return;
      }

      ///Event based timing is tricky. Make sure the object is newer than the lastAccessed date
      UserCircleCache userCircleCache = _userCircles!.firstWhere(
        (element) => element.circle == circleObject.circle!.id,
        orElse: () => UserCircleCache(),
      );

      ///Make sure there is a circle
      if (userCircleCache.circle == null ||
          circleObject.lastUpdate == null ||
          userCircleCache.lastLocalAccess == null)
        return;

      int dateCompare = circleObject.lastUpdate!.compareTo(
        userCircleCache.lastLocalAccess!,
      );

      if (dateCompare <= 0) return;

      //if (mounted) {
      int insertIndex = _unreadObjects.length;

      ///don't add if already marked read. Given everything is event based, something slow to process could try to re-add the object
      int readIndex = _markedReadObjects.indexWhere(
        (element) => element.id == circleObject.id,
      );

      if (readIndex != -1) {
        if (circleObject.type == CircleObjectType.CIRCLELIST ||
            circleObject.type == CircleObjectType.CIRCLEVOTE ||
            circleObject.type == CircleObjectType.CIRCLERECIPE) {
          if (circleObject.lastUpdate ==
              _markedReadObjects[readIndex].lastUpdate)
            return;
        } else
          return;
      }
      Iterable<CircleObject> objectsForCircle = _unreadObjects.where(
        (element) => element.circle!.id == circleObject.circle!.id,
      );

      //debugPrint('objectsForCircle.length: ${objectsForCircle.length}');
      //debugPrint('_unreadObjects.length: ${_unreadObjects.length}');

      String lastInList = '';
      for (CircleObject object in objectsForCircle) {
        if (circleObject.created!.isBefore(object.created!)) {
          insertIndex = _unreadObjects.indexWhere(
            (element) => element.id == object.id,
          );

          //debugPrint(insertIndex);

          break;
        }
        /*else if (circleObject.created!.isAfter(object.created!)) {
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
        index = _unreadObjects.indexWhere(
          (circleobject) => circleobject.id == circleObject.id,
        );
      }

      if (index == -1) {
        index = _unreadObjects.lastIndexWhere(
          (circleobject) => circleobject.seed == circleObject.seed,
        );
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
    List<CircleObject> objectsForCircle =
        _unreadObjects
            .where((element) => element.circle!.id! == circleObject.circle!.id)
            .toList();

    _circleObjectBloc.markMultipleRead(objectsForCircle);
    _markedReadObjects.addAll(objectsForCircle);

    setState(() {
      _removeBadge(circleObject.userCircleCache!);
      _unreadObjects.removeWhere(
        (element) =>
            element.userCircleCache!.usercircle! ==
            circleObject.userCircleCache!.usercircle,
      );
    });

    _goInside(circleObject.userCircleCache!);
  }

  Member _getMember(CircleObject circleObject) {
    ///There should only be one for a DM
    MemberCircle memberCircle = widget.memberCircles.firstWhere(
      (element) => element.circleID == circleObject.circle!.id,
    );

    Member member = globalState.members.firstWhere(
      (element) => element.memberID == memberCircle.memberID,
    );

    return member;
  }

  _removeBadge(UserCircleCache userCircleCache) {
    CircleObject circleObject = _unreadObjects.lastWhere(
      (element) => element.circle!.id == userCircleCache.circle,
      orElse: () => CircleObject(ratchetIndexes: []),
    );

    UserFurnace userFurnace = _userFurnaces!.firstWhere(
      (element) => element.pk == userCircleCache.userFurnace!,
    );

    if (circleObject.id != null) {
      widget.userCircleBloc.setLastAccessed(
        userFurnace,
        userCircleCache,
        DateTime.now(),
        _circleObjectBloc,
        true,
      );

      _userCircles!
          .firstWhere((element) => element.circle == userCircleCache.circle)
          .lastLocalAccess = userCircleCache.lastLocalAccess;
    } else {
      widget.userCircleBloc.setLastAccessed(
        userFurnace,
        userCircleCache,
        DateTime.now(),
        _circleObjectBloc,
        true,
      );
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

  markRead(CircleObject circleObject) async {
    if (circleObject.id == null) return;

    _unreadObjects.removeWhere((element) => element.id! == circleObject.id!);

    _markedReadObjects.add(circleObject);

    await _circleObjectBloc.markRead(circleObject.id!);
  }

  _dismissByCircleIndex(int index) {
    UserCircleCache userCircleCache = _unreadObjects[index].userCircleCache!;

    UserFurnace userFurnace = _unreadObjects[index].userFurnace!;

    _dismissByCircle(userCircleCache, userFurnace);
  }

  _dismissAfterInsideCircle(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
  ) async {
    try {
      String circleID = userCircleCache.circle!;

      List<CircleObject> objectsForCircle =
          _unreadObjects
              .where((element) => element.circle!.id! == circleID)
              .toList();

      await _circleObjectBloc.markMultipleRead(objectsForCircle);
      _markedReadObjects.addAll(objectsForCircle);

      _unreadObjects.removeWhere((element) => element.circle!.id! == circleID);

      int index = _userCircles!.indexWhere(
        (element) => element.usercircle == userCircleCache.usercircle,
      );

      if (index != -1) {
        _userCircles![index].showBadge = userCircleCache.showBadge;
        _userCircles![index].lastLocalAccess = userCircleCache.lastLocalAccess;
        _userCircles![index].lastItemUpdate = userCircleCache.lastItemUpdate;
      }
      if (mounted) setState(() {});
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._dismissAfterInsideCircle: $err');
    }

    //}
  }

  _dismissByCircle(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace, {
    bool refresh = true,
  }) {
    try {
      String circleID = userCircleCache.circle!;

      List<CircleObject> objectsForCircle =
          _unreadObjects
              .where((element) => element.circle!.id! == circleID)
              .toList();

      _circleObjectBloc.markMultipleRead(objectsForCircle);
      _markedReadObjects.addAll(objectsForCircle);

      _unreadObjects.removeWhere((element) => element.circle!.id! == circleID);

      if (refresh && mounted) {
        setState(() {});
      }

      /*widget.userCircleBloc
          .setLastAccessed(userFurnace, userCircleCache, DateTime.now(), true);
*/
      _removeBadge(userCircleCache);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._dismissByCircle: $err');
    }

    //}
  }

  _markFeedRead() async {
    try {
      for (UserCircleCache userCircleCache in _filteredWallUserCircleCaches) {
        DateTime readDate = DateTime.now();

        await _circleObjectBloc.markReadForCircle(
          userCircleCache.circle!,
          readDate,
        );
        userCircleCache.showBadge = false;
        userCircleCache.lastItemUpdate = readDate;
        userCircleCache.lastLocalAccess = readDate;

        await _userCircleBloc.setLastAccessed(
          _wallFurnaces.firstWhere(
            (element) => element.pk == userCircleCache.userFurnace!,
          ),
          userCircleCache,
          readDate,
          _circleObjectBloc,
          true,
        );

        await _userCircleBloc.turnOffBadge(
          userCircleCache,
          readDate,
          _circleObjectBloc,
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _handleDesktopTap(
    ItemType itemType, {
    UserCircleCache? userCircleCache,
  }) {
    if (itemType == ItemType.feed) {
      _desktopShowFeed = true;
      _desktopShowUnread = false;
      _desktopSelectUserCircleCache = null;
    } else if (itemType == ItemType.unread) {
      _desktopShowFeed = false;
      _desktopShowUnread = true;
      _desktopSelectUserCircleCache = null;
    } else if (itemType == ItemType.circle) {
      _desktopShowFeed = false;
      _desktopShowUnread = false;
      _desktopSelectUserCircleCache = userCircleCache;
    }

    setState(() {});
  }

  _resetDesktopUI() {
    setState(() {
      _desktopSelectUserCircleCache = null;
    });
  }

  _newDesktop(ItemType itemType) async {
    //var item = _leftSideItems[index];

    if (itemType == ItemType.circleLabel) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CircleNewWizardName(
                userFurnaces: _userFurnaces!,
                circleTypeList: widget.circleTypeList,
              ),
        ),
      );

      _refreshServer();
    } else if (itemType == ItemType.dmLabel) {
      List<UserFurnace> filteredFurnaces = [];
      filteredFurnaces.addAll(_userFurnaces!);

      if (widget.furnaceFilter.isNotEmpty && widget.furnaceFilter != "All") {
        filteredFurnaces.retainWhere(
          (furnace) => furnace.alias == widget.furnaceFilter,
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CircleAddConnection(
                userFurnaces: filteredFurnaces,
                userCircleCaches: _userCircles == null ? [] : _userCircles!,
              ),
        ),
      );
    }
  }
}

enum ItemType { feed, unread, circleLabel, circle, dmLabel, dm }

class LeftSideItem {
  ItemType itemType = ItemType.circle;
  UserCircleCache? userCircleCache;
  Member? member;
  String name = "";
  Icon? icon;

  LeftSideItem(
    this.itemType, {
    this.userCircleCache,
    this.member,
    this.name = "",
    this.icon,
  });
}
