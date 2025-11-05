import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class MemberInvitations extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace userFurnace;

  const MemberInvitations(
      {Key? key, this.userCircleCache, required this.userFurnace})
      : super(key: key);

  @override
  MemberInvitationsState createState() => MemberInvitationsState();
}

class MemberInvitationsState extends State<MemberInvitations> {
  final TextEditingController _username = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  List _invitations = [];
  final ScrollController _scrollController = ScrollController();
  final InvitationBloc _invitationBloc = InvitationBloc();
  bool changed = false;

  final MemberBloc _memberBloc = MemberBloc();
  List<Member> _allMembers = [];
  bool _ready = false;
  List<Member> _filteredMembers = [];

  final CircleBloc _circleBloc = CircleBloc();
  late GlobalEventBloc _globalEventBloc;

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _invitationBloc.invitations.listen((invitations) {
      if (mounted) {
        setState(() {
          /// get invitees list
          _invitations = invitations;

          /// remove invitations from members list
          // if (_allMembers.isNotEmpty && _invitations.isNotEmpty) {
          //   List<String> ids = [];
          //   for (var i = 0; i < invitations.length; i++) {
          //     String item = invitations[i].inviteeID;
          //     ids.add(item);
          //   }
          //_allMembers.removeWhere((element) => ids.contains(element.memberID));
          if (_allMembers.isNotEmpty) {
            for (Invitation invitation in _invitations) {
              _allMembers.removeWhere(
                  (element) => element.memberID == invitation.inviteeID);
            }
          }
          sortLists();

          _showSpinner = false;
          _ready = true;
        });
      }
    }, onError: (err) {
      debugPrint("err $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _circleBloc.membershipList.listen((memberList) {
      if (mounted) {
        setState(() {
          List<String> ids = [];
          for (var i = 0; i < memberList.length; i++) {
            String item = memberList[i]!.id!;
            ids.add(item);
          }

          _allMembers.removeWhere((element) => ids.contains(element.memberID));

          /// find invitees
          _invitationBloc.fetchInvitationsForCircle(
              widget.userCircleCache!.circle!, widget.userFurnace,
              force: true);
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _invitationBloc.inviteResponse.listen((response) {
      /// user invited
      if (mounted) {
        setState(() {
          _username.text = "";
          changed = true;
          //_showSpinner = false;
        });
        String msg;
        //_invitations.add(response);
        if (response!.status == "voting") {
          msg = AppLocalizations.of(context)!.voteToInviteUserCreated;
        } else {
          msg = AppLocalizations.of(context)!.invitationSent;
        }
        FormattedSnackBar.showSnackbarWithContext(context, msg, "", 1, false);

        _memberBloc.getNetworkMembersFromCache([widget.userFurnace],
            exclude: [widget.userCircleCache!]);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("err $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _invitationBloc.invitationResponse.listen((invitation) {
      /// user uninvited
      if (mounted) {
        setState(() {
          changed = true;
          _showSpinner = false;
          //_invitations.remove(invitation);
        });
        _memberBloc.getNetworkMembersFromCache([widget.userFurnace],
            exclude: [widget.userCircleCache!]);
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.invitationCanceled, "", 1, false);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("err $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    super.initState();

    _memberBloc.saved.listen((member) async {
      if (mounted) {
        prepInvite(member);
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.noticeTitle,
          err.toString().replaceFirst("Exception:", ''),
          null,
          null,
          null,
          true);
    }, cancelOnError: false);

    _invitationBloc.findUsers.listen((users) {
      if (mounted) {
        if (users.isEmpty) {
          DialogNotice.showNotice(
              context,
              AppLocalizations.of(context)!.noticeTitle,
              AppLocalizations.of(context)!.noticeUserNotFoundOnNetwork,
              null,
              null,
              null,
              false);
        } else if (users.length == 1) {
          //if (_allMembers.isNotEmpty) {
          int index = _allMembers
              .indexWhere((element) => element.memberID == users[0].id);
          if (index == -1) {
            ///result is returned to listener above
            _memberBloc.create(globalState, widget.userFurnace, users[0]);
          } else {
            prepInvite(Member.getMember(users[0].id!));
          }
          //}
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
          AppLocalizations.of(context)!.noticeTitle,
          err.toString().replaceFirst("Exception:", ''),
          null,
          null,
          null,
          true);
    }, cancelOnError: false);

    _memberBloc.refreshedMemberCircles.listen((membersAndCircles) {
      if (mounted) {
        bool changed = false;

        for (Member member in membersAndCircles.members) {
          if (member.lockedOut == true || member.blocked == true) {
            _allMembers
                .removeWhere((element) => element.memberID == member.memberID);
            changed = true;
          } else {
            int index = _allMembers
                .indexWhere((element) => element.memberID == member.memberID);

            if (index == -1) {
              changed = true;
              _allMembers.add(member);
            } else {
              if (_allMembers[index].username != member.username) {
                changed = true;
                _allMembers[index].username = member.username;
              }
            }
          }
        }

        if (changed) {
          _removeMemberCircles(membersAndCircles.memberCircles);

          _allMembers.sort((a, b) {
            return a.username.toLowerCase().compareTo(b.username.toLowerCase());
          });
          setState(() {});
        } else {
          _removeMemberCircles(membersAndCircles.memberCircles);

          setState(() {});
        }

        _invitationBloc.fetchInvitationsForCircle(
            widget.userCircleCache!.circle!, widget.userFurnace,
            force: true);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    /*
    _memberBloc.refreshedMemberCircles.listen((memberCircles) {
      if (mounted) {
        setState(() {
          List<String> ids = [];
          for (var i = 0; i < memberCircles.length; i++) {
            String item = memberCircles[i].memberID;
            ids.add(item);
          }

          _allMembers.removeWhere((element) => ids.contains(element.memberID));
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);*/

    _memberBloc.loaded.listen((members) {
      members.removeWhere(
          (element) => (element.lockedOut == true || element.blocked == true));

      if (mounted) {
        setState(() {
          _allMembers = members;
        });

        _memberBloc.refreshNetworkMembersFromAPI(
            _globalEventBloc, widget.userFurnace,
            exclude: [widget.userCircleCache!],
            includeMemberCircles: widget.userCircleCache!.circle!);
        /*_invitationBloc.fetchInvitationsForCircle(
            widget.userCircleCache!.circle!, widget.userFurnace,
            force: true);*/
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.getNetworkMembersFromCache([widget.userFurnace],
        exclude: [widget.userCircleCache!]);
  }

  sortLists() {
    if (_allMembers.isNotEmpty) {
      _filteredMembers.clear();
      _filteredMembers.addAll(_allMembers);

      /// sort members
      _filteredMembers.sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else {
      setState(() {
        _filteredMembers = [];
      });
    }

    if (_invitations.isNotEmpty) {
      /// sort invitees
      _invitations.sort(
          (a, b) => a.invitee.toLowerCase().compareTo(b.invitee.toLowerCase()));
    }
  }

  prepInvite(Member member) {
    bool found = false;
    for (Invitation invitation in _invitations) {
      if (invitation.inviteeID == member.memberID) {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            '${member.username} ${AppLocalizations.of(context)!.hasAlreadyBeenInvited}',
            '',
            2,
            false);
        found = true;
      }
    }
    setState(() {
      _showSpinner = false;
    });
    if (found == false) {
      inviteUser(User(id: member.memberID, username: member.username));
      /*FormattedSnackBar.showSnackbarWithContext(
            context, '${member.username} invited', '', 2);

         */
    }
  }

  @override
  void dispose() {
    _username.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: WrapperWidget(child:Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(children: <Widget>[
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
                ])),
            /*
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: FormattedText(
                    maxLength: 25,
                    // hintText: 'enter a username',
                    labelText: AppLocalizations.of(context)
                        .enterUsernameOrAlias, //'enter username or alias',
                    controller: _username,
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(children: <Widget>[
                const Spacer(),
                GradientButtonDynamic(
                    text: AppLocalizations.of(context).search2, //"search",
                    onPressed: () {
                      _searchForUser();
                    })
              ]),
            ),

             */
            ListView.separated(
                separatorBuilder: (context, index) => Divider(
                      color: globalState.theme.divider,
                    ),
                scrollDirection: Axis.vertical,
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _invitations.length,
                itemBuilder: (BuildContext context, int index) {
                  var row = _invitations[index];
                  User user = User(id: row.inviteeID, username: row.invitee);

                  return InkWell(
                      onTap: () {
                        _showProfile(user);
                      },
                      child: Row(children: [
                        AvatarWidget(
                          interactive: false,
                          user: user,
                          userFurnace: widget.userFurnace,
                          radius: 60,
                          refresh: _doNothing,
                          isUser: false,
                          showDM: false,
                        ),
                        const Padding(padding: EdgeInsets.only(right: 8)),
                       Flexible(child: ICText(user.getUsernameAndAlias(globalState),overflow: TextOverflow.fade, softWrap: false,
                            color: Member.returnColor(
                                user.id!, globalState.members))),
                        const Padding(padding: EdgeInsets.only(right: 25)),
                       ICText(
                              row.status == InvitationStatus.BLOCKED
                                  ? InvitationStatus.PENDING
                                  : row.status,
                              softWrap: false,
                              fontSize: 15,
                              color: globalState.theme.labelText),

                        const Padding(padding: EdgeInsets.only(right: 5)),
                        row.inviterID == widget.userFurnace.userid
                            ? GradientButtonDynamic(
                                onPressed: () => _cancel(row),
                                text: AppLocalizations.of(context)
                                    !.cancel, //"cancel",
                                height: 40,
                                color: globalState.theme.buttonDisabled,
                              )
                            : Container(),
                      ]));
                }),
            _filteredMembers.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(children: <Widget>[
                      const ICText('available people on this network:'),
                      const Padding(padding: EdgeInsets.only(right: 5)),
                      (widget.userFurnace.role == Role.OWNER ||
                          widget.userFurnace.role == Role.ADMIN) &&
                          _filteredMembers.isNotEmpty
                       ? Expanded(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              GradientButtonDynamic(
                                  onPressed: () => _inviteAll(),
                                  text: AppLocalizations.of(context)!.inviteSelectAll, //"invite all",
                                  height: 40,
                                  color: globalState.theme.button)
                            ]
                        )
                      )
                          : Container(),
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
                itemCount: _filteredMembers.length,
                itemBuilder: (BuildContext context, int index) {
                  var row = _filteredMembers[index];
                  User user = User(id: row.memberID, username: row.username);

                  return InkWell(
                      onTap: () {
                        _showProfile(user);
                      },
                      child: Row(children: [
                        AvatarWidget(
                          interactive: false,
                          user: user,
                          userFurnace: widget.userFurnace,
                          radius: 60,
                          refresh: _doNothing,
                          isUser: false,
                          showDM: false,
                        ),
                        const Padding(padding: EdgeInsets.only(right: 8)),
                        ICText(user.getUsernameAndAlias(globalState),
                            color: Member.returnColor(
                                user.id!, globalState.members)),
                        Expanded(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                              const Padding(padding: EdgeInsets.only(right: 5)),
                              GradientButtonDynamic(
                                  onPressed: () => inviteUser(user),
                                  text: AppLocalizations.of(context)
                                      !.invite, //"invite",
                                  //height: 35,
                                  height: 40,
                                  color: globalState.theme.button)
                            ]))
                      ]));
                }),
          ]),
      ));

    final makeForm = Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          //appBar: topAppBar,
          body: Stack(
            children: [
              widget.userFurnace.role == Role.MEMBER &&
                  widget.userFurnace.memberAutonomy == false
              ? const Center(
                child: ICText(
                  'You do not have the permissions to invite users',
                  fontSize: 18,
                  //color: globalState.theme.buttonIcon
                )
              )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _ready ? makeBody : Container()),
                    !globalState.isDesktop() ? ICText(AppLocalizations.of(context)
                        !.userNotOnYourNetwork) : Container(), //'User not on your network?'),
                    !globalState.isDesktop() ? TextButton(
                        onPressed: () {
                          _sendMagicLink();
                        },
                        child: ICText(
                          AppLocalizations.of(context)
                              !.sendAMmagicNetworkLink, //'Send a magic network link',
                          fontSize: 18,
                          color: globalState.theme.buttonIcon,
                        )) : Container()
                  ]),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
          //bottomNavigationBar: makeBottom,
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
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    if (changed) {
                      Navigator.pop(context, changed);
                    } else {
                      Navigator.pop(context);
                    }
                  } else if (details.velocity.pixelsPerSecond.dx < 0) {
                    DefaultTabController.of(context).animateTo(1);
                  }
                },
                child: makeForm)
            : makeForm);
  }

  _doNothing() {}

  _searchForUser() {
    FocusScope.of(context).requestFocus(FocusNode());

    if (_username.text.isEmpty) return;

    setState(() {
      _showSpinner = true;
    });

    ///default to hitting the server
    _invitationBloc.findUsersByUsername(_username.text, [widget.userFurnace]);
  }

  void _revalidate() {
    setState(() {
      if (_username.text.isEmpty) {
        _filteredMembers = List.from(_allMembers);
      } else {
        _filteredMembers = List.from(_allMembers);
        _filteredMembers.retainWhere((a) =>
            a.username.toLowerCase().contains(_username.text.toLowerCase()));
      }
    });
  }

  sendInvite() async {
    if (_showSpinner) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      ///check username and alias, but also match the furnace
      String id = Member.returnUserID(
        _username.text,
        widget.userFurnace.pk!,
        globalState.members,
      );

      if (id.isEmpty) {
        _invitationBloc.sendInvitation(
            _username.text,
            widget.userCircleCache!.circle,
            widget.userCircleCache!,
            widget.userFurnace,
            false);
      } else {
        _invitationBloc.sendInvitationByID(id, widget.userCircleCache!.circle,
            widget.userCircleCache!, widget.userFurnace, false);
      }
    }
  }

  _yes(Invitation invitation) {
    _invitationBloc.cancel(widget.userFurnace, invitation);

    setState(() {
      _showSpinner = true;
      _ready = false;
    });
  }

  _no() {}

  void _showProfile(User member) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: widget.userFurnace,
            userMember: member,
            showDM: true,
          ),
        ));

    setState(() {});
  }

  _cancel(Invitation invitation) {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.cancelInvitationTitle,
        AppLocalizations.of(context)!.cancelInvitationMessage,
        _yes,
        _no,
        false,
        invitation);
  }

  inviteUser(User user) async {
    if (_showSpinner) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
        _ready = false;
      });

      String? id = user.id;

      id ??= Member.returnUserID(
        user.getUsernameAndAlias(globalState),
        widget.userFurnace.pk!,
        globalState.members,
      );

      if (id.isEmpty) {
        _invitationBloc.sendInvitation(
            user.getUsernameAndAlias(globalState),
            widget.userCircleCache!.circle,
            widget.userCircleCache!,
            widget.userFurnace,
            false);
      } else {
        _invitationBloc.sendInvitationByID(id, widget.userCircleCache!.circle,
            widget.userCircleCache!, widget.userFurnace, false);
      }
    }
  }

  _inviteAll() async {
    if (_showSpinner) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
        _ready = false;
      });
    }

    for (Member m in _filteredMembers) {
      User user = User(id: m.memberID, username: m.username);
      String? id = user.id;
      id ??= Member.returnUserID(
        user.getUsernameAndAlias(globalState),
        widget.userFurnace.pk!,
        globalState.members,
      );
      if (id.isEmpty) {
        _invitationBloc.sendInvitation(
          user.getUsernameAndAlias(globalState),
          widget.userCircleCache!.circle,
          widget.userCircleCache!,
          widget.userFurnace,
          false);
      } else {
        _invitationBloc.sendInvitationByID(id, widget.userCircleCache!.circle,
          widget.userCircleCache!, widget.userFurnace, false);
      }
    }
  }

  _sendMagicLink() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkInvite(
            userFurnaces: [widget.userFurnace],
            userFurnace: widget.userFurnace,
          ),
        ));
  }

  _removeMemberCircles(List<MemberCircle> memberCircles) {
    List<String> ids = [];
    for (var i = 0; i < memberCircles.length; i++) {
      String item = memberCircles[i].memberID;
      ids.add(item);
    }

    _allMembers.removeWhere((element) => ids.contains(element.memberID));

    debugPrint('break');
  }

  /*_getMagicLink() async {
    try {
      setState(() {
        _showSpinner = true;

        _hostedFurnaceBloc.getMagicLinkToCircle(
            widget.userFurnace!, widget.userCircleCache!.circle!);
      });
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('MembersInvitations._getMagicLink: $err');

      setState(() {
        _showSpinner = false;
      });
    }
  }*/

}
