import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircleVideoUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  //final Circle circle;
  final bool showAvatar;
  final bool showDate;
  final bool interactive;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showTime;
  final Function download;
  final Function play;
  final Function retry;
  final Circle? circle;
  final Function predispose;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleVideoUserWidget(
    this.userCircleCache,
    this.replyObjectTapHandler,
    //this.circle,
    this.interactive,
    this.userFurnace,
    this.circleObject,
    this.replyObject,
    this.showAvatar,
    this.showDate,
    this.showTime,
    this.download,
    this.play,
    this.retry,
    this.circle,
    this.predispose,
    this.unpinObject,
    this.refresh,
    this.maxWidth,
  );

  @override
  CircleVideoUserWidgetState createState() => CircleVideoUserWidgetState();
}

class CircleVideoUserWidgetState extends State<CircleVideoUserWidget> {
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

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

  _decryptImageForDesktopTop() async {
    try {
      _imageBytes = await EncryptBlob.decryptBlobToMemory(DecryptArguments(
          encrypted: File(VideoCacheService.returnPreviewPath(
            widget.circleObject,
            widget.userCircleCache.circlePath!,
          )),
          nonce: widget.circleObject.video!.thumbCrank!,
          mac: widget.circleObject.video!.thumbSignature!,
          key: widget.circleObject.secretKey));

      if (_imageBytes != null) {
        widget.circleObject.video!.previewBytes = _imageBytes;
        widget.circleObject.userCircleCache = widget.userCircleCache;
        widget.circleObject.userFurnace = widget.userFurnace;
        globalState.globalEventBloc
            .broadcastMemCacheCircleObjectsAdd([widget.circleObject]);
        _imageDecrypted = true;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
    }
  }

  bool _isDecryptedToMemory() {
    if (_decryptingImage == false &&
        widget.circleObject.video != null &&
        widget.circleObject.video!.caching == false) {
      _decryptingImage = true;

      if (widget.circleObject.video!.previewBytes != null) {
        _imageBytes = widget.circleObject.video!.previewBytes;
        _imageDecrypted = true;
      } else if (widget.circleObject.id != null) {
        _decryptImageForDesktopTop();
      }
    }
    return _imageDecrypted;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = 200;
    double height = 200;

    double thumbnailWidth = widget.maxWidth;

    if (widget.circleObject.video != null) {
      if (widget.circleObject.video!.width != null) {
        if (widget.circleObject.video!.height! >
            widget.circleObject.video!.width!) {
          thumbnailWidth = thumbnailWidth * 0.75;
        }

        if (widget.circleObject.video!.width! < thumbnailWidth) {
          double ratio = thumbnailWidth / widget.circleObject.video!.width!;

          width = thumbnailWidth;

          height = (widget.circleObject.video!.height! * ratio).toDouble();
        } else if (widget.circleObject.video!.width! >= thumbnailWidth) {
          ///scale down
          double ratio = widget.circleObject.video!.width! / thumbnailWidth;

          width = thumbnailWidth;

          height = (widget.circleObject.video!.height! / ratio).toDouble();
        }
      }
    }

    sizedSpinner(double width, double height) =>
        Stack(alignment: Alignment.center, children: [
          SizedBox(
              width: width,
              height: height,
              child: Container(
                  constraints: const BoxConstraints.expand(),
                  alignment: Alignment.center,
                  color: globalState.theme.circleImageBackground,
                  child: Center(child: spinkitNoPadding))
              //  File(FileSystemServicewidget
              //.circleObject.gif.giphy),
              // ),
              )
        ]);

    final sizedMemCacheImage = globalState.isDesktop() && _isDecryptedToMemory()
        ? SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                )))
        : sizedSpinner(width, height);

    final sizedImage = SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              File(VideoCacheService.returnPreviewPath(
                  widget.circleObject, widget.userCircleCache.circlePath!)),
              fit: BoxFit.contain,
              //alignment: Alignment.centerRight,
            )));

    ///made this a widget so the dumb formatter would stop failing
    final column = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            widget.circleObject.body != null
                ? (widget.circleObject.body!.isNotEmpty
                    ? ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: widget.maxWidth),
                        //maxWidth: 250,
                        //height: 20,
                        child: Container(
                            padding: const EdgeInsets.all(
                                InsideConstants.MESSAGEPADDING),
                            //color: globalState.theme.dropdownBackground,
                            decoration: BoxDecoration(
                                color: globalState.theme.userObjectBackground,
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0),
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0))),
                            child: CircleObjectBody(
                              circleObject: widget.circleObject,
                              replyObject: widget.replyObject,
                              replyObjectTapHandler:
                                  widget.replyObjectTapHandler,
                              userCircleCache: widget.userCircleCache,
                              messageColor: globalState.theme.userObjectText,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              maxWidth: widget.maxWidth,
                            )),
                      )
                    : Container())
                : Container(),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            widget.circleObject.seed != null
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: widget.maxWidth),
                    child: widget.circleObject.video == null
                        ? ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: widget.maxWidth),
                            child: widget.circleObject.draft
                                ? Container()
                                : Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Center(child: spinkit)
                                    //  File(FileSystemServicewidget
                                    //.circleObject.gif.giphy),
                                    // ),
                                    ))
                        : widget.circleObject.fullTransferState ==
                                    BlobState.ENCRYPTING ||
                                widget.circleObject.fullTransferState ==
                                    BlobState.DECRYPTING
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                    globalState.isDesktop()
                                        ? Stack(
                                            alignment: Alignment.center,
                                            children: [
                                                sizedMemCacheImage,
                                                //spinkitNoPadding
                                              ])
                                        : VideoCacheService.isPreviewCached(
                                                widget.circleObject,
                                                widget.userCircleCache
                                                    .circlePath!)
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                    sizedImage,
                                                    spinkitNoPadding
                                                  ])
                                            : spinkit,
                                  ])
                            : widget.circleObject.video!.videoState ==
                                    VideoStateIC.DOWNLOADING_VIDEO
                                ? Stack(alignment: Alignment.center, children: [
                                    globalState.isDesktop()
                                        ? sizedMemCacheImage
                                        : sizedImage,
                                    CircularPercentIndicator(
                                      radius: 30.0,
                                      lineWidth: 5.0,
                                      percent: (widget.circleObject
                                                  .transferPercent ==
                                              null
                                          ? 0.01
                                          : widget.circleObject
                                                  .transferPercent! /
                                              100),
                                      center: Text(
                                          widget.circleObject.transferPercent ==
                                                  null
                                              ? '0%'
                                              : '${widget.circleObject.transferPercent}%',
                                          textScaler:
                                              const TextScaler.linear(1.0),
                                          style: TextStyle(
                                              color:
                                                  globalState.theme.progress)),
                                      progressColor: globalState.theme.progress,
                                    )
                                  ])
                                : widget.circleObject.video!.videoState ==
                                        VideoStateIC.PREVIEW_DOWNLOADED
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          globalState.isDesktop() &&
                                                  widget.circleObject.video!
                                                          .streamable ==
                                                      false
                                              ? sizedMemCacheImage
                                              : sizedImage,
                                          globalState.isDesktop() &&
                                                  _imageDecrypted == false &&
                                                  widget.circleObject.video!
                                                          .streamable ==
                                                      false
                                              ? Container()
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5, bottom: 5),
                                                  child: ClipOval(
                                                    child: Material(
                                                      color: globalState.theme
                                                          .chewiePlayBackground, // button color
                                                      child: InkWell(
                                                        splashColor: globalState
                                                            .theme
                                                            .chewieRipple, // inkwell color
                                                        child: SizedBox(
                                                            width: 65,
                                                            height: 65,
                                                            child: Icon(
                                                              Icons
                                                                  .play_for_work,
                                                              color: globalState
                                                                  .theme
                                                                  .chewiePlayForeground,
                                                              size: 35,
                                                            )),
                                                        onTap: () {
                                                          setState(() {
                                                            widget.download(widget
                                                                .circleObject);
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ))
                                        ],
                                      )
                                    : widget.circleObject.video!.videoState ==
                                            VideoStateIC.UPLOADING_VIDEO
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    globalState.isDesktop() &&
                                                            widget
                                                                    .circleObject
                                                                    .video!
                                                                    .streamable ==
                                                                false
                                                        ? sizedMemCacheImage
                                                        : VideoCacheService.isPreviewCached(
                                                                widget
                                                                    .circleObject,
                                                                widget
                                                                    .userCircleCache
                                                                    .circlePath!)
                                                            ? sizedImage
                                                            : Container(),
                                                    widget.circleObject
                                                                    .transferPercent !=
                                                                null &&
                                                            widget.circleObject
                                                                    .transferPercent !=
                                                                0 &&
                                                            widget.circleObject
                                                                    .retries <
                                                                5
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 0),
                                                            child:
                                                                CircularPercentIndicator(
                                                              radius: 30.0,
                                                              lineWidth: 5.0,
                                                              percent: (widget
                                                                          .circleObject
                                                                          .transferPercent ==
                                                                      null
                                                                  ? 0
                                                                  : widget.circleObject
                                                                          .transferPercent! /
                                                                      100),
                                                              center: Text(
                                                                  widget.circleObject
                                                                              .transferPercent ==
                                                                          null
                                                                      ? '...'
                                                                      : '${widget.circleObject.transferPercent}%',
                                                                  textScaler:
                                                                      const TextScaler
                                                                          .linear(
                                                                          1.0),
                                                                  style: TextStyle(
                                                                      color: globalState
                                                                          .theme
                                                                          .progress)),
                                                              progressColor:
                                                                  globalState
                                                                      .theme
                                                                      .progress,
                                                            ))
                                                        : widget.circleObject
                                                                    .retries <
                                                                5
                                                            ? Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            25),
                                                                child: Text(
                                                                  'queued',
                                                                  textScaler:
                                                                      const TextScaler
                                                                          .linear(
                                                                          1.0),
                                                                  style: TextStyle(
                                                                      color: globalState
                                                                          .theme
                                                                          .labelText),
                                                                ))
                                                            : Container(),
                                                  ])
                                            ],
                                          )
                                        : widget.circleObject.video!
                                                    .videoState ==
                                                VideoStateIC.NEEDS_CHEWIE
                                            ? SizedBox(
                                                width: width,
                                                height: height,
                                                child: InkWell(
                                                    onTap: () {
                                                      widget.play(
                                                          widget.circleObject);
                                                    },
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        globalState.isDesktop() &&
                                                                widget
                                                                        .circleObject
                                                                        .video!
                                                                        .streamable ==
                                                                    false
                                                            ? sizedMemCacheImage
                                                            : sizedImage,
                                                        widget.interactive
                                                            ? globalState.isDesktop() &&
                                                                    _imageDecrypted ==
                                                                        false &&
                                                                    widget
                                                                            .circleObject
                                                                            .video!
                                                                            .streamable ==
                                                                        false
                                                                ? Container()
                                                                : Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            0,
                                                                        bottom:
                                                                            0),
                                                                    child:
                                                                        ClipOval(
                                                                      child:
                                                                          Material(
                                                                        color: globalState
                                                                            .theme
                                                                            .chewiePlayBackground, // button color
                                                                        child:
                                                                            InkWell(
                                                                          splashColor: globalState
                                                                              .theme
                                                                              .chewieRipple, // inkwell color
                                                                          child: SizedBox(
                                                                              width: 65,
                                                                              height: 65,
                                                                              child: Icon(
                                                                                Icons.play_arrow,
                                                                                color: globalState.theme.chewiePlayForeground,
                                                                                size: 35,
                                                                              )),
                                                                          onTap:
                                                                              () {
                                                                            setState(() {
                                                                              widget.play(widget.circleObject);
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ))
                                                            : globalState.isDesktop() &&
                                                                    _imageDecrypted ==
                                                                        false &&
                                                                    widget
                                                                            .circleObject
                                                                            .video!
                                                                            .streamable ==
                                                                        false
                                                                ? Container()
                                                                : Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            0,
                                                                        bottom:
                                                                            0),
                                                                    child:
                                                                        ClipOval(
                                                                      child:
                                                                          Material(
                                                                        color: globalState
                                                                            .theme
                                                                            .chewiePlayBackground, // button color
                                                                        child: SizedBox(
                                                                            width: 65,
                                                                            height: 65,
                                                                            child: Icon(
                                                                              Icons.play_arrow,
                                                                              color: globalState.theme.chewiePlayForeground,
                                                                              size: 35,
                                                                            )),
                                                                      ),
                                                                    ),
                                                                  )
                                                      ],
                                                    )))
                                            : ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: InsideConstants
                                                            .MESSAGEBOXSIZE),
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child:
                                                        Center(child: spinkit)
                                                    //  File(FileSystemServicewidget
                                                    //.circleObject.gif.giphy),
                                                    // ),
                                                    ),
                                              ))
                : ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width),
                    child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Center(child: spinkit)),
                  )
          ]),
          widget.circleObject.video != null
              ? widget.circleObject.retries >=
                      5 /*|| widget.circleObject.video!.previewFile ==  null*/
                  ? Container(
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.2),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          )),
                      child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: TextButton(
                              onPressed: () {
                                widget.retry(widget.circleObject);
                              },
                              child: const Text(
                                'send failed, retry?',
                                style: TextStyle(color: Colors.red),
                              ))))
                  : Container()
              : Container(),
          widget.circleObject.video != null &&
                  widget.circleObject.retries >=
                      5 /*|| widget.circleObject.video!.previewFile ==  null*/
              ? const Padding(padding: EdgeInsets.only(bottom: 15))
              : Container(),
          CircleObjectDraft(
            circleObject: widget.circleObject,
            showTopPadding: true,
          ),
        ]);

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      //maxWidth: 250,
                                      //height: 20,
                                      child: Container(
                                          padding: const EdgeInsets.all(0.0),
                                          //color: globalState.theme.dropdownBackground,

                                          child: column),
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
}
