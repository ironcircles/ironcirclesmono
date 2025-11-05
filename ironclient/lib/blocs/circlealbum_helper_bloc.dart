import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/circlealbum.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:uuid/uuid.dart';

class CircleAlbumHelperBloc {
  late GlobalEventBloc _globalEventBloc;
  late CircleAlbumBloc _circleAlbumBloc;
  final ImageCacheService _imageCacheService = ImageCacheService();

  CircleAlbumHelperBloc(GlobalEventBloc globalEventBloc, CircleAlbumBloc circleAlbumBloc) {
    _globalEventBloc = globalEventBloc;
    _circleAlbumBloc = circleAlbumBloc;
  }

  CircleObject prepAlbum(CircleObject circleObject) {
    circleObject.album = CircleAlbum(media: []);
    circleObject.type = CircleObjectType.CIRCLEALBUM;

    return circleObject;
  }

  Future<UploadObject?> cacheImage(
      List<UploadObject> sharedQueue,
      int endLength,
      CircleObject cacheObject,
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      File image,
      bool hiRes,
      CircleObjectBloc callbackBloc,
      int index,
      int loadPercentIncrement,
      ) async {

    String thumbnailPath = '';
    String fullImagePath = '';

    try {

      ThumbnailDimensions thumbnailDimensions = ThumbnailDimensions.getDimensionsFromFile(image);

      String name = SecureRandomGenerator.generateString(length: 12);

      String extension = FileSystemService.getExtension(image.path);

      thumbnailPath = ImageCacheService.returnAlbumImagePath(
        userCircleCache.circlePath!, cacheObject, true,
        name, extension, //image.uri.pathSegments.last.split(".")[0],
      );

      fullImagePath = ImageCacheService.returnAlbumImagePath(
          userCircleCache.circlePath!,
          cacheObject,
          false,
          name,
          extension,
          //image.uri.pathSegments.last.split(".")[0]
      );

      File thumbnail = File(thumbnailPath);
      File full = File(fullImagePath);

      await _cacheThumbAndFull(userCircleCache, cacheObject, thumbnailPath,
          fullImagePath, image, hiRes);

      CircleImage circleImage = CircleImage(
        height: thumbnailDimensions.height,
        width: thumbnailDimensions.width,
        fullImageSize: full.lengthSync(),
        thumbnailSize: thumbnail.lengthSync(),
      );

      circleImage.fullFile = full;
      circleImage.thumbnailFile = thumbnail;

      AlbumItem item = cacheObject.album!.media.elementAt(index);

      item.image = circleImage;
      item.type = AlbumItemType.IMAGE;

      UploadObject obj = UploadObject(
        video: null,
        circleObject: cacheObject,
        full: full,
        thumbnail: thumbnail,
        source: image,
        fileName: name,
        //fileName: image.uri.pathSegments.last.split(".")[0],
        index: index,
        //loadPercentIncrement: loadPercentIncrement,
        extension: extension,
      );

      sharedQueue.add(obj);

      //debugPrint("shared queue length: " + sharedQueue.length.toString());
      if (sharedQueue.length == endLength) {
        //debugPrint("activiating album handler after caching!!");
        _circleAlbumBloc.handler(sharedQueue, userFurnace, userCircleCache, callbackBloc);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumHelperBloc.cacheImage: $error");
    }
  }

  Future<UploadObject?> cacheVideo(
      List<UploadObject> sharedQueue,
      int endLength,
      CircleObject cacheObject,
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      File video,
      bool streamable,
      int? thumbNailFrame,
      bool orientationNeeded,
      CircleObjectBloc callbackBloc,
      int index,
      int loadPercentIncrement,
      ) async {
    try {

      CircleVideo circleVideo = CircleVideo(
        videoState: VideoStateIC.UPLOADING_VIDEO,
        extension: FileSystemService.getExtension(video.path),
        sourceVideo: video.path,
        streamable: streamable,
      );

      AlbumItem item = cacheObject.album!.media[index];

      item.video = circleVideo;
      item.type = AlbumItemType.VIDEO;

      if (streamable) {
        item.fullTransferState = BlobState.UPLOADING;
      } else {
        item.fullTransferState = BlobState.ENCRYPTING;
      }

      bool alreadyCached = false;
      String videoPath = VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, cacheObject, index.toString(), false, FileSystemService.getExtension(video.path));
      String preview = VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, cacheObject, index.toString(), true, '');

      ///if the file already exists in unique storage (because it was shared from another circle), then don't create another one
      if (cacheObject.storageID != null && cacheObject.storageID!.isNotEmpty) {
        if (File(videoPath).existsSync()) {
          alreadyCached = true;
        }
      }

      late File cachedVideo;
      late File thumbnail;

      if (alreadyCached) {
        cachedVideo = File(videoPath);
        thumbnail = File(preview);

        VideoCacheService.setItemSize(item, preview);
      } else {
        //cache the video
        try {
          cachedVideo = await VideoCacheService.cacheAlbumVideo(
              userCircleCache, cacheObject, video, index.toString());
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          try {
            cachedVideo = await VideoCacheService.cacheAlbumVideo(
                userCircleCache, cacheObject, video, index.toString());
          } catch (error, trace) {
            LogBloc.insertError(error, trace);
            cacheObject.retries = RETRIES.MAX_VIDEO_UPLOAD_RETRIES;
            //await _circleObjectService.cacheCircleObject(cacheObject);
            //callbackBloc.sinkCircleObjectSave(cacheObject);
            rethrow;
          }
        }

        //cache the preview
        try {
          thumbnail = await VideoCacheService.cacheAlbumVideoPreview(userCircleCache, cacheObject, cachedVideo, thumbNailFrame, orientationNeeded, index.toString(), item);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          try {
            thumbnail = await VideoCacheService.cacheAlbumVideoPreview(userCircleCache, cacheObject, cachedVideo, thumbNailFrame, orientationNeeded, index.toString(), item);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            //user the default image background from the assets folder
            String previewPath = VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, cacheObject, index.toString(), true, '');
            thumbnail = File(previewPath);

            final byteData =
            await rootBundle.load('assets/images/nopreview.jpg');

            await thumbnail.writeAsBytes(byteData.buffer
                .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          }
        }
      }

      UploadObject obj = UploadObject(
        circleObject: cacheObject,
        thumbnail: thumbnail,
        video: cachedVideo,
        source: video,
        index: index,

        fileName: null,
        full: null,
        //loadPercentIncrement: loadPercentIncrement,
      );

      sharedQueue.add(obj);

      // debugPrint("shared queue length: " + sharedQueue.length.toString());
      if (sharedQueue.length == endLength) {
        //debugPrint("activiating album handler after caching!!");
        _circleAlbumBloc.handler(sharedQueue, userFurnace, userCircleCache, callbackBloc);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumHelperBloc.cacheVideo: $error");
    }
  }

  _cacheThumbAndFull(
      UserCircleCache userCircleCache,
      CircleObject cacheObject,
      String thumbnailPath,
      String fullImagePath,
      File image,
      bool hiRes,
      ) async {
    bool compress = true;
    String extension = FileSystemService.getExtension(image.path);
    if (extension == "gif") {
      compress = false;
    }

    try {
      ///if the file already exists in unique storage (because it was shared from another circle), then don't create another one
      if (cacheObject.storageID != null && cacheObject.storageID!.isNotEmpty) {
        if (File(thumbnailPath).existsSync()) {
          return;
        }
      }

      await _imageCacheService.copyFullAndThumbnail(
          cacheObject,
          thumbnailPath,
          fullImagePath,
          image,
          compress,
          hiRes: hiRes);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.cacheThumbAndFull: $error");

      try {

        await _imageCacheService.copyFullAndThumbnail(
            cacheObject, thumbnailPath, fullImagePath, image, compress,
            hiRes: hiRes);

      } catch (error, trace) {
        LogBloc.insertError(error, trace);

        //use the full file
        await image.copy(thumbnailPath);
        await image.copy(fullImagePath);

        LogBloc.insertLog("Could not compress image, used full",
            "AlbumBloc: ${userCircleCache.user!}");
      }
    }
  }

  Future<CircleObject> makeCacheObject(
      CircleObject circleObject,
      ) async {
    CircleObject cacheObject = circleObject;

    try {
      cacheObject = CircleObject(
          album: circleObject.album,
          type: circleObject.type,
          timer: circleObject.timer,
          scheduledFor: circleObject.scheduledFor,
          dateIncrement: circleObject.dateIncrement,
          creator: circleObject.creator,
          hiRes: circleObject.hiRes,
          body: circleObject.body,
          circle: circleObject.circle,
          reply: circleObject.reply,
          replyUserID: circleObject.replyUserID,
          replyUsername: circleObject.replyUsername,
          taggedUsers: circleObject.taggedUsers,
          ratchetIndexes: []);

      cacheObject.initDates();

      cacheObject.seed = const Uuid().v4();
      cacheObject.storageID =
      (circleObject.storageID == null || circleObject.storageID!.isEmpty)
          ? const Uuid().v4()
          : circleObject.storageID;

      cacheObject.transferPercent = 0;

      ///add them to globalevents so we don't process twice
      _globalEventBloc.addThumbandFull(cacheObject);

      cacheObject.secretKey ??= await ForwardSecrecy.genSecretKey();

      return cacheObject;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.makeCacheObject: $error");
    }
    return cacheObject;
  }




}