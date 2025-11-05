import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_name.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class CircleNewWizardInvitations extends StatefulWidget {
  final UserFurnace userFurnace;
  final WizardVariables wizardVariables;

  const CircleNewWizardInvitations(
      {required this.userFurnace, required this.wizardVariables});

  @override
  _CircleNewWizardInvitationsState createState() =>
      _CircleNewWizardInvitationsState();
}

class _CircleNewWizardInvitationsState
    extends State<CircleNewWizardInvitations> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late GlobalEventBloc _globalEventBloc;
  final ScrollController _scrollController = ScrollController();
  List<Member> _displayMembers = [];

  final InvitationBloc _invitationBloc = InvitationBloc();
  final MemberBloc _memberBloc = MemberBloc();
  final CircleBloc _circleBloc = CircleBloc();
  final TextEditingController _username = TextEditingController();
  bool _clicked = false;
  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  bool selectAll = false;

  @override
  void initState() {
    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _revalidate();

    _circleBloc.createdWithInvites.listen((success) {
      if (mounted) {
        if (success) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.successfullyCreatedCircle,
              "",
              2,
              false);

          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.errorCreatingCircle, "", 2, false);

          setState(() {
            _showSpinner = false;
            _clicked = false;
          });
        }
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      setState(() {
        _showSpinner = false;
        _clicked = false;
      });

      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.saved.listen((member) async {
      if (mounted) {
        if (widget.wizardVariables.members
                .indexWhere((element) => element.memberID == member.memberID) !=
            -1) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              '${member.username} ${AppLocalizations.of(context)!.isAlreadyOnTheList}',
              '',
              2,
              false);

          setState(() {
            _showSpinner = false;
          });
        } else {
          member.selected = true;
          widget.wizardVariables.members.add(member);
          widget.wizardVariables.members.sort((a, b) =>
              a.username.toLowerCase().compareTo(b.username.toLowerCase()));

          setState(() {
            _showSpinner = false;
            _displayMembers = widget.wizardVariables.members;
          });

          FormattedSnackBar.showSnackbarWithContext(
              context,
              '${member.username} ${AppLocalizations.of(context)!.addedToList}',
              '',
              2,
              false);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.notice,
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
              AppLocalizations.of(context)!.notice,
              AppLocalizations.of(context)!.noticeUserNotFoundOnNetwork,
              null,
              null,
              null,
              false);

          setState(() {
            _showSpinner = false;
          });
        } else if (users.length == 1) {
          _memberBloc.create(globalState, widget.userFurnace, users[0]);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });

      DialogNotice.showNotice(
          context,
          AppLocalizations.of(context)!.notice,
          err.toString().replaceFirst("Exception:", ''),
          null,
          null,
          null,
          true);
    }, cancelOnError: false);

    _memberBloc.refreshed.listen((members) {
      if (mounted) {
        bool changed = false;

        for (Member member in members) {
          if (member.lockedOut == true || member.blocked == true) {
            widget.wizardVariables.members
                .removeWhere((element) => element.memberID == member.memberID);
            changed = true;
          } else {
            int index = widget.wizardVariables.members
                .indexWhere((element) => element.memberID == member.memberID);

            if (index == -1) {
              changed = true;
              widget.wizardVariables.members.add(member);
            } else {
              if (widget.wizardVariables.members[index].username !=
                  member.username) {
                changed = true;
                widget.wizardVariables.members[index].username =
                    member.username;
              }
            }
          }
        }

        if (changed) {
          widget.wizardVariables.members.sort((a, b) {
            return a.username.toLowerCase().compareTo(b.username.toLowerCase());
          });
          setState(() {
            _displayMembers = widget.wizardVariables.members;
          });
        }
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _memberBloc.loaded.listen((members) {
      if (mounted) {
        setState(() {
          widget.wizardVariables.members.clear();
          widget.wizardVariables.members.addAll(members);
          _displayMembers = widget.wizardVariables.members;
        });

        _memberBloc.refreshNetworkMembersFromAPI(
            _globalEventBloc, widget.userFurnace);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.wizardVariables.members.isEmpty) {
      ///first time
      _memberBloc.getNetworkMembersFromCache([widget.userFurnace]);
    } else {
      ///see if there are any api changes
      _memberBloc.refreshNetworkMembersFromAPI(
          _globalEventBloc, widget.userFurnace);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBottom = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 2),
        child: globalState.isDesktop()
            ? Row(children: <Widget>[
                Spacer(),
                SizedBox(
                    height: 55,
                    width: 300,
                    child: GradientButton(
                        text: AppLocalizations.of(context)!.createCircle,
                        onPressed: () {
                          _createCircle();
                        })),
              ])
            : Row(children: <Widget>[
                Expanded(
                  child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: ButtonType.getWidth(
                              MediaQuery.of(context).size.width)),
                      child: GradientButton(
                          text: AppLocalizations.of(context)!.createCircle,
                          onPressed: () {
                            _createCircle();
                          })),
                ),
              ]),
      ),
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: WrapperWidget(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                Container(
                  // color: Colors.black,
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 0, bottom: 20),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        //const ICText('Select from below'),
                        ICText(AppLocalizations.of(context)!
                            .filterOrSelectFromBelow),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Row(children: <Widget>[
                            Expanded(
                              flex: 20,
                              child: FormattedText(
                                  maxLength: 25,
                                  // hintText: 'enter a username',
                                  labelText: AppLocalizations.of(context)!
                                      .enterUsername,
                                  controller: _username,
                                  onChanged: (value) {
                                    _revalidate();
                                  }),
                            ),
                          ]),
                        ),
                        _displayMembers.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      GradientButtonDynamic(
                                          onPressed: () => _selectAll(),
                                          text: AppLocalizations.of(context)!
                                              .inviteSelectAll, //"invite all",
                                          height: 40,
                                          color: globalState.theme.button)
                                    ]))
                            : Container(),
                        ListView.builder(
                            scrollDirection: Axis.vertical,
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount: _displayMembers.length,
                            itemBuilder: (BuildContext context, int index) {
                              var row = _displayMembers[index];

                              if (row.lockedOut || row.blocked)
                                return Container();

                              User user = User(
                                  id: row.memberID, username: row.username);

                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          row.selected = !row.selected;
                                        });
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
                                        Expanded(
                                            child: CheckboxListTile(
                                                side: BorderSide(
                                                    color: globalState
                                                        .theme.buttonDisabled,
                                                    width: 2.0),
                                                activeColor: globalState
                                                    .theme.buttonIcon,
                                                checkColor: globalState
                                                    .theme.checkBoxCheck,
                                                title: ICText(
                                                  user.getUsernameAndAlias(
                                                      globalState),
                                                  color: Member.returnColor(
                                                      row.memberID,
                                                      globalState.members),
                                                ),
                                                value: row.selected,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    row.selected = newValue!;
                                                  });
                                                })),
                                      ])));
                            })
                      ]),
                ),
                makeBottom,
              ])),
        ),
      ),
    );

    return Form(
      key: _formKey,
      child: SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
              title: AppLocalizations.of(context)!.inviteFriends,
              pop: _backPressed,
            ),
            //drawer: NavigationDrawer(),
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: makeBody,
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            )),
      ),
    );
  }

  _selectAll() {
    setState(() {
      selectAll = !selectAll;
      for (Member m in _displayMembers) {
        m.selected = selectAll;
      }
    });
  }

  void _revalidate() {
    setState(() {
      if (_username.text.isEmpty) {
        _displayMembers = widget.wizardVariables.members;
      } else {
        _displayMembers = List<Member>.from(widget.wizardVariables.members);
        _displayMembers.retainWhere((a) =>
            a.username.toLowerCase().contains(_username.text.toLowerCase()));
      }
    });
  }

  _backPressed() {
    Navigator.pop(context, widget.wizardVariables);
  }

  _createCircle() {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _showSpinner = true;
        });
        if (_clicked == false) {
          _clicked = true;

          _circleBloc.createAndSentInvitations(
              widget.userFurnace,
              widget.wizardVariables.circle,
              widget.wizardVariables.image,
              widget.wizardVariables.members,
              widget.wizardVariables.pickerColor);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('NewCircle._createCircle: $err');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      _clicked = false;
    }
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
}
