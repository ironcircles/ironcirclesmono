import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/link_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/utils/utils_export.dart';

class WallLinkWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final UserCircleCache userCircleCache;
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

  const WallLinkWidget(
      this.circleObject,
      this.replyObject,
      this.userCircleCache,
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

  @override
  _WallLinkWidgetState createState() => _WallLinkWidgetState();
}

class _WallLinkWidgetState extends State<WallLinkWidget> {
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                        ),
                                      ])))
                        ]),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            //padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                                color: globalState.theme.memberObjectBackground,
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0),
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0))),
                            child: InkWell(
                              onTap: widget.interactive
                                  ? () => LaunchURLs.launchURLForCircleObject(
                                      context, widget.circleObject)
                                  : null,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      widget.circleObject.body!.isNotEmpty
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                  ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                              maxWidth: widget
                                                                      .maxWidth -
                                                                  5),
                                                      //maxWidth: 250,
                                                      //height: 20,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 5,
                                                                top: 5),
                                                        //color: globalState.theme.dropdownBackground,
                                                        child: CircleObjectBody(
                                                          circleObject: widget
                                                              .circleObject,
                                                          replyObject: widget
                                                              .replyObject,
                                                          userCircleCache: widget
                                                              .userCircleCache,
                                                          messageColor: widget
                                                              .messageColor,
                                                          replyMessageColor: widget
                                                              .replyMessageColor,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          maxWidth:
                                                              widget.maxWidth,
                                                        ),
                                                      ))
                                                ])
                                          : Container(),
                                      widget.circleObject.link == null
                                          ? Text(
                                              'link not reachable',
                                              textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                            )
                                          : widget.circleObject.link!.image!
                                                  .isNotEmpty
                                              ? _networkImage(widget
                                                  .circleObject.link!.image)
                                              : Container(),
                                      Container(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Column(children: <Widget>[
                                                  ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          widget.maxWidth - 13,
                                                      //maxHeight: 120,
                                                    ),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 1),
                                                        child: widget
                                                                    .circleObject
                                                                    .link ==
                                                                null
                                                            ? Container()
                                                            : Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: <
                                                                    Widget>[
                                                                    widget
                                                                            .circleObject
                                                                            .link!
                                                                            .title!
                                                                            .isNotEmpty
                                                                        ? Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(bottom: 3),
                                                                            child: Text(
                                                                              widget.circleObject.link!.title!,
                                                                              textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                              maxLines: 3,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(fontSize: 14, color: globalState.theme.linkTitle),
                                                                            ))
                                                                        : Container(),
                                                                    widget.circleObject.link!.description!.isNotEmpty &&
                                                                            widget.replyObject ==
                                                                                null
                                                                        ? Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(bottom: 3),
                                                                            child: Text(
                                                                              widget.circleObject.link!.description!,
                                                                              textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                                              maxLines: 3,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(fontSize: 14, color: globalState.theme.linkDescription),
                                                                            ))
                                                                        : Container(),
                                                                    Text(
                                                                      widget
                                                                          .circleObject
                                                                          .link!
                                                                          .url!,
                                                                      textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                                      style: TextStyle(
                                                                          fontSize: widget.circleObject.link!.title == ""
                                                                              ? 14
                                                                              : 11,
                                                                          color: globalState
                                                                              .theme
                                                                              .url),
                                                                    ),
                                                                  ])), //<widget>  )//wr
                                                  )
                                                ])
                                              ]))
                                    ]),
                              ),
                            ),
                          )
                        ])
                  ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: true),
        ]));
  }

  _networkImage(image) {
    return SizedBox(
        width: widget.maxWidth,
        child: Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: widget.maxWidth - 10),
                child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: image, fit: BoxFit.scaleDown,
                          //placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Container(),
                        ))))));
  }
}
