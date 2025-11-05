import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:provider/provider.dart';

class HiddenIcon extends StatefulWidget {
  const HiddenIcon();

  @override
  State<StatefulWidget> createState() {
    return _HiddenIconState();
  }
}

class _HiddenIconState extends State<HiddenIcon> {
  //final bool actionNeeded;
  //List<UserFurnace>? _userFurnaces;
  //late UserCircleBloc _userCircleBloc; // = UserCircleBloc();
  //final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //FirebaseBloc? _firebaseBloc;
  late GlobalEventBloc _globalEventBloc;
  bool showNew = false;

  _closeHiddenCircles() {
    _globalEventBloc.broadcastCloseHiddenCircles();
  }

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    super.initState();
  }

  Widget build(BuildContext context) {
    return globalState.hiddenOpen
        ? IconButton(
            icon: Icon(Icons.lock_rounded,
                color: globalState.theme.menuIconsAlt),
            onPressed: _closeHiddenCircles)
        : Container();
  }
}
