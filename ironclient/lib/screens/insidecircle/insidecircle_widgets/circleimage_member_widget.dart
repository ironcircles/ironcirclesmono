import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';

class CircleImageMemberWidget extends StatefulWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color? replyMessageColor;
  final Color messageColor;
  final Circle? circle;
  final Function retry;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  //final File image;

  final UserCircleCache? userCircleCache;

  const CircleImageMemberWidget(
      this.userCircleCache,
      this.replyObjectTapHandler,
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
  CircleImageMemberWidgetState createState() => CircleImageMemberWidgetState();
}

class CircleImageMemberWidgetState extends State<CircleImageMemberWidget> {
  //CircleObjectBloc _circleObjectBloc = CircleObjectBloc();
  //CircleImageBloc _circleImageBloc = CircleImageBloc();
  File? image;
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

  final spinkit = Padding(
      padding: const EdgeInsets.only(right: 0),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  @override
  void initState() {
    super.initState();
  }

  _decryptImageForDesktopTop() async {
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
      globalState.globalEventBloc
          .broadcastMemCacheCircleObjectsAdd([widget.circleObject]);
      _imageDecrypted = true;
      if (mounted) {
        setState(() {});
      }
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
      padding: const EdgeInsets.only(top: .0, left: 0, right: 0, bottom: 0),
      child: (ImageCacheService.isThumbnailCached(widget.circleObject,
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
                              )))
                    ])
                  : sizedSpinner(width, height)
              : Stack(alignment: Alignment.center, children: [
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
                  widget.circleObject.fullTransferState == BlobState.DOWNLOADING
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: SpinKitThreeBounce(
                            size: 12,
                            color: globalState.theme.threeBounce,
                          ))
                      : Container(),
                ])
          : sizedSpinner(width, height)),
      // ),
    );

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
                          mainAxisAlignment: MainAxisAlignment.start,
                          //mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                    constraints: BoxConstraints(
                                        maxWidth: widget.maxWidth),
                                    //maxWidth: 250,
                                    //height: 20,
                                    child: Container(
                                      padding: const EdgeInsets.all(0.0),
                                      //color: globalState.theme.dropdownBackground,
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
                                                              BoxConstraints(
                                                                  maxWidth: widget
                                                                      .maxWidth),
                                                          //maxWidth: 250,
                                                          //height: 20,
                                                          child: Container(
                                                            padding: const EdgeInsets
                                                                .all(
                                                                InsideConstants
                                                                    .MESSAGEPADDING),
                                                            //color: globalState.theme.dropdownBackground,
                                                            decoration: BoxDecoration(
                                                                color: globalState
                                                                    .theme
                                                                    .memberObjectBackground,
                                                                borderRadius: const BorderRadius.only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            10.0),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            10.0),
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            10.0),
                                                                    topRight: Radius
                                                                        .circular(
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
                                                  ? sizedImage
                                                  : ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: 230),
                                                      child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5.0),
                                                          child: Center(
                                                              child: spinkit)
                                                          //  File(FileSystemServicewidget
                                                          //.circleObject.gif.giphy),
                                                          // ),
                                                          ),
                                                    )
                                            ]),
                                        widget.circleObject.image != null
                                            ? widget.circleObject.retries >= 5
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    //mainAxisSize: MainAxisSize.max,
                                                    children: [
                                                        Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                    color: Colors
                                                                        .red
                                                                        .withOpacity(
                                                                            .2),
                                                                    borderRadius:
                                                                        const BorderRadius
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
                                                                              10.0),
                                                                    )),
                                                            child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(1),
                                                                child:
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          widget
                                                                              .retry(widget.circleObject);
                                                                        },
                                                                        child:
                                                                            const Text(
                                                                          'download failed, retry?',
                                                                          style:
                                                                              TextStyle(color: Colors.red),
                                                                        ))))
                                                      ])
                                                : Container()
                                            : Container()
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
                    ))
                  ],
                ),
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
    if (circleObject.image == null) return false;

    bool retValue = ImageCacheService.isThumbnailCached(circleObject,
        widget.userCircleCache.circlePath, circleObject.seed);

    if (retValue == false && _fetchingImage == false && circleObject.image != null) {
      //request the object be cached
      _circleObjectBloc.downloadCircleImageThumbnail(
          widget.userCircleCache, widget.userFurnace, circleObject);

      _circleObjectBloc.downloadCircleImageFull(
          widget.userCircleCache, widget.userFurnace, circleObject);

      //_fetchingImage = true;
    }

    return retValue;
  }

   */
}
