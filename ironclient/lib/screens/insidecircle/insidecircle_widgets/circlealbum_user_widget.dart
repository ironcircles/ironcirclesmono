import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CircleAlbumUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  final Color? replyMessageColor;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache userCircleCache;
  final bool showTime;
  final Circle? circle;
  final Function reactionChanged;
  final Function refresh;
  final Function unpinObject;
  final double maxWidth;

  const CircleAlbumUserWidget(
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.replyMessageColor,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.circle,
      this.reactionChanged,
      this.refresh,
      this.unpinObject,
      this.maxWidth);

  @override
  _CircleAlbumUserWidget createState() => _CircleAlbumUserWidget();
}

class _CircleAlbumUserWidget extends State<CircleAlbumUserWidget> {
  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  List<AlbumItem> _currentItems = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _currentItems = [];

    double gridSize = globalState.isDesktop() ? widget.maxWidth : 200;
    double gridItemSize = gridSize / 2;

    for (AlbumItem item in widget.circleObject.album!.media) {
      if (item.removeFromCache == false) {
        _currentItems.add(item);
      }
    }
    if (_currentItems.isNotEmpty) {
      _currentItems.sort((a, b) => a.index.compareTo(b.index));
    }

    final showGrid = Padding(
        padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
        child: widget.circleObject.fullTransferState == BlobState.ENCRYPTING ||
                widget.circleObject.fullTransferState == BlobState.DECRYPTING
            ? Column(children: [
                Padding(
                    padding: const EdgeInsets.only(right: 25),
                    child: Text(
                      widget.circleObject.fullTransferState ==
                              BlobState.ENCRYPTING
                          ? 'Encrypting'
                          : 'Decrypting',
                      style: TextStyle(color: globalState.theme.labelText),
                    )),
                spinkit,
              ])
            : Stack(alignment: Alignment.center, children: [
                Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: SizedBox(
                        height: gridSize,
                        //widget.circleObject.album!.media.length > 2 ? 200 : 100,
                        width: gridSize,
                        child: _currentItems.isNotEmpty
                            ? GridView.builder(
                                itemCount: 4,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2),
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == 3) {
                                    return SizedBox(
                                        width: gridItemSize,
                                        height: gridItemSize,
                                        child: ClipRect(
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    color: globalState.theme
                                                        .userObjectBackground,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            bottomRight:
                                                                Radius.circular(
                                                                    10.0))),
                                                child: Center(
                                                    child: Icon(
                                                  Icons.photo_library,
                                                  size: 30,
                                                  color: globalState
                                                      .theme.buttonIcon,
                                                )))));
                                  } else {
                                    if (index >= _currentItems.length) {
                                      return SizedBox(
                                          width: gridItemSize, //100,
                                          height: gridItemSize, //100,
                                          child: ClipRRect(
                                              borderRadius: index == 1
                                                  ? const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(10.0))
                                                  : const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(
                                                              10.0)),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    color: globalState
                                                        .theme.objectDisabled,
                                                  ),
                                                  child: Center(
                                                      child: Icon(
                                                    Icons.add_box_outlined,
                                                    size: 30,
                                                    color: globalState
                                                        .theme.buttonIcon,
                                                  )))));
                                    } else {
                                      AlbumItem item = _currentItems[index];

                                      try {
                                        return SizedBox(
                                            width: gridItemSize,
                                            height: gridItemSize,
                                            child: ClipRRect(
                                                borderRadius: index == 0
                                                    ? const BorderRadius.only(
                                                        topLeft: Radius.circular(
                                                            10.0))
                                                    : index == 1
                                                        ? const BorderRadius
                                                            .only(
                                                            topRight:
                                                                Radius.circular(
                                                                    10.0))
                                                        : const BorderRadius
                                                            .only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    10.0)),
                                                child: item.type ==
                                                        AlbumItemType.IMAGE
                                                    ? (ImageCacheService
                                                            .isAlbumThumbnailCached(
                                                        widget.circleObject,
                                                        item,
                                                        widget.userCircleCache
                                                            .circlePath!,
                                                      ))
                                                        ? Image.file(
                                                            File(ImageCacheService.returnExistingAlbumImagePath(
                                                                widget
                                                                    .userCircleCache
                                                                    .circlePath!,
                                                                widget
                                                                    .circleObject,
                                                                item.image!
                                                                    .thumbnail!)),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : spinkit
                                                    : (VideoCacheService
                                                            .isAlbumPreviewCached(
                                                                widget
                                                                    .circleObject,
                                                                widget
                                                                    .userCircleCache
                                                                    .circlePath!,
                                                                item))
                                                        ? Image.file(
                                                            File(VideoCacheService.returnExistingAlbumVideoPath(
                                                                widget
                                                                    .userCircleCache
                                                                    .circlePath!,
                                                                widget
                                                                    .circleObject,
                                                                item.video!
                                                                    .preview!)),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : spinkit));
                                      } catch (err, trace) {
                                        LogBloc.insertError(err, trace);
                                        return Expanded(child: spinkit);
                                      }
                                    }
                                  }
                                })
                            : Container()

                        //  File(FileSystemServicewidget

                        // ),            //.circleObject.gif.giphy),
                        )),
                widget.circleObject.fullTransferState == BlobState.UPLOADING &&
                        widget.circleObject.transferPercent != null &&
                            widget.circleObject.transferPercent! >= 0 &&
                            widget.circleObject.transferPercent! < 100
                    ? Center(
                        child: CircularPercentIndicator(
                        radius: 30.0,
                        lineWidth: 5.0,
                        percent: (widget.circleObject.transferPercent == null
                            ? 0.01
                            : widget.circleObject.transferPercent! / 100),
                        center: Text(
                            widget.circleObject.transferPercent == null
                                ? '0%'
                                : '${widget.circleObject.transferPercent}%',
                            textScaler: const TextScaler.linear(1.0),
                            style:
                                TextStyle(color: globalState.theme.progress)),
                        progressColor: globalState.theme.progress,
                      ))
                    : Container(),
              ]));

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      widget.circleObject, widget.showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                      widget.circleObject)),
              child: Column(children: <Widget>[
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
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                    ),
                                    widget.showTime ||
                                            widget.circleObject.showOptionIcons
                                        ? Text(
                                            widget.circleObject.showOptionIcons
                                                ? ('${widget.circleObject.date!}  ${widget.circleObject.time!}')
                                                : widget.circleObject.time!,
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
                                        : Container(),
                                  ]),
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topRight,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: widget.maxWidth),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.only(right: 0),
                                        child: Column(children: <Widget>[
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                widget.circleObject.body != null
                                                    ? (widget.circleObject.body!
                                                            .isNotEmpty
                                                        ? ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth: widget
                                                                        .maxWidth),
                                                            child: Container(
                                                              padding: const EdgeInsets
                                                                  .all(
                                                                  InsideConstants
                                                                      .MESSAGEPADDING),
                                                              decoration: BoxDecoration(
                                                                  color: globalState
                                                                      .theme
                                                                      .userObjectBackground,
                                                                  borderRadius: const BorderRadius
                                                                      .only(
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              10.0),
                                                                      bottomRight:
                                                                          Radius.circular(
                                                                              10.0),
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              10.0),
                                                                      topRight:
                                                                          Radius.circular(
                                                                              10.0))),
                                                              child:
                                                                  CircleObjectBody(
                                                                replyObject: widget
                                                                    .replyObject,
                                                                replyObjectTapHandler:
                                                                    widget
                                                                        .replyObjectTapHandler,
                                                                replyMessageColor:
                                                                    widget
                                                                        .replyMessageColor,
                                                                userCircleCache:
                                                                    widget
                                                                        .userCircleCache,
                                                                circleObject: widget
                                                                    .circleObject,
                                                                messageColor:
                                                                    globalState
                                                                        .theme
                                                                        .userObjectText,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                maxWidth: widget
                                                                    .maxWidth,
                                                              ),
                                                            ),
                                                          )
                                                        : Container())
                                                    : Container(),
                                              ]),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                widget.circleObject.seed != null
                                                    //? Container()
                                                    ? showGrid
                                                    : ConstrainedBox(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 230),
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            child: Center(
                                                                child:
                                                                    spinkit)),
                                                      )
                                              ]),
                                        ]),
                                      ),
                                    )),
                                widget.circleObject.id == null ||
                                        widget.circleObject.editing == true
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: widget.circleObject.unstable
                                            ? Container(
                                                padding: const EdgeInsets.all(
                                                    InsideConstants
                                                        .MESSAGEPADDING),
                                                //color: globalState.theme.dropdownBackground,
                                                decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    // .circleObjectBackground,
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                5.0),
                                                        bottomRight:
                                                            Radius.circular(
                                                                5.0),
                                                        topLeft: Radius.circular(
                                                            5.0),
                                                        topRight:
                                                            Radius.circular(
                                                                5.0))),
                                                child: const Text(
                                                    "unstable connection",
                                                    textScaler:
                                                        TextScaler.linear(1.0),
                                                    style: TextStyle(
                                                        color: Colors.white)))
                                            : CircleAvatar(
                                                radius: 7.0,
                                                backgroundColor: globalState
                                                    .theme.sentIndicator,
                                              ))
                                    : Container()
                              ]),
                              CircleObjectDraft(
                                circleObject: widget.circleObject,
                                showTopPadding: false,
                              ),

                              ///TO DO
                              // widget.circleObject.image != null
                              //     ? widget.circleObject.retries >= 5
                              //     ? Row(
                              //     mainAxisAlignment:
                              //     MainAxisAlignment.end,
                              //     mainAxisSize: MainAxisSize.max,
                              //     children: [
                              //       Container(
                              //           decoration: BoxDecoration(
                              //               color: Colors.red
                              //                   .withOpacity(.2),
                              //               borderRadius:
                              //               const BorderRadius
                              //                   .only(
                              //                 bottomLeft:
                              //                 Radius.circular(
                              //                     10.0),
                              //                 bottomRight:
                              //                 Radius.circular(
                              //                     10.0),
                              //                 topLeft:
                              //                 Radius.circular(
                              //                     10.0),
                              //                 topRight:
                              //                 Radius.circular(
                              //                     10.0),
                              //               )),
                              //           child: Padding(
                              //               padding:
                              //               const EdgeInsets.all(
                              //                   1),
                              //               child: TextButton(
                              //                   onPressed: () {
                              //                     widget.retry(widget
                              //                         .circleObject);
                              //                   },
                              //                   child: const Text(
                              //                     'send failed, retry?',
                              //                     style: TextStyle(
                              //                         color:
                              //                         Colors.red),
                              //                   ))))
                              //     ])
                              //     : Container()
                              //     : Container()
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
                // widget.circleObject.showOptionIcons
                //     ? const Padding(
                //   padding: EdgeInsets.only(bottom: 30),
                // )
                //     : Container(),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: false),
        ]));
  }
}
