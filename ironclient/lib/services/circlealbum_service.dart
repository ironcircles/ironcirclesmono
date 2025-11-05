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

import '../models/album_item.dart';

class CircleAlbumService {
  CircleAlbumService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  final BlobUrlsService _blobUrlsService = BlobUrlsService();
  late GlobalEventBloc _globalEventBloc;
  final BlobService _blobService = BlobService();

  ///based off postCircleImage
  Future<CircleObject> postAlbum(
    UserCircleCache userCircleCache,
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEALBUM_OBJECT_ONLY;

      debugPrint(url);

      if (_globalEventBloc.deletedSeeds.contains(circleObject.seed))
        throw ("tried to send a deleted album");

      if (circleObject.secretKey == null)
        throw ("error occurred. delete album and try again");

      var encoded = json.encode(circleObject.toJson()).toString();
      CircleObject revertTo = CircleObject.fromJson(json.decode(encoded));

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      List<AlbumItem> items = encryptedCopy.album!.media;

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': circleObject.circle!.id,
        'userid': userFurnace.userid,
        'pushtoken': device.pushToken,
        'apikey': userFurnace.apikey,
        'device': device.uuid,
        'circle': circleObject.circle!.id,
        'creator': circleObject.creator!.id,
        'seed': circleObject.seed,
        'storageID': circleObject.storageID,
        'body': encryptedCopy.body,
        'type': circleObject.type,
        'items': items,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
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

        CircleObject retValue =
            CircleObject.fromJson(jsonResponse["circleObject"]);

        retValue.revertEncryptedFields(revertTo);
        CircleObject finalValue =
            await revertEncryptedAlbumFields(retValue, revertTo);

        finalValue.circle = circleObject.circle;
        finalValue.editing = false;
        finalValue.body = circleObject.body;
        finalValue.fullTransferState = BlobState.READY;
        finalValue.transferPercent = 100;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, finalValue);

        TableUserCircleCache.updateLastItemUpdate(finalValue.circle!.id,
            finalValue.creator!.id, finalValue.lastUpdate);

        if (circleObject.timer != null) {
          _globalEventBloc.startTimer(circleObject.timer!, circleObject);
        }
        _globalEventBloc.broadcastProgressIndicator(finalValue);

        return finalValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return circleObject;
      } else {
        debugPrint(
            'CircleAlbumService.postAlbum failed: ${response.statusCode}');
        debugPrint(response.body);

        throw ('CircleAlbumService.postAlbum failed: ${response.statusCode}');
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

        debugPrint("CircleAlbumService.postAlbum: $e");
      }

      rethrow;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumService.postAlbum: $error");
      rethrow;
    }
  }

  Future<CircleObject> putCircleAlbum(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      List<AlbumItem> changeItems,
      bool add) async {
    try {
      String url =
          userFurnace.url! + Urls.CIRCLEALBUM_OBJECT_ONLY + 'undefined';

      if (_globalEventBloc.deletedSeeds.contains(circleObject.seed))
        throw ("tried to send a deleted album");

      if (circleObject.secretKey == null)
        throw ("error occurred. delete image and try again");

      debugPrint(url);

      var encoded = json.encode(circleObject.toJson()).toString();
      CircleObject revertTo = CircleObject.fromJson(json.decode(encoded));

      CircleObject encrypting = CircleObject.fromJson(json.decode(encoded));
      //encrypting.album!.media = changeItems;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, encrypting);

      //List<AlbumItem> items = encryptedCopy.album!.media;

      Device device = await globalState.getDevice();

      List<AlbumItem> encryptedChangeItems = [];

      for (AlbumItem item in changeItems) {
        int? found = encryptedCopy.album!.media
            .indexWhere((element) => element.index == item.index);
        if (found != -1) {
          encryptedChangeItems.add(encryptedCopy.album!.media[found]);
        }
      }

      Map map = {
        'circleid': circleObject.circle!.id,
        'userid': userFurnace.userid,
        'pushtoken': device.pushToken,
        'apikey': userFurnace.apikey,
        'creator': circleObject.creator!.id,
        'device': device.uuid,
        'circle': circleObject.circle!.id,
        'seed': circleObject.seed,
        'storageID': circleObject.storageID,
        'body': encryptedCopy.body,
        'type': circleObject.type,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'items': encryptedCopy.album!.media,
        // 'newItems': add == true ? items : null,
        // 'deletedItems': add == true ? null : items,
        'newItems': add == true ? encryptedChangeItems : null,
        'deletedItems': add == true ? null : encryptedChangeItems,
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
            CircleObject.fromJson(jsonResponse["circleObject"]);

        retValue.revertEncryptedFields(revertTo);
        CircleObject finalValue =
            await revertEncryptedAlbumFields(retValue, revertTo);

        finalValue.circle = circleObject.circle;
        finalValue.editing = false;
        finalValue.body = circleObject.body;
        finalValue.fullTransferState = BlobState.READY;
        finalValue.transferPercent = 100;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, finalValue);

        TableUserCircleCache.updateLastItemUpdate(finalValue.circle!.id,
            finalValue.creator!.id, finalValue.lastUpdate);

        _globalEventBloc.broadcastProgressIndicator(finalValue);

        return finalValue;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);

        return circleObject;
      } else {
        debugPrint(
            'CircleAlbumService.putCircleAlbum failed: ${response.statusCode}');
        debugPrint(response.body);

        throw ('CircleAlbumService.putCircleAlbum failed: ${response.statusCode}');
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

        debugPrint("CircleAlbumService.putCircleAlbum: $e");
      }
      rethrow;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumService.putCircleAlbum: $error");
      rethrow;
    }
  }

  Future<bool> getImage(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      Function failedThumbCallback,
      Function failedFullCallback) async {
    try {
      BlobUrl? urls;

      if (item.image!.location == BlobLocation.S3 ||
          item.image!.location == BlobLocation.PRIVATE_S3 ||
          item.image!.location == BlobLocation.PRIVATE_WASABI) {
        urls = await _blobUrlsService.getDownloadUrls(
          userFurnace,
          BlobType.IMAGE,
          circleObject.id!,
          item.image!.fullImage!,
          item.image!.thumbnail!,
        );
      }

      bool thumbDone = false;
      bool fullDone = false;

      thumbDone = await getThumbnail(
          userFurnace, userCircleCache, circleObject, item, failedThumbCallback,
          url: urls);
      fullDone = await getFull(
          userFurnace, userCircleCache, circleObject, item, failedFullCallback,
          url: urls);

      return (thumbDone && fullDone);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumService.get: $error');
      failedThumbCallback(userFurnace, userCircleCache, circleObject, item);
      failedFullCallback(userFurnace, userCircleCache, circleObject, item);
    }
    return false;
  }

  Future<void> get(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      Function failedThumbCallback,
      Function failedFullCallback) async {
    try {
      if (circleObject.draft) return;

      BlobUrl? urls;

      if (item.image!.location == BlobLocation.S3 ||
          item.image!.location == BlobLocation.PRIVATE_S3 ||
          item.image!.location == BlobLocation.PRIVATE_WASABI) {
        urls = await _blobUrlsService.getDownloadUrls(
          userFurnace,
          BlobType.IMAGE,
          circleObject.id!,
          item.image!.fullImage!,
          item.image!.thumbnail!,
        );
      }

      getThumbnail(
          userFurnace, userCircleCache, circleObject, item, failedThumbCallback,
          url: urls);
      getFull(
          userFurnace, userCircleCache, circleObject, item, failedFullCallback,
          url: urls);

      return;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumService.get: $error');
      failedThumbCallback(userFurnace, userCircleCache, circleObject, item);
      failedFullCallback(userFurnace, userCircleCache, circleObject, item);
    }
  }

  Future<bool> getThumbnail(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      Function failedCallback,
      {BlobUrl? url}) async {
    try {
      bool complete = false;

      if (circleObject.draft) return complete;

      String thumbPath = ImageCacheService.returnExistingAlbumImagePath(
          userCircleCache.circlePath!, circleObject, item.image!.thumbnail!);

      if (item.image!.location == BlobLocation.S3 ||
          item.image!.location == BlobLocation.PRIVATE_S3 ||
          item.image!.location == BlobLocation.PRIVATE_WASABI) {
        late BlobUrl urls;

        if (url != null) {
          urls = url;
        } else {
          urls = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.IMAGE,
            circleObject.id!,
            item.image!.fullImage!,
            item.image!.thumbnail!,
          );
        }
        complete = await _blobService.getItem(
            item,
            userFurnace,
            item.image!.location!,
            urls.thumbnailUrl,
            thumbPath,
            circleObject.id!,
            progressCallback: _progressThumbnailDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      } else {
        complete = await _blobService.getItem(
            item,
            userFurnace,
            item.image!.location!,
            //urls.thumbnailUrl,
            userFurnace.url! +
                Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_THUMBNAIL +
                item.image!.thumbnail!,
            thumbPath,
            circleObject.id!,
            progressCallback: _progressThumbnailDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      }

      return complete;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumService.getThumbnail: $error');
      failedCallback(userFurnace, userCircleCache, circleObject);

      ///FIX
    }
    return false;
  }

  Future<bool> getFull(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, AlbumItem item, Function failedCallback,
      {BlobUrl? url}) async {
    bool complete = false;
    try {
      String fullPath = ImageCacheService.returnExistingAlbumImagePath(
          userCircleCache.circlePath!, circleObject, item.image!.fullImage!);

      if (item.image!.location == BlobLocation.S3 ||
          item.image!.location == BlobLocation.PRIVATE_S3 ||
          item.image!.location == BlobLocation.PRIVATE_WASABI) {
        late BlobUrl urls;

        if (url != null)
          urls = url;
        else
          urls = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.IMAGE,
            circleObject.id!,
            item.image!.fullImage!,
            item.image!.thumbnail!,
          );
        complete = await _blobService.getItem(item, userFurnace,
            item.image!.location!, urls.fileNameUrl, fullPath, circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      } else {
        complete = await _blobService.getItem(
            item,
            userFurnace,
            item.image!.location!,
            //urls.fileNameUrl,
            userFurnace.url! +
                Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
                item.image!.fullImage!,
            fullPath,
            circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      }

      return complete;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumService.get: $error");
      failedCallback(userFurnace, userCircleCache, circleObject, item);
    }
    return false;
  }

  progressDownloadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      AlbumItem item,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    try {
      if (progress == -1) {
        _globalEventBloc.removeItemFullOnError(item);
        failedCallback(userFurnace, userCircleCache, circleObject);

        ///FIX
        return;
      }

      if (progress == 100) {
        String path = ImageCacheService.returnExistingAlbumImagePath(
            userCircleCache.circlePath!, circleObject, item.image!.fullImage!);

        File encrypted = File('${path}enc');

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          File existing = File(path);

          if (existing.existsSync()) {
            //Should only happen if someone edited the image
            await existing.delete();
            imageCache.clear();
          }

          bool success = await EncryptBlob.decryptBlob(DecryptArguments(
              encrypted: encrypted,
              nonce: item.image!.fullCrank!,
              mac: item.image!.fullSignature!,
              key: circleObject.secretKey));

          if (!success) {
            ///TODO need to handle this better, the user can see the thumbnail, even full screen
            debugPrint("progress download callback -- not success");
            return;
          }
        } else {
          if (await encrypted.exists()) {
            try {
              await encrypted.rename(path);
            } catch (error, trace) {
              LogBloc.insertError(error, trace);
              debugPrint('$error');
            }
          }
        }

        item.fullTransferState = BlobState.READY;
        // circleObject.transferPercent = progress;
        // circleObject.nonUIRetries = 0;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleAlbumService.progressCallback: $error');
      BlobService.safeCancel(cancelToken);

      DownloadFailedReason? reason;

      if (error.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      _globalEventBloc.removeItemThumbOnError(item);
      failedCallback(userFurnace, userCircleCache, circleObject, item,
          reason: reason);
    }
  }

  _progressThumbnailDownloadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      AlbumItem item,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    try {
      if (progress == -1) {
        debugPrint("thumb error");
        _globalEventBloc.removeItemThumbOnError(item);
        failedCallback(userFurnace, userCircleCache, circleObject);

        ///FIX
      }

      if (progress == 100) {
        debugPrint("progress 100");
        String path = ImageCacheService.returnExistingAlbumImagePath(
            userCircleCache.circlePath!, circleObject, item.image!.thumbnail!);

        File encrypted = File('${path}enc');

        if (circleObject.ratchetIndexes.isNotEmpty) {
          item.thumbnailTransferState = BlobState.DECRYPTING;

          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          File existing = File(path);

          if (existing.existsSync()) {
            //Should only happen if someone edited the image
            await existing.delete();
            //imageCache!.clear();
            PaintingBinding.instance.imageCache.clear();
          }

          bool success = await EncryptBlob.decryptBlob(DecryptArguments(
              encrypted: encrypted,
              nonce: item.image!.thumbCrank!,
              mac: item.image!.thumbSignature!,
              key: circleObject.secretKey));

          if (!success) {
            item.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
            throw ('unable to decrypt image');
          }
        } else {
          if (await encrypted.exists()) {
            try {
              await encrypted.rename(path);
            } catch (error, trace) {
              LogBloc.insertError(error, trace);
              debugPrint('$error');
            }
          }
        }

        item.image!.thumbnailFile = File(path);
        item.thumbnailTransferState = BlobState.READY;
        _globalEventBloc.broadcastProgressThumbnailIndicator(circleObject);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace,
          source: 'CircleAlbumService._progressThumbnailDownloadCallback');

      DownloadFailedReason? reason;

      if (error.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      BlobService.safeCancel(cancelToken);
      failedCallback(userFurnace, userCircleCache, circleObject, item,
          reason: reason);
    }
  }

  postThumbnail(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject encryptedCopy,
      String fileName,
      BlobUrl urls,
      String extension,
      Function progressCallback) async {
    try {
      String thumbnailUrl;

      File encryptedThumb = File(
          ("${ImageCacheService.returnAlbumImagePath(userCircleCache.circlePath!, encryptedCopy, true, fileName!, extension)}enc"));

      if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_WASABI) {
        thumbnailUrl = urls.thumbnailUrl;

        await _blobService.putWithRetry(
            userFurnace, thumbnailUrl, encryptedThumb,
            userCircleCache: userCircleCache,
            circleObject: encryptedCopy,
            progressCallback: progressCallback,
            broadcastQuarterOnly: true,
            loggingTag: "postThumbnail");
      } else {
        File encryptedFull = File(
            ("${ImageCacheService.returnAlbumImagePath(userCircleCache.circlePath!, encryptedCopy, false, fileName!, extension)}enc"));

        String fileUrl = userFurnace.url! + Urls.GRIDFS_UPLOAD_DUAL;
        //thumbnailUrl = userFurnace.url! + Urls.CIRCLEIMAGETHUMBNAIL;

        _blobService.putGridFSDual(
            userFurnace,
            fileUrl,
            userCircleCache.circle!,
            encryptedFull,
            encryptedThumb,
            encryptedCopy,
            userCircleCache,
            doNothing,
            doNothing);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleAlbumService.postThumbnail: $err");
      rethrow;
    }
  }

  postFull(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject encryptedCopy,
      String? fileName,
      String extension,
      BlobUrl? urls,
      Function progressCallback,
      {maxRetries = RETRIES.MAX_IMAGE_UPLOAD_RETRIES}) async {
    try {
      String fileUrl;

      File encryptedFull = File(
          ("${ImageCacheService.returnAlbumImagePath(userCircleCache.circlePath!, encryptedCopy, false, fileName!, extension)}enc"));

      if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
          encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_WASABI) {
        fileUrl = urls!.fileNameUrl;

        await _blobService.putWithRetry(userFurnace, fileUrl, encryptedFull,
            userCircleCache: userCircleCache,
            circleObject: encryptedCopy,
            progressCallback: progressCallback,
            broadcastProgress: 25,
            maxRetries: maxRetries,
            loggingTag: "postFull");
      } else {
        File encryptedThumb = File(
            ("${ImageCacheService.returnAlbumImagePath(userCircleCache.circlePath!, encryptedCopy, true, fileName!, extension)}enc"));

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
            doNothing,
            doNothing);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleAlbumService.postFull: $err");
      rethrow;
    }
  }

  doNothing(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int broadcastProgress) {
    ///change to progress upload callback
  }

  updateAlbumOrder(
    UserFurnace userFurnace,
    CircleObject circleObject,
  ) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEALBUM_SORT + 'undefined';

      debugPrint(url);

      var encoded = json.encode(circleObject.toJson()).toString();
      CircleObject revertTo = CircleObject.fromJson(json.decode(encoded));

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      List<AlbumItem> sendList = [];

      for (AlbumItem item in circleObject.album!.media) {
        sendList.add(AlbumItem(
          id: item.id,
          index: item.index,
          type: item.type,
        ));
      }

      Device device = await globalState.getDevice();

      Map map = {
        'circleid': circleObject.circle!.id,
        'userid': userFurnace.userid,
        'pushtoken': device.pushToken,
        'apikey': userFurnace.apikey,
        'creator': circleObject.creator!.id,
        'items': sendList,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'body': encryptedCopy.body,
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'circleObjectID': circleObject.id!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));
      //.timeout(const Duration(seconds: RETRIES.TIMEOUT_API_IMAGE));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        CircleObject retValue =
            CircleObject.fromJson(jsonResponse["circleObject"]);
        retValue.revertEncryptedFields(revertTo);

        retValue.circle = circleObject.circle;
        retValue.editing = false;
        retValue.body = circleObject.body;
        retValue.album = circleObject.album;

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
            "CircleAlbumService.updateAlbumOrder failed: ${response.statusCode}");
        debugPrint(response.body);
        throw ('CircleAlbumService.updateAlbumOrder failed: ${response.statusCode}');
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumService.updateAlbumOrder: $error");
      rethrow;
    }
  }

  Future<CircleObject> revertEncryptedAlbumFields(
    CircleObject circleObject,
    CircleObject original,
  ) async {
    try {
      for (int i = 0; i < original.album!.media.length; i++) {
        AlbumItem originalItem = original.album!.media[i];
        circleObject.album!.media[i].image = originalItem.image;
        circleObject.album!.media[i].video = originalItem.video;
        circleObject.album!.media[i].gif = originalItem.gif;
        circleObject.album!.media[i].retries = originalItem.retries;
        circleObject.album!.media[i].thumbnailTransferState =
            originalItem.thumbnailTransferState;
        circleObject.album!.media[i].fullTransferState =
            originalItem.fullTransferState;
      }

      return circleObject;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleAlbumService.revertEncryptedAlbumFields: $error");
      rethrow;
    }
  }
}
