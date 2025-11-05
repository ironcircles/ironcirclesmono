import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_tabs.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class MemberList extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final Circle circle;

  const MemberList(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.userFurnaces,
      required this.circle})
      : super(key: key);

  @override
  MemberListState createState() => MemberListState();
}

class MemberListState extends State<MemberList> {
  List _members = [];
  final CircleBloc _circleBloc = CircleBloc();

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late UserCircleBloc _userCircleBloc; // = UserCircleBloc();
  late GlobalEventBloc _globalEventBloc;
  bool changed = false;

  @override
  void initState() {
    //_members = getMembers();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    super.initState();

    //Listen for membership load
    _circleBloc.membershipList.listen((memberList) {
      if (mounted) {
        setState(() {
          _members = memberList;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _circleBloc.membersNeedsRefresh.listen((bool Bool) {
      _circleBloc.getMembershipList(widget.userCircleCache, widget.userFurnace);
    });

    //Listen for the first CircleObject load
    _circleBloc.removeMemberResponse.listen((response) {
      if (mounted) {
        setState(() {
          changed = true;
          // _members = memberList;
          FormattedSnackBar.showSnackbarWithContext(
              context, response!, "", 2, false);
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.leaveCircleResponse.listen((response) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.leftCircle, "", 1, false);
        if (response!) _goHome();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    _circleBloc.getMembershipList(widget.userCircleCache, widget.userFurnace);
  }

  _goHome() async {
    _globalEventBloc.broadcastPopToHomeOpenTab(0);
    // await Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(builder: (context) => Home()),
    //     (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        //appBar: topAppBar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: WrapperWidget(child: Container(
                    // color: Colors.black,
                    padding: const EdgeInsets.only(
                        left: 0, right: 0, top: 10, bottom: 20),
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

                        if (row.lockedOut) {
                          return Container();
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            AvatarWidget(
                                user: row,
                                userFurnace: widget.userFurnace,
                                radius: 60,
                                refresh: _refresh,
                                showDM: true,
                                isUser: row.id == widget.userFurnace.userid),
                            const Padding(
                                padding: EdgeInsets.only(
                                    left: 0.0,
                                    top: 0.0,
                                    bottom: 0.0,
                                    right: 8.0)),
                            Expanded(
                                flex: 3,
                                child: InkWell(
                                    onTap: () {
                                      _showProfile(row);
                                    },
                                    child: Text(
                                      row.username!.length > 20
                                          ? row
                                              .getUsernameAndAlias(globalState)
                                              .substring(0, 19)
                                          : row
                                              .getUsernameAndAlias(globalState),
                                      textScaler: TextScaler.linear(
                                          globalState.labelScaleFactor),
                                      style: TextStyle(
                                          fontSize: 17,
                                          color: row.id! ==
                                                  widget.userFurnace.userid!
                                              ? globalState.theme.userObjectText
                                              : Member.returnColor(row.id!,
                                                  globalState.members)),
                                    ))),
                            const Padding(
                                padding: EdgeInsets.only(
                                    left: 0.0,
                                    top: 0.0,
                                    bottom: 0.0,
                                    right: 4.0)),
                            const Spacer(),
                            row.id == widget.userCircleCache.user
                                ? InkWell(
                                    onTap: () => _leave(context),
                                    child: TextButton(
                                      onPressed: () => {_leave(context)},
                                      child: ICText(
                                          AppLocalizations.of(context)!
                                              .leave
                                              .toLowerCase(),
                                          textScaleFactor:
                                              globalState.labelScaleFactor,
                                          color: globalState.theme.buttonIcon,
                                          fontSize: 14),
                                    ),
                                  )
                                : widget.circle.type == CircleType.OWNER
                                    ? widget.circle.owner ==
                                            widget.userFurnace.userid
                                        ? InkWell(
                                            onTap: () => _voteOut(
                                                context, row.username, row.id),
                                            child: TextButton(
                                              onPressed: () => {
                                                _removeMember(context,
                                                    row.username, row.id)
                                              },
                                              child: ICText(
                                                  AppLocalizations.of(context)!
                                                      .remove
                                                      .toLowerCase(),
                                                  color: globalState
                                                      .theme.buttonIcon,
                                                  textScaleFactor: 1.0,
                                                  fontSize: 14),
                                            ),
                                          )
                                        : Container()
                                    : InkWell(
                                        onTap: () => _voteOut(
                                            context, row.username, row.id),
                                        child: TextButton(
                                          onPressed: () => {
                                            _voteOut(
                                                context, row.username, row.id)
                                          },
                                          child: ICText(
                                              AppLocalizations.of(context)!
                                                  .voteOut
                                                  .toLowerCase(),
                                              textScaleFactor: 1.0,
                                              color:
                                                  globalState.theme.buttonIcon,
                                              fontSize: 14),
                                        ),
                                      ),
                          ],
                        );
                      },
                    )),
              ),
            )),
          ],
        ));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          if (changed)
            Navigator.pop(context, changed);
          else
            Navigator.pop(
              context,
            );
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 2000) {
                    if (changed) {
                      Navigator.pop(context, changed);
                    } else {
                      Navigator.pop(context);
                    }
                  } else if (details.velocity.pixelsPerSecond.dx > 200) {
                    DefaultTabController.of(context).animateTo(0);
                  }
                },
                child: makeBody)
            : makeBody);
    //  bottomNavigationBar: makeBottom,
  }

  _result(String memberID) {
    _circleBloc.removeMember(
        widget.userFurnace, widget.userCircleCache, memberID);
  }

  Future<void> _leave(BuildContext context) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.leaveCircleTitle,
        AppLocalizations.of(context)!.leaveCircleMessage,
        _leaveResult,
        null,
        false);
  }

  _leaveResult() {
    _userCircleBloc.leaveCircle(widget.userFurnace, widget.userCircleCache);
  }

  Future<void> _removeMember(
      BuildContext context, String? memberName, String? memberID) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.removeMemberTitle,
        "${AppLocalizations.of(context)!.removeMemberMessage} ($memberName)",
        _result,
        null,
        false,
        memberID);
  }

  Future<void> _voteOut(
      BuildContext context, String? memberName, String? memberID) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.voteOutMemberTitle,
        "${AppLocalizations.of(context)!.voteOutMemberMessage} ($memberName)",
        _result,
        null,
        false,
        memberID);
  }

  void _showProfile(User member) async {
    if (member.username == widget.userFurnace.username) {
      if (widget.userFurnace.authServer!) {
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Settings(),
            ));
      } else {
        ///Go to Network Manager and open a specific network profile
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NetworkDetailTabs(
                  showOnlyProfile: true,
                  refreshNetworkManager: _refresh,
                  userFurnace: widget.userFurnace,
                  userFurnaces: widget.userFurnaces),
            ));
      }
    } else {
      //if (widget.circle.type == CircleType.OWNER && widget.userFurnace.role == Role.OWNER) {
      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberProfile(
              userFurnace: widget.userFurnace,
              userMember: member,
              refresh: _refresh,
              showDM: true,
              // ownerCircle: widget.circle.type == CircleType.OWNER
              //       && widget.userFurnace.role == Role.OWNER
              //   ? true
              //     : false
              //role removed as would only change network role not circle role
            ),
          ));
      //} else {
      //   await Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => MemberProfile(
      //           userFurnace: widget.userFurnace,
      //           userMember: member,
      //           refresh: _refresh,
      //           showDM: true,
      //         ),
      //       ));
      //}
    }

    setState(() {});
  }

  /*void _showFullScreenAvatar(User member) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenAvatar(
            userid: member.id!,
            avatar: member.avatar,
          ),
        ));
  }

   */

  _refresh() {
    setState(() {
      _members = [];
    });
    _circleBloc.getMembershipList(widget.userCircleCache, widget.userFurnace);
  }
}
