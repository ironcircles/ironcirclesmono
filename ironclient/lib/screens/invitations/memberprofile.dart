import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/invitations/addfriendtocircles.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:provider/provider.dart';

import '../insidecircle/circleobjectscreens/report_post.dart';

class MemberProfile extends StatefulWidget {
  final User userMember;
  final UserFurnace userFurnace;
  final Function? refresh;
  final int? role;
  final bool showDM;
  //final bool ownerCircle;

  const MemberProfile({
    required this.userMember,
    required this.userFurnace,
    this.showDM = false,
    this.refresh,
    this.role,
    //this.ownerCircle = false,
  });

  @override
  _MemberProfileState createState() => _MemberProfileState();
}

class _MemberProfileState extends State<MemberProfile> {
  final TextEditingController _aliasController = TextEditingController();
  late HostedFurnaceBloc _hostedFurnaceBloc;
  final MemberCircleBloc _memberCircleBloc = MemberCircleBloc();
  final CircleBloc _circleBloc = CircleBloc();
  final InvitationBloc _invitationBloc = InvitationBloc();
  final UserBloc _userBloc = UserBloc();
  late UserCircleBloc _userCircleBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final MemberBloc _memberBloc = MemberBloc();
  String _alias = '';
  List<Member> _members = [];
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();
  TextEditingController _coinController = TextEditingController();

  final double _buttonWidth = 110;
  final double _buttonHeight = 45;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  ListItem _selected = ListItem(object: '', name: '');
  final List<ListItem> _roles = [
    ListItem(object: Role.ADMIN, name: 'admin'),
    ListItem(object: Role.MEMBER, name: 'member'),
    ListItem(object: Role.OWNER, name: 'owner'),
  ];

  // create some values
  Color _pickerColor = const Color(0xff443a49);
  late Color _currentColor;
  late Member _member;
  late GlobalEventBloc _globalEventBloc;
  //bool ownerCircle = false;
  bool reportImage = false;

  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    String? path =
        FileSystemService.returnAnyUserAvatarPath(widget.userMember.id!);

    _userBloc.connectionAdded.listen((member) {
      if (mounted) {
        setState(() {
          _member.connected = member.connected;
          _showSpinner = false;
        });
        _globalEventBloc.broadcastRefreshHome();
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), '', 2, false);

      setState(() {
        _showSpinner = false;
      });

      debugPrint("error $err");
    }, cancelOnError: false);

    _ironCoinBloc.recentCoinPayment.listen((payment) {
      globalState.ironCoinWallet.balance =
          globalState.ironCoinWallet.balance - payment.amount;
      FormattedSnackBar.showSnackbarWithContext(
          context,
          '${AppLocalizations.of(context)!.memberGiftedCoins} ${_member.username}',
          '',
          2,
          false);
    }, onError: (err) {
      debugPrint("recentCoinPayment.listen: $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), '', 2, true);
    }, cancelOnError: false);

    _members = globalState.members;

    _member = _members
        .firstWhere((element) => element.memberID == widget.userMember.id);

    _currentColor = _member.color;
    _pickerColor = _member.color;

    _userBloc.blockStatusUpdated.listen((bool status) {
      _memberBloc.setBlocked(widget.userFurnace.userid!, _member, status);

      _globalEventBloc.broadcastRefreshHome();

      if (status == true) {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            '${_member.username} ${AppLocalizations.of(context)!.memberBlocked}',
            '',
            2,
            false);
      } else {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            '${_member.username} ${AppLocalizations.of(context)!.memberUnblocked}',
            '',
            2,
            false);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _circleBloc.createdResponse.listen((success) {
      if (mounted) {
        /*FormattedSnackBar.showSnackbarWithContext(
            context, 'DM invitations sent', '', 2);

        Navigator.pop(context);*/
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), '', 2, true);
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _invitationBloc.inviteResponse.listen((invitation) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.dmInvitationSent, '', 2, false);

        Navigator.pop(context);
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _hostedFurnaceBloc.roleUpdated.listen((success) {
      if (mounted) {
        widget.userMember.role = _selected.object;

        if (widget.userMember.role == Role.OWNER) {
          ///set the widget variable to reflect the transfer. UserFurnace was updated/saved to cache in the service
          widget.userFurnace.role = Role.ADMIN;
        }

        if (widget.refresh != null) widget.refresh!();

        setState(() {
          _showSpinner = false;
        });

        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.roleSet, "", 2, false);
      }
    }, onError: (err) {
      debugPrint("MemberProfile._memberBloc.saved.listen: $err");

      if (mounted)
        setState(() {
          _showSpinner = false;
        });

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _memberBloc.saved.listen((success) {
      if (mounted) {
        setState(() {
          _currentColor = _pickerColor;
        });

        if (widget.refresh != null) widget.refresh!();
      }
    }, onError: (err) {
      debugPrint("MemberProfile._memberBloc.saved.listen: $err");
    }, cancelOnError: false);

    if (widget.role != null) {
      if (widget.role == Role.MEMBER) {
        _selected = _roles[1];
      } else if (widget.role == Role.ADMIN) {
        _selected = _roles[0];
      } else if (widget.role == Role.OWNER) {
        _selected = _roles[2];
      }
    }
    _aliasController.text = _member.alias;

    reportImage = false;
    if (FileSystemService.returnAnyUserAvatarPath(widget.userMember.id) !=
        null) {
      reportImage = true;
    }

    // if (widget.ownerCircle == true) {
    //   ownerCircle = true;
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: true,
        child: Scaffold(
            appBar: ICAppBar(title: AppLocalizations.of(context)!.memberProfileSettings, pop: _setAlias),
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            body: Stack(children: [
              SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(),
                      child: Container(
                          // color: Colors.black,
                          padding: const EdgeInsets.only(
                              left: 5, right: 5, top: 0, bottom: 5),
                          child: WrapperWidget(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Padding(
                                      padding: EdgeInsets.only(left: 20)),
                                  AvatarWidget(
                                      radius: 225 -
                                          (globalState.scaleDownIcons * 2),
                                      user: widget.userMember,
                                      userFurnace: widget.userFurnace,
                                      isUser: false,
                                      interactive: false,
                                      refresh: _doNothing),
                                ]),
                                const Padding(
                                    padding: EdgeInsets.only(top: 0)),
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Padding(
                                          padding: EdgeInsets.only(left: 10)),
                                      Expanded(
                                          child: Text(
                                        widget.userMember.username!,
                                        textScaler: TextScaler.linear(
                                            globalState.labelScaleFactor),
                                        style: TextStyle(
                                            color: _currentColor, fontSize: 26),
                                      )),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 0, top: 15),
                                          child: SizedBox(
                                              width: _buttonWidth,
                                              height: _buttonHeight,
                                              child: GradientButton(
                                                text: AppLocalizations.of(context)!.setColor,
                                                onPressed: () {
                                                  _pickColor();
                                                },
                                              )))
                                    ]),

                                const Padding(padding: EdgeInsets.only(top: 5)),
                                //_showAlias ?
                                Padding(
                                    padding: const EdgeInsets.only(
                                        right: 10, left: 10),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: FormattedText(
                                                  maxLength: 30,
                                                  labelText: AppLocalizations.of(context)!.enterAlias.toLowerCase(),
                                                  controller: _aliasController,
                                                  validator: (value) {
                                                    if (value
                                                        .toString()
                                                        .endsWith(' ')) {
                                                      return AppLocalizations.of(context)!.errorCannotEndWithASpace;
                                                    } else if (value
                                                        .toString()
                                                        .startsWith(' ')) {
                                                      return AppLocalizations.of(context)!.errorCannotStartWithASpace;
                                                    }
                                                    return null;
                                                  })),
                                        ])),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 0),
                                              child: SwitchListTile(
                                                inactiveThumbColor: globalState
                                                    .theme.inactiveThumbColor,
                                                inactiveTrackColor: globalState
                                                    .theme.inactiveTrackColor,
                                                trackOutlineColor:
                                                    MaterialStateProperty
                                                        .resolveWith(globalState
                                                            .getSwitchColor),
                                                title: Text(
                                                  '${AppLocalizations.of(context)!.includeOnFriendsScreen}?',
                                                  //softWrap: false,
                                                  textScaler: TextScaler.linear(
                                                      globalState
                                                          .labelScaleFactor),
                                                  style: TextStyle(
                                                      fontSize: 16 -
                                                          globalState
                                                              .scaleDownTextFont,
                                                      color: globalState.theme
                                                          .textFieldLabel),
                                                ),
                                                value: _member.connected,
                                                activeColor:
                                                    globalState.theme.button,
                                                onChanged: (bool value) {
                                                  _askToSetConnected(value);
                                                },
                                                //secondary: const Icon(Icons.remove_red_eye),
                                              )))
                                    ]),
                                widget.role != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0,
                                            right: 0,
                                            left: 10,
                                            bottom: 10),
                                        child: Row(children: <Widget>[
                                          Expanded(
                                              child: FormattedDropdownObject(
                                            list: _roles,
                                            selected: _selected,
                                            onChanged: (ListItem? newValue) {
                                              setState(() {
                                                _selected = newValue!;
                                              });
                                            },
                                            hintText:
                                            AppLocalizations.of(context)!.changeMembersRole.toLowerCase(), //'change the member\'s role',
                                          )),
                                          SizedBox(
                                              width: _buttonWidth,
                                              height: _buttonHeight,
                                              child: GradientButton(
                                                  text: AppLocalizations.of(context)!.setRole,
                                                  onPressed: _askChangeRole))
                                        ]))
                                    : Container(),

                                /*const Padding(padding: EdgeInsets.only(top: 20)),
                            widget.showDM
                                ? Row(children: [
                                    Expanded(
                                        child: GradientButton(
                                            text: 'DM', onPressed: _dm)),
                                  ])
                                : Container(),*/
                                widget.showDM
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 5))
                                    : Container(),
                                widget.showDM
                                    ? Row(children: [
                                        Expanded(
                                            child: GradientButton(
                                                text: AppLocalizations.of(context)!.addToCircle.toUpperCase(),
                                                onPressed: _addToCircle)),
                                      ])
                                    : Container(),
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(children: [
                                      Expanded(
                                          child: GradientButton(
                                              text: AppLocalizations.of(context)!.giveIronCoin.toUpperCase(),
                                              onPressed: _giveIronCoinDialog))
                                    ])),
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(children: [
                                      Expanded(
                                          child: GradientButton(
                                              text: AppLocalizations.of(context)!.generateChatHistory.toUpperCase(),
                                              onPressed: _generateChatHistoryDialog))
                                    ])),
                                widget.showDM
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 10))
                                    : Container(),
                                Row(children: [
                                  Expanded(
                                      child: GradientButton(
                                          text: _member.blocked == false
                                              ? AppLocalizations.of(context)!.blockUser.toUpperCase()
                                              : AppLocalizations.of(context)!.unblock.toUpperCase(),
                                          onPressed: _updateBlockStatus)),
                                ]),

                                (FileSystemService.returnAnyUserAvatarPath(
                                                widget.userMember.id) !=
                                            null) ||
                                        widget.userMember.avatar != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(children: [
                                          Expanded(
                                              child: GradientButton(
                                                  text: AppLocalizations.of(context)!.reportUserAvatar.toUpperCase(),
                                                  onPressed: _reportProfile))
                                        ]))
                                    : Container(),
                              ]))))),
              _showSpinner ? Center(child: spinkit) : Container()
            ])));
  }

  _doNothing() {}

  void _askChangeRole() {
    if (_selected.object == (widget.userMember.role)) return; //no change

    if (_selected.object == Role.OWNER ||
        widget.userMember.role == Role.OWNER) {
      if (widget.userFurnace.role == Role.OWNER)
        DialogYesNo.askYesNo(
            context,
            AppLocalizations.of(context)!.transferOwnershipTitle,
            '${AppLocalizations.of(context)!.transferOwnershipMessage1} ${widget.userMember.username}?\n\n${AppLocalizations.of(context)!.transferOwnershipMessage2}',
            _setRole,
            null,
            false,
            null);
      else
        DialogNotice.showNoticeOptionalLines(
            context,
            AppLocalizations.of(context)!.roleNotSet,
            AppLocalizations.of(context)!
                .errorOnlyOwnerOfNetworkCanTransferOwnership,
            false);
    } else {
      late String currentRole;
      late String newRole;

      if (widget.userMember.role == Role.ADMIN)
        currentRole = 'admin';
      else
        currentRole = "member";

      if (_selected.object == Role.ADMIN)
        newRole = 'admin';
      else
        newRole = "member";

      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.changeRoleTitle,
          '${AppLocalizations.of(context)!.changeRoleMessage}\n\n${widget.userMember.username}: $currentRole -> $newRole',
          _setRole,
          null,
          false,
          null);
    }
  }

  _setRole() {
    _hostedFurnaceBloc.setRole(
        widget.userFurnace, widget.userMember, _selected.object);

    setState(() {
      _showSpinner = true;
    });
  }

  _reportProfile() async {
    Violation? violation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPost(
            type: ReportType.PROFILE,
            userCircleCache: null,
            circleObject: null,
            circleObjectBloc: null,
            member: widget.userMember,
            userFurnace: widget.userFurnace,
            network: null,
          ),
        ));

    if (violation != null) {
      _hostedFurnaceBloc.reportAvatar(widget.userFurnace, violation);

      FormattedSnackBar.showSnackbarWithContext(
          context, "potential violation reported", "", 3, false);
    }
  }

  // _makeOwner() {
  //   ///make member owner, relinquish own ownership
  //   _hostedFurnaceBloc.giveOwnership(
  //     widget.userFurnace, widget.userMember
  //   );
  // }

  // _transferOwnership() {
  //   DialogYesNo.askYesNo(context,
  //       'Transfer Ownership?',
  //       'Do you want to transfer ownership of this circle to this user? This act is final unless they transfer it back.',
  //       _makeOwner,
  //       null,
  //       false);
  //   // _hostedFurnaceBloc.setRole(
  //   //     widget.userFurnace, widget.userMember, int.parse(_selected.id));
  //   //
  //   // setState(() {
  //   //   _showSpinner = true;
  //   // });
  // }

  _setAlias() {
    if (_aliasController.text != _alias || _aliasController.text == '') {
      _member.alias = _aliasController.text;
      _alias = _aliasController.text;
      _memberBloc.setAlias(
          widget.userFurnace.userid!, _member, _aliasController.text.trim());
    }
    Navigator.pop(context);
  }

  _setColor() {
    _memberBloc.setColor(
        widget.userFurnace.userid!, _member, _pickerColor, _members);
  }

  void changeColor(Color color) {
    setState(() => _pickerColor = color);
  }

  _pickColor() {
// raise the [showDialog] widget
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        title: ICText(
          AppLocalizations.of(context)!.selectAColor,
          fontSize: 20,
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ColorPicker(
            pickerColor: _pickerColor,
            onColorChanged: changeColor,
          ),
        ),
        actions: <Widget>[
          GradientButtonDynamic(
              onPressed: () {
                _setColor();
                Navigator.of(context).pop();
              },
              text: AppLocalizations.of(context)!.setColor,
              fontSize: 16),
        ],
      ),
    );
  }

  _updateBlockStatus() {
    _userBloc.updateBlockStatus(context,
        widget.userFurnace, widget.userMember, !_member.blocked);
  }

  _giveIronCoinDialog() {
    _coinController.text = '';
    String yourCoins = formatter.format(globalState.ironCoinWallet.balance);
    DialogYesNo.coinsAskYesNo(context, "${AppLocalizations.of(context)!.giveUserIronCoin}?",
        AppLocalizations.of(context)!.enterAmount, _coinController, _giveIronCoin, null, false, yourCoins);
  }


  _generateChatHistoryDialog() {
    DialogYesNo.askYesNo(context, "${AppLocalizations.of(context)!.generateChatHistoryDialog}?",
        AppLocalizations.of(context)!.enterAmount,  _giveIronCoin, null, false, );
  }

  _generateChatHistory(){


  }

  _giveIronCoin() {
    int? value = 0;
    if (_coinController.text.isNotEmpty) {
      value = int.tryParse(_coinController.text);
    }
    if (value != null && value > 0) {
      if (globalState.ironCoinWallet.balance >= value) {
        _ironCoinBloc.giveCoins(widget.userMember, value);
      } else {
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.notEnoughIronCoin, //"You do not have the IronCoin needed for this transaction",
            "",
            3,
            false);
      }
    } else {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.pleaseEnterWholeNumber, "", 3, false);
    }
    _coinController.text = '';
  }

  _addToCircle() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFriendToCircles(
            userFurnace: widget.userFurnace,
            member: widget.userMember,
          ),
        ));
  }

  _askToSetConnected(bool connected) async {
    if (connected == false) {
      MemberCircle? memberCircle = await _memberCircleBloc.getDM(
          widget.userFurnace.userid!, _member.memberID);

      if (memberCircle != null) {
        DialogNotice.showNoticeOptionalLines(
            context,
            'Cannot Remove Person',
            'You can\'t remove someone who is in a DM with you. You must leave the DM first (or cancel a pending invitation).',
            false);
        return;
      }
    }

    if (connected)
      DialogYesNo.askYesNo(
          context,
          '${AppLocalizations.of(context)!.addToFriendsTitle}?',
          AppLocalizations.of(context)!.addToFriendsMessage,
          _setConnected,
          null,
          false,
          connected);
    else
      DialogYesNo.askYesNo(
          context,
          '${AppLocalizations.of(context)!.removeFromFriendsTitle}?',
          AppLocalizations.of(context)!.removeFromFriendsMessage,
          _setConnected,
          null,
          false,
          connected);
  }

  _setConnected(bool connected) {
    setState(() {
      _showSpinner = true;
    });

    _userBloc.setConnected(context, widget.userFurnace, _member, connected);
  }

  // _dm() async {
  //   ///find the right usercircle
  //   MemberCircle? memberCircle = await _memberCircleBloc.getDM(
  //       widget.userFurnace.userid!, widget.userMember.id!);
  //
  //   if (memberCircle != null) {
  //     UserCircleCache userCircleCache = await _userCircleBloc
  //         .getUserCircleCacheFromCircle(memberCircle.circleID);
  //
  //     if (userCircleCache.hidden! == true &&
  //         userCircleCache.hiddenOpen != true) {
  //       if (mounted) {
  //         FormattedSnackBar.showSnackbarWithContext(
  //             context, AppLocalizations.of(context)!.dmNotFound, '', 2, false);
  //       }
  //       return;
  //     }
  //
  //     globalState.enterDM = userCircleCache;
  //
  //     if (mounted) {
  //       Navigator.pushReplacementNamed(
  //         context,
  //         '/home',
  //         // arguments: user,
  //       );
  //     }
  //   } else {
  //     setState(() {
  //       _showSpinner = true;
  //     });
  //
  //     ///see if the user was already invited
  //
  //     _circleBloc.createDirectMessageWithNewUser(
  //         globalState, _invitationBloc, widget.userFurnace, widget.userMember);
  //   }
  // }
}
