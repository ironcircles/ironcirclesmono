import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/table_circleobject.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

import '../models/album_item.dart';

class CallbackType {
  static const int FULLIMAGE = 0;
  static const int THUMBNAIL = 1;
}

class CircleVideoService {
  late GlobalEventBloc _globalEventBloc;
  final BlobUrlsService _blobUrlsService = BlobUrlsService();
  final BlobService _blobService = BlobService();

  CircleVideoService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  Future<String> getAlbumStreamingUrl(UserFurnace userFurnace,
      CircleObject circleObject, AlbumItem item) async {
    try {
      BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
          userFurnace,
          BlobType.VIDEO,
          circleObject.id!,
          item.video!.video!,
          item.video!.preview!);

      return blobUrl.fileNameUrl;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleVideoService._getAlbumStreamingUrl: $error');
      rethrow;
    }
  }

  Future<String> getStreamingUrl(
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
          userFurnace,
          BlobType.VIDEO,
          circleObject.id!,
          circleObject.video!.video!,
          circleObject.video!.preview!);

      return blobUrl.fileNameUrl;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoService._getStreamingUrl: $err');
      rethrow;
    }
  }

  Future<BlobUrl?> getUploadUrls(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      CircleObject circleObject,
      File file,
      File thumbnail,
      CircleObjectBloc callbackBloc) async {
    try {
      ///if this uses unique local storage, use the seed instead of the file name
      String filePath = VideoCacheService.getFilenameForAPI(
          circleObject, file.path, userCircleCache.circlePath!);
      String thumbPath = VideoCacheService.getFilenameForAPI(
          circleObject, thumbnail.path, userCircleCache.circlePath!);
      thumbnail.path;

      //get the location to save this
      BlobUrl urls = await _blobUrlsService.getUploadUrls(userFurnace,
          BlobType.VIDEO, userCircleCache.circle!, filePath, thumbPath);

      return urls;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoService.getUploadUrls: $err");

      rethrow;
    }
  }

  Future<CircleObject> encryptFiles(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      File video,
      File thumbnail,
      BlobUrl blobUrl) async {
    try {
      CircleObject encryptedCopy = circleObject;

      encryptedCopy.secretKey = await ForwardSecrecy.genSecretKey();

      encryptedCopy.transferPercent = 1;

      if (encryptedCopy.video == null) {
        debugPrint('break');
      }
      encryptedCopy.video ??= CircleVideo();

      encryptedCopy.video!.videoState = VideoStateIC.UPLOADING_VIDEO;
      encryptedCopy.video!.streamable = circleObject.video!.streamable;
      encryptedCopy.video!.sourceVideo = video.path;
      encryptedCopy.video!.preview = blobUrl.thumbnail;
      encryptedCopy.video!.extension = circleObject.video!.extension!;
      //FileSystemService.getExtension(video.path);
      encryptedCopy.video!.video = blobUrl.fileName;
      encryptedCopy.video!.previewSize = thumbnail.lengthSync();
      encryptedCopy.video!.videoSize = video.lengthSync();
      encryptedCopy.video!.height = circleObject.video!.height;
      encryptedCopy.video!.width = circleObject.video!.width;
      encryptedCopy.video!.location = blobUrl.location;

      // encryptedCopy.video = CircleVideo(
      //     videoState: VideoStateIC.UPLOADING_VIDEO,
      //     streamable: circleObject.video!.streamable,
      //     sourceVideo: video.path,
      //     preview: blobUrl.thumbnail,
      //     extension: FileSystemService.getExtension(video.path),
      //     video: blobUrl.fileName,
      //     previewSize: thumbnail.lengthSync(),
      //     videoSize: video.lengthSync(),
      //     height: circleObject.video!.height,
      //     width: circleObject.video!.width,
      //     location: blobUrl.location);

      ///don't encrypt video if it's streamable
      if (!circleObject.video!.streamable!) {
        DecryptArguments fullArgs = await EncryptBlob.encryptBlob(video.path,
            secretKey: encryptedCopy.secretKey!);
        encryptedCopy.video!.fullSignature = fullArgs.mac;
        encryptedCopy.video!.fullCrank = fullArgs.nonce;
      }

      ///encrypt the thumbnail regardless
      DecryptArguments thumbArgs = await EncryptBlob.encryptBlob(thumbnail.path,
          secretKey: encryptedCopy.secretKey!);
      encryptedCopy.video!.thumbSignature = thumbArgs.mac;
      encryptedCopy.video!.thumbCrank = thumbArgs.nonce;

      ///revert before displaying on screen, not sent to server
      encryptedCopy.encryptedBody = encryptedCopy.body;
      encryptedCopy.body = circleObject.body;

      ///set encrypted
      encryptedCopy.thumbnailTransferState = BlobState.ENCRYPTED;
      encryptedCopy.fullTransferState = BlobState.ENCRYPTED;
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

  progressUploadThumbnailCallback(
      UserFurnace userFurnace,
      CircleObject circleObject,
      UserCircleCache userCircleCache,
      int progress) async {}

  progressUploadCallback(UserFurnace userFurnace, CircleObject circleObject,
      UserCircleCache userCircleCache, int progress) async {
    try {
      if (circleObject.type != CircleObjectType.CIRCLEALBUM) {
        circleObject.transferPercent = progress;
        _globalEventBloc.broadcastProgressIndicator(circleObject);
      }
    } catch (err) {
      //ogBloc.insertError(err, trace);
      debugPrint('CircleVideoService.progressCallback: $err');
    }
  }

  postThumbnail(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy,
      [String? fileName,
      bool? streamable,
      BlobUrl? urls,
      Function? customProgressCallback]) async {
    try {
      //String fileUrl;
      String thumbnailUrl;

      late File encryptedThumb;

      if (encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
        if (streamable == true) {
          encryptedThumb = File((VideoCacheService.returnAlbumVideoPath(
              userCircleCache.circlePath!,
              encryptedCopy,
              fileName!,
              true,
              '')));
        } else {
          encryptedThumb = File(
              "${(VideoCacheService.returnAlbumVideoPath(userCircleCache.circlePath!, encryptedCopy, fileName!, true, ''))}enc");
        }
      } else {
        if (encryptedCopy.video!.streamable!) {
          encryptedThumb = File((VideoCacheService.returnPreviewPath(
              encryptedCopy, userCircleCache.circlePath!)));
        } else {
          encryptedThumb = File(
              ("${VideoCacheService.returnPreviewPath(encryptedCopy, userCircleCache.circlePath!)}enc"));
        }
      }

      if (encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
        if (urls!.location == BlobLocation.S3 ||
            urls.location == BlobLocation.PRIVATE_S3 ||
            urls.location == BlobLocation.PRIVATE_WASABI) {
          thumbnailUrl = urls.thumbnailUrl;

          ///fire off the thumbnail
          await _blobService.putWithRetry(
              userFurnace, thumbnailUrl, encryptedThumb,
              userCircleCache: userCircleCache,
              circleObject: encryptedCopy,
              progressCallback:
                  customProgressCallback ?? progressUploadThumbnailCallback,
              broadcastQuarterOnly: true);
        } else {
          ///TODO Gridfs
        }
      } else {
        if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
            encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
            encryptedCopy.transferUrls!.location ==
                BlobLocation.PRIVATE_WASABI) {
          thumbnailUrl = encryptedCopy.transferUrls!.thumbnailUrl;

          ///fire off the thumbnail
          await _blobService.putWithRetry(
              userFurnace, thumbnailUrl, encryptedThumb,
              userCircleCache: userCircleCache,
              circleObject: encryptedCopy,
              progressCallback:
                  customProgressCallback ?? progressUploadThumbnailCallback,
              broadcastQuarterOnly: true);
        } else {
          ///TODO Gridfs
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoService.postThumbnail: $err");
      rethrow;
    }
  }

  postFull(UserCircleCache userCircleCache, UserFurnace userFurnace,
      CircleObject encryptedCopy, File encryptedFull, maxRetries,
      [BlobUrl? urls, Function? customProgressCallback]) async {
    try {
      if (encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
        if (urls!.location == BlobLocation.S3 ||
            urls.location == BlobLocation.PRIVATE_S3 ||
            urls.location == BlobLocation.PRIVATE_WASABI) {
          await _blobService.putWithRetry(
              userFurnace, urls.fileNameUrl, encryptedFull,
              userCircleCache: userCircleCache,
              circleObject: encryptedCopy,
              progressCallback:
                  customProgressCallback ?? progressUploadCallback,
              //broadcastProgress: 25,
              maxRetries: maxRetries);
        } else {
          ///TODO Gridfs
        }
      } else {
        ///not an album
        if (encryptedCopy.transferUrls!.location == BlobLocation.S3 ||
            encryptedCopy.transferUrls!.location == BlobLocation.PRIVATE_S3 ||
            encryptedCopy.transferUrls!.location ==
                BlobLocation.PRIVATE_WASABI) {
          await _blobService.putWithRetry(userFurnace,
              encryptedCopy.transferUrls!.fileNameUrl, encryptedFull,
              userCircleCache: userCircleCache,
              circleObject: encryptedCopy,
              progressCallback:
                  customProgressCallback ?? progressUploadCallback,
              //broadcastProgress: 25,
              maxRetries: maxRetries);
        } else {
          ///TODO Gridfs
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoService.postFull: $err");
      rethrow;
    }
  }

  Future<CircleObject> postCircleVideo(UserFurnace userFurnace,
      UserCircleCache userCircleCache, CircleObject circleObject) async {
    late CircleObject revertTo;

    try {
      //Dio dio = Dio();

      String url = userFurnace.url! + Urls.CIRCLEVIDEO_S3;

      debugPrint(url);

      if (_globalEventBloc.deletedSeeds.contains(circleObject.seed))
        throw ("tried to send a deleted video");

      if (circleObject.secretKey == null)
        throw ("error occurred. delete video and try again");

      var encoded = json.encode(circleObject.toJson()).toString();
      revertTo = CircleObject.fromJson(json.decode(encoded));

      circleObject.video!.previewFile = null;
      circleObject.video!.videoFile = null;

      CircleObject encryptedCopy =
          await ForwardSecrecy.encryptCircleObject(userFurnace, circleObject);

      encryptedCopy.video!.blankEncryptionFields();
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
        'crank': encryptedCopy.crank,
        'signature': encryptedCopy.signature,
        'verification': encryptedCopy.verification,
        'senderRatchetPublic': encryptedCopy.senderRatchetPublic,
        'ratchetIndexes': encryptedCopy.ratchetIndexes,
        'video': encryptedCopy.video,
        'taggedUsers': encryptedCopy.taggedUsers,
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
        debugPrint(
            'CircleVideoService._postCircleVideo failed: ${response.statusCode}');
        debugPrint(response.body);

        throw ('CircleVideoService._postCircleVideo failed: ${response.statusCode}');
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
      globalState.forcedOrder
          .removeWhere((element) => element.seed == circleObject.seed);
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService2._postCircleImage: $err");

      circleObject.revertEncryptedFields(revertTo);
      rethrow;
    }

    //return null;
  }

  deleteItemCache(String userID, String circlePath, CircleObject circleObject,
      AlbumItem item) async {
    await VideoCacheService.deleteItemCache(circlePath, circleObject, item);

    int index = circleObject.album!.media.indexOf(item);
    circleObject.album!.media[index].video!.videoState =
        VideoStateIC.PREVIEW_DOWNLOADED;
    circleObject.album!.media[index].fullTransferState = BlobState.UNKNOWN;
    circleObject.album!.media[index].video!.videoFile = null;
    circleObject.album!.media[index].video!.streamableCached = false;

    await TableCircleObjectCache.updateCacheSingleObject(userID, circleObject);
  }

  deleteCache(
      String userID, String circlePath, CircleObject circleObject) async {
    await VideoCacheService.deleteCache(circlePath, circleObject);

    circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
    circleObject.fullTransferState = BlobState.UNKNOWN;
    circleObject.video!.videoFile = null;
    circleObject.video!.streamableCached = false;
    circleObject.transferPercent = 0;

    await TableCircleObjectCache.updateCacheSingleObject(userID, circleObject);
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

    if (circleObject.created!.difference(retValue.created!) <
        const Duration(minutes: 10)) {
      ///use the local date
      retValue.created = circleObject.created!;
    }

    retValue.fullTransferState = BlobState.READY;
    retValue.transferPercent = 100;
    retValue.circle = circleObject.circle;
    retValue.video!.previewBytes = circleObject.video!.previewBytes;

    if (retValue.video!.streamable!) {
      retValue.video!.streamableCached = true;

      if (globalState.isDesktop()) {
        await deleteCache(
            userCircleCache.user!, userCircleCache.circlePath!, retValue);

        retValue.video!.streamableCached == false;
      }

      ///this became annoying, can't play videos in low latency or airplane mode once shared
      ///also, unique storage identifiers for media will make sure there is only once copy.
      ///also, the user can still decide to remove the cache if they want to.
      /*await deleteCache(
          userCircleCache.user!, userCircleCache.circlePath!, retValue);

      retValue.video!.streamableCached == false;*/
    } else {
      retValue.video!.videoFile = File(VideoCacheService.returnVideoPath(
          retValue, userCircleCache.circlePath!, retValue.video!.extension!));
      retValue.video!.previewFile = File(VideoCacheService.returnPreviewPath(
        retValue,
        userCircleCache.circlePath!,
      ));
    }
    retValue.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
    await TableCircleObjectCache.updateCacheSingleObject(
        userFurnace.userid!, retValue);

    TableUserCircleCache.updateLastItemUpdate(
        retValue.circle!.id, retValue.creator!.id, retValue.lastUpdate);

    if (retValue.timer != null) {
      _globalEventBloc.startTimer(retValue.timer!, retValue);
    }

    //ForwardSecrecy.ratchetReceiverKey(
    //    userFurnace, circleObject.circle!.id!, userCircleCache.usercircle!);

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
      if (progress == -1) {
        circleObject.fullTransferState = BlobState.BLOB_UPLOAD_FAILED;

        return;
      }

      if (progress == 100) {
        circleObject.transferPercent = progress;

        circleObject.video!.streamableCached = true;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        String videoPath = VideoCacheService.returnVideoPath(circleObject,
            userCircleCache.circlePath!, circleObject.video!.extension!);

        //_globalEventBloc.broadcastProgressIndicator(circleObject);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          File encrypted = File('${videoPath}enc');

          if (circleObject.video!.streamable! || globalState.isDesktop()) {
            await encrypted.rename(videoPath);
          } else {
            //decrypt

            bool success = await EncryptBlob.decryptBlob(DecryptArguments(
              encrypted: encrypted,
              nonce: circleObject.video!.fullCrank!,
              mac: circleObject.video!.fullSignature!,
              key: circleObject.secretKey,
            ));

            if (!success) {
              circleObject.video!.videoState = BlobState.BLOB_DOWNLOAD_FAILED;
              circleObject.thumbnailTransferState =
                  BlobState.BLOB_DOWNLOAD_FAILED;
              throw ('unable to decrypt video');
            }
          }

          ///decrypt-error
          File thumbnail = File(VideoCacheService.returnPreviewPath(
            circleObject,
            userCircleCache.circlePath!,
          ));

          debugPrint(
              'thumbnail path ${thumbnail.path} and size ${thumbnail.lengthSync()}');

          File file = File(videoPath);
          if (file.existsSync()) {
            debugPrint('video size: ${file.lengthSync()}');
          } else {
            debugPrint('video not found');
          }

          //_globalEventBloc.broadcastObjectDownloaded(circleObject);
        }

        circleObject.video!.videoState = VideoStateIC.NEEDS_CHEWIE;

        circleObject.thumbnailTransferState = BlobState.READY;
        circleObject.fullTransferState = BlobState.READY;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        _globalEventBloc.broadcastProgressIndicator(circleObject);
      } else {
        if (progress < 1)
          circleObject.transferPercent = 1;
        else {
          circleObject.transferPercent = progress;
          _globalEventBloc.broadcastProgressIndicator(circleObject);

          /*
          ///make sure we aren't refresh the screen if it didn't change a full percent

          int diff = progress - circleObject.transferPercent!;

          debugPrint(diff.toString());
          debugPrint(progress.toString());
          debugPrint(circleObject.transferPercent.toString());

          if (diff >= 1) {
            debugPrint('event broadcasted');
            circleObject.transferPercent = progress;
            _globalEventBloc.broadcastProgressIndicator(circleObject);
          } else {
            debugPrint('NO event broadcasted');
            //circleObject.transferPercent = progress;
          }

           */
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.progressCallbackDownload: $error");

      DownloadFailedReason? reason;

      if (error.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      failedCallback(userFurnace, userCircleCache, circleObject,
          reason: reason);
    }
  }

  progressCallbackItemDownload(
      UserFurnace userFurnace,
      CircleObject circleObject,
      AlbumItem item,
      UserCircleCache userCircleCache,
      int progress,
      Function failedCallback,
      CancelToken cancelToken) async {
    try {
      if (progress == -1) {
        item.fullTransferState = BlobState.BLOB_UPLOAD_FAILED;
        return;
      }

      if (progress == 100) {
        //item.transferPercent = progress;

        item.video!.streamableCached = true;

        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);

        String videoPath = VideoCacheService.returnExistingAlbumVideoPath(
            userCircleCache.circlePath!, circleObject, item.video!.video!);

        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');

          File encrypted = File('${videoPath}enc');

          if (item.video!.streamable!) {
            await encrypted.rename(videoPath);
          } else {
            bool success = await EncryptBlob.decryptBlob(DecryptArguments(
                encrypted: encrypted,
                nonce: item.video!.fullCrank!,
                mac: item.video!.fullSignature!,
                key: circleObject.secretKey));

            if (!success) {
              item.video!.videoState = BlobState.BLOB_DOWNLOAD_FAILED;
              item.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
              throw ('unable to decrypt album video');
            }
          }

          ///decrypt-error
          File thumbnail = File(VideoCacheService.returnExistingAlbumVideoPath(
              userCircleCache.circlePath!, circleObject, item.video!.preview!));

          debugPrint(
              'thumbnail path ${thumbnail.path} and size ${thumbnail.lengthSync()}');

          File file = File(videoPath);
          if (file.existsSync()) {
            debugPrint('video size: ${file.lengthSync()}');
          } else {
            debugPrint('video not found');
          }
        }

        item.video!.videoState = VideoStateIC.NEEDS_CHEWIE;
        item.thumbnailTransferState = BlobState.READY;
        item.fullTransferState = BlobState.READY;
        await TableCircleObjectCache.updateCacheSingleObject(
            userFurnace.userid!, circleObject);
        //_globalEventBloc.broadcastProgressIndicator(circleObject);
        _globalEventBloc.broadcastAlbumItemIndicator(item);
      } else {
        ///reimplement this later
        if (progress < 1) {
          //item.transferPercent = 1;
        } else {
          //item.transferPercent = progress;
          //_globalEventBloc.broadcastProgressIndicator(circleObject);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.progressCallbackItemDownload: $error");

      DownloadFailedReason? reason;

      if (error.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      failedCallback(userFurnace, userCircleCache, circleObject, item,
          reason: reason);
    }
  }

  Future<void> get(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, Function failedCallback) async {
    try {
      String videoPath = VideoCacheService.returnVideoPath(circleObject,
          userCircleCache.circlePath!, circleObject.video!.extension!);

      String url = '';

      if (circleObject.video!.location == BlobLocation.S3 ||
          circleObject.video!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.video!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.VIDEO,
            circleObject.id!,
            circleObject.video!.video!,
            circleObject.video!.preview!);

        url = blobUrl.fileNameUrl;
      } else {
        url = userFurnace.url! +
            Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
            circleObject.video!.video!;
      }

      _blobService.get(
        userFurnace,
        circleObject.video!.location!,
        url,
        videoPath,
        circleObject.id!,
        progressCallback: progressCallbackDownload,
        circleObject: circleObject,
        userCircleCache: userCircleCache,
        failedCallback: failedCallback,
      );

      //throw ('failed');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoService.get: $err');

      failedCallback(userFurnace, userCircleCache, circleObject);
    }
  }

  Future<void> getAlbumVideo(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      AlbumItem item,
      Function failedCallback) async {
    try {
      String videoPath = VideoCacheService.returnExistingAlbumVideoPath(
          userCircleCache.circlePath!, circleObject, item.video!.video!);

      String url = '';

      if (item.video!.location == BlobLocation.S3 ||
          item.video!.location == BlobLocation.PRIVATE_S3 ||
          item.video!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.VIDEO,
            circleObject.id!,
            item.video!.video!,
            item.video!.preview!);

        url = blobUrl.fileNameUrl;
      } else {
        url = userFurnace.url! +
            Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL +
            item.video!.video!;
      }

      _blobService.getItem(
        item,
        userFurnace,
        item.video!.location!,
        url,
        videoPath,
        circleObject.id!,
        progressCallback: progressCallbackItemDownload,
        circleObject: circleObject,
        userCircleCache: userCircleCache,
        failedCallback: failedCallback,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoService.get: $err');

      failedCallback(userFurnace, userCircleCache, circleObject, item);
    }
  }

  progressCallbackItemPreviewDownload(
    UserFurnace userFurnace,
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    int progress,
    String previewPath,
    Function failedCallback,
    CancelToken? cancelToken,
    AlbumItem item,
  ) async {
    try {
      File encrypted = File('${previewPath}enc');

      if (item.video!.streamable!) {
        await encrypted.rename(previewPath);
      } else {
        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }
        File encrypted = File('${previewPath}enc');

        bool success = await EncryptBlob.decryptBlob(DecryptArguments(
            encrypted: encrypted,
            nonce: item.video!.thumbCrank!,
            mac: item.video!.thumbSignature!,
            key: circleObject.secretKey));

        if (!success) {
          item.thumbnailTransferState = BlobState.BLOB_DOWNLOAD_FAILED;
          throw ('unable to decrypt image');
        }
      }

      item.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _globalEventBloc.broadcastItemPreviewDownloaded(item);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("CircleVideoBloc.progressCallbackItemPreviewDownload: $error");

      DownloadFailedReason? reason;

      if (error.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      failedCallback(userFurnace, userCircleCache, circleObject, item,
          cancelToken: cancelToken, reason: reason);
    }
  }

  progressCallbackPreviewDownload(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      int progress,
      String previewPath,
      Function failedCallback,
      CancelToken? cancelToken) async {
    try {
      File encrypted = File('${previewPath}enc');

      if (circleObject.video!.streamable!) {
        await encrypted.rename(previewPath);
      } else {
        if (circleObject.ratchetIndexes.isNotEmpty) {
          circleObject.secretKey ??= await ForwardSecrecy.getSecretKey(
              userCircleCache.usercircle!, circleObject);

          if (circleObject.secretKey!.isEmpty) throw ('could not find key');
        }
        // File encrypted = File('${previewPath}enc');

        if (globalState.isDesktop()) {
          await encrypted.rename(previewPath);
        } else {
          bool success = await EncryptBlob.decryptBlob(DecryptArguments(
              encrypted: encrypted,
              nonce: circleObject.video!.thumbCrank!,
              mac: circleObject.video!.thumbSignature!,
              key: circleObject.secretKey));

          if (!success) {
            circleObject.thumbnailTransferState =
                BlobState.BLOB_DOWNLOAD_FAILED;
            //circleObject.retries = RETRIES.MAX_IMAGE_DOWNLOAD_RETRIES;
            throw ('unable to decrypt image');
          }
        }
      }

      circleObject.video!.videoState = VideoStateIC.PREVIEW_DOWNLOADED;
      await TableCircleObjectCache.updateCacheSingleObject(
          userFurnace.userid!, circleObject);

      _globalEventBloc.broadcastPreviewDownloaded(circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleVideoBloc.progressCallback: $err");

      DownloadFailedReason? reason;

      if (err.toString().toLowerCase().contains('unable to decrypt')) {
        reason = DownloadFailedReason.decryption;
      }

      failedCallback(userFurnace, userCircleCache, circleObject,
          reason: reason);
    }
  }

  downloadAlbumPreview(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      Function failedCallback,
      AlbumItem item) async {
    try {
      Dio dio = Dio();

      String previewPath = VideoCacheService.returnExistingAlbumVideoPath(
          userCircleCache.circlePath!, circleObject, item.video!.preview!);

      String url = '';

      if (item.video!.location == BlobLocation.S3 ||
          item.video!.location == BlobLocation.PRIVATE_S3 ||
          item.video!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.VIDEO,
            circleObject.id!,
            item.video!.video!,
            item.video!.preview!);

        url = blobUrl.thumbnailUrl;
      } else {
        url = userFurnace.url! +
            Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_THUMBNAIL +
            item.video!.preview!;
      }

      if (await Network.isConnected()) {
        Response response = await dio.download(url, '${previewPath}enc',
            options: Options(
              responseType: ResponseType.bytes,
              headers: item.video!.location == BlobLocation.S3 ||
                      item.video!.location == BlobLocation.PRIVATE_S3 ||
                      item.video!.location == BlobLocation.PRIVATE_WASABI
                  ? {}
                  : {
                      'Authorization': userFurnace.token,
                      'authid': circleObject.id!,
                      //'type': circleObject.type,
                      'type': CircleObjectType.CIRCLEVIDEO,
                    },
            ), onReceiveProgress: (int sentBytes, int totalBytes) {
          double progressPercent = sentBytes / totalBytes * 100;
          debugPrint("$progressPercent %");
        });

        if (response.statusCode == 200) {
          progressCallbackItemPreviewDownload(userFurnace, userCircleCache,
              circleObject, 100, previewPath, failedCallback, null, item);
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint(
              'CircleVideoService.downloadAlbumPreview download failed: ${response.statusCode}');
          debugPrint(response.data);

          failedCallback(userFurnace, userCircleCache, circleObject, item,
              cancelToken: null, reason: null);
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
      }

      failedCallback(userFurnace, userCircleCache, circleObject, item,
          cancelToken: null, reason: null);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('CircleVideoService.downloadAlbumPreview: $error');
      failedCallback(
        userFurnace,
        userCircleCache,
        circleObject,
        item,
        cancelToken: null,
        reason: null,
      );
    }
  }

  downloadPreview(UserFurnace userFurnace, UserCircleCache userCircleCache,
      CircleObject circleObject, Function failedCallback) async {
    try {
      Dio dio = Dio();

      //SignedUrl? signedUrl = await _getDownloadSignedUrls(
      // userFurnace, userCircleCache, circleObject);

      String previewPath = VideoCacheService.returnPreviewPath(
          circleObject, userCircleCache.circlePath!);

      String url = '';

      if (circleObject.video!.location == BlobLocation.S3 ||
          circleObject.video!.location == BlobLocation.PRIVATE_S3 ||
          circleObject.video!.location == BlobLocation.PRIVATE_WASABI) {
        BlobUrl blobUrl = await _blobUrlsService.getDownloadUrls(
            userFurnace,
            BlobType.VIDEO,
            circleObject.id!,
            circleObject.video!.video!,
            circleObject.video!.preview!);

        url = blobUrl.thumbnailUrl;
      } else {
        url = userFurnace.url! +
            Urls.GRIDFS_DOWNLOAD_CIRCLEOBJECT_THUMBNAIL +
            circleObject.video!.preview!;
      }

      debugPrint(url);

      if (await Network.isConnected()) {
        Response response = await dio.download(
          url,
          '${previewPath}enc',
          options: Options(
            responseType: ResponseType.bytes,
            headers: circleObject.video!.location == BlobLocation.S3 ||
                    circleObject.video!.location == BlobLocation.PRIVATE_S3 ||
                    circleObject.video!.location == BlobLocation.PRIVATE_WASABI
                ? {}
                : {
                    'Authorization': userFurnace.token,
                    'authid': circleObject.id!,
                    'type': circleObject.type,
                  },
          ),
          onReceiveProgress: (int sentBytes, int totalBytes) {
            double progressPercent = sentBytes / totalBytes * 100;
            debugPrint("$progressPercent %");
          },
        );

        if (response.statusCode == 200) {
          progressCallbackPreviewDownload(userFurnace, userCircleCache,
              circleObject, 100, previewPath, failedCallback, null);

          //return previewPath;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
        } else {
          debugPrint(
              'CircleVideoService.downloadCircleImage image download failed: ${response.statusCode}');
          debugPrint(response.data);

          failedCallback(userFurnace, userCircleCache, circleObject);
          //throw ('download failed');
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
      }

      failedCallback(userFurnace, userCircleCache, circleObject);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideoService.downloadPreview: $err');
      failedCallback(
        userFurnace,
        userCircleCache,
        circleObject,
      );
    }
  }
}
