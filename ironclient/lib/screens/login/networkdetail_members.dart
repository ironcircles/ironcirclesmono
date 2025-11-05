import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_requests.dart';
import 'package:ironcirclesapp/screens/widgets/dialogsharemagiclink.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class NetworkDetailMembers extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final Function refreshTabs;
  final HostedFurnaceBloc hostedFurnaceBloc;

  // FlutterManager({Key key, this.title}) : super(key: key);
  const NetworkDetailMembers(
      {Key? key,
      required this.userFurnace,
      required this.refreshTabs,
      required this.userFurnaces,
      required this.hostedFurnaceBloc})
      : super(key: key);
  // final String title;

  @override
  NetworkMembersState createState() => NetworkMembersState();
}

class NetworkMembersState extends State<NetworkDetailMembers> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final userFurnaceBloc = UserFurnaceBloc();
  late final GlobalEventBloc _globalEventBloc;
  List _members = [];
  bool _editingPrivileges = false;
  List<NetworkRequest> _requests = [];

  UserFurnace? localFurnace;
  double radius = 200 - (globalState.scaleDownTextFont * 2);

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    widget.hostedFurnaceBloc.networkRequests.listen((networkRequests) {
      if (mounted) {
        setState(() {
          _requests = networkRequests;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.hostedFurnaceBloc.lockedOut.listen((member) {
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });
      }

      if (member.lockedOut)
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.lockedOut.toLowerCase(),
            "",
            2,
            false);
      else
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.unlocked.toLowerCase(), "", 2, false);

      _globalEventBloc.broadcastMemberRefreshNeeded();
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.hostedFurnaceBloc.members.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.hostedFurnaceBloc.magicLink.listen((magicLink) async {
      if (mounted) {
        setState(() {
          _showSpinner = false;
        });

        globalState.lastCreatedMagicLink = magicLink;
        DialogShareMagicLink.shareToPopup(context, _shareHandler);
      }
    }, onError: (err) {
      debugPrint("error $err");

      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    localFurnace ??= widget.userFurnace;

    //_initListeners();

    if (localFurnace!.connected! && widget.userFurnace.role == Role.OWNER ||
        widget.userFurnace.role == Role.ADMIN ||
        widget.userFurnace.role == Role.IC_ADMIN) {
      widget.hostedFurnaceBloc.getNetworkRequests(widget.userFurnace);
      _editingPrivileges = true;
    }

    widget.hostedFurnaceBloc.getMembers(localFurnace!);
    _showSpinner = true;

    super.initState();
  }

  @override
  void dispose() {
    userFurnaceBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final makeMembers = _showSpinner
        ? Center(child: spinkit)
        : SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Container(
              // color: Colors.black,
              padding:
                  const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
              child: WrapperWidget(
                  child: ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  color: globalState.theme.divider,
                ),
                scrollDirection: Axis.vertical,
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _members.length,
                itemBuilder: (BuildContext context, int index) {
                  User row = _members[index];
                  bool isUser = false;
                  if (row.id == widget.userFurnace.userid!) {
                    isUser = true;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 0.0, top: 0.0, bottom: 0.0, right: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        AvatarWidget(
                          user: row,
                          userFurnace: widget.userFurnace,
                          radius: 60,
                          refresh: _refreshMemberList,
                          isUser: row.id == widget.userFurnace.userid,
                          role: row.role,
                          showDM: true,
                        ),
                        const Padding(
                            padding: EdgeInsets.only(
                                left: 0.0, top: 0.0, bottom: 0.0, right: 8.0)),
                        Expanded(
                            child: InkWell(
                          onTap: () => isUser ? null : _showProfile(row),
                          child: ICText(row.getUsernameAndAlias(globalState),
                              textScaleFactor: globalState.labelScaleFactor,
                              fontSize: 14,
                              color: row.id! == widget.userFurnace.userid!
                                  ? globalState.theme.userObjectText
                                  : Member.returnColor(
                                      row.id!, globalState.members)),
                        )),
                        const Padding(
                            padding: EdgeInsets.only(
                                left: 0.0, top: 0.0, bottom: 0.0, right: 2.0)),
                        row.role == Role.ADMIN
                            ? SizedBox(
                                width: globalState.isDesktop() ? 100 : 75,
                                child: InkWell(
                                  onTap: () =>
                                      isUser ? null : _showProfile(row),
                                  child: TextButton(
                                    onPressed: () => {
                                      isUser ? null : _showProfile(row),
                                    },
                                    child: ICText(
                                        AppLocalizations.of(context)!
                                            .admin
                                            .toLowerCase(),
                                        color: isUser
                                            ? globalState.theme.buttonDisabled
                                            : globalState.theme.buttonIcon,
                                        textScaleFactor: 1.0,
                                        fontSize: 14),
                                  ),
                                ))
                            : (row.role == Role.OWNER ||
                                    row.role == Role.IC_ADMIN)
                                ? SizedBox(
                                    width: globalState.isDesktop() ? 100 : 75,
                                    child: InkWell(
                                      onTap: () =>
                                          isUser ? null : _showProfile(row),
                                      child: TextButton(
                                        onPressed: () => {
                                          isUser ? null : _showProfile(row),
                                        },
                                        child: ICText(
                                            AppLocalizations.of(context)!
                                                .owner
                                                .toLowerCase(),
                                            color: isUser
                                                ? globalState
                                                    .theme.buttonDisabled
                                                : globalState.theme.buttonIcon,
                                            textScaleFactor: 1.0,
                                            fontSize: 14),
                                      ),
                                    ))
                                : SizedBox(
                            width: globalState.isDesktop() ? 100 : 77,
                                    child: InkWell(
                                      onTap: () =>
                                          isUser ? null : _showProfile(row),
                                      child: TextButton(
                                        onPressed: () => {
                                          isUser ? null : _showProfile(row),
                                        },
                                        child: ICText(
                                            AppLocalizations.of(context)!
                                                .member
                                                .toLowerCase(),
                                            color: isUser
                                                ? globalState
                                                    .theme.buttonDisabled
                                                : globalState.theme.buttonIcon,
                                            overflow: TextOverflow.visible,
                                            textScaleFactor: 1.0,
                                            fontSize: 14),
                                      ),
                                    )),
                        const Padding(
                            padding: EdgeInsets.only(
                                left: 0.0, top: 0.0, bottom: 0.0, right: 2.0)),
                        isUser
                            ? (row.role == Role.OWNER ||
                                    row.role == Role.IC_ADMIN)
                                ?  SizedBox(width: globalState.isDesktop() ? 100 : 75)
                                : Container()
                            : _editingPrivileges == true
                                ? SizedBox(
                            width: globalState.isDesktop() ? 100 : 75,
                                    child: InkWell(
                                      onTap: () => _askLockoutUser(row),
                                      child: TextButton(
                                        onPressed: () => {_askLockoutUser(row)},
                                        child: ICText(
                                            row.lockedOut
                                                ? AppLocalizations.of(context)!
                                                    .unlock
                                                : AppLocalizations.of(context)!
                                                    .lockOut,
                                            color: globalState.theme.buttonIcon,
                                            textScaleFactor: 1.0,
                                            fontSize: 14),
                                      ),
                                    ))
                                : Container()
                      ],
                    ),
                  );
                },
              )),
            ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        widget.userFurnace.discoverable &&
                (widget.userFurnace.role == Role.OWNER ||
                    widget.userFurnace.role == Role.IC_ADMIN ||
                    widget.userFurnace.role == Role.ADMIN)
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                    child: _requests.isEmpty
                        ? ICText(
                            AppLocalizations.of(context)!.noPendingJoinRequests)
                        : GradientButtonDynamic(
                            text:
                                '${_requests.length} ${AppLocalizations.of(context)!.networkRequests.toLowerCase()}',
                            color: globalState.theme.urgentAction,
                            onPressed: _showRequests,
                          ))
              ])
            : Container(),
        widget.userFurnace.connected!
            ? Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Divider(
                  color: globalState.theme.screenLink,
                  height: 2,
                  thickness: 2,
                  indent: 0,
                  endIndent: 0,
                ))
            : Container(),
        const Padding(padding: EdgeInsets.only(top: 10)),
        /*Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 5),
            child: Row(children: [
              ICText(
                'Members:',
                color: globalState.theme.labelText,
                fontSize: 16,
              ),
              const Spacer()
            ])),*/
        widget.userFurnace.connected!
            ? Expanded(flex: 1, child: makeMembers)
            : Container(),
      ],
    );
  }

  void _askLockoutUser(User user) {
    if (user.lockedOut) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.unlockAccountTitle,
          '${AppLocalizations.of(context)!.unlockAccountMessageFirst} ${user.username} ${AppLocalizations.of(context)!.unlockAccountMessageSecond}',
          _setLockout,
          null,
          false,
          user);
    } else {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.lockAccountTitle,
          '${AppLocalizations.of(context)!.lockAccountMessageFirst} ${user.username} ${AppLocalizations.of(context)!.lockAccountMessageSecond}',
          _setLockout,
          null,
          false,
          user);
    }
  }

  void _setLockout(User user) async {
    try {
      widget.hostedFurnaceBloc
          .lockout(widget.userFurnace, user, !user.lockedOut);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  _refreshMemberList() {
    setState(() {});
  }

  void _initListeners() {
    userFurnaceBloc.userFurnace.listen((success) {
      localFurnace = success;

      if (!success!.connected!) {
        FormattedSnackBar.showSnackbarWithContext(
            context, "Network disconnected", "", 1, false);
        setState(() {});
      }
    }, onError: (err) {
      setState(() {
        localFurnace = null;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    userFurnaceBloc.removed.listen((success) {
      FormattedSnackBar.showSnackbarWithContext(
          context, "Network removed", "", 2, false);

      Navigator.pop(context);

      /*Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => FurnaceManager(),
          ),
          ModalRoute.withName("/home"));

       */
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);
  }

  _shareHandler(BuildContext context, String magicLink, bool inside) {
    if (inside)
      _globalEventBloc.broadcastPopToHomeAndOpenShare(
          SharedMediaHolder(message: magicLink));
    else
      Share.share(magicLink);
  }

  /*
  _getMagicLink() async {
    try {
      setState(() {
        _showSpinner = true;

        //_hostedFurnaceBloc.getMagicLinkToNetwork(widget.userFurnace);
        // _hostedFurnaceBloc.getFirebaseDynamicLink(widget.userFurnace);
      });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MembersInvitations._getMagicLink: $err');

      setState(() {
        _showSpinner = false;
      });
    }
  }

   */

  void _showRequests() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NetworkRequests(
                  userFurnace: widget.userFurnace,
                  userFurnaces: widget.userFurnaces,
                  hostedFurnaceBloc: widget.hostedFurnaceBloc,
                  networkRequests: _requests,
                  fromActionRequired: false,
                )));
  }

  void _showProfile(User row) async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: widget.userFurnace,
            userMember: row,
            refresh: _refreshMemberList,
            role: widget.userFurnace.role == Role.IC_ADMIN ||
                    widget.userFurnace.role == Role.OWNER ||
                    widget.userFurnace.role == Role.ADMIN
                ? row.role
                : null,
            showDM: true,
          ),
        ));
  }
}

class FurnaceConnection {
  final UserFurnace userFurnace;
  final User user;

  FurnaceConnection({required this.userFurnace, required this.user});
}
