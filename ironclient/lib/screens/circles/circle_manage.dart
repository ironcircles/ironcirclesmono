import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/circle_hide.dart';
import 'package:ironcirclesapp/screens/circles/circle_manage_row.dart';
import 'package:ironcirclesapp/screens/circles/circle_openhidden.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_container.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

class CircleManage extends StatefulWidget {
  final List<UserCircleCache> userCircleCaches;
  final List<MemberCircle> memberCircles;
  final UserCircleBloc userCircleBloc;
  final bool circles;
  final List<UserFurnace> userFurnaces;

  // FlutterManager({Key key, this.title}) : super(key: key);
  const CircleManage({
    Key? key,
    required this.userCircleCaches,
    required this.userCircleBloc,
    required this.circles,
    required this.memberCircles,
    required this.userFurnaces,
  }) : super(key: key);
  // final String title;

  @override
  _CircleManageState createState() => _CircleManageState();
}

class _CircleManageState extends State<CircleManage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<int> _pin = [];
  //bool _hidden = false;
  //bool _showPassword = false;

  //String? _furnace = 'all';
  //String _ownershipModel = '';
  // List<String?> _furnaceList = [];
  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  late FirebaseBloc _firebaseBloc;

  //UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //List<UserFurnace>? _userFurnaces;
  List<UserCircleCache> _userCircleCaches = [];

  late Color _rowItemColor;

  bool showSpinner = true;

  final _spinkit = SpinKitDualRing(color: globalState.theme.spinner, size: 60);

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${DateTime.now()}');

    _rowItemColor = globalState.theme.buttonIcon;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    _userCircleBloc.updateResponse.listen(
      (userCircleCache) {
        if (mounted) {
          //debugPrint('CircleManagerManage._userCircleBloc.updateResponse');
          _userCircleBloc.sinkOnly(widget.userFurnaces, includeClosed: true);

          //refresh home
          widget.userCircleBloc.sinkOnly(
            widget.userFurnaces,
            includeClosed: false,
          );
        }
      },
      onError: (err) {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          1,
          true,
        );
        debugPrint("error $err");
      },
      cancelOnError: false,
    );

    _userCircleBloc.allUserCircles.listen(
      (userCircleCaches) {
        if (mounted) {
          //debugPrint('Event listener: ${DateTime.now()}');

          userCircleCaches.removeWhere((element) => element.prefName == null);
          userCircleCaches.removeWhere(
            (element) => element.cachedCircle!.type == CircleType.WALL,
          );

          userCircleCaches.sort((a, b) {
            return a.prefName!.toLowerCase().compareTo(
              b.prefName!.toLowerCase(),
            );
          });
          //debugPrint('After sort: ${DateTime.now()}');
          setState(() {
            showSpinner = false;
            _userCircleCaches = userCircleCaches;
          });
          //debugPrint('After setstate: ${DateTime.now()}');
        }
      },
      onError: (err) {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          2,
          true,
        );
      },
      cancelOnError: false,
    );

    //debugPrint('Sink only: ${DateTime.now()}');

    //_userCircleCaches.addAll(widget.userCircleCaches);

    // _userCircleCaches.sort((a, b) {
    //  return a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase());
    // });

    _userCircleBloc.sinkOnly(widget.userFurnaces, includeClosed: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*
  _goHome() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),
        (Route<dynamic> route) => false);
  }

   */

  @override
  Widget build(BuildContext context) {
    ///Uncomment below to separate Circles and DM management
    //_filteredCircles = _userCircleCaches;
    /*_filteredCircles = _userCircleCaches
        .where((element) => element.dm != widget.circles)
        .toList();

     */

    final makeBody = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
        // color: Colors.black,
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
        child: ListView.separated(
          separatorBuilder:
              (context, index) => Divider(color: globalState.theme.divider),
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: _userCircleCaches.length,
          itemBuilder: (BuildContext context, int index) {
            UserCircleCache row = _userCircleCaches[index];

            return CircleManageRow(
              row: row,
              close: _close,
              closeHidden: _closeHidden,
              pinCircle: _pinCircle,
              memberCircles: widget.memberCircles,
              hide: _hide,
              mute: _mute,
              open: _open,
              pinCheck: _pinCheck,
              setCircleGuarded: _setCircleGuarded,
              unhide: _unhide,
              rowItemColor: _rowItemColor,
              openCircle: _openCircle,
            );
          },
        ),
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      appBar: ICAppBar(
        title:
            AppLocalizations.of(
              context,
            )!.manageCirclesDMs, //'Manage Circles/DMs',
        actions: [
          IconButton(
            //padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.help, color: globalState.theme.menuIcons),
            onPressed: () {
              if (globalState.userSetting.allowHidden) {
                _showHiddenNotice();
              } else {
                _showNotice();
              }
            },
          ),
          globalState.userSetting.allowHidden
              ? IconButton(
                //padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.vpn_key_rounded),
                //iconSize: 35,
                color: globalState.theme.unlock,
                onPressed: () {
                  _goToHidden();
                },
              )
              : Container(),
        ],
      ),
      //drawer: NavigationDrawer(),
      body: SafeArea(
        left: true,
        top: true,
        right: true,
        bottom: true,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[Expanded(child: makeBody)],
            ),
            showSpinner ? _spinkit : Container(),
          ],
        ),
      ),
    );
  }

  _openCircle(
    UserCircleCache userCircleCache, {
    bool guardPinAccepted = false,
  }) async {
    // Check if circle is guarded
    if (userCircleCache.guarded! && !guardPinAccepted) {
      _clickedUserCircleCache = userCircleCache;
      await DialogPatternCapture.capture(
        context,
        _pinCapturedForOpen,
        AppLocalizations.of(context)!.swipePatternToEnter,
      );
      return;
    }

    // Find the associated user furnace
    UserFurnace? userFurnace;
    try {
      userFurnace = widget.userFurnaces.firstWhere(
        (furnace) => furnace.pk == userCircleCache.userFurnace,
      );
    } catch (e) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          "Unable to open this circle/DM",
          "",
          2,
          true,
        );
      }
      return;
    }

    // Navigate to the circle/DM
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InsideCircleContainer(
              userCircleCache: userCircleCache,
              userFurnace: userFurnace!,
              hiddenOpen: userCircleCache.hiddenOpen,
              userFurnaces: widget.userFurnaces,
              memCacheObjects: const [],
              refresh: () {
                _userCircleBloc.sinkOnly(
                  widget.userFurnaces,
                  includeClosed: true,
                );
              },
              dismissByCircle: (UserCircleCache ucc, UserFurnace uf) {},
            ),
      ),
    );

    // Refresh the list after returning
    if (mounted) {
      _userCircleBloc.sinkOnly(widget.userFurnaces, includeClosed: true);
    }
  }

  _pinCapturedForOpen(List<int> pin) {
    if (_clickedUserCircleCache != null) {
      if (_clickedUserCircleCache!.checkPin(pin)) {
        _openCircle(_clickedUserCircleCache!, guardPinAccepted: true);
      } else {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.patternsDoNotMatch,
          "",
          2,
          true,
        );
      }
    }
  }

  _goToHidden() async {
    // if (!globalState.user.allowClosed) return;
    bool? success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CircleOpenHidden()),
    );

    if (success != null && success == true) {
      _userCircleBloc.sinkOnly(widget.userFurnaces, includeClosed: true);

      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.opened,
          "",
          3,
          false,
        );
      }
    }
  }

  _closeCallback(UserCircleCache row) {
    _userCircleBloc.updateClosed(row, true);
  }

  _closeHidden(UserCircleCache row) {
    _userCircleBloc.closeHidden(_firebaseBloc, row);
  }

  _close(UserCircleCache row) async {
    /*String? passcode = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CloseCircle(),
        ));

    if (passcode != null) {
      if (passcode.isEmpty)
        _closeCallback(row);
      else
        _hideCallback(row, passcode);
    }

     */

    _closeCallback(row);
  }

  _hide(UserCircleCache row) async {
    String? passcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CircleHide(
              userFurnaces: widget.userFurnaces,
              userCircleCache: row,
            ),
      ),
    );

    if (passcode != null) {
      if (passcode.isNotEmpty) _hideCallback(row, passcode);
    }
  }

  _open(UserCircleCache row) async {
    _userCircleBloc.updateClosed(row, false);
    FormattedSnackBar.showSnackbarWithContext(
      context,
      AppLocalizations.of(context)!.opening,
      "",
      1,
      false,
    );
  }

  _pinCircle(UserCircleCache row) async {
    if (row.pinned) {
      row.pinned = false;
      _userCircleBloc.updatePinned(row);
      FormattedSnackBar.showSnackbarWithContext(
        context,
        AppLocalizations.of(context)!.circleUnpinned,
        "",
        1,
        false,
      );
    } else {
      row.pinned = true;
      _userCircleBloc.updatePinned(row);
      FormattedSnackBar.showSnackbarWithContext(
        context,
        AppLocalizations.of(context)!.circlePinned,
        "",
        1,
        false,
      );
    }
  }

  _mute(UserCircleCache row) async {
    if (row.closed)
      FormattedSnackBar.showSnackbarWithContext(
        context,
        AppLocalizations.of(context)!.closedCircleCannotBeMuted,
        "",
        1,
        false,
      );
    else {
      _userCircleBloc.updateMutedNoFurnace(row, !row.muted);
      if (row.muted)
        FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.unmuting,
          "",
          1,
          false,
        );
      else
        FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.muting,
          "",
          1,
          false,
        );
    }
  }

  _hideCallback(UserCircleCache row, String passcode) {
    row.hiddenOpen = true;
    row.hidden = true;

    _userCircleBloc.hide(_firebaseBloc, row, true, passcode);
  }

  _unhide(UserCircleCache row) {
    DialogYesNo.askYesNo(
      context,
      row.dm
          ? AppLocalizations.of(context)!.unhideDMTitle
          : AppLocalizations.of(context)!.unhideCircleTitle,
      row.dm
          ? AppLocalizations.of(context)!.unhideDMMessage
          : AppLocalizations.of(context)!.unhideCircleMessage,
      _unhideConfirm,
      null,
      false,
      row,
    );
  }

  _unhideConfirm(UserCircleCache row) {
    row.hiddenOpen = false;
    row.hidden = false;

    _userCircleBloc.hide(_firebaseBloc, row, false, '');
  }

  UserCircleCache? _guarded;

  _unguard(UserCircleCache row) {
    row.guarded = false;
    _userCircleBloc.unguard(null, row);

    FormattedSnackBar.showSnackbarWithContext(
      context,
      AppLocalizations.of(context)!.swipePatternRemoved,
      "",
      2,
      false,
    );
  }

  _setCircleGuarded(UserCircleCache row) async {
    _guarded = row;

    await DialogPatternCapture.capture(
      context,
      _pin1Captured,
      AppLocalizations.of(context)!.swipePattern,
    );
  }

  _pin1Captured(List<int> pin) async {
    debugPrint(pin.toString());
    _pin = pin;
    await DialogPatternCapture.capture(
      context,
      _pin2Captured,
      AppLocalizations.of(context)!.pleaseReswipePattern,
    );
  }

  _pin2Captured(List<int> pin) {
    setState(() {
      if (listEquals(pin, _pin)) {
        _userCircleBloc.setPin(null, _guarded!, pin);
      } else {
        FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.patternsDoNotMatch,
          "",
          2,
          false,
        );
      }
    });
  }

  UserCircleCache? _clickedUserCircleCache;

  _pinCheck(UserCircleCache row) {
    _clickedUserCircleCache = row;

    DialogPatternCapture.capture(
      context,
      _pinCaptured,
      AppLocalizations.of(context)!.swipePatternToEnter,
    );
  }

  _pinCaptured(List<int> pin) {
    try {
      //String pinString = UserCircleCache.pinToString(pin);

      if (_clickedUserCircleCache != null) {
        if (_clickedUserCircleCache!.checkPin(pin)) {
          _unguard(_clickedUserCircleCache!);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaputured: $err');
    }
  }

  _showHiddenNotice() {
    DialogNotice.showNotice(
      context,
      widget.circles
          ? AppLocalizations.of(context)!.circleOptionsTitle
          : AppLocalizations.of(context)!.dmOptionsTitle,
      AppLocalizations.of(context)!.circleDmOptionsMuting,
      AppLocalizations.of(context)!.circleDmOptionsClosing,
      AppLocalizations.of(context)!.circleDmOptionsGuarding,
      AppLocalizations.of(context)!.circleDmOptionsHiding,
      false,
    );
  }

  _showNotice() {
    DialogNotice.showNotice(
      context,
      widget.circles
          ? AppLocalizations.of(context)!.circleOptionsTitle
          : AppLocalizations.of(context)!.dmOptionsTitle,
      AppLocalizations.of(context)!.circleDmOptionsMuting,
      AppLocalizations.of(context)!.circleDmOptionsClosing,
      AppLocalizations.of(context)!.circleDmOptionsGuarding,
      null,
      false,
    );
  }
}
