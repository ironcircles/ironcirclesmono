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
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class CircleVideoStreamingMemberWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final bool interactive;
  final Function? replyObjectTapHandler;
  //final Circle circle;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showTime;
  final Function download;
  final Color messageColor;
  final Color? replyMessageColor;
  final Function stream;
  final Function unpinObject;
  final Function refresh;

  final Circle? circle;
  // final int state;
  final ChewieController? chewieController;
  final VideoControllerBloc videoControllerBloc;
  final Function predispose;
  final double maxWidth;

  const CircleVideoStreamingMemberWidget(
      this.userCircleCache,
      this.interactive,
      this.replyObjectTapHandler,
      //this.circle,
      this.userFurnace,
      this.circleObject,
      this.replyObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.download,
      this.stream,
      this.circle,
      //this.state,
      this.chewieController,
      this.videoControllerBloc,
      this.predispose,
      this.messageColor,
      this.replyMessageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  _CircleVideoStreamingMemberWidgetState createState() =>
      _CircleVideoStreamingMemberWidgetState();
}

class _CircleVideoStreamingMemberWidgetState
    extends State<CircleVideoStreamingMemberWidget> {
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 0),
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
      if (widget.circleObject.video!.thumbCrank == null) {
        ///Before desktop, streaming thumbnails were not encrypted
        _imageBytes = File(VideoCacheService.returnPreviewPath(
          widget.circleObject,
          widget.userCircleCache.circlePath!,
        )).readAsBytesSync();
      } else {
        _imageBytes = await EncryptBlob.decryptBlobToMemory(DecryptArguments(
            encrypted: File(VideoCacheService.returnPreviewPath(
              widget.circleObject,
              widget.userCircleCache.circlePath!,
            )),
            nonce: widget.circleObject.video!.thumbCrank!,
            mac: widget.circleObject.video!.thumbSignature!,
            key: widget.circleObject.secretKey));
      }
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
    if (widget.interactive) widget.predispose(widget.circleObject);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.interactive)
        widget.videoControllerBloc.disposeObject(widget.circleObject);
    });

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
                                showTime: widget.showTime,
                                refresh: widget.refresh,
                                maxWidth: widget.maxWidth,
                              ),
                              Stack(
                                  alignment: Alignment.topLeft,
                                  children: <Widget>[
                                    Align(
                                        alignment: Alignment.topLeft,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: widget.maxWidth),
                                          //maxWidth: 250,
                                          //height: 20,
                                          child: Container(
                                            padding: const EdgeInsets.all(0.0),
                                            //color: globalState.theme.dropdownBackground,

                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        widget.circleObject
                                                                    .body !=
                                                                null
                                                            ? (widget
                                                                    .circleObject
                                                                    .body!
                                                                    .isNotEmpty
                                                                ? ConstrainedBox(
                                                                    constraints:
                                                                        BoxConstraints(
                                                                            maxWidth:
                                                                                widget.maxWidth),
                                                                    //maxWidth: 250,
                                                                    //height: 20,
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          InsideConstants
                                                                              .MESSAGEPADDING),
                                                                      //color: globalState.theme.dropdownBackground,
                                                                      decoration: BoxDecoration(
                                                                          color: globalState
                                                                              .theme
                                                                              .memberObjectBackground,
                                                                          borderRadius: const BorderRadius
                                                                              .only(
                                                                              bottomLeft: Radius.circular(10.0),
                                                                              bottomRight: Radius.circular(10.0),
                                                                              topLeft: Radius.circular(10.0),
                                                                              topRight: Radius.circular(10.0))),
                                                                      child:
                                                                          CircleObjectBody(
                                                                        circleObject:
                                                                            widget.circleObject,
                                                                        replyObject:
                                                                            widget.replyObject,
                                                                        replyObjectTapHandler:
                                                                            widget.replyObjectTapHandler,
                                                                        userCircleCache:
                                                                            widget.userCircleCache,
                                                                        messageColor:
                                                                            widget.messageColor,
                                                                        replyMessageColor:
                                                                            widget.replyMessageColor,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        maxWidth:
                                                                            widget.maxWidth,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container())
                                                            : Container(),
                                                      ]),
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth: widget
                                                                        .maxWidth),
                                                            child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: .0,
                                                                        left: 0,
                                                                        right:
                                                                            0,
                                                                        bottom:
                                                                            0),
                                                                child: widget
                                                                            .chewieController ==
                                                                        null
                                                                    ? widget.circleObject.video ==
                                                                            null
                                                                        ? ConstrainedBox(
                                                                            constraints:
                                                                                BoxConstraints(maxWidth: widget.maxWidth),
                                                                            child: Padding(padding: const EdgeInsets.all(5.0), child: spinkit
                                                                                //  File(FileSystemServicewidget
                                                                                //.circleObject.gif.giphy),
                                                                                // ),
                                                                                ))
                                                                        : VideoCacheService.isPreviewCached(widget.circleObject, widget.userCircleCache.circlePath!) //widget.circleObject.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED
                                                                            ? InkWell(
                                                                                onTap: () {
                                                                                  widget.stream(widget.circleObject);
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
                                                                                    widget.circleObject.video!.videoState == VideoStateIC.BUFFERING
                                                                                        ? SizedBox(width: 65, height: 65, child: spinkitNoPadding)
                                                                                        : widget.interactive
                                                                                            ? globalState.isDesktop() && _imageDecrypted == false && widget.circleObject.video!.streamable == false
                                                                                                ? Container()
                                                                                                : ClipOval(
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
                                                                                                            widget.stream(widget.circleObject);
                                                                                                          });
                                                                                                        },
                                                                                                      ),
                                                                                                    ),
                                                                                                  )
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
                                                                                ))
                                                                            : ConstrainedBox(
                                                                                constraints: const BoxConstraints(maxWidth: 230),
                                                                                child: Padding(padding: const EdgeInsets.all(5.0), child: spinkit
                                                                                    //  File(FileSystemServicewidget
                                                                                    //.circleObject.gif.giphy),
                                                                                    // ),
                                                                                    ),
                                                                              )

                                                                    //  File(FileSystemServicewidget
                                                                    //.circleObject.gif.giphy),
                                                                    // ),

                                                                    : /*Center(
                                          child:
                                              CircularProgressIndicator(),
                                        )*/
                                                                    SizedBox(
                                                                        width: 300,
                                                                        height: 200,
                                                                        child: AspectRatio(
                                                                            aspectRatio: widget.chewieController!.aspectRatio ?? widget.chewieController!.videoPlayerController.value.aspectRatio,
                                                                            child: Chewie(
                                                                              controller: widget.chewieController!,
                                                                            )))))
                                                      ]),
                                                ]),
                                          ),
                                        )),
                                    widget.circleObject.id == null
                                        ? Align(
                                            alignment: Alignment.topRight,
                                            child: CircleAvatar(
                                              radius: 7.0,
                                              backgroundColor: globalState
                                                  .theme.sentIndicator,
                                            ))
                                        : Container()
                                  ])
                            ],
                          ),
                        ),
                      ),
                    ]),
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
