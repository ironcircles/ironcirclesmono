import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlevote_radio_closed.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleVoteUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool interactive;
  final bool showAvatar;
  final bool? showDate;
  final bool? showTime;
  final Function? submitVote;
  //final User user;
  final String? user;
  int? _radioValue = -1;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  //int groupValue3;

  CircleVoteUserWidget(
      {required this.circleObject,
      required this.userFurnace,
      required this.interactive,
      required this.showAvatar,
      this.showDate,
      this.showTime,
      this.submitVote,
      this.user,
      required this.unpinObject,
      required this.refresh,
      required this.maxWidth});

  @override
  CircleVoteUserWidgetState createState() => CircleVoteUserWidgetState();
}

class CircleVoteUserWidgetState extends State<CircleVoteUserWidget> {
  final double _rightPadding = 0;
  //int? _radioValue = -1;

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

    /*if (_radioValue == -1)*/
    if (CircleVote.didUserVote(widget.circleObject.vote!, widget.user))
      widget._radioValue = CircleVote.getUserVotedForIndex(
          widget.circleObject.vote!, widget.user);

    //_setUserVote();

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      widget.circleObject, widget.showDate!),
                  bottom: SharedFunctions.calculateBottomPadding(
                    widget.circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(
                  showDate: widget.showDate!,
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
                                child: widget.showTime! ||
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
                                                fontSize:
                                                    globalState.dateFontSize,
                                              ),
                                            )
                                          ])
                                    : Container(),
                              ),
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topRight,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: widget.maxWidth),
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                            color: globalState
                                                .theme.userObjectBackground,
                                            borderRadius:
                                                const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(10.0),
                                                    bottomRight:
                                                        Radius.circular(10.0),
                                                    topLeft:
                                                        Radius.circular(10.0),
                                                    topRight:
                                                        Radius.circular(10.0))),
                                        child: refresh == true
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                    Text(
                                                        widget
                                                            .circleObject.vote!
                                                            .getTitle(context),
                                                        textScaler: TextScaler
                                                            .linear(globalState
                                                                .messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                            color: globalState
                                                                .theme
                                                                .listTitle,
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
                                                        widget
                                                            .circleObject.vote!
                                                            .getTitle(context),
                                                        textScaler: TextScaler
                                                            .linear(globalState
                                                                .messageHeaderScaleFactor),
                                                        style: TextStyle(
                                                            color: globalState
                                                                .theme
                                                                .listTitle,
                                                            fontSize: globalState
                                                                .titleSize)),
                                                    Text(
                                                      widget.circleObject.vote!
                                                          .getQuestion(context),
                                                      textScaler: TextScaler
                                                          .linear(globalState
                                                              .messageHeaderScaleFactor),
                                                      style: TextStyle(
                                                          color: globalState
                                                              .theme
                                                              .userObjectText,
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
                                                                  .getDescription(
                                                                      context),
                                                              textScaler:
                                                                  TextScaler.linear(
                                                                      globalState
                                                                          .messageScaleFactor),
                                                              style: TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .objectTitle,
                                                                  fontSize: globalState
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

                                                        return widget
                                                                    .circleObject
                                                                    .vote!
                                                                    .open! &&
                                                                !CircleVote.didUserVote(
                                                                    widget
                                                                        .circleObject
                                                                        .vote!,
                                                                    widget
                                                                        .user) &&
                                                                widget
                                                                    .interactive
                                                            ? Padding(
                                                                padding: EdgeInsets.only(
                                                                    left: 20.0,
                                                                    top: 10.0,
                                                                    bottom: 0.0,
                                                                    right:
                                                                        _rightPadding),
                                                                //child: Wrap(spacing: 0, runSpacing: 0.0,  crossAxisAlignment: WrapCrossAlignment.center,
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  //mainAxisAlignment:
                                                                  //   MainAxisAlignment.start,
                                                                  children: <Widget>[
                                                                    SizedBox(
                                                                        height:
                                                                            23,
                                                                        width:
                                                                            23,
                                                                        child:
                                                                            Radio(
                                                                          fillColor:
                                                                              MaterialStateProperty.all(
                                                                            globalState.theme.labelText,
                                                                          ),
                                                                          activeColor: globalState
                                                                              .theme
                                                                              .buttonIcon,
                                                                          value:
                                                                              index,
                                                                          groupValue:
                                                                              widget._radioValue,
                                                                          onChanged:
                                                                              _handleRadioValueChange,
                                                                        )),
                                                                    const Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left:
                                                                              0.0,
                                                                          top:
                                                                              0.0,
                                                                          bottom:
                                                                              0.0,
                                                                          right:
                                                                              10),
                                                                    ),
                                                                    Expanded(
                                                                        child: InkWell(
                                                                            onTap: () {
                                                                              _handleRadioValueChange(index);
                                                                            },
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                                                                              child: ICText(_buildRowText(row), textScaleFactor: globalState.messageScaleFactor, fontSize: 14, color: globalState.theme.labelText),
                                                                            ))),
                                                                  ],
                                                                ),
                                                              )
                                                            : Padding(
                                                                padding: EdgeInsets.only(
                                                                    left: 20.0,
                                                                    top: 10.0,
                                                                    bottom: 0.0,
                                                                    right:
                                                                        _rightPadding),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  // mainAxisAlignment:
                                                                  //   MainAxisAlignment.end,
                                                                  children: <Widget>[
                                                                    CircleVoteRadioClosed(
                                                                        widget
                                                                            .circleObject
                                                                            .vote,
                                                                        row,
                                                                        index,
                                                                        widget
                                                                            ._radioValue),
                                                                    Expanded(
                                                                      child: ICText(
                                                                          _buildRowText(
                                                                              row),
                                                                          textScaleFactor: globalState
                                                                              .messageScaleFactor,
                                                                          fontSize:
                                                                              14,
                                                                          color: globalState
                                                                              .theme
                                                                              .buttonDisabled),
                                                                    )
                                                                  ],
                                                                ),
                                                              );
                                                      },
                                                    ),
                                                    CircleVote.didUserVote(
                                                                widget
                                                                    .circleObject
                                                                    .vote!,
                                                                widget.user) &&
                                                            widget.circleObject
                                                                .vote!.open! &&
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
                                                                const Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              10),
                                                                ),
                                                                ICText(
                                                                    AppLocalizations.of(
                                                                            context)!
                                                                        .tapToChangeVote
                                                                        .toLowerCase(),
                                                                    textScaleFactor:
                                                                        globalState
                                                                            .messageHeaderScaleFactor,
                                                                    color: globalState
                                                                        .theme
                                                                        .listExpand),
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
                                                                widget
                                                                    .interactive
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
                                                                    ICText(
                                                                        'touch to see full list',
                                                                        textScaleFactor:
                                                                            globalState
                                                                                .messageHeaderScaleFactor,
                                                                        color: globalState
                                                                            .theme
                                                                            .listExpand),
                                                                    const Padding(
                                                                      padding: EdgeInsets.only(
                                                                          bottom:
                                                                              10),
                                                                    ),
                                                                  ])
                                                            : Container(),
                                                    widget.interactive
                                                        ? widget
                                                                    .circleObject
                                                                    .vote!
                                                                    .open! &&
                                                                !CircleVote.didUserVote(
                                                                    widget
                                                                        .circleObject
                                                                        .vote!,
                                                                    widget
                                                                        .user) &&
                                                                widget
                                                                        .circleObject
                                                                        .vote!
                                                                        .options!
                                                                        .length <
                                                                    5
                                                            ? Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .end,
                                                                  children: <Widget>[
                                                                    GradientButton(
                                                                      width: 80,
                                                                      height:
                                                                          40,
                                                                      text:
                                                                      AppLocalizations.of(context)!.vote.toLowerCase(),
                                                                      onPressed:
                                                                          () {
                                                                        if (widget._radioValue! >
                                                                            -1) {
                                                                          widget.submitVote!(
                                                                              widget.circleObject,
                                                                              widget.circleObject.vote!.options![widget._radioValue!]);
                                                                        }
                                                                      },
                                                                    )
                                                                  ],
                                                                ))
                                                            : Container()
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

  String _buildRowText(CircleVoteOption row) {
    String retValue = row.option!;

    if (widget.circleObject.vote!.type != null) {
      retValue = row.getOption(context, widget.circleObject.vote!.type!);
    }

    if (row.usersVotedFor != null)
      retValue += " (${row.usersVotedFor!.length})";
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
}
