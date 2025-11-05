import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenavatar.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';

class CircleObjectMember extends StatelessWidget {
  final UserFurnace userFurnace;
  final User creator;
  final Color messageColor;
  final bool interactive;
  final Function refresh;
  final CircleObject circleObject;
  final bool showTime;
  final double maxWidth;
  final bool isWall;

  const CircleObjectMember(
      {required this.creator,
      required this.circleObject,
      required this.userFurnace,
      required this.messageColor,
      required this.interactive,
      required this.showTime,
      required this.refresh,
      required this.maxWidth,
      this.isWall = false});

  @override
  Widget build(BuildContext context) {
    String username = creator.getUsernameAndAlias(globalState);

    final memberUsername = InkWell(
        onTap: interactive
            ? () {
                if (userFurnace.userid! == creator.id!)
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
      circleObject.showOptionIcons
          ? ('${circleObject.date!}  ${circleObject.time!}')
          : circleObject.time!,
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

    return showTime || circleObject.showOptionIcons
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
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: userFurnace,
            userMember: creator,
            refresh: refresh,
            showDM: true,
          ),
        ));
  }

  void _showFullScreenAvatar(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenAvatar(
            userid: creator.id!,
            avatar: creator.avatar,
          ),
        ));
  }
}
