/*import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ChatGridViewDM extends StatefulWidget {
  final List<MemberCircle> memberCircles;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Member member;
  final MemberCircle memberCircle;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;
  final bool onlyFurnace;

  ChatGridViewDM(
    this.index,
    this.userFurnace,
    this.userCircleBloc,
    this.userCircleCache,
    this.member,
    this.memberCircle,
    this.memberCircles,
    this.goInside,
    this.onlyFurnace,
  );

  @override
  UserCircleWidgetState createState() => UserCircleWidgetState();
}

class UserCircleWidgetState extends State<ChatGridViewDM>
    with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  Animation<double>? animation;
  double _circleRadius = 180;
  double _circleRadiusBadgeVisible = 170;
  double _glowBorder = 300;

  // int tempCounter = 0;
  // UserCircleCache userCircleCache;

  // late UserCircleBloc _userCircleBloc;
  //late GlobalEventBloc _globalEventBloc;

  @override
  void dispose() {
    // animationController.dispose();
    //_userCircleBloc.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(ChatGridViewDM oldWidget) {
    if (oldWidget.userCircleCache.usercircle !=
        widget.userCircleCache.usercircle)
      widget.userCircleBloc.notifyWhenBackgroundReady(
          widget.userFurnace, widget.userCircleCache);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    //_globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    //_userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    //local mutable instance
    //userCircleCache = widget.userCircleCache;

    //Listen for the first CircleObject load
    widget.userCircleBloc.imageLoaded.listen((userCircleCache) {
      if (mounted) {
        //debugPrint('image loaded: ${userCircleCache.usercircle} : ${userCircleCache.prefName}');

        if (userCircleCache.usercircle == widget.userCircleCache.usercircle) {
          //debugPrint('SHOULD HIT THIS FREAKING BREAKPOINT');
          // debugPrint('image matches: ${userCircleCache.prefName} : ${widget.userCircleCache.prefName}');
          setState(() {
            //_imageReady = true;
          });
        }
      }
    }, onError: (err) {
      debugPrint("UserCircleWidget.initState: $err");
    }, cancelOnError: false);

    // debugPrint ('${widget.userCircleCache.prefName} init State');
    //debugPrint(widget.userCircleCache.prefName);
    widget.userCircleBloc
        .notifyWhenBackgroundReady(widget.userFurnace, widget.userCircleCache);

    //_imagePath = _getBackgroundPath();

    super.initState();

    //double width = MediaQuery.of(context).size.width;
    //double height = MediaQuery.of(context).size.height;

    if (Platform.isIOS) _glowBorder = 270;
  }

  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    //debugPrint('usercircle build');

    if (width > height) {
      _glowBorder = 0;
    } else {
      if (Platform.isIOS)
        _glowBorder = 270;
      else
        _glowBorder = 300;
    }

    // if (width > 750) {
    //_circleRadiusBadgeVisible = 160;
    // _glowBorder = 0;
    //_circleRadius = 150;
    // }
    //debugPrint(width);
    // debugPrint(height);

    //800.0
    //I/flutter ( 4956): 1232.0

    return InkWell(
        highlightColor: Colors.lightBlueAccent.withOpacity(.1),
        onTap: () {
          if (mounted) {
            setState(() {
              widget.goInside(widget.userCircleCache);
            });
          }
          // widget.goInside(widget.userCircleCache);
        },
        child: Container(
            /*decoration: BoxDecoration(
              color: globalState.theme.circleBackground,
            ),

             */
            padding: const EdgeInsets.all(4.0),
            // color: Colors.black,
            child: Stack(alignment: Alignment.center, children: <Widget>[
              Center(
                child: widget.userCircleCache.showBadge!
                    ? AvatarGlow(
                        //startDelay: Duration(milliseconds: 1000),
                        //duration: Duration(milliseconds: 2000),
                        repeatPauseDuration: Duration(milliseconds: 100),
                        endRadius: (_circleRadiusBadgeVisible +
                            _glowBorder), //required
                        //glowColor: globalState.theme.drawerItemText,
                        glowColor: globalState.theme.circleGlow,
                        repeat: true,
                        //showTwoGlows: true,
                        animate: true,
                        curve: Curves.slowMiddle,
                        child: AvatarWidget(
                          interactive: false,
                          user: User(
                              id: widget.member.memberID,
                              username: widget.member.username,
                              avatar: widget.member.avatar),
                          userFurnace: widget.userFurnace,
                          refresh: _refresh,
                          radius: _circleRadiusBadgeVisible,
                          isUser: false,
                          //fromHome: true,
                        ),
                      )
                    : AvatarWidget(
                        interactive: false,
                        user: User(
                            id: widget.member.memberID,
                            username: widget.member.username,
                            avatar: widget.member.avatar),
                        userFurnace: widget.userFurnace,
                        refresh: _refresh,
                        radius: _circleRadius,
                        isUser: false,
                  //fromHome: true,
                      ),
              ),
              Center(
                  child: Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                //color: Color.fromRGBO(0, 0, 0, 0.5),
                alignment: Alignment.center,
                width: _circleRadius - 10,
                height: 55,
              )),
              Center(
                  child: Container(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        widget.member.returnUsernameAndAlias(),
                        textAlign: TextAlign.center,
                        textScaleFactor: globalState.nameScaleFactor,
                        style: ICTextStyle.getStyle(context: context, 
                            color: globalState.theme.dmPrefName, fontSize: 15),
                      ))),
              Center(
                  child: Container(
                      padding:
                          const EdgeInsets.only(top: 30.0, left: 15, right: 15),
                      child: Text(
                        widget.userFurnace.alias!,
                        textScaleFactor: 1.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          // color: Color(0xff0cbab8),

                          color: globalState.theme.furnace,
                          fontStyle: FontStyle.italic,
                          fontSize: 10, /*fontWeight: FontWeight.bold*/
                        ),
                      ))),
              Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.userCircleCache.hidden!
                          ? Icon(
                              Icons.lock_rounded,
                              size: 25,
                              color: globalState.theme.menuIconsAlt,
                            )
                          : Container(),
                      widget.userCircleCache.guarded!
                          ? Icon(
                              Icons.security,
                              size: 25,
                              color: globalState.theme.menuIconsAlt,
                            )
                          : Container(),
                      widget.userCircleCache.showBadge!
                          ? Icon(
                              Icons.message,
                              size: 25,
                              color: globalState.theme.circleText,
                            )
                          : Container()
                    ],
                  )),
            ])));
  }


  _refresh() {
    setState(() {});
  }
}*/
