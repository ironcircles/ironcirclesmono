/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';

import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ChatListViewDM extends StatefulWidget {
  final List<MemberCircle> memberCircles;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Member member;
  final MemberCircle memberCircle;
  final Function goInside;
  final int index;
  final UserCircleBloc userCircleBloc;
  final bool onlyFurnace;

  ChatListViewDM(
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
  _ChatListViewDMState createState() => _ChatListViewDMState();
}

class _ChatListViewDMState extends State<ChatListViewDM> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    try {
      /* _memberCircle = widget.memberCircles.firstWhere(
          (element) => element.circleID == widget.userCircleCache.circle!);
         // orElse: () =>
            //  MemberCircle(memberID: '', userID: '', circleID: '', dm: false));

      _member = globalState.members
          .firstWhere((element) => element.memberID == _memberCircle.memberID);

      */
    } catch (err) {
      debugPrint('$err');
    }

    super.initState();
  }

  _refresh() {
    setState(() {});
  }

  Widget build(BuildContext context) {
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
            /*color: Colors.red,*/
            child: Padding(
          padding: const EdgeInsets.only(
              left: 0.0, top: 0.0, bottom: 0.0, right: 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AvatarWidget(
                interactive: false,
                user: User(
                    id: widget.member.memberID,
                    username: widget.member.username,
                    avatar: widget.member.avatar),
                userFurnace: widget.userFurnace,
                refresh: _refresh,
                radius: 60, isUser:false,
              ),
              Expanded(
                  flex: 4,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              widget.member.username.length > 20
                                  ? widget.member.returnUsernameAndAlias()
                                  : widget.member.returnUsernameAndAlias(),
                              textScaleFactor: globalState.nameScaleFactor,
                              style: TextStyle(
                                  fontSize: 17, color: widget.member.color),
                            )),
                        Row(children: [
                          Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                widget.userFurnace.alias!,
                                textScaleFactor: 1.0,
                                style:
                                    TextStyle(color: globalState.theme.furnace),
                              )),
                        ])
                      ])),
              Padding(
                  padding: EdgeInsets.only(right: 0),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 25,
                    color: widget.userCircleCache.hidden!
                        ? globalState.theme.menuIconsAlt
                        : Colors.transparent,
                  )),
              Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.security,
                    size: 25,
                    color: widget.userCircleCache.guarded!
                        ? globalState.theme.menuIconsAlt
                        : Colors.transparent,
                  )),
              Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.message,
                    size: 22,
                    color: widget.userCircleCache.showBadge!
                        ? globalState.theme.menuIcons
                        : Colors.transparent,
                  )),
              Padding(padding: EdgeInsets.only(right: 5)),
              SizedBox(
                  width: 75,
                  child: Text(
                    _returnDateString(),
                    textScaleFactor: 1.0,
                    style: TextStyle(color: globalState.theme.labelTextSubtle),
                  )),
              Padding(padding: EdgeInsets.only(right: 10))
            ],
          ),
        )));
  }

  String _returnDateString() {
    DateTime now = DateTime.now();

    if (widget.userCircleCache.lastItemUpdate!.year == now.year &&
        widget.userCircleCache.lastItemUpdate!.month == now.month &&
        widget.userCircleCache.lastItemUpdate!.day == now.day) {
      return DateFormat('hh:mm a')
          .format(widget.userCircleCache.lastItemUpdate!);
    } else {
      return DateFormat('MMM dd')
          .format(widget.userCircleCache.lastItemUpdate!);
    }
  }
}

 */
