import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/circleeventrespondent.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/avatarwidget.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class CircleEventAttendees extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;


  const CircleEventAttendees({
    Key? key,
    required this.circleObject,
    required this.userFurnace,

  }) : super(key: key);

  @override
  _CircleEventAttendees createState() => _CircleEventAttendees();
}

class _CircleEventAttendees extends State<CircleEventAttendees> {
  ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late CircleEvent _circleEvent;
  bool header = false;
  int counter = 1;

  @override
  void initState() {
    super.initState();

    _circleEvent = widget.circleObject.event!;

    _circleEvent.respondents
        .sort((a, b) => a.attending.index.compareTo(b.attending.index));
  }

  @override
  void dispose() {
    super.dispose();
  }

  _refresh(){

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {

    final _makeBody = SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
          // color: Colors.black,
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 20),
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _circleEvent.respondents.length,
            itemBuilder: (BuildContext context, int index) {
              var row = _circleEvent.respondents[index];
              int headerCount = 0;

              header = false;

              if (index == 0) {
                header = true;
                headerCount = _circleEvent.attendingYesCount;
              } else {
                var priorRow = _circleEvent.respondents[index - 1];

                if (row.attending != priorRow.attending) {
                  if (row.attending == Attending.Maybe)
                    headerCount = _circleEvent.attendingMaybeCount;
                  else
                    headerCount = _circleEvent.attendingNoCount;
                  header = true;
                  counter = 1;
                } else
                  counter++;
              }

              return Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header
                            ? Padding(
                                padding: const EdgeInsets.only(top: 15, bottom: 10),
                                child: Text(
                                  '${row.attending.name}: $headerCount', textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                  style: TextStyle(
                                      fontSize: globalState.userSetting.fontSize + 5,
                                      color: globalState.theme.buttonIcon),
                                ))
                            : const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                              ),
                        Row(children: [
                          const Padding(padding: EdgeInsets.only(left: 20)),
                          AvatarWidget(refresh: _refresh,
                            user: row.respondent,
                            userFurnace: widget.userFurnace,
                            radius: 45, isUser:row.respondent.id == widget.userFurnace.userid,
                          ),
                          const Padding(padding: EdgeInsets.only(right: 10)),
                          Expanded(child: Text(
                            '${row.respondent.getUsernameAndAlias(globalState)}: ${row.numOfGuests}', textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                            style: TextStyle(
                                fontSize: globalState.userSetting.fontSize,
                                color: globalState.theme.labelText),
                          ))
                        ])
                      ]));
            },
          )),
    );
    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.attendees,),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: _makeBody),
              ],
            )));
  }
}
