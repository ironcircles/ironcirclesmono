import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class VideoGallery extends StatefulWidget {
  final double width;
  final double height;
  final CircleObject circleObject;
  final UserCircleCache userCircleCache;
  final bool isUser;
  final Function? share;
  final Function download;
  final Function? cancel;
  final Function play;
  final Function? deleteCache;
  final Function longPress;
  final Function shortPress;
  final Function fullScreen;
  final bool anythingSelected;
  final bool isSelected;
  final bool isSelecting;
  final List<CircleObject>? libraryObjects;

  const VideoGallery(
      {required this.userCircleCache,
      required this.height,
      required this.width,
      required this.circleObject,
      this.libraryObjects,
      this.share,
      required this.download,
      required this.isSelected,
      required this.anythingSelected,
      required this.play,
      this.cancel,
      this.deleteCache,
      required this.fullScreen,
      required this.longPress,
      required this.shortPress,
      this.isUser = false,
      required this.isSelecting});

  @override
  _VideoGalleryState createState() => _VideoGalleryState();
}

class _VideoGalleryState extends State<VideoGallery> {
  late CircleVideoBloc _circleVideoBloc;
  late GlobalEventBloc _globalEventBloc;

  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

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

  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 0),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  @override
  void initState() {
    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleVideoBloc = CircleVideoBloc(_globalEventBloc);

    if (widget.circleObject.video!.videoState! <
        VideoStateIC.PREVIEW_DOWNLOADED)
      _circleVideoBloc.notifyWhenPreviewReady(widget.circleObject.userFurnace!,
          widget.circleObject.userCircleCache!, widget.circleObject);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Circle? _circle;

    sizedSpinner(double width, double height) =>
        Stack(alignment: Alignment.center, children: [
          SizedBox(
              width: width,
              height: height,
              child: Container(
                  constraints: const BoxConstraints.expand(),
                  alignment: Alignment.center,
                  color: globalState.theme.circleImageBackground,
                  child: Center(child: spinkit))
              //  File(FileSystemServicewidget
              //.circleObject.gif.giphy),
              // ),
              )
        ]);

    final sizedMemCacheImage = globalState.isDesktop() && _isDecryptedToMemory()
        ? SizedBox(
            width: widget.width,
            height: widget.height,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                )))
        : sizedSpinner(widget.width, widget.height);

    final sizedImage = SizedBox(
        width: widget.width,
        height: widget.height,
        child: VideoCacheService.isPreviewCached(
                widget.circleObject, widget.userCircleCache.circlePath!)
            ? Image.file(
                File(VideoCacheService.returnPreviewPath(
                    widget.circleObject, widget.userCircleCache.circlePath!)),
                fit: BoxFit.cover,
                //alignment: Alignment.centerRight,
              )
            : Center(child: spinkit));

    return Expanded(
        child: InkWell(
            onLongPress: () {
              widget.longPress(widget.circleObject);
            },
            onTap: () {
              widget.shortPress(widget.circleObject, _circle);
            },
            child: Padding(
                padding: EdgeInsets.all(widget.isSelected ? 1 : 0),
                child: Stack(alignment: Alignment.topLeft, children: <Widget>[
                  SizedBox(
                      width: widget.width,
                      height: widget.height,
                      //color: globalState.theme.background,
                      child: Stack(children: <Widget>[
                        Align(
                            alignment: Alignment.center,
                            child: widget.circleObject.seed != null
                                ? widget.circleObject.video == null
                                    ? Center(child: spinkit)
                                    : widget.circleObject.video!.videoState ==
                                            VideoStateIC.DOWNLOADING_VIDEO
                                        ? globalState.isDesktop() &&
                                                widget.circleObject.video!.streamable ==
                                                    false
                                            ? sizedMemCacheImage
                                            : Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                    sizedImage,
                                                    CircularPercentIndicator(
                                                      radius: 30.0,
                                                      lineWidth: 5.0,
                                                      percent: (widget
                                                                  .circleObject
                                                                  .transferPercent ==
                                                              null
                                                          ? 0.01
                                                          : widget.circleObject
                                                                  .transferPercent! /
                                                              100),
                                                      center: Text(
                                                          widget.circleObject
                                                                      .transferPercent ==
                                                                  null
                                                              ? '0%'
                                                              : '${widget.circleObject.transferPercent}%',
                                                          textScaler:
                                                              const TextScaler
                                                                  .linear(1.0),
                                                          style: TextStyle(
                                                              color: globalState
                                                                  .theme
                                                                  .progress)),
                                                      progressColor: globalState
                                                          .theme.progress,
                                                    )
                                                  ])
                                        : (widget.circleObject.video!.videoState ==
                                                    VideoStateIC
                                                        .PREVIEW_DOWNLOADED &&
                                                widget.circleObject.video!.streamable ==
                                                    false)
                                            ? globalState.isDesktop() &&
                                                    widget.circleObject.video!.streamable ==
                                                        false
                                                ? Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      sizedMemCacheImage,
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5,
                                                                  bottom: 5),
                                                          child: ClipOval(
                                                            child: Material(
                                                              color: globalState
                                                                  .theme
                                                                  .chewiePlayBackground, // button color
                                                              child: InkWell(
                                                                splashColor:
                                                                    globalState
                                                                        .theme
                                                                        .chewieRipple, // inkwell color
                                                                child: SizedBox(
                                                                    width: 45,
                                                                    height: 45,
                                                                    child: Icon(
                                                                      Icons
                                                                          .play_for_work,
                                                                      color: globalState
                                                                          .theme
                                                                          .chewiePlayForeground,
                                                                      size: 25,
                                                                    )),
                                                                onTap: () {
                                                                  setState(() {
                                                                    widget.download(
                                                                        widget
                                                                            .circleObject);
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ))
                                                    ],
                                                  )
                                                : Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      sizedImage,
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5,
                                                                  bottom: 5),
                                                          child: ClipOval(
                                                            child: Material(
                                                              color: globalState
                                                                  .theme
                                                                  .chewiePlayBackground, // button color
                                                              child: InkWell(
                                                                splashColor:
                                                                    globalState
                                                                        .theme
                                                                        .chewieRipple, // inkwell color
                                                                child: SizedBox(
                                                                    width: 45,
                                                                    height: 45,
                                                                    child: Icon(
                                                                      Icons
                                                                          .play_for_work,
                                                                      color: globalState
                                                                          .theme
                                                                          .chewiePlayForeground,
                                                                      size: 25,
                                                                    )),
                                                                onTap: () {
                                                                  setState(() {
                                                                    widget.download(
                                                                        widget
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
                                                ? Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      globalState.isDesktop() &&
                                                              widget
                                                                      .circleObject
                                                                      .video!
                                                                      .streamable ==
                                                                  false
                                                          ? sizedMemCacheImage
                                                          : sizedImage,
                                                      Padding(
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
                                                    ],
                                                  )
                                                : (widget.circleObject.video!.videoState == VideoStateIC.VIDEO_READY ||
                                                        widget.circleObject.video!.videoState ==
                                                            VideoStateIC
                                                                .NEEDS_CHEWIE ||
                                                        widget.circleObject.video!.videoState ==
                                                            VideoStateIC
                                                                .BUFFERING ||
                                                        widget.circleObject.video!.videoState ==
                                                            VideoStateIC
                                                                .VIDEO_UPLOADED ||
                                                        (widget.circleObject.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED &&
                                                            widget
                                                                .circleObject
                                                                .video!
                                                                .streamable!) ||
                                                        (widget.circleObject.fullTransferState ==
                                                            BlobState.READY))
                                                    ? Stack(
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
                                                          Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 0,
                                                                      bottom:
                                                                          0),
                                                              child: ClipOval(
                                                                child: Material(
                                                                  color: globalState
                                                                      .theme
                                                                      .chewiePlayBackground, // button color
                                                                  child:
                                                                      InkWell(
                                                                    splashColor:
                                                                        globalState
                                                                            .theme
                                                                            .chewieRipple, // inkwell color
                                                                    child: SizedBox(
                                                                        width: 45,
                                                                        height: 45,
                                                                        child: Icon(
                                                                          Icons
                                                                              .play_arrow,
                                                                          color: globalState
                                                                              .theme
                                                                              .chewiePlayForeground,
                                                                          size:
                                                                              25,
                                                                        )),
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        widget.play(
                                                                            widget.circleObject);
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ))
                                                        ],
                                                      )
                                                    : SizedBox(
                                                        width: widget.width,
                                                        height: widget.height,
                                                        child: Center(child: spinkit))
                                : SizedBox(width: widget.width, height: widget.height, child: Center(child: spinkit))),
                        widget.circleObject.video!.streamable! &&
                                !widget.circleObject.video!.streamableCached
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                    onPressed: () {
                                      widget.download(widget.circleObject);
                                    },
                                    icon: Icon(
                                      Icons.play_for_work,
                                      color: globalState
                                          .theme.chewiePlayForeground,
                                      size: 30,
                                    )))
                            : Container()
                      ])),
                  widget.isSelected
                      ? Container(
                          color: const Color.fromRGBO(124, 252, 0, 0.5),
                          alignment: Alignment.center,
                          width: widget.width,
                          height: widget.height,
                        )
                      : Container(),
                  widget.isSelected
                      ? Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.check_circle,
                            color: globalState.theme.buttonIcon,
                          ))
                      : widget.anythingSelected
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.circle_outlined,
                                color: globalState.theme.buttonDisabled,
                              ))
                          : Container(),
                  widget.circleObject.circle!.id == DeviceOnlyCircle.circleID
                      ? Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.save,
                                color: globalState.theme.buttonIconHighlight,
                              )))
                      : Container(),
                  widget.isSelecting
                      ? Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              widget.fullScreen(widget.circleObject);
                            },
                          ))
                      : Container(),
                  widget.circleObject.id == null
                      ? Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            radius: 7.0,
                            backgroundColor: globalState.theme.sentIndicator,
                          ))
                      : Container()
                ]))));
  }
}
