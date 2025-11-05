import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class WallVideoStreamingWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final bool interactive;
  //final Circle circle;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showTime;
  final Function download;
  final Function stream;
  final Function? deleteCache;
  final Circle? circle;
  final Function predispose;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;
  final Color messageColor;

  const WallVideoStreamingWidget(
    this.userCircleCache,
    this.interactive,
    this.userFurnace,
    this.circleObject,
    this.replyObject,
    this.showAvatar,
    this.showDate,
    this.showTime,
    this.download,
    this.stream,
    this.deleteCache,
    this.circle,
    this.predispose,
    this.unpinObject,
    this.refresh,
    this.maxWidth,
    this.messageColor,
  );

  @override
  _CircleVideoStreamingUserWidgetState createState() =>
      _CircleVideoStreamingUserWidgetState();
}

class _CircleVideoStreamingUserWidgetState
    extends State<WallVideoStreamingWidget> {
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    widget.circleObject.body !=
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
                                                                                .theme.userObjectBackground,
                                                                            borderRadius: const BorderRadius.only(
                                                                                bottomLeft: Radius.circular(10.0),
                                                                                bottomRight: Radius.circular(10.0),
                                                                                topLeft: Radius.circular(10.0),
                                                                                topRight: Radius.circular(10.0))),
                                                                        child: CircleObjectBody(
                                                                          circleObject:
                                                                              widget.circleObject,
                                                                          userCircleCache:
                                                                              widget.userCircleCache,
                                                                          replyObject:
                                                                              widget.replyObject,
                                                                          replyObjectTapHandler:
                                                                              null,
                                                                          replyMessageColor: globalState
                                                                              .theme
                                                                              .userObjectText,
                                                                          messageColor: globalState
                                                                              .theme
                                                                              .userObjectText,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.end,
                                                                          maxWidth:
                                                                              widget.maxWidth,
                                                                        )),
                                                              )
                                                            : Container())
                                                        : Container(),
                                                  ]),
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    ConstrainedBox(
                                                        constraints:
                                                            BoxConstraints(
                                                                maxWidth: widget
                                                                    .maxWidth),
                                                        child: Padding(
                                                            padding: const EdgeInsets.only(
                                                                top: .0,
                                                                left: 0,
                                                                right: 0,
                                                                bottom: 0),
                                                            child: widget.circleObject.video ==
                                                                    null
                                                                ? ConstrainedBox(
                                                                    constraints: BoxConstraints(
                                                                        maxWidth: widget
                                                                            .maxWidth),
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.all(
                                                                            5.0),
                                                                        child: Center(
                                                                            child:
                                                                                spinkit)
                                                                        //  File(FileSystemServicewidget
                                                                        //.circleObject.gif.giphy),
                                                                        // ),
                                                                        ))
                                                                :
                                                                        widget.circleObject.video!.videoState == VideoStateIC.VIDEO_UPLOADED ||
                                                                        widget.circleObject.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED ||
                                                                        widget.circleObject.video!.videoState == VideoStateIC.NEEDS_CHEWIE
                                                                    ? InkWell(
                                                                        onTap: () {
                                                                          widget
                                                                              .stream(widget.circleObject);
                                                                        },
                                                                        child: Stack(
                                                                          alignment:
                                                                              Alignment.center,
                                                                          children: [
                                                                            globalState.isDesktop() && widget.circleObject.video!.streamable == false
                                                                                ? Stack(alignment: Alignment.center, children: [
                                                                                    sizedMemCacheImage,
                                                                                    //spinkitNoPadding
                                                                                  ])
                                                                                : sizedImage,
                                                                            widget.interactive
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
                                                                                        ))
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
                                                                        constraints:
                                                                            BoxConstraints(maxWidth: width),
                                                                        child: Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(5.0),
                                                                            child: Center(child: spinkit)
                                                                            //  File(FileSystemServicewidget
                                                                            //.circleObject.gif.giphy),
                                                                            // ),
                                                                            ),
                                                                      )))
                                                  ]),
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
                            ],
                          ),
                        ),
                      ),
                    ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: false),
        ]));
  }
}
