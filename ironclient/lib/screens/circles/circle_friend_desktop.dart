import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/membercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/invitations_invites.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';
import 'package:ironcirclesapp/screens/widgets/dialogyesno.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class CircleFriendDesktopWidget extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace userFurnace;
  final Member member;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;
  final CircleBloc circleBloc;
  final bool onlyFurnace;
  final MemberCircleBloc memberCircleBloc;
  final Function dmCanceled;
  final Function showSpinner;
  final Invitation? invitation;
  final Function refreshInvitations;

  const CircleFriendDesktopWidget(
      Key? key,
      this.index,
      this.userFurnace,
      this.userCircleBloc,
      this.circleBloc,
      this.userCircleCache,
      this.member,
      this.memberCircleBloc,
      this.goInside,
      this.onlyFurnace,
      this.dmCanceled,
      this.showSpinner,
      this.invitation,
      this.refreshInvitations)
      : super(key: key);

  @override
  _CircleFriendWidgetState createState() => _CircleFriendWidgetState();
}

class _CircleFriendWidgetState extends State<CircleFriendDesktopWidget> {
  //final CircleBloc _circleBloc = CircleBloc();
  final InvitationBloc _invitationBloc = InvitationBloc();

  final double _circleRadiusBadgeVisible = 60;
  final double _circleRadius = 60;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(CircleFriendDesktopWidget oldWidget) {
    if (widget.userCircleCache != null) {
      if (oldWidget.userCircleCache!.usercircle !=
          widget.userCircleCache!.usercircle)
        widget.userCircleBloc.notifyWhenBackgroundReady(
            widget.userFurnace, widget.userCircleCache!);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    widget.circleBloc.createdResponse.listen((success) {
      if (mounted) {
        /*FormattedSnackBar.showSnackbarWithContext(
            context, 'DM invitations sent', '', 2);

        Navigator.pop(context);*/
      }
    }, onError: (err) {
      debugPrint("error $err");
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context, err.toString(), '', 2, true);
        setState(() {
          // _showSpinner = false;
        });
      }
    }, cancelOnError: false);

    _invitationBloc.dmCanceled.listen((success) {
      if (widget.userCircleCache != null) {
        widget.dmCanceled(widget.userCircleCache!);
      }
    }, onError: (err) {
      debugPrint("error $err");
      setState(() {
        //_showSpinner = false;
      });
    }, cancelOnError: false);

    _invitationBloc.inviteResponse.listen((invitation) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.dmInvitationSent, '', 2, false);

        ///flip the dmConnected flag
        //Navigator.pop(context);
      }
    }, onError: (err) {
      debugPrint("error $err");
      if (mounted) {
        setState(() {
          //_showSpinner = false;
        });
      }
    }, cancelOnError: false);

    super.initState();
  }

  _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stackedUserCircleImage = widget.userCircleCache == null
        ? Container()
        : Stack(alignment: Alignment.center, children: <Widget>[
            Center(
                child: widget.userCircleCache != null &&
                        widget.userCircleCache!.showBadge!
                    ? AvatarGlow(
                        glowCount: 2,
                        glowRadiusFactor: 0.2,
                        startDelay: const Duration(milliseconds: 1000),
                        //duration: Duration(milliseconds: 2000),
                        // endRadius: (_circleRadiusBadgeVisible +
                        // _glowBorder),
                        glowColor: globalState.theme.circleGlow,
                        repeat: true,
                        animate: true,
                        curve: Curves.slowMiddle,
                        child: Material(
                            elevation: 8.0,
                            shape: const CircleBorder(),
                            child: AvatarWidget(
                              interactive: true,
                              user: User(
                                  id: widget.member.memberID,
                                  username: widget.member.username,
                                  avatar: widget.member.avatar),
                              userFurnace: widget.userFurnace,
                              refresh: _refresh,
                              radius: 60 - (globalState.scaleDownIcons * 2),
                              isUser: false,
                              showDM: true,
                            )))
                    : AvatarWidget(
                        interactive: true,
                        user: User(
                            id: widget.member.memberID,
                            username: widget.member.username,
                            avatar: widget.member.avatar),
                        userFurnace: widget.userFurnace,
                        refresh: _refresh,
                        radius: 60 - (globalState.scaleDownIcons * 2),
                        isUser: false,
                        showDM: true,
                      )),
            // Center(
            //     child: Container(
            //   decoration: const BoxDecoration(
            //     color: Color.fromRGBO(0, 0, 0, 0.5),
            //     borderRadius: BorderRadius.all(Radius.circular(12)),
            //   ),
            //   alignment: Alignment.center,
            //   width: widget.userCircleCache.showBadge!
            //       ? _circleRadius - 13
            //       : _circleRadius -
            //           3, //_hasBackground() ? _circleRadius : _circleRadius - 10,
            //   height: _circleRadius / 2,
            // )),
            // Center(
            //     child: Container(
            //         padding:
            //             const EdgeInsets.only(bottom: 10.0, left: 15, right: 15),
            //         child: Text(
            //           widget.userCircleCache.prefName == null
            //               ? ''
            //               : widget.userCircleCache.prefName!,
            //           overflow: TextOverflow.fade,
            //           softWrap: false,
            //           textAlign: TextAlign.center,
            //           textScaler: TextScaler.linear(globalState.nameScaleFactor),
            //           style: ICTextStyle.getStyle(
            //               context: context,
            //               color: globalState.theme.circleText,
            //               fontSize: 15),
            //         ))),
            // Center(
            //     child: Container(
            //         padding:
            //             const EdgeInsets.only(top: 30.0, left: 15, right: 15),
            //         child: Text(widget.userFurnace.alias!,
            //             textScaler: const TextScaler.linear(1.0),
            //             textAlign: TextAlign.center,
            //             overflow: TextOverflow.fade,
            //             softWrap: false,
            //             style: TextStyle(
            //               color: globalState.theme.furnace,
            //               fontStyle: FontStyle.italic,
            //               fontSize: 10, /*fontWeight: FontWeight.bold*/
            //             )))),
            Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.userCircleCache!.hidden!
                        ? Icon(
                            Icons.lock_rounded,
                            size: 25,
                            color: globalState.theme.menuIconsAlt,
                          )
                        : Container(),
                    widget.userCircleCache!.guarded!
                        ? Icon(
                            Icons.security,
                            size: 25,
                            color: globalState.theme.menuIconsAlt,
                          )
                        : Container(),
                    widget.userCircleCache!.showBadge!
                        ? Icon(
                            Icons.message,
                            size: 25,
                            color: globalState.theme.circleText,
                          )
                        : Container()
                  ],
                )),
          ]);

    return InkWell(
        highlightColor: Colors.lightBlueAccent.withOpacity(.1),
        onTap: widget.userCircleCache == null ||
                (widget.userCircleCache!.dmConnected == false)
            ? null
            : () {
                if (mounted) {
                  setState(() {
                    widget.goInside(widget.userCircleCache,
                        member: widget.member);
                  });
                }
                // widget.goInside(widget.userCircleCache);
              },
        child: Container(
            padding: const EdgeInsets.only(left: 5),
            //height: 58,
            decoration: BoxDecoration(
                color: globalState.theme.memberObjectBackground.withOpacity(.3),
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: 2),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      widget.userCircleCache == null
                          ? AvatarWidget(
                              interactive: true,
                              user: User(
                                  id: widget.member.memberID,
                                  username: widget.member.username,
                                  avatar: widget.member.avatar),
                              userFurnace: widget.userFurnace,
                              refresh: _refresh,
                              radius: 60 - (globalState.scaleDownIcons * 2),
                              isUser: false,
                              showDM: true,
                            )
                          : stackedUserCircleImage,
                      Expanded(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Expanded(
                                flex: 1,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 5,
                                        ),
                                        child: ICText(
                                            widget.member
                                                .returnUsernameAndAlias(),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                            textScaleFactor:
                                                globalState.nameScaleFactor,
                                            fontSize: 17,
                                            color: widget.member.color),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5),
                                          child: Row(children: [
                                            Expanded(
                                              child: ICText(
                                                  widget.userFurnace.alias!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  textScaleFactor: 1.0,
                                                  fontSize: 12,
                                                  color: globalState
                                                      .theme.furnace),
                                            ),
                                          ])),
                                      widget.userCircleCache != null
                                          ? Flexible(
                                              child: ICText(
                                              " ${_returnDateString(widget.userCircleCache!)}",
                                              color: globalState
                                                  .theme.labelTextSubtle,
                                              overflow: TextOverflow.fade,
                                              fontSize: 12,
                                              maxLines: 1,
                                              softWrap: false,
                                            ))
                                          : Container()
                                    ])),
                            widget.invitation != null
                                ? GradientButtonDynamic(
                                    fontSize: globalState.isDesktop() ? 12 : 16,
                                    onPressed: _viewInvitations,
                                    text: AppLocalizations.of(context)!
                                        .acceptDmRequest)
                                : Container(),
                            widget.userCircleCache == null
                                ? widget.invitation == null
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: GradientButtonDynamic(
                                            fontSize: globalState.isDesktop()
                                                ? 12
                                                : 16,
                                            onPressed: _askToCreateDM,
                                            text:
                                                '  ${AppLocalizations.of(context)!.newDm}  '))
                                    : Container()
                                : widget.userCircleCache!.dmConnected == false
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: GradientButtonDynamic(
                                            fontSize: globalState.isDesktop()
                                                ? 12
                                                : 16,
                                            onPressed: _askToCancelDM,
                                            text:
                                                ' ${AppLocalizations.of(context)!.cancelInvitation} '))
                                    : Container()
                          ]))
                    ]))));
  }

  String _returnDateString(UserCircleCache userCircleCache) {
    DateTime now = DateTime.now();

    if (userCircleCache.lastItemUpdate!.year == now.year &&
        userCircleCache.lastItemUpdate!.month == now.month &&
        userCircleCache.lastItemUpdate!.day == now.day) {
      return DateFormat('hh:mm a').format(userCircleCache.lastItemUpdate!);
    } else {
      return DateFormat('MMM dd').format(userCircleCache.lastItemUpdate!);
    }
  }

  void _showProfile() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: widget.userFurnace,
            userMember: User(
                id: widget.member.memberID,
                username: widget.member.username,
                avatar: widget.member.avatar),
            refresh: _refresh,
            showDM: true,
          ),
        ));

    if (mounted) setState(() {});
  }

  _askToCreateDM() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.createDMTitle,
        '${AppLocalizations.of(context)!.createDMMessage} ${widget.member.username}?',
        _createDM,
        null,
        false);
  }

  _askToCancelDM() {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.cancelDMInviteTitle,
        '${AppLocalizations.of(context)!.cancelDMInviteMessage} ${widget.member.username}?',
        _cancelDM,
        null,
        false);
  }

  _createDM() async {
    widget.showSpinner();

    widget.circleBloc.createDirectMessageWithNewUser(
        globalState,
        _invitationBloc,
        widget.userFurnace,
        User(
            id: widget.member.memberID,
            username: widget.member.username,
            avatar: widget.member.avatar));
  }

  _cancelDM() async {
    _invitationBloc.cancelDM(widget.userFurnace, widget.userCircleCache!);
  }

  _viewInvitations() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Invites(
                  userFurnaces: [widget.userFurnace],
                  invitations: [widget.invitation!],
                  refreshCallback: widget.refreshInvitations,
                  userCircleBloc: widget.userCircleBloc,
                  serverRefresh: false,
                )));
  }

  String? _getBackgroundPath() {
    String? retValue;

    if (widget.userCircleCache!.background != null) {
      retValue = FileSystemService.returnUserCircleBackgroundPath(
          widget.userCircleCache!.circlePath!,
          widget.userCircleCache!.background!);
    } else if (widget.userCircleCache!.masterBackground != null) {
      retValue = FileSystemService.returnCircleBackgroundPath(
          widget.userCircleCache!.circlePath!,
          widget.userCircleCache!.masterBackground!);
    }

    return retValue;
  }
}
