import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class TaskEdit extends StatefulWidget {
  final CircleListTask? circleListTask;
  final List<String?>? members;
  final List<User?> membersList;
  final Function? remove;
  final int? index;
  final Function? changeComplete;
  final bool isNew;
  final Function? add;
  final Function onChanged;
  final bool checkable;
  final bool templateMode;
  final void Function(String)? onFieldSubmitted;

  const TaskEdit({
    Key? key,
    this.members,
    required this.membersList,
    required this.isNew,
    this.circleListTask,
    this.checkable = true,
    this.remove,
    this.add,
    required this.onChanged,
    this.index,
    required this.changeComplete,
    this.templateMode = false,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  CircleListState createState() => CircleListState();
}

class CircleListState extends State<TaskEdit> {
  final bool _expand = false;
  bool enableCheckbox = false;

  //bool _saveList = false;

  //ScrollController _scrollController = ScrollController();
  //final _scaffoldKey = GlobalKey<ScaffoldState>();
  //final _formKey = GlobalKey<FormState>();
  // CircleListBloc _circleListBloc = CircleListBloc();

  final double _iconSize = 45;

  @override
  void initState() {
    super.initState();

    if (widget.circleListTask!.controller!.text.isNotEmpty)
      enableCheckbox = true;
  }

  _showTask() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                  radius: 18,
                  backgroundColor: globalState.theme.listIconBackground,
                  child: Text(
                    (widget.circleListTask!.order).toString(),
                    style: TextStyle(
                        fontSize: 13,
                        color: globalState.theme.listIconForeground),
                  )),
              //child: Text('1')),
              const Padding(padding: EdgeInsets.only(right: 4)),
              Expanded(
                flex: 1,
                child: ExpandingLineText(
                  counterText: '',
                  maxLength: TextLength.Smaller,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  focusNode: widget.circleListTask!.focusNode,
                  /*validator: (value) {
                if (value.toString().isEmpty) {
                  return 'name of task is required';
                }
                return null;
              },

               */
                  onChanged: (text) {
                    widget.circleListTask!.name = text;

                    if (text != null) if (text.toString().isNotEmpty)
                      setState(() {
                        enableCheckbox = true;
                      });
                    else
                      setState(() {
                        enableCheckbox = false;
                      });

                    widget.onChanged(widget.circleListTask!.order, text);
                  },
                  controller: widget.circleListTask!.controller,
                  maxLines: 6,
                  textColor: globalState.theme.listLineText,
                  fontSize: 14,
                  underline: globalState.theme.listLineText,
                ),
              ),
              ClipOval(
                child: Material(
                  color: widget.isNew
                      ? globalState.theme.background
                      : globalState.theme.tabBackground, // button color
                  child: InkWell(
                    splashColor:
                        globalState.theme.buttonLineBackground, // inkwell color
                    child: SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: Icon(Icons.remove_circle,
                            color: globalState.theme.recipeIconAltBackground)),
                    onTap: () {
                      setState(() {
                        widget.remove!(widget.index);
                      });
                    },
                  ),
                ),
              ),
              widget.checkable && !widget.templateMode
                  ? ClipOval(
                      child: Material(
                        color: widget.isNew
                            ? globalState.theme.background
                            : globalState.theme.tabBackground, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonLineBackground, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child:
                                  (widget.circleListTask!.expanded || _expand)
                                      ? Icon(Icons.expand_less,
                                          color: globalState
                                              .theme.recipeIconAltBackground)
                                      : Icon(Icons.expand_more,
                                          color: globalState
                                              .theme.recipeIconAltBackground)),
                          onTap: () {
                            setState(() {
                              widget.circleListTask!.expanded =
                                  !widget.circleListTask!.expanded;
                            });
                          },
                        ),
                      ),
                    )
                  : Container(),

              widget.checkable
                  ? widget.isNew
                      ? Container()
                      : Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: InkWell(
                              onTap: () {
                                setState(() {
                                  widget.circleListTask!.complete =
                                      !widget.circleListTask!.complete!;
                                });
                              },
                              child: SizedBox(
                                  height: 25.0,
                                  width: 35,
                                  child: Checkbox(
                                      activeColor: globalState.theme.buttonIcon,
                                      checkColor:
                                          globalState.theme.checkBoxCheck,
                                      side: BorderSide(
                                          color:
                                              globalState.theme.buttonDisabled,
                                          width: 2.0),
                                      value: widget.circleListTask!.complete,
                                      onChanged: enableCheckbox
                                          ? (newValue) {
                                              //setState(() {
                                              widget.circleListTask!.complete =
                                                  newValue;
                                              widget.changeComplete!(
                                                  widget.circleListTask,
                                                  newValue);
                                              // });
                                            }
                                          : null))))
                  : Container(),
              //const Padding(padding: EdgeInsets.only(right: 2)),
              globalState.isDesktop()
                  ? Padding(padding: EdgeInsets.only(right: _iconSize))
                  : const Padding(padding: EdgeInsets.only(right: 2)),
            ]),
        _expand || widget.circleListTask!.expanded
            ? Column(children: [
                const Padding(padding: EdgeInsets.only(top: 5)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 39),
                      ),
                      widget.members == null
                          ? Container()
                          : Expanded(
                              flex: 1,
                              child: FormattedDropdown(
                                fontSize: 14,
                                hintText: AppLocalizations.of(context)!
                                    .assignTo
                                    .toLowerCase(),
                                list: widget.members ?? [''],
                                selected:
                                    widget.circleListTask!.assignee == null
                                        ? ''
                                        : widget.circleListTask!.assignee!
                                            .getUsernameAndAlias(globalState),
                                underline: globalState.theme.buttonIcon,
                                onChanged: (String? value) {
                                  setState(() {
                                    User? user;

                                    if (value != null && value.isNotEmpty)
                                      user = widget.membersList.firstWhere(
                                          (element) =>
                                              element!.getUsernameAndAlias(
                                                  globalState) ==
                                              value);

                                    widget.circleListTask!.assignee = user;
                                  });
                                },
                              )),

                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 15),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 2, right: 0),
                          child: blankDate(widget.circleListTask!.due)
                              ? Container()
                              : Text(
                                  //'',
                                  DateFormat('MM-dd-yy @ hh:mm a')
                                      .format(widget.circleListTask!.due!),
                                  textScaler: TextScaler.linear(
                                      globalState.labelScaleFactor),
                                  //  DateFormat.yMMMEdjm().format(_due[index]),
                                  style: TextStyle(
                                      color: globalState.theme.buttonIcon),
                                )),
                      const Spacer(),
                      ClipOval(
                          child: Material(
                        color: globalState.theme.tabBackground, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonLineBackground, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: Icon(Icons.calendar_today,
                                  color: globalState
                                      .theme.recipeIconAltBackground)),
                          onTap: () {
                            setState(() {
                              //remove(index);
                              _getDateTime(widget.circleListTask!.due);
                            });
                          },
                        ),
                      )),
                    ]),

              ])
            : Container(),
      ]),
    );
  }

  _showCompleteTask() {
    return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                    radius: 18,
                    backgroundColor: globalState.theme.listIconBackground,
                    child: Text(
                      widget.circleListTask!.order.toString(),
                      style: TextStyle(
                          fontSize: 13,
                          color: globalState.theme.listIconForeground),
                    )),
                //child: Text('1')),
                const Padding(padding: EdgeInsets.only(right: 14)),
                Expanded(
                    flex: 1,
                    child: Text(
                        widget.circleListTask!.name == null
                            ? ''
                            : widget.circleListTask!.name!,
                        textScaler:
                            TextScaler.linear(globalState.messageScaleFactor),
                        style: TextStyle(
                            fontSize: 14,
                            color: globalState.theme.buttonDisabled))),

                ClipOval(
                  child: Material(
                    color: globalState.theme.tabBackground, // button color
                    child: InkWell(
                      splashColor: globalState
                          .theme.buttonLineBackground, // inkwell color
                      child: SizedBox(
                          width: _iconSize,
                          height: _iconSize,
                          child: Icon(Icons.remove_circle,
                              color:
                                  globalState.theme.recipeIconAltBackground)),
                      onTap: () {
                        setState(() {
                          widget.remove!(widget.index);
                        });
                      },
                    ),
                  ),
                ),
                ClipOval(
                  child: Material(
                    color: globalState.theme.tabBackground, // button color
                    child: SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: Icon(Icons.remove_circle,
                            color: globalState.theme.tabBackground)),
                  ),
                ),
                widget.checkable
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            widget.circleListTask!.complete =
                                !widget.circleListTask!.complete!;
                          });
                        },
                        child: SizedBox(
                            height: 25.0,
                            width: 35,
                            child: Checkbox(
                              side: BorderSide(
                                  color: globalState.theme.buttonDisabled),
                              //hoverColor: globalState.theme.buttonDisabled,
                              activeColor: globalState.theme.buttonIcon,
                              checkColor: globalState.theme.checkBoxCheck,
                              value: widget.circleListTask!.complete,
                              onChanged: (newValue) {
                                setState(() {
                                  //widget.circleListTask.complete = newValue;
                                  widget.changeComplete!(
                                      widget.circleListTask, newValue);

                                  //save to server
                                });
                              },
                            )))
                    : Container(),
                globalState.isDesktop()
                    ? Padding(padding: EdgeInsets.only(right: _iconSize))
                    : const Padding(padding: EdgeInsets.only(right: 2)),
              ]),
          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  Text(
                    widget.circleListTask!.completedBy != null
                        ? widget.circleListTask!.completedBy!
                            .getUsernameAndAlias(globalState)
                        : '',
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.buttonDisabled, fontSize: 13),
                  ),
                  globalState.isDesktop()
                      ? Padding(padding: EdgeInsets.only(right: _iconSize))
                      : const Padding(padding: EdgeInsets.only(right: 2)),
                ]),
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  blankDate(widget.circleListTask!.completed)
                      ? Container()
                      : Text(
                          //'',
                          DateFormat('MM-dd-yy @ hh:mm a')
                              .format(widget.circleListTask!.completed!),
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),

                          //  DateFormat.yMMMEdjm().format(_due[index]),
                          style: TextStyle(
                              color: globalState.theme.buttonDisabled),
                        ),
                  globalState.isDesktop()
                      ? Padding(padding: EdgeInsets.only(right: _iconSize))
                      : const Padding(padding: EdgeInsets.only(right: 2)),
                ])
          ]),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.circleListTask!.complete!)
      return _showCompleteTask();
    else
      return _showTask();
  }

  _getDateTime(DateTime? due) async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: blankDate(due) ? DateTime.now() : due!,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.dark(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  )
                : Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.light(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  ));
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
          initialTime: TimeOfDay.now(),
          context: context,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: globalState.theme.themeMode == ICThemeMode.dark
                    ? Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: globalState.theme.button,
                          //accentColor:  globalState.theme.button,
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
                          //accentColor:  globalState.theme.button,
                          colorScheme: ColorScheme.light(
                              primary: globalState.theme.button),
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      ));
          });

      if (time != null) {
        setState(() {
          widget.circleListTask!.due =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  bool blankDate(DateTime? due) {
    if (due == null) return true;

    return (due.difference(DateTime(1)).inSeconds == 0);
  }
}
