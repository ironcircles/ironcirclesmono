import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlelink_widget.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ShowReplyWidget extends StatelessWidget {
  final CircleObject replyObject;
  final CircleObject mainObject;
  final UserCircleCache userCircleCache;
  final String? stringStatement;
  final double maxWidth;

  ShowReplyWidget(
      {this.stringStatement,
      required this.replyObject,
      required this.mainObject,
      required this.userCircleCache,
      required this.maxWidth});

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  final spinkitNoPadding = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    double width = 175;
    double height = 175;
    double halved = 175 / 2;
    double thumbnailWidth = 175;
    List<AlbumItem> albumItems = [];

    if (replyObject.type == CircleObjectType.CIRCLEALBUM) {
      albumItems = replyObject.album!.media;
      albumItems.removeWhere((element) => element.removeFromCache == true);
    }

    if (replyObject.image != null) {
      if (replyObject.image!.width != null) {
        if (replyObject.image!.width! <= thumbnailWidth) {
          ///scale up
          double ratio = thumbnailWidth / replyObject.image!.width!;

          width = thumbnailWidth;

          height = (replyObject.image!.height! * ratio).toDouble();
        } else if (replyObject.image!.width! >= thumbnailWidth) {
          ///scale down
          double ratio = replyObject.image!.width! / thumbnailWidth;

          width = thumbnailWidth;

          height = (replyObject.image!.height! / ratio).toDouble();
        }
      }
    } else if (replyObject.video != null) {
      if (replyObject.video!.width != null) {
        if (replyObject.video!.width! < thumbnailWidth) {
          double ratio = thumbnailWidth / replyObject.video!.width!;

          width = thumbnailWidth;

          height = (replyObject.video!.height! * ratio).toDouble();
        } else if (replyObject.video!.width! >= thumbnailWidth) {
          ///scale down
          double ratio = replyObject.video!.width! / thumbnailWidth;

          width = thumbnailWidth;

          height = (replyObject.video!.height! / ratio).toDouble();
        }
      }
    }

    final sizedAlbum = Padding(
        padding: const EdgeInsets.only(),
        child: SizedBox(
            height: width,
            width: height,
            child: GridView.builder(
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 3) {
                    return SizedBox(
                        width: halved,
                        height: halved,
                        child: ClipRect(
                            child: Container(
                                decoration: BoxDecoration(
                                    color: userCircleCache.user ==
                                            mainObject.creator!.id
                                        ? globalState
                                            .theme.memberObjectBackground
                                        : globalState
                                            .theme.userObjectBackground,
                                    borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(10.0))),
                                child: Center(
                                    child: Icon(
                                  Icons.photo_album,
                                  size: 30,
                                  color: globalState.theme.buttonIcon,
                                )))));
                  } else {
                    if (index >= albumItems.length) {
                      return SizedBox(
                          width: halved, //100,
                          height: halved, //100,
                          child: ClipRRect(
                              borderRadius: index == 1
                                  ? const BorderRadius.only(
                                      topRight: Radius.circular(10.0))
                                  : const BorderRadius.only(
                                      bottomLeft: Radius.circular(10.0)),
                              child: Container(
                                  decoration: BoxDecoration(
                                    color: globalState.theme.objectDisabled,
                                  ),
                                  child: Center(
                                      child: Icon(
                                    Icons.add_box_outlined,
                                    size: 30,
                                    color: globalState.theme.buttonIcon,
                                  )))));
                    } else {
                      AlbumItem item = albumItems[index];

                      try {
                        return SizedBox(
                            width: halved,
                            height: halved,
                            child: ClipRRect(
                                borderRadius: index == 0
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(10.0))
                                    : index == 1
                                        ? const BorderRadius.only(
                                            topRight: Radius.circular(10.0))
                                        : const BorderRadius.only(
                                            bottomLeft: Radius.circular(10.0)),
                                child: item.type == AlbumItemType.IMAGE
                                    ? (ImageCacheService.isAlbumThumbnailCached(
                                            replyObject,
                                            item,
                                            userCircleCache.circlePath!))
                                        ? Image.file(
                                            File(ImageCacheService
                                                .returnExistingAlbumImagePath(
                                                    userCircleCache.circlePath!,
                                                    replyObject,
                                                    item.image!.thumbnail!)),
                                            fit: BoxFit.cover,
                                          )
                                        : spinkit
                                    : (VideoCacheService.isAlbumPreviewCached(
                                            replyObject,
                                            userCircleCache.circlePath!,
                                            item))
                                        ? Image.file(
                                            File(VideoCacheService
                                                .returnExistingAlbumVideoPath(
                                                    userCircleCache.circlePath!,
                                                    replyObject,
                                                    item.video!.preview!)),
                                            fit: BoxFit.cover,
                                          )
                                        : spinkit));
                      } catch (err, trace) {
                        LogBloc.insertError(err, trace);
                        return Expanded(child: spinkit);
                      }
                    }
                  }
                })));

    final sizedImage = Padding(
      padding: const EdgeInsets.only(top: .0, left: 0, right: 0, bottom: 0),
      child: ImageCacheService.isThumbnailCached(
              replyObject, userCircleCache.circlePath!, replyObject.seed!)
          ? Column(children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: width,
                    height: height,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: globalState.isDesktop()
                            ? replyObject.image!.imageBytes == null
                                ? Container()
                                : Image.memory(replyObject.image!.imageBytes!)
                            : Image.file(
                                File(ImageCacheService.returnThumbnailPath(
                                    userCircleCache.circlePath!, replyObject)),
                                fit: BoxFit.contain,
                              ))),
                replyObject.fullTransferState == BlobState.DOWNLOADING
                    ? Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: SpinKitThreeBounce(
                          size: 12,
                          color: globalState.theme.threeBounce,
                        ))
                    : Container(),
                replyObject.fullTransferState == BlobState.UPLOADING
                    ? Column(children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: CircularPercentIndicator(
                              radius: 30.0,
                              lineWidth: 5.0,
                              percent: (replyObject.transferPercent == null
                                  ? 0.01
                                  : replyObject.transferPercent! / 100),
                              center: Text(
                                  replyObject.transferPercent == null
                                      ? '0%'
                                      : '${replyObject.transferPercent}%',
                                  textScaler: const TextScaler.linear(1.0),
                                  style: TextStyle(
                                      color: globalState.theme.progress)),
                              progressColor: globalState.theme.progress,
                            )),
                      ])
                    : Container(),
                /*widget.circleObject.fullTransferState == BlobState.ENCRYPTING ||
                        widget.circleObject.fullTransferState ==
                            BlobState.DECRYPTING
                    ? Padding(
                        padding: EdgeInsets.only(top: 10, right: 25),
                        child: Text(
                          widget.circleObject.fullTransferState ==
                                  BlobState.ENCRYPTING
                              ? 'Encrypting'
                              : 'Decrypting',
                          style: TextStyle(color: globalState.theme.buttonIcon),
                        ))
                    : Container()*/
              ]),
              replyObject.image != null
                  ? replyObject.retries >= 5
                      ? TextButton(
                          onPressed: () {
                            // widget.retry(replyObject);
                          },
                          child: const Text(
                            'send failed, retry?',
                            textScaler: TextScaler.linear(1.0),
                            style: TextStyle(color: Colors.red),
                          ))
                      : Container()
                  : Container()
            ])
          : Stack(alignment: Alignment.center, children: [
              replyObject.fullTransferState == BlobState.DOWNLOADING
                  ? SizedBox(
                      width: width,
                      height: height,
                      child: Container(
                          constraints: const BoxConstraints.expand(),
                          alignment: Alignment.center,
                          color: globalState.theme.circleImageBackground,
                          child: Center(child: spinkit)))
                  : replyObject.draft
                      ? Container()
                      : spinkit,
            ]),
    );

    final sizedVideoPreview = replyObject.video == null
        ? Container()
        : SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: globalState.isDesktop()
                    ? replyObject.video!.previewBytes == null
                        ? Container()
                        : Image.memory(replyObject.video!.previewBytes!)
                    : Image.file(
                        File(VideoCacheService.returnPreviewPath(
                            replyObject, userCircleCache.circlePath!)),
                        fit: BoxFit.contain,
                        //alignment: Alignment.centerRight,
                      )));

    final sizedVideo = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        replyObject.seed != null
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: replyObject.video == null
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: replyObject.draft
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Center(child: spinkit)))
                    : replyObject.fullTransferState == BlobState.ENCRYPTING ||
                            replyObject.fullTransferState ==
                                BlobState.DECRYPTING
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                VideoCacheService.isPreviewCached(replyObject,
                                        userCircleCache.circlePath!)
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                            sizedVideoPreview,
                                            spinkitNoPadding
                                          ])
                                    : spinkit
                              ])
                        : replyObject.video!.videoState ==
                                VideoStateIC.DOWNLOADING_VIDEO
                            ? Stack(alignment: Alignment.center, children: [
                                sizedVideoPreview,
                                CircularPercentIndicator(
                                  radius: 30.0,
                                  lineWidth: 5.0,
                                  percent: (replyObject.transferPercent == null
                                      ? 0.01
                                      : replyObject.transferPercent! / 100),
                                  center: Text(
                                      replyObject.transferPercent == null
                                          ? '0%'
                                          : '${replyObject.transferPercent}%',
                                      textScaler: const TextScaler.linear(1.0),
                                      style: TextStyle(
                                          color: globalState.theme.progress)),
                                  progressColor: globalState.theme.progress,
                                )
                              ])
                            : replyObject.video!.videoState ==
                                    VideoStateIC.PREVIEW_DOWNLOADED
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      sizedVideoPreview,
                                      // Padding(
                                      //   padding: const EdgeInsets.only(right: 5, bottom: 5),
                                      //   child: ClipOval(
                                      //     child: Material(
                                      //       color: globalState.theme.chewiePlayBackground,
                                      //       child: InkWell(
                                      //         splashColor: globalState.theme.chewieRipple,
                                      //         child: SizedBox(
                                      //           width: 65,
                                      //           height: 65,
                                      //           child: Icon(
                                      //             Icons.play_for_work,
                                      //             color: globalState.theme.chewiePlayForeground,
                                      //             size: 35,
                                      //           )),
                                      //       ),
                                      //     ),
                                      //   ))
                                    ],
                                  )
                                : replyObject.video!.videoState ==
                                        VideoStateIC.UPLOADING_VIDEO
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                VideoCacheService
                                                        .isPreviewCached(
                                                            replyObject,
                                                            userCircleCache
                                                                .circlePath!)
                                                    ? sizedVideoPreview
                                                    : Container(),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 0),
                                                    child:
                                                        CircularPercentIndicator(
                                                      radius: 30.0,
                                                      lineWidth: 5.0,
                                                      percent: (replyObject
                                                                  .transferPercent ==
                                                              null
                                                          ? 0
                                                          : replyObject
                                                                  .transferPercent! /
                                                              100),
                                                      center: Text(
                                                          replyObject.transferPercent ==
                                                                  null
                                                              ? '...'
                                                              : '${replyObject.transferPercent}%',
                                                          textScaler:
                                                              const TextScaler
                                                                  .linear(1.0),
                                                          style: TextStyle(
                                                              color: globalState
                                                                  .theme
                                                                  .progress)),
                                                      progressColor: globalState
                                                          .theme.progress,
                                                    ))
                                              ])
                                        ],
                                      )
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          sizedVideoPreview,
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 5, bottom: 5),
                                              child: ClipOval(
                                                child: Material(
                                                  color: globalState.theme
                                                      .chewiePlayBackground,
                                                  child: InkWell(
                                                    splashColor: globalState
                                                        .theme.chewieRipple,
                                                    child: SizedBox(
                                                        width: 45,
                                                        height: 45,
                                                        child: Icon(
                                                          Icons.play_arrow,
                                                          color: globalState
                                                              .theme
                                                              .chewiePlayForeground,
                                                          size: 25,
                                                        )),
                                                  ),
                                                ),
                                              ))
                                        ],
                                      )
                // ConstrainedBox(
                //       constraints: const BoxConstraints(maxWidth: InsideConstants.MESSAGEBOXSIZE),
                //       child: Padding(padding: const EdgeInsets.all(5.0), child: Center(child: spinkit)
                //       ),)
                )
            : Stack(
                alignment: Alignment.center,
                children: [
                  sizedVideoPreview,
                  Padding(
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      child: ClipOval(
                        child: Material(
                          color: globalState.theme.chewiePlayBackground,
                          child: InkWell(
                            splashColor: globalState.theme.chewieRipple,
                            child: SizedBox(
                                width: 65,
                                height: 65,
                                child: Icon(
                                  Icons.play_for_work,
                                  color: globalState.theme.chewiePlayForeground,
                                  size: 35,
                                )),
                          ),
                        ),
                      ))
                ],
              )
        // ConstrainedBox(
        //       constraints: BoxConstraints(maxWidth: width),
        //       child: Padding(
        //         padding: const EdgeInsets.all(5.0),
        //         child: Center(child: spinkit)
        //       ),
        // )
      ],
    );

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      replyObject.type == CircleObjectType.CIRCLEGIF && replyObject.gif != null
          ? SizedBox(
              width: width,
              height: height,
              child: CachedNetworkImage(
                fit: BoxFit.contain,
                imageUrl: replyObject.gif!.giphy!,
                placeholder: (context, url) => spinkit,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ))
          : replyObject.type == CircleObjectType.CIRCLEIMAGE &&
                  replyObject.image != null
              ? sizedImage
              : replyObject.type == CircleObjectType.CIRCLEVIDEO &&
                      replyObject.video != null
                  ? sizedVideo
                  : replyObject.type == CircleObjectType.CIRCLEALBUM &&
                          replyObject.album != null
                      ? sizedAlbum
                      : replyObject.type == CircleObjectType.CIRCLELINK &&
                              replyObject.link != null
                          ? CircleLinkWidget(
                              key: GlobalKey(),
                              circleObject: replyObject,
                              maxWidth: maxWidth,
                            )
                          : Container()
    ]);
  }
}
