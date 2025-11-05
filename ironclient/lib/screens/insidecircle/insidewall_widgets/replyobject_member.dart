import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenavatar.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';

class ReplyObjectMember extends StatelessWidget {
  final UserFurnace userFurnace;
  final User? creator;
  //final Color messageColor;
  final bool interactive;
  final Function refresh;
  //final CircleObject circleObject;
  final ReplyObject replyObject;
  final bool showTime;
  final double maxWidth;
  final bool isWall;

  const ReplyObjectMember(
      {required this.creator,
        //required this.circleObject,
        required this.replyObject,
        required this.userFurnace,
        //required this.messageColor,
        required this.interactive,
        required this.showTime,
        required this.refresh,
        required this.maxWidth,
        this.isWall = false});

  @override
  Widget build(BuildContext context) {

    String username = "";
    Color messageColor;
    String creatorID = "";
    if (creator != null) {
      username = creator!.getUsernameAndAlias(globalState);
      creatorID = creator!.id!;
    }
    if (creator != null && creator!.id != userFurnace.userid) {
      messageColor = Member.getMemberColor(userFurnace, creator);
    } else {
      messageColor = globalState.theme.userObjectText;
    }

    final memberUsername = InkWell(
        onTap: interactive
            ? () {
          if (userFurnace.userid! == creatorID)
            _showFullScreenAvatar(context);
          else
            _showProfile(context);
        }
            : null,
        child: Text(
          username,
          textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
          overflow: TextOverflow.fade,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            color: messageColor,
            fontWeight: FontWeight.w600,
            fontSize: globalState.userSetting.fontSize,
          ),
        ));

    final messageDateTime = Text(
      replyObject.showOptionIcons
          ? ('${replyObject.date!}  ${replyObject.time!}')
          : replyObject.time!,
      textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
      style: TextStyle(
        color: globalState.theme.time,
        fontWeight: FontWeight.w600,
        fontSize: globalState.dateFontSize,
      ),
    );

    final network = Text(userFurnace.alias!,
      textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
      overflow: TextOverflow.fade,
      softWrap: false,
      maxLines: 1,
      style: TextStyle(
        color: globalState.theme.furnace,
        fontWeight: FontWeight.w600,
        fontSize: globalState.dateFontSize,
      ),
    );

    return showTime || replyObject.showOptionIcons
        ? globalState.mediaScaleFactor > 1.1 || username.length > 15 || isWall
        ? Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(
              width: maxWidth,
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: memberUsername),
                  ])),
          isWall
              ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                messageDateTime,
                const Padding(
                  padding: EdgeInsets.only(left: 5.0),
                ),
                Expanded(child: network),
                const Padding(
                  padding: EdgeInsets.only(left: 5.0),
                ),
              ])
              : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: messageDateTime),
                const Padding(
                  padding: EdgeInsets.only(left: 5.0),
                ),
              ])
        ])
        : ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        //maxWidth: 250,
        //height: 20,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(child: memberUsername),
                    const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                    ),
                    messageDateTime,
                    const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                    ),
                  ])
            ]))
        : Container();
  }

  void _showProfile(BuildContext context) async {
    if (creator != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberProfile(
              userFurnace: userFurnace,
              userMember: creator!,
              refresh: refresh,
              showDM: true,
            ),
          ));
    }
  }

  void _showFullScreenAvatar(BuildContext context) {
    if (creator != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenAvatar(
              userid: creator!.id!,
              avatar: creator!.avatar,
            ),
          ));
    }
  }
}