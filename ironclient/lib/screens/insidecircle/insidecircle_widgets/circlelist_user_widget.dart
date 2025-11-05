import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleListUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool interactive;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Function updateList;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleListUserWidget(
      this.circleObject,
      this.userFurnace,
      this.interactive,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.updateList,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  CircleListUserWidgetState createState() => CircleListUserWidgetState();
}

class CircleListUserWidgetState extends State<CircleListUserWidget> {
  List<CircleListTask>? _circleListTasks;
  bool isDirty = false;
  CircleList? _circleList;

  @override
  void initState() {
    super.initState();
  }

  bool _checkIsDirty() {
    bool isDirty = false;

    for (CircleListTask original in widget.circleObject.list!.tasks!) {
      for (CircleListTask clone in _circleList!.tasks!) {
        if (clone.id == original.id) {
          if (clone.complete != original.complete) {
            return true;
          }
        }
      }
    }

    return isDirty;
  }

  final spinkit = Padding(
      padding: const EdgeInsets.only(right: 0),
      child:
          SpinKitThreeBounce(size: 20, color: globalState.theme.threeBounce));

  bool refresh = false;

  @override
  Widget build(BuildContext context) {
    _checkRefresh();

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      widget.circleObject, widget.showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                    widget.circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(
                  showDate: widget.showDate,
                  circleObject: widget.circleObject,
                  editableObject: true,
                ),
                PinnedObject(
                  circleObject: widget.circleObject,
                  unpinObject: widget.unpinObject,
                  isUser: true,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                child: widget.showTime ||
                                        widget.circleObject.showOptionIcons
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 5.0),
                                            ),
                                            Text(
                                              widget.circleObject
                                                      .showOptionIcons
                                                  ? ('${widget.circleObject.lastUpdatedDate!}  ${widget.circleObject.lastUpdatedTime!}')
                                                  : widget.circleObject
                                                      .lastUpdatedTime!,
                                              textScaler: TextScaler.linear(
                                                  globalState
                                                      .messageHeaderScaleFactor),
                                              style: TextStyle(
                                                color: globalState.theme.time,
                                                fontWeight: FontWeight.w600,
                                                fontSize: globalState
                                                    .userSetting.fontSize,
                                              ),
                                            )
                                          ])
                                    : Container(),
                              ),
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topRight,
                                    child: widget.circleObject.draft
                                        ? Container()
                                        : ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: widget.maxWidth),
                                            //maxWidth: 250,
                                            //height: 20,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              //color: globalState.theme.dropdownBackground,
                                              decoration: BoxDecoration(
                                                  color: globalState.theme
                                                      .userObjectBackground,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10.0),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  10.0),
                                                          topLeft:
                                                              Radius.circular(
                                                                  10.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  10.0))),
                                              child: refresh == true
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                          Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <Widget>[
                                                                Text(
                                                                    AppLocalizations.of(
                                                                            context)!
                                                                        .list,
                                                                    textScaler:
                                                                        TextScaler.linear(
                                                                            globalState
                                                                                .messageScaleFactor),
                                                                    style: TextStyle(
                                                                        color: globalState
                                                                            .theme
                                                                            .listTitle,
                                                                        fontSize:
                                                                            globalState.titleSize))
                                                              ]),
                                                        Center(child: spinkit)
                                                        ])
                                                  : Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                          Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <Widget>[
                                                                Text(
                                                                  AppLocalizations.of(
                                                                          context)!
                                                                      .list,
                                                                  textScaler: TextScaler.linear(
                                                                      globalState
                                                                          .messageHeaderScaleFactor),
                                                                  style:
                                                                      TextStyle(
                                                                    color: globalState
                                                                        .theme
                                                                        .listTitle,
                                                                    fontSize:
                                                                        globalState
                                                                            .titleSize,
                                                                  ),
                                                                ),
                                                              ]),
                                                          widget
                                                                  .circleObject
                                                                  .list!
                                                                  .complete
                                                              ? Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: <Widget>[
                                                                      Text(
                                                                        AppLocalizations.of(context)!
                                                                            .complete,
                                                                        textScaler:
                                                                            TextScaler.linear(globalState.messageScaleFactor),
                                                                        style: TextStyle(
                                                                            color:
                                                                                globalState.theme.listTitle,
                                                                            fontSize: 18),
                                                                      ),
                                                                      Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              left: 10),
                                                                          child: ClipOval(
                                                                              child: Material(
                                                                            color:
                                                                                globalState.theme.buttonIcon, // button color
                                                                            child: SizedBox(
                                                                                width: 25,
                                                                                height: 25,
                                                                                child: Icon(
                                                                                  Icons.check,
                                                                                  color: globalState.theme.checkBoxCheck,
                                                                                )),
                                                                          )))
                                                                    ])
                                                              : Container(),
                                                          widget.circleObject
                                                                      .list ==
                                                                  null
                                                              ? Container()
                                                              : //Row(mainAxisAlignment: MainAxisAlignment.end ,children: <Widget>[
                                                              ICText(
                                                                  widget.circleObject.list!.name ==
                                                                          null
                                                                      ? ''
                                                                      : widget
                                                                          .circleObject
                                                                          .list!
                                                                          .name!,
                                                                  textScaleFactor:
                                                                      globalState
                                                                          .messageScaleFactor,
                                                                  color: globalState
                                                                      .theme
                                                                      .userObjectText,
                                                                  fontSize: globalState
                                                                      .userSetting
                                                                      .fontSize),
                                                          widget.circleObject.list!
                                                                          .complete ==
                                                                      false &&
                                                                  widget
                                                                          .circleObject
                                                                          .list!
                                                                          .lastEdited !=
                                                                      null
                                                              ? Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                      ICText(
                                                                          '${AppLocalizations.of(context)!.lastEditedBy} ',
                                                                          textScaleFactor: globalState
                                                                              .messageHeaderScaleFactor,
                                                                          color: globalState
                                                                              .theme
                                                                              .listTitle),
                                                                      ICText(
                                                                          widget
                                                                              .circleObject
                                                                              .list!
                                                                              .lastEdited!
                                                                              .getUsernameAndAlias(
                                                                                  globalState),
                                                                          textScaleFactor: globalState
                                                                              .messageHeaderScaleFactor,
                                                                          color: widget.circleObject.list!.lastEdited!.id == widget.userFurnace.userid
                                                                              ? globalState.theme.userObjectText
                                                                              : Member.getMemberColor(widget.userFurnace, widget.circleObject.list!.lastEdited!)),
                                                                    ])
                                                              : Container(),
                                                          widget
                                                                  .circleObject
                                                                  .list!
                                                                  .complete
                                                              ? Container()
                                                              : SingleChildScrollView(
                                                                  keyboardDismissBehavior:
                                                                      ScrollViewKeyboardDismissBehavior
                                                                          .onDrag,
                                                                  child: ListView
                                                                      .builder(
                                                                    scrollDirection:
                                                                        Axis.vertical,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    //controller: _scrollController,
                                                                    shrinkWrap:
                                                                        true,
                                                                    itemCount:
                                                                        _circleListTasks!
                                                                            .length,
                                                                    itemBuilder:
                                                                        (BuildContext
                                                                                context,
                                                                            int index) {
                                                                      CircleListTask
                                                                          task =
                                                                          _circleListTasks![
                                                                              index];
                                                                      return index >
                                                                              4
                                                                          ? index == (_circleListTasks!.length - 1)
                                                                              ? Center(
                                                                                  child: ICText(
                                                                                  AppLocalizations.of(context)!.tapToSeeFullList,
                                                                                  color: globalState.theme.listExpand,
                                                                                ))
                                                                              : Container()
                                                                          : Container(
                                                                              padding: const EdgeInsets.only(top: 10, left: 0, right: 10),
                                                                              /*color: Colors.red,*/

                                                                              child: Column(
                                                                                  //mainAxisSize: MainAxisSize.min,
                                                                                  children: <Widget>[
                                                                                    Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                                                                                      CircleAvatar(
                                                                                        radius: 15,
                                                                                        backgroundColor: globalState.theme.listIconBackground,
                                                                                        child: Text(task.order.toString(), style: TextStyle(fontSize: 12, color: globalState.theme.listIconForeground)),
                                                                                      ),
                                                                                      const Padding(
                                                                                        padding: EdgeInsets.only(
                                                                                          left: 5,
                                                                                        ),
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: ICText(task.name == null ? '' : task.name!, textScaleFactor: globalState.messageScaleFactor, fontSize: 14, color: globalState.theme.userObjectText),
                                                                                      ),
                                                                                      const Padding(
                                                                                          padding: EdgeInsets.only(
                                                                                        right: 5,
                                                                                      )),
                                                                                      _circleList!.checkable && widget.interactive
                                                                                          ? InkWell(
                                                                                              onTap: () {
                                                                                                setState(() {
                                                                                                  task.complete = !task.complete!;
                                                                                                });
                                                                                              },
                                                                                              child: SizedBox(
                                                                                                  height: 35.0,
                                                                                                  width: 45,
                                                                                                  child: Checkbox(
                                                                                                      side: BorderSide(color: globalState.theme.buttonDisabled, width: 2.0),
                                                                                                      activeColor: globalState.theme.buttonIcon,
                                                                                                      checkColor: globalState.theme.checkBoxCheck,
                                                                                                      value: task.complete,
                                                                                                      onChanged: (newValue) {
                                                                                                        setState(() {
                                                                                                          task.complete = newValue;
                                                                                                          isDirty = _checkIsDirty();
                                                                                                        });
                                                                                                      })))
                                                                                          : Container(),
                                                                                    ]),
                                                                                  ]));
                                                                    },
                                                                  ),
                                                                ),
                                                          _circleList!.complete
                                                              ? Container()
                                                              : isDirty
                                                                  ? Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              10),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: <Widget>[
                                                                          GradientButton(
                                                                            width:
                                                                                95,
                                                                            height:
                                                                                40,
                                                                            text:
                                                                            AppLocalizations.of(context)!.update.toLowerCase(),
                                                                            onPressed:
                                                                                () {
                                                                              widget.updateList(widget.circleObject, _circleList);
                                                                              isDirty = false;
                                                                            },
                                                                          )
                                                                        ],
                                                                      ))
                                                                  : Container()
                                                        ]),
                                            ),
                                          )),
                                CircleObjectDraft(
                                  circleObject: widget.circleObject,
                                  showTopPadding: true,
                                ),
                                widget.circleObject.id == null
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: CircleAvatar(
                                          radius: 7.0,
                                          backgroundColor:
                                              globalState.theme.sentIndicator,
                                        ))
                                    : Container(),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      AvatarWidget(
                          refresh: widget.refresh,
                          userFurnace: widget.userFurnace,
                          user: widget.circleObject.creator,
                          showAvatar: widget.showAvatar,
                          isUser: true),
                    ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: false),
        ]));
  }

  _checkRefresh() {
    if (_circleList == null) {
      refresh = true;
    } else if (_circleList!.lastUpdate != widget.circleObject.list!.lastUpdate) {
      refresh = true;
    }
    if (refresh == true) {
      _refreshList();
    }
  }

  _refreshList() {
    _circleList = CircleList.deepCopy(widget.circleObject.list!);
    _circleList!.sortList();
    _circleListTasks = _circleList!.tasks;
    _circleListTasks!.retainWhere((element) => element.complete == false);
    setState(() {
      refresh = false;
    });
  }

/*
  _updateTask(CircleListTask task, bool newValue) {
    setState(() {
      task.complete = newValue;

      _circleListBloc.updateList(widget.userCircleCache, widget.circleObject,
          _circleList, false, widget.userFurnace);
    });
  }
  */
}
