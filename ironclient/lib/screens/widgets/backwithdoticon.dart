import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:provider/provider.dart';

class BackWithDotIcon extends StatefulWidget {
  final Function goHome;
  final bool forceRefresh;
  final String? circleID;
  final List<UserFurnace> userFurnaces;

  const BackWithDotIcon(
      {required this.goHome,
      required this.forceRefresh,
      this.circleID,
      required this.userFurnaces});

  @override
  State<StatefulWidget> createState() {
    return _BackWithDotIconState();
  }
}

class _BackWithDotIconState extends State<BackWithDotIcon> {
  //final bool actionNeeded;
  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  FirebaseBloc? _firebaseBloc;

  bool showNew = false;

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _firebaseBloc ??= Provider.of<FirebaseBloc>(context, listen: false);

    _firebaseBloc!.circleEvent.listen((circle) {
      if (mounted) {
        if (circle != widget.circleID)
          _userCircleBloc.sinkOnly(widget.userFurnaces);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.allUserCircles.listen((userCircles) {
      if (mounted) {
        bool bFound = false;

        for (UserCircleCache userCircleCache in userCircles) {
          if (userCircleCache.showBadge == true &&
              userCircleCache.circle! != widget.circleID &&
              userCircleCache.cachedCircle!.type! != CircleType.WALL) {
            bFound = true;
            break;
          }
        }

        setState(() {
          showNew = bFound;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    //_userFurnaceBloc.request(globalState.user.id, true);

    _userCircleBloc.sinkOnly(widget.userFurnaces);

    super.initState();
  }

  Widget build(BuildContext context) {
    return showNew || widget.forceRefresh
        ? Stack(alignment: Alignment.center, children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: globalState.theme.menuIcons), // set your color here
              onPressed: () {
                widget.goHome();
              },
            ),
            InkWell(
                onTap: () {
                  widget.goHome();
                },
                child: Padding(
                    padding: const EdgeInsets.only(left: 15, top: 15),
                    child: Container(
                        padding: const EdgeInsets.only(left: 5, top: 50),
                        decoration: BoxDecoration(
                          color: globalState.theme.menuIconsAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 8,
                          maxHeight: 8,
                        )))),
          ])
        : IconButton(
            icon: Icon(Icons.arrow_back, color: globalState.theme.menuIcons), iconSize: 24,
            onPressed: () {
              setState(() {
                /*if (globalState.theme.mode == 'dark')
                  globalState.theme = DarkTheme();
                else
                  globalState.theme = LightTheme();

                 */
              });

              widget.goHome();
            },
          );
  }
}
