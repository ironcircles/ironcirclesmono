import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleevent_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/circleeventrespondent.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circleevent_attendees.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/pickers.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

/*

This class won't format because of the method at the very bottom.  Not sure why, but remove it, format, put it back works.

 */

class CircleEventDetail extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final CircleObject? circleObject;
  final CircleObject? replyObject;
  final CircleObjectBloc circleObjectBloc;
  final bool fromCentralCalendar;
  final int? increment;
  final DateTime? scheduledFor;
  final bool wall;
  final Function? setNetworks;

  const CircleEventDetail(
      {Key? key,
      required this.circleObjectBloc,
      required this.userCircleCache,
      required this.userFurnace,
      required this.circleObject,
      required this.userFurnaces,
      required this.fromCentralCalendar,
      this.increment,
      this.setNetworks,
      this.scheduledFor,
      this.wall = false,
      this.replyObject})
      : super(key: key);

  @override
  _CircleEventDetailState createState() => _CircleEventDetailState();
}

enum Mode {
  create,
  edit,
  respond,
  readonly,
}

enum RSVP {
  yes,
  maybe,
  no,
}

class _CircleEventDetailState extends State<CircleEventDetail> {
  final ScrollController _scrollController = ScrollController();
  late GlobalEventBloc _globalEventBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late CircleEvent _circleEvent;
  final CircleEventBloc _circleEventBloc = CircleEventBloc();
  int _rsvpIndex = RSVP.maybe.index;
  late Mode screenMode;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late CircleEventRespondent _circleEventRespondent;
  late UserCircleCache _userCircleCache;
  late UserFurnace _userFurnace;
  List<UserFurnace> _selectedNetworks = [];
  bool _popping = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    _userCircleCache = widget.userCircleCache;
    _userFurnace = widget.userFurnace;
    _findAttendee();

    DateTime now = DateTime.now();

    if (DateTime(
                widget.circleObject!.event!.endDate.year,
                widget.circleObject!.event!.endDate.month,
                widget.circleObject!.event!.endDate.day)
            .compareTo(DateTime(now.year, now.month, now.day)) <
        0) {
      screenMode = Mode.readonly;
    } else if (widget.circleObject!.id == null) {
      screenMode = Mode.create;
      _rsvpIndex = 0;
      _circleEventRespondent.numOfGuests = 1;
      widget.circleObject!.event!.respondents = [_circleEventRespondent];
    } else if (widget.circleObject!.creator!.id == widget.userFurnace.userid)
      screenMode = Mode.edit;
    else
      screenMode = Mode.respond;
    if (_circleEventRespondent.numOfGuests == 0)
      _circleEventRespondent.numOfGuests = 1;
    _circleEvent = widget.circleObject!.event!;

    _titleController.text = _circleEvent.title;
    _descriptionController.text = _circleEvent.description;
    _locationController.text = _circleEvent.location;
    _rsvpIndex = _circleEventRespondent.attending.index;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    //Event was cached, return object
    widget.circleObjectBloc.saveResults.listen((object) {
      if (mounted) {
        setState(() {
          if (widget.fromCentralCalendar) {
            if (object.id != null) _exit(circleObject: object);

            ///wait until the save completes
          } else {
            _exit(circleObject: object);

            ///Pop back to InsideCircle screen while saving continues
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: (screenMode == Mode.create || screenMode == Mode.edit)
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                  maxHeight:
                      125 //put here the max height to which you need to resize the textbox
                  ),
              child: ExpandingLineText(
                  maxLength: TextLength.Smallest,
                  maxLines: 3,
                  readOnly:
                      (screenMode == Mode.create || screenMode == Mode.edit)
                          ? false
                          : true,
                  labelText: AppLocalizations.of(context)!.eventTitle,
                  controller: _titleController,
                  validator: (value) {
                    if (value.isEmpty) {
                      return AppLocalizations.of(context)!.errorFieldRequired;
                    }

                    return null;
                  }))
          : Padding(
              padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.title}:\t\t',
                      textScaler: TextScaler.linear(
                          globalState.messageHeaderScaleFactor),
                      style: TextStyle(
                          fontSize: 18, color: globalState.theme.labelText),
                    ),
                    Expanded(
                        child: Text(_titleController.text,
                            textScaler: TextScaler.linear(
                                globalState.messageHeaderScaleFactor),
                            style: TextStyle(
                                fontSize: globalState.userSetting.fontSize,
                                color: globalState.theme.buttonIcon))),
                  ])),
    );

    final description = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: (screenMode == Mode.create || screenMode == Mode.edit)
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                  maxHeight:
                      125 //put here the max height to which you need to resize the textbox
                  ),
              child: ExpandingLineText(
                maxLength: TextLength.Small,
                maxLines: 3,
                readOnly: (screenMode == Mode.create || screenMode == Mode.edit)
                    ? false
                    : true,
                labelText: AppLocalizations.of(context)!.description.toLowerCase(),
                controller: _descriptionController,
                /*validator: (value) {
                          if (value.isEmpty) {
                            return 'field is required';
                          }
                        },

                         */
              ))
          : _descriptionController.text.isEmpty
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.description}:\t\t',
                          textScaler: TextScaler.linear(
                              globalState.messageHeaderScaleFactor),
                          style: TextStyle(
                              fontSize: 18, color: globalState.theme.labelText),
                        ),
                        Expanded(
                            child: Text(_descriptionController.text,
                                textScaler: TextScaler.linear(
                                    globalState.messageHeaderScaleFactor),
                                style: TextStyle(
                                    fontSize: globalState.userSetting.fontSize,
                                    color: globalState.theme.buttonIcon))),
                        //Spacer()
                      ])),
    );

    final location = Row(mainAxisSize: MainAxisSize.min, children: [
      (screenMode == Mode.readonly || screenMode == Mode.respond)
          ? InkWell(
              onTap: () {
                MapsLauncher.launchQuery(_locationController.text);
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                    padding: const EdgeInsets.only(left: 14, top: 0, bottom: 4),
                    child: Text(
                      '${AppLocalizations.of(context)!.location.toLowerCase()}:\t\t',
                      textScaler: TextScaler.linear(
                          globalState.messageHeaderScaleFactor),
                      style: TextStyle(
                          fontSize: 18, color: globalState.theme.labelText),
                    )),
                Text(_locationController.text,
                    textScaler:
                        TextScaler.linear(globalState.messageHeaderScaleFactor),
                    style: TextStyle(
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.buttonIcon)),
                //Spacer()
              ]))
          : (screenMode == Mode.create || screenMode == Mode.edit)
              ? Expanded(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 125),
                      child: ExpandingLineText(
                        maxLength: TextLength.Small,
                        maxLines: 3,
                        labelText: AppLocalizations.of(context)!.location.toLowerCase(),
                        controller: _locationController,
                        /*validator: (value) {
                          if (value.isEmpty) {
                            return 'field is required';
                          }
                        },

                         */
                      )))
              : Container(),
      IconButton(
          onPressed: () {
            MapsLauncher.launchQuery(_locationController.text);
          },
          icon: Icon(
            Icons.map,
            color: globalState.theme.buttonIcon,
          ))
    ]);

    final start = Padding(
        padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
        child: Row(children: [
          ICText('${AppLocalizations.of(context)!.start.toLowerCase()}:\t\t',
              textScaleFactor: globalState.messageHeaderScaleFactor,
              fontSize: globalState.userSetting.fontSize,
              color: globalState.theme.labelText),
          Row(children: [
            InkWell(
                onTap: _changeStartDate,
                child: ICText(_circleEvent.startDateString,
                    textScaleFactor: globalState.messageHeaderScaleFactor,
                    fontSize: globalState.userSetting.fontSize,
                    color: globalState.theme.textField)),
            Padding(
                padding: const EdgeInsets.only(left: 0, top: 4, bottom: 4),
                child: Row(children: [
                  ICText(' @ ',
                      textScaleFactor: globalState.messageHeaderScaleFactor,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.labelText),
                  InkWell(
                      onTap: _selectStartTime,
                      child: ICText(_circleEvent.startTimeString,
                          textScaleFactor: globalState.messageHeaderScaleFactor,
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.textField)),
                ]))
          ])
        ]));

    final end = Padding(
        padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
        child: Row(children: [
          ICText('${AppLocalizations.of(context)!.end.toLowerCase()}:\t\t\t\t',
              textScaleFactor: globalState.messageHeaderScaleFactor,
              fontSize: globalState.userSetting.fontSize,
              color: globalState.theme.labelText),
          Row(children: [
            InkWell(
                onTap: _changeEndDate,
                child: ICText(_circleEvent.endDateString,
                    textScaleFactor: globalState.messageHeaderScaleFactor,
                    fontSize: globalState.userSetting.fontSize,
                    color: globalState.theme.textField)),
            Padding(
                padding: const EdgeInsets.only(left: 0, top: 4, bottom: 4),
                child: Row(children: [
                  ICText(' @ ',
                      textScaleFactor: globalState.messageHeaderScaleFactor,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.labelText),
                  InkWell(
                      onTap: _selectEndTime,
                      child: ICText(_circleEvent.endTimeString,
                          textScaleFactor: globalState.messageHeaderScaleFactor,
                          fontSize: globalState.userSetting.fontSize,
                          color: globalState.theme.textField))
                ]))
          ]),
        ]));

    final rsvp = screenMode != Mode.readonly
        ? Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(children: [
              Row(
                children: [
                  ICText(AppLocalizations.of(context)!.rsvp,
                      textScaleFactor: globalState.messageHeaderScaleFactor,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.labelText),
                  const SizedBox(
                    width: (180),
                  ),
                  ICText(AppLocalizations.of(context)!.guests,
                      textScaleFactor: globalState.messageHeaderScaleFactor,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.labelText),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 10)),
              Row(children: [
                MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(1),
                    ),
                    child: ToggleSwitch(
                      customWidths: const [70, 70, 70],
                      initialLabelIndex: _rsvpIndex,
                      activeBgColor: [globalState.theme.textField],
                      inactiveBgColor: globalState.theme.tabBackground,
                      totalSwitches: 3,
                      labels: [
                        AppLocalizations.of(context)!.yes,
                        AppLocalizations.of(context)!.maybe,
                        AppLocalizations.of(context)!.no,
                      ],
                      customTextStyles: [
                        TextStyle(
                            fontSize:
                                12 / MediaQuery.textScalerOf(context).scale(1)),
                        TextStyle(
                            fontSize:
                                12 / MediaQuery.textScalerOf(context).scale(1)),
                        TextStyle(
                            fontSize:
                                12 / MediaQuery.textScalerOf(context).scale(1))
                      ],
                      onToggle: (index) {
                        //debugPrint(index);

                        if (index == 2) {
                          _circleEventRespondent.numOfGuests = 1;
                        }

                        setState(() {
                          //if (index == 0) {}
                          _rsvpIndex = index!;

                          _circleEventRespondent.attending =
                              Attending.values[index];
                        });

                        //_rsvpIndex = index!;
                      },
                    )),
                // Padding(padding: EdgeInsets.only(left:20)),

                const SizedBox(
                  width: 18,
                ),

                _rsvpIndex == RSVP.no.index
                    ? Container()
                    : Row(children: [
                        SizedBox(
                            width: 25,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        globalState.theme.textField,
                                    backgroundColor:
                                        globalState.theme.tabBackground,
                                    shape: const ContinuousRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)))),
                                onPressed: () {
                                  _decrement(1);
                                },
                                child: ICText('-',
                                    textScaleFactor:
                                        globalState.messageHeaderScaleFactor,
                                    color: globalState.theme.buttonIcon))),
                        Padding(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: Text(
                                _circleEventRespondent.numOfGuests.toString(),
                                textScaler: TextScaler.linear(
                                    globalState.messageHeaderScaleFactor),
                                style: TextStyle(
                                    color: globalState.theme.labelText))),
                        SizedBox(
                            width: 25,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        globalState.theme.textField,
                                    backgroundColor:
                                        globalState.theme.tabBackground,
                                    shape: const ContinuousRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)))),
                                onPressed: () {
                                  _increment(1);
                                },
                                child: ICText('+',
                                    textScaleFactor:
                                        globalState.messageHeaderScaleFactor,
                                    color: globalState.theme.buttonIcon))),
                      ])
              ])
            ]))
        : Container();

    final attendeeCount = Padding(
        padding: const EdgeInsets.only(
          top: 10,
        ),
        child: Column(children: [
          Row(
            children: [
              ICText(AppLocalizations.of(context)!.attendeeCount,
                  textScaleFactor: globalState.messageHeaderScaleFactor,
                  fontSize: globalState.userSetting.fontSize,
                  color: globalState.theme.labelText),
            ],
          ),
          Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 0),
              child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CircleEventAttendees(
                                userFurnace: widget.userFurnace,
                                circleObject: CircleObject(
                                    ratchetIndexes: [], event: _circleEvent),
                              )),
                    );
                  },
                  child: Row(children: [
                    ICText('${AppLocalizations.of(context)!.yes}: ',
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.labelText),
                    ICText(
                        widget.circleObject!.event!.attendingYesCount
                            .toString(),
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.textField),
                    const Padding(
                        padding: EdgeInsets.only(top: 0, left: 30, right: 0)),
                    ICText('${AppLocalizations.of(context)!.maybe}: ',
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.labelText),
                    ICText(
                        widget.circleObject!.event!.attendingMaybeCount
                            .toString(),
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.textField),
                    const Padding(
                        padding: EdgeInsets.only(top: 0, left: 30, right: 0)),
                    ICText('${AppLocalizations.of(context)!.no}: ',
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.labelText),
                    ICText(
                        widget.circleObject!.event!.attendingNoCount.toString(),
                        textScaleFactor: globalState.messageHeaderScaleFactor,
                        fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.textField),
                  ])))
        ]));

    final makeButton = (screenMode == Mode.create ||
            screenMode == Mode.edit ||
            screenMode == Mode.respond)
        ? SizedBox(
            height: 75.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2),
              child: Row(children: <Widget>[
                Expanded(
                    child: GradientButton(
                        width: MediaQuery.of(context).size.width,
                        text: screenMode == Mode.create
                            ? AppLocalizations.of(context)!.cREATEEVENT
                            : screenMode == Mode.edit
                                ? AppLocalizations.of(context)!.uPDATEEVENT
                                : 'RSVP',
                        onPressed: () {
                          _save();
                        })),
              ]),
            ),
          )
        : Container();

    final getForm = Form(
        key: _formKey,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            key: _scaffoldKey,
            appBar: ICAppBar(title: AppLocalizations.of(context)!.eventDetails),
            body: SafeArea(
              left: true,
              top: false,
              right: true,
              bottom: true,
              child: Container(
                //color: globalState.theme.body,
                // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 0, bottom: 5),
                child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _scrollController,
                        child: WrapperWidget(child:Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                title,
                                start,
                                end,
                                description,
                                location,
                                rsvp,
                                //_numberOfGuests,
                                attendeeCount,

                                ///select a furnace to post to
                                widget.userFurnaces.length > 1 &&
                                        widget.wall &&
                                        widget.setNetworks != null
                                    ? Row(children: <Widget>[
                                        Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10, left: 2, right: 2),
                                              child: SelectNetworkTextButton(
                                                userFurnaces:
                                                    widget.userFurnaces,
                                                selectedNetworks:
                                                    _selectedNetworks,
                                                callback: _setNetworks,
                                              ),
                                            ))
                                      ])
                                    : Container(),
                                makeButton,
                              ],
                            ),
                            _showSpinner ? Center(child: spinkit) : Container(),
                          ],
                        ))),
              ),
            ))));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) => _exit,
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _exit();
                  }
                },
                child: getForm)
            : getForm);
  }

  _increment(int value) {
    setState(() {
      _circleEventRespondent.numOfGuests += value;
      if (_circleEventRespondent.numOfGuests > 2000)
        _circleEventRespondent.numOfGuests = 2000;
    });
  }

  _decrement(int value) {
    setState(() {
      _circleEventRespondent.numOfGuests -= value;

      if (_circleEventRespondent.numOfGuests < 1)
        _circleEventRespondent.numOfGuests = 1;
    });
  }

  _changeEndDate() async {
    if (screenMode == Mode.create || screenMode == Mode.edit) {
      DateTime? date = await showDatePicker(
          context: context,
          firstDate: _circleEvent.startDate,
          lastDate: DateTime(DateTime.now().year + 5),
          initialDate: _circleEvent.startDate,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.dark(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      )
                    : Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!));
          });

      setState(() {
        if (date != null) {
          _circleEvent.endDate = date;
          if (date.isBefore(_circleEvent.startDate)) {
            _circleEvent.startDate = date;
          }
        }
      });
    }
  }

  _changeStartDate() async {
    if (screenMode == Mode.create || screenMode == Mode.edit) {
      DateTime? date = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(DateTime.now().year + 5),
          initialDate: DateTime.now(),
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.dark(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      )
                    : Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!));
          });

      setState(() {
        if (date != null) {
          _circleEvent.startDate = date;
          if (date.isAfter(_circleEvent.endDate)) {
            _circleEvent.endDate = date;
          }
        }
      });
    }
  }
  //
  // _canEditDates() async {
  //   if (screenMode == Mode.create || screenMode == Mode.edit) {
  //     if (widget.circleObject!.id == null) {
  //       _exit();
  //     } else {
  //       var result = await Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //             builder: (context) => CircleEventCalendar(
  //                   circleObjectBloc: widget.circleObjectBloc,
  //                   userFurnaces: widget.userFurnaces,
  //                   userFurnace: widget.userFurnace,
  //                   userCircleCache: widget.userCircleCache,
  //                   replyObject: null,
  //                   screenMode: CalendarMode.edit,
  //                 )),
  //       ); //.then(_circleObjectBloc.requestNewerThan(
  //
  //       setState(() {
  //         _circleEvent.startDate = result.startDate;
  //         _circleEvent.endDate = result.endDate;
  //       });
  //     }
  //   }
  // }

  _exit({CircleObject? circleObject}) {
    debugPrint("exit called");

    if (_popping == false) {
      _popping = true;
      _closeKeyboard();
      if (circleObject != null) {
        _circleEvent.title = _titleController.text;
        _circleEvent.description = _descriptionController.text;
        _circleEvent.location = _locationController.text;

        widget.circleObject!.event = _circleEvent;
        circleObject.event = _circleEvent;
        Navigator.of(context).pop(circleObject);
      }
    } else {
      Navigator.pop(context);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _findAttendee() {
    _circleEventRespondent = widget.circleObject!.event!.respondents.firstWhere(
        (element) => element.respondent.id == _userFurnace.userid,
        orElse: () => CircleEventRespondent(
            respondent:
                User(id: _userFurnace.userid!, username: _userFurnace.username),
            attending: widget.circleObject!.id == null
                ? Attending.Yes
                : Attending.Maybe));

    if (!widget.circleObject!.event!.respondents
        .contains(_circleEventRespondent))
      widget.circleObject!.event!.respondents.add(_circleEventRespondent);
  }

  _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      if (widget.circleObject!.id == null) {
        if (widget.wall) {
          if (_selectedNetworks.isEmpty) {
            if (widget.userFurnaces.length == 1) {
              _setNetworksAndPost(widget.userFurnaces);
            } else {
              List<UserFurnace>? selectedNetworks =
                  await DialogSelectNetworks.selectNetworks(
                      context: context,
                      networks: widget.userFurnaces,
                      callback: _setNetworksAndPost,
                      existingNetworksFilter: _selectedNetworks);

              if (selectedNetworks == null) {
                setState(() {
                  _showSpinner = false;
                });
              }
            }
          } else {
            ///this is a wall post with only one connected network
            _saveCircleObject();
          }
        } else {
          ///this is a new wall add
          _saveCircleObject();
        }
      } else {
        ///this is an edit
        _saveCircleObject();
      }
    }
  }

  _saveCircleObject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });
      _circleEvent.title = _titleController.text;
      _circleEvent.description = _descriptionController.text;
      _circleEvent.location = _locationController.text;

      if (widget.circleObject!.id == null) {
        if (widget.wall) {
          Navigator.pop(context, _circleEvent);
        } else {
          _circleEventBloc.createEvent(
              widget.circleObjectBloc,
              _userCircleCache,
              _circleEvent,
              _userFurnace,
              _globalEventBloc,
              widget.replyObject,
              widget.increment,
              widget.scheduledFor);
        }
      } else {
        _circleEventBloc.updateEvent(widget.circleObjectBloc, _userCircleCache,
            widget.circleObject!, _userFurnace);
      }
    }
  }

  _selectEndTime() async {
    if (screenMode == Mode.create || screenMode == Mode.edit) {
      TimeOfDay? time = await Pickers.pickTime(
          context,
          TimeOfDay(
              hour: _circleEvent.endDate.hour,
              minute: _circleEvent.endDate.minute));

      if (time != null) {
        setState(() {
          _circleEvent.endDate = DateTime(
              _circleEvent.endDate.year,
              _circleEvent.endDate.month,
              _circleEvent.endDate.day,
              time.hour,
              time.minute);
        });
      }
    }
  }

  _selectStartTime() async {
    if (screenMode == Mode.create || screenMode == Mode.edit) {
      TimeOfDay? time = await Pickers.pickTime(
          context,
          TimeOfDay(
              hour: _circleEvent.startDate.hour,
              minute: _circleEvent.startDate.minute));

      if (time != null) {
        Duration duration =
            _circleEvent.endDate.difference(_circleEvent.startDate);

        setState(() {
          _circleEvent.startDate = DateTime(
              _circleEvent.startDate.year,
              _circleEvent.startDate.month,
              _circleEvent.startDate.day,
              time.hour,
              time.minute);

          //bump the end time out
          _circleEvent.endDate = _circleEvent.startDate.add(duration);
        });
      }
    }
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;

      _saveCircleObject();
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;
      setState(() {});
    }
  }
}
