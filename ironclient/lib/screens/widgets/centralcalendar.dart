import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleevent_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_detail.dart';
import 'package:ironcirclesapp/screens/utilities/selectcirclescreen.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

enum CalendarMode {
  create,
  edit,
}

class CentralCalendar extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? filteredUserFurnace;
  final UserFurnace? userFurnace;
  final List<UserFurnace> userFurnaces;
  final CircleObjectBloc circleObjectBloc;
  final CircleObject? replyObject;
  final CalendarMode screenMode;
  final Function? longPress;
  final String calendarType;
  late CircleObject? selected;
  final bool slideUpPanel;
  final DateTime? scheduledFor;
  final int? increment;
  final Function? setEventDateTime;

  CentralCalendar(
      {Key? key,
      required this.userCircleCache,
      required this.circleObjectBloc,
      required this.userFurnace,
      this.filteredUserFurnace,
      required this.userFurnaces,
      required this.replyObject,
      required this.screenMode,
      this.longPress,
      this.selected,
      this.scheduledFor,
      this.increment,
      this.setEventDateTime,
      this.slideUpPanel = false,
      required this.calendarType})
      : super(key: key);

  @override
  _CentralCalendarState createState() => _CentralCalendarState();
}

List<CircleObject> _events = [];

class _CentralCalendarState extends State<CentralCalendar> {
  late FirebaseBloc _firebaseBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final CircleEventBloc _circleEventBloc = CircleEventBloc();

  late CircleEvent _circleEvent;
  DateTime? _selectedDay;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _addNew = true;
  final double _iconSize = 25;
  late GlobalEventBloc _globalEventBloc;

  late DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // late DateTime _firstDay = DateTime(_today.year, _today.month - 3, _today.day);
  //late DateTime _lastDay = DateTime(_today.year, _today.month + 3, _today.day);

  late final ValueNotifier<List<CircleObject>> _selectedEvents;

  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOn; // Can be toggled on/off by longpressing a date

  final bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    _today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    //_firstDay = DateTime(_today.year, _today.month - 3, _today.day);
    // _lastDay = DateTime(_today.year, _today.month + 3, _today.day);

    _focusedDay = _today;

    _circleEvent = CircleEvent(
        respondents: [],
        encryptedLineItems: [],
        startDate: DateTime(
            _today.year, _today.month, _today.day, DateTime.now().hour + 1),
        endDate: DateTime(
            _today.year, _today.month, _today.day, DateTime.now().hour + 2));

    //_duration = _circleEvent.endDate.hour - _circleEvent.startDate.hour;

    //_globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _selectedDay = _today;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    _firebaseBloc.calendarRefresh.listen((events) async {
      if (mounted) {
        try {
          _circleEventBloc.readEventsFromCache(
              _globalEventBloc, widget.userFurnaces, widget.userCircleCache);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'CentralCalendar._firebaseBloc.calendarRefresh.listen: $err');
        }
      }
    }, onError: (err) {
      //_clearSpinner();
      debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
    }, cancelOnError: false);

    _circleEventBloc.scheduledEvents.listen((events) async {
      if (mounted) {
        try {
          setState(() {
            _events = events;

            //DateTime.utc(kFirstDay.year, kFirstDay.month, item * 5)

            _kEventSource = Map.fromIterable(
              _events,
              key: (item) => DateTime(item.event.startDate.year,
                  item.event.startDate.month, item.event.startDate.day),
              value: (item) => _events
                  .where((element) =>
                      DateTime(
                          element.event!.startDate.year,
                          element.event!.startDate.month,
                          element.event!.startDate.day) ==
                      DateTime(
                          item.event!.startDate.year,
                          item.event!.startDate.month,
                          item.event!.startDate.day))
                  .toList(),
            );

            kEvents = LinkedHashMap<DateTime, List<CircleObject>>(
              equals: isSameDay,
              hashCode: getHashCode,
            )..addAll(_kEventSource);

            // if (_selectedEvents.value.isEmpty)
            // _selectedEvents.value = _getEventsForDay(_today);
            // else
            _selectedEvents.value = _getEventsForRange(
                _circleEvent.startDate, _circleEvent.endDate);
          });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(
              'CentralCalendar._circleEventBloc.scheduledEvents.listen: $err');
        }
      }
    }, onError: (err) {
      //_clearSpinner();
      debugPrint("CentralCalendar._circleEventBloc.scheduledEvents: $err");
    }, cancelOnError: false);

    //_circleEventBloc.readEventsFromCache(
    // widget.userFurnaces, widget.userCircleCache);
  }

  List<CircleObject> _getEventsForDay(DateTime day) {
    if (kEvents != null) {
      return kEvents[day] ?? [];
    } else
      return [];
  }

  List<CircleObject> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    DateTime now = DateTime.now();

    //debugPrint('_onDaySelected: ${now.compareTo(selectedDay)}');
    //debugPrint(now.toString());
    //debugPrint(_today.toString());
    // debugPrint(selectedDay.toString());

    if (now.compareTo(selectedDay) <= 0)
      _addNew = true;
    else
      _addNew = false;

    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        Duration duration =
            _circleEvent.endDate.difference(_circleEvent.startDate);

        _circleEvent.startDate = DateTime(selectedDay.year, selectedDay.month,
            selectedDay.day, now.hour, now.minute);
        _circleEvent.endDate = _circleEvent.startDate.add(duration);

        _selectedDay =
            selectedDay; //DateTime(selectedDay.year, selectedDay.month, now.hour, now.minute);
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    } else if (_addNew) setState(() {});

    if (widget.setEventDateTime != null) {
      widget.setEventDateTime!(_circleEvent.startDate, _circleEvent.endDate);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    //debugPrint('_onRangeSelected()');

    // `start` or `end` could be null
    if (start != null && end != null) {
      _circleEvent.startDate = DateTime(start.year, start.month, start.day,
          _circleEvent.startDate.hour, _circleEvent.startDate.minute);

      _circleEvent.endDate = DateTime(end.year, end.month, end.day,
          _circleEvent.endDate.hour, _circleEvent.endDate.minute);
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _circleEvent.startDate = DateTime(start.year, start.month, start.day,
          _circleEvent.startDate.hour, _circleEvent.startDate.minute);
      _circleEvent.endDate = DateTime(start.year, start.month, start.day,
          _circleEvent.endDate.hour, _circleEvent.endDate.minute);
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      // _circleEvent.startDate = end;
      _circleEvent.endDate = DateTime(end.year, end.month, end.day,
          _circleEvent.endDate.hour, _circleEvent.endDate.minute);
      _selectedEvents.value = _getEventsForDay(end);
    }

    debugPrint(
        '_onRangeSelected: ${DateTime.now().compareTo(_circleEvent.startDate)}');

    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;

      if (_today.compareTo(_circleEvent.startDate) <= 0)
        _addNew = true;
      else
        _addNew = false;
    });

    if (widget.setEventDateTime != null) {
      widget.setEventDateTime!(_circleEvent.startDate, _circleEvent.endDate);
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    _circleEventBloc.readEventsFromCache(
        _globalEventBloc, widget.userFurnaces, widget.userCircleCache);

    final _showCalendar = TableCalendar(
      headerStyle: HeaderStyle(
          titleTextStyle: TextStyle(
              fontSize: ((14 / globalState.mediaScaleFactor) *
                      globalState.messageScaleFactor) -
                  globalState.scaleDownTextFont)),
      daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle:
              TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
          weekendStyle:
              TextStyle(fontSize: (14 / globalState.mediaScaleFactor))),
      availableCalendarFormats: const {CalendarFormat.month: 'month'},
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: globalState.theme.menuIconsAlt,
          shape: BoxShape.circle,
        ),
        holidayTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(
            fontSize: (14 / globalState.mediaScaleFactor),
            color: globalState.theme.calendarDayOfWeek),
        selectedTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        outsideTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        rangeStartTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        rangeEndTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        todayTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        weekendTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        withinRangeTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        disabledTextStyle:
            TextStyle(fontSize: (14 / globalState.mediaScaleFactor)),
        selectedDecoration: BoxDecoration(
            color: globalState.theme.calendarRangeStart,
            shape: BoxShape.circle),
        todayDecoration: BoxDecoration(
            color: globalState.theme.calendarToday, shape: BoxShape.circle),
        rangeHighlightColor: globalState.theme.calendarRange,
        rangeStartDecoration: BoxDecoration(
            color: globalState.theme.calendarRangeStart,
            shape: BoxShape.circle),
        rangeEndDecoration: BoxDecoration(
            color: globalState.theme.calendarRangeEnd, shape: BoxShape.circle),
      ),
      firstDay: DateTime.utc(2022, 01, 01),
      lastDay: DateTime.utc(2032, 3, 14),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      locale: GlobalEventBloc.returnLocale(context).toString(),//(AppLocalizations.of(context)!.language).toString() == Language.TURKISH.toString()? 'tr': 'en_us',
      eventLoader: _getEventsForDay,
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: _rangeSelectionMode,
      calendarFormat: CalendarFormat.month,
      onDaySelected: _onDaySelected,
      onRangeSelected: _onRangeSelected,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );

    final _showEvents = Expanded(
        child: ValueListenableBuilder<List<CircleObject>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    CircleObject circleObject = value[index];
                    return Stack(children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: ButtonType.getWidth(width),
                              ), //vertical: 4
                              decoration: BoxDecoration(
                                color: globalState.theme.buttonIconHighlight,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  onLongPress: () {
                                    widget.calendarType == "vault"
                                        ? widget.longPress!(circleObject)
                                        : _nothing();
                                  },
                                  onTap: () {
                                    /*Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CircleEventDetail(
                                          userFurnaces: widget.userFurnaces,
                                          circleObjectBloc:
                                              widget.circleObjectBloc,
                                          circleObject: circleObject,
                                          userFurnace:
                                              circleObject.userFurnace!,
                                          userCircleCache:
                                              circleObject.userCircleCache!,
                                          replyObject: widget.replyObject,
                                        )),
                              );*/

                                    _shortPress(circleObject);
                                  },
                                  leading: widget.calendarType == "vault"
                                      ? widget.selected == null
                                          ? null
                                          : widget.selected!.seed ==
                                                  circleObject.seed
                                              ? Icon(Icons.check_circle,
                                                  color: globalState
                                                      .theme.buttonIcon)
                                              : Icon(Icons.circle_outlined,
                                                  color: globalState
                                                      .theme.buttonIcon)
                                      : null,
                                  title: Text(circleObject.event!.title),
                                  subtitle: Column(children: [
                                    Row(children: [
                                      Expanded(
                                        child: ICText(
                                          circleObject
                                              .userCircleCache!.prefName!,
                                          overflow: TextOverflow.ellipsis,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      Text(
                                        '${circleObject.event!.startDateString} @ ${circleObject.event!.startTimeString}',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ]),
                                    Row(children: [
                                      Expanded(
                                        child: ICText(
                                            circleObject.userFurnace!.alias!,
                                            overflow: TextOverflow.ellipsis,
                                            color: Colors.black),
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      Text(
                                        '${circleObject.event!.endDateString} @ ${circleObject.event!.endTimeString}',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ]),
                                  ]),
                                  trailing: const Icon(
                                      Icons.keyboard_arrow_right,
                                      color: Colors.white,
                                      size: 30.0),
                                ),
                              ))),
                    ]);
                  });
            }));

    return MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1),
        ),
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          //appBar: topAppBar,
          body:   Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _showCalendar,
                  _showEvents,
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
          floatingActionButton: _addNew && widget.slideUpPanel == false
              ? FloatingActionButton(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0))),
                  heroTag: "new",
                  backgroundColor: globalState.theme.homeFAB,
                  onPressed: () async {
                    if (widget.userFurnace == null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SelectCircleScreen(selected: _createEvent)));
                    } else {
                      if (widget.screenMode == CalendarMode.create)
                        _createEvent(
                            widget.userFurnace!, widget.userCircleCache!);
                      else
                        Navigator.pop(context, _circleEvent);
                    }
                  },
                  child: Icon(
                    widget.screenMode == CalendarMode.create
                        ? Icons.add
                        : Icons.check,
                    size: _iconSize + 5,
                    color: globalState.theme.background,
                  ),
                )
              : Container(),
        ));
  }

  _nothing() {
    //does nothing
  }

  _shortPress(circleObject) {
    if (widget.selected != null) {
      widget.selected = circleObject;
    } else {
      _openEvent(circleObject, circleObject.userFurnace!,
          circleObject.userCircleCache!);
    }
  }

  _createEvent(UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    CircleObject? circleObject = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CircleEventDetail(
                userFurnaces: widget.userFurnaces,
                circleObjectBloc: widget.circleObjectBloc,
                circleObject:
                    CircleObject(ratchetIndexes: [], event: _circleEvent),
                userFurnace: userFurnace,
                userCircleCache: userCircleCache,
                replyObject: widget.replyObject,
                fromCentralCalendar: true,
                increment: widget.increment,
                scheduledFor: widget.scheduledFor,
              )),
    );

    if (circleObject == null) return;

    _circleEvent = circleObject.event!;

    if (widget.userFurnace != null && widget.calendarType != "vault") {
      if (circleObject.seed != null) Navigator.pop(context, _circleEvent);
    } else {
      if (circleObject.seed != null) {
        _circleEvent = CircleEvent(
            respondents: [],
            encryptedLineItems: [],
            startDate: _circleEvent.startDate,
            endDate: _circleEvent.endDate);
      }
      _circleEventBloc.readEventsFromCache(
          _globalEventBloc, widget.userFurnaces, widget.userCircleCache);
    }
  }

  _openEvent(CircleObject circleObject, UserFurnace userFurnace,
      UserCircleCache userCircleCache) async {
    CircleObject? returnObject;

    returnObject = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CircleEventDetail(
                userFurnaces: widget.userFurnaces,
                circleObjectBloc: widget.circleObjectBloc,
                circleObject: circleObject,
                userFurnace: userFurnace,
                userCircleCache: userCircleCache,
                replyObject: widget.replyObject,
                fromCentralCalendar: true,
              )),
    );

    if (returnObject != null) {
      circleObject = returnObject;

      _circleEvent = circleObject.event!;

      if (widget.userFurnace != null && widget.calendarType != "vault") {
        if (circleObject.seed != null) Navigator.pop(context, _circleEvent);
      } else {
        _circleEvent = CircleEvent(
            respondents: [],
            encryptedLineItems: [],
            startDate: _circleEvent.startDate,
            endDate: _circleEvent.endDate);

        _onDaySelected(_circleEvent.startDate, _circleEvent.startDate);

        _circleEventBloc.readEventsFromCache(
            _globalEventBloc, widget.userFurnaces, widget.userCircleCache);
      }
    }
  }

  var kEvents;

  Map<DateTime, List<CircleObject>> _kEventSource = Map();

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  /// Returns a list of [DateTime] objects from [first] to [last], inclusive.
  List<DateTime> daysInRange(DateTime first, DateTime last) {
    final dayCount = last.difference(first).inDays + 1;
    return List.generate(
      dayCount,
      (index) => DateTime.utc(first.year, first.month, first.day + index),
    );
  }
}
