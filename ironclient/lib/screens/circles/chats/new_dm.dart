/*import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:provider/provider.dart';

import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class NewDM extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<UserCircleCache> userCircleCaches;

  NewDM(
      {Key? key, required this.userFurnaces, required this.userCircleCaches})
      : super(key: key);

  @override
  _DirectMessageNewState createState() => _DirectMessageNewState();
}

class _DirectMessageNewState extends State<NewDM> {
  List<Member> _members = [];
  MemberBloc _memberBloc = MemberBloc();
  CircleBloc _circleBloc = CircleBloc();
  InvitationBloc _invitationBloc = InvitationBloc();
  late GlobalEventBloc _globalEventBloc;
  TextEditingController _username = TextEditingController();
  ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool changed = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _invitationBloc.inviteResponse.listen((invitation) {
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
              context, "Notice", 'User not found', null, null, null);
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

      DialogNotice.showNotice(context, "Notice",
          err.toString().replaceFirst("Exception:", ''), null, null, null);
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

      DialogNotice.showNotice(context, "Notice",
          err.toString().replaceFirst("Exception:", ''), null, null, null);
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.loaded.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.getConnectedMembers(
        widget.userFurnaces, widget.userCircleCaches,
        removeDM: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
            constraints: BoxConstraints(),
            child: Container(
              // color: Colors.black,
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20, bottom: 20),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: <
                      Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormattedText(maxLength: 25,
                        // hintText: 'enter a username',
                        labelText: 'enter username',
                        controller: _username,
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: GradientButton(
                          text: "SEND INVITE",
                          onPressed: () {
                            _searchForUser();
                          }),
                    ),
                  ]),
                ),
                _members.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Row(children: <Widget>[
                          Expanded(
                              flex: 20,
                              child: Center(
                                child: Text('OR',
                                    textScaleFactor:
                                        globalState.labelScaleFactor,
                                    style: TextStyle(
                                        color: globalState.theme.textFieldLabel,
                                        fontSize: 20.0)),
                              )),
                        ]),
                      )
                    : Container(),
                _members.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Row(children: <Widget>[
                          Expanded(
                            flex: 20,
                            child: Text('select from existing connections:',
                                textScaleFactor: globalState.labelScaleFactor,
                                style: TextStyle(
                                    color: globalState.theme.textFieldLabel,
                                    fontSize: 20.0)),
                          ),
                        ]),
                      )
                    : Container(),
                Container(
                    // color: Colors.black,
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 20, bottom: 20),
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        color: globalState.theme.divider,
                      ),
                      scrollDirection: Axis.vertical,
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: _members.length,
                      itemBuilder: (BuildContext context, int index) {
                        Member row = _members[index];
                        User user =
                            User(id: row.memberID, username: row.username);

                        UserFurnace userFurnace = widget.userFurnaces
                            .firstWhere(
                                (element) => element.pk == row.furnaceKey);

                        return Container(
                            /*color: Colors.red,*/
                            child: Padding(
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
                                refresh: _doNothing, isUser:false,
                              ),
                              Expanded(
                                  flex: 2,
                                  child: InkWell(
                                      onTap: () {
                                        _showProfile(user, userFurnace);
                                      },
                                      child: Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Container(
                                              height: 50,
                                              child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    row.username.length > 20
                                                        ? user
                                                            .getUsernameAndAlias(
                                                                globalState)
                                                            .substring(0, 19)
                                                        : user
                                                            .getUsernameAndAlias(
                                                                globalState),
                                                    textScaleFactor: globalState
                                                        .labelScaleFactor,
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Member.returnColor(
                                                          row.memberID,
                                                          globalState.members),
                                                    ),
                                                  )))))),
                              // Spacer(),
                              TextButton(
                                onPressed: () {
                                  _confirmCreateDirectMessage(
                                      ConfirmationParams(
                                          userFurnace: userFurnace,
                                          member: row),
                                      row.username,
                                      _createDirectMessageConfirmed);
                                },
                                child: Text('slide',
                                    textScaleFactor:
                                        globalState.labelScaleFactor,
                                    style: TextStyle(
                                        color: globalState.theme.buttonIcon,
                                        fontSize: 14)),
                              ),
                              Padding(padding: EdgeInsets.only(right: 10))
                            ],
                          ),
                        ));
                      },
                    ))
              ]),
            )));

    return WillPopScope(
        onWillPop: () {
          //Navigator.of(context, ).pop(_userCircleCache);

          if (changed)
            Navigator.pop(context, changed);
          else
            Navigator.pop(
              context,
            );

          return Future<bool>.value(false);
        },
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            /*appBar: ICAppBar(
              title: "New Direct Message",
            ),*/
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
    //  bottomNavigationBar: makeBottom,
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
        'Create DM?',
        'Are you sure you want to invite $username to a DM?',
        confirmed,
        null,
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
}

class ConfirmationParams {
  final UserFurnace userFurnace;
  final Member? member;
  final User? user;

  ConfirmationParams({required this.userFurnace, this.user, this.member});
}

 */
