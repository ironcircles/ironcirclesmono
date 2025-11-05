import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/invitations_invites.dart';
import 'package:ironcirclesapp/screens/widgets/blinkingtext.dart';
import 'package:provider/provider.dart';


/*
class _TAB {
  static const int INVITATIONS = 0;
  static const int IGNORELIST = 1;
}*/

class Invitations extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final UserFurnace? filteredUserFurnace;
  final Function refreshCallback;
  final UserCircleBloc userCircleBloc;

  const Invitations(
      {Key? key,
      required this.userFurnaces,
      required this.filteredUserFurnace,
      required this.refreshCallback,
      required this.userCircleBloc})
      : super(key: key);

  @override
  _InvitationsState createState() => _InvitationsState();
}

class _InvitationsState extends State<Invitations> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Invitation> _invitations = [];
  bool _invitationsLoaded = false;
  final InvitationBloc _invitationBloc = InvitationBloc();
  late GlobalEventBloc _globalEventBloc;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _globalEventBloc.invitationRefresh.listen((refresh) {
      _invitationBloc.sinkCache(widget.userFurnaces);
    }, onError: (err) {}, cancelOnError: false);

    //Listen for the list of invitations
    _invitationBloc.invitations.listen((invitations) {
      //LogBloc.insertLog("invitations: ${invitations.length}", 'invitations screen listner');
      if (mounted) {
        //LogBloc.insertLog("refreshing screen", 'invitations screen listner');
        setState(() {

          _invitations = invitations;
          _invitationsLoaded = true;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _invitationBloc.sinkCache(widget.userFurnaces);
    _invitationBloc.fetchInvitationsForUser(widget.userFurnaces);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        //initialIndex: 0,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: PreferredSize(
              preferredSize: const Size(30.0, 40.0),
              child: TabBar(
                padding: const EdgeInsets.only(left: 3, right: 3),
                //indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor: globalState.theme.unselectedLabel,
                labelColor: globalState.theme.buttonIcon,
                //isScrollable: true,
                indicatorColor: Colors.black,
                indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10), // Creates border
                    color: Colors.lightBlueAccent.withOpacity(.1)),
                tabs: [
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(AppLocalizations.of(context)!.friends,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              fontSize: 16.0 - globalState.scaleDownTextFont)),
                    ),
                  ),
                  _invitations.isNotEmpty
                      ? Tab(
                          child: Stack(
                              alignment: Alignment.topRight,
                              children: <Widget>[
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    /*Text("INVITATIONS ",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(fontSize: 16.0)),*/
                                    BlinkingText(
                                        size: 16.0 -
                                            globalState.scaleDownTextFont,
                                        text:
                                            'INVITATIONS (${_invitations.length.toString()})',
                                        color: globalState.theme.buttonIcon),
                                    /*Padding(
                                  padding: EdgeInsets.only(left: 0, top: 0),
                                  child: Container(
                                      padding: EdgeInsets.only(left: 0, top: 0),
                                      decoration: BoxDecoration(
                                        color: globalState.theme.menuIconsAlt,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth: 8,
                                        maxHeight: 8,
                                      ))),
                                      */
                                  ]),
                            ]))
                      : Tab(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(AppLocalizations.of(context)!.invitations,
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                    fontSize:
                                        16.0 - globalState.scaleDownTextFont)),
                          ),
                        ),
                ],
              )),

          //drawer: NavigationDrawer(),*/
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: _invitationsLoaded
                ? TabBarView(
                    children: [
                      // Friends(
                      //   userFurnaces: widget.userFurnaces,
                      //   filteredUserFurnace: widget.filteredUserFurnace,
                      // ),
                      Invites(
                          userCircleBloc: widget.userCircleBloc,
                          userFurnaces: widget.userFurnaces,
                          invitations: _invitations,
                          refreshCallback: widget.refreshCallback),
                      /* InvitationBlocked(
                    userFurnaces: userFurnaces,
                    refreshCallback: refreshCallback),*/
                    ],
                  )
                : Container(),
          ),
        ));
  }
}
