import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle.dart';

class InsideCircleContainer extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final List<UserCircleCache> wallUserCircleCaches;
  final UserFurnace userFurnace;
  final List<UserFurnace>? userFurnaces;
  final List<UserFurnace> wallFurnaces;
  final bool? hiddenOpen;
  final SharedMediaHolder? sharedMediaHolder;
  final Function? refresh;
  final Function? markRead;
  final Function? dismissByCircle;
  final Member? dmMember;
  final bool wall;
  final List<CircleObject> memCacheObjects;

  const InsideCircleContainer(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      this.hiddenOpen,
      this.userFurnaces,
      this.wallFurnaces = const [],
      this.sharedMediaHolder,
      required this.memCacheObjects,
      this.refresh,
      this.markRead,
      this.dismissByCircle,
      this.wall = false,
      this.wallUserCircleCaches = const [],
      this.dmMember})
      : super(key: key);

  @override
  _LocalStateState createState() => _LocalStateState();
}

class _LocalStateState extends State<InsideCircleContainer> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    try {} catch (err, trace) {
      LogBloc.postLog(err.toString(), 'InsideCircle.initState');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            key: _scaffoldKey,
            body: InsideCircle(
              replyObjects: [],
              userCircleCache: widget.userCircleCache,
              userFurnace: widget.userFurnace,
              userFurnaces: widget.userFurnaces,
              memCacheObjects: widget.memCacheObjects,
              //_wallFurnaces,
              wall: false,
              wallUserCircleCaches: widget.wallUserCircleCaches,
              wallFurnaces: widget.wallFurnaces,
              markRead: widget.markRead,
              hiddenOpen: widget.hiddenOpen,
              refresh: widget.refresh,
              dismissByCircle: widget.dismissByCircle,
              dmMember: null,
              sharedMediaHolder: widget.sharedMediaHolder,
            ))

        //bottomNavigationBar: SizedBox(height: 2),
        );
  }
}
