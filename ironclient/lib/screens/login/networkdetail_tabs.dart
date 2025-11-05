import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
import 'package:ironcirclesapp/screens/login/networkdetail.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_health.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_members.dart';
import 'package:ironcirclesapp/screens/settings/settings_general.dart';
import 'package:ironcirclesapp/screens/settings/settings_security.dart';
import 'package:ironcirclesapp/screens/widgets/blinkingicon.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

class FURNACETAB {
  static const int DETAIL = 0;
  static const int PROFILE = 1;
  static const int SECURITY = 2;
  static const int REQUESTS = 3;
}

class NetworkDetailTabs extends StatefulWidget {
  final UserFurnace userFurnace;
  final int tab;
  final List<UserFurnace> userFurnaces;
  final bool showOnlyProfile;
  final Function refreshNetworkManager;
  // FlutterManager({Key key, this.title}) : super(key: key);
  const NetworkDetailTabs(
      {Key? key,
      this.tab = 0,
      required this.userFurnace,
      required this.userFurnaces,
      required this.refreshNetworkManager,
      this.showOnlyProfile = false})
      : super(key: key);
  // final String title;
  @override
  FurnaceTabState createState() => FurnaceTabState();
}

class FurnaceTabState extends State<NetworkDetailTabs>
    with SingleTickerProviderStateMixin {
  UserFurnace? localFurnace;
  User localUser = User();
  bool requestNotification = false;
  late FirebaseBloc _firebaseBloc;
  late GlobalEventBloc _globalEventBloc;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  //List<NetworkRequest> _requests = [];
  late HostedFurnace hostedFurnace;

  late TabController _tabController;
  bool changed = false;

  @override
  void initState() {
    localFurnace = widget.userFurnace;
    localUser.userFurnace = localFurnace;
    localUser.username = localFurnace!.username;
    localUser.id = localFurnace!.userid;

    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    int tabLength = getTabLength();

    _tabController = TabController(length: tabLength, vsync: this);

    _firebaseBloc.networkRequestsUpdated.listen((success) {
      if (mounted) {
        if (success == true) {
          setState(() {
            requestNotification = true;
          });
        }
      }
    });

    _hostedFurnaceBloc.requestsBlinkStop.listen((success) {
      if (mounted) {
        setState(() {
          requestNotification = false;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    ///if there are any requests there should be the dot icon
    _hostedFurnaceBloc.networkRequests.listen((networkRequests) {
      if (mounted) {
        if (networkRequests.isNotEmpty) {
          var pendingRequests = networkRequests
              .where(
                  (element) => element.status == NetworkRequestStatus.PENDING)
              .toList();

          setState(() {
            requestNotification = pendingRequests.isEmpty ? false : true;
          });
        } else {
          setState(() {
            requestNotification = false;
          });
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.networkRetrieved.listen((networkRetrieved) {
      if (mounted) {
        setState(() {
          hostedFurnace = networkRetrieved;

          if (widget.userFurnace.role == Role.OWNER ||
              widget.userFurnace.role == Role.ADMIN ||
              widget.userFurnace.role == Role.IC_ADMIN) {
            _hostedFurnaceBloc.getNetworkRequests(widget.userFurnace);
          }
        });
      }
    });

    _hostedFurnaceBloc.getHostedFurnace(_globalEventBloc, widget.userFurnace);

    super.initState();
  }

  void _refreshFurnace(userFurnace) {
    setState(() {
      localFurnace = userFurnace;
    });
  }

  List<Widget> profileTabsView() {
    return [
      SettingsGeneral(
        userFurnace: localFurnace,
        fromFurnaceManager: true,
      ),
    ];
  }

  List<Widget> tabDetailProfileView() {
    return [
      NetworkDetail(
        userFurnace: localFurnace!,
        refreshNetworkManager: widget.refreshNetworkManager,
        refreshTabs: _refreshFurnace,
        userFurnaces: widget.userFurnaces,
      ),
      SettingsGeneral(
        userFurnace: localFurnace,
        fromFurnaceManager: true,
      ),
      NetworkDetailMembers(
        userFurnace: localFurnace!,
        refreshTabs: _refreshFurnace,
        userFurnaces: widget.userFurnaces,
        hostedFurnaceBloc: _hostedFurnaceBloc,
      ),
      NetworkDetailHealth()
    ];
  }

  List<Widget> tabDetailProfileSecurityView() {
    return [
      NetworkDetail(
        userFurnace: localFurnace!,
        refreshNetworkManager: widget.refreshNetworkManager,
        refreshTabs: _refreshFurnace,
        userFurnaces: widget.userFurnaces,
      ),
      SettingsGeneral(
        userFurnace: localFurnace,
        fromFurnaceManager: true,
      ),
      SettingsSecurity(user: localUser, userFurnace: localFurnace),
      NetworkDetailMembers(
        userFurnace: localFurnace!,
        refreshTabs: _refreshFurnace,
        userFurnaces: widget.userFurnaces,
        hostedFurnaceBloc: _hostedFurnaceBloc,
      ),
      NetworkDetailHealth()
    ];
  }

  List<Widget> tabDisconnectedView() {
    return [
      NetworkDetail(
        userFurnace: localFurnace!,
        refreshNetworkManager: widget.refreshNetworkManager,
        refreshTabs: _refreshFurnace,
        userFurnaces: widget.userFurnaces,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final tabDisconnected = [
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.detailCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
    ];

    final tabOnlyProfile = [
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.profileCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
    ];

    final tabDetailProfileSecurity = [
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.detailCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.profileCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.security.toUpperCase(),
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
      requestNotification == false ||
              (localFurnace!.role != Role.OWNER &&
                  localFurnace!.role != Role.ADMIN &&
                  localFurnace!.role != Role.IC_ADMIN)
          ? Tab(
              child: Align(
              alignment: Alignment.center,
              child: Text(AppLocalizations.of(context)!.mEMBERS,
                  textScaler: const TextScaler.linear(1.0),
                  style: const TextStyle(fontSize: 17.0)),
            ))
          : Tab(
              child: Stack(alignment: Alignment.centerRight, children: <Widget>[
              Text("${AppLocalizations.of(context)!.mEMBERS}  ",
                  textScaler: const TextScaler.linear(1.0),
                  style: const TextStyle(fontSize: 17.0)),
              BlinkIcon(),
            ])),
      Tab(
          child: Align(
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.healthCaps,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 17.0)),
      ))
    ];

    final tabDetailProfile = [
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.detailCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
      Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.profileCaps,
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(fontSize: 17.0)),
        ),
      ),
      requestNotification == false ||
              (localFurnace!.role != Role.OWNER &&
                  localFurnace!.role != Role.ADMIN &&
                  localFurnace!.role != Role.IC_ADMIN)
          ? Tab(
              child: Align(
              alignment: Alignment.center,
              child: Text(AppLocalizations.of(context)!.mEMBERS,
                  textScaler: const TextScaler.linear(1.0),
                  style: const TextStyle(fontSize: 17.0)),
            ))
          : Tab(
              child: Stack(alignment: Alignment.centerRight, children: <Widget>[
              Text("${AppLocalizations.of(context)!.mEMBERS}  ",
                  textScaler: const TextScaler.linear(1.0),
                  style: const TextStyle(fontSize: 17.0)),
              BlinkIcon(),
            ])),
      Tab(
          child: Align(
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.healthCaps,
            textScaler: const TextScaler.linear(1.0),
            style: const TextStyle(fontSize: 17.0)),
      ))
    ];

    final body = DefaultTabController(
        length: getTabLength(),
        initialIndex: widget.tab,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(children: [
              (widget.userFurnace.memberAutonomy == false &&
                          widget.userFurnace.role == Role.MEMBER) ||
                      globalState.isDesktop()
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GradientButton(
                        width: screenWidth - 20,
                        onPressed: _getMagicLink,
                        text: AppLocalizations.of(context)!.shareMagicLink,
                      ),
                    ),
              TabBar(
                  tabAlignment: TabAlignment.start,
                  dividerHeight: 0.0,
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: -10.0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  unselectedLabelColor: globalState.theme.unselectedLabel,
                  labelColor: globalState.theme.buttonIcon,
                  isScrollable: true,
                  indicatorColor: Colors.black,
                  indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Creates border
                      color: Colors.lightBlueAccent.withOpacity(.1)),
                  tabs: widget.showOnlyProfile
                      ? tabOnlyProfile
                      : localFurnace!.connected == false
                          ? tabDisconnected
                          : localFurnace!.authServer == false &&
                                  localFurnace!.linkedUser == null
                              ? tabDetailProfileSecurity
                              : tabDetailProfile),
              const Padding(
                padding: EdgeInsets.only(top: 15),
              ),
              Expanded(
                  child: TabBarView(
                      controller: _tabController,
                      children: widget.showOnlyProfile
                          ? profileTabsView()
                          : localFurnace!.connected == false
                              ? tabDisconnectedView()
                              : localFurnace!.authServer == false &&
                                      localFurnace!.linkedUser == null
                                  ? tabDetailProfileSecurityView()
                                  : tabDetailProfileView()))
            ]),
          ),
        ));

    return Scaffold(
      appBar: ICAppBar(
        title: (widget.userFurnace.alias != null)
            ? widget.userFurnace.alias!
            : AppLocalizations.of(context)!.network,
      ),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: body),
              //makeBottom,
            ],
          )),
    );
  }

  _getMagicLink() async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkInvite(
            userFurnaces: [widget.userFurnace],
            userFurnace: widget.userFurnace,
          ),
        ));
  }

  //
  // localFurnace!.role == Role.OWNER ||
  // localFurnace!.role == Role.ADMIN ||
  // localFurnace!.role == Role.IC_ADMIN
  // ? localFurnace!.standalone
  // ? localFurnace!.authServer!
  // ? tabOwnerStandaloneAuthView()
  //     : tabOwnerStandaloneView()
  //     : tabOwnerHostedView()
  //     : localFurnace!.standalone
  // ? localFurnace!.authServer!
  // ? tabMemberStandaloneAuthView()
  //     : tabMemberStandaloneView()
  //     : tabMemberHostedView()))

  int getTabLength() {
    int length = widget.showOnlyProfile
        ? 1
        : localFurnace!.connected! == false
            ? 1
            : localFurnace!.authServer == false &&
                    localFurnace!.linkedUser == null
                ? 5
                : 4;
    return length;
  }

  // int getTabLength() {
  //   int length = widget.showOnlyProfile
  //       ? 1
  //       : localFurnace!.connected! == false
  //           ? 1
  //           : localFurnace!.role == Role.OWNER ||
  //                   localFurnace!.role == Role.ADMIN ||
  //                   localFurnace!.role == Role.IC_ADMIN
  //               ? localFurnace!.standalone
  //                   ? 3
  //                   : localFurnace!.linkedUser != null
  //                       ? 4
  //                       : 5
  //               : localFurnace!.standalone
  //                   ? 3
  //                   : localFurnace!.linkedUser != null
  //                       ? 4
  //                       : 5;
  //
  //   return length;
  // }

  refreshTabs() {}
}
