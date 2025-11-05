import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:ironcirclesapp/screens/widgets/loop_restart_indicator.dart';

class WallVideoWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  //final Circle circle;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showTime;
  final Function unpinObject;
  final Function download;
  final Function? play;
  final Color messageColor;
  final Color? replyMessageColor;
  final bool interactive;
  final Function refresh;

  final Circle? circle;
  final Function retry;
  // final int state;
  final ChewieController? chewieController;
  final VideoControllerBloc videoControllerBloc;
  final Function predispose;
  final double maxWidth;

  const WallVideoWidget(
      this.userCircleCache,
      //this.circle,
      this.userFurnace,
      this.circleObject,
      this.replyObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.download,
      this.play,
      this.circle,

      //this.state,
      this.chewieController,
      this.retry,
      this.videoControllerBloc,
      this.predispose,
      this.messageColor,
      this.replyMessageColor,
      this.unpinObject,
      this.interactive,
      this.refresh,
      this.maxWidth);

  @override
  _WallVideoWidgetState createState() => _WallVideoWidgetState();
}

class _WallVideoWidgetState extends State<WallVideoWidget> {
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

  final spinkit = Padding(
      padding: const EdgeInsets.only(right: 150),
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
    /* widget.predispose(widget.circleObject);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      widget.videoControllerBloc.disposeObject(widget.circleObject);
    });
*/
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = 200;
    double height = 200;

    double thumbnailWidth = widget.maxWidth;

    if (widget.circleObject.video != null) {
      if (widget.circleObject.video!.width != null) {

        if (widget.circleObject.video!.height! > widget.circleObject.video!.width!){
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

    final uploading =
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Stack(alignment: Alignment.center, children: [
        VideoCacheService.isPreviewCached(
                widget.circleObject, widget.userCircleCache.circlePath!)
            ? globalState.isDesktop()
                ? Stack(alignment: Alignment.center, children: [
                    sizedMemCacheImage,
                    //spinkitNoPadding
                  ])
                : sizedImage
            : Container(),
        widget.circleObject.transferPercent != null &&
                widget.circleObject.transferPercent != 0 &&
                widget.circleObject.retries < 5
            ? Padding(
                padding: const EdgeInsets.only(right: 0),
                child: CircularPercentIndicator(
                  radius: 30.0,
                  lineWidth: 5.0,
                  percent: (widget.circleObject.transferPercent == null
                      ? 0
                      : widget.circleObject.transferPercent! / 100),
                  center: Text(
                      widget.circleObject.transferPercent == null
                          ? '...'
                          : '${widget.circleObject.transferPercent}%',
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(color: globalState.theme.progress)),
                  progressColor: globalState.theme.progress,
                ))
            : widget.circleObject.retries < 5
                ? Padding(
                    padding: const EdgeInsets.only(right: 25),
                    child: Text(
                      'queued',
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(color: globalState.theme.labelText),
                    ))
                : Container()
      ])
    ]);

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomLeft, children: <Widget>[
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
                    mainAxisAlignment: MainAxisAlignment.start,
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              CircleObjectMember(
                                creator: widget.circleObject.creator!,
                                circleObject: widget.circleObject,
                                userFurnace: widget.userFurnace,
                                messageColor: widget.messageColor,
                                interactive: true,
                                isWall: true,
                                showTime: widget.showTime,
                                refresh: widget.refresh,
                                maxWidth: widget.maxWidth,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                Stack(children: <Widget>[
                  Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: widget.maxWidth),
                        //maxWidth: 250,
                        //height: 20,
                        child: Container(
                          padding: const EdgeInsets.all(0.0),
                          //color: globalState.theme.dropdownBackground,

                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      widget.circleObject.body != null
                                          ? (widget
                                                  .circleObject.body!.isNotEmpty
                                              ? ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxWidth:
                                                          widget.maxWidth),
                                                  //maxWidth: 250,
                                                  //height: 20,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .all(InsideConstants
                                                            .MESSAGEPADDING),
                                                    //color: globalState.theme.dropdownBackground,
                                                    decoration: BoxDecoration(
                                                        color: globalState.theme
                                                            .memberObjectBackground,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                                bottomLeft:
                                                                    Radius.circular(
                                                                        10.0),
                                                                bottomRight: Radius
                                                                    .circular(
                                                                        10.0),
                                                                topLeft: Radius
                                                                    .circular(
                                                                        10.0),
                                                                topRight: Radius
                                                                    .circular(
                                                                        10.0))),
                                                    child: CircleObjectBody(
                                                      circleObject:
                                                          widget.circleObject,
                                                      replyObject:
                                                          widget.replyObject,
                                                      userCircleCache: widget
                                                          .userCircleCache,
                                                      messageColor:
                                                          widget.messageColor,
                                                      replyMessageColor: widget
                                                          .replyMessageColor,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      maxWidth: widget.maxWidth,
                                                    ),
                                                  ),
                                                )
                                              : Container())
                                          : Container(),
                                    ]),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      widget.circleObject.seed != null
                                          ? ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  //minWidth:
                                                  //     InsideConstants
                                                  //         .MESSAGEBOXSIZE,
                                                  maxWidth: widget.maxWidth),
                                              child: Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: .0,
                                                      left: 0,
                                                      right: 0,
                                                      bottom: 0),
                                                  child:
                                                      widget.chewieController ==
                                                              null
                                                          ? widget.circleObject.video ==
                                                                  null
                                                              ? ConstrainedBox(
                                                                  constraints: BoxConstraints(
                                                                      maxWidth: widget
                                                                          .maxWidth),
                                                                  child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              5.0),
                                                                      child: Center(
                                                                          child:
                                                                              spinkit)
                                                                      //  File(FileSystemServicewidget
                                                                      //.circleObject.gif.giphy),
                                                                      // ),
                                                                      ))
                                                              : widget.circleObject.video!.videoState ==
                                                          VideoStateIC
                                                                          .DOWNLOADING_VIDEO
                                                                  ? Stack(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      children: [
                                                                          globalState.isDesktop() && widget.circleObject.video!.streamable == false
                                                                              ? Stack(alignment: Alignment.center, children: [
                                                                                  sizedMemCacheImage,
                                                                                  //spinkitNoPadding
                                                                                ])
                                                                              : sizedImage,
                                                                          Padding(
                                                                              padding: const EdgeInsets.only(right: 0),
                                                                              child: CircularPercentIndicator(
                                                                                radius: 30.0,
                                                                                lineWidth: 5.0,
                                                                                percent: (widget.circleObject.transferPercent == null ? 0.01 : widget.circleObject.transferPercent! / 100),
                                                                                center: Text(
                                                                                  widget.circleObject.transferPercent == null ? '0%' : '${widget.circleObject.transferPercent}%',
                                                                                  textScaler: const TextScaler.linear(1.0),
                                                                                  style: TextStyle(color: globalState.theme.progress),
                                                                                ),
                                                                                progressColor: globalState.theme.progress,
                                                                              ))
                                                                        ])
                                                                  : (widget.circleObject.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED ||
                                                                              widget.circleObject.retries >=
                                                                                  5) &&
                                                                          VideoCacheService.isPreviewCached(
                                                                              widget.circleObject,
                                                                              widget.userCircleCache.circlePath!) //s, path)idget.circleObject.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED /*|| widget.circleObject.video!.previewFile != null*/
                                                                      ? Stack(
                                                                          alignment:
                                                                              Alignment.center,
                                                                          children: [
                                                                            globalState.isDesktop() && widget.circleObject.video!.streamable == false
                                                                                ? Stack(alignment: Alignment.center, children: [
                                                                                    sizedMemCacheImage,
                                                                                    //spinkitNoPadding
                                                                                  ])
                                                                                : sizedImage,
                                                                            /*TextButton(child:Text('download', style: TextStyle(fontSize: 24, color: globalState.theme.buttonIcon),
                                                                          ), onPressed: () {},),

                                                                           */
                                                                            globalState.isDesktop() && _imageDecrypted == false && widget.circleObject.video!.streamable == false
                                                                                ? Container()
                                                                                : widget.interactive
                                                                                    ? Padding(
                                                                                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                                                                                        child: ClipOval(
                                                                                          child: Material(
                                                                                            color: globalState.theme.chewiePlayBackground, // button color
                                                                                            child: InkWell(
                                                                                              splashColor: globalState.theme.chewieRipple, // inkwell color
                                                                                              child: SizedBox(
                                                                                                  width: 65,
                                                                                                  height: 65,
                                                                                                  child: Icon(
                                                                                                    Icons.play_for_work,
                                                                                                    color: globalState.theme.chewiePlayForeground,
                                                                                                    size: 35,
                                                                                                  )),
                                                                                              onTap: () {
                                                                                                setState(() {
                                                                                                  widget.download(widget.circleObject);
                                                                                                });
                                                                                              },
                                                                                            ),
                                                                                          ),
                                                                                        ))
                                                                                    : globalState.isDesktop() && _imageDecrypted == false && widget.circleObject.video!.streamable == false
                                                                                        ? Container()
                                                                                        : Padding(
                                                                                            padding: const EdgeInsets.only(right: 0, bottom: 0),
                                                                                            child: ClipOval(
                                                                                              child: Material(
                                                                                                color: globalState.theme.chewiePlayBackground, // button color
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
                                                                        )
                                                                      : widget.circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO
                                                                          ? uploading
                                                                          : widget.circleObject.video!.videoState == VideoStateIC.NEEDS_CHEWIE
                                                                              ? InkWell(
                                                                                  onTap: () {
                                                                                    widget.play!(widget.circleObject);
                                                                                  },
                                                                                  child: Stack(
                                                                                    alignment: Alignment.center,
                                                                                    children: [
                                                                                      globalState.isDesktop() && widget.circleObject.video!.streamable == false
                                                                                          ? sizedMemCacheImage
                                                                                          : SizedBox(
                                                                                              width: width,
                                                                                              height: height,
                                                                                              child: ClipRRect(
                                                                                                  borderRadius: BorderRadius.circular(15),
                                                                                                  child: Image.file(
                                                                                                    File(VideoCacheService.returnPreviewPath(widget.circleObject, widget.userCircleCache.circlePath!)),
                                                                                                    fit: BoxFit.contain,
                                                                                                  ))),
                                                                                      /*TextButton(child:Text('download', style: TextStyle(fontSize: 24, color: globalState.theme.buttonIcon),
                                                                          ), onPressed: () {},),

                                                                           */
                                                                                      globalState.isDesktop() &&
                                                                                          _imageDecrypted == false && widget.circleObject.video!.streamable == false
                                                                                          ? Container()
                                                                                          : widget.play != null
                                                                                          ? Padding(
                                                                                              padding: const EdgeInsets.only(right: 0, bottom: 0),
                                                                                              child: ClipOval(
                                                                                                child: Material(
                                                                                                  color: globalState.theme.chewiePlayBackground, // button color
                                                                                                  child: InkWell(
                                                                                                    splashColor: globalState.theme.chewieRipple, // inkwell color
                                                                                                    child: SizedBox(
                                                                                                        width: 65,
                                                                                                        height: 65,
                                                                                                        child: Icon(
                                                                                                          Icons.play_arrow,
                                                                                                          color: globalState.theme.chewiePlayForeground,
                                                                                                          size: 35,
                                                                                                        )),
                                                                                                    onTap: () {
                                                                                                      setState(() {
                                                                                                        widget.play!(widget.circleObject);
                                                                                                      });
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ))
                                                                                          : globalState.isDesktop() &&
                                                                                          _imageDecrypted == false && widget.circleObject.video!.streamable == false
                                                                                          ? Container()
                                                                                          : Padding(
                                                                                              padding: const EdgeInsets.only(right: 0, bottom: 0),
                                                                                              child: ClipOval(
                                                                                                child: Material(
                                                                                                  color: globalState.theme.chewiePlayBackground, // button color
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
                                                                                  ))
                                                                              : ConstrainedBox(
                                                                                  constraints: BoxConstraints(maxWidth: widget.maxWidth),
                                                                                  child: Padding(padding: const EdgeInsets.all(5.0), child: Center(child: spinkit)
                                                                                      //  File(FileSystemServicewidget
                                                                                      //.circleObject.gif.giphy),
                                                                                      // ),
                                                                                      ),
                                                                                )
                                                          : SizedBox(
                                                              width: 300,
                                                              height: 200,
                                                              child: AspectRatio(
                                                                  aspectRatio: widget.chewieController!.aspectRatio ?? widget.chewieController!.videoPlayerController.value.aspectRatio,
                                                                  child: LoopRestartIndicator(
                                                                    controller: widget.chewieController!.videoPlayerController,
                                                                    child: Chewie(
                                                                      controller: widget.chewieController!,
                                                                    ),
                                                                  ))))
                                              //  File(FileSystemServicewidget
                                              //.circleObject.gif.giphy),
                                              // ),

                                              )
                                          : /*Center(
                                          child:
                                              CircularProgressIndicator(),
                                        )*/
                                          ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 230),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Center(child: spinkit)
                                                  //  File(FileSystemServicewidget
                                                  //.circleObject.gif.giphy),
                                                  // ),
                                                  ),
                                            )
                                    ]),
                                widget.circleObject.video != null
                                    ? widget.circleObject.retries >= 5
                                        ? TextButton(
                                            onPressed: () {
                                              widget.retry(widget.circleObject);
                                            },
                                            child: const Text(
                                              'download failed, retry?',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ))
                                        : Container()
                                    : Container()
                              ]),
                        ),
                      )),
                ])
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

  /*
  bool _isThumbnailCached(CircleObject circleObject) {
    if (circleObject.seed == null) return false;

    bool retValue = FileSystemService.isThumbnailCached(
        widget.userCircleCache.circlePath, circleObject.seed);

    if (retValue == false &&
        _fetchingImage == false &&
        circleObject.image != null) {
      //request the object be cached
      _circleObjectBloc.downloadCircleImageThumbnail(
          widget.userCircleCache, widget.userFurnace, circleObject);
      _circleObjectBloc.downloadCircleImageFull(
          widget.userCircleCache, widget.userFurnace, circleObject);

      // _fetchingImage = true;
    }

    return retValue;
  }
  */
}
