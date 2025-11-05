import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/centralcalendar.dart';
import 'package:provider/provider.dart';

class CentralCalendarScreen extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final Function refreshCallback;
  final bool slideUpPanel;
  final Function? setEventDateTime;

  const CentralCalendarScreen({
    Key? key,
    required this.userFurnaces,
    required this.refreshCallback,
    this.setEventDateTime,

    this.slideUpPanel = false,
  }) : super(key: key);

  @override
  _CentralCalendarScreenState createState() => _CentralCalendarScreenState();
}

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}

class _CentralCalendarScreenState extends State<CentralCalendarScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  //UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late GlobalEventBloc _globalEventBloc;
  late CircleObjectBloc _circleObjectBloc;

  bool filter = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        //appBar: topAppBar,
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
              child: Stack(children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                          child:   CentralCalendar(
                              calendarType: "all",
                              screenMode: CalendarMode.create,
                              userCircleCache: null,
                              circleObjectBloc: _circleObjectBloc,
                              userFurnace: null,
                              slideUpPanel: widget.slideUpPanel,
                              userFurnaces: widget.userFurnaces,
                              setEventDateTime: widget.setEventDateTime,
                              replyObject: null))
                    ])
              ])),
        ));
  }
}
