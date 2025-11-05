import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallrepliesscreen.dart';

class WallRepliesWidget extends StatefulWidget {
  List<ReplyObject> replyObjects;
  CircleObject circleObject;
  UserFurnace userFurnace;
  ReplyObjectBloc replyObjectBloc;
  Color messageColor;
  Function refresh;
  final double maxWidth;
  UserCircleCache userCircleCache;
  GlobalEventBloc globalEventBloc;
  MemberBloc memberBloc;
  //CircleObjectBloc circleObjectBloc;

  WallRepliesWidget({
    Key? key,
    required this.replyObjects,
    required this.circleObject,
    required this.userFurnace,
    required this.replyObjectBloc,
    required this.messageColor,
    //required this.circleObjectBloc,
    required this.refresh,
    required this.maxWidth,
    required this.userCircleCache,
    required this.globalEventBloc,
    required this.memberBloc,
  }) : super(key: key);

  @override
  WallRepliesWidgetState createState() => WallRepliesWidgetState();
}

class WallRepliesWidgetState extends State<WallRepliesWidget> {
  List<ReplyObject> _replies = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Padding(
    //     padding: const EdgeInsets.only(left: 10),
    //     child:
    //       InkWell(
    //           onTap: _openWallReplies,
    //           child: Text(
    //               widget.replyObjects.isNotEmpty
    //                   ? "${AppLocalizations.of(context)!.repliesWidgetExisting} (${widget.replyObjects.length})"
    //                   : AppLocalizations.of(context)!.repliesWidgetNone,
    //               textScaler: TextScaler.linear(globalState.messageScaleFactor),
    //               style: TextStyle(
    //                 fontSize: globalState.userSetting.fontSize,
    //                 color: globalState.theme.button,
    //                 height: 1.4,
    //               )))
    //     );

    return Padding(
        padding: const EdgeInsets.only(left: 0),
        child: InkWell(
                onTap: _openWallReplies,
                child: Stack(alignment: Alignment.bottomRight, children: [
                   Padding(
                      padding:  EdgeInsets.only(right: 0, top: 3, bottom: widget.replyObjects.isEmpty ? 0 : 5),
                      child: Icon(Icons.message_rounded,
                          size: 35, color: globalState.theme.button)),
                  Text(
                      widget.replyObjects.isNotEmpty
                          ? "(${widget.replyObjects.length})"
                          : "",
                      textScaler:
                          TextScaler.linear(globalState.messageScaleFactor),
                      style: TextStyle(
                        fontSize: 12,
                        color: globalState.theme.labelText,
                        height: 1.4,
                      ))
                ])));
  }

  _openWallReplies() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WallRepliesScreen(
                  userCircleCache: widget.userCircleCache,
                  circleObject: widget.circleObject,
                  userFurnace: widget.userFurnace,
                  replyObjectBloc: widget.replyObjectBloc,
                  refresh: widget.refresh,
                  maxWidth: widget.maxWidth,
                  fromReply: false,
                  globalEventBloc: widget.globalEventBloc,
                  replyObjects: widget.replyObjects,
                  memberBloc: widget.memberBloc,
                )));
  }
}
