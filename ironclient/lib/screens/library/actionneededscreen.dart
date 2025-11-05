import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/actionneededbloc.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_edit_tabs.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlevotes_edit.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/library/actionrequireditem.dart';
import 'package:ironcirclesapp/screens/library/circleobjectitem.dart';
import 'package:ironcirclesapp/screens/library/genericitem.dart';
import 'package:ironcirclesapp/screens/login/login_changegenerated.dart';
import 'package:ironcirclesapp/screens/login/network_connect_hosted.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_requests.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_tabs.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/screens/settings/settings_accountrecovery.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogyesno.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class ActionNeededScreen extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<ActionRequired> actionRequired;
  final List<CircleObject> highPriority;
  final List<CircleObject> lowPriority;
  final Function refreshCallback;

  const ActionNeededScreen({
    Key? key,
    required this.userFurnaces,
    required this.actionRequired,
    required this.highPriority,
    required this.lowPriority,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  ActionNeededScreenState createState() => ActionNeededScreenState();
}

class ActionNeededScreenState extends State<ActionNeededScreen> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final ActionNeededBloc _actionNeededBloc = ActionNeededBloc();
  final AuthenticationBloc _authenticationBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late UserCircleBloc _userCircleBloc; // = UserCircleBloc();
  late GlobalEventBloc _globalEventBloc;
  late HostedFurnaceBloc _hostedFurnaceBloc;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  //CircleObjectBloc _circleObjectBloc = CircleObjectBloc();
  //List<CircleObject> _circleobjects =[];

  bool filter = false;
  //var _tapPosition;
  //final double _iconSize = 45;

  bool _urgentDone = true;
  bool _circleObjectDone = true;

  final _spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  bool _showSpinner = false;

  List<GenericItem> _items = [];
  List<GenericItem> _itemsActionRequiredStaging = [];
  List<GenericItem> _itemsVotesAndLists = [];
  //List<UserFurnace>? _userFurnaces = [];

  _makeCircleObjectGeneric(CircleObject circleObject) {
    return CircleObjectItem(
        id: circleObject.id,
        circleObject: circleObject,
        userFurnacePK: circleObject.userFurnace!.pk,
        type: ActionRequiredType.CIRCLEOBJECT,
        showFullList: _showFullList,
        showFullVote: _showFullVote);
  }

  _makeGenericActionRequired(ActionRequired actionRequired) {
    return ActionRequiredItem(
        id: actionRequired.id,
        actionRequired: actionRequired,
        userFurnacePK: actionRequired.userFurnace!.pk,
        type: ActionRequiredType.ACTIONNEEDED,
        tapHandler: _navigateToActionRequired,
        dismiss: actionRequired.alertType ==
                ActionRequiredAlertType.USER_JOINED_NETWORK
            ? _confirmDismiss
            : null);
  }

  _makeNetworkRequest(ActionRequired actionRequired) {
    return ActionRequiredItem(
      id: actionRequired.id,
      actionRequired: actionRequired,
      userFurnacePK: actionRequired.userFurnace!.pk,
      type: ActionRequiredType.REQUESTMADE,
      joinNetwork: _joinNetwork,
      dismiss: _confirmDismiss,
      userFurnaces: widget.userFurnaces,
      hostedFurnaceBloc: _hostedFurnaceBloc,
      tapHandler: _navigateToActionRequired,
    );
  }

  _makeRequestApproved(ActionRequired actionRequired) {
    return ActionRequiredItem(
        id: actionRequired.id,
        actionRequired: actionRequired,
        userFurnacePK: actionRequired.userFurnace!.pk,
        type: ActionRequiredType.REQUESTAPPROVED,
        joinNetwork: _joinNetwork,
        dismiss: _confirmDismiss);
  }

  Future<void> refresh() async {
    _userCircleBloc.fetchUserCircles(widget.userFurnaces, true, true);
  }

  @override
  void initState() {
    debugPrint('start: ${DateTime.now()}');

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _globalEventBloc.actionNeededRefresh.listen((refresh) async {
      if (mounted) {
        await _actionNeededBloc.loadCircleObjects(widget.userFurnaces);
        await _actionNeededBloc.loadActionRequired(widget.userFurnaces);
      }
    }, onError: (err) {
      debugPrint("ActionRequired.submitVoteResults.listen: $err");
    }, cancelOnError: false);

    _actionNeededBloc.actionRequired.listen((objects) {
      //_circleobjects = circleobjects;

      _itemsActionRequiredStaging = [];

      for (ActionRequired actionRequired in objects) {
        if (actionRequired.alertType ==
            ActionRequiredAlertType.NETWORK_REQUEST_APPROVED) {
          _itemsActionRequiredStaging.add(_makeRequestApproved(actionRequired));
        } else if (actionRequired.alertType ==
            ActionRequiredAlertType.USER_REQUESTED_JOIN_NETWORK) {
          _itemsActionRequiredStaging.add(_makeNetworkRequest(actionRequired));
        } else {
          _itemsActionRequiredStaging
              .add(_makeGenericActionRequired(actionRequired));
        }
      }

      if (mounted) {
        setState(() {
          //showSpinner = false;
          _circleObjectDone = true;
        });
      }
    }, onError: (err) {
      debugPrint("ActionRequired..actionRequired.listen: $err");
    }, cancelOnError: false);

    _actionNeededBloc.circleObjects.listen((circleobjects) {
      _itemsVotesAndLists = [];
      _itemsVotesAndLists.addAll(_itemsActionRequiredStaging);

      debugPrint(
          'ActionNeededScreen._actionNeededBloc.circleObjects.listen: ${DateTime.now()}');

      for (CircleObject circleObject in circleobjects) {
        if (circleObject.vote != null &&
            circleObject.vote!.type == CircleVoteType.REMOVEMEMBER) {
          if (circleObject.vote!.object != circleObject.userFurnace!.userid!) {
            _itemsVotesAndLists.add(_makeCircleObjectGeneric(circleObject));
          }
        } else {
          _itemsVotesAndLists.add(_makeCircleObjectGeneric(circleObject));
        }
      }

      if (mounted) {
        setState(() {
          //_circleobjects = circleobjects;
          _items = _itemsVotesAndLists;

          _urgentDone = true;
        });
      }
    }, onError: (err) {
      debugPrint("ActionRequired.allCircleObjects.listen: $err");
    }, cancelOnError: false);

    _userCircleBloc.allUserCircles.listen((objects) {
      if (mounted)
        //setState(() {
        _actionNeededBloc.loadActionRequired(widget.userFurnaces);
      // });
    }, onError: (err) {
      debugPrint("ActionRequired.allCircleObjects.listen: $err");
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen(
        (refreshedUserCircleCaches) async {
      if (mounted) {
        debugPrint(
            '_userCircleBloc.refreshedUserCircles: ${refreshedUserCircleCaches.length}');

        await _actionNeededBloc.loadCircleObjects(widget.userFurnaces);
        await _actionNeededBloc.loadActionRequired(widget.userFurnaces);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    for (var object in widget.actionRequired) {
      if (object.alertType ==
          ActionRequiredAlertType.NETWORK_REQUEST_APPROVED) {
        _items.add(_makeRequestApproved(object));
      } else if (object.alertType ==
          ActionRequiredAlertType.USER_REQUESTED_JOIN_NETWORK) {
        _items.add(_makeNetworkRequest(object));
      } else if (object.alertType ==
          ActionRequiredAlertType.USER_REQUESTED_EMPTY) {
        continue;
      } else {
        _items.add(_makeGenericActionRequired(object));
      }
    }
    for (var object in widget.highPriority) {
      if (object.vote!.type == CircleVoteType.REMOVEMEMBER) {
        if (object.vote!.object != object.userFurnace!.userid!) {
          _items.add(_makeCircleObjectGeneric(object));
        }
      }
    }
    for (var object in widget.lowPriority) {
      _items.add(_makeCircleObjectGeneric(object));
    }

    super.initState();
  }

  @override
  void dispose() {
    _actionNeededBloc.dispose();
    _userFurnaceBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //refresh();

    const makeFilter =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Padding(
        padding: EdgeInsets.only(top: 10),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10),
      ),
    ]);

    final makeList = ListView.separated(
        // Let the ListView know how many items it needs to build
        itemCount: _items.length,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 1500,
        separatorBuilder: (context, index) {
          return Container(
            color: globalState.theme.background,
            height: 1,
            width: double.maxFinite,
          );
        },
        itemBuilder: (context, index) {
          try {
            GenericItem item = _items[index];

            if (widget.userFurnaces.length == 1) {
              if (item.userFurnacePK != widget.userFurnaces[0].pk)
                return Container();
            }

            if (item.type == ActionRequiredType.CIRCLEOBJECT) {
              return WrapperWidget(
                  child: item.buildCircleObject(context, index)!);
            } else if (item.type == ActionRequiredType.REQUESTAPPROVED) {
              return WrapperWidget(
                  child: item.buildRequestApproved(context, index)!);
            } else if (item.type == ActionRequiredType.REQUESTMADE) {
              return WrapperWidget(
                  child: item.buildNetworkRequest(context, index)!);
            } else {
              return WrapperWidget(
                  child: item.buildActionRequired(context, index)!);
            }
          } catch (err) {
            LogBloc.insertLog(err.toString(), 'ActionNeeded UI Build error');
            return Container();
          }
        });

    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: globalState.isDesktop()
            ? const ICAppBar(
                title: "Action Needed",
                leadingIndicator: false,
              )
            : null,
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(children: [
              RefreshIndicator(
                  color: globalState.theme.buttonIcon,
                  key: _refreshIndicatorKey,
                  onRefresh: refresh,
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          makeFilter,
                          // Spacer(),
                          Expanded(
                            child: _items.isNotEmpty
                                ? makeList
                                : (!_circleObjectDone || !_urgentDone)
                                    ? _spinkit
                                    : Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .noActionsRequired,
                                              textScaler: TextScaler.linear(
                                                  globalState.labelScaleFactor),
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            )
                                          ],
                                        ),
                                      ),
                          ),
                        ],
                      ))),
              _showSpinner ? _spinkit : Container()
            ])),
      ),
    );
  }

  void _showFullList(int index, CircleObject circleObject) async {
    CircleObject? updatedObject = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CircleListEditTabs(
            circleObject: circleObject,
            //circleList: circleObject.list!,
            userCircleCache: circleObject.userCircleCache,
            userFurnace: circleObject.userFurnace,
            isNew: true,
          ),
        ));

    if (updatedObject != null) {
      setState(() {
        if (updatedObject.list!.complete)
          _items.removeAt(index);
        else {
          updatedObject.userCircleCache = circleObject.userCircleCache;
          updatedObject.userFurnace = circleObject.userFurnace;
          _items[index] = _makeCircleObjectGeneric(updatedObject);
        }
      });

      widget.refreshCallback();
    }
  }

  void _showFullVote(int index, CircleObject circleObject) async {
    CircleObject? updatedObject = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CircleVoteScreen(
            circleObject: circleObject,
            userCircleCache: circleObject.userCircleCache,
            userFurnace: circleObject.userFurnace,
            screenMode: ScreenMode.EDIT,
          ),
        ));

    if (updatedObject != null) {
      setState(() {
        _items.removeAt(index);
      });

      widget.refreshCallback();
    }
  }

  void _showNetworkRequests(int index, ActionRequired actionRequired) async {
    bool? done = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NetworkRequests(
                  userFurnace: actionRequired.userFurnace!,
                  userFurnaces: widget.userFurnaces,
                  hostedFurnaceBloc: _hostedFurnaceBloc,
                  networkRequests: const [],
                  fromActionRequired: true,
                )));

    if (done != null) {
      setState(() {
        _items.removeAt(index);
      });
      widget.refreshCallback();
    }
  }

  void _dismissConfirmed(ActionRequired actionRequired) async {
    await _actionNeededBloc.dismiss(actionRequired);
    refresh();
  }

  void _confirmDismiss(ActionRequired actionRequired) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.dismissTitle,
        AppLocalizations.of(context)!.dismissMessage,
        _dismissConfirmed,
        null,
        false,
        actionRequired);
  }

  void _showPasswordFragment(int index, ActionRequired actionRequired) async {
    try {
      setState(() {
        _showSpinner = true;
      });
      await _authenticationBloc.sendEncryptedBackupKeyFragForResetCode(
          actionRequired.userFurnace!, actionRequired);

      await DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.passwordResetHelpTitle,
          "${actionRequired.resetUser!.getUsernameAndAlias(globalState)} ${AppLocalizations.of(context)!.passwordResetHelpMessage1}",
          AppLocalizations.of(context)!.passwordResetHelpMessage2,
          actionRequired.resetFragment,
          null,
          false);

      setState(() {
        _showSpinner = false;
      });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 1, true);
      setState(() {
        _showSpinner = false;
      });
    }
  }

  void _navigateToActionRequired(
      int index, ActionRequired actionRequired) async {
    if (actionRequired.alertType ==
        ActionRequiredAlertType.SETUP_PASSWORD_ASSIST) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsAccountRecovery(
                  userFurnace: actionRequired.userFurnace!,
                  user: actionRequired.user!)));

      refresh();

      /*if (actionRequired.userFurnace!.authServer!)
       Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Settings(tab: TAB.SECURITY)));
      else
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NetworkDetailTabs(
                      userFurnace: actionRequired.userFurnace,
                      tab: FURNACETAB.PASSWORD,
                    )));*/
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.HELP_WITH_RESET) {
      _showPasswordFragment(index, actionRequired);
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.EXPORT_KEYS) {
      if (actionRequired.userFurnace!.authServer!)
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Settings(tab: TAB.SECURITY)));
      else
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NetworkDetailTabs(
                      refreshNetworkManager: refresh,
                      userFurnace: actionRequired.userFurnace!,
                      tab: FURNACETAB.SECURITY,
                      userFurnaces: widget.userFurnaces,
                    )));
      //_showPasswordFragment(index, actionRequired);
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.CHANGE_GENERATED) {
      var result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginChangeGenerated(
              existingPassword: globalState.userFurnace!.password == null
                  ? ''
                  : globalState.userFurnace!.password!,
              existingPin: globalState.userFurnace!.pin == null
                  ? ''
                  : globalState.userFurnace!.pin!,
              username: globalState.userFurnace!.username!,
              screenType: PassScreenType.CHANGE_PASSWORD,
              userFurnace: globalState.userFurnace!,
            ),
          ));

      //if (result != null && result == true) {
      ///delete the action need item
      await _actionNeededBloc.removeChangeGenerated([actionRequired]);
      refresh();
      //}
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.NETWORK_REQUEST_APPROVED) {
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.USER_JOINED_NETWORK) {
      MemberBloc memberBloc = MemberBloc();
      memberBloc.create(
          globalState, actionRequired.userFurnace!, actionRequired.member!);

      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberProfile(
              userMember: actionRequired.member!,
              userFurnace: actionRequired.userFurnace!,
              showDM: true,
            ),
          ));

      refresh();
    } else if (actionRequired.alertType ==
        ActionRequiredAlertType.USER_REQUESTED_JOIN_NETWORK) {
      _showNetworkRequests(index, actionRequired);
    }
  }

  _cancelRequest(ActionRequired actionRequired) async {
    setState(() {
      _items.remove(actionRequired);
      _actionNeededBloc.dismissNetworkNotification(
          widget.userFurnaces, actionRequired.networkRequest!);
    });
  }

  void _joinNetwork(ActionRequired act) async {
    bool canAddNetwork =
        await PremiumFeatureCheck.canAddNetwork(context, widget.userFurnaces);

    if (canAddNetwork && act.networkRequest != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NetworkConnectHosted(
                    userFurnace: widget.userFurnaces[0],
                    source: Source.fromActionRequired,
                    authServer: false,
                    request: act.networkRequest!,
                    actionRequired: act,
                  )));
    }
  }
}
