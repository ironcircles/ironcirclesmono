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
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class CircleRecipeService {
  final BlobUrlsService _blobUrlsService = BlobUrlsService();
  final BlobService _blobService = BlobService();

  late GlobalEventBloc _globalEventBloc;

  CircleRecipeService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  Future<void> getImage(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      Function failedCallback) async {
    try {
      String thumbPath = ImageCacheService.returnThumbnailPath(
          userCircleCache.circlePath!, circleObject);

      imageCache.clear();

      if (circleObject.recipe!.image!.location == BlobLocation.S3 ||
          circleObject.recipe!.image!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.recipe!.image!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl urls = await _blobUrlsService.getDownloadUrl(
          userFurnace,
          BlobType.IMAGE,
          circleObject.id!,
          circleObject.recipe!.image!.thumbnail!,
        );

        _blobService.get(userFurnace, circleObject.recipe!.image!.location!,
            urls.fileNameUrl, thumbPath, circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      } else {
        _blobService.get(
            userFurnace,
            circleObject.recipe!.image!.location!,
            userFurnace.url! +
                Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
                circleObject.recipe!.image!.thumbnail!,
            thumbPath,
            circleObject.id!,
            progressCallback: progressDownloadCallback,
            circleObject: circleObject,
            userCircleCache: userCircleCache,
            failedCallback: failedCallback);
      }

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      _globalEventBloc.removeOnError(circleObject);
      debugPrint('CircleRecipeService.getImage: $err');
      rethrow;
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
      if (progress == -1) {
        _globalEventBloc.removeOnError(circleObject);

        return;
      }

      CircleObject retValue = circleObject;

      if (progress == 100) {
        String path = ImageCacheService.returnThumbnailPath(
            userCircleCache.circlePath!, circleObject);

        File encrypted = File('${path}enc');

        retValue.thumbnailTransferState = BlobState.DECRYPTING;

        retValue.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

        if (retValue.secretKey!.isEmpty) throw ('could not find key');

        await EncryptBlob.decryptBlob(DecryptArguments(
            encrypted: encrypted,
            nonce: retValue.recipe!.image!.thumbCrank!,
            mac: retValue.recipe!.image!.thumbSignature!,
            key: retValue.secretKey));

        if (await encrypted.exists()) {
          encrypted.delete();
        }

        //circleObject.image!.thumbnail = path;
        retValue.recipe!.image!.thumbnailFile = File(path);
        retValue.thumbnailTransferState = BlobState.READY;
      }

      retValue.transferPercent = progress;
      //retValue.thumbnailTransferState = BlobState.READY;
      _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeService.progressDownloadCallback: $err');
      _globalEventBloc.removeOnError(circleObject);
    }
  }

  progressUploadCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress,
      Function postFailed,
      CircleObjectBloc callbackBloc) async {
    try {
      if (progress == -1) {
        _globalEventBloc.removeOnError(circleObject);

        return;
      }

      CircleObject retValue = circleObject;

      if (progress == 100) {
        retValue = await _create(userCircleCache, circleObject, userFurnace);

        if (circleObject.recipe!.image != null) {
          String path = ImageCacheService.returnThumbnailPath(
              userCircleCache.circlePath!, circleObject);

          circleObject.recipe!.image!.thumbnailFile = File(path);

          File enc = File(
              ("${ImageCacheService.returnThumbnailPath(userCircleCache.circlePath!, circleObject)}enc"));

          FileSystemService.safeDelete(enc);
        }

        retValue.transferPercent = progress;
        _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
      }

      retValue.transferPercent = progress;
      _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeService.progressUploadCallback: $err');
      _globalEventBloc.removeOnError(circleObject);
    }
  }

  updateImageCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress,
      Function postFailed,
      CircleObjectBloc callbackBloc) async {
    try {
      if (progress == -1) {
        _globalEventBloc.removeOnError(circleObject);

        return;
      }

      CircleObject retValue = circleObject;

      if (progress == 100) {
        retValue = await _update(userCircleCache, circleObject, userFurnace);

        if (circleObject.recipe!.image != null) {
          String path = ImageCacheService.returnThumbnailPath(
              userCircleCache.circlePath!, circleObject);

          circleObject.recipe!.image!.thumbnailFile = File(path);

          File enc = File(
              ("${ImageCacheService.returnThumbnailPath(userCircleCache.circlePath!, circleObject)}enc"));

          if (await enc.exists()) {
            enc.delete();
          }
        }

        imageCache.clear();

        retValue.transferPercent = progress;
        _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
        _globalEventBloc.broadcastRecipeUpdated(retValue);
      }

      retValue.transferPercent = progress;
      _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeService.progressCallback: $err');
      _globalEventBloc.removeOnError(circleObject);
    }
  }

  Future<CircleObject> create(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      UserFurnace userFurnace,
      Function processFailed,
      CircleObjectBloc callbackBloc) async {
    try {
      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      //revert before displaying on screen, not sent to server
      encryptedCopy.encryptedBody = encryptedCopy.body;
      encryptedCopy.body = circleObject.body;
      encryptedCopy.original = circleObject;

      if (circleObject.recipe!.image != null) {
        File thumbnail = circleObject.recipe!.image!.thumbnailFile!;

        //get the location to save this
        BlobUrl urls = await _blobUrlsService.getUploadUrl(userFurnace,
            BlobType.IMAGE, userCircleCache.circle!, thumbnail.path);

        encryptedCopy.recipe!.image = CircleImage(
            thumbnail: urls.fileName,
            thumbnailSize: thumbnail.lengthSync(),
            location: urls.location);

        DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(
            ImageCacheService.returnThumbnailPath(
                userCircleCache.circlePath!, circleObject),
            secretKey: encryptedCopy.secretKey!);

        //Set the stuff
        encryptedCopy.recipe!.image!.thumbSignature = thumbArgs.mac;
        encryptedCopy.recipe!.image!.thumbCrank = thumbArgs.nonce;

        encryptedCopy.thumbnailTransferState = BlobState.UPLOADING;

        if (urls.location == BlobLocation.S3 ||
            urls.location == BlobLocation.PRIVATE_S3 ||
            urls.location == BlobLocation.PRIVATE_WASABI) {
          //save the blob
          _blobService.put(userFurnace, urls.fileNameUrl, thumbArgs.encrypted,
              circleObject: encryptedCopy,
              userCircleCache: userCircleCache,
              progressCallback: progressUploadCallback,
              postFailed: processFailed,
              callbackBloc: callbackBloc);
        } else {
          String url = userFurnace.url! + Urls.GRIDFS_POST;
          //thumbnailUrl = userFurnace.url! + Urls.CIRCLEIMAGETHUMBNAIL;

          _blobService.putGridFS(
            userFurnace,
            url,
            userCircleCache.circle!,
            thumbArgs.encrypted,
            encryptedCopy,
            userCircleCache,
            progressUploadCallback,
          );
        }
      } else {
        CircleObject retValue =
            await _create(userCircleCache, encryptedCopy, userFurnace);

        retValue.transferPercent = 100;
        _globalEventBloc.broadcastProgressThumbnailIndicator(retValue);
        return retValue;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeService.create: $err');

      rethrow;
    }
    return circleObject;
  }

  Future<CircleObject> _create(
    UserCircleCache userCircleCache,
    CircleObject encryptedCopy,
    UserFurnace userFurnace,
  ) async {
    String url = userFurnace.url! + Urls.CIRCLERECIPE;

    UserTemplateRatchet userTemplateRatchet =
        await ForwardSecrecyUser.encryptRecipeTemplate(
            userFurnace.userid!, encryptedCopy.recipe!);

    Device device = await globalState.getDevice();

    Map map = {
      'circleid': userCircleCache.circle,
      'circle': encryptedCopy.circle!.id,
      'creator': encryptedCopy.creator!.id,
      'owner': encryptedCopy.creator!.id,
      'type': encryptedCopy.type,
      'seed': encryptedCopy.seed,
      'body': encryptedCopy.encryptedBody,
      'device': device.uuid,
      'template': encryptedCopy.recipe!.template,
      'pushtoken': device.pushToken,
      'saveTemplate': encryptedCopy.recipe!.saveTemplate,
      'instructions': encryptedCopy.recipe!.instructions,
      'ingredients': encryptedCopy.recipe!.ingredients,
      'crank': encryptedCopy.crank,
      'signature': encryptedCopy.signature,
      'verification': encryptedCopy.verification,
      'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
      'ratchetIndexes': encryptedCopy.ratchetIndexes,
      'userTemplateRatchet': userTemplateRatchet,
    };

    if (encryptedCopy.recipe!.image != null) {
      map["recipeimage"] = encryptedCopy.recipe!.image;
    }

    if (encryptedCopy.timer != null) {
      map["timer"] = encryptedCopy.timer;
    }
    if (encryptedCopy.scheduledFor != null) {
      String scheduled = encryptedCopy.scheduledFor.toString().substring(0, 17);
      String time = encryptedCopy.original!.dateIncrement.toString();
      String scheduledTime = scheduled + time;
      map["scheduledFor"] = scheduledTime;
    }

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      CircleObject retValue =
          CircleObject.fromJson(jsonResponse["circleobject"]);

      retValue.circle ??= encryptedCopy.circle;

      retValue.revertEncryptedFields(encryptedCopy.original!);

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, retValue);

      TableUserCircleCache.updateLastItemUpdate(
          retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

      if (jsonResponse["template"] != null) {
        CircleRecipeTemplate template =
            CircleRecipeTemplate.fromJson(jsonResponse["template"]);

        template.revertEncryptedFields(encryptedCopy.original!.recipe!);

        //CircleRecipeTemplate.put(userFurnace.userid!, template);
      }

      return retValue;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }

    return encryptedCopy;
  }

  Future<void> update(
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      UserFurnace userFurnace,
      Function processFailed,
      CircleObjectBloc callbackBloc) async {
    try {
      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      //revert before displaying on screen, not sent to server
      encryptedCopy.encryptedBody = encryptedCopy.body;
      encryptedCopy.body = circleObject.body;
      encryptedCopy.original = circleObject;

      if (circleObject.recipe!.image != null &&
          circleObject.recipe!.image!.thumbnailFile != null) {
        File thumbnail = circleObject.recipe!.image!.thumbnailFile!;

        //get the location to save this
        BlobUrl urls = await _blobUrlsService.getUploadUrl(userFurnace,
            BlobType.IMAGE, userCircleCache.circle!, thumbnail.path);

        encryptedCopy.recipe!.image = CircleImage(
            thumbnail: urls.fileName,
            thumbnailSize: thumbnail.lengthSync(),
            location: urls.location);

        DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(
            ImageCacheService.returnThumbnailPath(
                userCircleCache.circlePath!, circleObject),
            secretKey: encryptedCopy.secretKey!);

        //Set the stuff
        encryptedCopy.recipe!.image!.thumbSignature = thumbArgs.mac;
        encryptedCopy.recipe!.image!.thumbCrank = thumbArgs.nonce;

        encryptedCopy.thumbnailTransferState = BlobState.UPLOADING;

        if (urls.location == BlobLocation.S3 ||
            urls.location == BlobLocation.PRIVATE_S3 ||
            urls.location == BlobLocation.PRIVATE_WASABI) {
          //save the blob
          _blobService.put(userFurnace, urls.fileNameUrl, thumbArgs.encrypted,
              circleObject: encryptedCopy,
              userCircleCache: userCircleCache,
              progressCallback: updateImageCallback,
              postFailed: processFailed,
              callbackBloc: callbackBloc);
        } else {
          String url = userFurnace.url! + Urls.GRIDFS_POST;
          //thumbnailUrl = userFurnace.url! + Urls.CIRCLEIMAGETHUMBNAIL;

          _blobService.putGridFS(
            userFurnace,
            url,
            userCircleCache.circle!,
            thumbArgs.encrypted,
            encryptedCopy,
            userCircleCache,
            updateImageCallback,
          );
        }
      } else {
        CircleObject retValue =
            await _update(userCircleCache, encryptedCopy, userFurnace);

        //retValue.transferPercent = 100;
        _globalEventBloc.broadcastRecipeUpdated(retValue);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleRecipeService.update: $err');

      rethrow;
    }
  }

  Future<CircleObject> _update(UserCircleCache userCircleCache,
      CircleObject encryptedCopy, UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.CIRCLERECIPE + 'undefined';

    Device device = await globalState.getDevice();

    Map map = {
      'circleid': userCircleCache.circle,
      'circle': encryptedCopy.circle!.id,
      'seed': encryptedCopy.seed,
      'body': encryptedCopy.encryptedBody,
      'crank': encryptedCopy.crank,
      'signature': encryptedCopy.signature,
      'verification': encryptedCopy.verification,
      'pushtoken': device.pushToken,
      'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
      'ratchetIndexes': encryptedCopy.ratchetIndexes,
      'instructions': encryptedCopy.recipe!.instructions,
      'ingredients': encryptedCopy.recipe!.ingredients,
      'circleObjectID': encryptedCopy.id!,
    };

    if (encryptedCopy.recipe!.image != null) {
      map["recipeimage"] = encryptedCopy.recipe!.image;
    }

    debugPrint(url);

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.put(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      CircleObject retValue =
          CircleObject.fromJson(jsonResponse["circleobject"]);

      retValue.revertEncryptedFields(encryptedCopy.original!);

      //flip the dates to move to bottom of sort list
      retValue.created = retValue.lastUpdate;

      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, retValue);

      TableUserCircleCache.updateLastItemUpdate(
          retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

      return retValue;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);

      return encryptedCopy;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
