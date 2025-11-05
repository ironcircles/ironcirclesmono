import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class WallRecipeWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final UserCircleCache userCircleCache;
  final Color messageColor;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const WallRecipeWidget(
      this.circleObject,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.userCircleCache,
      this.messageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  _WallRecipeWidgetState createState() => _WallRecipeWidgetState();
}

class _WallRecipeWidgetState extends State<WallRecipeWidget> {
  //int _radioValue = -1;
  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 150),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  final spinkitNoPadding = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );
  @override
  Widget build(BuildContext context) {
    //_setUserVote();

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    CircleObjectMember(
                                      creator: widget.circleObject.creator!,
                                      circleObject: widget.circleObject,
                                      userFurnace: widget.userFurnace,
                                      messageColor: widget.messageColor,
                                      interactive: true,
                                      isWall: true,
                                      showTime: true, // widget.showTime,
                                      refresh: widget.refresh,
                                      maxWidth: widget.maxWidth,
                                    ),
                                  ])))
                    ]),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topLeft,
                                    child:widget.circleObject.draft
                                        ? Container()
                                        : ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: widget.maxWidth),
                                      //maxWidth: 250,
                                      //height: 20,
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        //color: globalState.theme.dropdownBackground,
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
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      'Recipe',
                                                      textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                                      style: TextStyle(
                                                        color: globalState
                                                            .theme.listTitle,
                                                        fontSize: globalState
                                                            .titleSize,
                                                      ),
                                                    ),
                                                  ]),
                                              widget.circleObject.body == null
                                                  ? Container()
                                                  : //Row(mainAxisAlignment: MainAxisAlignment.end ,children: <Widget>[
                                                  Text(
                                                      widget.circleObject.body!,
                                                      textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                      style: TextStyle(
                                                          color: globalState
                                                              .theme.button,
                                                          fontSize: 15)),
                                              widget.circleObject.recipe == null
                                                  ? Container()
                                                  : widget.circleObject.recipe!
                                                              .image !=
                                                          null
                                                      ? widget.circleObject
                                                                      .fullTransferState ==
                                                                  BlobState
                                                                      .ENCRYPTING ||
                                                              widget
                                                                      .circleObject
                                                                      .fullTransferState ==
                                                                  BlobState
                                                                      .DECRYPTING
                                                          ? Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                  Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          right:
                                                                              25),
                                                                      child:
                                                                          Text(
                                                                        widget.circleObject.fullTransferState ==
                                                                                BlobState.ENCRYPTING
                                                                            ? 'Encrypting'
                                                                            : 'Decrypting',
                                                                        style: TextStyle(
                                                                            color:
                                                                                globalState.theme.labelText),
                                                                      )),
                                                                  spinkit,
                                                                ])
                                                          : (ImageCacheService.isRecipeImageCached(
                                                                  widget
                                                                      .circleObject
                                                                      .recipe!
                                                                      .image!
                                                                      .thumbnailSize,
                                                                  widget
                                                                      .userCircleCache
                                                                      .circlePath!,
                                                                  widget
                                                                      .circleObject
                                                                      .seed!)
                                                              ? Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                      Image
                                                                          .file(
                                                                        File(ImageCacheService.returnThumbnailPath(
                                                                            widget.userCircleCache.circlePath!,
                                                                            widget.circleObject)),
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      ),
                                                                      widget.circleObject.fullTransferState == BlobState.DOWNLOADING ||
                                                                              widget.circleObject.fullTransferState == BlobState.UPLOADING
                                                                          ? Padding(
                                                                              padding: const EdgeInsets.only(right: 0),
                                                                              child: CircularPercentIndicator(
                                                                                radius: 30.0,
                                                                                lineWidth: 5.0,
                                                                                percent: (widget.circleObject.transferPercent == null ? 0.01 : widget.circleObject.transferPercent! / 100),
                                                                                center: Text(widget.circleObject.transferPercent == null ? '0%' : '${widget.circleObject.transferPercent}%', textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                                progressColor: globalState.theme.progress,
                                                                              ))
                                                                          : Container(),
                                                                    ])
                                                              : ConstrainedBox(
                                                                  constraints:
                                                                      BoxConstraints(
                                                                          maxWidth:
                                                                              widget.maxWidth),
                                                                  child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              5.0),
                                                                      child: Center(
                                                                          child:
                                                                              spinkitNoPadding)
                                                                      //  File(FileSystemServicewidget
                                                                      //.circleObject.gif.giphy),
                                                                      // ),
                                                                      ),
                                                                ))
                                                      : Container(),
                                              widget.circleObject.recipe == null
                                                  ? Container()
                                                  : //Row(mainAxisAlignment: MainAxisAlignment.end ,children: <Widget>[
                                                  widget.circleObject.recipe!
                                                          .notes!.isEmpty
                                                      ? Container()
                                                      : Text(
                                                          widget
                                                                      .circleObject
                                                                      .recipe!
                                                                      .notes!
                                                                      .length <
                                                                  292
                                                              ? widget
                                                                  .circleObject
                                                                  .recipe!
                                                                  .notes!
                                                              : '${widget.circleObject.recipe!.notes!.substring(0, 291)}...',
                                                          textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                          style:
                                                              TextStyle(
                                                                  color: globalState
                                                                      .theme
                                                                      .listLoadMore,
                                                                  fontSize:
                                                                      12)),
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
                              CircleObjectDraft(
                                circleObject: widget.circleObject,
                                showTopPadding: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: true),
        ]));
  }

  // return retValue;
}
