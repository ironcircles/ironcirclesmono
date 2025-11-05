import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/blocs/circlealbum_helper_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circlealbum.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/circlealbum_service.dart';
import 'package:ironcirclesapp/services/circleimage_service.dart';
import 'package:ironcirclesapp/services/circleobject_service.dart';
import 'package:ironcirclesapp/services/circlevideo_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../services/tenor_service.dart';

class DownloadObject {
  CircleObject circleObject;
  AlbumItem item;

  DownloadObject({
    required this.circleObject,
    required this.item,
  });
}

class UploadObject {
  int retries;
  CircleObject circleObject;

  File? thumbnail;
  File? full;
  String? fileName;

  File? video;

  File source;
  int index;
  BlobUrl? transferUrls;

  //int loadPercentIncrement;
  String? extension;

  UploadObject({
    required this.video,
    required this.thumbnail,
    required this.full,
    required this.source,
    required this.circleObject,
    this.retries = 0,
    required this.fileName,
    required this.index,
    this.transferUrls,
    //required this.loadPercentIncrement,
    this.extension,
  });
}

class CircleAlbumBloc {
  late CircleAlbumService _circleAlbumService;
  final ImageCacheService _imageCacheService = ImageCacheService();
  late CircleImageService _circleImageService; // = CircleImage2Service();
  late CircleVideoService _circleVideoService;
  final CircleObjectService _circleObjectService = CircleObjectService();
  late GlobalEventBloc _globalEventBloc;

  late CircleAlbumHelperBloc _circleAlbumHelperBloc;

  late VideoControllerBloc _videoControllerBloc;
  late CircleVideoBloc _circleVideoBloc;

  final List<QueueObject> _queue = [];

  int _downloadingCount = 0;

  List<List<DownloadObject>> _downloadQueueOfQueues = [];
  List<DownloadObject> _downloadQueue = [];
  List<String> _downloadObjects = [];

  List<List<UploadObject>> _uploadQueueOfQueues = [];
  List<UploadObject> _uploadQueue = [];
  int _uploadingCount = 0;

  final _currentMedia = PublishSubject<List<AlbumItem>>();
  Stream<List<AlbumItem>> get currentMedia => _currentMedia.stream;

  final _mediaDeleted = PublishSubject<List<AlbumItem>>();
  Stream<List<AlbumItem>> get mediaDeleted => _mediaDeleted.stream;

  CircleAlbumBloc(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
    _circleImageService = CircleImageService(_globalEventBloc);
    _circleAlbumService = CircleAlbumService(_globalEventBloc);
    _circleVideoService = CircleVideoService(_globalEventBloc);
    _videoControllerBloc = VideoControllerBloc();
    _circleVideoBloc = CircleVideoBloc(_globalEventBloc);
    _circleAlbumHelperBloc = CircleAlbumHelperBloc(_globalEventBloc, this);
  }

  //deprecated
  final _imageSaved = PublishSubject<CircleObject>();
  Stream<CircleObject> get imageSaved => _imageSaved.stream;

  final _putFailed = PublishSubject<int>();
  Stream<int> get putFailed => _putFailed.stream;

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

  _stepIsConnected(
    UploadObject uploadObject,
  ) async {
    bool success = false;
    uploadObject.retries = 0;

    do {
      try {
        if (await Network.isConnected()) {
          success = true;
        } else {
          throw ('connection not detected');
        }
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleAlbumBloc._stepIsConnected: $err");

        uploadObject.retries += 1;
        await Future.delayed(const Duration(milliseconds: 200)); //add a wait
        if (uploadObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
      }
    } while (!success &&
        !_globalEventBloc.deletedSeed(uploadObject.circleObject.seed!));
  }

  _stepGetURls(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    UploadObject uploadObject,
  ) async {
    bool success = false;
    uploadObject.retries = 0;

    do {
      try {
        BlobUrl? blobUrl = await _circleImageService.getUploadUrls(
            userCircleCache,
            userFurnace,
            circleObject,
            uploadObject.full!,
            uploadObject.thumbnail!);

        if (blobUrl != null) {
          AlbumItem? item = circleObject.album?.media[uploadObject.index];
          item?.image?.thumbnail = blobUrl.thumbnail;
          item?.image?.fullImage = blobUrl.fileName;
          item?.image?.location = blobUrl.location;
          uploadObject.transferUrls = blobUrl;
          //circleObject.transferUrls = blobUrl;

          success = true;
        } else {
          throw ('could not get urls');
        }
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleAlbumBloc._stepGetURls: $err");

        if (err.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
          uploadObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
          TableCircleObjectCache.deleteBySeed(uploadObject.circleObject.seed!);
          _queue.removeWhere((element) =>
              element.circleObject.seed == uploadObject.circleObject.seed);
          _globalEventBloc.broadCastMemCacheCircleObjectsRemove(
              [uploadObject.circleObject]);
          _globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
          rethrow;
        } else {
          uploadObject.retries += 1;

          //add a wait
          await Future.delayed(const Duration(milliseconds: 200));

          if (uploadObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    uploadObject.retries = 0;
  }

  _stepGetVideoURls(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    CircleObjectBloc callbackBloc,
    UploadObject uploadObject,
  ) async {
    bool success = false;
    uploadObject.retries = 0;

    do {
      try {
        BlobUrl? blobUrl = await _circleVideoService.getUploadUrls(
            userCircleCache,
            userFurnace,
            circleObject,
            uploadObject.video!,
            uploadObject.thumbnail!,
            callbackBloc);

        if (blobUrl != null) {
          AlbumItem? item = circleObject.album?.media[uploadObject.index];
          item?.video!.preview = blobUrl.thumbnail;
          item?.video!.previewSize = uploadObject.thumbnail!.lengthSync();
          item?.video!.video = blobUrl.fileName;
          item?.video!.videoSize = uploadObject.video!.lengthSync();
          item?.video!.location = blobUrl.location;
          uploadObject.transferUrls = blobUrl;
          //circleObject.transferUrls = blobUrl;

          success = true;
        } else {
          throw ('could not get urls');
        }
      } catch (error) {
        if (error.toString().contains(ErrorMessages.USER_BEING_VOTED_OUT)) {
          uploadObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
          TableCircleObjectCache.deleteBySeed(uploadObject.circleObject.seed!);
          _globalEventBloc.broadCastMemCacheCircleObjectsRemove(
              [uploadObject.circleObject]);
          _queue.removeWhere((element) =>
              element.circleObject.seed == uploadObject.circleObject.seed);
          _globalEventBloc.broadcastError(ErrorMessages.USER_BEING_VOTED_OUT);
          rethrow;
        } else {
          debugPrint("CircleAlbumBloc._stepGetVideoURls: $error");

          uploadObject.retries += 1;

          //add a wait
          await Future.delayed(const Duration(milliseconds: 200));

          if (uploadObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    uploadObject.retries = 0;
  }

  Future<CircleObject> _encryptVideoFilesMain(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    File video,
    File thumbnail,
    UploadObject uploadObject,
    BlobUrl blobUrl,
  ) async {
    try {
      CircleObject encryptedCopy = circleObject;

      encryptedCopy.transferPercent = 0;
      encryptedCopy.album!.media[uploadObject.index].video = CircleVideo(
          videoState: VideoStateIC.UPLOADING_VIDEO,
          streamable:
              circleObject.album!.media[uploadObject.index].video!.streamable,
          sourceVideo: video.path,
          preview: blobUrl.thumbnail,
          extension: FileSystemService.getExtension(video.path),
          video: blobUrl.fileName,
          previewSize: thumbnail.lengthSync(),
          videoSize: video.lengthSync(),
          height: circleObject.album!.media[uploadObject.index].video!
              .height, //circleObject.video!.height
          width: circleObject.album!.media[uploadObject.index].video!.width,
          location: blobUrl.location);

      if (!circleObject.album!.media[uploadObject.index].video!.streamable!) {
        DecryptArguments fullArgs = await EncryptBlob.encryptBlob(video.path,
            secretKey: encryptedCopy.secretKey!);

        DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(
            thumbnail.path,
            secretKey: encryptedCopy.secretKey!);

        ///Set the stuff
        encryptedCopy.album!.media[uploadObject.index].video!.fullSignature =
            fullArgs.mac;
        encryptedCopy.album!.media[uploadObject.index].video!.fullCrank =
            fullArgs.nonce;
        encryptedCopy.album!.media[uploadObject.index].video!.thumbSignature =
            thumbArgs.mac;
        encryptedCopy.album!.media[uploadObject.index].video!.thumbCrank =
            thumbArgs.nonce;

        ///revert before displaying on screen, not sent to server
        encryptedCopy.encryptedBody = encryptedCopy.body;
        encryptedCopy.body = circleObject.body;
      }

      ///set encrypted
      // encryptedCopy.thumbnailTransferState = BlobState.ENCRYPTED;
      // encryptedCopy.fullTransferState = BlobState.ENCRYPTED;

      encryptedCopy.album!.media[uploadObject.index].thumbnailTransferState =
          BlobState.ENCRYPTED;
      encryptedCopy.album!.media[uploadObject.index].fullTransferState =
          BlobState.ENCRYPTED;
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _globalEventBloc.broadcastProgressIndicator(encryptedCopy);

      return encryptedCopy;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoService.encryptFiles: $err");

      rethrow;
    }
  }

  _encryptVideoFiles(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File video,
      File thumbnail,
      UploadObject uploadObject) async {
    bool success = false;
    //circleObject.retries = 0;
    uploadObject.retries = 0;

    do {
      try {
        debugPrint('blob encrypt start: ${DateTime.now()}');

        CircleObject newObject = await _encryptVideoFilesMain(
            userFurnace,
            userCircleCache,
            circleObject,
            video,
            thumbnail,
            uploadObject,
            uploadObject.transferUrls!);

        newObject.album!.media[uploadObject.index].thumbnailTransferState =
            BlobState.UPLOADING;
        newObject.album!.media[uploadObject.index].fullTransferState =
            BlobState.UPLOADING;

        // circleObject.thumbnailTransferState = BlobState.UPLOADING;
        // circleObject.fullTransferState = BlobState.UPLOADING;

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        debugPrint('blob encrypt stop: ${DateTime.now()}');

        success = true;
        return newObject;
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint("CircleAlbumBloc._encryptVideoFiles: $err");

        //circleObject.retries += 1;
        uploadObject.retries += 1;

        //add a wait
        await Future.delayed(const Duration(milliseconds: 200));

        if (uploadObject.retries //circleObject.retries
            >=
            RETRIES.MAX_VIDEO_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    //circleObject.retries = 0;
    uploadObject.retries = 0;
  }

  _encryptFiles(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    UploadObject uploadObject,
  ) async {
    bool success = false;
    //circleObject.retries = 0;
    uploadObject.retries = 0;
    CircleObject encryptedCopy = circleObject;

    do {
      try {
        encryptedCopy.secretKey = circleObject.secretKey;
        encryptedCopy.transferUrls = uploadObject.transferUrls!;

        DecryptArguments fullArgs = await EncryptBlob.encryptBlob(
            uploadObject.full!.path,
            secretKey: encryptedCopy.secretKey!);
        DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(
            uploadObject.thumbnail!.path,
            secretKey: encryptedCopy.secretKey!);

        encryptedCopy.album!.media[uploadObject.index].image?.fullSignature =
            fullArgs.mac;
        encryptedCopy.album!.media[uploadObject.index].image?.fullCrank =
            fullArgs.nonce;
        encryptedCopy.album!.media[uploadObject.index].image?.thumbSignature =
            thumbArgs.mac;
        encryptedCopy.album!.media[uploadObject.index].image?.thumbCrank =
            thumbArgs.nonce;

        TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        debugPrint('blob encrypt stop: ${DateTime.now()}');

        //return encryptedCopy;
        success = true;
      } catch (err) {
        //LogBloc.insertError(err, trace);
        debugPrint("CircleAlbumBloc._encryptFiles: $err");

        uploadObject.retries += 1;

        if (err.toString().contains("PathNotFoundException") &&
            uploadObject.retries >= 2) {
          await haltOnError(
              userFurnace: userFurnace,
              circleObject: circleObject,
              upload: false);
          return;
        }

        //add a wait
        await Future.delayed(const Duration(milliseconds: 200));

        if (uploadObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) rethrow;
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));

    uploadObject.retries = 0;
    return encryptedCopy;
  }

  _postVideoThumbnail(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject encryptedCopy,
      File thumbnail,
      UploadObject uploadObject) async {
    try {
      await _circleVideoService.postThumbnail(
        userCircleCache,
        userFurnace,
        encryptedCopy,
        uploadObject.index.toString(),
        uploadObject
            .circleObject.album!.media[uploadObject.index].video!.streamable!,
        uploadObject.transferUrls,
        _doNothing,
      );

      //remove the encrypted thumbnail
      File thumbEnc = File(
          ("${VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, encryptedCopy, uploadObject.index.toString(), true, "")}enc"));

      debugPrint(thumbEnc.path);

      if (await thumbEnc.exists()) {
        try {
          thumbEnc.delete();
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('$err');
        }
      }

      encryptedCopy.album!.media[uploadObject.index].thumbnailTransferState =
          BlobState.READY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted video preview");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);
    } catch (err) {
      //LogBloc.insertError(err, trace);
      debugPrint("CircleAlbumBloc._postVideoThumbnail: $err");
      //showRetry(encryptedCopy, callbackBloc);
      rethrow;
    }
  }

  _postThumbnail(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject encryptedCopy,
      File thumbnail,
      UploadObject uploadObject) async {
    try {
      await _circleAlbumService.postThumbnail(
        userCircleCache,
        userFurnace,
        encryptedCopy,
        uploadObject.fileName!,
        uploadObject.transferUrls!,
        uploadObject.extension!,
        _progressCallback,
      );

      File thumbEnc = File(("${uploadObject.thumbnail!.path}enc"));

      if (await thumbEnc.exists()) {
        try {
          thumbEnc.delete();
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('$err');
        }
      }

      encryptedCopy.thumbnailTransferState = BlobState.UPLOADED_BLOB_ONLY;
      encryptedCopy.fullTransferState = BlobState.UPLOADING;

      encryptedCopy.album!.media[uploadObject.index].thumbnailTransferState =
          BlobState.READY;

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
      debugPrint("CircleAlbumBloc._postThumbnail: $err");
      //showRetry(encryptedCopy, callbackBloc);
      rethrow;
    }
  }

  _postVideoFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File full, UploadObject uploadObject,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      //encryptedCopy.retries = 0;
      uploadObject.retries = 0;

      late File enc;

      if (encryptedCopy.album!.media[uploadObject.index].video!.streamable!) {
        enc = File((VideoCacheService.returnAlbumVideoPath(
            userCircleCache.circlePath!,
            encryptedCopy,
            uploadObject.index.toString(),
            false,
            FileSystemService.getExtension(full.path))));
      } else {
        enc = File(
            ("${VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, encryptedCopy, uploadObject.index.toString(), false, FileSystemService.getExtension(full.path))}enc"));
      }

      debugPrint(enc.path);

      await _circleVideoService.postFull(userCircleCache, userFurnace,
          encryptedCopy, enc, maxRetries, uploadObject.transferUrls, _progressCallback);

      encryptedCopy.album!.media[uploadObject.index].video!.videoState =
          VideoStateIC.VIDEO_UPLOADED;
      encryptedCopy.album!.media[uploadObject.index].fullTransferState =
          BlobState.READY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted video");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);

      if (!encryptedCopy.album!.media[uploadObject.index].video!.streamable!) {
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
    } catch (err) {
      debugPrint("CircleImageBloc._postFull: $err");
      rethrow;
    }
  }

  _postFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File full, UploadObject uploadObject,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      //encryptedCopy.retries = 0;
      uploadObject.retries = 0;

      await _circleAlbumService.postFull(
          userCircleCache,
          userFurnace,
          encryptedCopy,
          uploadObject.fileName,
          uploadObject.extension!,
          uploadObject.transferUrls,
          _progressCallback,
          maxRetries: maxRetries);

      encryptedCopy.fullTransferState = BlobState.UPLOADED_BLOB_ONLY;

      encryptedCopy.album!.media[uploadObject.index].fullTransferState =
          BlobState.READY;

      //make sure this wasn't added to the delete queue
      if (_globalEventBloc.deletedSeeds.contains(encryptedCopy.seed)) {
        TableCircleObjectCache.deleteBySeed(encryptedCopy.seed!);
        _globalEventBloc.broadCastMemCacheCircleObjectsRemove([encryptedCopy]);
        throw ("tried to send a deleted image");
      }

      //don't wait
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, encryptedCopy);

      //remove the encrypted copy
      // File enc = File(
      //     ("${ImageCacheService.returnAlbumImagePath(userCircleCache.circlePath!, encryptedCopy, false, uploadObject.fileName!)}enc"));
      File enc = File(("${uploadObject.full!.path}enc"));

      if (await enc.exists()) {
        try {
          enc.delete();
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint('$err');
        }
      }
    } catch (error) {
      //LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.postFull: $error");
      rethrow;
    }
  }

  _postHotSwapImage(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject encryptedCopy,
      File source,
      File thumbnail,
      UploadObject uploadObject,
      {File? encryptedSource}) async {
    String fullImagePath = ImageCacheService.returnAlbumImagePath(
        userCircleCache.circlePath!,
        encryptedCopy,
        false,
        uploadObject.fileName!,
        uploadObject.extension!);
    File fullImage = File(fullImagePath);

    if (fullImage.existsSync()) {
      await FileSystemService.safeDelete(fullImage);
    }

    //create file
    await _imageCacheService.createFullFallback(
        encryptedCopy, fullImagePath, source);

    encryptedCopy.album!.media[uploadObject.index].image!.fullImageSize =
        fullImage.lengthSync();

    encryptedCopy = await _encryptFiles(
      userCircleCache,
      userFurnace,
      encryptedCopy,
      uploadObject,
    );

    await _stepGetURls(
        userCircleCache, userFurnace, encryptedCopy, uploadObject);

    await _postFull(
        userCircleCache, userFurnace, encryptedCopy, fullImage, uploadObject);
  }

  _postAlbumOnly(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject circleObject, CircleObjectBloc callbackBloc,
      {List<AlbumItem>? changeItems, bool? add}) async {
    bool success = false;
    circleObject.retries = 0;
    List<AlbumItem> holdingItems = [];
    if (circleObject.id != null && add == true) {
      holdingItems = List.from(circleObject.album!.media);
      holdingItems.removeWhere((element) => element.id != null);
    } else if (circleObject.id != null && add == false) {
      holdingItems = List.from(changeItems!);
    }

    do {
      try {
        late CircleObject savedObject;

        if (circleObject.id != null) {
          savedObject = await _circleAlbumService.putCircleAlbum(
              userCircleCache, userFurnace, circleObject, holdingItems, add!);
        } else {
          savedObject = await _circleAlbumService.postAlbum(
              userCircleCache, userFurnace, circleObject);
        }

        if (savedObject.id != null) {
          success = true;

          callbackBloc.sinkCircleObjectSave(savedObject);

          if (userCircleCache.guarded != true &&
              (userCircleCache.hidden != true ||
                  userCircleCache.hiddenOpen == true)) {
            savedObject.userCircleCache = userCircleCache;
            savedObject.userFurnace = userFurnace;
            _globalEventBloc.broadcastMemCacheCircleObjectsAdd([savedObject]);

            _currentMedia.sink.add(savedObject.album!.media);

            if (circleObject.id != null && add == false) {
              _mediaDeleted.sink.add(holdingItems);
            }
          }
        } else {
          throw ('could not save object');
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        debugPrint("CircleAlbumBloc.postAlbumOnly: $error");

        circleObject.retries += 1;

        if (circleObject.retries >= RETRIES.MAX_IMAGE_UPLOAD_RETRIES) {
          rethrow;
        }
      }
    } while (!success && !_globalEventBloc.deletedSeed(circleObject.seed!));
  }

  _checkUploadQueue(UploadObject uploadObject, UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObjectBloc callbackBloc) async {
    _uploadQueue.remove(uploadObject);
    _uploadingCount--;

    if (_uploadQueue.isEmpty) {
      if (uploadObject.circleObject.cancelToken == null) {
        debugPrint("cancel token is null");
        uploadObject.circleObject.cancelToken = CancelToken();
      }
      if (uploadObject.circleObject.secretKey == null) {
        debugPrint("secret key is null");
      }
      if (uploadObject.circleObject.seed == null) {
        debugPrint("seed is null");
      }
      if (uploadObject.circleObject.id != null) {
        await _postAlbumOnly(userCircleCache, userFurnace,
            uploadObject.circleObject, callbackBloc,
            add: true);
      } else {
        await _postAlbumOnly(userCircleCache, userFurnace,
            uploadObject.circleObject, callbackBloc);
      }

      debugPrint("handling emptied queue (album done)");
      _uploadQueueOfQueues.removeAt(0);
    } else if (uploadObject.circleObject.id == null) {
      // uploadObject.circleObject.transferPercent =
      //     uploadObject.circleObject.transferPercent! +
      //         uploadObject!.loadPercentIncrement!;
      _globalEventBloc
          .broadcastProgressThumbnailIndicator(uploadObject.circleObject);
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, uploadObject.circleObject);
      debugPrint(
          "should increment load percent:${uploadObject.circleObject.transferPercent}");
    }

    _globalEventBloc
        .broadcastProgressThumbnailIndicator(uploadObject.circleObject);
    _uploadNextBatch(userCircleCache, userFurnace, callbackBloc);
  }

  _postSteps(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
    UploadObject uploadObject,
    CircleObjectBloc callbackBloc,
  ) async {
    try {
      await _stepIsConnected(uploadObject);

      await _stepGetURls(
          userCircleCache, userFurnace, circleObject, uploadObject);

      CircleObject newObject = await _encryptFiles(
        userCircleCache,
        userFurnace,
        circleObject,
        uploadObject,
      );

      newObject.cancelToken = CancelToken();
      //newObject.transferUrls = queueObject.transferUrls;

      await _postThumbnail(
        userCircleCache,
        userFurnace,
        newObject,
        uploadObject.thumbnail!,
        uploadObject,
      );

      try {
        await _postFull(userCircleCache, userFurnace, newObject,
            uploadObject.full!, uploadObject,
            maxRetries: RETRIES.MAX_IMAGE_UPLOAD_RETRIES_BEFORE_HOTSWAP);
      } catch (err) {
        LogBloc.insertLog(
            "Resorted to lower res image", "_postSteps: ${userFurnace.userid}");

        await _postHotSwapImage(userFurnace, userCircleCache, newObject,
            uploadObject.source, uploadObject.thumbnail!, uploadObject,
            encryptedSource: uploadObject.full);
      }

      ///refresh the screen spinner
      _globalEventBloc.broadcastProgressIndicator(uploadObject.circleObject);

      _checkUploadQueue(
          uploadObject, userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.postSteps: $error");
      _globalEventBloc.removeOnError(circleObject);
    }
  }

  _postVideoSteps(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File source,
      File video,
      File thumbnail,
      UploadObject uploadObject,
      CircleObjectBloc callbackBloc) async {
    try {
      await _stepIsConnected(uploadObject);
      await _stepGetVideoURls(userCircleCache, userFurnace, circleObject,
          callbackBloc, uploadObject);

      CircleObject newObject = await _encryptVideoFiles(userCircleCache,
          userFurnace, circleObject, video, thumbnail, uploadObject);

      newObject.cancelToken = CancelToken();
      //newObject.transferUrls = queueObject.transferUrls;

      await _postVideoThumbnail(
          userCircleCache, userFurnace, newObject, thumbnail, uploadObject);

      await _postVideoFull(
          userCircleCache, userFurnace, newObject, video, uploadObject,
          maxRetries: RETRIES.MAX_VIDEO_UPLOAD_RETRIES);

      _checkUploadQueue(
          uploadObject, userCircleCache, userFurnace, callbackBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _globalEventBloc.removeOnError(circleObject);

      if (_queue.indexWhere(
              (element) => element.circleObject.seed == circleObject.seed) >
          -1) {
        showRetry(uploadObject, callbackBloc);
      }
    }
  }

  showRetry(
    UploadObject uploadObject,
    CircleObjectBloc callbackBloc,
  ) async {
    uploadObject.retries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES;
    await _circleObjectService.cacheCircleObject(uploadObject.circleObject);

    _globalEventBloc.removeOnError(uploadObject.circleObject);

    callbackBloc.sinkCircleObjectSave(uploadObject.circleObject);
  }

  _processObject(UploadObject uploadObject, UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObjectBloc callbackBloc) async {
    try {
      debugPrint("uploading object");

      if (uploadObject.full != null) {
        ///image
        await _postSteps(userCircleCache, userFurnace,
            uploadObject.circleObject, uploadObject, callbackBloc);
      } else if (uploadObject.video != null) {
        ///video
        await _postVideoSteps(
            userCircleCache,
            userFurnace,
            uploadObject.circleObject,
            uploadObject.source,
            uploadObject.video!,
            uploadObject.thumbnail!,
            uploadObject,
            callbackBloc);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.processObject: $error");

      _globalEventBloc.removeOnError(uploadObject.circleObject);

      showRetry(uploadObject, callbackBloc);
    }
  }

  _processQueue(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) async {
    if (_uploadQueueOfQueues.isEmpty) {
      debugPrint("queueOfQueues is empty. should be done uploading albums");
      return;
    } else {
      _uploadQueue = _uploadQueueOfQueues[0];

      if (await Network.isMobile() == false) {
        if (_uploadQueue.length < 11) {
          _uploadingCount = _uploadQueue.length;

          ///count is less than 11 so just process all of them
          for (UploadObject uploadObject in _uploadQueue) {
            ///use the object's hitchhikers if they exist

            _processObject(
                uploadObject, userCircleCache, userFurnace, callbackBloc);
          }
        } else if (_uploadQueue.isNotEmpty) {
          if (_uploadQueue.length >= 10)
            _uploadingCount = 10;
          else
            _uploadingCount = _uploadQueue.length;

          for (int i = 0; i < _uploadQueue.length; i++) {
            _processObject(
                _uploadQueue[i], userCircleCache, userFurnace, callbackBloc);

            if (i == 9) break; //only process 10
          }
        }
      } else {
        if (_uploadQueue.length < 4) {
          _uploadingCount = _uploadQueue.length;

          ///count is less than 4 so just process all of them
          for (UploadObject uploadObject in _uploadQueue) {
            ///use the object's hitchhikers if they exist

            _processObject(
                uploadObject, userCircleCache, userFurnace, callbackBloc);
          }
        } else if (_uploadQueue.isNotEmpty) {
          if (_uploadQueue.length >= 3)
            _uploadingCount = 3;
          else
            _uploadingCount = _uploadQueue.length;

          for (int i = 0; i < _uploadQueue.length; i++) {
            _processObject(
                _uploadQueue[i], userCircleCache, userFurnace, callbackBloc);

            if (i == 2) break; //only process 3
          }
        }
      }
    }
  }

  _uploadNextBatch(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) {
    if (_uploadingCount == 0) {
      _processQueue(userCircleCache, userFurnace, callbackBloc);
    }
  }

  handler(List<UploadObject> sharedQueue, UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObjectBloc callbackBloc) {
    _uploadQueueOfQueues.add(sharedQueue);

    ///last item
    if (_uploadQueueOfQueues.length == 1) {
      debugPrint("triggering upload queue processing");
      _uploadNextBatch(userCircleCache, userFurnace, callbackBloc);
    }
  }

  _progressCallback(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int progress) {
    debugPrint("****************************broadcast progress: $progress");

    if (progress < 100)
      _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
  }

  _doNothing(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int progress) {}

  makeAlbum(
    CircleObject circleObject,
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    List<Media> mediaCollection,
    bool hiRes,
    CircleObjectBloc callbackBloc,
  ) async {
    List<Media> mediaList = List.from(mediaCollection);
    int loadPercentIncrement = 100 ~/ mediaList.length.floor();

    CircleObject preppedObject = _circleAlbumHelperBloc.prepAlbum(circleObject);

    preppedObject.album!.bytesTransferred = 0;
    for (Media media in mediaList) {
      preppedObject.album!.bytesTotal += media.file.lengthSync();
    }

    CircleObject cacheObject =
        await _circleAlbumHelperBloc.makeCacheObject(preppedObject);
    cacheObject.transferPercent = 0;
    await _circleObjectService.cacheCircleObject(cacheObject);
    callbackBloc.sinkCircleObjectSave(cacheObject);
    cacheObject.thumbnailTransferState = BlobState.UPLOADING;
    cacheObject.fullTransferState = BlobState.UPLOADING;
    _globalEventBloc.broadcastProgressThumbnailIndicator(cacheObject);
    TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, cacheObject);

    int endLength = mediaCollection.length;

    ///check for too big images before queue!
    mediaCollection.removeWhere((element) =>
        element.mediaType == MediaType.image &&
        element.file.lengthSync() > EncryptBlob.maxForEncrypted);
    if (endLength != mediaCollection.length) {
      _putFailed.sink.add(BlobFailed.FILETOOLARGE);
    } else {
      List<UploadObject> sharedQueue = [];

      ///hander is called from the helper bloc once the last image/video has been cached
      for (int i = 0; i < mediaCollection.length; i++) {
        Media media = mediaCollection[i];
        AlbumItem item = AlbumItem(index: i, type: AlbumItemType.IMAGE);
        cacheObject.album!.media.add(item);

        if (media.mediaType == MediaType.image) {
          _circleAlbumHelperBloc.cacheImage(
              sharedQueue,
              endLength,
              cacheObject,
              userCircleCache,
              userFurnace,
              media.file,
              hiRes,
              callbackBloc,
              i,
              loadPercentIncrement);
        } else if (media.mediaType == MediaType.video) {
          _circleAlbumHelperBloc.cacheVideo(
              sharedQueue,
              endLength,
              cacheObject,
              userCircleCache,
              userFurnace,
              File(media.path),
              media.streamable,
              media.thumbIndex,
              false,
              callbackBloc,
              i,
              loadPercentIncrement);
        } else if (media.mediaType == MediaType.gif) {
          ///called when sharing album that has tenor gif in it
          cacheObject.album!.media[i].type = AlbumItemType.GIF;
          cacheObject.album!.media[i].gif = CircleGif();
          cacheObject.album!.media[i].gif!.giphy = media.path;
          cacheObject.album!.media[i].gif!.width = media.width;
          cacheObject.album!.media[i].gif!.height = media.height;
        }
      }
    }
  }

  ///for hiding album object
  static Future<bool> unCacheMedia(
      CircleObject circleObject, String circlePath) async {
    try {
      for (AlbumItem item in circleObject.album!.media) {
        if (item.type == AlbumItemType.IMAGE) {
          await ImageCacheService.deleteAlbumImage(
              circleObject, circlePath, item);
        } else if (item.type == AlbumItemType.VIDEO) {
          await VideoCacheService.deleteAlbumVideo(
              circlePath, circleObject, item);
        } else if (item.type == AlbumItemType.GIF) {
          //nothing
        }
      }

      return true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.unCacheMedia: $error");
      return false;
    }
  }

  deleteCachedMedia(
    CircleObject circleObject,
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    List<AlbumItem> albumItems,
  ) async {
    try {
      for (AlbumItem item in albumItems) {
        if (item.type == AlbumItemType.IMAGE) {
          ///delete cached image
          await ImageCacheService.deleteAlbumImage(
              circleObject, userCircleCache.circlePath!, item);
        } else if (item.type == AlbumItemType.VIDEO) {
          await VideoCacheService.deleteAlbumVideo(
              userCircleCache.circlePath!, circleObject, item);
        } else if (item.type == AlbumItemType.GIF) {
          //nothing
        }
        circleObject.album!.media.remove(item);
      }

      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _currentMedia.sink.add(circleObject.album!.media);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.deleteAlbumMedia: $error");
    }
  }

  ///delete media from album
  deleteAlbumMedia(
    CircleObject circleObject,
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    List<AlbumItem> albumItems,
    CircleObjectBloc callbackBloc,
  ) async {
    try {
      for (AlbumItem item in albumItems) {
        if (item.type == AlbumItemType.IMAGE) {
          ///delete cached image
          await ImageCacheService.deleteAlbumImage(
              circleObject, userCircleCache.circlePath!, item);
        } else if (item.type == AlbumItemType.VIDEO) {
          await VideoCacheService.deleteAlbumVideo(
              userCircleCache.circlePath!, circleObject, item);
        } else if (item.type == AlbumItemType.GIF) {
          //nothing
        }
      }

      circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
          userCircleCache.usercircle!, circleObject);

      _postAlbumOnly(userCircleCache, userFurnace, circleObject, callbackBloc,
          changeItems: albumItems, add: false);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.deleteAlbumMedia: $error");
    }
  }

  ///add media to album
  addAlbumMedia(
    CircleObject circleObject,
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    List<Media> mediaCollection,
    CircleObjectBloc callbackBloc,
    bool hiRes,
  ) async {
    try {
      circleObject.fullTransferState = BlobState.UPLOADING;
      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
          userCircleCache.usercircle!, circleObject);

      //_globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);

      int loadPercentIncrement = 100 ~/ mediaCollection.length.floor();
      int baseLength = circleObject.album!.media.length;

      int endLength = mediaCollection.length;

      ///check for too big images before queue!
      mediaCollection.removeWhere((element) =>
          element.mediaType == MediaType.image &&
          element.file.lengthSync() > EncryptBlob.maxForEncrypted);
      if (endLength != mediaCollection.length) {
        _putFailed.sink.add(BlobFailed.FILETOOLARGE);
      } else {
        List<UploadObject> sharedQueue = [];
        for (int i = 0; i < mediaCollection.length; i++) {
          Media media = mediaCollection[i];
          int index = i + baseLength;
          AlbumItem item = AlbumItem(index: index, type: AlbumItemType.IMAGE);
          circleObject.album!.media.add(item);

          if (media.mediaType == MediaType.image) {
            _circleAlbumHelperBloc.cacheImage(
                sharedQueue,
                endLength,
                circleObject,
                userCircleCache,
                userFurnace,
                media.file,
                hiRes,
                callbackBloc,
                index,
                loadPercentIncrement);
          } else if (media.mediaType == MediaType.video) {
            _circleAlbumHelperBloc.cacheVideo(
                sharedQueue,
                endLength,
                circleObject,
                userCircleCache,
                userFurnace,
                File(media.path),
                media.streamable,
                media.thumbIndex,
                false,
                callbackBloc,
                index,
                loadPercentIncrement);
          } else if (media.mediaType == MediaType.gif) {
            ///this shouldn't happen, gifs added through different function
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.addAlbumMedia");
    }
  }

  ///add tenor gif to album
  addAlbumGif(
    CircleObject circleObject,
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    GiphyOption gif,
    CircleObjectBloc callbackBloc,
  ) async {
    try {
      circleObject.fullTransferState = BlobState.UPLOADING;
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
          userCircleCache.usercircle!, circleObject);

      AlbumItem item = AlbumItem(
        type: AlbumItemType.GIF,
        index: circleObject.album!.media.length,

        ///add to end
      );
      item.gif = CircleGif();
      item.gif!.giphy = gif.url;
      item.gif!.width = gif.width;
      item.gif!.height = gif.height;

      circleObject.album!.media.add(item);
      //TableCircleObjectCache.updateCacheSingleObject(userFurnace.userid!, circleObject);

      _postAlbumOnly(userCircleCache, userFurnace, circleObject, callbackBloc,
          add: true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.addAlbumGif");
    }
  }

  processFullDownloadFailed(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      {DownloadFailedReason? reason}) async {
    try {
      if (item.image == null) {
        await haltOnError(
            userFurnace: userFurnace,
            circleObject: circleObject,
            upload: false);
        return;
      }

      String extension = FileSystemService.getExtension(item.image!.fullImage!);

      File full = File(ImageCacheService.returnAlbumImagePath(
          userCircleCache.circlePath!,
          circleObject,
          false,
          item.image!.fullImage!,
          extension));

      FileSystemService.safeDelete(full);

      circleObject.nonUIRetries++;

      ///FIX?

      if (reason != null) {
        ///run the mac at least twice
        if (reason == DownloadFailedReason.decryption && item.retries >= 2) {
          await haltOnError(
              userFurnace: userFurnace,
              circleObject: circleObject,
              upload: false,
              failUI: false);
          return;
        }
      }

      if (circleObject.nonUIRetries < 12) {
        ///fix?
        item.fullTransferState = BlobState.DOWNLOADING;

        _globalEventBloc.fullItems.add(item);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        _circleAlbumService.getFull(userFurnace, userCircleCache, circleObject,
            item, processFullDownloadFailed);
      } else {
        item.fullTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumBloc.processImageDownloadFailed: $error');
      processFullDownloadFailed(
          userFurnace, userCircleCache, circleObject, item);
    }
  }

  processThumbnailDownloadFailed(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      {DownloadFailedReason? reason}) async {
    try {
      circleObject.retries += 1;

      if (item.image == null) {
        await haltOnError(
            userFurnace: userFurnace,
            circleObject: circleObject,
            upload: false);
        return;
      }

      File thumbnail = File(ImageCacheService.returnExistingAlbumImagePath(
          userCircleCache.circlePath!, circleObject, item.image!.thumbnail!));

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

      if (reason != null) {
        if (reason == DownloadFailedReason.keyDoesNotExist) {
          ///item was probably deleted by owner, stop trying to download
          item.removeFromCache = true;
          item.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
          await TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
          _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
        }
      } else if (item.retries < RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        item.thumbnailTransferState = BlobState.DOWNLOADING;
        _globalEventBloc.thumbnailItems.add(item);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }

        _circleAlbumService.getThumbnail(userFurnace, userCircleCache,
            circleObject, item, processThumbnailDownloadFailed);
      } else {
        //remove
        item.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumBloc.processThumbnailDownloadFailed: $error');

      if (circleObject.retries > RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES) {
        circleObject.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      } else {
        processThumbnailDownloadFailed(
            userFurnace, userCircleCache, circleObject, item);
      }
    }
  }

  _downloadNextBatch(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) {
    if (_downloadingCount == 0) {
      debugPrint("processDownloadQueue");
      _processDownloadQueue(userCircleCache, userFurnace, callbackBloc);
    }
  }

  _handleVideoDownload(
      DownloadObject queueObject,
      AlbumItem item,
      CircleObject object,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObjectBloc callbackBloc,
      CircleVideoBloc circleVideoBloc,
      VideoControllerBloc videoControllerBloc,
      {broadcastAutoPlay = false}) async {
    try {
      if (VideoCacheService.isAlbumVideoCached(
          object, userCircleCache.circlePath!, item)) {
        ///bandaid for lost state
        if (item.video!.videoState == null || item.video!.videoState == 0) {
          item.video!.videoState = VideoStateIC.INITIALIZING_CHEWIE;
          TableCircleObjectCache.updateCacheSingleObject('', object);
        }

        ///does it already have a chewie controller?
        if (videoControllerBloc.fetchAlbumController(item) == null) {
          item.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
        } else {
          item.video!.videoState = VideoStateIC.VIDEO_READY;
        }

        item.video!.videoFile = File(
            VideoCacheService.returnExistingAlbumVideoPath(
                userCircleCache.circlePath!, object, item.video!.video!));

        TableCircleObjectCache.updateCacheSingleObject('', object);

        if (broadcastAutoPlay) circleVideoBloc.broadcastItemAutoplay(item);
      } else if (VideoCacheService.isAlbumPreviewCached(
          object, userCircleCache.circlePath!, item)) {
        String path = VideoCacheService.returnExistingAlbumVideoPath(
            userCircleCache.circlePath!, object, item.video!.preview!);

        if (item.video!.previewFile == null) {
          item.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
          TableCircleObjectCache.updateCacheSingleObject('', object);
          item.video!.previewFile = File(path);
        } else if (item.video!.previewFile!.path != path)
          item.video!.previewFile = File(path);
      } else {
        item.video!.videoState = VideoStateIC.DOWNLOADING_PREVIEW;
        TableCircleObjectCache.updateCacheSingleObject('', object);

        await circleVideoBloc.notifyWhenItemPreviewReady(
            userFurnace, userCircleCache, object, item);
      }

      _checkDownloadQueue(
          queueObject, userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumBloc.handleVideoDownload: $error');
      processThumbnailDownloadFailed(
          userFurnace, userCircleCache, object, item);
    }
  }

  _handleImageDownload(
      DownloadObject queueObject,
      AlbumItem item,
      CircleObject circleObject,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObjectBloc callbackBloc) async {
    try {
      if (!ImageCacheService.isAlbumThumbnailCached(
              circleObject, item, userCircleCache.circlePath!) ||
          !ImageCacheService.isAlbumFullImageCached(circleObject, item,
              userCircleCache.circlePath!, circleObject.seed!)) {
        await _circleAlbumService.getImage(
            userFurnace,
            userCircleCache,
            circleObject,
            item,
            processThumbnailDownloadFailed,
            processFullDownloadFailed);
      }

      debugPrint("checking download queue");
      _checkDownloadQueue(
          queueObject, userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _globalEventBloc.removeOnError(circleObject);
      debugPrint('CircleAlbumBloc.handleImageDownload: $error');

      processThumbnailDownloadFailed(
          userFurnace, userCircleCache, circleObject, item);
    }
  }

  _checkDownloadQueue(
      DownloadObject queueObject,
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObjectBloc callbackBloc) async {
    try {
      _downloadQueue.remove(queueObject);
      _downloadingCount--;

      if (_downloadQueue.isEmpty) {
        queueObject.circleObject.fullTransferState = BlobState.READY;
        _globalEventBloc
            .broadcastProgressThumbnailIndicator(queueObject.circleObject);
        if (_globalEventBloc.fullExists(queueObject.circleObject) == true) {
          _globalEventBloc.broadcastObjectDownloaded(queueObject.circleObject);
        }
        TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, queueObject.circleObject);

        await Future.delayed(const Duration(milliseconds: 100)); //add a wait
        _currentMedia.sink.add(queueObject.circleObject.album!.media);

        debugPrint("handling emptied queue (album done)");
        _downloadQueueOfQueues.removeAt(0);
        _downloadObjects.remove(queueObject.circleObject.id!);
        _globalEventBloc.broadcastAlbumDownloaded(queueObject.circleObject);
      }

      _downloadNextBatch(userCircleCache, userFurnace, callbackBloc);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.checkDownloadQueue: $error");
    }
  }

  _downloadObject(DownloadObject queueObject, UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObjectBloc callbackBloc) async {
    try {
      debugPrint("downloading object");

      if (queueObject.item.type == AlbumItemType.IMAGE) {
        await _handleImageDownload(
            queueObject,
            queueObject.item,
            queueObject.circleObject,
            userFurnace,
            userCircleCache,
            callbackBloc);
      } else if (queueObject.item.type == AlbumItemType.GIF) {
        ///nothing
      } else if (queueObject.item.type == AlbumItemType.VIDEO) {
        await _handleVideoDownload(
            queueObject,
            queueObject.item,
            queueObject.circleObject,
            userFurnace,
            userCircleCache,
            callbackBloc,
            _circleVideoBloc,
            _videoControllerBloc);
      }

      ///allow the screen to refresh
      await Future.delayed(const Duration(milliseconds: 100)); //add a wait
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.downloadObject: $error");
      //_globalEventBloc.removeOnError(queueObject.circleObject);
      //showRetry(queueObject, callbackBloc);
    }
  }

  _processDownloadQueue(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObjectBloc callbackBloc,
  ) async {
    if (_downloadQueueOfQueues.isEmpty) {
      debugPrint("queueOfQueues is empty. should be done downloading albums");
      return;
    } else {
      debugPrint("next queue queueing up, or continued:");
      _downloadQueue = _downloadQueueOfQueues[0];

      if (_downloadQueue.length < 26) {
        _downloadingCount = _downloadQueue.length;

        for (DownloadObject queueObject in _downloadQueue) {
          _downloadObject(
              queueObject, userCircleCache, userFurnace, callbackBloc);
        }
      } else if (_downloadQueue.isNotEmpty) {
        if (_downloadQueue.length >= 25) {
          _downloadingCount = 25;
        } else {
          _downloadingCount = _downloadQueue.length;
        }

        for (int i = 0; i < _downloadQueue.length; i++) {
          _downloadObject(
              _downloadQueue[i], userCircleCache, userFurnace, callbackBloc);

          if (i == 24) break;
        }
      }
    }
  }

  _queueAlbum(CircleObject circleObject, UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObjectBloc callbackBloc) async {
    List<DownloadObject> _downloads = [];

    for (AlbumItem item in circleObject.album!.media) {
      if (item.type == AlbumItemType.IMAGE) {
        if (item.removeFromCache == true) {
          ImageCacheService.deleteAlbumImage(
              circleObject, userCircleCache.circlePath!, item);
          TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
        } else {
          if (!ImageCacheService.isAlbumThumbnailCached(
                  circleObject, item, userCircleCache.circlePath!) ||
              !ImageCacheService.isAlbumFullImageCached(circleObject, item,
                  userCircleCache.circlePath!, circleObject.seed!)) {
            DownloadObject obj =
                DownloadObject(circleObject: circleObject, item: item);
            if (!_downloads.contains(obj)) {
              _downloads.add(obj);
            }
          }
        }
      } else if (item.type == AlbumItemType.VIDEO) {
        if (item.removeFromCache == true) {
          VideoCacheService.deleteAlbumVideo(
              userCircleCache.circlePath!, circleObject, item);
          TableCircleObjectCache.updateCacheSingleObject(
              userFurnace.userid!, circleObject);
        } else {
          if ( //!VideoCacheService.isAlbumVideoCached(circleObject, userCircleCache.circlePath!, item) ||
              !VideoCacheService.isAlbumPreviewCached(
                  circleObject, userCircleCache.circlePath!, item))

          ///need only check for preview, as downloading video happens when user requests!!
          {
            DownloadObject obj =
                DownloadObject(circleObject: circleObject, item: item);
            if (!_downloads.contains(obj)) {
              _downloads.add(obj);
            }
          } else {
            if (item.video!.videoState == VideoStateIC.UNKNOWN) {
              item.video!.videoState = VideoStateIC.VIDEO_DOWNLOADED;
            }
          }
        }
      } else if (item.type == AlbumItemType.GIF) {
        ///no download needed
      }

      ///check if last item in album
      if (circleObject.album!.media.indexOf(item) ==
          circleObject.album!.media.length - 1) {
        if (_downloads.isNotEmpty) {
          circleObject.fullTransferState = BlobState.DOWNLOADING;
          _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);

          _downloadQueueOfQueues.add(_downloads);
          if (_downloadQueueOfQueues.length == 1) {
            ///triggering queue processing
            debugPrint("triggering queue processing, length is " +
                _downloadQueueOfQueues.length.toString());
            _downloadNextBatch(userCircleCache, userFurnace, callbackBloc);
          }
        } else {
          ///downloads empty
          _downloadObjects.remove(circleObject.id!);
          _globalEventBloc.broadcastAlbumDownloaded(circleObject);
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  notifyWhenAlbumReady(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, CircleObjectBloc callbackBloc) async {
    ///when album updated, give more retries?

    if (circleObject.draft ||
        circleObject.fullTransferState == BlobState.UPLOADING ||
        circleObject.transferPercent != null ||
        circleObject.fullTransferState == BlobState.UPLOADED_BLOB_ONLY ||
        circleObject.fullTransferState == BlobState.DOWNLOADING ||
        circleObject.id == null ||
        circleObject.circle!.id == DeviceOnlyCircle.circleID ||
        _globalEventBloc.deletedSeeds.contains(circleObject.seed) ||
        _downloadObjects.contains(circleObject.id!) ||
        _globalEventBloc.albumExists(circleObject)) {
      return;
    } else {
      ///album shouldn't exist in download objects nor global event bloc
      _globalEventBloc.addAlbumObject(circleObject);
      _downloadObjects.add(circleObject.id!);
      _queueAlbum(circleObject, userCircleCache, userFurnace, callbackBloc);
    }
  }

  updateAlbumOrder(UserFurnace userFurnace, CircleObject circleObject,
      List<AlbumItem> items) {
    try {
      for (AlbumItem item in circleObject.album!.media) {
        int placeIndex = items.indexOf(item);
        if (placeIndex != -1) {
          item.index = placeIndex;
        }
      }

      _circleAlbumService.updateAlbumOrder(userFurnace, circleObject);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumBloc.updateAlbumOrder: $error");
    }
  }

  Future<CircleObject> addCacheMedia(
    CircleObject circleObject,
    List<Media> mediaCollection,
    bool hiRes,
  ) async {
    circleObject.thumbnailTransferState = BlobState.UPLOADING;
    circleObject.fullTransferState = BlobState.UPLOADING;
    _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
    TableCircleObjectCache.updateCacheSingleObject(
        globalState.userFurnace!.userid!, circleObject);

    try {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      for (Media media in mediaCollection) {
        if (media.mediaType == MediaType.image) {
          ThumbnailDimensions thumbnailDimensions =
              ThumbnailDimensions.getDimensionsFromFile(media.file);
          String name = FileSystemService.getFilename(media.file.path);
          String ext = FileSystemService.getExtension(media.file.path);

          String nameCropped =
              name.substring(0, name.length - (ext.length + 1));

          String thumbnailPath = ImageCacheService.returnAlbumImagePath(
              circlePath, circleObject, true, nameCropped, ext);
          String fullImagePath = ImageCacheService.returnAlbumImagePath(
              circlePath, circleObject, false, nameCropped, ext);

          File thumbnail = File(thumbnailPath);
          File full = File(fullImagePath);

          await _imageCacheService.copyFullAndThumbnail(
              circleObject, thumbnailPath, fullImagePath, media.file, true,
              hiRes: hiRes);

          CircleImage image = CircleImage(
            height: thumbnailDimensions.height,
            width: thumbnailDimensions.width,
            fullImageSize: full.lengthSync(),
            thumbnailSize: thumbnail.lengthSync(),
            thumbnail: '${nameCropped}_thumbnail.jpg',
            fullImage: '${nameCropped}_full.jpg',
          );

          image.fullFile = full;
          image.thumbnailFile = thumbnail;

          AlbumItem item = AlbumItem(
            id: const Uuid().v4(),
            index: circleObject.album!.media.length,
            type: AlbumItemType.IMAGE,
            image: image,
            thumbnailTransferState: BlobState.CACHED,
            fullTransferState: BlobState.CACHED,
          );

          circleObject.album!.media.add(item);

          media.file.delete();
        } else if (media.mediaType == MediaType.video) {
          String name = FileSystemService.getFilename(media.file.path);
          String ext = FileSystemService.getExtension(media.file.path);

          String nameCropped =
              name.substring(0, name.length - (ext.length + 1));

          CircleVideo video = CircleVideo(
            videoState: VideoStateIC.VIDEO_READY,
            extension: FileSystemService.getExtension(media.path),
            sourceVideo: media.path,
            streamable: false,
            preview: '${nameCropped}_preview.jpg',
            video: '${name}',
          );

          AlbumItem item = AlbumItem(
            id: const Uuid().v4(),
            index: circleObject.album!.media.length,
            type: AlbumItemType.VIDEO,
            video: video,
          );

          File cachedVideo = await VideoCacheService.cacheAlbumVideo(
              circleObject.userCircleCache!,
              circleObject,
              media.file,
              nameCropped);

          late File thumbnail;
          try {
            thumbnail = await VideoCacheService.cacheAlbumVideoPreview(
                circleObject.userCircleCache!,
                circleObject,
                cachedVideo,
                0,
                false,
                nameCropped,
                item);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            //use the default image background from the assets folder
            String previewPath = VideoCacheService.returnPreviewPath(
                circleObject, circleObject.userCircleCache!.circlePath!);
            thumbnail = File(previewPath);

            final byteData =
                await rootBundle.load('assets/images/nopreview.jpg');

            await thumbnail.writeAsBytes(byteData.buffer
                .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          }

          item.video!.previewSize = thumbnail.lengthSync();
          item.video!.videoSize = cachedVideo.lengthSync();
          item.video!.videoState = VideoStateIC.NEEDS_CHEWIE;

          item.thumbnailTransferState = BlobState.READY;
          item.fullTransferState = BlobState.READY;

          circleObject.album!.media.add(item);
        }
      }

      circleObject.thumbnailTransferState = BlobState.READY;

      circleObject = await _circleObjectService.cacheCircleObject(circleObject);
      TableCircleObjectCache.updateCacheSingleObject(
          globalState.userFurnace!.userid!, circleObject);

      _currentMedia.sink.add(circleObject.album!.media);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleAlbumBloc.addCacheMedia: $err");
    }
    return circleObject;
  }

  Future<CircleObject> cacheToDevice(
    List<Media> mediaCollection,
    bool hiRes,
    CircleObjectBloc callbackBloc,
  ) async {
    CircleObject circleObject = CircleObject(
        type: CircleObjectType.CIRCLEALBUM,
        album: CircleAlbum(media: []),
        creator: globalState.user,
        hiRes: hiRes,
        body: '',
        circle: Circle(id: DeviceOnlyCircle.circleID, privacyShareImage: true),
        ratchetIndexes: []);

    ///cache object
    CircleObject cacheObject =
        await _circleAlbumHelperBloc.makeCacheObject(circleObject);

    cacheObject.thumbnailTransferState = BlobState.UPLOADING;
    cacheObject.fullTransferState = BlobState.UPLOADING;
    _globalEventBloc.broadcastProgressThumbnailIndicator(cacheObject);
    TableCircleObjectCache.updateCacheSingleObject(
        globalState.userFurnace!.userid!, cacheObject);

    try {
      String circlePath = await FileSystemService.returnCirclesDirectory(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      // cacheObject = CircleObject(
      //   type: CircleObjectType.CIRCLEALBUM,
      //   album: CircleAlbum(media: []),
      //   creator: globalState.user,
      //   hiRes: hiRes,
      //   body: '',
      //   circle: Circle(id: DeviceOnlyCircle.circleID, privacyShareImage: true),
      //   ratchetIndexes: []);

      cacheObject.userCircleCache = UserCircleCache(
          circlePath: circlePath, prefName: DeviceOnlyCircle.prefName);
      cacheObject.userFurnace = globalState.userFurnace;

      cacheObject.initDates();

      cacheObject.seed = const Uuid().v4();
      cacheObject.id = cacheObject.seed;
      //cacheObject.storageID = image.storageID.isEmpty ? const Uuid().v4() : image.storageID;
      cacheObject.storageID = const Uuid().v4();

      for (Media media in mediaCollection) {
        // int index = mediaCollection.indexOf(media);
        // AlbumItem item = AlbumItem(
        //   index: index,
        //   type: AlbumItemType.IMAGE,
        // );
        // cacheObject.album!.media.add(item);
        if (media.mediaType == MediaType.image) {
          // _cacheImage(cacheObject, cacheObject.userCircleCache!, cacheObject.userFurnace!, media.file,
          //     hiRes, callbackBloc, index);
          // await Future.delayed(const Duration(milliseconds: 100));

          ThumbnailDimensions thumbnailDimensions =
              ThumbnailDimensions.getDimensionsFromFile(media.file);

          String name = FileSystemService.getFilename(media.file.path);
          String ext = FileSystemService.getExtension(media.file.path);

          String nameCropped =
              name.substring(0, name.length - (ext.length + 1));

          String thumbnailPath = ImageCacheService.returnAlbumImagePath(
              circlePath, cacheObject, true, nameCropped, ext);
          String fullImagePath = ImageCacheService.returnAlbumImagePath(
              circlePath, cacheObject, false, nameCropped, ext);

          File thumbnail = File(thumbnailPath);
          File full = File(fullImagePath);

          // ? pathBuilder = '${pathBuilder}_thumbnail.jpg'
          //     : pathBuilder = '${pathBuilder}_full.jpg';

          await _imageCacheService.copyFullAndThumbnail(
              cacheObject, thumbnailPath, fullImagePath, media.file, true,
              hiRes: hiRes);

          CircleImage image = CircleImage(
            height: thumbnailDimensions.height,
            width: thumbnailDimensions.width,
            fullImageSize: full.lengthSync(),
            thumbnailSize: thumbnail.lengthSync(),
            thumbnail: '${nameCropped}_thumbnail.jpg',
            fullImage: '${nameCropped}_full.jpg',
            // fullFile: full,
            // thumbnailFile: thumbnail,
          );

          image.fullFile = full;
          image.thumbnailFile = thumbnail;

          AlbumItem item = AlbumItem(
            id: const Uuid().v4(),
            index: cacheObject.album!.media.length,
            type: AlbumItemType.IMAGE,
            image: image,
            thumbnailTransferState: BlobState.CACHED,
            fullTransferState: BlobState.CACHED,
          );

          cacheObject.album!.media.add(item);

          media.file.delete();
        } else if (media.mediaType == MediaType.video) {
          // _cacheVideo(cacheObject, cacheObject.userCircleCache!, cacheObject.userFurnace!, media.file, //File(media.path),
          //     media.streamable, media.thumbIndex, false, callbackBloc, index);
          // await Future.delayed(const Duration(milliseconds: 100));

          String name = FileSystemService.getFilename(media.file.path);
          String ext = FileSystemService.getExtension(media.file.path);

          String nameCropped =
              name.substring(0, name.length - (ext.length + 1));

          CircleVideo video = CircleVideo(
            videoState: VideoStateIC.VIDEO_READY,
            extension: FileSystemService.getExtension(media.path),
            sourceVideo: media.path,
            streamable: false,
            preview: '${nameCropped}_preview.jpg',
            video: '${name}',
          );

          AlbumItem item = AlbumItem(
            id: const Uuid().v4(),
            index: cacheObject.album!.media.length,
            type: AlbumItemType.VIDEO,
            video: video,
            // thumbnailTransferState:
            //   fullTransferState:
          );

          ///don't delete the source. It may be being used in another circle. Garbage collect later
          //media.file.delete();

          File cachedVideo = await VideoCacheService.cacheAlbumVideo(
              cacheObject.userCircleCache!,
              cacheObject,
              media.file,
              nameCropped);

          late File thumbnail;
          try {
            thumbnail = await VideoCacheService.cacheAlbumVideoPreview(
                cacheObject.userCircleCache!,
                cacheObject,
                cachedVideo,
                0,
                false,
                nameCropped,
                item);
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            //use the default image background from the assets folder
            String previewPath = VideoCacheService.returnPreviewPath(
                cacheObject, cacheObject.userCircleCache!.circlePath!);
            thumbnail = File(previewPath);

            final byteData =
                await rootBundle.load('assets/images/nopreview.jpg');

            await thumbnail.writeAsBytes(byteData.buffer
                .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          }

          item.video!.previewSize = thumbnail.lengthSync();
          item.video!.videoSize = cachedVideo.lengthSync();
          item.video!.videoState = VideoStateIC.NEEDS_CHEWIE;

          item.thumbnailTransferState = BlobState.READY;
          item.fullTransferState = BlobState.READY;

          cacheObject.album!.media.add(item);
        }
      }

      cacheObject.thumbnailTransferState = BlobState.READY;

      cacheObject = await _circleObjectService.cacheCircleObject(cacheObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleAlbumBloc.cacheToDevice: $err");
    }
    return cacheObject;
  }

  dispose() async {
    await _currentMedia.drain();
    _currentMedia.close();

    await _mediaDeleted.drain();
    _mediaDeleted.close();

    await _imageSaved.drain();
    _imageSaved.close();

    await _putFailed.drain();
    _putFailed.close();
  }
}
