import 'dart:async';
import 'dart:io';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/actionneededbloc.dart';
import 'package:ironcirclesapp/blocs/backgroundtask_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/librarybloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/circles/circle_manage.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_name.dart';
import 'package:ironcirclesapp/screens/circles/circles.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullofficialnotification.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle.dart';
import 'package:ironcirclesapp/screens/invitations/invitations_invites.dart';
import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
import 'package:ironcirclesapp/screens/leftnavigation/backlogscreen.dart';
import 'package:ironcirclesapp/screens/leftnavigation/helpcenter.dart';
import 'package:ironcirclesapp/screens/leftnavigation/releases.dart';
import 'package:ironcirclesapp/screens/library/actionneededscreen.dart';
import 'package:ironcirclesapp/screens/library/library.dart';
import 'package:ironcirclesapp/screens/login/applink.dart';
import 'package:ironcirclesapp/screens/login/login_changegenerated.dart';
import 'package:ironcirclesapp/screens/login/networkmanagertabs.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/payment/coinledger.dart';
import 'package:ironcirclesapp/screens/utilities/receive_share.dart';
import 'package:ironcirclesapp/screens/walkthroughs/export_walkthroughs.dart';
import 'package:ironcirclesapp/screens/widgets/bottomButtonNav.dart';
import 'package:ironcirclesapp/screens/widgets/dialogfilterhome.dart';
import 'package:ironcirclesapp/screens/widgets/dialoghomeshortcuts.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:provider/provider.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

enum HomeIndex { feed, circles, friends }

class Home extends StatefulWidget {
  final int tab;
  //final int circlesTab;
  final HomeNavToScreen openScreen;
  final String toast;
  final SharedMediaHolder? sharedMediaHolder;

  const Home({
    Key? key,
    this.tab = 0,
    //this.circlesTab = 1,
    this.openScreen = HomeNavToScreen.nothing,
    this.toast = '',
    this.sharedMediaHolder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  final ScrollController _networkScroller = ScrollController();

  final List<CircleObject> _memCacheCircleObjects = [];
  final List<ReplyObject> _memCacheReplyObjects = [];
  final UserBloc _userBloc = UserBloc();
  bool? _sortAlpha = false;
  bool? _sortName = false;
  String _circleNameFilter = '';
  final bool _sortVault = false;
  List<ActionRequired> _actionRequired = [];
  List<CircleObject> _circleObjectHighPriority = [];
  List<CircleObject> _circleObjectLowPriority = [];

  double radius = 50;
  bool _urgentDone = false;
  bool _circleObjectDone = false;

  List<Invitation> _invitations = [];
  int invitationsCount = 0;
  static const double _iconPadding = 10;

  final ActionNeededBloc _actionNeededBloc = ActionNeededBloc();
  final InvitationBloc _invitationBloc = InvitationBloc();
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ActionNeededScreenState> _actionRequiredKey = GlobalKey();

  List<UserFurnace>? _userFurnaces;

  late UserCircleBloc _userCircleBloc;
  late CircleObjectBloc _circleObjectBloc;
  late CircleVideoBloc _circleVideoBloc;
  late GlobalEventBloc _globalEventBloc;
  final MemberCircleBloc _memberCircleBloc = MemberCircleBloc();
  late ReplyObjectBloc _replyObjectBloc;
  FirebaseBloc? _firebaseBloc;

  List<UserCircleCache> _userCircles = [];
  List<UserCircleCache>? _filteredUserCircles;

  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  List<MemberCircle> _memberCircles = [];
  List<String> _furnaceAliases = [];
  String _furnaceFilter = 'All';
  UserFurnace? _filteredFurnace;
  bool hiddenOpen = false;

  final IronCoinBloc _ironCoinBloc = IronCoinBloc();

  String _circleTypeFilter = 'All';
  CircleType? _filteredCircleType;
  //late List<CircleType> circleTypeList;
  late List<String> _circleTypes;
  late List<String> _circleTypesHidden;
  late List<String> _circleFilterMenu;

  late HomeWalkthrough _homeWalkthrough;
  //final CirclesWalkthrough _circlesWalkthrough = CirclesWalkthrough();

  final String hiddenFilter = 'Hidden';
  final String all = 'All';
  bool _firstPull = true;
  late LibraryBloc _crossBloc;

  List<ListItem> _circleTypeList = [];

  Timer? timer;

  final int _desktopLeftSideFlex = 20;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    globalState.globalEventBloc = _globalEventBloc;
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);
    _circleVideoBloc = CircleVideoBloc(_globalEventBloc);
    _crossBloc = LibraryBloc(globalEventBloc: _globalEventBloc);
    _replyObjectBloc = ReplyObjectBloc(
        globalEventBloc: _globalEventBloc, userCircleBloc: _userCircleBloc);

    super.initState();

    globalState.setAppPath();

    ///push notifications for windows and linux are not supported yet so poll server
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      timer = Timer.periodic(const Duration(seconds: 8),
          (Timer t) => _refreshDesktop()); // Your function
    }

    _homeWalkthrough = HomeWalkthrough(_finish);
    globalState.selectedHomeIndex = widget.tab;

    //if (globalState.userSetting.sortAlpha != null) {
    _sortAlpha = globalState.userSetting.sortAlpha;
    //}

    if (globalState.sortName != null) {
      _sortName = globalState.sortName;
    }

    if (globalState.lastSelectedFilter != null) {
      _furnaceFilter = globalState.lastSelectedFilter!;
    }

    if (globalState.circleTypeFilter != null) {
      _circleTypeFilter = globalState.circleTypeFilter!;
    }

    _globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    _globalEventBloc.closeHiddenCircles.listen((value) {
      _hiddenCirclesClosed();
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.popToHomeOpenScreen.listen((screen) async {
      //if (mounted) {
      _popToHomeOpenScreen(screen);
      //}
    }, onError: (err) {
      debugPrint("Home.actionNeededRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.popToHomeAndOpenShare.listen((shareHolder) async {
      //if (mounted) {
      _popToHomeOpenShare(shareHolder);
      //}
    }, onError: (err) {
      debugPrint("Home.actionNeededRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.popToHomeEnterCircle.listen(
        (userCircleCacheAndShare) async {
      //if (mounted) {
      _popToHomeEnterCircle(userCircleCacheAndShare);
      //}
    }, onError: (err) {
      debugPrint("Home.actionNeededRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.popToHomeOpenTab.listen((tab) async {
      _popToHomeOpenTab(tab);
    }, onError: (err) {
      debugPrint("Home.actionNeededRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.wipePhone.listen((wipe) {
      /*setState(() {
        _wipePhone = true;
      });*/
    }, onError: (err) {}, cancelOnError: false);

    //Listen for userfurnace changes
    _globalEventBloc.userFurnaceUpdated.listen((userFurnace) {
      if (mounted) {
        int index = _userFurnaces!
            .indexWhere((furnace) => userFurnace.pk == furnace.pk);

        if (index != -1) {
          setState(() {
            _userFurnaces![index] = userFurnace;
          });
        }
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen.userFurnaceUpdated: $err");
    }, cancelOnError: false);

    _globalEventBloc.actionNeededRefresh.listen((refresh) async {
      if (mounted) {
        debugPrint('Home_globalEventBloc.actionNeededRefresh');
        //_refresh();

        if (_userFurnaces != null) {
          await _actionNeededBloc.loadCircleObjects(_userFurnaces!);
          await _actionNeededBloc.loadActionRequired(_userFurnaces!);
        }

        //if (_actionRequiredKey.currentState != null) {
        //_actionRequiredKey.currentState!.refresh();
        //}
      }
    }, onError: (err) {
      debugPrint("Home.actionNeededRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.showPinNeeded.listen((a) async {
      if (mounted) {
        _showPinNeeded();
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.showTOS.listen((a) async {
      if (mounted) {
        _showTOS();
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberCircleBloc.loaded.listen((memberCircles) {
      if (memberCircles != _memberCircles) if (mounted) {
        setState(() {
          //debugPrint(
          //'Home.dart - received memberCircles at: ${DateTime.now()}');
          _memberCircles = memberCircles;
        });
      }
    });

    _userCircleBloc.refreshedUserCircles.listen(
        (refreshedUserCircleCaches) async {
      if (mounted) {
        _userCircles = refreshedUserCircleCaches;
        debugPrint(
            '################################Home._userCircleBloc.refreshedUserCircles: ${refreshedUserCircleCaches.length}');

        if (Platform.isWindows) {
          int index =
              _userCircles.indexWhere((element) => element.showBadge == true);

          if (index == -1) {
            WindowsTaskbar.resetOverlayIcon();
          } else {
            ///on windows listen for the show badge notification
            WindowsTaskbar.setOverlayIcon(
              ThumbnailToolbarAssetIcon('assets/images/badge.ico'),
              tooltip: 'New item',
            );
          }
        }

        bool anyHiddenOpen =
            refreshedUserCircleCaches.any((item) => item.hiddenOpen == true);

        MemberBloc.populateGlobalState(globalState, _userFurnaces!);
        _memberCircleBloc.getForCircles(refreshedUserCircleCaches);

        _actionNeededBloc.loadCircleObjects(_userFurnaces!);
        _actionNeededBloc.loadActionRequired(_userFurnaces!);
        //_ironCoinBloc.requestCurrency();

        ///doesn't poll the server
        _invitationBloc.sinkCache(_userFurnaces!);

        ///don't need to poll the server
        _addHiddenFilter(anyHiddenOpen);

        setState(() {
          hiddenOpen = anyHiddenOpen;
        });
      }
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
        debugPrint('Home._userCircleBloc.updateResponse');

        setState(() {
          if (globalState.circleTypeFilter == null &&
              globalState.lastSelectedFilter == null) {
            _circleTypeFilter = 'All';
            _furnaceFilter = 'All';
          }

          _userCircleBloc.fetchUserCircles(_userFurnaces!, true, false);
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.invitationRefresh.listen((refresh) {
      debugPrint('Home_globalEventBloc.invitationRefresh');
      _invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);
      //_invitationBloc.sinkCache(_userFurnaces!);
    }, onError: (err) {
      debugPrint("ActionRequired.invitationRefresh.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.invitationReceived.listen((invitation) {
      debugPrint('Home_globalEventBloc.invitationReceived');

      ///add the userfurnace
      UserFurnace userFurnace = _userFurnaces!
          .firstWhere((element) => element.userid == invitation.inviteeID);
      invitation.userFurnace = userFurnace;

      int index =
          _invitations.indexWhere((element) => element.id == invitation.id);

      if (index == -1) {
        _invitations.add(invitation);
      } else {
        //_invitations[index] = invitation;
      }

      if (mounted)
        setState(() {
          invitationsCount = _invitations.length;
        });
    }, onError: (err) {
      debugPrint("ActionRequired.invitationRefresh.listen: $err");
    }, cancelOnError: false);

    _invitationBloc.invitations.listen((objects) {
      /*
      for (Invitation invitation in objects) {
        int index =
            _invitations.indexWhere((element) => element.id == invitation.id);

        if (index == -1) {
          _invitations.add(invitation);
        }
      }*/

      _invitations = [];

      _invitations.addAll(objects);

      if (mounted) {
        setState(() {
          invitationsCount = objects.length;
        });
      } else
        invitationsCount = objects.length;
    }, onError: (err) {
      debugPrint("ActionRequired..actionRequired.listen: $err");
    }, cancelOnError: false);

    _actionNeededBloc.actionRequired.listen((objects) {
      _actionRequired = [];
      _actionRequired.addAll(objects);

      if (mounted) {
        setState(() {
          _urgentDone = true;
        });
      }
    }, onError: (err) {
      debugPrint("ActionRequired..actionRequired.listen: $err");
    }, cancelOnError: false);

    _actionNeededBloc.circleObjects.listen((circleobjects) {
      _circleObjectHighPriority = [];
      _circleObjectLowPriority = [];

      for (CircleObject circleObject in circleobjects) {
        if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
          if (circleObject.vote!.type == CircleVoteType.REMOVEMEMBER) {
            if (circleObject.vote!.object !=
                circleObject.userFurnace!.userid!) {
              _circleObjectHighPriority.add(circleObject);
            }
          }
        } else {
          _circleObjectLowPriority.add(circleObject);
        }
      }

      if (mounted) {
        setState(() {
          _circleObjectDone = true;
        });
      }
    }, onError: (err) {
      debugPrint("ActionRequired.allCircleObjects.listen: $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsRemoveAllHidden.listen(
        (success) async {
      _hiddenCirclesClosed();
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheReplyObjectsAdd.listen((replyObjects) async {
      for (ReplyObject replyObject in replyObjects) {
        if (replyObject.id == null) continue;
        int index = _memCacheReplyObjects
            .indexWhere((element) => element.seed == replyObject.seed);

        if (index == -1) {
          _memCacheReplyObjects.add(replyObject);
        } else {
          _memCacheReplyObjects[index] = replyObject;
        }
        if (mounted) {
          setState(() {});
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsAdd.listen((circleObjects) async {
      ///for broadcasting to the library
      List<CircleObject> addedObjects = [];

      ///upsert to list based on seed
      for (CircleObject circleObject in circleObjects) {
        if (circleObject.userFurnace == null) {
          try {
            throw ("circleObject.userFurnace == null");
          } catch (err, trace) {
            //LogBloc.insertError(err, trace);
            debugPrint(err.toString());
          }
        }
        //if (circleObject.id == null) continue;
        int index = _memCacheCircleObjects
            .indexWhere((element) => element.seed == circleObject.seed);

        if (index == -1) {
          _memCacheCircleObjects.add(circleObject);
        } else {
          if (circleObject.type == CircleObjectType.CIRCLEIMAGE &&
              circleObject.image!.imageBytes == null &&
              _memCacheCircleObjects[index].image != null) {
            circleObject.image!.imageBytes =
                _memCacheCircleObjects[index].image!.imageBytes;
          } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO &&
              circleObject.video != null) {
            if (circleObject.video!.videoBytes == null) {
              circleObject.video!.videoBytes =
                  _memCacheCircleObjects[index].video!.videoBytes;
            }

            if (circleObject.video!.previewBytes == null) {
              circleObject.video!.previewBytes =
                  _memCacheCircleObjects[index].video!.previewBytes;
            }
          }
          _memCacheCircleObjects[index] = circleObject;
        }

        addedObjects.add(circleObject);
      }

      _globalEventBloc.broadcastAddToLibrary(addedObjects);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheReplyObjectsRemove.listen((replyObjects) async {
      ///remove where seed matches
      for (ReplyObject replyObject in replyObjects) {
        // ReplyObject populatedObject = _memCacheReplyObjects.firstWhere(
        //     (element) => element.seed == replyObject.seed,
        //     orElse: () => replyObject);

        _memCacheReplyObjects
            .removeWhere((element) => element.seed == replyObject.seed);
      }
      if (mounted) {
        setState(() {});
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsRemove.listen((circleObjects) async {
      ///remove where seed matches
      for (CircleObject circleObject in circleObjects) {
        CircleObject populatedObject = _memCacheCircleObjects.firstWhere(
            (element) => element.seed == circleObject.seed,
            orElse: () => circleObject);

        if (populatedObject.userCircleCache != null) {
          _circleObjectBloc.deleteObjectBlobs(
              populatedObject.userCircleCache, populatedObject);
        }

        _memCacheCircleObjects
            .removeWhere((element) => element.seed == circleObject.seed);
      }

      _globalEventBloc.broadcastRemoveFromLibrary(circleObjects);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsRemoveCircle.listen((circleID) async {
      List<CircleObject> removedObjects = _memCacheCircleObjects
          .where((element) => element.circle!.id == circleID)
          .toList();

      _memCacheCircleObjects
          .removeWhere((element) => element.circle!.id == circleID);

      _globalEventBloc.broadcastRemoveFromLibrary(removedObjects);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsRemoveExpired.listen(
        (memCacheExpired) async {
      List<CircleObject> removedObjects = _memCacheCircleObjects
          .where((element) =>
              element.circle!.id == memCacheExpired.circleID &&
              element.created!.millisecondsSinceEpoch <
                  memCacheExpired.privacyDisappearingTimer)
          .toList();

      ///remove where created is less that expired
      _memCacheCircleObjects.removeWhere((element) =>
          element.circle!.id == memCacheExpired.circleID &&
          element.created!.millisecondsSinceEpoch <
              memCacheExpired.privacyDisappearingTimer);

      _globalEventBloc.broadcastRemoveFromLibrary(removedObjects);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.memCacheCircleObjectsAddCircle.listen((circleID) async {
      //TODO
      // _crossBloc.initialLoad(userFurnaces!, true, amount: 5000);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _replyObjectBloc.memCacheReplyObjects.listen((replyObjects) {
      if (replyObjects != null) {
        _memCacheReplyObjects.clear();
        _memCacheReplyObjects.addAll(replyObjects);

        if (mounted) {
          setState(() {});
        }
        debugPrint("reply load finished at: ${DateTime.now()}");
      }
    }, onError: (err) {
      debugPrint('Home.listen: $err');
    }, cancelOnError: false);

    _crossBloc.allCircleObjects.listen((circleObjects) {
      if (circleObjects != null) {
        _memCacheCircleObjects.clear();
        _memCacheCircleObjects.addAll(circleObjects);

        if (mounted) {
          setState(() {});
        }

        debugPrint("load finished at: ${DateTime.now()}");
      }
    }, onError: (err) {
      debugPrint("Library.listen: $err");
    }, cancelOnError: false);

    ///from notification, updated or new
    _globalEventBloc.replyObjectBroadcast.listen((obj) {
      if (mounted) {
        setState(() {
          ReplyObjectCollection.addObjects(
            _memCacheReplyObjects,
            [obj],
            obj.circleObjectID!,
            _userFurnaces![0],
          );
        });
      }
    });

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) async {
      debugPrint(
          '################################Home._userFurnaceBloc.userfurnaces.listen');

      _userFurnaces = userFurnaces;

      if (_userFurnaces != null) {
        if (_memCacheCircleObjects.isEmpty) {
          debugPrint("load started at: ${DateTime.now()}");
          _crossBloc.initialLoad(userFurnaces!, true, amount: 500);
        }
        if (_memCacheReplyObjects.isEmpty) {
          debugPrint("reply load started at: ${DateTime.now()}");
          _replyObjectBloc.initialLoad(1000, userFurnaces![0].userid!);
        }
      }

      _populateFurnaceAliases();

      _userCircleBloc.fetchUserCircles(
          _userFurnaces!, true, _firstPull ? true : false);
      _firstPull = false;

      ///get the list of items
      _actionNeededBloc.loadCircleObjects(_userFurnaces!);
      _actionNeededBloc.loadActionRequired(_userFurnaces!);
      _invitationBloc.sinkCache(userFurnaces!);

      if (mounted) {
        setState(() {});

        _popups();
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    if (_firebaseBloc == null) {
      _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

      _firebaseBloc!.circleEvent.listen((success) {
        _userCircleBloc.sinkCache(_userFurnaces!);
      }, onError: (err) {
        debugPrint("error $err");
      }, cancelOnError: false);
    }

    _globalEventBloc.invitationRefresh.listen((success) {
      _userFurnaceBloc.requestConnected(globalState.user.id);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.refreshHome.listen((success) {
      _userFurnaceBloc.requestConnected(globalState.user.id);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.showMustUpdate.listen((a) async {
      if (mounted) {
        _showMustUpdate();
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    //Permissions.batteryOptimizationGranted(context);

    _userFurnaceBloc.requestConnected(globalState.user.id);
    _ironCoinBloc.requestCurrency();

    //_testAsync();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.toast.isNotEmpty) {
        FormattedSnackBar.showSnackbarWithContext(
            context, widget.toast, '', 10, false);
      }

      ///fire off jobs that should run after the initial screen is shown
      _postLoadJobs();

      if (widget.openScreen != HomeNavToScreen.nothing) {
        _openScreen(widget.openScreen);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _circleTypeList = [
        ListItem(
            object: CircleType.STANDARD,
            name: AppLocalizations.of(context)!.standardCircleType),
        ListItem(
            object: CircleType.VAULT,
            name: AppLocalizations.of(context)!.vaultCircleType),
        ListItem(
            object: CircleType.OWNER,
            name: AppLocalizations.of(context)!.ownerCircleType),
        ListItem(
            object: CircleType.TEMPORARY,
            name: AppLocalizations.of(context)!.temporaryCircleType)
      ];
    });
  }


  // void _testAsync() async {
  //
  //   //PermissionsAndroid permissionsAndroid = PermissionsAndroid();
  //
  //   //await Permissions.batteryOptimizationGranted(context);
  //   //await permissionsAndroid.batteryOptimizationGranted(context);
  //   BackgroundTaskBloc.testIsolate();
  //
  // }

  @override
  void dispose() {
    //_actionNeededBloc.dispose();
    //_invitationBloc.dispose();
    //_scrollController.dispose();
    _userCircleBloc.dispose();
    _circleObjectBloc.dispose();
    _userFurnaceBloc.dispose();
    _ironCoinBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    globalState.setScaler(MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));

    // globalState.mediaScaleFactor = textScale;
    //debugPrint('TEXT SCAlE FACTOR $textScale');
    globalState.setLocaleAndLanguage(context);

    _circleTypes = [
      AppLocalizations.of(context)!.standardCircleType,
      AppLocalizations.of(context)!.vaultCircleType
    ];
    _circleTypesHidden = [
      AppLocalizations.of(context)!.hiddenCircleType,
      AppLocalizations.of(context)!.standardCircleType,
      AppLocalizations.of(context)!.vaultCircleType
    ];

    hiddenOpen
        ? _circleFilterMenu = _circleTypesHidden
        : _circleFilterMenu = _circleTypes;

    if (_userCircles != null) {
      _filteredUserCircles = [];
      _filteredUserCircles!.addAll(_userCircles);

      // var nullPrefNames = _filteredUserCircles!.where((test) => test.prefName == null);
      //
      // for(UserCircleCache userCircleCache in  nullPrefNames){
      //   userCircleCache.prefName == "";
      // }

      //furnace filter

      if (_furnaceFilter != all) {
        if (_furnaceFilter == hiddenFilter) {
          _filteredUserCircles!
              .retainWhere((userCircle) => userCircle.hiddenOpen == true);
        } else {
          _filteredUserCircles!.retainWhere((userCircle) =>
              _getUserFurnace(userCircle)!.alias == _furnaceFilter);
        }
      }

      if (_circleTypeFilter != all) {
        _filteredUserCircles!
            .retainWhere((a) => a.cachedCircle!.type == _circleTypeFilter);
      }

      if (_sortAlpha!)
        _filteredUserCircles!.sort((a, b) =>
            a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase()));
      else
        _filteredUserCircles!
            .sort((a, b) => b.lastItemUpdate!.compareTo(a.lastItemUpdate!));
    } else {
      _filteredUserCircles = null;
    }

    //if (_userFurnaces != null) debugPrint(_userFurnaces.length);

    final appbar = AppBar(
      //leadingWidth: 10,
      elevation: 0,
      toolbarHeight: 45,
      centerTitle: false,
      titleSpacing: 0.0,
      backgroundColor: globalState.theme.appBar, //globalState.theme.appBar,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      title: Text('IronCircles',
          textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
          style: ICTextStyle.getStyle(
              context: context,
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      actions: <Widget>[
        globalState.selectedHomeIndex == BottomNavigationOptions.NETWORKS
            ? IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  _showContextHelp();
                },
                icon: Icon(Icons.help, color: globalState.theme.menuIcons),
              )
            : Container(),
        globalState.selectedHomeIndex == BottomNavigationOptions.CIRCLES
            ? IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  _showHomeShortCuts();
                },
                icon: Icon(Icons.help, color: globalState.theme.menuIcons),
              )
            : Container(),
        hiddenOpen
            ? IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  _broadcastCloseHiddenCircles();
                },
                icon: Icon(Icons.lock_rounded, color: globalState.theme.button),
              )
            : Container(),
        _furnaceAliases.isNotEmpty
            ? IconButton(
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                onPressed: () {
                  _filterHome();
                },
                icon: Icon(Icons.filter_list_rounded,
                    color: (_circleTypeFilter == all &&
                            _furnaceFilter == all &&
                            _sortAlpha == false &&
                            _sortName == false)
                        ? globalState.theme.menuIcons
                        : globalState.theme.menuIconsAlt),
              )
            : Container(),
        globalState.selectedHomeIndex == BottomNavigationOptions.CIRCLES
            ? IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CircleManage(
                                userFurnaces: _userFurnaces!,
                                memberCircles: _memberCircles,
                                userCircleCaches: _userCircles,
                                userCircleBloc: _userCircleBloc,
                                circles: true,
                              )));
                },
                padding: const EdgeInsets.only(right: _iconPadding),
                constraints: const BoxConstraints(),
                iconSize: 27 - globalState.scaleDownIcons,
                icon: Icon(Icons.tune, color: globalState.theme.menuIcons))
            : Container(),
      ],
      leading: HamburgerIcon(
        walkthroughKey: _homeWalkthrough.hamburger,
        scaffoldKey: _scaffoldKey,
      ),
    );

    final desktopSideBar = Expanded(
        flex: 1,
        child: Container(
            color: globalState.theme.desktopSideBarBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(left: 5, top: 5),
                    child: HamburgerIcon(scaffoldKey: _scaffoldKey)),
                const Padding(padding: EdgeInsets.only(top: 10)),
                Center(
                    child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: globalState.selectedHomeIndex ==
                                  BottomNavigationOptions.CIRCLES
                              ? globalState.theme.desktopSelectedSideBarIcon
                              : globalState.theme.desktopSideBarBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(
                            //Icons.photo_library_rounded,

                            Icons.home,

                            color: globalState.theme.desktopSideBarIcon,
                          ),
                          onPressed: () {
                            globalState.selectedHomeIndex =
                                BottomNavigationOptions.CIRCLES;
                            setState(() {});
                          },
                        ))),
                Center(
                    child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: globalState.selectedHomeIndex ==
                                  BottomNavigationOptions.LIBRARY
                              ? globalState.theme.desktopSelectedSideBarIcon
                              : globalState.theme.desktopSideBarBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(
                            //Icons.photo_library_rounded,
                            Icons.perm_media_rounded,
                            color: globalState.theme.desktopSideBarIcon,
                          ),
                          onPressed: () {
                            globalState.selectedHomeIndex =
                                BottomNavigationOptions.LIBRARY;
                            setState(() {});
                          },
                        ))),
                Center(
                    child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: globalState.selectedHomeIndex ==
                            BottomNavigationOptions.ACTIONS
                        ? globalState.theme.desktopSelectedSideBarIcon
                        : globalState.theme.desktopSideBarBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(alignment: Alignment.topRight, children: [
                    IconButton(
                      icon: Icon(
                        //Icons.photo_library_rounded,
                        Icons.pending_actions,
                        color: (_urgentDone &&
                                _circleObjectDone &&
                                _actionRequired.length +
                                        _circleObjectHighPriority.length >
                                    0)
                            ? globalState.theme.urgentAction
                            : globalState.theme.desktopSideBarIcon,
                      ),
                      onPressed: () {
                        globalState.selectedHomeIndex =
                            BottomNavigationOptions.ACTIONS;
                        setState(() {});
                      },
                    ),
                    (_urgentDone &&
                            _circleObjectDone &&
                            _actionRequired.length +
                                    _circleObjectHighPriority.length >
                                0)
                        ? ICText(
                            (_actionRequired.length +
                                    _circleObjectHighPriority.length)
                                .toString(),
                            color: globalState.theme.urgentAction)
                        : ICText(" ", color: globalState.theme.urgentAction)
                  ]),
                )),
                Center(
                    child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: globalState.selectedHomeIndex ==
                                  BottomNavigationOptions.NETWORKS
                              ? globalState.theme.desktopSelectedSideBarIcon
                              : globalState.theme.desktopSideBarBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(
                            //Icons.photo_library_rounded,
                            Icons.vpn_lock_rounded,
                            color: globalState.theme.desktopSideBarIcon,
                          ),
                          onPressed: () {
                            globalState.selectedHomeIndex =
                                BottomNavigationOptions.NETWORKS;
                            setState(() {});
                          },
                        ))),
                Padding(
                  padding:
                      EdgeInsets.only(bottom: 5, left: 10, right: 5, top: 10),
                  child: Center(
                      child: Container(
                    // width: 40,
                    height: 1,
                    color: Colors.white,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 5),
                  child: Center(
                      child: ICText(
                    AppLocalizations.of(context)!.networks,
                    fontSize: 12,
                    color: globalState.theme.labelText,
                  )),
                ),
                _userFurnaces == null
                    ? Container()
                    : Expanded(
                        child: Center(
                            child: Theme(
                                data: ThemeData(
                                    scrollbarTheme: ScrollbarThemeData(
                                  thumbColor: MaterialStateProperty.all(
                                      Colors.blueGrey.shade800),
                                  trackColor: MaterialStateProperty.all(
                                      globalState.theme.buttonIconHighlight),
                                )),
                                child: Scrollbar(
                                    controller: _networkScroller,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                        itemCount: _userFurnaces!.length,
                                        padding: const EdgeInsets.only(
                                            right: 0, left: 0),
                                        controller: _networkScroller,
                                        scrollDirection: Axis.vertical,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          var item = _userFurnaces![index];

                                          return Center(
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                      color: _filteredFurnace !=
                                                                  null &&
                                                              _filteredFurnace!
                                                                      .alias ==
                                                                  item.alias
                                                          ? globalState.theme
                                                              .desktopSelectedNetwork
                                                          : globalState.theme
                                                              .desktopUnselectedNetwork,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  10))),

                                                  //height: 45,
                                                  //width: 45,
                                                  child: Tooltip(
                                                      message: item.alias!,
                                                      key: GlobalKey(),
                                                      child: InkWell(
                                                        child: ClipOval(
                                                            child: FileSystemService.returnAnyFurnaceImagePath(item
                                                                        .userid!) !=
                                                                    null
                                                                ? Image.file(
                                                                    File(FileSystemService.returnAnyFurnaceImagePath(item
                                                                        .userid!)!),
                                                                    key:
                                                                        GlobalKey(),
                                                                    height:
                                                                        radius,
                                                                    width:
                                                                        radius,
                                                                    fit: BoxFit
                                                                        .cover)
                                                                : Image.asset(
                                                                    'assets/images/ios_icon.png',
                                                                    height:
                                                                        radius,
                                                                    width:
                                                                        radius,
                                                                    fit: BoxFit
                                                                        .fitHeight)),
                                                        onTap: () {
                                                          _setNetworkFilter(
                                                              item.alias!);
                                                        },
                                                      ))));

                                          //return Row(mainAxisAlignment: MainAxisAlignment.end, children:[Text("eee")]);
                                        }))))),
              ],
            )));

    final bottomNavBar = CustomAnimatedBottomBar(
      items: <BottomNavyBarItem>[
        BottomNavyBarItem(
          key: _homeWalkthrough.homeButton,
          icon: const Icon(
            Icons.home,
          ),
          title: Text(
            AppLocalizations.of(context)!.home,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: globalState.theme.button,
          inactiveColor: globalState.theme.inactive,
          textAlign: TextAlign.center,
        ),
        BottomNavyBarItem(
          key: _homeWalkthrough.keyButton1,
          icon: const Icon(
            //Icons.photo_library_rounded,
            Icons.perm_media_rounded,
          ),
          title: Text(
            AppLocalizations.of(context)!.library,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: globalState.theme.button,
          inactiveColor: globalState.theme.inactive,
          textAlign: TextAlign.center,
        ),
        BottomNavyBarItem(
          key: _homeWalkthrough.keyButton3,
          icon: const Icon(
            Icons.pending_actions,
          ),
          title: Text(
            AppLocalizations.of(context)!.actions,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 14),
          ),
          count: (_urgentDone && _circleObjectDone)
              ? (_actionRequired.length + _circleObjectHighPriority.length)
              : 0,
          activeColor: globalState.theme.button,
          inactiveColor: globalState.theme.inactive,
          textAlign: TextAlign.center,
        ),
        BottomNavyBarItem(
          key: _homeWalkthrough.invitationsTarget,
          icon: const Icon(
            Icons.vpn_lock,
          ),
          //count: invitationsCount,
          title: Text(
            AppLocalizations.of(context)!.networks,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: globalState.theme.button,
          inactiveColor: globalState.theme.inactive,
          textAlign: TextAlign.center,
        ),
        /*BottomNavyBarItem(
                      key: _homeWalkthrough.keyButton2,
                      icon: const Icon(
                        Icons.event,
                      ),
                      title: const Text(
                        'Events',
                        textScaleFactor: 1.0,
                        style: TextStyle(fontSize: 14),
                      ),
                      count: 0,
                      activeColor: globalState.theme.button,
                      inactiveColor: globalState.theme.inactive,
                      textAlign: TextAlign.center,
                    ),

                     */

        /*BottomNavyBarItem(
                  icon: Icon(Icons.public),
                  enabled: !globalState.userSetting.minor,
                  title: Text(
                    'Browser',
                    textScaleFactor: 1.0,
                  ),
                  activeColor: globalState.theme.button,
                  inactiveColor: globalState.theme.inactive,
                  textAlign: TextAlign.center,
                )*/
      ],
      onIndexChanged: _selectionChanged,
      backgroundColor: globalState.theme.bottomBackgroundColor,
    );

    return globalState.loggingOut
        ? Container()
        : SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Scaffold(
                key: _scaffoldKey,
                appBar: globalState.isDesktop() ? null : appbar,
                drawer: ICNavigationDrawer(
                    userFurnaces: _userFurnaces ?? [],
                    userCircleBloc: _userCircleBloc),
                backgroundColor: globalState.theme.background,
                body: Stack(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    globalState.isDesktop() ? desktopSideBar : Container(),
                    globalState.selectedHomeIndex ==
                            BottomNavigationOptions.CIRCLES
                        ? Expanded(
                            flex: globalState.isDesktop()
                                ? _desktopLeftSideFlex
                                : 1,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  globalState.isDesktop() == false &&
                                          _invitations.isNotEmpty &&
                                          globalState.dismissInvitations ==
                                              false
                                      ? InkWell(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Invites(
                                                          userFurnaces:
                                                              _userFurnaces!,
                                                          invitations:
                                                              _invitations,
                                                          refreshCallback:
                                                              _refreshInvitations,
                                                          userCircleBloc:
                                                              _userCircleBloc,
                                                        )));
                                          },
                                          child: Container(
                                              height: 35,

                                              ///round corners
                                              decoration: BoxDecoration(
                                                  color: globalState
                                                      .theme.urgentAction
                                                      .withOpacity(.2),
                                                  borderRadius: BorderRadius.only(
                                                      topLeft:
                                                          const Radius.circular(
                                                              10),
                                                      topRight:
                                                          const Radius.circular(
                                                              10),
                                                      bottomLeft: Radius.circular(
                                                          globalState.notification != null
                                                              ? 0
                                                              : 10),
                                                      bottomRight: Radius.circular(
                                                          globalState.notification != null ? 0 : 10))),
                                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                const Spacer(),
                                                ICText(
                                                  '${AppLocalizations.of(context)!.newInvitations}: ${_invitations.length}',
                                                  color: globalState
                                                      .theme.urgentAction,
                                                ),
                                                const Spacer(),
                                              ])))
                                      : Container(),
                                  globalState.notification != null
                                      ? InkWell(
                                          onTap: () async {
                                            ///open full screen title and message
                                            bool? dismiss =
                                                await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            FullOfficialNotification(
                                                              notification:
                                                                  globalState
                                                                      .notification!,
                                                            )));

                                            if (dismiss != null && dismiss) {
                                              _dismissNotification();
                                            }
                                          },
                                          child: Container(
                                              height: 35,
                                              decoration: BoxDecoration(
                                                  color: globalState
                                                      .theme.button
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                        _invitations.isNotEmpty &&
                                                                globalState
                                                                        .dismissInvitations ==
                                                                    false
                                                            ? 0
                                                            : 10),
                                                    topRight: Radius.circular(
                                                        _invitations.isNotEmpty &&
                                                                globalState
                                                                        .dismissInvitations ==
                                                                    false
                                                            ? 0
                                                            : 10),
                                                    bottomLeft:
                                                        const Radius.circular(
                                                            10),
                                                    bottomRight:
                                                        const Radius.circular(
                                                            10),
                                                  )),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    ICText(
                                                      globalState
                                                          .notification!.title,
                                                      color: globalState
                                                          .theme.button,
                                                    ),
                                                    const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 5)),
                                                    InkWell(
                                                      child: ICText(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .dismiss,
                                                        color: globalState.theme
                                                            .buttonIconHighlight,
                                                      ),
                                                      onTap: () {
                                                        ///dismiss the notification
                                                        _dismissNotification();
                                                      },
                                                    )
                                                  ])))
                                      : Container(),
                                  Expanded(
                                      child: Circles(
                                    filterHome: _filterHome,
                                    //startTab: globalState.selectedCircleIndex,
                                    invitations: _invitations,
                                    refreshInvitations: _refreshInvitations,
                                    walkthrough: _homeWalkthrough,
                                    userCircleBloc: _userCircleBloc,
                                    sortAlpha: _sortAlpha == null
                                        ? false
                                        : _sortAlpha!,
                                    sortName:
                                        _sortName == null ? false : _sortName!,
                                    circleNameFilter: _circleNameFilter,
                                    circleTypeFilter: _circleTypeFilter,
                                    memCacheObjects: _memCacheCircleObjects,
                                    replyObjects: _memCacheReplyObjects,
                                    furnaceFilter: _furnaceFilter,
                                    circleVideoBloc: _circleVideoBloc,
                                    furnaces: _furnaceAliases,
                                    sharedMediaHolder: widget.sharedMediaHolder,
                                    showFeed:
                                        globalState.userSetting.unreadFeedOn,
                                    memberCircles: _memberCircles,
                                    enterCircle: globalState.enterCircle,
                                    circleTypeList: _circleTypeList,
                                  ))
                                ]))
                        : globalState.selectedHomeIndex ==
                                BottomNavigationOptions.NETWORKS
                            ? _userFurnaces == null
                                ? Container()
                                : Expanded(
                                    flex: globalState.isDesktop()
                                        ? _desktopLeftSideFlex
                                        : 1,
                                    child: NetworkManagerTabs(
                                        userFurnace: globalState.userFurnace!,
                                        userFurnaces: _userFurnaces!,
                                        openScreen: globalState
                                            .homeShortCutResultScreen))
                            : globalState.selectedHomeIndex ==
                                    BottomNavigationOptions.ACTIONS
                                ? _userFurnaces == null
                                    ? Container()
                                    : Expanded(
                                        flex: globalState.isDesktop()
                                            ? _desktopLeftSideFlex
                                            : 1,
                                        child: ActionNeededScreen(
                                          key: _actionRequiredKey,
                                          userFurnaces: _filteredFurnace == null
                                              ? _userFurnaces!
                                              : [_filteredFurnace!],
                                          actionRequired: _actionRequired,
                                          highPriority:
                                              _circleObjectHighPriority,
                                          lowPriority: _circleObjectLowPriority,
                                          refreshCallback:
                                              _refreshActionRequired,
                                        ))
                                : globalState.selectedHomeIndex ==
                                        BottomNavigationOptions.LIBRARY
                                    ? _userFurnaces == null
                                        ? Container()
                                        : Expanded(
                                            flex: globalState.isDesktop()
                                                ? _desktopLeftSideFlex
                                                : 1,
                                            child: LibraryScreen(
                                                userFurnaces: _userFurnaces!,
                                                // _filteredFurnace == null
                                                //     ? _userFurnaces!
                                                //     : [_filteredFurnace!],
                                                circleVideoBloc:
                                                    _circleVideoBloc,
                                                filteredFurnace:
                                                    _filteredFurnace,
                                                crossObjects:
                                                    _memCacheCircleObjects,
                                                // _filteredFurnace ==
                                                //         null
                                                //     ? _memCacheCircleObjects
                                                //     : _memCacheCircleObjects
                                                //         .where((element) =>
                                                //             element
                                                //                 .userCircleCache!
                                                //                 .userFurnace ==
                                                //             _filteredFurnace!
                                                //                 .pk)
                                                //         .toList(),
                                                slideUpPanel: false,
                                                refreshCallback:
                                                    _refreshActionRequired))
                                    : Container()
                  ])
                ]),
                bottomNavigationBar:
                    globalState.isDesktop() ? null : bottomNavBar));
  }

  _clearFilters() {
    setState(() {
      _filteredCircleType = null;
      _filteredFurnace = null;
      _circleTypeFilter = all;
      globalState.circleTypeFilter = _circleTypeFilter;
      _furnaceFilter = all;
      globalState.lastSelectedFilter = _furnaceFilter;
      _sortName = false;
      _circleNameFilter = '';
      _sortAlpha = false;
    });
  }

  _sortByName(String name) {
    if (mounted) {
      setState(() {
        if (name.isNotEmpty) {
          _sortName = true;
          _circleNameFilter = name;
        } else {
          _sortName = false;
          _circleNameFilter = '';
        }
      });
    }
  }

  _sortByAlpha() {
    if (mounted) {
      setState(() {
        globalState.lastSelectedIndexCircles = null;
        globalState.lastSelectedIndexDMs = null;

        globalState.userSetting.setSortAlpha(!_sortAlpha!);

        _sortAlpha = !_sortAlpha!;
      });

      if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    }
  }

  _setCircleFilter(String value) {
    setState(() {
      if (value == all) {
        _filteredCircleType = null;
      }
      _circleTypeFilter = value;
      globalState.circleTypeFilter = _circleTypeFilter;
    });
  }

  _setNetworkFilter(String value) {
    setState(() {
      ///test to see if the user deselected
      if (value == _furnaceFilter) {
        value = all;
      }

      _furnaceFilter = value;
      globalState.lastSelectedFilter = _furnaceFilter;

      if (value == all) {
        _filteredFurnace = null;
      } else {
        int index =
            _userFurnaces!.indexWhere((element) => element.alias == value);

        if (index != -1) {
          _filteredFurnace = _userFurnaces![index];
        }
      }
    });
  }

  UserFurnace? _getUserFurnace(UserCircleCache userCircleCache) {
    UserFurnace? retValue;

    for (var userFurnace in _userFurnaces!) {
      if (userFurnace.pk == userCircleCache.userFurnace) {
        retValue = userFurnace;
      }
    }

    return retValue;
  }

  Future<void> _refreshDesktop() async {
    _userCircleBloc.fetchAll(false);
  }

  Future<void> _refresh({updatePriority = false}) async {
    _userFurnaceBloc
        .request(globalState.user.id); //this will invoke sink notification

    if (updatePriority) {}
  }

  Future<void> _refreshInvitations(List<Invitation> invitations) async {
    setState(() {
      invitationsCount = invitations.length;
    });

    _invitations = invitations;

    _refresh();
  }

  Future<void> _refreshActionRequired() async {
    await _actionNeededBloc.loadCircleObjects(_userFurnaces!);
    await _actionNeededBloc.loadActionRequired(_userFurnaces!);
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        globalState.setGlobalState();

        if (mounted) {
          globalState.setLocaleAndLanguage(context);
        }
        _refresh();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  _addHiddenFilter(bool add) {
    if (add) {
      /*if (_furnaceAliases.indexOf(hiddenFilter) == -1) {
        _furnaceAliases.add(hiddenFilter);
      }

       */
    } else {
      _furnaceAliases.removeWhere((item) => item == hiddenFilter);

      if (_furnaceFilter == hiddenFilter) {
        _furnaceFilter = all;
        globalState.lastSelectedFilter = all;
      }

      //  });
    }
  }

  _populateFurnaceAliases() {
    _furnaceAliases = [];

    _furnaceAliases.add(all);

    if (hiddenOpen) _furnaceAliases.add(hiddenFilter);

    for (UserFurnace userFurnace in _userFurnaces!) {
      if (userFurnace.connected!) {
        int exists = _furnaceAliases
            .indexWhere((element) => element == userFurnace.alias);

        if (exists != -1) continue;

        _furnaceAliases.add(userFurnace.alias!);
      }
    }
  }

  _selectionChanged(int index) {
    setState(() {
      globalState.lastSelectedIndexCircles = 0.0;
      globalState.lastSelectedIndexDMs = 0.0;
      globalState.selectedHomeIndex = index;
    });
  }

  _showTOS() async {
    bool? accept = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsOfService(
            buttonText: 'CONTINUE',
          ),
        ));

    if (accept != null) {
      UserBloc userBloc = UserBloc();
      userBloc.acceptTOS(globalState.userFurnace!);
    } else {
      _showTOS();
    }
  }

  /*_setAutoBackup() async {
    KeychainBackupBloc keychainBackupBloc = KeychainBackupBloc();
    keychainBackupBloc.toggle(globalState.userFurnace!, true);

    globalState.user.autoKeychainBackup = true;
  }

   */

  _isWallEnabled() {
    bool retValue = false;

    int index =
        _userFurnaces!.lastIndexWhere((element) => element.enableWall == true);

    if (index != -1) retValue = true;

    return retValue;
  }

  _popups() async {
    if (globalState.showHomeTutorial) {
      if (globalState.requestedFromLanding) {
        globalState.requestedFromLanding = false;
        await DialogHomeShortcuts.showRequestPending(context);
      }
      /* await Future.delayed(
        Duration(seconds: 1),
      );*/
      _showHomeShortCuts(firstTime: true);
      globalState.showHomeTutorial = false;
    } else if (globalState.initialLink != null) {
      PendingDynamicLinkData initialLink = globalState.initialLink!;
      globalState.initialLink = null;

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppLink(
              link: initialLink.link.toString(),
            ),
          ));
    } else if (globalState.connectedHostedInvitation != null) {
      String networkName =
          globalState.connectedHostedInvitation!.hostedFurnace.name;
      String inviter = globalState.connectedHostedInvitation!.inviter.username!;
      globalState.connectedHostedInvitation = null;
      DialogNotice.showNoticeOptionalLines(
          context,
          'Network Connected',
          'You have joined $networkName. $inviter has been notified they can send you invitations to Circles now',
          false);
    }

    ///this has been moved from autologin
    else if (globalState.sharedText.isNotEmpty ||
        globalState.sharedMediaCollection.isNotEmpty) {
      ///don't process twice
      String sharedText = globalState.sharedText;
      MediaCollection mediaCollection = globalState.sharedMediaCollection;

      globalState.sharedText = '';
      globalState.sharedMediaCollection = MediaCollection();

      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReceiveShare(
                  sharedText: sharedText,
                  sharedMedia: mediaCollection,
                  userFurnaces: _userFurnaces!,
                )),
      );
    }

    /*if (globalState.showWelcome) {
      await DialogNotice.showNotice(
        context,
        'Welcome to IronCircles!',
        'The menu on the left includes options for creating circles, watching tutorials, reporting issues or requests, and changing your profile.',
        'You can invite others to a Circle by entering and then selecting the Members menu at the top right.',
        "Better (and more) tutorials are on the way.",
        "Feel free to use the report a feature option if you have a question or request.",
      );

      globalState.showWelcome = false;
    }
    //});

     */
  }

  /*_showBackupKeyNeeded() async {
    bool? success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TempBackupKeyNeeded(
            userFurnace: globalState.userFurnace!,
            //buttonText: 'CONTINUE',
          ),
        ));

    if (success != null) {
      //UserBloc userBloc = UserBloc();
      //userBloc.acceptTOS(globalState.userFurnace!);
    } else {
      _showBackupKeyNeeded();
    }
  }

   */

  _showPinNeeded() async {
    /*bool? success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TempSelectPin(
            userFurnace: globalState.userFurnace!,
            //buttonText: 'CONTINUE',
          ),
        ));

    if (success != null) {
      //UserBloc userBloc = UserBloc();
      //userBloc.acceptTOS(globalState.userFurnace!);
    } else {
      _showPinNeeded();
    }

     */
  }

  /*_toggleFeed() {
    setState(() {
      _showFeed = !_showFeed;
      globalState.userSetting.unreadFeedOn = _showFeed;
    });
  }

   */

  void _showWalkthru() {
    _homeWalkthrough.tutorialCoachMark.show(context: context);
  }

  void _showHomeShortCuts({bool firstTime = false}) async {
    if (globalState.selectedCircleTabIndex == 0 &&
        _isWallEnabled() &&
        globalState.isDesktop() == false) {
      DialogHomeShortcuts.showWallHelp(context);
    } else if (globalState.selectedCircleTabIndex == 2) {
      DialogHomeShortcuts.showFriendsHelp(context);
    } else if (globalState.userFurnace!.password != null &&
        globalState.userFurnace!.password!.isNotEmpty) {
      DialogHomeShortcuts.showShortcuts(
          context, true, _showHomeShortCutsResponse, firstTime);
    } else {
      DialogHomeShortcuts.showShortcuts(
          context, false, _showHomeShortCutsResponse, false);
    }
  }

  void _showContextHelp() {
    DialogHomeShortcuts.showNetworkHelp(context);
  }

  void _showMustUpdate() async {
    DialogHomeShortcuts.showMustUpdate(context, false, _showMustUpdateResponse);
  }

  _showMustUpdateResponse(
      DialogMustUpgradeResponse dialogMustUpgradeResponse) async {
    if (dialogMustUpgradeResponse == DialogMustUpgradeResponse.update) {
      _openReleases();
    }
  }

  _openReleases() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Releases()),
    );
  }

  _showHomeShortCutsResponse(
      DialogHomeShortcutsResponse dialogHomeShortcutsResponse) async {
    if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.goInsideVault)
      _goInsideVault();
    else if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.showWalkthru)
      _showWalkthru();
    else if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.inviteFriends)
      _getMagicLink();
    else if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.findNetworks) {
      globalState.homeShortCutResultScreen = HomeNavToScreen.addNetwork;

      setState(() {
        globalState.selectedHomeIndex = 3;
      });
    } else if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.changeGenerated) {
      var result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginChangeGenerated(
              existingPassword: globalState.userFurnace!.password!,
              existingPin: globalState.userFurnace!.pin!,
              username: globalState.userFurnace!.username!,
              screenType: PassScreenType.CHANGE_PASSWORD,
              userFurnace: globalState.userFurnace!,
            ),
          ));

      //if (result != null && result == true) {
      ///delete the action need item
      await _actionNeededBloc.removeChangeGenerated(_actionRequired);
      _refreshActionRequired();
      //_refresh(updatePriority: true);

      //}
    } else if (dialogHomeShortcutsResponse ==
        DialogHomeShortcutsResponse.createCircle) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CircleNewWizardName(
                    userFurnaces: _userFurnaces!,
                    circleTypeList: _circleTypeList,
                  )));

      _refresh();
    }
  }

  void _goInsideVault() async {
    if (_userFurnaces != null) {
      var userCircleCaches = await _userCircleBloc.sinkCache(_userFurnaces!);

      for (UserCircleCache userCircleCache in userCircleCaches) {
        if (userCircleCache.cachedCircle != null) {
          if (userCircleCache.cachedCircle!.type == CircleType.VAULT) {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InsideCircle(
                          replyObjects: const [],
                          memCacheObjects: _memCacheCircleObjects,
                          userCircleCache: userCircleCache,
                          userFurnace: globalState.userFurnace!,
                          hiddenOpen: false,
                          userFurnaces: _userFurnaces,
                        )),
              );
            }

            return;
          }
        }
      }
    }
  }

  void _finish() {
    _showHomeShortCuts();
  }

  _broadcastCloseHiddenCircles() async {

    _furnaceFilter = all;
    globalState.lastSelectedFilter = all;

    _circleTypeFilter = all;
    globalState.circleTypeFilter = all;

    _globalEventBloc.broadcastCloseHiddenCircles();
  }

  _hiddenCirclesClosed() async {
    globalState.hiddenOpen = false;
    await UserCircleBloc.closeHiddenCircles(_firebaseBloc!);
    _memCacheCircleObjects.clear();

    if (_userCircles != null)
      _userCircles.removeWhere((item) => item.hidden == true);

    if (_filteredUserCircles != null)
      _filteredUserCircles!.removeWhere((item) => item.hidden == true);

    _addHiddenFilter(false);

    hiddenOpen = false;

    Navigator.of(context).popUntil((route) => route.isFirst);

    globalState.selectedHomeIndex = 0;

    if (mounted) {
      setState(() {});
    }

    _crossBloc.initialLoad(_userFurnaces!, true, amount: 5000);
  }

  void _postLoadJobs() {
    if (globalState.firstLoadComplete == false) {
      globalState.firstLoadComplete = true;

      ///insert any first load jobs here
      CircleObjectBloc.cleanupStuckObjects();

      _circleObjectBloc.retryFailedInDatabase();

      ///remove after everyone is past v103
      //RatchetKey.ratchetBlankReceiverPrivateKeys();
    }
  }

  bool _openedScreen = false;

  UserCircleCacheAndShare? _enterUserCircle;

  _openScreen(HomeNavToScreen screen) {
    if (screen == HomeNavToScreen.backlog && !_openedScreen) {
      _openedScreen = true;

      ///open the helpcenter
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const HelpCenter()));

      ///then open the backlog
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ReportIssue()));
    } else if (screen == HomeNavToScreen.invitations) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Invites(
                    userFurnaces: _userFurnaces ?? [],
                    invitations: _invitations,
                    refreshCallback: _refreshInvitations,
                    userCircleBloc: _userCircleBloc,
                  )));
    } else if (screen == HomeNavToScreen.giftedIronCoin) {
      if (globalState.userFurnace == null) {
        return;
      }

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CoinLedger(
                    userFurnace: globalState.userFurnace!,
                  )));
    }
  }

  _getMagicLink() async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkInvite(
            userFurnaces: _userFurnaces!,
            //userFurnace: widget.userFurnace,
          ),
        ));
  }

  _dismissNotification() {
    if (globalState.userFurnace != null) {
      ///dismiss the notification
      _userBloc.dismissOfficialNotification(
          globalState.userFurnace!, globalState.notification!);
    }
    setState(() {
      globalState.notification = null;
    });
  }

  _popToHomeEnterCircle(UserCircleCacheAndShare userCircleCacheAndShare) async {
    Navigator.of(context).popUntil((route) => route.isFirst);

    bool wall = false;

    if (userCircleCacheAndShare.userCircleCache.cachedCircle!.type ==
        CircleType.WALL) {
      wall = true;
      globalState.selectedCircleTabIndex = 0;
      //LogBloc.insertLog("popped to Feed", "_popToHomeEnterCircle");
      globalState.selectedHomeIndex = BottomNavigationOptions.CIRCLES;
    }

    globalState.enterCircle = userCircleCacheAndShare;
    debugPrint(
        "******************* FROM HOME globalState.enterCircle: ${globalState.enterCircle == null}");

    globalState.selectedHomeIndex = 0;

    if (mounted) {
      setState(() {});
    }

    ///after setState above finishes
    if (wall) {
      await Future.delayed(const Duration(milliseconds: 100));

      globalState.enterCircle = userCircleCacheAndShare;
      debugPrint(
          "******************* FROM HOME globalState.enterCircle after setState: globalState.enterCircle:${globalState.enterCircle == null}");
      _globalEventBloc.broadcastOpenFeed();
    }
  }

  _popToHomeOpenTab(int tab) async {
    globalState.selectedHomeIndex = tab;
    //globalState.selectedCircleIndex = -1;

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {});
    }
  }

  _popToHomeOpenScreen(HomeNavToScreen screen) async {
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (screen != HomeNavToScreen.nothing) {
      _openScreen(screen);
    }
  }

  _popToHomeOpenShare(SharedMediaHolder shareHolder) async {
    globalState.selectedHomeIndex = BottomNavigationOptions.CIRCLES;
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (shareHolder.sharedMedia != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_context) => ReceiveShare(
                  userFurnaces: _userFurnaces!,
                  sharedMedia: shareHolder.sharedMedia,
                )),
      );
    } else if (shareHolder.sharedGif != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_context) => ReceiveShare(
                  userFurnaces: _userFurnaces!,
                  sharedGif: shareHolder.sharedGif,
                )),
      );
    } else if (shareHolder.sharedText != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_context) => ReceiveShare(
                  userFurnaces: _userFurnaces!,
                  sharedText: shareHolder.sharedText,
                )),
      );
    } else if (shareHolder.sharedVideo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_context) => ReceiveShare(
                  userFurnaces: _userFurnaces!,
                  sharedVideos: [shareHolder.sharedVideo!],
                )),
      );
    } else if (shareHolder.message.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_context) => ReceiveShare(
                  userFurnaces: _userFurnaces!,
                  sharedText: shareHolder.message,
                )),
      );
    }
  }

  _filterHome() {
    DialogFilterHome.filterHomePopup(
        context: context,
        networks: _userFurnaces == null ? [] : _userFurnaces!,
        circleTypes: _circleFilterMenu,
        setNetworkFilter: _setNetworkFilter,
        setCircleTypeFilter: _setCircleFilter,
        sortByAlpha: _sortByAlpha,
        homeTab: globalState.selectedHomeIndex,
        clear: _clearFilters,
        nameFilter: _circleNameFilter,
        existingSort: _sortAlpha!,
        existingName: _sortName!,
        sortByName: _sortByName,
        existingNetworkFilter: _furnaceFilter,
        existingCircleFilter: _circleTypeFilter);
  }
}
