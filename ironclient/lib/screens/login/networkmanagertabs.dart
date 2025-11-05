import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/screens/login/networkmanager.dart';
import 'package:ironcirclesapp/screens/login/networkmanager_requests.dart';
import 'package:ironcirclesapp/screens/widgets/blinkingicon.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:provider/provider.dart';

enum NETWORKMANAGERTABS { networks, requests }

class NetworkManagerTabs extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final String? toast;
  final HomeNavToScreen openScreen;

  const NetworkManagerTabs({
    Key? key,
    this.toast,
    required this.userFurnace,
    required this.userFurnaces,
    required this.openScreen,
  }) : super(key: key);

  @override
  _NetworkManagerTabsState createState() => _NetworkManagerTabsState();
}

class _NetworkManagerTabsState extends State<NetworkManagerTabs> {
  bool requestNotification = false;
  late FirebaseBloc _firebaseBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  @override
  void initState() {
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    _firebaseBloc.requestsUpdated.listen((bool Bool) {
      if (mounted) {
        if (Bool == true) {
          setState(() {
            requestNotification = true;
          });
        }
      }
    });

    super.initState();
  }

  List<Widget> tabViews() {
    return [
      NetworkManager(
          userFurnaceBloc: _userFurnaceBloc,
          toast: widget.toast,
          openScreen: widget.openScreen),
      NetworkManagerRequests(
        userFurnaceBloc: _userFurnaceBloc,
        userFurnace: widget.userFurnace,
        userFurnaces: widget.userFurnaces,
        toast: widget.toast,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Tab(
          child: Align(
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.networks,
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(fontSize: 17.0 - globalState.scaleDownTextFont)),
      )),
      Tab(
          child: Align(
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.requests,
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(fontSize: 17.0 - globalState.scaleDownTextFont)),
      ))
    ];

    final tabsWithNotification = [
      Tab(
          child: Align(
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.networks,
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(fontSize: 17.0 - globalState.scaleDownTextFont)),
      )),
      Tab(
          child: Stack(children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.requests,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(fontSize: 17.0 - globalState.scaleDownTextFont)),
        ),
        Align(alignment: Alignment.centerRight, child: BlinkIcon()),
      ]))
    ];

    final body = DefaultTabController(
        length: 2,
        initialIndex: NETWORKMANAGERTABS.networks.index,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: PreferredSize(
              preferredSize: const Size(30.0, 40.0),
              child: TabBar(
                  dividerHeight: 0.0,
                  padding: const EdgeInsets.only(left: 3, right: 3),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: -10.0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  tabAlignment: globalState.isDesktop()
                      ? TabAlignment.center
                      : TabAlignment.start,
                  unselectedLabelColor: globalState.theme.unselectedLabel,
                  labelColor: globalState.theme.buttonIcon,
                  isScrollable: true,
                  indicatorColor: Colors.black,
                  indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.lightBlueAccent.withOpacity(.1)),
                  tabs: requestNotification == true
                      ? tabsWithNotification
                      : tabs)),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: TabBarView(
              children: tabViews(),
            ),
          ),
        ));

    return Scaffold(
        /*appBar: ICAppBar(
        title: 'Network Manager',
      ),

       */
        appBar: globalState.isDesktop()
            ? const ICAppBar(
                title: "Network Manager",
                leadingIndicator: false,
              )
            : null,
        backgroundColor: globalState.theme.background,
        body: Padding(
            padding:
                const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(child: body),
                ])));
  }
}
