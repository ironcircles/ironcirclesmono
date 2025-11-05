import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class CircleAlbumMemberWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  final Color? replyMessageColor;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache userCircleCache;
  final bool showTime;
  final Color messageColor;
  final Circle? circle;
  final Function reactionChanged;
  final Function refresh;
  final Function unpinObject;
  final double maxWidth;

  const CircleAlbumMemberWidget(
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.replyMessageColor,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.circle,
      this.unpinObject,
      this.reactionChanged,
      this.refresh,
      this.maxWidth);

  @override
  _CircleAlbumMemberWidget createState() => _CircleAlbumMemberWidget();
}

class _CircleAlbumMemberWidget extends State<CircleAlbumMemberWidget> {
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
            : Padding(
                padding: const EdgeInsets.only(left: 0),
                child: SizedBox(
                    height:
                        widget.circleObject.album!.media.length > 2 ? gridSize : gridItemSize,
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
                                    child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                            bottomRight: Radius.circular(10.0)),
                                        child: Container(
                                            color: globalState
                                                .theme.memberObjectBackground,
                                            child: Center(
                                                child: Icon(
                                              Icons.photo_library,
                                              size: 30,
                                              color:
                                                  globalState.theme.buttonIcon,
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
                                              Radius.circular(
                                                  10.0))
                                              : const BorderRadius.only(
                                              bottomLeft:
                                              Radius.circular(
                                                  10.0)),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                color: globalState.theme.objectDisabled,
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
                                                  topLeft:
                                                      Radius.circular(10.0))
                                              : index == 1
                                                  ? const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(10.0))
                                                  : const BorderRadius.only(
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
                                                              .circlePath!))
                                                  ? Image.file(
                                                      File(ImageCacheService
                                                          .returnExistingAlbumImagePath(
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
                                                          widget.circleObject,
                                                          widget.userCircleCache
                                                              .circlePath!,
                                                          item))
                                                  ? Image.file(
                                                      File(VideoCacheService
                                                          .returnExistingAlbumVideoPath(
                                                              widget
                                                                  .userCircleCache
                                                                  .circlePath!,
                                                              widget
                                                                  .circleObject,
                                                              item.video!
                                                                  .preview!)),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : spinkit,
                                        ));
                                  } catch (err, trace) {
                                    LogBloc.insertError(err, trace);
                                    return Expanded(child: spinkit);
                                  }
                                }
                              }
                            })
                        : Container()

                    //  File(FileSystemServicewidget
                    //.circleObject.gif.giphy),
                    // ),
                    )));

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomLeft, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      widget.circleObject, widget.showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                      widget.circleObject)),
              child: Column(children: <Widget>[
                DateWidget(
                  showDate: widget.showDate,
                  circleObject: widget.circleObject,
                ),
                PinnedObject(
                  circleObject: widget.circleObject,
                  unpinObject: widget.unpinObject,
                  isUser: false,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarWidget(
                          refresh: widget.refresh,
                          userFurnace: widget.userFurnace,
                          user: widget.circleObject.creator,
                          showAvatar: widget.showAvatar,
                          isUser: true),
                      Expanded(
                          child: Container(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                          maxWidth:
                                              InsideConstants.MESSAGEBOXSIZE),
                                      child: Container(
                                        padding: const EdgeInsets.all(0),
                                        child: Column(children: <Widget>[
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                widget.circleObject.body != null
                                                    ? (widget.circleObject.body!
                                                            .isNotEmpty
                                                        ? ConstrainedBox(
                                                            constraints:
                                                                const BoxConstraints(
                                                                    maxWidth:
                                                                        InsideConstants
                                                                            .MESSAGEBOXSIZE),
                                                            child: Container(
                                                              padding: const EdgeInsets
                                                                  .all(
                                                                  InsideConstants
                                                                      .MESSAGEPADDING),
                                                              decoration: BoxDecoration(
                                                                  color: globalState
                                                                      .theme
                                                                      .memberObjectBackground,
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
                                                                circleObject: widget
                                                                    .circleObject,
                                                                replyObject: widget
                                                                    .replyObject,
                                                                replyObjectTapHandler:
                                                                    widget
                                                                        .replyObjectTapHandler,
                                                                userCircleCache:
                                                                    widget
                                                                        .userCircleCache,
                                                                messageColor: widget
                                                                    .messageColor,
                                                                replyMessageColor:
                                                                    widget
                                                                        .replyMessageColor,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
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
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                widget.circleObject.seed != null
                                                    ? showGrid
                                                    : ConstrainedBox(
                                                        constraints:
                                                            BoxConstraints(
                                                                maxWidth: widget
                                                                    .maxWidth),
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            child: Center(
                                                                child:
                                                                    spinkit)),
                                                      )
                                              ]),

                                          ///PUT RETRY WIDGET HERE FROM CIRCLE IMAGE MEMBER WIDGET?
                                          // widget.circleObject.image != null
                                          //     ? widget.circleObject.retries >= 5
                                          //     ? Row(
                                          //     mainAxisAlignment:
                                          //     MainAxisAlignment.start,
                                          //     //mainAxisSize: MainAxisSize.max,
                                          //     children: [
                                          //       Container(
                                          //           decoration:
                                          //           BoxDecoration(
                                          //               color: Colors
                                          //                   .red
                                          //                   .withOpacity(
                                          //                   .2),
                                          //               borderRadius:
                                          //               const BorderRadius
                                          //                   .only(
                                          //                 bottomLeft:
                                          //                 Radius.circular(
                                          //                     10.0),
                                          //                 bottomRight:
                                          //                 Radius.circular(
                                          //                     10.0),
                                          //                 topLeft: Radius
                                          //                     .circular(
                                          //                     10.0),
                                          //                 topRight:
                                          //                 Radius.circular(
                                          //                     10.0),
                                          //               )),
                                          //           child: Padding(
                                          //               padding:
                                          //               const EdgeInsets
                                          //                   .all(1),
                                          //               child:
                                          //               TextButton(
                                          //                   onPressed:
                                          //                       () {
                                          //                     widget
                                          //                         .retry(widget.circleObject);
                                          //                   },
                                          //                   child:
                                          //                   const Text(
                                          //                     'download failed, retry?',
                                          //                     style:
                                          //                     TextStyle(color: Colors.red),
                                          //                   ))))
                                          //     ])
                                          //     : Container()
                                          //     : Container()
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
                            ]),
                      )),
                    ]),
                widget.circleObject.showOptionIcons
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                      )
                    : Container(),
              ])),
          widget.circleObject.timer == null
              ? Container()
              : Positioned(
                  bottom: widget.circleObject.showOptionIcons ? 30 : 0,
                  left: 0,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 26,
                                child: Text(
                                  UserDisappearingTimerStrings
                                      .getUserTimerString(
                                          widget.circleObject.timer!),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: globalState.theme.buttonIcon),
                                )),
                            Icon(Icons.timer,
                                size: 15, color: globalState.theme.buttonIcon),
                          ]))),
        ]));
  }
}
