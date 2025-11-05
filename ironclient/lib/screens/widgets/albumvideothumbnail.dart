import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class AlbumVideoThumbnailWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserCircleCache userCircleCache;
  final AlbumItem item;
  final Function longPress;
  final Function tap;
  final bool isSelected;
  final bool anythingSelected;
  final bool isReordering;
  final Function fullScreen;
  final Function download;
  final Function play;
  final GlobalEventBloc globalEventBloc;

  const AlbumVideoThumbnailWidget({
    required this.circleObject,
    required this.userCircleCache,
    required this.item,
    required this.longPress,
    required this.tap,
    required this.isSelected,
    required this.anythingSelected,
    required this.isReordering,
    required this.fullScreen,
    required this.download,
    required this.play,
    required this.globalEventBloc,
  });

  @override
  AlbumVideoThumbnailWidgetState createState() =>
      AlbumVideoThumbnailWidgetState();
}

class AlbumVideoThumbnailWidgetState extends State<AlbumVideoThumbnailWidget> {
  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  bool _previewDownloaded = false;
  bool _videoDownloaded = false;

  @override
  void initState() {
    super.initState();

    //listener for
    widget.globalEventBloc.itemProgressIndicator.listen((item) {
      if (mounted) {
        try {
          setState(() {
            if (item.id == widget.item.id) {
              if (item.fullTransferState == BlobState.READY) {
                setState(() {
                  widget.item.fullTransferState = BlobState.READY;
                  _videoDownloaded = VideoCacheService.isAlbumVideoCached(widget.circleObject, widget.userCircleCache.circlePath!, widget.item);
                });
              }
            }
          });
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint('FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $error');
        }
      }
    }, onError: (err) {
      debugPrint(
          "FullScreenAlbumSwiper.globalEventBloc.itemProgressIndicator.listen: $err");
    }, cancelOnError: false);

    _previewDownloaded = VideoCacheService.isAlbumPreviewCached(widget.circleObject, widget.userCircleCache.circlePath!, widget.item);
    _videoDownloaded = VideoCacheService.isAlbumVideoCached(widget.circleObject, widget.userCircleCache.circlePath!, widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final sizedImage = (VideoCacheService.isAlbumPreviewCached(
            widget.circleObject,
            widget.userCircleCache.circlePath!,
            widget.item))
        ? Image.file(
            File(VideoCacheService.returnExistingAlbumVideoPath(
                widget.userCircleCache.circlePath!,
                widget.circleObject,
                widget.item.video!.preview!)),
            fit: BoxFit.fill,//BoxFit.cover,
          )
        : spinkit;

    return InkWell(
        onLongPress: widget.isReordering
            ? null
            : () {
                widget.longPress(widget.item);
              },
        onTap: widget.isReordering
            ? null
            : () {
                widget.tap(widget.item);
              },
        child: ClipRect(
            child: Stack(
               fit: StackFit.passthrough,
          //fit: StackFit.expand,
          children: [
            widget.item.video == null
                ? Center(child: spinkit)
                : widget.item.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
                    ? Stack(alignment: Alignment.center, children: [
                        sizedImage,
                        spinkit, ///put percentage here
                      ])
                    : (widget.item.video!.videoState ==
                                VideoStateIC.PREVIEW_DOWNLOADED &&
                            widget.item.video!.streamable == false) ||
                      (_previewDownloaded == true && _videoDownloaded == false &&
                          widget.item.video!.streamable == false)
                        ? Stack(alignment: Alignment.center, children: [
                            sizedImage,
                            Padding(
                                padding:
                                    const EdgeInsets.only(right: 5, bottom: 5),
                                child: ClipOval(
                                  child: Material(
                                    color: globalState.theme
                                        .chewiePlayBackground, // button color
                                    child: InkWell(
                                      splashColor: globalState
                                          .theme.chewieRipple, // inkwell color
                                      child: SizedBox(
                                          width: 45,
                                          height: 45,
                                          child: Icon(
                                            Icons.play_for_work,
                                            color: globalState
                                                .theme.chewiePlayForeground,
                                            size: 25,
                                          )),
                                      onTap: () {
                                        setState(() {
                                          widget.download(widget.item, widget.circleObject);
                                        });
                                      },
                                    ),
                                  ),
                                ))
                          ])
                        : widget.item.video!.videoState ==
                                VideoStateIC.UPLOADING_VIDEO
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  sizedImage,
                                  Padding(
                                      padding: const EdgeInsets.only(right: 0),
                                      child: spinkit)
                                ],
                              )
                            : (widget.item.video!.videoState ==
                                        VideoStateIC.VIDEO_READY ||
                                    widget.item.video!.videoState ==
                                        VideoStateIC.NEEDS_CHEWIE ||
                                    
                                    widget.item.video!.videoState ==
                                        VideoStateIC.VIDEO_UPLOADED ||
                                    (widget.item.video!.videoState ==
                                            VideoStateIC.PREVIEW_DOWNLOADED &&
                                        widget.item.video!.streamable!) ||
                                    widget.item.fullTransferState ==
                                        BlobState.READY) || (
                                  _previewDownloaded == true &&
                                  _videoDownloaded == true
                                  )
                                ? Stack(alignment: Alignment.center, children: [
                                    sizedImage,
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            right: 0, bottom: 0),
                                        child: ClipOval(
                                          child: Material(
                                            color: globalState.theme
                                                .chewiePlayBackground, // button color
                                            child: InkWell(
                                              splashColor: globalState.theme
                                                  .chewieRipple, // inkwell color
                                              child: SizedBox(
                                                  width: 45,
                                                  height: 45,
                                                  child: Icon(
                                                    Icons.play_arrow,
                                                    color: globalState.theme
                                                        .chewiePlayForeground,
                                                    size: 25,
                                                  )),
                                              onTap: () {
                                                setState(() {
                                                  widget.play(widget.item);
                                                });
                                              },
                                            ),
                                          ),
                                        ))
                                  ])
                                : Center(child: spinkit),

            ///add back in once streaming back
            widget.item.video!.streamable! &&
                !widget.item.video!.streamableCached
                ? Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                    onPressed: () {
                      widget.download(widget.item, widget.circleObject);
                    },
                    icon: Icon(
                      Icons.play_for_work,
                      color: globalState
                          .theme.chewiePlayForeground,
                      size: 30,
                    )))
                : Container(),

            widget.isSelected
                ? Container(
                    color: const Color.fromRGBO(124, 252, 0, 0.5),
                    alignment: Alignment.center,
                  )
                : Container(),
            widget.isSelected
                ? Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.check_circle,
                        color: globalState.theme.buttonIcon,
                      )))
                : widget.anythingSelected
                    ? Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.circle_outlined,
                        color: globalState.theme.buttonDisabled,
                  )))
                    : Container(),
            widget.anythingSelected
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
                          widget.item, /*widget.circleObject!.circle*/
                        );
                      },
                    ))
                : Container()
          ],
        )));
  }
}
