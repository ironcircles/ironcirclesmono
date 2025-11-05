import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/centralcalendar.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class CircleEventCalendar extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final CircleObjectBloc circleObjectBloc;
  final CalendarMode screenMode;
  final DateTime? scheduledFor;
  final int? increment;

  //final CircleListBloc circleListBloc;
  final CircleObject? replyObject;
  //final int timer;

  const CircleEventCalendar(
      {Key? key,
      required this.userCircleCache,
      required this.circleObjectBloc,
      required this.userFurnace,
      required this.userFurnaces,
      required this.replyObject,
      this.scheduledFor,
      this.increment,
      required this.screenMode})
      : super(key: key);

  @override
  _CircleEventCalendarState createState() => _CircleEventCalendarState();
}

class _CircleEventCalendarState extends State<CircleEventCalendar> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  popReturnData(CircleObject circleObject) {
    if (circleObject.id == null) {
      Navigator.pop(context, circleObject);
      return Future<bool>.value(true);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.createAnEvent,
      ),
      body: SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                      child: CentralCalendar(
                          calendarType: "all",
                          screenMode: widget.screenMode,
                          userCircleCache: widget.userCircleCache,
                          circleObjectBloc: widget.circleObjectBloc,
                          userFurnace: widget.userFurnace,
                          scheduledFor: widget.scheduledFor,
                          increment: widget.increment,
                          userFurnaces: widget.userFurnaces,
                          replyObject: widget.replyObject))
                ])),
      ),
    );
  }

}
