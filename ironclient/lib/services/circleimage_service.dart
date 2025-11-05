import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CallbackType {
  static const int FULLIMAGE = 0;
  static const int THUMBNAIL = 1;
}

class CircleImageService {
  CircleImageService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  late GlobalEventBloc _globalEventBloc;
  final BlobUrlsService _blobUrlsService = BlobUrlsService();
  final BlobService _blobService = BlobService();

  Future<void> get(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      Function failedThumbCallback,
      Function failedFullCallback) async {
    try {
      BlobUrl? urls;

      if (circleObject.image!.location == BlobLocation.S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_WASABI) {
        urls = await _blobUrlsService.getDownloadUrls(
          userFurnace,
          BlobType.IMAGE,
          circleObject.id!,
          circleObject.image!.fullImage!,
          circleObject.image!.thumbnail!,
        );
      }

      getThumbnail(
          userFurnace, userCircleCache, circleObject, failedThumbCallback,
          url: urls);
      getFull(userFurnace, userCircleCache, circleObject, failedFullCallback,
          url: urls);

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageService2.get: $err');
      failedThumbCallback(userFurnace, userCircleCache, circleObject);
      failedFullCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<void> getThumbnail(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      Function failedCallback,
      {BlobUrl? url}) async {
    try {
      if (circleObject.draft) return;

      String thumbPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject);

      if (circleObject.image!.location == BlobLocation.S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_WASABI) {
        late BlobUrl urls;

        if (url != null)
          urls = url;
        else
          urls = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.IMAGE,
            circleObject.id!,
            circleObject.image!.fullImage!,
            circleObject.image!.thumbnail!,
          );

        _blobService.get(userFurnace, circleObject.image!.location!,
            urls.thumbnailUrl, thumbPath, circleObject.id!,
            progressCallback: _progressThumbnailDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      } else {
        _blobService.get(
            userFurnace,
            circleObject.image!.location!,
            userFurnace.url! +
                Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_THUMBNAIL +
                circleObject.image!.thumbnail!,
            thumbPath,
            circleObject.id!,
            progressCallback: _progressThumbnailDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      }

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageService2.getThumbnail: $err');
      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<void> getFull(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, Function failedCallback,
      {BlobUrl? url}) async {
    try {
      //debugPrint('CircleImageService2.get');

      String fullPath = ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, circleObject);

      //String thumbPath =
      ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject);

      if (circleObject.image!.location == BlobLocation.S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.image!.location == BlobLocation.PRIVATE_WASABI) {
        late BlobUrl urls;

        if (url != null)
          urls = url;
        else
          urls = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.IMAGE,
            circleObject.id!,
            circleObject.image!.fullImage!,
            circleObject.image!.thumbnail!,
          );

        _blobService.get(userFurnace, circleObject.image!.location!,
            urls.fileNameUrl, fullPath, circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      } else {
        _blobService.get(
            userFurnace,
            circleObject.image!.location!,
            userFurnace.url! +
                Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
                circleObject.image!.fullImage!,
            fullPath,
            circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      }

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImageService2.get: $err');
      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  _progressThumbnailDownloadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    //debugPrint('hello?');

    try {
      if (progress == -1) {
        _globalEventBloc.removeThumbOnError(circleObject);
        failedCallback(userFurnace, userCircleCache, circleObject);
      }

      if (progress == 100) {
        String path = ImageCacheService.returnThumbnailPath(
            userCircleCache.circlePath!, circleObject);

        File encrypted = File('${path}enc');

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.thumbnailTransferState = BlobState.DECRYPTING;
          //_globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);

          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          ///was there a prior image with the same seed? should only happen if someone edited the image
          File existing = File(path);
          if (existing.existsSync()) {
            await existing.delete();
            //imageCache!.clear();
            PaintingBinding.instance.imageCache.clear();
          }

          ///if we are on desktop, don't decrypt the file
          if (globalState.isDesktop()) {


            ///the file is currently named seed.jpgenc
            ///leave the file type as enc only
            encrypted.rename(path);
          } else {
            bool success = await EncryptBlob.decryptBlob(DecryptArguments(
                encrypted: encrypted,
                nonce: circleObject.image!.thumbCrank!,
                mac: circleObject.image!.thumbSignature!,
                key: circleObject.secretKey));

            if (!success) {
              circleObject.thumbnailTransferState =
                  BlobState.BLOB_DOWNLOAD_FAILED;
              //circleObject.retries = RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;
              throw ('unable to decrypt image');
            }
          }
        } else {
          if (await encrypted.exists()) {
            try {
              await encrypted.rename(path);
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
              debugPrint('$err');
            }
          }
        }

        //circleObject.image!.thumbnail = path;
        circleObject.image!.thumbnailFile = File(path);
        circleObject.thumbnailTransferState = BlobState.READY;
        _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'CircleImageService2._progressThumbnailDownloadCallback');

      DownloadFailedReason? reason;

      if (err.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      BlobService.safeCancel(cancelToken);
      failedCallback(userFurnace, userCircleCache, circleObject,
          reason: reason);
    }
  }

  progressDownloadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    try {
      //throw('chaos');

      if (progress == -1) {
        _globalEventBloc.removeFullOnError(circleObject);
        failedCallback(userFurnace, userCircleCache, circleObject);
        return;
      }

      if (progress == 100) {
        String path = ImageCacheService.returnFullImagePath(
            userCircleCache.circlePath!, circleObject);

        File encrypted = File('${path}enc');
        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          File existing = File(path);

          if (existing.existsSync()) {
            //should only happen if someone edited the image
            await existing.delete();
            imageCache.clear();
          }

          ///if we are on desktop, don't decrypt the file
          if (globalState.isDesktop()) {
            ///the file is currently named seed.jpgenc
            ///leave the file type as enc only
            encrypted.rename(path);
          } else {
            bool success = await EncryptBlob.decryptBlob(DecryptArguments(
                encrypted: encrypted,
                nonce: circleObject.image!.fullCrank!,
                mac: circleObject.image!.fullSignature!,
                key: circleObject.secretKey));

            if (!success) {
              ///TODO need to handle this better, the user can see the thumbnail, even full screen
              return;
              circleObject.retries = circleObject.retries + 1;
              if (circleObject.retries >= 2) {
                circleObject.fullTransferState = BlobState.BLOB_DOWNLOAD_FAILED;

                throw ('unable to decrypt image');
              }
            }
          }
        } else {
          if (await encrypted.exists()) {
            try {
              await encrypted.rename(path);
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
              debugPrint('$err');
            }
          }
        }

        circleObject.fullTransferState = BlobState.READY;
        circleObject.transferPercent = progress;
        circleObject.nonUIRetries = 0;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleImage2Service.progressCallback: $err');
      BlobService.safeCancel(cancelToken);

      DownloadFailedReason? reason;

      if (err.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      //_globalEventBloc.removeFullOnError(circleObject);
      _globalEventBloc.removeThumbOnError(circleObject);
      failedCallback(userFurnace, userCircleCache, circleObject,
          reason: reason);
    }
  }

  _progressThumbnailUploadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress) async {
    return;
  }

  progressUploadCallback(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int progress) async {
    try {
        circleObject.transferPercent = progress;
        _globalEventBloc.broadcastProgressIndicator(circleObject);
    } catch (err) {
      //ogBloc.insertError(err, trace);
      debugPrint('CircleImage2Service.progressCallback: $err');
    }
  }

  Future<BlobUrl?> getUploadUrls(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File file,
      File thumbnail,
      ) async {
    try {
      ///if this uses unique local storage, use the seed instead of the file name

      //get the location to save this
      BlobUrl urls = await _blobUrlsService.getUploadUrls(userFurnace,
          BlobType.IMAGE, userCircleCache.circle!, file.path, thumbnail.path);

      return urls;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2.getUploadUrls: $err");

      rethrow;
    }
  }

  Future<CircleObject> encryptHotSwap(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject encryptedCopy,
    File file,
  ) async {
    // CircleObject encryptedCopy = circleObject;

    try {
      // encryptedCopy =
      // await ForwardSecrecy.encryptCircleObject(userFurnace, encryptedCopy);

      DecryptArguments fullArgs = await EncryptBlob.encryptBlob(
          ImageCacheService.returnFullImagePath(
              userCircleCache.circlePath!, encryptedCopy),
          secretKey: encryptedCopy.secretKey!);

      //Set the stuff
      encryptedCopy.image!.fullSignature = fullArgs.mac;
      encryptedCopy.image!.fullCrank = fullArgs.nonce;

      return encryptedCopy;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2.encryptHotSwap: $err");

      rethrow;
    }
  }

  Future<CircleObject> encryptFiles(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File file,
      File thumbnail,
      BlobUrl blobUrl) async {

    try {
      circleObject.secretKey = await ForwardSecrecy.genSecretKey();

      circleObject.transferUrls = blobUrl;

      debugPrint(ImageCacheService.returnFullImagePath(
          userCircleCache.circlePath!, circleObject));
      debugPrint(ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject));

      DecryptArguments fullArgs = await EncryptBlob.encryptBlob(
          ImageCacheService.returnFullImagePath(
              userCircleCache.circlePath!, circleObject),
          secretKey: circleObject.secretKey!);

      DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(
          ImageCacheService.returnThumbnailPath(
              userCircleCache.circlePath!, circleObject),
          secretKey: circleObject.secretKey!);

      //Set the stuff
      circleObject.image!.fullSignature = fullArgs.mac;
      circleObject.image!.fullCrank = fullArgs.nonce;
      circleObject.image!.thumbSignature = thumbArgs.mac;
      circleObject.image!.thumbCrank = thumbArgs.nonce;
      //encryptedCopy.image!.width = circleObject.image!.width;
      //encryptedCopy.image!.height = circleObject.image!.height;

      //set encrypted
      circleObject.thumbnailTransferState = BlobState.ENCRYPTED;
      circleObject.fullTransferState = BlobState.ENCRYPTED;
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      //revert before displaying on screen, not sent to server
      circleObject.encryptedBody = circleObject.body;
      circleObject.body = circleObject.body;

      return circleObject;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2.encryptFiles: $err");

      rethrow;
    }
  }

  postThumbnail(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, [String? fileName, BlobUrl? urls]) async {
    try {
      //String fileUrl;
      String thumbnailUrl;

      //throw('chaos');

      //var requestMultipart = http.MultipartRequest("", Uri.parse("uri"));
      File encryptedThumb = File(
            ("${ImageCacheService.returnThumbnailPath(userCircleCache.circlePath!, encryptedCopy)}enc"));

      if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_WASABI) {
        // fileUrl = encryptedCopy.transferUrls!.fileNameUrl;
        thumbnailUrl = encryptedCopy.transferUrls!.thumbnailUrl;

        //print(thumbnailUrl);
       //print(encryptedThumb.path);

        //fire off the thumbnail
        await _blobService.putWithRetry(
            userFurnace, thumbnailUrl, encryptedThumb,
            userCircleCache: userCircleCache,
            circleObject: encryptedCopy,
            progressCallback: progressUploadCallback,
            broadcastQuarterOnly: true,
            loggingTag: "postThumbnail");
      } else {
        File encryptedFull = File(
            ("${ImageCacheService.returnFullImagePath(userCircleCache.circlePath!, encryptedCopy)}enc"));

        String fileUrl = userFurnace.url! + Urls.GRIDFS_UPLOAD_DUAL;
        //thumbnailUrl = userFurnace.url! + Urls.CIRCLEIMAGETHUMBNAIL;

       //print(fileUrl);
        //print(encryptedFull.path);

        _blobService.putGridFSDual(
            userFurnace,
            fileUrl,
            userCircleCache.circle!,
            encryptedFull,
            encryptedThumb,
            encryptedCopy,
            userCircleCache,
            progressUploadCallback,
            _progressThumbnailUploadCallback);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2.postThumbnail: $err");
      rethrow;
    }
  }

  postFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, String? fileName, BlobUrl? urls,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      String fileUrl;

      File encryptedFull = File(
            ("${ImageCacheService.returnFullImagePath(userCircleCache.circlePath!, encryptedCopy)}enc"));

      if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_WASABI) {
        fileUrl = encryptedCopy.transferUrls!.fileNameUrl;

        await _blobService.putWithRetry(userFurnace, fileUrl, encryptedFull,
            userCircleCache: userCircleCache,
            circleObject: encryptedCopy,
            progressCallback: progressUploadCallback,
            broadcastProgress: 25,
            maxRetries: maxRetries,
            loggingTag: "postFull");
      } else {
        File encryptedThumb = File(
            ("${ImageCacheService.returnThumbnailPath(userCircleCache.circlePath!, encryptedCopy)}enc"));

        fileUrl = userFurnace.url! + Urls.GRIDFS_UPLOAD_DUAL;
        //thumbnailUrl = userFurnace.url! + Urls.CIRCLEIMAGETHUMBNAIL;

        _blobService.putGridFSDual(
            userFurnace,
            fileUrl,
            userCircleCache.circle!,
            encryptedFull,
            encryptedThumb,
            encryptedCopy,
            userCircleCache,
            progressUploadCallback,
            _progressThumbnailUploadCallback);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2.postFull: $err");
      rethrow;
    }
  }

  Future<CircleObject> postCircleImage(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    late CircleObject revertTo;

    try {
      //Dio dio = Dio();

      String url = userFurnace.url! + Urls.CIRCLEIMAGE_OBJECT_ONLY;

      debugPrint(url);

      if (_globalEventBloc.deletedSeeds.contains(circleObject.seed))
        throw ("tried to send a deleted image");

      if (circleObject.secretKey == null)
        throw ("error occurred. delete image and try again");

      var encoded = json.encode(circleObject.toJson()).toString();
      revertTo = CircleObject.fromJson(json.decode(encoded));

      circleObject.image!.fullFile = null;
      circleObject.image!.thumbnailFile = null;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      //print(encryptedCopy.secretKey);

      encryptedCopy.image!.blankEncryptionFields();

      //throw('chaos');
      Device device = await globalState.getDevice();

      Map map = {
        'circleid': circleObject.circle!.id,
        'userid': userFurnace.userid,
        'pushtoken': device.pushToken,
        'device': device.uuid,
        'apikey': userFurnace.apikey,
        'creator': circleObject.creator!.id,
        'circle': circleObject.circle!.id,
        'seed': circleObject.seed,
        'storageID': circleObject.storageID,
        'body': encryptedCopy.body,
        'type': circleObject.type,
        'image': encryptedCopy.image,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
      };

      String waitingOn = CircleObject.getWaitingOn(circleObject);

      if (waitingOn.isNotEmpty) {
        map["waitingOn"] = waitingOn;
      }


      if (circleObject.timer != null) {
        map["timer"] = circleObject.timer;
      }
      if (circleObject.scheduledFor != null) {
        String scheduled =
            encryptedCopy.scheduledFor.toString().substring(0, 17);
        String time = circleObject.dateIncrement.toString();
        String scheduledTime = scheduled + time;
        map["scheduledFor"] = scheduledTime;
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http
          .post(Uri.parse(url),
              headers: {
                'Authorization': userFurnace.token!,
                'Content-Type': "application/json",
              },
              body: json.encode(map))
          .timeout(const Duration(seconds: RETRIES.TIMEOUT_API_IMAGE));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        return _processPostResult(
            jsonResponse, userFurnace, userCircleCache, circleObject, revertTo);
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return circleObject;
      } else if (response.statusCode == 400) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        return _processPostResult(
            jsonResponse, userFurnace, userCircleCache, circleObject, revertTo);
      } else {
        debugPrint(
            'CircleImageService2._postCircleImage failed: ${response.statusCode}');
        debugPrint(response.body);

        throw ('CircleImageService2._postCircleImage failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
// The request was made and the server responded with a status code
// that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
// Something happened in setting up or sending the request that triggered an Error

        debugPrint(e.message);

        debugPrint("CircleImageService2._postCircleImage: $e");
      }

      rethrow;
    } catch (err, trace) {
      globalState.forcedOrder.removeWhere((element) => element.seed == circleObject.seed);
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2._postCircleImage: $err");

      circleObject.revertEncryptedFields(revertTo);
      rethrow;
    }

    //return null;
  }

  Future<CircleObject> _processPostResult(
      Map<String, dynamic> jsonResponse,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      CircleObject revertTo) async {
    CircleObject retValue = CircleObject.fromJson(jsonResponse["circleobject"]);
    //retValue.body = circleObject.body; //revert to unencrypted

    retValue.revertEncryptedFields(revertTo);

    if (circleObject.created!.difference(retValue.created!) < const Duration(minutes: 10)) {
      ///use the local date
      retValue.created = circleObject.created!;
    }

    retValue.fullTransferState = BlobState.READY;
    retValue.transferPercent = 100;
    retValue.circle = circleObject.circle;
    retValue.image!.imageBytes = circleObject.image!.imageBytes;
    //retValue.ratchetIndexes = circleObject.ratchetIndexes;
    await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, retValue);

    TableUserCircleCache.updateLastItemUpdate(
        retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

    if (circleObject.timer != null) {
      _globalEventBloc.startTimer(circleObject.timer!, circleObject);
    }

    // ForwardSecrecy.ratchetReceiverKey(
    //    userFurnace, circleObject.circle!.id!, userCircleCache.usercircle!);

    _globalEventBloc.broadcastProgressIndicator(retValue);

    return retValue;
  }

  Future<CircleObject> putCircleImage(UserCircleCache userCircleCache,
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      //Dio dio = Dio();

      String url =
          userFurnace.url! + Urls.CIRCLEIMAGE_OBJECT_ONLY + 'undefined';

      if (circleObject.secretKey == null)
        throw ("error occurred. delete image and try again");

      debugPrint(url);

      var encoded = json.encode(circleObject.toJson()).toString();
      CircleObject revertTo = CircleObject.fromJson(json.decode(encoded));

      circleObject.image!.fullFile = null;
      circleObject.image!.thumbnailFile = null;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      encryptedCopy.image!.blankEncryptionFields();

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': circleObject.circle!.id,
        'userid': userFurnace.userid,
        'pushtoken': device.pushToken,
        'apikey': userFurnace.apikey,
        'creator': circleObject.creator!.id,
        'circle': circleObject.circle!.id,
        'seed': circleObject.seed,
        'storageID': circleObject.storageID,
        'body': encryptedCopy.body,
        'type': circleObject.type,
        'image': encryptedCopy.image,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'circleObjectID': circleObject.id!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http
          .put(Uri.parse(url),
              headers: {
                'Authorization': userFurnace.token!,
                'Content-Type': "application/json",
              },
              body: json.encode(map))
          .timeout(const Duration(seconds: RETRIES.TIMEOUT_API_IMAGE));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        CircleObject retValue =
            CircleObject.fromJson(jsonResponse["circleobject"]);

        retValue.revertEncryptedFields(revertTo);

        retValue.editing = false;
        retValue.body = circleObject.body; //revert to unencrypted
        retValue.fullTransferState = BlobState.READY;
        retValue.transferPercent = 100;
        //retValue.ratchetIndexes = circleObject.ratchetIndexes;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, retValue);

        TableUserCircleCache.updateLastItemUpdate(
            retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

        _globalEventBloc.broadcastProgressIndicator(retValue);

        return retValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return circleObject;
      } else {
        debugPrint(
            'CircleImageService2._putCircleImage failed: ${response.statusCode}');
        debugPrint(response.body);

        throw ('CircleImageService2._putCircleImage failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
// The request was made and the server responded with a status code
// that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        debugPrint(e.response!.data);
        debugPrint(e.response!.headers.toString());
      } else {
// Something happened in setting up or sending the request that triggered an Error

        debugPrint(e.message);

        debugPrint("CircleImageService2._putCircleImage: $e");
      }

      rethrow;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2._putCircleImage: $err");
      rethrow;
    }

    //return null;
  }
}
