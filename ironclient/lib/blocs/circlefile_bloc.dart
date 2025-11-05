import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circlefile.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/circlefile_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

class QueueObject {
  CircleObject circleObject;
  File queueFile;
  File source;

  QueueObject(
      {required this.circleObject,
      required this.queueFile,
      required this.source});
}

class CircleFileBloc {
  final CircleObjectService _circleObjectService = CircleObjectService();
  late CircleFileService _circleFileService;

  late GlobalEventBloc _globalEventBloc;

  List<QueueObject> _queue = [];
  int _queueCount = 0;
  int _processingCount = 0;

  CircleFileBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _circleFileService = CircleFileService(_globalEventBloc);
  }

  final _cacheDeleted = PublishSubject<CircleObject>();
  Stream<CircleObject> get cacheDeleted => _cacheDeleted.stream;

  dispose() async {
    _cacheDeleted.drain();
    _cacheDeleted.close();
  }

  Future<CircleObject> cancelFileTransfer(
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    //circleObject.file.fileState = FileState.UNKNOWN;

    _queue.removeWhere(
        (element) => element.circleObject.seed == circleObject.seed);

    _globalEventBloc.fullObjects.remove(circleObject);

    BlobService.safeCancelTokens(circleObject);

    if (circleObject.fullTransferState == BlobState.UPLOADING) {
      await TableCircleObjectCache.deleteBySeed(circleObject.seed!);
      _globalEventBloc.broadCastMemCacheCircleObjectsRemove([circleObject]);
    } else if (circleObject.fullTransferState == BlobState.UPLOADING) {
      circleObject.fullTransferState = BlobState.UNKNOWN;
      circleObject.retries = 0;
      circleObject.transferPercent = 0;

      await TableCircleObjectCache.updateCacheSingleObject(
          userCircleCache.user!, circleObject);
    }

    if (FileCacheService.isFileCached(
        circleObject, userCircleCache.circlePath!)) {
      FileCacheService.deleteFile(userCircleCache.circlePath!, circleObject);
    }

    return circleObject;
  }

  deleteCache(
      String userID, String circlePath, CircleObject circleObject) async {
    await _circleFileService.deleteCache(userID, circlePath, circleObject);

    _cacheDeleted.sink.add(circleObject);
  }

  cleanCache(List<String> createdFiles, CircleObject circleObject) async {
    try {
      if (circleObject.file!.sourceFile != null) {
        for (String filePath in createdFiles) {
          if (FileSystemService.getFilename(filePath) ==
              FileSystemService.getFilename(circleObject.file!.sourceFile!))
            File(circleObject.file!.sourceFile!).delete();
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleFileBloc.cleanCache: $err');
    }
  }

  retryUpload(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File file,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    try {
      debugPrint(
          'CircleFileBloc.processFileFailed processed: ${circleObject.retries}');

      _globalEventBloc.addFull(circleObject);

      if (circleObject.retries > RETRIES.MAX_VIDEO_UPLOAD_RETRIES) {
        showRetry(circleObject, callbackBloc);
        return;
      }

      ///user will have to manually resend

      if (circleObject.transferUrls == null)
        await _stepGetURls(
            userCircleCache, userFurnace, circleObject, file, callbackBloc);

      bool passedGate = false;

      //Second Gate - Check to see if encryption finished
      //do the encrypted files exist and do they match the size of the original?
      File encryptedFull = File('${file.path}enc');
      try {
        if (encryptedFull.existsSync()) encryptedFull.delete();
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint('CircleFileBloc.processFileFailed.encryptedFull: $err');
      }

      circleObject =
          await _encryptFiles(userCircleCache, userFurnace, circleObject, file);

      passedGate = false;

      if (circleObject.fullTransferState! < BlobState.UPLOADED_BLOB_ONLY) {
        //LogBloc.insertLog('postThumbnail', 'retryUpload');

        await _circleFileService.postFile(
            userCircleCache, userFurnace, circleObject, encryptedFull,
            maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);
        await _postObjectOnly(userCircleCache, userFurnace, circleObject);
      } else {
        await _postObjectOnly(userCircleCache, userFurnace, circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleFileBloc.processFileFailed: $err');

      //increment the retries
      circleObject.retries = circleObject.retries + 1;
      circleObject = await _circleObjectService.cacheCircleObject(circleObject);

      retryUpload(userCircleCache, userFurnace, circleObject, file, thumbnail,
          callbackBloc);
    }
  }

  /// upload circle file
  uploadFiles(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      List<Media> mediaCollection) async {
    try {
      bool first = true;

      _queueCount = mediaCollection.length;

      ///save just the circleobjects
      for (Media media in mediaCollection) {
        late CircleObject individual;

        if (first) {
          individual = circleObject;
          if (individual.body != null)
            individual.body = individual.body!.trim();
          first = false;
        } else {
          individual = CircleObject.prepNewCircleObject(
              userCircleCache, userFurnace, '', 0, null, type: CircleObjectType.CIRCLEFILE);
          individual.timer = circleObject.timer;
        }

       // individual.type = CircleObjectType.CIRCLEFILE;

        debugPrint(
            'file block - network user: ${individual.userFurnace!.userid}, usercirclecache user: ${individual.userCircleCache!.user}, seed: ${individual.seed}');

        ///this is async, next steps are dependant on the function
        cacheObjectUpdateScreen(userCircleCache, userFurnace, individual,
            callbackBloc, File(media.path),
            name: media.name);

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleObjectBloc.saveCircleImagesFromAssets: $error");
    }
  }

  uploadFile(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
    File file,
  ) async {
    _queueCount = 1;

    cacheObjectUpdateScreen(
      userCircleCache,
      userFurnace,
      circleObject,
      callbackBloc,
      file,
    );
  }

  cacheObjectUpdateScreen(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      CircleObjectBloc callbackBloc,
      File file,
      {String name = ''}) async {
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
            replyUserID: circleObject.replyUserID,
            replyUsername: circleObject.replyUsername,
            taggedUsers: circleObject.taggedUsers,
            ratchetIndexes: []);
        cacheObject.initDates();
      } else {
        cacheObject = circleObject;
      }

      cacheObject.userFurnace = userFurnace;
      cacheObject.userCircleCache = userCircleCache;
      cacheObject.body = circleObject.body;
      cacheObject.transferPercent = 0;
      cacheObject.fullTransferState = BlobState.UPLOADING;

      cacheObject.file = CircleFile(
        extension: FileSystemService.getExtension(file.path),
        name: name.isNotEmpty ? name : FileSystemService.getFilename(file.path),
        fileSize: file.lengthSync(),
        sourceFile: file.path,
      );

      cacheObject.fullTransferState = BlobState.ENCRYPTING;

      cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);
      debugPrint(
          'file block cache - network user: ${cacheObject.userFurnace!.userid}, usercirclecache user: ${cacheObject.userCircleCache!.user}, seed: ${cacheObject.seed}');

      await TableUserCircleCache.updateLastItemUpdate(
          circleObject.userCircleCache!.circle!,
          circleObject.creator!.id,
          DateTime.now().toLocal());

      ///refresh the circle
      callbackBloc.sinkCircleObjectSave(cacheObject);

      late File cachedFile;

      ///cache the file
      try {
        cachedFile = await FileCacheService.cacheFile(
            userCircleCache, cacheObject, file);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        try {
          cachedFile = await FileCacheService.cacheFile(
              userCircleCache, cacheObject, file);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          cacheObject.retries = RETRIES.MAX_FILE_UPLOAD_RETRIES;
          await _circleObjectService.cacheCircleObject(cacheObject);
          callbackBloc.sinkCircleObjectSave(cacheObject);

          rethrow;
        }
      }

      callbackBloc.sinkCircleObjectSave(cacheObject);

      ///allow the screen to refresh
      await Future.delayed(const Duration(milliseconds: 100)); //add a wait

      ///add to the processing queue
      _queue.add(QueueObject(
          circleObject: cacheObject, queueFile: cachedFile, source: file));

      ///process queue if full
      _isQueueFull(userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleFileBloc.cacheObjectUpdateScreen: $error");

      _globalEventBloc.removeOnError(circleObject);

      showRetry(circleObject, callbackBloc);
    }
  }

  showRetry(
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
  ) async {
    circleObject.retries = RETRIES.MAX_FILE_UPLOAD_RETRIES;
    await _circleObjectService.cacheCircleObject(circleObject);

    _globalEventBloc.removeOnError(circleObject);

    callbackBloc.sinkCircleObjectSave(circleObject);
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

      await _postSteps(userCircleCache, userFurnace, queueObject.circleObject,
          queueObject.source, queueObject.queueFile, callbackBloc);

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
      debugPrint("CircleFileBloc.post: $error");

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
      CircleObjectBloc callbackBloc) async {
    try {
      await _stepIsConnected(
          userCircleCache, userFurnace, circleObject, full, callbackBloc);
      await _stepGetURls(
          userCircleCache, userFurnace, circleObject, full, callbackBloc);
      circleObject = await _encryptFiles(
        userCircleCache,
        userFurnace,
        circleObject,
        full,
      );

      circleObject.cancelToken = CancelToken();

      await _postFull(userCircleCache, userFurnace, circleObject, full,
          maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);

      await _postObjectOnly(userCircleCache, userFurnace, circleObject);

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
        debugPrint("CircleFileBloc._stepIsConnected: $err");

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
      CircleObjectBloc callbackBloc) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        //throw ('fail');

        BlobUrl? blobUrl = await _circleFileService.getUploadUrl(
            userCircleCache, userFurnace, circleObject, full, callbackBloc);

        if (blobUrl != null) {
          circleObject.file!.file = blobUrl.fileName;
          circleObject.file!.fileSize = full.lengthSync();
          circleObject.file!.location = blobUrl.location;
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
          debugPrint("CircleFileBloc._stepGetURls: $err");

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
      CircleObject circleObject, File full) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        debugPrint('blob encrypt start: ${DateTime.now()}');

        circleObject = await _circleFileService.encryptFile(userFurnace,
            userCircleCache, circleObject, full, circleObject.transferUrls!);

        circleObject.fullTransferState = BlobState.UPLOADING;

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        debugPrint('blob encrypt stop: ${DateTime.now()}');

        success = true;
        return circleObject;
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("CircleFileBloc._encryptFiles: $err");

        circleObject.retries += 1;

        //add a wait
        await Future.delayed(const Duration(milliseconds: 200));

        if (circleObject.retries >= RETRIES.MAX_FILE_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    circleObject.retries = 0;
  }

  _postFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File full,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      encryptedCopy.retries = 0;

      File enc = File(
          ("${FileCacheService.returnFilePath(userCircleCache.circlePath!, '${encryptedCopy.seed!}.${encryptedCopy.file!.extension!}')}enc"));

      await _circleFileService.postFile(
          userCircleCache, userFurnace, encryptedCopy, enc,
          maxRetries: maxRetries);

      encryptedCopy.transferPercent = 100;
      encryptedCopy.fullTransferState = BlobState.UPLOADED_BLOB_ONLY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted file");
      }

      ///don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);

      if (globalState.isDesktop()) {
        await enc.rename(FileCacheService.returnFilePath(userCircleCache.circlePath!, '${encryptedCopy.seed!}.enc'));
        FileSystemService.safeDelete(full);
      } else {
        ///remove the encrypted copy
        FileSystemService.safeDelete(enc);
      }
    } catch (err) {
      debugPrint("CircleFileBloc._postFull: $err");
      rethrow;
    }
  }

  _postObjectOnly(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject circleObject) async {
    bool success = false;
    circleObject.retries = 0;

    do {
      try {
        circleObject = await _circleFileService.postCircleFile(
            userFurnace, userCircleCache, circleObject);

        if (circleObject.id != null)
          success = true;
        else
          throw ('could not save object');
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("CircleFileBloc._postObjectOnly: $err");

        circleObject.retries += 1;

        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
          rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));
  }

  processDownloadFailed(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject,
      {CancelToken? cancelToken}) async {
    try {
      circleObject.retries += 1;
      circleObject.transferPercent = 0;

      debugPrint('${circleObject.retries}');

      //stop the download if in progress
      if (cancelToken != null) BlobService.safeCancel(cancelToken);
      BlobService.safeCancelTokens(circleObject);

      if (!FileCacheService.isFileCached(
          circleObject, userCircleCache.circlePath!)) {
        File file = File(FileCacheService.returnFilePath(
            userCircleCache.circlePath!,
            circleObject.seed! + circleObject.file!.extension!));

        if (file.existsSync()) file.delete();

        if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
          _circleFileService.get(userFurnace, userCircleCache, circleObject,
              processDownloadFailed);
        } else {
          circleObject.fullTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
          await TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
          _globalEventBloc.broadcastPreviewDownloaded(circleObject);
        }

        return;
      }

      //assume the file failed
      File file = File(FileCacheService.returnFilePath(
          userCircleCache.circlePath!,
          circleObject.seed! + circleObject.file!.extension!));

      if (file.existsSync()) file.delete();
      if (circleObject.retries < RETRIES.MAX_VIDEO_DOWNLOAD_RETRIES) {
        downloadFile(userFurnace, userCircleCache, circleObject);
      } else {
        circleObject.fullTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastPreviewDownloaded(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleFileBloc.processDownloadFailed: $err');

      processDownloadFailed(userFurnace, userCircleCache, circleObject);
    }
  }

  downloadFile(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject) async {
    try {
      if (!_globalEventBloc.fullExists(circleObject)) {
        _globalEventBloc.addFull(circleObject);

        circleObject.fullTransferState = BlobState.DOWNLOADING;
        circleObject.transferPercent = 0;

        _circleFileService.get(
            userFurnace, userCircleCache, circleObject, processDownloadFailed);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleFileBloc.downloadFile: $err");

      processDownloadFailed(userFurnace, userCircleCache, circleObject);
    }
  }

  removeFromDeviceCache(List<CircleObject> circleObjects) async {
    await FileSystemService.returnCirclesDirectory(
        globalState.user.id!, DeviceOnlyCircle.circleID);

    await TableCircleObjectCache.deleteList(_globalEventBloc, circleObjects);
  }

  Future<List<CircleObject>> cacheToDevice(
    MediaCollection mediaCollection,
  ) async {
    List<CircleObject> circleObjects = [];

    try {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      for (var file in mediaCollection.media) {
        if (file.mediaType != MediaType.file) continue;

        CircleObject cacheObject = CircleObject(
            type: CircleObjectType.CIRCLEFILE,
            creator: globalState.user,
            body: '',
            circle:
                Circle(id: DeviceOnlyCircle.circleID, privacyShareImage: true),
            ratchetIndexes: []);

        cacheObject.userCircleCache = UserCircleCache(
            circlePath: circlePath, prefName: DeviceOnlyCircle.prefName);

        cacheObject.initDates();

        cacheObject.seed = const Uuid().v4();
        cacheObject.id = cacheObject.seed;

        cacheObject.fullTransferState = BlobState.READY;

        cacheObject.file = CircleFile(
          //fileState: FileState.VIDEO_READY,
          extension: FileSystemService.getExtension(file.path),
          sourceFile: file.path,
        );

        ///cache the file
        File cachedFile = await FileCacheService.cacheFile(
            cacheObject.userCircleCache!, cacheObject, file.file);

        ///delete the cached file
        file.file.delete();
        cacheObject.userFurnace = globalState.userFurnace;
        cacheObject.file!.fileSize = cachedFile.lengthSync();
        cacheObject.fullTransferState = BlobState.READY;

        ///Object has been cached
        cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);

        circleObjects.add(cacheObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleFileBloc.cacheToDevice: $error");
    }

    return circleObjects;
  }
}
