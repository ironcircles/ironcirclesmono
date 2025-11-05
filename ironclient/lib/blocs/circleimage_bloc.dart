import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/circleimage_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class SelectedMedia {
  bool hiRes = false;
  bool streamable = false;
  final bool album ;
  MediaCollection mediaCollection;
  UserFurnace? userFurnace;
  String caption;

  SelectedMedia(
      {required this.mediaCollection,
      required this.hiRes,
      required this.streamable,
      required this.album,
      this.caption = '',
      this.userFurnace});
}

class QueueObject {
  CircleObject circleObject;
  File thumbnail;
  File full;
  File source;

  QueueObject(
      {required this.circleObject,
      required this.thumbnail,
      required this.full,
      required this.source});
}

class CircleImageBloc {
  final ImageCacheService _imageCacheService = ImageCacheService();
  late CircleImageService _circleImageService; // = CircleImage2Service();
  final CircleObjectService _circleObjectService = CircleObjectService();
  late GlobalEventBloc _globalEventBloc;

  final List<QueueObject> _queue = [];
  int _queueCount = 0;
  int _processingCount = 0;

  CircleImageBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _circleImageService = CircleImageService(globalEventBloc);
  }

  //deprecated
  final _imageSaved = PublishSubject<CircleObject>();
  Stream<CircleObject> get imageSaved => _imageSaved.stream;

  final _putFailed = PublishSubject<int>();
  Stream<int> get putFailed => _putFailed.stream;

  dispose() async {
    // await _initCache.drain();
    //  _initCache.close();

    // await _itemCached.drain();
    // _itemCached.close();

    await _imageSaved.drain();
    _imageSaved.close();

    //await _markupCached.drain();
    //_markupCached.close();

    await _putFailed.drain();
    _putFailed.close();
  }

  removeInProgressPost(CircleObject circleObject) {
    _globalEventBloc.removeOnError(circleObject);
    _queue.removeWhere(
        (element) => element.circleObject.seed == circleObject.seed);
  }

  put(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject circleObject, CircleObjectBloc callbackBloc, File image,
      {hiRes = false}) async {
    String thumbnailPath = '';
    String fullImagePath = '';

    try {
      if (image.lengthSync() > EncryptBlob.maxForEncrypted) {
        _putFailed.sink.add(BlobFailed.FILETOOLARGE);

        return;
      }

      imageLib.Image? fileImage = imageLib.decodeImage(image.readAsBytesSync());

      if (fileImage == null) throw ('could not load image');

      ThumbnailDimensions thumbnailDimensions =
          ThumbnailDimensions.getDimensionsFromFile(image);

      if (circleObject.body != null)
        circleObject.body = circleObject.body!.trim();
      circleObject = await _circleObjectService.cacheCircleObject(circleObject);
      circleObject.thumbnailTransferState = BlobState.ENCRYPTING;
      circleObject.fullTransferState = BlobState.ENCRYPTING;
      circleObject.editing = true;

      //add them to globalevents so we don't process twice
      _globalEventBloc.addThumbandFull(circleObject);

      //refresh the circle
      callbackBloc.sinkCircleObjectSave(circleObject);

      //cache
      thumbnailPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject);

      fullImagePath = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, circleObject);

      imageCache.clear();
      PaintingBinding.instance.imageCache.clear();

      File thumbnail = File(thumbnailPath);
      File full = File(fullImagePath);

      if (thumbnail.existsSync()) await thumbnail.delete();
      if (full.existsSync()) await full.delete();

      await cacheThumbandFull(userCircleCache, circleObject, thumbnailPath,
          fullImagePath, image, hiRes);

      imageCache.clear();

      circleObject.image = CircleImage(
        height: thumbnailDimensions.height,
        width: thumbnailDimensions.width,
        fullImageSize: full.lengthSync(),
        thumbnailSize: thumbnail.lengthSync(),
      );

      await _circleObjectService.cacheCircleObject(circleObject);
      circleObject.thumbnailTransferState = BlobState.ENCRYPTING;

      //refresh the circle
      callbackBloc.sinkCircleObjectSave(circleObject);

      await _postSteps(userCircleCache, userFurnace, circleObject, image, full,
          thumbnail, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.put: $error");

      _globalEventBloc.removeOnError(circleObject);

      showRetry(circleObject, callbackBloc);
    }
  }

  cacheThumbandFull(
      UserCircleCache userCircleCache,
      CircleObject cacheObject,
      String thumbnailPath,
      String fullImagePath,
      File image,
      bool hiRes) async {
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
          cacheObject, thumbnailPath, fullImagePath, image, compress,
          hiRes: hiRes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      //compression probably failed

      try {
        //try it one more time
        await _imageCacheService.copyFullAndThumbnail(
            cacheObject, thumbnailPath, fullImagePath, image, compress,
            hiRes: hiRes);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        //TODO this could cause scrolling nightmares, memory consumption, etc

        //use the full file
        await image.copy(thumbnailPath);
        await image.copy(fullImagePath);

        LogBloc.insertLog("Could not compress image, used full",
            "ImageBloc: ${userCircleCache.user!}");
      }
    }
  }

  showRetry(
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
  ) async {
    circleObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
    await _circleObjectService.cacheCircleObject(circleObject);

    _globalEventBloc.removeOnError(circleObject);

    callbackBloc.sinkCircleObjectSave(circleObject);
  }

  _postHotSwapImage(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject encryptedCopy,
      File source,
      File thumbnail,
      CircleObjectBloc callbackBloc,
      {File? encryptedSource}) async {
    ///FOR TESTING
    // await _postFull(userCircleCache, userFurnace, encryptedCopy, encryptedSource!);

    //return;

    String fullImagePath = ImageCacheService.returnFullImagePath(
        userCircleCache.circlePath!, encryptedCopy);
    File fullImage = File(fullImagePath);

    if (fullImage.existsSync()) {
      await FileSystemService.safeDelete(fullImage);
    }

    //create file
    await _imageCacheService.createFullFallback(
        encryptedCopy, fullImagePath, source);

    encryptedCopy.image!.fullImageSize = fullImage.lengthSync();

    encryptedCopy = await _circleImageService.encryptHotSwap(
      userCircleCache,
      userFurnace,
      encryptedCopy,
      source,
    );

    await _stepGetURls(userCircleCache, userFurnace, encryptedCopy, fullImage,
        thumbnail, callbackBloc);

    await _postFull(userCircleCache, userFurnace, encryptedCopy, fullImage);
  }

  /// upload circle images
  uploadCircleImages(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      List<Media> mediaCollection,
      //List<File> images,
      bool hiRes) async {
    try {
      //debugPrint("UserCircle path: ${userCircleCache.circlePath}");

      bool first = true;

      _queueCount = mediaCollection.length;

      debugPrint('seed: ${circleObject.seed}');

      ///Cache the objects
      for (Media media in mediaCollection) {
        late CircleObject individual;

        ///TODO this needs to change to support guaranteed order of messages
        if (first) {
          individual = circleObject;
          if (individual.body != null)
            individual.body = individual.body!.trim();
          first = false;
        } else {
          individual = CircleObject.prepNewCircleObject(
              userCircleCache, userFurnace, '', 0, null,
              type: CircleObjectType.CIRCLEIMAGE);
          individual.timer = circleObject.timer;
        }

        //individual.type = CircleObjectType.CIRCLEIMAGE;
        individual.storageID = media.storageID;

        ///this is async, next steps are dependant on the function
        await cacheObjectUpdateScreen(userCircleCache, userFurnace, individual,
            callbackBloc, File(media.path), hiRes);

        await Future.delayed(const Duration(milliseconds: 100));
      }

      ///process queue
      _isQueueFull(userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.saveCircleImagesFromAssets: $error");
    }
  }

   cacheObjectUpdateScreen(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject cacheObject,
    CircleObjectBloc callbackBloc,
    File image,
    bool hiRes,
  ) async {
    //int width = 0;
    //int height = 0;

    //CircleObject cacheObject = circleObject;
    String thumbnailPath = '';
    String fullImagePath = '';

    try {
      if (image.lengthSync() > EncryptBlob.maxForEncrypted) {
        _putFailed.sink.add(BlobFailed.FILETOOLARGE);

        return;
      }

      ThumbnailDimensions thumbnailDimensions =
          ThumbnailDimensions.getDimensionsFromFile(image);

      if (cacheObject.storageID == null || cacheObject.storageID!.isEmpty) {
        cacheObject.storageID = const Uuid().v4();
      }

      ///add them to globalevents so we don't process twice
      _globalEventBloc.addThumbandFull(cacheObject);

      ///cache
      thumbnailPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, cacheObject);

      fullImagePath = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, cacheObject);

      File thumbnail = File(thumbnailPath);
      File full = File(fullImagePath);

      await cacheThumbandFull(userCircleCache, cacheObject, thumbnailPath,
          fullImagePath, image, hiRes);

      cacheObject.image = CircleImage(
        height: thumbnailDimensions.height,
        width: thumbnailDimensions.width,
        fullImageSize: full.lengthSync(),
        thumbnailSize: thumbnail.lengthSync(),
      );
      cacheObject.image!.fullFile = full;
      cacheObject.image!.thumbnailFile = thumbnail;

      cacheObject.thumbnailTransferState = BlobState.CACHED;
      cacheObject.fullTransferState = BlobState.CACHED;

      //Object has been cached
      await _circleObjectService.cacheCircleObject(cacheObject);

      cacheObject.thumbnailTransferState = BlobState.ENCRYPTING;
      cacheObject.fullTransferState = BlobState.ENCRYPTING;

      if (globalState.isDesktop()) {
        cacheObject.image!.imageBytes = thumbnail.readAsBytesSync();
        // _globalEventBloc.broadcastMemCacheCircleObjectsAdd([circleObject]);
      }

      ///refresh the circle
      callbackBloc.sinkCircleObjectSave(cacheObject);

      ///allow the screen to refresh
      await Future.delayed(const Duration(milliseconds: 100)); //add a wait

      ///add to the processing queue
      _queue.add(QueueObject(
          circleObject: cacheObject,
          thumbnail: thumbnail,
          full: full,
          source: image));
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.post: $error");

      _globalEventBloc.removeOnError(cacheObject);

      showRetry(cacheObject, callbackBloc);
    }

    return;
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
        ///use the object's hitchhikers if they exist

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
          queueObject.full,
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

  post(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
    File image,
    bool hiRes,
  ) async {
    //int width = 0;
    //int height = 0;

    CircleObject cacheObject = circleObject;
    String thumbnailPath = '';
    String fullImagePath = '';

    try {
      if (image.lengthSync() > EncryptBlob.maxForEncrypted) {
        _putFailed.sink.add(BlobFailed.FILETOOLARGE);

        return;
      }

      ThumbnailDimensions thumbnailDimensions =
          ThumbnailDimensions.getDimensionsFromFile(image);

      cacheObject = CircleObject(
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
      cacheObject.storageID = const Uuid().v4();

      //add them to globalevents so we don't process twice
      _globalEventBloc.addThumbandFull(cacheObject);

      //cache
      thumbnailPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, cacheObject);

      fullImagePath = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, cacheObject);

      File thumbnail = File(thumbnailPath);
      File full = File(fullImagePath);

      await cacheThumbandFull(userCircleCache, cacheObject, thumbnailPath,
          fullImagePath, image, hiRes);

      cacheObject.image = CircleImage(
        height: thumbnailDimensions.height,
        width: thumbnailDimensions.width,
        fullImageSize: full.lengthSync(),
        thumbnailSize: thumbnail.lengthSync(),
      );

      cacheObject.thumbnailTransferState = BlobState.CACHED;
      cacheObject.fullTransferState = BlobState.CACHED;

      //Object has been cached
      await _circleObjectService.cacheCircleObject(cacheObject);

      cacheObject.thumbnailTransferState = BlobState.ENCRYPTING;
      cacheObject.fullTransferState = BlobState.ENCRYPTING;

      ///add the hitchhikers
      cacheObject.userCircleCache = userCircleCache;
      cacheObject.userFurnace = userFurnace;

      //refresh the circle
      callbackBloc.sinkCircleObjectSave(cacheObject);

      await _postSteps(userCircleCache, userFurnace, cacheObject, image, full,
          thumbnail, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.post: $error");

      _globalEventBloc.removeOnError(circleObject);
      showRetry(circleObject, callbackBloc);
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
      ///debugprint the seed and usercirclecache
      // debugPrint(
      //     "seed: ${circleObject.seed}, userCircleCache: ${userCircleCache.usercircle!}");
      // debugPrint("userCircleCache: ${userCircleCache.circlePath}");

      await _stepIsConnected(userCircleCache, userFurnace, circleObject, full,
          thumbnail, callbackBloc);

      await _stepGetURls(userCircleCache, userFurnace, circleObject, full,
          thumbnail, callbackBloc);

      circleObject = await _encryptFiles(userCircleCache, userFurnace,
          circleObject, full, thumbnail, callbackBloc);

      circleObject.cancelToken = CancelToken();

      await _postThumbnail(
          userCircleCache, userFurnace, circleObject, thumbnail);

      //debugPrint("start post full");

      try {
        await _postFull(userCircleCache, userFurnace, circleObject, full,
            maxRetries: RETRIES.MAX_IMAGE_UPLOAD_RETRIES_BEFORE_HOTSWAP);

        //debugPrint("post full success");
      } catch (err) {
        LogBloc.insertLog(
            "Resorted to lower res image", "_postSteps: ${userFurnace.userid}");

        await _postHotSwapImage(userFurnace, userCircleCache, circleObject,
            source, thumbnail, callbackBloc,
            encryptedSource: full);
      }

      await _postObjectOnly(userCircleCache, userFurnace, circleObject);

      ///TODO Dont' delete the cache object, should garbage collect old files later
      ///FileSystemService.safeDelete(source); //don't wait
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

        BlobUrl? blobUrl = await _circleImageService.getUploadUrls(
          userCircleCache,
          userFurnace,
          circleObject,
          full,
          thumbnail,
        );

        if (blobUrl != null) {
          //print("IMAGESERVICEDEBUGGING - ${blobUrl.thumbnail}");
          //print("IMAGESERVICEDEBUGGING - ${blobUrl.fileName}");
          //print("IMAGESERVICEDEBUGGING - ${blobUrl.location}");

          circleObject.image!.thumbnail = blobUrl.thumbnail;
          circleObject.image!.fullImage = blobUrl.fileName;
          circleObject.image!.location = blobUrl.location;
          circleObject.transferUrls = blobUrl;

          success = true;
        } else {
          throw ('could not get urls');
        }
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleImageBloc._stepGetURls: $err");

        if (err.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
          circleObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
          TableCircleObjectCache.deleteBySeed(circleObject.seed!);
          _queue.removeWhere(
              (element) => element.circleObject.seed == circleObject.seed);
          _globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
          _globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
          rethrow;
        } else {
          circleObject.retries += 1;

          //add a wait
          await Future.delayed(const Duration(milliseconds: 200));

          if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    circleObject.retries = 0;
  }

  _encryptFiles(
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
        debugPrint('blob encrypt start: ${DateTime.now()}');

        circleObject = await _circleImageService.encryptFiles(
            userCircleCache,
            userFurnace,
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
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleImageBloc._encryptFiles: $err");

        circleObject.retries += 1;

        if (err.toString().contains("PathNotFoundException") &&
            circleObject.retries >= 2) {
          await haltOnError(
              userFurnace: userFurnace,
              circleObject: circleObject,
              upload: false);
          return;
        }

        //add a wait
        await Future.delayed(const Duration(milliseconds: 200));

        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    circleObject.retries = 0;
  }

  _postThumbnail(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File thumbnail) async {
    try {
      await _circleImageService.postThumbnail(
        userCircleCache,
        userFurnace,
        encryptedCopy,
      );
      File deleteThumb;

      String thumbnailPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, encryptedCopy);

      if (globalState.isDesktop()) {
        deleteThumb = File(thumbnailPath);

        if (await deleteThumb.exists()) {
          try {
            deleteThumb.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
          }
        }

        File renameEncrypted = File("${thumbnailPath}enc");

        await renameEncrypted.rename(thumbnailPath);
      } else {
        //remove the encrypted thumbnail
        deleteThumb = File("${thumbnailPath}enc");

        if (await deleteThumb.exists()) {
          try {
            deleteThumb.delete();
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

      await _circleImageService.postFull(
          userCircleCache, userFurnace, encryptedCopy, "", null,
          maxRetries: maxRetries);

      encryptedCopy.transferPercent = 100;
      encryptedCopy.fullTransferState = BlobState.UPLOADED_BLOB_ONLY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted image");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);

      File deleteFile;

      String path = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, encryptedCopy);

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

        await renameEncrypted.rename(path);
      } else {
        ///remove the encrypted file and keep the unencrypted
        deleteFile = File("${path}enc");

        if (await deleteFile.exists()) {
          try {
            deleteFile.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint('$err');
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
        ///RBR
        ///wait 4 seconds
        //await Future.delayed(const Duration(seconds: 20));

        late CircleObject savedObject;

        if (circleObject.id != null)
          savedObject = await _circleImageService.putCircleImage(
              userCircleCache, userFurnace, circleObject);
        else {
          savedObject = await _circleImageService.postCircleImage(
              userFurnace, userCircleCache, circleObject);
        }

        debugPrint('seed: ${circleObject.seed}');

        if (savedObject.id != null) {
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
        debugPrint("CircleImageService.sendCircleImageObject: $err");

        circleObject.retries += 1;

        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
          rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));
  }

  retryUpload(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File full,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    try {
      if (_globalEventBloc.thumbnailExists(circleObject))
        return;
      else
        _globalEventBloc.addThumbandFull(circleObject);

      if (circleObject.retries <= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
        ///RBR BUT TEST BEFORE REMOVING
        circleObject.transferUrls == null;

        if (circleObject.transferUrls == null)
          //LogBloc.insertLog('getting aws urls', 'retryUpload');
          await _stepGetURls(userCircleCache, userFurnace, circleObject, full,
              thumbnail, callbackBloc);

        bool passedGate = false;

        if (circleObject.thumbnailTransferState! >= BlobState.ENCRYPTED ||
            circleObject.fullTransferState! >= BlobState.ENCRYPTED) {
          if (circleObject.image!.fullSignature != null &&
              circleObject.image!.fullCrank != null &&
              circleObject.image!.thumbSignature != null &&
              circleObject.image!.thumbCrank != null &&
              circleObject.secretKey != null) passedGate = true;
        }

        if (!passedGate) {
          File encryptedThumb = File('${thumbnail.path}enc');
          File encryptedFull = File('${full.path}enc');

          try {
            if (encryptedFull.existsSync()) encryptedFull.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
                'CircleImageBloc.processImageFailed.deleteEncryptedThumbnail: $err');
          }

          try {
            if (encryptedThumb.existsSync()) encryptedThumb.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            debugPrint(
                'CircleImageBloc.processImageFailed.deleteEncryptedThumbnail: $err');
          }

          //LogBloc.insertLog('encrypting files', 'retryUpload');
          circleObject = await _encryptFiles(userCircleCache, userFurnace,
              circleObject, full, thumbnail, callbackBloc);
        }

        if (circleObject.thumbnailTransferState! <
            BlobState.UPLOADED_BLOB_ONLY) {
          //LogBloc.insertLog('postThumbnail', 'retryUpload');

          await _circleImageService.postThumbnail(
            userCircleCache,
            userFurnace,
            circleObject,
          );
          await _postFull(userCircleCache, userFurnace, circleObject, full,
              maxRetries: RETRIES.MAX_IMAGE_UPLOAD_RETRIES_BEFORE_HOTSWAP);
          await _postObjectOnly(userCircleCache, userFurnace, circleObject);
        } else if (circleObject.fullTransferState! <
            BlobState.UPLOADED_BLOB_ONLY) {
          //LogBloc.insertLog('postFull', 'retryUpload');
          await _circleImageService.postFull(
              userCircleCache, userFurnace, circleObject, "", null);
          await _postObjectOnly(userCircleCache, userFurnace, circleObject);
        } else {
          await _postObjectOnly(userCircleCache, userFurnace, circleObject);
        }
      } else
        showRetry(circleObject, callbackBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageBloc.retryUpload: $err');
      circleObject.retries += 1;
      await haltOnError(
          userFurnace: userFurnace, circleObject: circleObject, upload: true);
    }
  }

  notifyWhenThumbReady(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, CircleObjectBloc callbackBloc) async {
    try {
      if (circleObject.draft) return;

      if (circleObject.retries >= RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        if (circleObject.id != null) {
          //a state transition error occurred when moving from v32-v34

          if (ImageCacheService.isThumbnailCached(
              circleObject, userCircleCache.circlePath!, circleObject.seed!)) {
            circleObject.thumbnailTransferState = BlobState.READY;
            circleObject.fullTransferState = BlobState.READY;
            circleObject.retries = 0;
            TableCircleObjectCache.updateCacheSingleObject(
                userFurnace.userid!, circleObject);
          } else {
            return;
          }
        } else {
          return;
        }
      }

      ///ignore while transfer in progress
      if (circleObject.thumbnailTransferState == BlobState.ENCRYPTING ||
          circleObject.thumbnailTransferState == BlobState.DECRYPTING ||
          //circleObject.thumbnailTransferState == BlobState.UPLOADING ||
          //circleObject.thumbnailTransferState == BlobState.UPLOADED_BLOB_ONLY ||
          //circleObject.fullTransferState == BlobState.UPLOADED_BLOB_ONLY ||
          circleObject.fullTransferState == BlobState.UPLOADING ||
          circleObject.fullTransferState == BlobState.DOWNLOADING) {
        if (!_globalEventBloc.thumbnailExists(circleObject) &&
            circleObject.id == null &&
            circleObject.retries != -1 &&
            circleObject.thumbnailTransferState != BlobState.READY) {
          circleObject.retries = RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;
        }

        return;
      }

      if (circleObject.fullTransferState == BlobState.READY &&
          circleObject.id == null) {
        circleObject.retries = RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;

        return;
      }

      ///make sure it's not already being downloaded
      if (_globalEventBloc.thumbnailExists(circleObject)) {
        debugPrint('already in GlobalEventBloc');
        return;
      }

      // debugPrint('notifyWhenThumbReady');

      if (circleObject.seed == null) {
        debugPrint('this should not happen');
      }

      if (circleObject.id != null) {
        //debugPrint(circleObject.id!);
      }

      ///There was an edge case where an image decrypts but then loses it's size and dimensions
      ///We made it past the downloading check. If the size is 0, deal with it.
      ///TODO this works, but there is some kind of timing event, maybe related to touching a push notification, that is causing this to happen
      if (circleObject.image!.thumbnailSize == 0) {
        if (!_globalEventBloc.retryExists(circleObject)) {
          LogBloc.insertLog("Image in decrypting mode with no size",
              "CircleImageBloc.notifyWhenThumbReady");
          _globalEventBloc.addRetry(circleObject);
          callbackBloc.getSingleObject(
              userFurnace, circleObject.id!, userCircleCache);
        }
        return;
      }

      ///Is the thumbnail cached?
      if (ImageCacheService.isThumbnailCached(
          circleObject, userCircleCache.circlePath!, circleObject.seed!)) {
        if (circleObject.thumbnailTransferState != BlobState.READY) {
          circleObject.thumbnailTransferState = BlobState.READY;
          circleObject.retries = 0;
          TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
        }

        if (circleObject.image!.thumbnailFile == null) {
          circleObject.image!.thumbnailFile = File(
              ImageCacheService.returnThumbnailPath(
                  userCircleCache.circlePath!, circleObject));
        }

        ///check the full only
        if (!_globalEventBloc.fullExists(circleObject)) {
          if (!ImageCacheService.isFullImageCached(
              circleObject, userCircleCache.circlePath!, circleObject.seed!)) {
            processFullDownloadFailed(
                userFurnace, userCircleCache, circleObject);
          } else {
            if (circleObject.fullTransferState != BlobState.READY) {
              circleObject.fullTransferState = BlobState.READY;
              circleObject.retries = 0;
              TableCircleObjectCache.updateCacheSingleObject(
                  userFurnace.userid!, circleObject);
            }
          }
        }
      } else {
        if (circleObject.crank.isNotEmpty &&
            circleObject.ratchetIndexes.isEmpty) {
          throw ('ratchetIndexes not saved');
        }
        circleObject.thumbnailTransferState = BlobState.DOWNLOADING;
        circleObject.fullTransferState = BlobState.DOWNLOADING;

        _globalEventBloc.thumbnailObjects.add(circleObject);
        _globalEventBloc.fullObjects.add(circleObject);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        ///make sure the image isn't being uploaded
        if (circleObject.image == null) return;

        _circleImageService.get(userFurnace, userCircleCache, circleObject,
            processThumbnailDownloadFailed, processFullDownloadFailed);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _globalEventBloc.removeOnError(circleObject);
      debugPrint('CircleImageBloc.notifyWhenThumbReady: $err');

      processThumbnailDownloadFailed(
        userFurnace,
        userCircleCache,
        circleObject,
      );
    }
  }

  retryDownload(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
  ) async {
    processThumbnailDownloadFailed(userFurnace, userCircleCache, circleObject);

    if (!_globalEventBloc.fullExists(circleObject))
      processFullDownloadFailed(userFurnace, userCircleCache, circleObject);
  }

  haltOnError(
      {required UserFurnace userFurnace,
      required CircleObject circleObject,
      required bool upload,
      bool failUI = true}) async {
    ///remove the object
    BlobService.safeCancelTokens(circleObject);

    circleObject.retries = upload
        ? RETRIES.MAX_IMAGE_UPLOAD_RETRIES
        : RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;

    circleObject.thumbnailTransferState =
        upload ? BlobState.BLOB_UPLOAD_FAILED : BlobState.BLOB_DOWNLOAD_FAILED;

    await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, circleObject);

    _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
    _globalEventBloc.removeOnError(circleObject);
  }

  processThumbnailDownloadFailed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject,
      {DownloadFailedReason? reason}) async {
    try {
      debugPrint('processPreviewDownloadFailed');

      File thumbnail = File(ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject));

      circleObject.retries += 1;
      //debugPrint('${circleObject.retries}');

      if (reason != null) {
        ///run the mac at least twice
        if (reason == DownloadFailedReason.decryption &&
            circleObject.retries >= 2) {
          await haltOnError(
              userFurnace: userFurnace,
              circleObject: circleObject,
              upload: false);
          return;
        }
      }

      await FileSystemService.safeDelete(thumbnail);

      if (circleObject.retries < RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        circleObject.thumbnailTransferState = BlobState.DOWNLOADING;
        _globalEventBloc.thumbnailObjects.add(circleObject);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        _circleImageService.getThumbnail(userFurnace, userCircleCache,
            circleObject, processThumbnailDownloadFailed);
      } else {
        //remove
        circleObject.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageBloc.processImageDownloadFailed: $err');
      processThumbnailDownloadFailed(
          userFurnace, userCircleCache, circleObject);
    }
  }

  processFullDownloadFailed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject,
      {DownloadFailedReason? reason}) async {
    try {
      debugPrint('processImageDownloadFailed');

      File full = File(ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, circleObject));

      FileSystemService.safeDelete(full);

      circleObject.nonUIRetries++;
      //debugPrint('${circleObject.nonUIRetries}');

      if (reason != null) {
        ///run the mac at least twice
        if (reason == DownloadFailedReason.decryption &&
            circleObject.retries >= 2) {
          await haltOnError(
              userFurnace: userFurnace,
              circleObject: circleObject,
              upload: false,
              failUI: false);
          return;
        }
      }

      if (circleObject.nonUIRetries < 12) {
        circleObject.fullTransferState = BlobState.DOWNLOADING;

        _globalEventBloc.fullObjects.add(circleObject);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        _circleImageService.getFull(userFurnace, userCircleCache, circleObject,
            processFullDownloadFailed);
      } else {
        circleObject.fullTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageBloc.processImageDownloadFailed: $err');
      processFullDownloadFailed(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<File> cacheMarkup(Uint8List bytes) async {
    File retValue =
        await _imageCacheService.cacheMarkup(bytes); //async with callback

    return retValue;
  }

  /*
  callbackWithFile(File file) {
    _markupCached.sink.add(file);
  }

   */

  putAlbumCallback() {}

  putAlbum(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      List<File> images) async {
    /*
    try {
      //cache the CircleObject
      CircleObject cacheObject = CircleObject(
          type: circleObject.type,
          creator: circleObject.creator,
          circle: circleObject.circle,
          ratchetIndexes: []);
      cacheObject.initDates();

      cacheObject.body = circleObject.body;
      cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);
      cacheObject.thumbnailTransferState = BlobState.ENCRYPTING;
      cacheObject.fullTransferState = BlobState.ENCRYPTING;
      cacheObject.album = [];

      //refresh the circle
      callbackBloc.sinkCircleObjectSave(cacheObject);

      //create the circle images

      for (File pickedFile in images) {
        File image = File(pickedFile.path);

        /*if (image.lengthSync() > EncryptBlob.maxBeforeStream) {
          _putFailed.sink.add(BlobFailed.FILETOOLARGE);

          return;
        }

         */

        Image? fileImage = decodeImage(image.readAsBytesSync());

        if (fileImage == null) throw ('could not load image');

        late int width;
        late int height;
        late var orientation;

        if (fileImage.exif.data.containsKey(274)) {
          orientation = fileImage.exif.data[274];

          if (orientation == 1) {
            width = fileImage.width;
            height = fileImage.height;
          } else if (orientation == 3) {
            width = fileImage.width;
            height = fileImage.height;
          } else if (orientation == 6) {
            width = fileImage.height;
            height = fileImage.width;
          } else if (orientation == 8) {
            width = fileImage.height;
            height = fileImage.width;
          } else {
            width = fileImage.width;
            height = fileImage.height;
          }
        } else {
          width = fileImage.width;
          height = fileImage.height;
        }

        if (width > ImageConstants.THUMBNAIL_WIDTH) {
          double ratio = width / ImageConstants.THUMBNAIL_WIDTH;
          width = ImageConstants.THUMBNAIL_WIDTH.toInt();

          height = (height ~/ ratio);
        }

        CircleImage circleImage =
            CircleImage(width: width, height: height, seed: Uuid().v4());

        //cache
        String thumbnailPath = ImageCacheService.returnThumbnailPath(
            userCircleCache.circlePath!, circleImage.seed);

        String fullImagePath = ImageCacheService.returnFullImagePath(
            userCircleCache.circlePath!, circleImage.seed);

        await _imageCacheService.copyFullAndThumbnail(userCircleCache,
            cacheObject, thumbnailPath, fullImagePath, image, true);

        circleImage.thumbnailFile = File(thumbnailPath);
        circleImage.fullFile = File(fullImagePath);
        circleImage.fullImageSize = circleImage.fullFile!.lengthSync();
        circleImage.thumbnailSize = circleImage.thumbnailFile!.lengthSync();

        cacheObject.album!.add(circleImage);
      }

      //async with callback
      _circleAlbumService.put(userCircleCache, userFurnace, cacheObject,
          _processUploadFailed, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.put: " + error.toString());
    }

     */
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
    bool hiRes,
  ) async {
    String thumbnailPath = '';
    String fullImagePath = '';

    List<CircleObject> circleObjects = [];

    try {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      for (var image in mediaCollection.media) {
        if (image.mediaType != MediaType.image) continue;

        ThumbnailDimensions thumbnailDimensions =
            ThumbnailDimensions.getDimensionsFromFile(image.file);

        CircleObject cacheObject = CircleObject(
            type: CircleObjectType.CIRCLEIMAGE,
            creator: globalState.user,
            hiRes: hiRes,
            body: '',
            circle: Circle(id: DeviceOnlyCircle.circleID),
            ratchetIndexes: []);

        cacheObject.userCircleCache = UserCircleCache(circlePath: circlePath);

        cacheObject.initDates();

        cacheObject.seed = const Uuid().v4();
        cacheObject.id = cacheObject.seed;
        cacheObject.storageID =
            image.storageID.isEmpty ? const Uuid().v4() : image.storageID;

        //cache
        thumbnailPath =
            ImageCacheService.returnThumbnailPath(circlePath, cacheObject);

        fullImagePath =
            ImageCacheService.returnFullImagePath(circlePath, cacheObject);

        File thumbnail = File(thumbnailPath);
        File full = File(fullImagePath);

        await _imageCacheService.copyFullAndThumbnail(
            cacheObject, thumbnailPath, fullImagePath, image.file, true,
            hiRes: hiRes);

        cacheObject.image = CircleImage(
          height: thumbnailDimensions.height,
          width: thumbnailDimensions.width,
          fullImageSize: full.lengthSync(),
          thumbnailSize: thumbnail.lengthSync(),
        );

        cacheObject.thumbnailTransferState = BlobState.CACHED;
        cacheObject.fullTransferState = BlobState.CACHED;
        cacheObject.userFurnace = globalState.userFurnace;

        //Object has been cached
        cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);

        image.file.delete(); //remove the camera image

        circleObjects.add(cacheObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleImageBloc.cacheToDevice: $error");
    }

    return circleObjects;
  }
}
