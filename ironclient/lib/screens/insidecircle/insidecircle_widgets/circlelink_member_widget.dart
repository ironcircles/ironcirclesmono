import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/link_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlelink_widget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/utils_export.dart';

class CircleLinkMemberWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final UserCircleCache userCircleCache;
  final Function? replyObjectTapHandler;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color messageColor;
  final Color? replyMessageColor;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final bool interactive;
  final double maxWidth;

  const CircleLinkMemberWidget(
      this.circleObject,
      this.replyObject,
      this.userCircleCache,
      this.replyObjectTapHandler,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.replyMessageColor,
      this.userFurnace,
      this.circle,
      this.unpinObject,
      this.refresh,
      this.interactive,
      this.maxWidth);

  CircleLinkMemberWidgetState createState() => CircleLinkMemberWidgetState();
}

class CircleLinkMemberWidgetState extends State<CircleLinkMemberWidget> {
  final LinkBloc _linkBloc = LinkBloc();

  @override
  void initState() {
    //Listen for the first CircleObject load
    _linkBloc.fetchLinkResults.listen((linkPreview) {
      if (mounted) {
        setState(() {});

        widget.circleObject.link = linkPreview;
      }
    }, onError: (err) {
      debugPrint("CircleImageUserWidget.initState: $err");
      //_fetchingImage =false;
    }, cancelOnError: false);

    ///This was removed. If the poster of a link didn't unfurl it correctly, the member won't see the results.
    ///Uncommenting will send too many users to LinkPreview.com, maybe for no reason if the title and description are really blank
    ///if (widget.circleObject.link!.title!.isEmpty && widget.circleObject.link!.description!.isEmpty)
    ///_linkBloc.fetchLink(widget.circleObject, widget.userFurnace);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    //if (widget.circleObject.link!.title!.isEmpty) _urlHeight += 2;

    //if (widget.circleObject.link!.description!.isEmpty) _urlHeight += 2;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DateWidget(
                        showDate: widget.showDate,
                        circleObject: widget.circleObject),
                    PinnedObject(
                      circleObject: widget.circleObject,
                      unpinObject: widget.unpinObject,
                      isUser: false,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AvatarWidget(
                            refresh: widget.refresh,
                            userFurnace: widget.userFurnace,
                            user: widget.circleObject.creator,
                            showAvatar: widget.showAvatar,
                            isUser: false),
                        Expanded(
                            child: Container(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      CircleObjectMember(
                                        creator: widget.circleObject.creator!,
                                        circleObject: widget.circleObject,
                                        userFurnace: widget.userFurnace,
                                        messageColor: widget.messageColor,
                                        interactive: true,
                                        showTime: widget.showTime,
                                        refresh: widget.refresh,
                                        maxWidth: widget.maxWidth,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(0),
                                        decoration: BoxDecoration(
                                            color: globalState
                                                .theme.memberObjectBackground,
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
                                        child: InkWell(
                                          onTap: widget.circleObject.reply !=
                                                  widget.circleObject.link!.url
                                              ? widget.interactive
                                                  ? () => LaunchURLs
                                                      .launchURLForCircleObject(
                                                          context,
                                                          widget.circleObject)
                                                  : null
                                              : () {
                                                  widget.replyObjectTapHandler!(
                                                      widget.circleObject);
                                                },
                                          // onLongPress: () => _showIconOptions(context),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: widget.maxWidth - 5),
                                            //maxWidth: 250,
                                            //height: 20,
                                            //child: *
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  widget.circleObject.body!
                                                          .isNotEmpty
                                                      ? Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                              ConstrainedBox(
                                                                  constraints: BoxConstraints(
                                                                      maxWidth:
                                                                          widget
                                                                              .maxWidth-5),
                                                                  //maxWidth: 250,
                                                                  //height: 20,
                                                                  child:
                                                                      Container(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        bottom:
                                                                            10,
                                                                        right:
                                                                            5,
                                                                        top: 5,
                                                                        left:
                                                                            5),
                                                                    //color: globalState.theme.dropdownBackground,
                                                                    child:
                                                                        CircleObjectBody(
                                                                      circleObject:
                                                                          widget
                                                                              .circleObject,
                                                                      replyObject:
                                                                          widget
                                                                              .replyObject,
                                                                      replyObjectTapHandler:
                                                                          widget
                                                                              .replyObjectTapHandler,
                                                                      userCircleCache:
                                                                          widget
                                                                              .userCircleCache,
                                                                      messageColor:
                                                                          widget
                                                                              .messageColor,
                                                                      replyMessageColor:
                                                                          widget
                                                                              .replyMessageColor,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      maxWidth:
                                                                          widget
                                                                              .maxWidth,
                                                                    ),
                                                                  ))
                                                            ])
                                                      : Container(),
                                                  CircleLinkWidget(
                                                    circleObject:
                                                        widget.circleObject,
                                                    maxWidth: widget.maxWidth,
                                                  )
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ]))),
                      ],
                    ),
                  ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: true),
        ]));
  }
}
