import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/fullscreen/fullscreenavatar.dart';
import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';

class CircleObjectCreator extends StatelessWidget {
  final UserFurnace userFurnace;
  //final Circle circle;
  final User creator;
  final Color messageColor;
  final bool interactive;
  final Function refresh;

  const CircleObjectCreator({
    required this.creator,
    //required this.circle,
    required this.userFurnace,
    required this.messageColor,
    required this.interactive,
    required this.refresh,
  });

  Widget build(BuildContext context) {
    //Color? test = globalState.getMember(creator.id!).color;
    //debugPrint('test: $test');
    //debugPrint('messageColor: $messageColor');

    return InkWell(
        onTap: interactive
            ? () {
                if (userFurnace.userid! == creator.id!)
                  _showFullScreenAvatar(context);
                else
                  _showProfile(context);
              }
            : null,
        child: Text(
          creator.getUsernameAndAlias(globalState),
          textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
          style: TextStyle(
            color: messageColor,
            fontWeight: FontWeight.w600,
            fontSize: globalState.userSetting.fontSize,
          ),
        ));
  }

  void _showProfile(BuildContext context) async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfile(
            userFurnace: userFurnace,
            userMember: creator,
            refresh: refresh,
            // ownerCircle: circle.type == CircleType.OWNER
            //   && userFurnace.role == Role.OWNER
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
