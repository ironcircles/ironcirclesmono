import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevote_radio_closed.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class WallVoteWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool interactive;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  //final int groupValue;
  final String? user;
  final Color messageColor;
  final Function unpinObject;
  final Function submitVote;
  final Function leave;
  int? _radioValue = -1;
  final Function refresh;
  final double maxWidth;

  WallVoteWidget(
      this.circleObject,
      this.userFurnace,
      this.interactive,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.submitVote,
      this.user,
      this.leave,
      this.messageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<WallVoteWidget> {
  //int _radioValue = -1;

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  bool refresh = false;
  DateTime? _lastUpdate;

  @override
  Widget build(BuildContext context) {
    if (_lastUpdate == null) {
      setState(() {
        refresh = true;
      });
    } else {
      if (_lastUpdate != widget.circleObject.lastUpdate) {
        setState(() {
          refresh = true;
        });
      }
    }
    if (refresh) {
      _refreshVote();
    }

    if (CircleVote.didUserVote(widget.circleObject.vote!, widget.user))
      widget._radioValue = CircleVote.getUserVotedForIndex(
          widget.circleObject.vote!, widget.user);
    //else _radioValue = -1;

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
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Column(
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
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                                Text(
                                                    widget.circleObject.vote!.getTitle(context),
                                                    textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                    style: TextStyle(
                                                        color: globalState
                                                            .theme.listTitle,
                                                        fontSize: globalState
                                                            .titleSize)),
                                                Center(child: spinkit),
                                              ])
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                                Text(
                                                    widget.circleObject.vote!.getTitle(context),
                                                    textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                    style: TextStyle(
                                                        color: globalState
                                                            .theme.listTitle,
                                                        fontSize: globalState
                                                            .titleSize)),
                                                Text(
                                                  widget.circleObject.vote!
                                                      .question!,
                                                  textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                  style: TextStyle(
                                                      color:
                                                          widget.messageColor,
                                                      fontSize: globalState
                                                          .userSetting
                                                          .fontSize),
                                                ),
                                                widget.circleObject.vote!
                                                            .description !=
                                                        null
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 15,
                                                                bottom: 10),
                                                        child: Center(
                                                            child: Text(
                                                          widget
                                                              .circleObject
                                                              .vote!
                                                              .description!,
                                                          textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                          style: TextStyle(
                                                              color: globalState
                                                                  .theme
                                                                  .objectTitle,
                                                              fontSize:
                                                                  globalState
                                                                      .userSetting
                                                                      .fontSize,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic),
                                                        )))
                                                    : Container(),
                                                ListView.builder(
                                                  //scrollDirection: Axis.vertical,
                                                  //controller: _scrollController,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  itemCount: widget
                                                              .circleObject
                                                              .vote!
                                                              .options!
                                                              .length >
                                                          4
                                                      ? 4
                                                      : widget
                                                          .circleObject
                                                          .vote!
                                                          .options!
                                                          .length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    CircleVoteOption row =
                                                        widget
                                                            .circleObject
                                                            .vote!
                                                            .options![index];

                                                    return widget.circleObject
                                                                .vote!.open! &&
                                                            !CircleVote.didUserVote(
                                                                widget
                                                                    .circleObject
                                                                    .vote!,
                                                                widget.user) &&
                                                            CircleVote.canUserVote(
                                                                widget
                                                                    .circleObject
                                                                    .vote!,
                                                                widget.user) &&
                                                            widget.interactive
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 20.0,
                                                                    top: 12.0,
                                                                    bottom: 0.0,
                                                                    right: 0),
                                                            //child: Wrap(spacing: 0, runSpacing: 0.0,  crossAxisAlignment: WrapCrossAlignment.center,
                                                            child: Row(
                                                              //mainAxisAlignment:
                                                              //   MainAxisAlignment.start,
                                                              children: <
                                                                  Widget>[
                                                                SizedBox(
                                                                    height: 23,
                                                                    width: 23,
                                                                    child:
                                                                        Radio(
                                                                      activeColor: globalState
                                                                          .theme
                                                                          .listTitle,
                                                                      value:
                                                                          index,
                                                                      groupValue:
                                                                          widget
                                                                              ._radioValue,
                                                                      onChanged:
                                                                          _handleRadioValueChange,
                                                                    )),
                                                                const Padding(
                                                                  padding: EdgeInsets.only(
                                                                      left: 0.0,
                                                                      top: 0.0,
                                                                      bottom:
                                                                          0.0,
                                                                      right:
                                                                          10),
                                                                ),
                                                                Expanded(
                                                                    child: InkWell(
                                                                        onTap: () {
                                                                          _handleRadioValueChange(
                                                                              index);
                                                                        },
                                                                        child: Padding(
                                                                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                                                                            child: Text(
                                                                              _buildRowText(row),
                                                                              textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                              style: TextStyle(fontSize: 17, color: globalState.theme.objectTitle),
                                                                            )))),
                                                              ],
                                                            ),
                                                          )
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 20.0,
                                                                    top: 10.0,
                                                                    bottom: 0.0,
                                                                    right: 0),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              // mainAxisAlignment:
                                                              //   MainAxisAlignment.end,
                                                              children: <
                                                                  Widget>[
                                                                CircleVoteRadioClosed(
                                                                    widget
                                                                        .circleObject
                                                                        .vote,
                                                                    row,
                                                                    index,
                                                                    widget
                                                                        ._radioValue),
                                                                Expanded(
                                                                    child: Text(
                                                                  _buildRowText(
                                                                      row),
                                                                  textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          17,
                                                                      color: globalState
                                                                          .theme
                                                                          .listTitle),
                                                                )),
                                                              ],
                                                            ));
                                                  },
                                                ),
                                                CircleVote.didUserVote(
                                                            widget.circleObject
                                                                .vote!,
                                                            widget.user) &&
                                                        widget.circleObject
                                                            .vote!.open! &&
                                                        widget.interactive
                                                    ? Column(
                                                        //mainAxisAlignment:
                                                        // MainAxisAlignment.start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                            const Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          10),
                                                            ),
                                                            Text(
                                                              'tap to change vote',
                                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                              style: TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .listExpand),
                                                            ),
                                                            const Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          10),
                                                            ),
                                                          ])
                                                    : widget
                                                                    .circleObject
                                                                    .vote!
                                                                    .options!
                                                                    .length >
                                                                4 &&
                                                            widget.interactive
                                                        ? Column(
                                                            //mainAxisAlignment:
                                                            // MainAxisAlignment.start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: <Widget>[
                                                                Text(
                                                                  'touch to see full list',
                                                                  textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                                  style: TextStyle(
                                                                      color: globalState
                                                                          .theme
                                                                          .listExpand),
                                                                ),
                                                                const Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              10),
                                                                ),
                                                              ])
                                                        : Container(),
                                                widget.interactive
                                                    ? widget.circleObject.vote!
                                                                .open! &&
                                                            !CircleVote.didUserVote(
                                                                widget
                                                                    .circleObject
                                                                    .vote!,
                                                                widget.user) &&
                                                            widget
                                                                    .circleObject
                                                                    .vote!
                                                                    .options!
                                                                    .length <
                                                                5 &&
                                                            CircleVote.canUserVote(
                                                                widget
                                                                    .circleObject
                                                                    .vote!,
                                                                widget.user) &&
                                                            widget.interactive
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 0),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: <
                                                                  Widget>[
                                                                GradientButton(
                                                                  width: 80,
                                                                  height: 40,
                                                                  text: "vote",
                                                                  onPressed:
                                                                      () {
                                                                    if (widget
                                                                            ._radioValue! >
                                                                        -1) {
                                                                      widget.submitVote(
                                                                          widget
                                                                              .circleObject,
                                                                          widget
                                                                              .circleObject
                                                                              .vote!
                                                                              .options![widget._radioValue!]);
                                                                    }
                                                                  },
                                                                )
                                                              ],
                                                            ))
                                                        : Container()
                                                    : Container(),
                                                !CircleVote.canUserVote(
                                                            widget.circleObject
                                                                .vote!,
                                                            widget.user) &&
                                                        widget.circleObject.vote!
                                                                .type ==
                                                            CircleVoteType
                                                                .REMOVEMEMBER &&
                                                        widget.circleObject
                                                            .vote!.open! &&
                                                        widget.interactive
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 15),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: <Widget>[
                                                            Expanded(
                                                              child: Text(
                                                                "There is an active vote to remove you from this circle.  Would you like to leave instead?",
                                                                textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                                style: TextStyle(
                                                                    color: globalState
                                                                        .theme
                                                                        .urgentAction),
                                                              ),
                                                            ),
                                                          ],
                                                        ))
                                                    : Container(),
                                                !CircleVote.canUserVote(
                                                            widget.circleObject
                                                                .vote!,
                                                            widget.user) &&
                                                        widget.circleObject
                                                                .vote!.type ==
                                                            CircleVoteType
                                                                .REMOVEMEMBER &&
                                                        widget.circleObject
                                                            .vote!.open!
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: <Widget>[
                                                            GradientButton(
                                                              width: 80,
                                                              height: 40,
                                                              text: "leave",
                                                              onPressed: () {
                                                                widget.leave();
                                                              },
                                                            )
                                                          ],
                                                        ))
                                                    : Container(),
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
                                : Container()
                          ])
                        ],
                      ),
                    ),
                  ),
                ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: true),
        ]));
  }

  String _buildRowText(CircleVoteOption row) {
    String retValue = row.option!;
    if (row.usersVotedFor != null) {
      retValue += " (${row.usersVotedFor!.length})";
    }

    return retValue;
  }

  _handleRadioValueChange(int? value) {
    setState(() {
      widget._radioValue = value;
    });
  }

  _refreshVote() {
    _lastUpdate = widget.circleObject.lastUpdate;
    setState(() {
      refresh = false;
    });
  }

  /*_setUserVote() {
    //widget.circleObject.vote.userVoted = false;

    for (CircleVoteOption option in widget.circleObject.vote.options) {
      if (option.usersVotedFor.contains(widget.user)) {
        widget.circleObject.vote.userVoted = true;
      }
    }

    // return retValue;
  }*/
}
