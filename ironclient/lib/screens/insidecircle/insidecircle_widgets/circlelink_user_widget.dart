import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlelink_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/utils_export.dart';

class CircleLinkUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final UserCircleCache userCircleCache;
  final Function? replyObjectTapHandler;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  //final Function openExternalBrowser;

  const CircleLinkUserWidget(
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.userCircleCache,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.userFurnace,
      this.circle,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  CircleLinkUserWidgetState createState() => CircleLinkUserWidgetState();
}

class CircleLinkUserWidgetState extends State<CircleLinkUserWidget> {
  //int _urlHeight = 2;
  late CircleObject _circleObject; // = widget.circleObject;
  //LinkBloc _linkBloc = LinkBloc();

  @override
  void initState() {
    _circleObject = widget.circleObject;

    //debugPrint('urlA: ${widget.circleObject.link.url}');
    //debugPrint('urlB: ${_circleObject.link.url}');

    /* if (widget.circleObject.link != null) {
      if (widget.circleObject.link!.title!.isEmpty) _urlHeight += 2;

      if (widget.circleObject.link!.description!.isEmpty) _urlHeight += 2;
    }

    */

    /*
    //Listen for the first CircleObject load
    _linkBloc.fetchLinkResults.listen((linkPreview) {
      if (mounted) {
        setState(() {});

        _circleObject.link = linkPreview;
      }
    }, onError: (err) {
      debugPrint("CircleImageUserWidget.initState: $err");
      //_fetchingImage =false;
    }, cancelOnError: false);
    */

    //_linkBloc.fetchLink(_circleObject, widget.userFurnace);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    DateWidget(
                        showDate: widget.showDate,
                        circleObject: widget.circleObject),
                    PinnedObject(
                      circleObject: widget.circleObject,
                      unpinObject: widget.unpinObject,
                      isUser: true,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      widget.showTime ||
                                              widget
                                                  .circleObject.showOptionIcons
                                          ? Text(
                                              widget.circleObject
                                                      .showOptionIcons
                                                  ? ('${widget.circleObject.date!}  ${widget.circleObject.time!}')
                                                  : widget.circleObject.time!,
                                        textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                              style: TextStyle(
                                                color: globalState.theme.time,
                                                fontWeight: FontWeight.w600,
                                                fontSize: globalState
                                                    .userSetting.fontSize,
                                              ),
                                            )
                                          : Container(),
                                    ]),
                                Container(
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                        color: globalState
                                            .theme.userObjectBackground,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(10.0),
                                            bottomRight: Radius.circular(10.0),
                                            topLeft: Radius.circular(10.0),
                                            topRight: Radius.circular(10.0))),
                                    child: InkWell(
                                      onTap: widget.circleObject.reply !=
                                              widget.circleObject.link!.url
                                          ? () => LaunchURLs
                                              .launchURLForCircleObject(
                                                  context, widget.circleObject)
                                          : () {
                                              widget.replyObjectTapHandler!(
                                                  widget.circleObject);
                                            },
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Stack(
                                                alignment: Alignment.topRight,
                                                children: <Widget>[
                                                  widget.circleObject.body ==
                                                          null
                                                      ? Container()
                                                      : widget.circleObject
                                                                  .body ==
                                                              ''
                                                          ? Container()
                                                          : Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: <
                                                                  Widget>[
                                                                  ConstrainedBox(
                                                                      constraints:
                                                                          BoxConstraints(
                                                                              maxWidth: widget.maxWidth),
                                                                      //maxWidth: 250,
                                                                      //height: 20,
                                                                      child: Container(
                                                                          padding: const EdgeInsets.only(bottom: 10, right: 5, top: 5, left: 5),
                                                                          child: CircleObjectBody(
                                                                            circleObject:
                                                                                widget.circleObject,
                                                                            replyObject:
                                                                                widget.replyObject,
                                                                            replyObjectTapHandler:
                                                                                widget.replyObjectTapHandler,
                                                                            userCircleCache:
                                                                                widget.userCircleCache,
                                                                            messageColor:
                                                                                globalState.theme.userObjectText,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.end,
                                                                            maxWidth:
                                                                                widget.maxWidth,
                                                                          ))),
                                                                ]),
                                                  widget.circleObject.id == null
                                                      ? Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: CircleAvatar(
                                                            radius: 7.0,
                                                            backgroundColor:
                                                                globalState
                                                                    .theme
                                                                    .sentIndicator,
                                                          ))
                                                      : Container()
                                                ]),
                                            CircleLinkWidget(
                                              circleObject:
                                              widget.circleObject,
                                              maxWidth: widget.maxWidth,
                                            )
                                          ]),
                                    )),
                              ],
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
}
