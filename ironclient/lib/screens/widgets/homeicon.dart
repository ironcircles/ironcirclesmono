/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:provider/provider.dart';

import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';

class HomeIcon extends StatefulWidget {
  final Function goHome;
  final bool forceRefresh;
  final String? circleID;

  HomeIcon({required this.goHome, required this.forceRefresh, this.circleID});

  @override
  State<StatefulWidget> createState() {
    return HomeIconState();
  }
}

class HomeIconState extends State<HomeIcon> {
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


    if (_firebaseBloc == null) {
      _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    }

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      if (mounted) {
        if (userFurnaces != null) {
          debugPrint('home icon');
          _userCircleBloc.fetchUserCircles(userFurnaces, true,
              fetchCircleObjects: false);
        }

        //setState(() {
         // _userFurnaces = userFurnaces;
        //});
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _firebaseBloc!.circleEvent.listen((circle) {
      if (mounted) {
        if (circle != widget.circleID)
          _userFurnaceBloc.request(globalState.user.id, true);
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _userCircleBloc.allUserCircles.listen((userCircles) {
      if (mounted) {
        bool bFound = false;

        for (UserCircleCache userCircleCache in userCircles) {
          if (userCircleCache.showBadge == true) {
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

    _userFurnaceBloc.request(globalState.user.id, true);

    super.initState();
  }

  Widget build(BuildContext context) {
    return showNew || widget.forceRefresh
        ? Stack(alignment: Alignment.center, children: <Widget>[
            IconButton(
              icon: Icon(Icons.home,
                  color: globalState.theme.menuIcons), // set your color here
              onPressed: () {
                widget.goHome();
              },
            ),
            Padding(
                padding: EdgeInsets.only(left: 15, top: 15),
                child: Container(
                    padding: EdgeInsets.only(left: 5, top: 50),
                    decoration: BoxDecoration(
                      color: globalState.theme.menuIconsAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: 8,
                      maxHeight: 8,
                    ))),
          ])
        : IconButton(
            icon: Icon(Icons.home,
                color: globalState.theme.menuIcons),
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

 */
