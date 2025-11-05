import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class CircleAddConnection extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<UserCircleCache> userCircleCaches;
  //final Function refresh;

  const CircleAddConnection({
    Key? key,
    required this.userFurnaces,
    required this.userCircleCaches,
    /*required this.refresh*/
  }) : super(key: key);

  @override
  _DirectMessageNewState createState() => _DirectMessageNewState();
}

class _DirectMessageNewState extends State<CircleAddConnection> {
  List<Member> _members = [];
  final MemberBloc _memberBloc = MemberBloc();
  final UserBloc _userBloc = UserBloc();
  final CircleBloc _circleBloc = CircleBloc();
  final InvitationBloc _invitationBloc = InvitationBloc();
  late GlobalEventBloc _globalEventBloc;
  final TextEditingController _username = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool changed = false;
  List<Member> _displayMembers = [];

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _userBloc.blockStatusUpdated.listen((bool status) {
      setState(() {});

      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.memberUnblocked, '', 2, false);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userBloc.connectionAdded.listen((member) {
      if (mounted) {
        _globalEventBloc.broadcastRefreshHome();

        Navigator.pop(context);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    /*_invitationBloc.inviteResponse.listen((invitation) {
      if (mounted) {
        _globalEventBloc.broadcastRefreshHome();

        Navigator.pop(context);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _invitationBloc.findUsers.listen((users) {
      if (mounted) {
        if (users.isEmpty) {
          DialogNotice.showNotice(
              context,
              AppLocalizations.of(context).noticeTitle,
              AppLocalizations.of(context).userNotFound,
              null,
              null,
              null,
              false);
        } else if (users.length == 1) {
          _confirmCreateDirectMessage(
              ConfirmationParams(
                  userFurnace: users[0].userFurnace!, user: users[0]),
              users[0].username!,
              _createDirectMessageWithNoUserConfirmed);
        }

        setState(() {
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context).noticeTitle,
          err.toString().replaceFirst("Exception:", ''),
          null,
          null,
          null,
          true);
    }, cancelOnError: false);

    _circleBloc.createdResponse.listen((response) {
      ///empty on purpose
      ///
    }, onError: (err) {
      setState(() {
        _showSpinner = false;
      });

      ///don't display a warning if the DM is hidden
      if (err.toString().contains("SILENT")) return;

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context).noticeTitle,
          err.toString().replaceFirst("Exception:", ''),
          null,
          null,
          null,
          true);
      debugPrint("error $err");
    }, cancelOnError: false);*/

    _memberBloc.refreshed.listen((members) {
      if (mounted) {
        bool changed = false;

        for (Member member in members) {
          if (member.lockedOut == true) {
            _members
                .removeWhere((element) => element.memberID == member.memberID);
            changed = true;
          } else {
            int index = _members
                .indexWhere((element) => element.memberID == member.memberID);

            if (index == -1) {
              if (member.connected == false) {
                changed = true;
                _members.add(member);
              }
            } else {
              if (_members[index].username != member.username) {
                changed = true;
                _members[index].username = member.username;
              }
            }
          }
        }

        if (changed) {
          _members.sort((a, b) {
            return a.username.toLowerCase().compareTo(b.username.toLowerCase());
          });
          setState(() {
            _displayMembers = _members;
          });
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.loaded.listen((members) {
      if (mounted) {
        setState(() {
          members.removeWhere((element) =>
              element.lockedOut == true || element.connected == true);
          _members = members;
          _displayMembers = members;
          _showSpinner = false;
        });

        for (UserFurnace userFurnace in widget.userFurnaces) {
          ///parallel should be fine
          _memberBloc.refreshNetworkMembersFromAPI(
              _globalEventBloc, userFurnace);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    List<UserFurnace> userFurnaces = widget.userFurnaces;

    if (globalState.lastSelectedFilter != null) {
      int index = widget.userFurnaces.indexWhere(
          (element) => element.alias == globalState.lastSelectedFilter);

      if (index != -1) {
        userFurnaces = [];
        userFurnaces.add(widget.userFurnaces[index]);
      }
    }

    _showSpinner = true;

    _memberBloc.getNetworkMembersFromCache(userFurnaces,
        exclude: widget.userCircleCaches, includeDisconnected: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bottomButton = Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: GradientButton(
          //width: screenWidth - 20,
          onPressed: _getMagicLink,
          text: AppLocalizations.of(context)!.sENDMAGICLINKTONETWORK,
        ));

    final makeBody = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Container(
            // color: Colors.black,
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
            child: WrapperWidget(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(
                        flex: 20,
                        child: FormattedText(
                            maxLength: 25,
                            labelText:
                                AppLocalizations.of(context)!.filterByUsername,
                            controller: _username,
                            onChanged: (value) {
                              _revalidate();
                            }))
                  ]),
                  _members.isEmpty && !_showSpinner
                      ? Padding(
                          padding: const EdgeInsets.only(top: 100, bottom: 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  flex: 1,
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .noAdditionalNetworkConnectionsFound,
                                      textScaler: TextScaler.linear(
                                          globalState.labelScaleFactor),
                                      style: TextStyle(
                                          color:
                                              globalState.theme.textFieldLabel,
                                          fontSize: 14.0)),
                                ),
                              ]),
                        )
                      : Container(),
                  ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      color: globalState.theme.divider,
                    ),
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _displayMembers.length,
                    itemBuilder: (BuildContext context, int index) {
                      Member row = _displayMembers[index];
                      User user =
                          User(id: row.memberID, username: row.username);

                      UserFurnace userFurnace = widget.userFurnaces.firstWhere(
                          (element) => element.pk == row.furnaceKey);

                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 0.0, top: 0.0, bottom: 0.0, right: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            AvatarWidget(
                              interactive: false,
                              user: user,
                              userFurnace: userFurnace,
                              radius: 60,
                              refresh: _doNothing,
                              isUser: false,
                            ),
                            Expanded(
                                flex: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: ICText(
                                            row.returnUsernameAndAlias(),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                            textScaleFactor:
                                                globalState.nameScaleFactor,
                                            fontSize: 17,
                                            color: row.color),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5),
                                          child: Row(children: [
                                            Expanded(
                                              child: ICText(userFurnace.alias!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  textScaleFactor: 1.0,
                                                  color: globalState
                                                      .theme.furnace),
                                            ),
                                          ]))
                                    ])),
                            // Spacer(),
                            row.blocked == false
                                ? TextButton(
                                    onPressed: () {
                                      _confirmAddConnection(
                                          ConfirmationParams(
                                              userFurnace: userFurnace,
                                              member: row),
                                          row.username,
                                          _addConnectionConfirmed);

                                      /*_confirmCreateDirectMessage(
                                ConfirmationParams(
                                    userFurnace: userFurnace, member: row),
                                row.username,
                                _createDirectMessageConfirmed);*/
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.addFriend,
                                        textScaler: TextScaler.linear(
                                            globalState.labelScaleFactor),
                                        style: TextStyle(
                                            color: globalState.theme.buttonIcon,
                                            fontSize: 14)),
                                  )
                                : TextButton(
                                    onPressed: () {
                                      _updateBlockStatus(
                                          userFurnace, user, row);
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.unblock,
                                        textScaler: TextScaler.linear(
                                            globalState.labelScaleFactor),
                                        style: TextStyle(
                                            color: globalState.theme.buttonIcon,
                                            fontSize: 14)),
                                  ),
                            const Padding(padding: EdgeInsets.only(right: 10))
                          ],
                        ),
                      );
                    },
                  ),
                  globalState.isDesktop()
                      ? const Padding(padding: EdgeInsets.only(top: 50))
                      : Container(),
                ]))));

    final makeScaffold = Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.addToFriends,
        ),
        body: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: makeBody,
              ),
              globalState.isDesktop() == false ? bottomButton : Container()
            ],
          ),
          _showSpinner ? Center(child: spinkit) : Container(),
        ]));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          if (changed) {
            Navigator.pop(context, changed);
          } else {
            Navigator.pop(context);
          }
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    if (changed) {
                      Navigator.pop(context, changed);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: makeScaffold)
            : makeScaffold);
  }

  void _revalidate() {
    setState(() {
      if (_username.text.isEmpty) {
        _displayMembers = _members;
      } else {
        _displayMembers = List<Member>.from(_members);
        _displayMembers.retainWhere((a) =>
            a.username.toLowerCase().contains(_username.text.toLowerCase()));
      }
    });
  }

  void _showProfile(User member, UserFurnace userFurnace) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: userFurnace,
            userMember: member,
            refresh: _refresh,
          ),
        ));

    setState(() {});
  }

  _createDirectMessageWithNoUserConfirmed(
      ConfirmationParams confirmationParams) {
    try {
      FocusScope.of(context).requestFocus(FocusNode());

      setState(() {
        _showSpinner = true;
      });

      _circleBloc.createDirectMessageWithNewUser(globalState, _invitationBloc,
          confirmationParams.user!.userFurnace!, confirmationParams.user!);
    } catch (err) {
      setState(() {
        _showSpinner = false;
      });
    }
  }

  _confirmAddConnection(ConfirmationParams confirmationParams, String username,
      Function confirmed) {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.addFriend,
        '${AppLocalizations.of(context)!.addThisUserToYourFriendsList} $username',
        confirmed,
        null,
        false,
        confirmationParams);
  }

  _addConnectionConfirmed(ConfirmationParams confirmationParams) {
    _userBloc.setConnected(context, confirmationParams.userFurnace,
        confirmationParams.member!, true);
  }

  _createDirectMessageConfirmed(ConfirmationParams confirmationParams) {
    try {
      FocusScope.of(context).requestFocus(FocusNode());

      setState(() {
        _showSpinner = true;
      });
      _circleBloc.createDirectMessage(_invitationBloc,
          confirmationParams.userFurnace, confirmationParams.member!);
    } catch (err) {
      setState(() {
        _showSpinner = false;
      });
    }
  }

  _confirmCreateDirectMessage(ConfirmationParams confirmationParams,
      String username, Function confirmed) {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.createDMTitle,
        '${AppLocalizations.of(context)!.createDMMessage} $username',
        confirmed,
        null,
        false,
        confirmationParams);
  }

  _searchForUser() {
    // if (_formKey.currentState!.validate()) {
    setState(() {
      _showSpinner = true;
    });

    /*Member member =
        Member.getMemberByUsername(_username.text, globalState.members);

    if (member.memberID.isNotEmpty) {
      UserFurnace memberFurnace = _findFurnaceByKey(member.furnaceKey);

      if (memberFurnace.pk != null) {
        _confirmCreateDirectMessage(
            ConfirmationParams(userFurnace: memberFurnace, member: member),
            member.username,
            _createDirectMessageWithNoUserConfirmed);

        return;
      }
    }

     */

    ///default to hitting the server
    _invitationBloc.findUsersByUsername(_username.text, widget.userFurnaces);
  }

  /*UserFurnace _findFurnaceByKey(int key) {
    return widget.userFurnaces.firstWhere((element) => element.pk == key,
        orElse: () => UserFurnace());
  }

   */

  _doNothing() {}

  _refresh() {
    setState(() {});
  }

  _getMagicLink() async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkInvite(
            userFurnaces: widget.userFurnaces,
            //userFurnace: widget.userFurnace,
          ),
        ));
  }

  _updateBlockStatus(UserFurnace userFurnace, User userMember, Member member) {
    _userBloc.updateBlockStatus(context, userFurnace, userMember, false);
    _memberBloc.setBlocked(userFurnace.userid!, member, false);
  }
}

class ConfirmationParams {
  final UserFurnace userFurnace;
  final Member? member;
  final User? user;

  ConfirmationParams({required this.userFurnace, this.user, this.member});
}
