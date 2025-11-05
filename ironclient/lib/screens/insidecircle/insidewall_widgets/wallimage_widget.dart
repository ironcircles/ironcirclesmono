import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class WallImageWidget extends StatefulWidget {
  final GlobalEventBloc globalEventBloc;
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final UserCircleCache? userCircleCache;
  final Color? replyMessageColor;
  final Color messageColor;
  final bool showTime;
  final Circle? circle;
  final Function retry;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const WallImageWidget(
      this.globalEventBloc,
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      this.replyObject,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.replyMessageColor,
      this.circle,
      this.retry,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  _WallImageWidgetState createState() => _WallImageWidgetState();
}

class _WallImageWidgetState extends State<WallImageWidget> {
  File? image;
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  _decryptImageForDesktopTop() async {
    try {
      _imageBytes = await EncryptBlob.decryptBlobToMemory(DecryptArguments(
          encrypted: File(ImageCacheService.returnThumbnailPath(
              widget.userCircleCache!.circlePath!, widget.circleObject)),
          nonce: widget.circleObject.image!.thumbCrank!,
          mac: widget.circleObject.image!.thumbSignature!,
          key: widget.circleObject.secretKey));

      if (_imageBytes != null) {
        widget.circleObject.image!.imageBytes = _imageBytes;
        widget.circleObject.userCircleCache = widget.userCircleCache;
        widget.circleObject.userFurnace = widget.userFurnace;
        widget.globalEventBloc
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
    if (_decryptingImage == false) {
      _decryptingImage = true;

      if (widget.circleObject.image!.imageBytes != null) {
        _imageBytes = widget.circleObject.image!.imageBytes;
        _imageDecrypted = true;
      } else if (widget.circleObject.id != null) {
        _decryptImageForDesktopTop();
      }
    }
    return _imageDecrypted;
  }

  @override
  void initState() {
    /*
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleImageBloc = CircleImageBloc(_globalEventBloc!);

    //Backwards compatability - This is not needed post October 2019
    if (widget.circleObject.seed == null) {
      if (widget.circleObject.id != null) {
        widget.circleObject.seed = widget.circleObject.id;
      }
    }

    _circleImageBloc.notifyWhenThumbReady(
        widget.userFurnace!, widget.userCircleCache!, widget.circleObject);


     */
    /*
    _circleImageBloc.thumbnailDownloaded.listen((String? id) {
      if (mounted) {
        if (widget.circleObject.id == id) {
          setState(() {
            //loaded = true;
          });
        }
      }
    }, onError: (err) {
      debugPrint("CircleImageUserWidget.initState: $err");
    }, cancelOnError: false);

     */

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 200;
    double height = 200;

    double thumbnailWidth = widget.maxWidth;

    if (widget.circleObject.image != null) {
      if (widget.circleObject.image!.width != null) {
        if (widget.circleObject.image!.height! >
            widget.circleObject.image!.width!) {
          thumbnailWidth = thumbnailWidth * 0.75;
        }

        if (widget.circleObject.image!.width! <= thumbnailWidth) {
          ///scale up
          double ratio = thumbnailWidth / widget.circleObject.image!.width!;

          width = thumbnailWidth;

          height = (widget.circleObject.image!.height! * ratio).toDouble();
        } else if (widget.circleObject.image!.width! >= thumbnailWidth) {
          ///scale down
          double ratio = widget.circleObject.image!.width! / thumbnailWidth;

          width = thumbnailWidth;

          height = (widget.circleObject.image!.height! / ratio).toDouble();
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
                  child: Center(child: spinkit))
              //  File(FileSystemServicewidget
              //.circleObject.gif.giphy),
              // ),
              )
        ]);

    final sizedImage = Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
      child: ImageCacheService.isThumbnailCached(widget.circleObject,
              widget.userCircleCache!.circlePath!, widget.circleObject.seed!)
          ? globalState.isDesktop()
              ? _isDecryptedToMemory()
                  ? Stack(alignment: Alignment.center, children: [
                      SizedBox(
                          width: width,
                          height: height,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ))),
                      widget.circleObject.fullTransferState ==
                              BlobState.DOWNLOADING
                          ? Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: SpinKitThreeBounce(
                                size: 12,
                                color: globalState.theme.threeBounce,
                              ))
                          : Container(),
                      widget.circleObject.fullTransferState ==
                              BlobState
                                  .UPLOADING // && widget.circleObject.retries < 5
                          ? Column(children: [
                              Padding(
                                  padding: const EdgeInsets.only(right: 0),
                                  child: CircularPercentIndicator(
                                    radius: 30.0,
                                    lineWidth: 5.0,
                                    percent: (widget
                                                .circleObject.transferPercent ==
                                            null
                                        ? 0.01
                                        : widget.circleObject.transferPercent! /
                                            100),
                                    center: Text(
                                        widget.circleObject.transferPercent ==
                                                null
                                            ? '0%'
                                            : '${widget.circleObject.transferPercent}%',
                                        textScaler:
                                            const TextScaler.linear(1.0),
                                        style: TextStyle(
                                            color: globalState.theme.progress)),
                                    progressColor: globalState.theme.progress,
                                  )),
                            ])
                          : Container(),
                    ])
                  : sizedSpinner(width, height)
              : Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(
                        width: width,
                        height: height,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(ImageCacheService.returnThumbnailPath(
                                  widget.userCircleCache!.circlePath!,
                                  widget.circleObject)),
                              fit: BoxFit.contain,
                            ))),
                    widget.circleObject.fullTransferState ==
                            BlobState.DOWNLOADING
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: SpinKitThreeBounce(
                              size: 12,
                              color: globalState.theme.threeBounce,
                            ))
                        : Container(),
                    widget.circleObject.fullTransferState ==
                            BlobState
                                .UPLOADING // && widget.circleObject.retries < 5
                        ? Column(children: [
                            Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: CircularPercentIndicator(
                                  radius: 30.0,
                                  lineWidth: 5.0,
                                  percent: (widget
                                              .circleObject.transferPercent ==
                                          null
                                      ? 0.01
                                      : widget.circleObject.transferPercent! /
                                          100),
                                  center: Text(
                                      widget.circleObject.transferPercent ==
                                              null
                                          ? '0%'
                                          : '${widget.circleObject.transferPercent}%',
                                      textScaler: const TextScaler.linear(1.0),
                                      style: TextStyle(
                                          color: globalState.theme.progress)),
                                  progressColor: globalState.theme.progress,
                                )),
                          ])
                        : Container(),
                  ]),
                ])
          : Stack(alignment: Alignment.center, children: [
              widget.circleObject.fullTransferState == BlobState.DOWNLOADING
                  ? SizedBox(
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
                  : widget.circleObject.draft
                      ? Container()
                      : spinkit,
            ]),

      //  File(FileSystemServicewidget
      //.circleObject.gif.giphy),
      // ),
    );

    //
    // final sizedImage = Padding(
    //   padding: const EdgeInsets.only(top: .0, left: 0, right: 0, bottom: 0),
    //   child: ImageCacheService.isThumbnailCached(widget.circleObject,
    //           widget.userCircleCache!.circlePath!, widget.circleObject.seed!)
    //       ? Column(children: [
    //           Stack(alignment: Alignment.center, children: [
    //             SizedBox(
    //                 width: width,
    //                 height: height,
    //                 child: ClipRRect(
    //                     borderRadius: BorderRadius.circular(15),
    //                     child: Image.file(
    //                       File(ImageCacheService.returnThumbnailPath(
    //                           widget.userCircleCache!.circlePath!,
    //                           widget.circleObject)),
    //                       fit: BoxFit.contain,
    //                     ))),
    //             widget.circleObject.fullTransferState == BlobState.DOWNLOADING
    //                 ? Padding(
    //                     padding: const EdgeInsets.only(right: 0),
    //                     child: SpinKitThreeBounce(
    //                       size: 12,
    //                       color: globalState.theme.threeBounce,
    //                     ))
    //                 : Container(),
    //             widget.circleObject.fullTransferState ==
    //                     BlobState
    //                         .UPLOADING // && widget.circleObject.retries < 5
    //                 ? Column(children: [
    //                     Padding(
    //                         padding: const EdgeInsets.only(right: 0),
    //                         child: CircularPercentIndicator(
    //                           radius: 30.0,
    //                           lineWidth: 5.0,
    //                           percent: (widget.circleObject.transferPercent ==
    //                                   null
    //                               ? 0.01
    //                               : widget.circleObject.transferPercent! / 100),
    //                           center: Text(
    //                               widget.circleObject.transferPercent == null
    //                                   ? '0%'
    //                                   : '${widget.circleObject.transferPercent}%',
    //                               textScaler: const TextScaler.linear(1.0),
    //                               style: TextStyle(
    //                                   color: globalState.theme.progress)),
    //                           progressColor: globalState.theme.progress,
    //                         )),
    //                   ])
    //                 : Container(),
    //           ]),
    //           widget.circleObject.image != null
    //               ? widget.circleObject.retries >= 5
    //                   ? Container(
    //                       decoration: BoxDecoration(
    //                           color: Colors.red.withOpacity(.2),
    //                           borderRadius: const BorderRadius.only(
    //                             bottomLeft: Radius.circular(10.0),
    //                             bottomRight: Radius.circular(10.0),
    //                             topLeft: Radius.circular(10.0),
    //                             topRight: Radius.circular(10.0),
    //                           )),
    //                       child: Padding(
    //                           padding: const EdgeInsets.all(1),
    //                           child: TextButton(
    //                               onPressed: () {
    //                                 widget.retry(widget.circleObject);
    //                               },
    //                               child: const Text(
    //                                 'send failed, retry?',
    //                                 style: TextStyle(color: Colors.red),
    //                               ))))
    //                   : Container()
    //               : Container()
    //         ])
    //       : Stack(alignment: Alignment.center, children: [
    //           widget.circleObject.fullTransferState == BlobState.DOWNLOADING
    //               ? SizedBox(
    //                   width: width,
    //                   height: height,
    //                   child: Container(
    //                       constraints: const BoxConstraints.expand(),
    //                       alignment: Alignment.center,
    //                       color: globalState.theme.circleImageBackground,
    //                       child: Center(child: spinkit))
    //                   //  File(FileSystemServicewidget
    //                   //.circleObject.gif.giphy),
    //                   // ),
    //                   )
    //               : widget.circleObject.draft
    //                   ? Container()
    //                   : SizedBox(
    //               width: width,
    //               height: height,
    //               child: Container(
    //                   constraints: const BoxConstraints.expand(),
    //                   alignment: Alignment.center,
    //                   color: globalState.theme.circleImageBackground,
    //                   child: Center(child: spinkit))
    //             //  File(FileSystemServicewidget
    //             //.circleObject.gif.giphy),
    //             // ),
    //           )
    //         ]),
    //
    // );

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
                    circleObject: widget.circleObject,
                    showDate: widget.showDate),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left: 0.0),
                                    ),
                                    AvatarWidget(
                                        refresh: widget.refresh,
                                        userFurnace: widget.userFurnace,
                                        user: widget.circleObject.creator,
                                        showAvatar: true,
                                        isUser: false),
                                    Expanded(
                                        child: Container(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: <Widget>[
                                                  CircleObjectMember(
                                                    creator: widget
                                                        .circleObject.creator!,
                                                    circleObject:
                                                        widget.circleObject,
                                                    userFurnace:
                                                        widget.userFurnace,
                                                    messageColor:
                                                        widget.messageColor,
                                                    interactive: true,
                                                    isWall: true,
                                                    showTime: true,
                                                    refresh: widget.refresh,
                                                    maxWidth: widget.maxWidth,
                                                  )
                                                ]))),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                                          .theme
                                                                          .memberObjectBackground,
                                                                      borderRadius: const BorderRadius
                                                                          .only(
                                                                          bottomLeft: Radius.circular(
                                                                              10.0),
                                                                          bottomRight: Radius.circular(
                                                                              10.0),
                                                                          topLeft: Radius.circular(
                                                                              10.0),
                                                                          topRight:
                                                                              Radius.circular(10.0))),
                                                                  child:
                                                                      CircleObjectBody(
                                                                    replyObject:
                                                                        widget
                                                                            .replyObject,
                                                                    replyMessageColor:
                                                                        widget
                                                                            .replyMessageColor,
                                                                    userCircleCache:
                                                                        widget
                                                                            .userCircleCache,
                                                                    circleObject:
                                                                        widget
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
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    widget.circleObject.seed !=
                                                            null
                                                        ? sizedImage
                                                        : /*Center(
                                          child:
                                              CircularProgressIndicator(),
                                        )*/
                                                        ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth: widget
                                                                        .maxWidth),
                                                            child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        5.0),
                                                                child: Center(
                                                                    child:
                                                                        spinkit)
                                                                //  File(FileSystemServicewidget
                                                                //.circleObject.gif.giphy),
                                                                // ),
                                                                ),
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
                                            ? /*Icon(
                                              Icons.signal_wifi_off,
                                              color: Colors.amberAccent,
                                            )*/
                                            Container(
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
          CircleObjectTimer(circleObject: widget.circleObject, isMember: false),
        ]));
  }
}
