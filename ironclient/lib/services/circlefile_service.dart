import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CircleFileService {
  late GlobalEventBloc _globalEventBloc;
  final BlobUrlsService _blobUrlsService = BlobUrlsService();
  final BlobService _blobService = BlobService();

  CircleFileService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  Future<BlobUrl?> getUploadUrl(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File file,
      CircleObjectBloc callbackBloc) async {
    try {
      //get the location to save this
      BlobUrl url = await _blobUrlsService.getUploadUrl(
        userFurnace,
        BlobType.FILE,
        userCircleCache.circle!,
        file.path,
      );

      return url;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleFileService.getUploadUrls: $err");

      rethrow;
    }
  }

  Future<CircleObject> encryptFile(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      File file,
      BlobUrl blobUrl) async {
    try {
      CircleObject encryptedCopy = circleObject;

      encryptedCopy.secretKey = await ForwardSecrecy.genSecretKey();

      encryptedCopy.transferPercent = 1;
      encryptedCopy.fullTransferState = BlobState.UPLOADING;

      encryptedCopy.file!.fileSize = file.lengthSync();
      encryptedCopy.file!.location = blobUrl.location;
      encryptedCopy.file!.file = blobUrl.fileName;

      /*encryptedCopy.file = CircleFile(
          name: FileSystemService.getFilename(file.path),
          file: blobUrl.fileName,
          fileSize: file.lengthSync(),
          location: blobUrl.location);

       */

      DecryptArguments fullArgs = await EncryptBlob.encryptBlob(file.path,
          secretKey: encryptedCopy.secretKey!);

      ///Set the stuff
      encryptedCopy.file!.fileSignature = fullArgs.mac;
      encryptedCopy.file!.fileCrank = fullArgs.nonce;

      ///revert before displaying on screen, not sent to server
      encryptedCopy.encryptedBody = encryptedCopy.body;
      encryptedCopy.body = circleObject.body;

      //set encrypted
      encryptedCopy.fullTransferState = BlobState.ENCRYPTED;
      TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _globalEventBloc.broadcastProgressIndicator(encryptedCopy);

      return encryptedCopy;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleFileService.encryptFiles: $err");

      rethrow;
    }
  }

  progressUploadThumbnailCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress) async {}
  progressUploadCallback(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int progress) async {
    try {
      circleObject.transferPercent = progress;
      _globalEventBloc.broadcastProgressIndicator(circleObject);
    } catch (err) {
      //ogBloc.insertError(err, trace);
      debugPrint('CircleFileService.progressCallback: $err');
    }
  }

  postFile(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject encryptedCopy,
    File encryptedFull, {
    maxRetries = RETRIES.MAX_FILE_UPLOAD_RETRIES,
  }) async {
    try {
      String fileUrl;

      if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_WASABI) {
        fileUrl = encryptedCopy.transferUrls!.fileNameUrl;

        await _blobService.putWithRetry(userFurnace, fileUrl, encryptedFull,
            userCircleCache: userCircleCache,
            circleObject: encryptedCopy,
            progressCallback: progressUploadCallback,
            maxRetries: maxRetries);
      } else {
        ///TODO Gridfs
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleFileService.postFull: $err");
      rethrow;
    }
  }

  Future<CircleObject> postCircleFile(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    late CircleObject revertTo;

    try {
      //Dio dio = Dio();

      String url = userFurnace.url! + Urls.CIRCLEFILE_OBJECT_ONLY;

      debugPrint(url);

      if (_globalEventBloc.deletedSeeds.contains(circleObject.seed))
        throw ("tried to send a deleted file");

      if (circleObject.secretKey == null)
        throw ("error occurred. delete file and try again");

      var encoded = json.encode(circleObject.toJson()).toString();
      revertTo = CircleObject.fromJson(json.decode(encoded));

      circleObject.file!.actualFile = null;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      encryptedCopy.file!.blankEncryptionFields();
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
        'body': encryptedCopy.body,
        'type': circleObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'file': encryptedCopy.file,
        'taggedUsers': encryptedCopy.taggedUsers,
      };

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

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

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
        if (response.body.contains(
            'You cannot post when there is an active vote to remove you from the Circle')) {
          Map<String, dynamic> jsonResponse = json.decode(response.body);

          return _processPostResult(jsonResponse, userFurnace, userCircleCache,
              circleObject, revertTo);
        } else {
          debugPrint(
              'CircleFileService._postCircleFile failed: ${response.statusCode}');
          debugPrint(response.body);

          throw ('CircleFileService._postCircleFile failed: ${response.statusCode}');
        }
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
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2._postCircleImage: $err");

      circleObject.revertEncryptedFields(revertTo);
      rethrow;
    }

    //return null;
  }

  deleteCache(
      String userID, String circlePath, CircleObject circleObject) async {
    if (globalState.isDesktop()) {
      String path = FileCacheService.returnFilePath(
          circlePath, '${circleObject.seed}.enc');
      await FileSystemService.safeDelete(File(path));
    } else {
      await FileCacheService.deleteCache(circlePath, circleObject);
    }
    circleObject.fullTransferState = BlobState.UNKNOWN;
    circleObject.file!.actualFile = null;
    circleObject.transferPercent = 0;

    await TableCircleObjectCache.updateCacheSingleObject(userID, circleObject);
  }

  Future<CircleObject> _processPostResult(
      Map<String, dynamic> jsonResponse,
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      CircleObject revertTo) async {
    if (jsonResponse["msg"] != null) {
      if (jsonResponse["msg"].contains(
          'You cannot post when there is an active vote to remove you from the Circle')) {
        //throw ("You cannot post when there is an active vote to remove you from the Circle");
        _globalEventBloc.broadcastError(
            "You cannot post when there is an active vote to remove you from the Circle");
        return circleObject;
      }
    }

    CircleObject retValue = CircleObject.fromJson(jsonResponse["circleobject"]);
    //retValue.body = circleObject.body; //revert to unencrypted

    retValue.revertEncryptedFields(revertTo);

    retValue.fullTransferState = BlobState.READY;
    retValue.transferPercent = 100;
    retValue.circle = circleObject.circle!;

    retValue.file!.actualFile = File(FileCacheService.returnFilePath(
        userCircleCache.circlePath!,
        circleObject.seed! + circleObject.file!.extension!));

    await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, retValue);

    TableUserCircleCache.updateLastItemUpdate(
        retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

    if (retValue.timer != null) {
      _globalEventBloc.startTimer(retValue.timer!, retValue);
    }

    _globalEventBloc.broadcastProgressIndicator(retValue);

    return retValue;
  }

  progressCallbackDownload(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    try {
      debugPrint('progressCallbackDownload: $progress');

      if (progress == -1) {
        circleObject.fullTransferState = BlobState.BLOB_UPLOAD_FAILED;

        return;
      }

      if (progress == 100) {
        circleObject.transferPercent = progress;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        String filePath = FileCacheService.returnFilePath(
            userCircleCache.circlePath!,
            '${circleObject.seed!}.${circleObject.file!.extension!}');

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        if (globalState.isDesktop() == false) {
          if (circleObject.ratchetIndexes.isNotEmpty &&
              globalState.isDesktop() == false) {
            circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
                userCircleCache.usercircle!, circleObject);

            if (circleObject.secretKey!.isEmpty) throw ('could not find key');

            File encrypted = File('${filePath}enc');

            ///decrypt
            await EncryptBlob.decryptBlob(DecryptArguments(
                encrypted: encrypted,
                nonce: circleObject.file!.fileCrank!,
                mac: circleObject.file!.fileSignature!,
                key: circleObject.secretKey));
          }
        } else {
          File encrypted = File('${filePath}enc');
          await encrypted.rename(FileCacheService.returnFilePath(
              userCircleCache.circlePath!, '${circleObject.seed!}.enc'));
        }

        circleObject.fullTransferState = BlobState.READY;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastProgressIndicator(circleObject);
      } else {
        if (progress < 1)
          circleObject.transferPercent = 1;
        else
          circleObject.transferPercent = progress;

        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleFileBloc.progressCallbackDownload: $error");
      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<void> get(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, Function failedCallback) async {
    try {
      String filePath = FileCacheService.returnFilePath(
          userCircleCache.circlePath!,
          '${circleObject.seed!}.${circleObject.file!.extension!}');

      String url = '';

      if (circleObject.file!.location == BlobLocation.S3 ||
          circleObject.file!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.file!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl blobUrl = await _blobUrlsService.getDownloadUrl(
          userFurnace,
          BlobType.FILE,
          circleObject.id!,
          circleObject.file!.file!,
        );

        url = blobUrl.fileNameUrl;
      } else {
        if (circleObject.file!.file == null) return;

        url = userFurnace.url! +
            Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
            circleObject.file!.file!;
      }

      _blobService.get(
        userFurnace,
        circleObject.file!.location!,
        url,
        filePath,
        circleObject.id!,
        progressCallback: progressCallbackDownload,
        circleObject: circleObject,
        userCircleCache: userCircleCache,
        failedCallback: failedCallback,
      );

      //throw ('failed');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleFileService.get: $err');

      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }
}
