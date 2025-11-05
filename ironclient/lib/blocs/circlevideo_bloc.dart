import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/circlevideo_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

class QueueObject {
  CircleObject circleObject;
  File thumbnail;
  File video;
  File source;

  QueueObject(
      {required this.circleObject,
      required this.thumbnail,
      required this.video,
      required this.source});
}

class CircleVideoBloc {
  final CircleObjectService _circleObjectService = CircleObjectService();
  late CircleVideoService _circleVideoService;

  late GlobalEventBloc _globalEventBloc;

  final List<QueueObject> _queue = [];
  int _queueCount = 0;
  int _processingCount = 0;

  CircleVideoBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _circleVideoService = CircleVideoService(_globalEventBloc);
  }

  final _streamAvailable = PublishSubject<CircleObject>();
  Stream<CircleObject> get streamAvailable => _streamAvailable.stream;

  final _streamItemAvailable = PublishSubject<AlbumItem>();
  Stream<AlbumItem> get streamItemAvailable => _streamItemAvailable.stream;

  final _autoPlayReady = PublishSubject<CircleObject>();
  Stream<CircleObject> get autoPlayReady => _autoPlayReady.stream;

  final _itemAutoPlayReady = PublishSubject<AlbumItem>();
  Stream<AlbumItem> get itemAutoPlayReady => _itemAutoPlayReady.stream;

  dispose() async {
    _streamAvailable.drain();
    _streamAvailable.close();

    _autoPlayReady.drain();
    _autoPlayReady.close();

    _itemAutoPlayReady.drain();
    _itemAutoPlayReady.close();
  }

  broadcastAutoplay(CircleObject circleObject) async {
    try {
      _autoPlayReady.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoBloc.getStreamingUrl: $err');
      _autoPlayReady.sink.addError(err);
    }
  }

  broadcastItemAutoplay(AlbumItem item) async {
    try {
      _itemAutoPlayReady.sink.add(item);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoBloc.broadcastItemAutoplay: $err');
      _itemAutoPlayReady.sink.addError(err);
    }
  }

  getAlbumStreamingUrl(UserFurnace userFurnace, CircleObject circleObject, AlbumItem item) async {
    try {
      item.video!.streamingUrl = await _circleVideoService.getAlbumStreamingUrl(userFurnace, circleObject, item);

      debugPrint(item.video!.streamingUrl);

      _streamItemAvailable.sink.add(item);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.getAlbumStreamingUrl: $error");
      _streamItemAvailable.sink.addError(error);
    }
  }

  getStreamingUrl(UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      circleObject.video!.streamingUrl =
          await _circleVideoService.getStreamingUrl(userFurnace, circleObject);

      debugPrint(circleObject.video!.streamingUrl);

      _streamAvailable.sink.add(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoBloc.getStreamingUrl: $err');
      _streamAvailable.sink.addError(err);
    }
  }

  Future<CircleObject> cancelVideoTransfer(
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    //circleObject.video.videoState = VideoStateIC.UNKNOWN;

    _queue.removeWhere(
        (element) => element.circleObject.seed == circleObject.seed);

    _globalEventBloc.fullObjects.remove(circleObject);

    BlobService.safeCancelTokens(circleObject);

    if (circleObject.video!.videoState == VideoStateIC.UPLOADING_VIDEO) {
      await TableCircleObjectCache.deleteBySeed(circleObject.seed!);
      _globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
    } else if (circleObject.video!.videoState ==
        VideoStateIC.DOWNLOADING_VIDEO) {
      circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
      circleObject.retries = 0;
      circleObject.transferPercent = 0;

      await TableCircleObjectCache.updateCacheSingleObject(
          userCircleCache.user!, circleObject);
    }

    if (VideoCacheService.isVideoCached(
        circleObject, userCircleCache.circlePath!)) {
      VideoCacheService.deleteVideo(userCircleCache.circlePath!, circleObject);
    }

    return circleObject;
  }

  deleteItemCache(
      String userID, String circlePath, CircleObject circleObject, AlbumItem item) async {
    await _circleVideoService.deleteItemCache(userID, circlePath, circleObject, item);
  }

  deleteCache(
      String userID, String circlePath, CircleObject circleObject) async {
    await _circleVideoService.deleteCache(userID, circlePath, circleObject);

    _globalEventBloc.cacheDeleted.sink.add(circleObject);
  }

  cleanCache(List<String> createdVideos, CircleObject circleObject) async {
    try {
      if (circleObject.video!.sourceVideo != null) {
        for (String videoPath in createdVideos) {
          if (FileSystemService.getFilename(videoPath) ==
              FileSystemService.getFilename(circleObject.video!.sourceVideo))
            File(circleObject.video!.sourceVideo!).delete();
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoBloc.cleanCache: $err');
    }
  }

  showRetry(
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
  ) async {
    circleObject.retries = RETRIES.MAX_VIDEO_UPLOAD_RETRIES;
    await _circleObjectService.cacheCircleObject(circleObject);

    _globalEventBloc.removeOnError(circleObject);

    callbackBloc.sinkCircleObjectSave(circleObject);
  }

  retryUpload(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File video,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    try {
      debugPrint(
          'CircleVideoBloc.processVideoFailed processed: ${circleObject.retries}');

      if (_globalEventBloc.thumbnailExists(circleObject))
        return;
      else
        _globalEventBloc.addThumbandFull(circleObject);

      if (circleObject.transferUrls == null)
        //LogBloc.insertLog('getting aws urls', 'retryUpload');
        await _stepGetURls(userCircleCache, userFurnace, circleObject, video,
            thumbnail, callbackBloc);

      bool passedGate = false;

      //Second Gate - Check to see if the files exist

      if (!thumbnail.existsSync() || !video.existsSync()) {
        //TODO
        //FileSystemService.safeDelete(thumbnail);
        //FileSystemService.safeDelete(video);
      }

      //do the encrypted files exist and do they match the size of the original?
      File encryptedThumb = File('${thumbnail.path}enc');
      File encryptedFull = File('${video.path}enc');

      if (encryptedThumb.existsSync()) {
        if (encryptedThumb.lengthSync() == thumbnail.lengthSync()) {
          if (encryptedFull.existsSync()) {
            if (encryptedFull.lengthSync() == video.lengthSync()) {
              //validate the encryption information is part of the object

              if (circleObject.video!.fullSignature != null &&
                  circleObject.video!.fullCrank != null &&
                  circleObject.video!.thumbSignature != null &&
                  circleObject.video!.thumbCrank != null &&
                  circleObject.secretKey != null) passedGate = true;
            }
          }
        }
      }

      if (!passedGate) {
        await FileSystemService.safeDelete(encryptedFull);
        await FileSystemService.safeDelete(encryptedFull);

        circleObject = await _encryptFiles(
            userCircleCache, userFurnace, circleObject, video, thumbnail);

        if (circleObject.video!.streamable == true) {
          encryptedFull = File(video.path);
        }
      }

      passedGate = false;

      if (circleObject.thumbnailTransferState! < BlobState.UPLOADED_BLOB_ONLY) {
        //LogBloc.insertLog('postThumbnail', 'retryUpload');

        await _circleVideoService.postThumbnail(
          userCircleCache,
          userFurnace,
          circleObject,
        );
        await _postFull(
            userCircleCache, userFurnace, circleObject, encryptedFull);
        /*await _circleVideoService.postFull(
            userCircleCache, userFurnace, circleObject, encryptedFull,
            maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);

         */
        await _postObjectOnly(userCircleCache, userFurnace, circleObject);
      } else if (circleObject.fullTransferState! <
          BlobState.UPLOADED_BLOB_ONLY) {
        await _postFull(
            userCircleCache, userFurnace, circleObject, encryptedFull);
        /* await _circleVideoService.postFull(
            userCircleCache, userFurnace, circleObject, encryptedFull,
            maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);

        */
        await _postObjectOnly(userCircleCache, userFurnace, circleObject);
      } else {
        await _postObjectOnly(userCircleCache, userFurnace, circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      circleObject.retries = RETRIES.MAX_VIDEO_UPLOAD_RETRIES;
      TableCircleObjectCache.updateCacheSingleObject(
          userCircleCache.user!, circleObject);
      debugPrint('CircleVideoBloc.processVideoFailed: $err');
      _globalEventBloc.removeOnError(circleObject);
    }
  }

  /// upload circle videos
  uploadVideos(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      List<Media> mediaCollection) async {
    try {
      bool first = true;

      _queueCount = mediaCollection.length;

      //save just the circleobjects
      for (Media media in mediaCollection) {
        late CircleObject individual;

        if (first) {
          individual = circleObject;
          if (individual.body != null)
            individual.body = individual.body!.trim();
          first = false;
        } else {
          individual = CircleObject.prepNewCircleObject(
              userCircleCache, userFurnace, '', 0, null, type: CircleObjectType.CIRCLEVIDEO);
          individual.timer = circleObject.timer;
        }

        //individual.type = CircleObjectType.CIRCLEVIDEO;
        individual.storageID = media.storageID;

        ///this is async, next steps are dependant on the function
        // await cacheObjectUpdateScreen(
            // media.thumbnail,
            // userCircleCache,
            // userFurnace,
            // individual,
            // callbackBloc,
            // File(media.path),
            // media.streamable,
            // media.thumbIndex, false);

        //uploadVideo(userCircleCache, userFurnace, individual, callbackBloc,
        //  File(media.path), streamable, media.thumbIndex, false);

        await Future.delayed(const Duration(milliseconds: 100));
      }

      ///process queue
      _isQueueFull(userCircleCache, userFurnace, callbackBloc);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.saveCircleImagesFromAssets: $error");
    }
  }
  //
  // uploadVideo(
  //     UserCircleCache userCircleCache,
  //     UserFurnace userFurnace,
  //     CircleObject circleObject,
  //     CircleObjectBloc callbackBloc,
  //     File video,
  //     String tempPreview,
  //     bool streamable,
  //     int? thumbNailFrame,
  //     bool orientationNeeded) async {
  //   _queueCount = 1;
  //
  //   cacheObjectUpdateScreen(
  //       tempPreview,
  //       userCircleCache,
  //       userFurnace,
  //       circleObject,
  //       callbackBloc,
  //       video,
  //       streamable,
  //       thumbNailFrame,
  //       orientationNeeded);
  // }

  cacheObjectUpdateScreen(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      File video,
      String tempPreview,
      bool streamable,
      int? thumbNailFrame,
      bool orientationNeeded) async {
    CircleObject cacheObject = circleObject;

    try {
      if (circleObject.id == null) {
        circleObject.seed ??= const Uuid().v4();
        cacheObject = CircleObject(
            type: circleObject.type,
            creator: circleObject.creator,
            circle: circleObject.circle,
            timer: circleObject.timer,
            scheduledFor: circleObject.scheduledFor,
            dateIncrement: circleObject.dateIncrement,
            reply: circleObject.reply,
            storageID: circleObject.storageID,
            replyUserID: circleObject.replyUserID,
            replyUsername: circleObject.replyUsername,
            taggedUsers: circleObject.taggedUsers,
            ratchetIndexes: []);
        cacheObject.initDates();
        cacheObject.circle = circleObject.circle;
      } else {
        cacheObject = circleObject;
      }

      cacheObject.userCircleCache = userCircleCache;
      cacheObject.userFurnace = userFurnace;
      cacheObject.body = circleObject.body;
      cacheObject.transferPercent = 0;
      cacheObject.video = CircleVideo(
          videoState: VideoStateIC.UPLOADING_VIDEO,
          extension: FileSystemService.getExtension(video.path),
          sourceVideo: video.path,
          streamable: streamable);

      if (streamable)
        cacheObject.fullTransferState = BlobState.UPLOADING;
      else
        cacheObject.fullTransferState = BlobState.ENCRYPTING;

      cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);

      await TableUserCircleCache.updateLastItemUpdate(circleObject.circle!.id,
          circleObject.creator!.id, DateTime.now().toLocal());

      cacheObject.video!.caching = true;

      ///refresh the circle
      callbackBloc.sinkCircleObjectSave(cacheObject);

      bool alreadyCached = false;
      String videoPath = VideoCacheService.returnVideoPath(cacheObject,
          userCircleCache.circlePath!, cacheObject.video!.extension!);
      String preview = VideoCacheService.returnPreviewPath(
          cacheObject, userCircleCache.circlePath!);

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

        VideoCacheService.setSize(cacheObject, preview);
      } else {
        //cache the video
        try {
          cachedVideo = await VideoCacheService.cacheVideo(
              userCircleCache, cacheObject, video);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          try {
            cachedVideo = await VideoCacheService.cacheVideo(
                userCircleCache, cacheObject, video);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            cacheObject.retries = RETRIES.MAX_VIDEO_UPLOAD_RETRIES;
            await _circleObjectService.cacheCircleObject(cacheObject);
            callbackBloc.sinkCircleObjectSave(cacheObject);

            rethrow;
          }
        }

        //cache the preview
        try {
          thumbnail = await VideoCacheService.cacheVideoPreview(
              tempPreview,
              userCircleCache,
              cacheObject,
              cachedVideo,
              thumbNailFrame,
              orientationNeeded);

          if (globalState.isDesktop()) {
            cacheObject.video!.previewBytes = thumbnail.readAsBytesSync();
          }
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          try {
            thumbnail = await VideoCacheService.cacheVideoPreview(
                tempPreview,
                userCircleCache,
                cacheObject,
                cachedVideo,
                thumbNailFrame,
                orientationNeeded);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            //user the default image background from the assets folder
            String previewPath = VideoCacheService.returnPreviewPath(
                cacheObject, userCircleCache.circlePath!);
            thumbnail = File(previewPath);

            final byteData =
                await rootBundle.load('assets/images/nopreview.jpg');

            await thumbnail.writeAsBytes(byteData.buffer
                .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          }
        }
      }

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, cacheObject);

      if (globalState.isDesktop()) {
        cacheObject.video!.caching = false;
        cacheObject.video!.previewBytes = thumbnail.readAsBytesSync();
        cacheObject.video!.videoBytes = cachedVideo.readAsBytesSync();
      }

      callbackBloc.sinkCircleObjectSave(cacheObject);

      ///allow the screen to refresh
      await Future.delayed(const Duration(milliseconds: 100)); //add a wait

      ///add to the processing queue
      _queue.add(QueueObject(
          circleObject: cacheObject,
          thumbnail: thumbnail,
          video: cachedVideo,
          source: video));

      ///process queue if full
      _isQueueFull(userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.cacheObjectUpdateScreen: $error");

      _globalEventBloc.removeOnError(circleObject);

      showRetry(circleObject, callbackBloc);
    }
  }

  _isQueueFull(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) {
    ///check to see if queue is full
    if (_queue.length == _queueCount) {
      processQueue(userCircleCache, userFurnace, callbackBloc);
    }
  }

  processQueue(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) async {
    if (_queue.length < 4) {
      _processingCount = _queue.length;

      ///count is less than 4 so just process all of them
      for (QueueObject queueObject in _queue) {
        _processObject(
            queueObject,
            queueObject.circleObject.userCircleCache ?? userCircleCache,
            queueObject.circleObject.userFurnace ?? userFurnace,
            callbackBloc);
      }
    } else if (_queue.isNotEmpty) {
      if (_queue.length >= 3)
        _processingCount = 3;
      else
        _processingCount = _queue.length;

      for (int i = 0; i < _queue.length; i++) {
        _processObject(
            _queue[i],
            _queue[i].circleObject.userCircleCache ?? userCircleCache,
            _queue[i].circleObject.userFurnace ?? userFurnace,
            callbackBloc);

        if (i == 2) break; //only process 3
      }
    }
  }

  _processObject(QueueObject queueObject, UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObjectBloc callbackBloc) async {
    try {
      ///allow the screen to refresh
      await Future.delayed(const Duration(milliseconds: 100)); //add a wait

      await _postSteps(
          userCircleCache,
          userFurnace,
          queueObject.circleObject,
          queueObject.source,
          queueObject.video,
          queueObject.thumbnail,
          callbackBloc);

      ///success, remove it from the queue
      _queue.remove(queueObject);
      _processingCount--;

      _processNextBatch(
        userCircleCache,
        userFurnace,
        callbackBloc,
      );
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.post: $error");

      _globalEventBloc.removeOnError(queueObject.circleObject);

      showRetry(queueObject.circleObject, callbackBloc);
    }
  }

  _processNextBatch(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) {
    if (_processingCount == 0) {
      processQueue(userCircleCache, userFurnace, callbackBloc);
    }
  }

  _postSteps(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File source,
      File full,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    try {
      await _stepIsConnected(userCircleCache, userFurnace, circleObject, full,
          thumbnail, callbackBloc);
      await _stepGetURls(userCircleCache, userFurnace, circleObject, full,
          thumbnail, callbackBloc);
      circleObject = await _encryptFiles(
          userCircleCache, userFurnace, circleObject, full, thumbnail);

      circleObject.cancelToken = CancelToken();

      await _postThumbnail(
          userCircleCache, userFurnace, circleObject, thumbnail);

      await _postFull(userCircleCache, userFurnace, circleObject, full,
          maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);

      await _postObjectOnly(userCircleCache, userFurnace, circleObject);

      ///Don't delete, this remove the cache for a shared object, and also, a stuck video might lose the file in the filepicker cache
      //FileSystemService.safeDelete(source); //don't wait
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _globalEventBloc.removeOnError(circleObject);

      if (_queue.indexWhere(
              (element) => element.circleObject.seed == circleObject.seed) >
          -1) {
        showRetry(circleObject, callbackBloc);
      }
    }
  }

  _stepIsConnected(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File full,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        if (await Network.isConnected()) {
          success = true;
        } else {
          throw ('connection not detected');
        }
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleImageBloc._stepIsConnected: $err");

        circleObject.retries += 1;
        await Future.delayed(const Duration(milliseconds: 200)); //add a wait
        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));
  }

  _stepGetURls(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File full,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        //throw ('fail');

        BlobUrl? blobUrl = await _circleVideoService.getUploadUrls(
            userCircleCache,
            userFurnace,
            circleObject,
            full,
            thumbnail,
            callbackBloc);

        if (blobUrl != null) {
          circleObject.video!.preview = blobUrl.thumbnail;
          circleObject.video!.previewSize = thumbnail.lengthSync();
          circleObject.video!.video = blobUrl.fileName;
          circleObject.video!.videoSize = full.lengthSync();
          circleObject.video!.location = blobUrl.location;
          circleObject.transferUrls = blobUrl;

          success = true;
        } else {
          throw ('could not get urls');
        }
      } catch (err) {
        //LogBloc.insertError(err, trace);
        if (err.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
          circleObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
          TableCircleObjectCache.deleteBySeed(circleObject.seed!);
          _globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
          _queue.removeWhere(
              (element) => element.circleObject.seed == circleObject.seed);
          _globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
          rethrow;
        } else {
          debugPrint("CircleImageBloc._stepGetURls: $err");

          circleObject.retries += 1;

          //add a wait
          await Future.delayed(const Duration(milliseconds: 200));

          if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    circleObject.retries = 0;
  }

  _encryptFiles(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject circleObject, File full, File thumbnail) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        debugPrint('blob encrypt start: ${DateTime.now()}');

        circleObject = await _circleVideoService.encryptFiles(
            userFurnace,
            userCircleCache,
            circleObject,
            full,
            thumbnail,
            circleObject.transferUrls!);

        circleObject.thumbnailTransferState = BlobState.UPLOADING;
        circleObject.fullTransferState = BlobState.UPLOADING;

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        debugPrint('blob encrypt stop: ${DateTime.now()}');

        success = true;
        return circleObject;
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("CircleVideoBloc._encryptFiles: $err");

        circleObject.retries += 1;

        //add a wait
        await Future.delayed(const Duration(milliseconds: 200));

        if (circleObject.retries >= RETRIES.MAX_VIDEO_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    circleObject.retries = 0;
  }

  _postThumbnail(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File thumbnail) async {
    try {
      await _circleVideoService.postThumbnail(
        userCircleCache,
        userFurnace,
        encryptedCopy,
      );

      File deleteFile;
      String path = VideoCacheService.returnPreviewPath(
          encryptedCopy, userCircleCache.circlePath!);

      if (globalState.isDesktop()) {
        ///keep the encrypted file and remove the unencrypted
        deleteFile = File(path);

        if (await deleteFile.exists()) {
          try {
            deleteFile.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }

        File renameEncrypted = File("${path}enc");

        if (await renameEncrypted.exists()) {
          await renameEncrypted.rename(path);
        }
      } else {
        ///remove the encrypted thumbnail
        deleteFile = File(("${path}enc"));

        if (await deleteFile.exists()) {
          try {
            deleteFile.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }
      }

      encryptedCopy.thumbnailTransferState = BlobState.UPLOADED_BLOB_ONLY;
      encryptedCopy.fullTransferState = BlobState.UPLOADING;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted image");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint("CircleImageBloc._postThumbnail: $err");
      //showRetry(encryptedCopy, callbackBloc);
      rethrow;
    }
  }

  _postFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File full,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      encryptedCopy.retries = 0;

      late File enc;

      if (encryptedCopy.video!.streamable!)
        enc = File((VideoCacheService.returnVideoPath(
            encryptedCopy,
            userCircleCache.circlePath!,
            FileSystemService.getExtension(full.path))));
      else
        enc = File(
            ("${VideoCacheService.returnVideoPath(encryptedCopy, userCircleCache.circlePath!, FileSystemService.getExtension(full.path))}enc"));

      await _circleVideoService.postFull(
          userCircleCache, userFurnace, encryptedCopy, enc,
          maxRetries);

      encryptedCopy.transferPercent = 100;
      encryptedCopy.fullTransferState = BlobState.UPLOADED_BLOB_ONLY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted video");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);

      if (globalState.isDesktop() && !encryptedCopy.video!.streamable!) {
        File deleteFile;
        String path = VideoCacheService.returnVideoPath(
            encryptedCopy,
            userCircleCache.circlePath!,
            FileSystemService.getExtension(full.path));

        ///keep the encrypted file and remove the unencrypted
        deleteFile = File(path);

        if (await deleteFile.exists()) {
          try {
            deleteFile.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }

        File renameEncrypted = File("${path}enc");

        await renameEncrypted.rename(path);
      } else {
        ///remove the encrypted video
        if (!encryptedCopy.video!.streamable!) {
          //remove the encrypted copy
          if (await enc.exists()) {
            try {
              enc.delete();
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
              debugPrint('$err');
            }
          }
        }
      }
    } catch (err) {
      debugPrint("CircleImageBloc._postFull: $err");
      rethrow;
    }
  }

  _postObjectOnly(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject circleObject) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        circleObject = await _circleVideoService.postCircleVideo(
            userFurnace, userCircleCache, circleObject);

        if (circleObject.id != null) {
          success = true;

          if (userCircleCache.guarded != true &&
              (userCircleCache.hidden != true ||
                  userCircleCache.hiddenOpen == true)) {
            circleObject.userCircleCache = userCircleCache;
            circleObject.userFurnace = userFurnace;
            _globalEventBloc.broadcastMemCacheCircleObjectsAdd([circleObject]);
          }
        } else
          throw ('could not save object');
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("CircleVideoBloc._postObjectOnly: $err");

        circleObject.retries += 1;

        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
          rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));
  }

  notifyWhenItemPreviewReady(UserFurnace? userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject, AlbumItem item) async {
    try {
      if (circleObject.draft) return;

      String previewPath = VideoCacheService.returnExistingAlbumVideoPath(userCircleCache.circlePath!, circleObject, item.video!.preview!);

      if (VideoCacheService.isAlbumPreviewCached(circleObject, userCircleCache.circlePath!, item))
      {
        File preview = File(previewPath);

        int length = await preview.length();

        if (length == item.video!.previewSize ||
            item.video!.previewSize == 0) {
          item.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
          _globalEventBloc.broadcastItemPreviewDownloaded(item);
        }
      } else {
        //make sure it's not already being downloaded
        if (_globalEventBloc.albumThumbnailExists(item)) {
          debugPrint('called twice');
          return;
        }

        _globalEventBloc.thumbnailItems.add(item);

        debugPrint(
            'albumitem video state: ${item.video!.videoState}');

        _circleVideoService.downloadAlbumPreview(
            userFurnace!, userCircleCache, circleObject, processItemDownloadFailed, item);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoBloc.notifyWhenItemPreviewReady: $err");

      await processItemDownloadFailed(userFurnace!, userCircleCache, circleObject, item);
    }
  }

  notifyWhenPreviewReady(UserFurnace? userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    try {
      if (circleObject.draft) return;

      String previewPath = VideoCacheService.returnPreviewPath(
          circleObject, userCircleCache.circlePath!);

      if (VideoCacheService.isPreviewCached(
          circleObject, userCircleCache.circlePath!)) {
        File preview = File(previewPath);

        int length = await preview.length();

        if (length == circleObject.video!.previewSize ||
            circleObject.video!.previewSize == 0) {
          circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
          _globalEventBloc.broadcastPreviewDownloaded(circleObject);
        }
      } else {
        //make sure it's not already being downloaded
        if (_globalEventBloc.thumbnailExists(circleObject)) {
          debugPrint('called twice');
          return;
        }

        _globalEventBloc.thumbnailObjects.add(circleObject);

        debugPrint(
            'circleobject video state: ${circleObject.video!.videoState}');

        _circleVideoService.downloadPreview(
            userFurnace!, userCircleCache, circleObject, processDownloadFailed);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoBloc.notifyWhenPreviewReady: $err");

      await processDownloadFailed(userFurnace!, userCircleCache, circleObject);
    }
  }

  processItemDownloadFailed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject, AlbumItem item,
  {CancelToken? cancelToken, DownloadFailedReason? reason}) async {
    try {
      circleObject.retries += 1;
      circleObject.transferPercent = 0;

      debugPrint('${circleObject.retries}');

      if (reason != null) {
        ///run the decryption at least twice
        if (reason == DownloadFailedReason.decryption &&
          circleObject.retries >= 2) {
          await haltOnError(userFurnace, circleObject, false);
          return;
        }
      }

      //stop the download if in progress
      if (cancelToken != null) BlobService.safeCancel(cancelToken);
      BlobService.safeCancelTokens(circleObject);

      if (!VideoCacheService.isAlbumPreviewCached(circleObject, userCircleCache.circlePath!, item)) {
        File preview = File(VideoCacheService.returnExistingAlbumVideoPath(userCircleCache.circlePath!, circleObject, item.video!.preview!));

        if (preview.existsSync()) preview.delete();

        File video = File(VideoCacheService.returnExistingAlbumVideoPath(userCircleCache.circlePath!, circleObject, item.video!.video!));

        if (video.existsSync()) video.delete();

        if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          _circleVideoService.downloadAlbumPreview(userFurnace, userCircleCache, circleObject, processItemDownloadFailed, item);
        } else {
          item.video!.videoState = VideoStateIC.FAILED;
          await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
          _globalEventBloc.broadcastItemPreviewDownloaded(item);
        }

        return;
      }

      //assume the video failed
      File video = File(VideoCacheService.returnExistingAlbumVideoPath(
        userCircleCache.circlePath!, circleObject, item.video!.video!));

      if (video.existsSync()) video.delete();
      if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
        downloadAlbumVideo(userFurnace, userCircleCache, circleObject, item);
      } else {
        item.video!.videoState = VideoStateIC.FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastItemPreviewDownloaded(item);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleVideoBloc.processItemDownloadFailed: $error');

      processItemDownloadFailed(userFurnace, userCircleCache, circleObject, item);
    }
  }

  processDownloadFailed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject,
      {CancelToken? cancelToken, DownloadFailedReason? reason}) async {
    try {
      circleObject.retries += 1;
      circleObject.transferPercent = 0;

      debugPrint('${circleObject.retries}');

      if (reason != null) {
        ///run the decryption at least twice
        if (reason == DownloadFailedReason.decryption &&
            circleObject.retries >= 2) {
          await haltOnError(userFurnace, circleObject, false);
          return;
        }
      }

      //stop the download if in progress
      if (cancelToken != null) BlobService.safeCancel(cancelToken);
      BlobService.safeCancelTokens(circleObject);

      if (!VideoCacheService.isPreviewCached(
          circleObject, userCircleCache.circlePath!)) {
        File preview = File(VideoCacheService.returnPreviewPath(
            circleObject, userCircleCache.circlePath!));

        if (preview.existsSync()) preview.delete(); //might be a partial file

        File video = File(VideoCacheService.returnVideoPath(circleObject,
            userCircleCache.circlePath!, circleObject.video!.extension!));

        if (video.existsSync()) video.delete();

        if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          _circleVideoService.downloadPreview(userFurnace, userCircleCache,
              circleObject, processDownloadFailed);
        } else {
          circleObject.video!.videoState = VideoStateIC.FAILED;
          await TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
          _globalEventBloc.broadcastPreviewDownloaded(circleObject);
        }

        return;
      }

      //assume the video failed
      File video = File(VideoCacheService.returnVideoPath(circleObject,
          userCircleCache.circlePath!, circleObject.video!.extension!));

      if (video.existsSync()) video.delete();
      if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
        downloadVideo(userFurnace, userCircleCache, circleObject);
      } else {
        circleObject.video!.videoState = VideoStateIC.FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastPreviewDownloaded(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoBloc.processDownloadFailed: $err');

      processDownloadFailed(userFurnace, userCircleCache, circleObject);
    }
  }

  downloadAlbumVideo(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, AlbumItem albumItem) async {
    try {
      if (albumItem.video!.streamable == true) {
        albumItem.video!.streamableCached = true;
      }

      albumItem.video!.videoState = VideoStateIC.DOWNLOADING_VIDEO;

      await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, circleObject);

      _circleVideoService.getAlbumVideo(
        userFurnace, userCircleCache, circleObject, albumItem, processItemDownloadFailed);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleVideoBloc.downloadAlbumVideo: $error');

      processItemDownloadFailed(userFurnace, userCircleCache, circleObject, albumItem);
    }
  }

  downloadVideo(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject) async {
    try {
      if (circleObject.video!.streamable == true)
        circleObject.video!.streamableCached = true;

      circleObject.video!.videoState = VideoStateIC.DOWNLOADING_VIDEO;

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _circleVideoService.get(
          userFurnace, userCircleCache, circleObject, processDownloadFailed);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoBloc.downloadVideo: $err");

      processDownloadFailed(userFurnace, userCircleCache, circleObject);
    }
  }

  removeFromDeviceCache(List<CircleObject> circleObjects) async {
    await FileSystemService.returnCirclesDirectory(
        globalState.user.id!, DeviceOnlyCircle.circleID);

    await TableCircleObjectCache.deleteList(_globalEventBloc, circleObjects);

    /* for (var circleObject in circleObjects) {
      ImageCacheService.deleteCircleObjectImage(circlePath, circleObject.seed!);
    }

    */
  }

  Future<List<CircleObject>> cacheToDevice(
    MediaCollection mediaCollection,
  ) async {
    List<CircleObject> circleObjects = [];

    try {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      for (var video in mediaCollection.media) {
        if (video.mediaType != MediaType.video) continue;

        CircleObject cacheObject = CircleObject(
            type: CircleObjectType.CIRCLEVIDEO,
            creator: globalState.user,
            body: '',
            circle:
                Circle(id: DeviceOnlyCircle.circleID, privacyShareImage: true),
            ratchetIndexes: []);

        cacheObject.userCircleCache = UserCircleCache(
            circlePath: circlePath, prefName: DeviceOnlyCircle.prefName);

        cacheObject.initDates();

        cacheObject.storageID =
            video.storageID.isEmpty ? const Uuid().v4() : video.storageID;
        cacheObject.id = cacheObject.seed;

        cacheObject.video = CircleVideo(
            videoState: VideoStateIC.VIDEO_READY,
            extension: FileSystemService.getExtension(video.path),
            sourceVideo: video.path,
            streamable: false);

        //cache the video
        File cachedVideo = await VideoCacheService.cacheVideo(
            cacheObject.userCircleCache!, cacheObject, video.file);

        //cache the preview

        late File thumbnail;
        try {
          thumbnail = await VideoCacheService.cacheVideoPreview(video.thumbnail,
              cacheObject.userCircleCache!, cacheObject, cachedVideo, 0, false);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          //user the default image background from the assets folder
          String previewPath = VideoCacheService.returnPreviewPath(
              cacheObject, cacheObject.userCircleCache!.circlePath!);
          thumbnail = File(previewPath);

          final byteData = await rootBundle.load('assets/images/nopreview.jpg');

          await thumbnail.writeAsBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }

        ///TODO don't delete the source. It may be being used in another circle. Garbage collect later
        //video.file.delete();

        cacheObject.userFurnace = globalState.userFurnace;

        cacheObject.video!.previewSize = thumbnail.lengthSync();
        cacheObject.video!.videoSize = cachedVideo.lengthSync();

        cacheObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;

        cacheObject.thumbnailTransferState = BlobState.READY;
        cacheObject.fullTransferState = BlobState.READY;

        //Object has been cached
        cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);

        circleObjects.add(cacheObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.cacheToDevice: $error");
    }

    return circleObjects;
  }

  haltOnError(
      UserFurnace userFurnace, CircleObject circleObject, bool upload) async {
    ///remove the object
    BlobService.safeCancelTokens(circleObject);
    circleObject.retries = upload
        ? RETRIES.MAX_VIDEO_UPLOAD_RETRIES
        : RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES;
    circleObject.thumbnailTransferState =
        upload ? BlobState.BLOB_UPLOAD_FAILED : BlobState.BLOB_DOWNLOAD_FAILED;
    await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, circleObject);
    _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
    _globalEventBloc.removeOnError(circleObject);
  }
}
