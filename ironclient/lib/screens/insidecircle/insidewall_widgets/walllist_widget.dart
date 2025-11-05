import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class WallListWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool interactive;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color messageColor;
  final Function updateList;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const WallListWidget(
      this.circleObject,
      this.userFurnace,
      this.interactive,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.updateList,
      this.messageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<WallListWidget> {
  //CircleListBloc _circleListBloc = CircleListBloc();

  List<CircleListTask>? _circleListTasks;
  bool isDirty = false;
  CircleList? _circleList;

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
    if (_circleList == null) {
      setState(() {
        refresh = true;
      });
    } else {
      if (_circleList!.lastUpdate != widget.circleObject.list!.lastUpdate) {
        setState(() {
          refresh = true;
        });
      }
    }
    if (refresh) {
      _refreshList();
    }

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomLeft, children: <Widget>[
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
                    circleObject: widget.circleObject),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 0.0),
                      ),
                      AvatarWidget(
                          refresh: widget.refresh,
                          userFurnace: widget.userFurnace,
                          user: widget.circleObject.creator,
                          showAvatar: true,
                          isUser: false),
                      Expanded(
                          child: Container(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    CircleObjectMember(
                                      creator: widget.circleObject.creator!,
                                      circleObject: widget.circleObject,
                                      userFurnace: widget.userFurnace,
                                      messageColor: widget.messageColor,
                                      interactive: true,
                                      isWall: true,
                                      showTime: true,
                                      refresh: widget.refresh,
                                      maxWidth: widget.maxWidth,
                                    )
                                  ]))),
                    ]),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: <
                    Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Stack(children: <Widget>[
                            Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: widget.maxWidth),
                                  //maxWidth: 250,
                                  //height: 20,
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    //color: globalState.theme.dropdownBackground,
                                    decoration: BoxDecoration(
                                        color: globalState
                                            .theme.memberObjectBackground,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(10.0),
                                            bottomRight: Radius.circular(10.0),
                                            topLeft: Radius.circular(10.0),
                                            topRight: Radius.circular(10.0))),
                                    child: refresh == true
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        'List',
                                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                          color: globalState
                                                              .theme.listTitle,
                                                          fontSize: globalState
                                                              .titleSize,
                                                        ),
                                                      ),
                                                    ]),
                                                Center(child: spinkit)
                                              ])
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        'List',
                                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                          color: globalState
                                                              .theme.listTitle,
                                                          fontSize: globalState
                                                              .titleSize,
                                                        ),
                                                      ),
                                                    ]),
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      widget.circleObject.list!
                                                              .complete
                                                          ? Text(
                                                              'Complete',
                                                              textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                              style: TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .listTitle,
                                                                  fontSize: 18),
                                                            )
                                                          : Container(),
                                                      widget.circleObject.list!
                                                              .complete
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left: 10),
                                                              child: ClipOval(
                                                                  child:
                                                                      Material(
                                                                color: globalState
                                                                    .theme
                                                                    .buttonIcon, // button color
                                                                child: SizedBox(
                                                                    width: 25,
                                                                    height: 25,
                                                                    child: Icon(
                                                                      Icons
                                                                          .check,
                                                                      color: globalState
                                                                          .theme
                                                                          .checkBoxCheck,
                                                                    )),
                                                              )))
                                                          : Container()
                                                    ]),
                                                widget.circleObject.list == null
                                                    ? Container()
                                                    : //Row(mainAxisAlignment: MainAxisAlignment.end ,children: <Widget>[
                                                    Text(
                                                        widget.circleObject.list!.name ==
                                                                null
                                                            ? ''
                                                            : widget
                                                                .circleObject
                                                                .list!
                                                                .name!,
                                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                            color: globalState
                                                                .theme
                                                                .buttonIcon,
                                                            fontSize:
                                                                globalState
                                                                    .userSetting
                                                                    .fontSize)),
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
                                                            Text(
                                                              'edited by ',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .listTitle),
                                                            ),
                                                            Text(
                                                              widget
                                                                  .circleObject
                                                                  .list!
                                                                  .lastEdited!
                                                                  .getUsernameAndAlias(
                                                                      globalState),
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                  color: widget
                                                                              .circleObject
                                                                              .list!
                                                                              .lastEdited!
                                                                              .id ==
                                                                          widget
                                                                              .userFurnace
                                                                              .userid
                                                                      ? globalState
                                                                          .theme
                                                                          .userObjectText
                                                                      : Member.getMemberColor(
                                                                          widget
                                                                              .userFurnace,
                                                                          widget
                                                                              .circleObject
                                                                              .list!
                                                                              .lastEdited!)),
                                                            )
                                                          ])
                                                    : Container(),
                                                widget.circleObject.list!
                                                        .complete
                                                    ? Container()
                                                    : SingleChildScrollView(
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        child: ListView.builder(
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          physics:
                                                              const NeverScrollableScrollPhysics(),
                                                          //controller: _scrollController,
                                                          shrinkWrap: true,
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
                                                            return index > 4
                                                                ? index ==
                                                                        (_circleListTasks!.length -
                                                                            1)
                                                                    ? Center(
                                                                        child:
                                                                            Text(
                                                                        'tap to see full list',
                                                                        textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                        style: TextStyle(
                                                                            color:
                                                                                globalState.theme.listExpand),
                                                                      ))
                                                                    : Container()
                                                                : Container(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        top: 10,
                                                                        left: 0,
                                                                        right:
                                                                            10),
                                                                    /*color: Colors.red,*/

                                                                    child: Column(
                                                                        //mainAxisSize: MainAxisSize.min,
                                                                        children: <Widget>[
                                                                          Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: <Widget>[
                                                                                CircleAvatar(radius: 15, backgroundColor: globalState.theme.listIconBackground, child: Text(task.order.toString(), style: TextStyle(fontSize: 12, color: globalState.theme.listIconForeground))),
                                                                                const Padding(
                                                                                  padding: EdgeInsets.only(left: 5),
                                                                                ),
                                                                                Expanded(
                                                                                    child: Text(
                                                                                  task.name == null ? '' : task.name!,
                                                                                  textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                                  style: TextStyle(fontSize: 15, color: globalState.theme.buttonIcon),
                                                                                )),
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
                                                                                            width: 40,
                                                                                            child: Theme(
                                                                                                data: ThemeData(unselectedWidgetColor: globalState.theme.checkUnchecked),
                                                                                                child: Checkbox(
                                                                                                    activeColor: globalState.theme.buttonIcon,
                                                                                                    checkColor: globalState.theme.checkBoxCheck,
                                                                                                    value: task.complete,
                                                                                                    onChanged: (newValue) {
                                                                                                      setState(() {
                                                                                                        task.complete = newValue;
                                                                                                        isDirty = _checkIsDirty();
                                                                                                      });
                                                                                                    }))))
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
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 10),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: <
                                                                  Widget>[
                                                                GradientButton(
                                                                  width: 95,
                                                                  height: 40,
                                                                  text:
                                                                      "update",
                                                                  onPressed:
                                                                      () {
                                                                    widget.updateList(
                                                                        widget
                                                                            .circleObject,
                                                                        _circleList);

                                                                    isDirty =
                                                                        false;
                                                                  },
                                                                )
                                                              ],
                                                            ))
                                                        : Container()
                                              ]),
                                  ),
                                )),
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
                ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: true)
        ]));
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

  // return retValue;
}
