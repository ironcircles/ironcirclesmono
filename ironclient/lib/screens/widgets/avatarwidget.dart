import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_tabs.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class AvatarWidget extends StatefulWidget {
  final UserFurnace userFurnace;
  final User? user;
  final double radius;
  final bool? showAvatar;
  final Function refresh;
  final bool interactive;
  final bool isUser;
  final File? overrideImage;
  final int? role;
  final bool showDM;

  const AvatarWidget({
    required this.user,
    required this.userFurnace,
    required this.isUser,
    this.radius = 40,
    this.showAvatar = true,
    this.interactive = true,
    required this.refresh,
    this.overrideImage,
    this.role,
    this.showDM = true,
  });

  @override
  AvatarWidgetState createState() => AvatarWidgetState();
}

class AvatarWidgetState extends State<AvatarWidget> {
  //UserBloc _userBloc = UserBloc();
  //late GlobalEventBloc _globalEventBloc;

  int _accountType = AccountType.FREE;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user != null) {
      if (widget.isUser) {
        _accountType = globalState.user.accountType!;
      } else {
        ///Some members are not cached because they are locked out
        Member member = Member.getMember(widget.user!.id!);
        if (member.memberID.isEmpty) {
          _accountType == Role.MEMBER;
        } else {
          _accountType = member.accountType;
        }
      }
    }

    Widget _privacyPlus = Stack(alignment: Alignment.bottomRight, children: [
      Icon(
        Icons.shield,
        size: widget.radius / 3,
        color: Colors.lightBlueAccent,
      ),
      /*Padding(
          padding: EdgeInsets.only(right: 0, bottom: 1),
          child: Icon(Icons.add,
              size: widget.radius / 3, color: Colors.brown.withOpacity(.65))),*/
    ]);

    return Container(
        child: widget.user == null
            ? ClipOval(
                child: Image.asset(
                  'assets/images/avatar.jpg',
                  height: widget.radius,
                  width: widget.radius,
                  fit: BoxFit.fitHeight,
                ))
            : Stack(
                alignment:
                    _isPrivacyPlus() ? Alignment.bottomRight : Alignment.center,
                children: [
                    ClipOval(
                        //radius: radius,
                        child: widget.showAvatar!
                            ? InkWell(
                                onTap: widget.interactive
                                    ? () {
                                        if (widget.userFurnace.userid! ==
                                            widget.user!.id!) {
                                          //if (FileSystemService.returnAnyUserAvatarPath(
                                          //    widget.user!.id) !=
                                          //null)
                                          _openSettings();
                                        } else
                                          _showProfile();
                                      }
                                    : null,
                                child: widget.overrideImage != null
                                    ? Image.file(widget.overrideImage!,
                                        //fit: BoxFit.fill,
                                        height: widget.radius,
                                        width: widget.radius,
                                        fit: BoxFit.cover)
                                    : FileSystemService.returnAnyUserAvatarPath(
                                                widget.user!.id) !=
                                            null
                                        ? Image.file(
                                            File(FileSystemService
                                                .returnAnyUserAvatarPath(
                                                    widget.user!.id,
                                                    avatar:
                                                        widget.user!.avatar)!),
                                            //fit: BoxFit.fill,
                                            height: widget.radius,
                                            width: widget.radius,
                                            fit: BoxFit.cover)
                                        : Image.asset(
                                            'assets/images/avatar.jpg',
                                            height: widget.radius,
                                            width: widget.radius,
                                            fit: BoxFit.fitHeight,
                                          ))
                            : SizedBox(
                                height: widget.radius,
                                width: widget.radius,
                                child: Container(
                                  color: globalState.theme.background,
                                ),
                              )),
                    _isPrivacyPlus() ? _privacyPlus : Container(),
                  ]));
  }

  bool _isPrivacyPlus() {
    return (widget.showAvatar! && (_accountType == AccountType.PREMIUM));
  }

  void _showProfile() async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: widget.userFurnace,
            userMember: widget.user!,
            refresh: widget.refresh,
            role: widget.role,
            showDM: widget.showDM,
          ),
        ));
  }

  _refresh() {
    setState(() {});
  }

  void _openSettings() async {
    if (widget.userFurnace.authServer!) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => Settings(tab: TAB.PROFILE)));
    } else {
      ///Go to Network Manager and open a specific network profile
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NetworkDetailTabs(
                showOnlyProfile: true,
                userFurnace: widget.userFurnace,
                refreshNetworkManager: _refresh,
                userFurnaces: [widget.userFurnace]),
          ));
    }
  }
  /*void _showFullScreenAvatar() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenAvatar(
            userid: widget.user!.id!,
            avatar: widget.user!.avatar,
          ),
        ));
  }

   */
}
