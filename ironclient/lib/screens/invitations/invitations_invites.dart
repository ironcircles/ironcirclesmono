import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/invitations_blocked.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class Invites extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<Invitation> invitations;
  final Function refreshCallback;
  final UserCircleBloc userCircleBloc;
  final bool serverRefresh;

  const Invites(
      {Key? key,
      required this.userFurnaces,
      required this.refreshCallback,
      required this.invitations,
      required this.userCircleBloc,
      this.serverRefresh = true})
      : super(key: key);

  @override
  InvitesState createState() => InvitesState();
}

class InvitesState extends State<Invites> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late GlobalEventBloc _globalEventBloc;
  List _invitations = [];
  //ScrollController _scrollController = ScrollController();

  final InvitationBloc _invitationBloc = InvitationBloc();

  final TextEditingController _circleName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  //bool _hidden = false;
  //String _furnace = 'first match';
  //String _ownershipModel = '';
  //List<String> _furnaceList = [];
  //late UserCircleBloc _userCircleBloc;
  List<UserFurnace>? _userFurnaces;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  final MemberBloc _memberBloc = MemberBloc();
  bool _processing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _invitations = widget.invitations;
    _userFurnaces = widget.userFurnaces;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _userFurnaceBloc.userfurnaces.listen((furnaces) async {
      if (mounted) {
        debugPrint('_userFurnaceBloc.userfurnaces.listen');

        _userFurnaces = furnaces;
        if (widget.serverRefresh) {
          _invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);
        }
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    ///Listen for the list of invitations
    _invitationBloc.invitations.listen((invitations) {
      _invitations = invitations;
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });
      }

      /// refresh home
      widget.refreshCallback(invitations);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    ///Listen invitation results
    _invitationBloc.invitationResponse.listen((invitation) {
      debugPrint('hit _invitationBloc.invitationResponse');
      _showSpinner = false;

      ///find and remove the invitation
      widget.invitations.removeWhere((element) => element.id == invitation.id);
      _invitations.removeWhere((element) => element.id == invitation.id);

      if (invitation.status == 'blocked') {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            '${invitation.inviter} ${AppLocalizations.of(context)!.memberBlocked}',
            "",
            2,
            false);
        for (Member m in globalState.members) {
          if (m.memberID == invitation.inviterID) {
            _memberBloc.setBlocked(invitation.userFurnace.userid!, m, true);
          }
        }

        //refresh the list as the user in question may have sent additional invites
        //_invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);
      } else {
        ///reset global state so home refreshes
        globalState.userCircleFetch = null;

        FormattedSnackBar.showSnackbarWithContext(
            context, "Invitation ${invitation.status}", "", 2, false);
      }

      if (widget.serverRefresh == false) {
        Navigator.pop(context);
      }

      _invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);

      _processing = false;

      if (mounted) {
        setState(() {});
      }
    }, onError: (err) {
      debugPrint("error $err");
      _processing = false;
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    if (widget.userFurnaces.isEmpty) {
      _userFurnaceBloc.requestConnected(globalState.user.id);
    } else if (widget.serverRefresh) {
      _invitationBloc.fetchInvitationsForUser(_userFurnaces!, force: true);
    }

    super.initState();
  }

  @override
  void dispose() {
    _circleName.dispose();
    _password.dispose();
    _password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ListTile makeDMInvitationTile(Invitation invitation) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0, color: globalState.theme.boxOutline))),
            child: Icon(Icons.person_add_alt_1,
                color: globalState.theme.buttonIconHighlight),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              ICText(
                  "${AppLocalizations.of(context)!.dm}: ",
                  textScaleFactor: globalState.cardScaleFactor,
                  color: globalState.theme.textFieldLabel,
                  fontSize: 18),
              ICText(_getUserNameAndAlias(invitation),
                  color: globalState.theme.textFieldPerson,
                  textScaleFactor: globalState.cardScaleFactor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ]),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                ICText(
                  "${AppLocalizations.of(context)!.network}: ",
                    textScaleFactor: globalState.cardScaleFactor,
                    color: globalState.theme.textFieldLabel,
                    fontSize: 18),
                const Padding(padding: EdgeInsets.only(left: 5.0)),
                Expanded(
                    child: ICText(
                  invitation.userFurnace.alias!,
                  textScaleFactor: globalState.cardScaleFactor,
                  color: globalState.theme.furnace,
                  fontSize: 18,
                )),
              ],
            ),
          ]),
        );

    ListTile makeCircleInvitationTile(Invitation invitation) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0, color: globalState.theme.boxOutline))),
            child:
                Icon(Icons.add_circle, color: globalState.theme.textFieldLabel),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(children: [
              ICText(
                "${AppLocalizations.of(context)!.circle}: ",
                color: globalState.theme.textFieldLabel,
                textScaleFactor: globalState.cardScaleFactor,
                fontSize: 16,
              ),
              Expanded(
                child: ICText(invitation.circleName,
                    textScaleFactor: globalState.cardScaleFactor,
                    color: globalState.theme.textFieldPerson,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              )
            ]),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                ICText("${AppLocalizations.of(context)!.inviter}: ",
                    textScaleFactor: globalState.cardScaleFactor,
                    fontSize: 16,
                    color: globalState.theme.textFieldLabel),
                const Padding(
                    padding: EdgeInsets.only(left: 5.0, bottom: 5, top: 10)),
                Expanded(
                  child: ICText(_getUserNameAndAlias(invitation),
                      textScaleFactor: globalState.cardScaleFactor,
                      fontSize: 16,
                      color: globalState.theme.textFieldPerson,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ICText("${AppLocalizations.of(context)!.network}: ",
                    textScaleFactor: globalState.cardScaleFactor,
                    fontSize: 16,
                    color: globalState.theme.textFieldLabel),
                const Padding(padding: EdgeInsets.only(left: 5.0)),
                Expanded(
                    flex: 1,
                    child: ICText(
                      invitation.userFurnace.alias!,
                      fontSize: 16,
                      textScaleFactor: globalState.cardScaleFactor,
                      color: globalState.theme.furnace,
                    )),
              ],
            ),
          ]),
        );

    Card makeCard(Invitation invitation) => Card(
        surfaceTintColor: Colors.transparent,
        color: invitation.dm ? globalState.theme.card : globalState.theme.card,
        elevation: 8.0,
        margin: const EdgeInsets.only(bottom: 5.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          invitation.dm
              ? makeDMInvitationTile(invitation)
              : makeCircleInvitationTile(invitation),
          ButtonBar(
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: TextButton(
                    child: Text(AppLocalizations.of(context)!.blockUser,
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 14)),
                    onPressed: () {
                      _blocklist(invitation);
                    },
                  )),
              TextButton(
                child: Text(AppLocalizations.of(context)!.decline,
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(
                        color: globalState.theme.labelTextSubtle,
                        fontSize: 14)),
                onPressed: () {
                  _decline(invitation);
                },
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: TextButton(
                    child: Text(AppLocalizations.of(context)!.accept,
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            color: globalState.theme.buttonIcon, fontSize: 14)),
                    onPressed: () {
                      _accept(invitation);
                    },
                  )),
            ],
          ),
        ]));

    final makeBody = Container(
      color: globalState.theme.background,
      // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _invitations.length,
        itemBuilder: (BuildContext context, int index) {
          return WrapperWidget(child: makeCard(_invitations[index]));
        },
      ),
    );

    List<String> _empty = [ AppLocalizations.of(context)!.noPendingInvitations];

    final makeEmpty = Container(
      //color: globalState.theme.body,
      // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
      padding: const EdgeInsets.only(top: 40),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _empty.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: Text(
              _empty[0],
              textScaler: TextScaler.linear(globalState.labelScaleFactor),
              style:
                  TextStyle(fontSize: 16, color: globalState.theme.labelText),
            ),
          );
        },
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(title: AppLocalizations.of(context)!.invitationsTitle),
            //drawer: NavigationDrawer(),
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: Stack(
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                              child: RefreshIndicator(
                                  key: _refreshIndicatorKey,
                                  color: globalState.theme.buttonIcon,
                                  onRefresh: _refresh,
                                  child: _invitations.isNotEmpty
                                      ? makeBody
                                      : makeEmpty)),
                          //const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 10, bottom: 5),
                            child: GradientButtonDynamic(
                              text: AppLocalizations.of(context)!.viewBlockedUsers,
                              onPressed: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InvitationBlocked(
                                        refreshCallback: widget.refreshCallback,
                                        userFurnaces: widget.userFurnaces,
                                      ),
                                    ));

                                _invitationBloc.fetchInvitationsForUser(
                                    _userFurnaces!,
                                    force: true);
                              },
                            ),
                          ),
                        ]),
                    _showSpinner ? spinkit : Container()
                  ],
                ))));
  }

  Future<void> _refresh() async {
    debugPrint('refresh');
    _userFurnaceBloc.request(globalState.user.id);

    return;
  }

  String _getUserNameAndAlias(Invitation invitation) {
    User user = User(id: invitation.inviterID, username: invitation.inviter);

    return user.getUsernameAndAlias(globalState);
  }

  _decline(Invitation invitation) {
    if (!_processing) {
      setState(() {
        _showSpinner = true;
      });
      _processing = true;
      _invitationBloc.decline(invitation);
    }
  }

  _accept(Invitation invitation) {
    if (!_processing) {
      setState(() {
        _showSpinner = true;
      });
      _processing = true;
      _invitationBloc.accept(widget.userCircleBloc, invitation);
    }
  }

  _blocklist(Invitation invitation) {
    _invitationBloc.addToBlockedListFromInvitation(invitation);
  }
}
