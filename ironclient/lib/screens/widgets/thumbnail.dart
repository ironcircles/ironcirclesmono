import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class ThumbnailWidget extends StatefulWidget {
  final CircleObject circleObject;
  final List<CircleObject>? libraryObjects;
  final bool isSelected;
  final bool anythingSelected;
  final Function longPress;
  final Function shortPress;
  final Function fullScreen;
  final bool isSelecting;
  final double? width;
  final double? height;

  const ThumbnailWidget({
    required this.circleObject,
    this.libraryObjects,
    required this.isSelected,
    required this.anythingSelected,
    required this.longPress,
    required this.shortPress,
    required this.fullScreen,
    required this.isSelecting,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  @override
  ThumbnailWidgetState createState() => ThumbnailWidgetState();
}

class ThumbnailWidgetState extends State<ThumbnailWidget> {
  late CircleImageBloc _circleImageBloc;
  late GlobalEventBloc _globalEventBloc;
  final CircleBloc _circleBloc = CircleBloc();
  Circle? _circle;
  double _width = 250;
  double _height = 250;
  bool _decryptingImage = false;
  bool _imageDecrypted = false;
  Uint8List? _imageBytes;

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  _decryptImageForDesktopTop() async {
    try {
      _imageBytes = await EncryptBlob.decryptBlobToMemory(DecryptArguments(
          encrypted: File(ImageCacheService.returnThumbnailPath(
              widget.circleObject.userCircleCache!.circlePath!,
              widget.circleObject)),
          nonce: widget.circleObject.image!.thumbCrank!,
          mac: widget.circleObject.image!.thumbSignature!,
          key: widget.circleObject.secretKey));

      if (_imageBytes != null) {
        widget.circleObject.image!.imageBytes = _imageBytes;
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
    ///filtering the object will change the image bytes, makes sure the sizes match
    if (_imageBytes != null) {
      if (_imageBytes != widget.circleObject.image!.imageBytes) {
        _imageBytes = null;
        _decryptingImage = false;
        _imageDecrypted = false;
      }
    }

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
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleImageBloc = CircleImageBloc(_globalEventBloc);

    //Listen for the first CircleObject load
    _globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        setState(() {
          //loaded = true;
        });
      }
    }, onError: (err) {
      debugPrint("CircleImageUserWidget.initState: $err");
    }, cancelOnError: false);

    _circleBloc.fetchedResponse.listen((circle) {
      if (mounted) {
        if (_circle == null) {
          setState(() {
            _circle = circle;
          });
        }
      }
    }, onError: (err) {
      debugPrint("ThumbnailWidget.listen: $err");
    }, cancelOnError: false);

    if (widget.circleObject.userFurnace != null &&
        widget.circleObject.userCircleCache != null) {
      _circleImageBloc.notifyWhenThumbReady(
          widget.circleObject.userFurnace!,
          widget.circleObject.userCircleCache!,
          widget.circleObject,
          CircleObjectBloc(globalEventBloc: _globalEventBloc));
    }

    super.initState();
  }

  getWidth() {
    if (widget.width != null) {
      _width = widget.width!;
    }
    return _width;
  }

  getHeight() {
    if (widget.height != null) {
      _height = widget.height!;
    }
    return _height;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: InkWell(
            onLongPress: () {
              widget.longPress(widget.circleObject);
            },
            onTap: () {
              widget.shortPress(widget.circleObject, _circle);
            },
            child: Padding(
                padding: EdgeInsets.all(widget.isSelected ? 0 : 0),
                child: Stack(children: [
                  Container(
                    width: getWidth(),
                    height: getHeight(),
                    color: globalState.theme.imageBackground,
                    child: (ImageCacheService.isThumbnailCached(
                            widget.circleObject,
                            widget.circleObject.userCircleCache!.circlePath!,
                            widget.circleObject.seed!)
                        ? globalState.isDesktop()
                            ? _isDecryptedToMemory()
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Center(child: spinner)
                            : Image.file(
                                File(ImageCacheService.returnThumbnailPath(
                                    widget.circleObject.userCircleCache!
                                        .circlePath!,
                                    widget.circleObject)),
                                fit: BoxFit.cover,
                              )
                        : Center(child: spinner)),
                  ),
                  widget.circleObject!.fullTransferState == BlobState.UPLOADING
                      ? SizedBox(
                          width: getWidth(),
                          height: getHeight(),
                          child: Align(
                              alignment: Alignment.center,
                              child: CircularPercentIndicator(
                                radius: 30.0,
                                lineWidth: 5.0,
                                percent: (widget
                                            .circleObject!.transferPercent ==
                                        null
                                    ? 0.01
                                    : widget.circleObject!.transferPercent! /
                                        100),
                                center: Text(
                                    widget.circleObject!.transferPercent == null
                                        ? '0%'
                                        : '${widget.circleObject!.transferPercent}%',
                                    textScaler: const TextScaler.linear(1.0),
                                    style: TextStyle(
                                        color: globalState.theme.progress)),
                                progressColor: globalState.theme.progress,
                              )))
                      : Container(),
                  widget.circleObject.id == null
                      ? Align(
                          alignment: Alignment.topRight,
                          child: widget.circleObject.unstable
                              ? Container(
                                  padding: const EdgeInsets.all(
                                      InsideConstants.MESSAGEPADDING),
                                  //color: globalState.theme.dropdownBackground,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      // .circleObjectBackground,
                                      borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(5.0),
                                          bottomRight: Radius.circular(5.0),
                                          topLeft: Radius.circular(5.0),
                                          topRight: Radius.circular(5.0))),
                                  child: const Text("unstable connection",
                                      textScaler: TextScaler.linear(1.0),
                                      style: TextStyle(color: Colors.white)))
                              : CircleAvatar(
                                  radius: 7.0,
                                  backgroundColor:
                                      globalState.theme.sentIndicator,
                                ))
                      : Container(),
                  widget.isSelected
                      ? Container(
                          color: const Color.fromRGBO(124, 252, 0, 0.5),
                          alignment: Alignment.center,
                          width: getWidth(),
                          height: getHeight(),
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
                              widget.fullScreen(
                                widget
                                    .circleObject, /*widget.circleObject!.circle*/
                              );
                            },
                          ))
                      : Container()
                ]))));
  }
}
