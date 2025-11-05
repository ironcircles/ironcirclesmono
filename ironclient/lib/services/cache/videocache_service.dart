import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as image_lib;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:path/path.dart';

class CallbackType {
  static const int FULLIMAGE = 0;
  static const int THUMBNAIL = 1;
}

class VideoCacheService {
  static String getFilenameForAPI(
      CircleObject circleObject, String knownPath, String circlePath) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /*if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(globalState.getAppPath(), 'storage_videos',
          circleObject.seed!, pathBuilder = '${pathBuilder}_thumbnail.jpg');
    } else {
      pathBuilder = knownPath;
    }*/

    pathBuilder = knownPath;

    return pathBuilder;
  }

  static String _getPath(CircleObject circleObject, String circlePath,
      {required bool thumbnail, required String extension}) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /*if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_videos',
        circleObject.storageID!,
      );
    } else {*/
    ///videos that existed pre storageID
    if (FileSystemEntity.typeSync(join(circlePath, 'videos')) ==
        FileSystemEntityType.notFound) {
      Directory(join(circlePath, 'videos')).createSync(recursive: true);
    }

    pathBuilder = join(
      circlePath,
      'videos',
      circleObject.seed!,
    );

    if (globalState.isDesktop()) {
      ///the path is seed plus enc
      if (thumbnail) {
        pathBuilder = '${pathBuilder}_preview.enc';
      } else {
        if (circleObject.video!.streamable!) {
          pathBuilder = '$pathBuilder.$extension';
        } else {
          pathBuilder = '${pathBuilder}_full.enc';
        }
      }
      // thumbnail
      //     ? pathBuilder = '${pathBuilder}_preview.enc'
      //     : pathBuilder = '${pathBuilder}_full.enc';
    } else {
      thumbnail
          ? pathBuilder = '${pathBuilder}_preview.jpg'
          : pathBuilder = '$pathBuilder.$extension';
    }

    return pathBuilder;
  }

  static bool isAlbumPreviewCached(
      CircleObject circleObject, String path, AlbumItem item) {
    if (item.video!.preview == null) {
      return false;
    }

    String previewPath =
        returnExistingAlbumVideoPath(path, circleObject, item.video!.preview!);
    bool retValue = FileSystemService.fileExists(previewPath);

    if (retValue) {
      retValue = false;
      //also test the size because somehow flutter was returning events before the file completely downloaded
      if (item.video != null) {
        //test for old images
        if (item.video!.previewSize != null && item.video!.previewSize != 0) {
          var file = File(previewPath);
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == item.video!.previewSize) retValue = true;
        } else {
          retValue = true;
        }
      }
    }

    return retValue;
  }

  static bool isPreviewCached(CircleObject circleObject, String path) {
    // bool retValue = FileSystemService.fileExists(
    // join(path, 'videos', '${circleObject.seed!}_preview.jpg'));

    String previewPath =
        _getPath(circleObject, path, thumbnail: true, extension: '');
    bool retValue = FileSystemService.fileExists(previewPath);

    if (retValue) {
      retValue = false;
      //also test the size because somehow flutter was returning events before the file completely downloaded
      if (circleObject.video != null) {
        //test for old images
        if (circleObject.video!.previewSize != null &&
            circleObject.video!.previewSize != 0) {
          var file = File(previewPath);
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == circleObject.video!.previewSize) retValue = true;
        } else {
          retValue = true;
        }
      }
    }

    return retValue;
  }

  static bool isAlbumVideoCached(
      CircleObject circleObject, String? path, AlbumItem item) {
    if (item.video!.extension == null) return false;

    String videoPath =
        returnExistingAlbumVideoPath(path!, circleObject, item.video!.video!);
    bool retValue = FileSystemService.fileExists(videoPath);

    if (retValue) {
      retValue = false;
      //also test the size because somehow flutter was returning events before the file completely downloaded
      //if (circleObject.video != null) {
      //test for old images
      if (item.video!.videoSize != null) {
        ///decrypt-failure
        if (item.video!.videoSize == 0) return true;

        var file = File(videoPath);
        var length = file.lengthSync();

        //debugPrint ('image size: $length for image ${circleObject.seed}');

        if (length == item.video!.videoSize) retValue = true;
      }
      //}
    }

    return retValue;
  }

  static bool isVideoCached(CircleObject circleObject, String? path) {
    if (circleObject.video!.extension == null) return false;

    String videoPath = _getPath(circleObject, path!,
        thumbnail: false, extension: circleObject.video!.extension!);
    bool retValue = FileSystemService.fileExists(videoPath);

    if (retValue) {
      retValue = false;
      //also test the size because somehow flutter was returning events before the file completely downloaded
      //if (circleObject.video != null) {
      //test for old images
      if (circleObject.video!.videoSize != null) {
        ///decrypt-failure
        if (circleObject.video!.videoSize == 0) return true;

        var file = File(videoPath);
        var length = file.lengthSync();

        //debugPrint ('image size: $length for image ${circleObject.seed}');

        if (length == circleObject.video!.videoSize) retValue = true;
      }
      //}
    }

    return retValue;
  }

  static String returnPreviewPath(
      CircleObject circleObject, String circlePath) {
    return _getPath(circleObject, circlePath, thumbnail: true, extension: '');
  }

  static String returnExistingAlbumVideoPath(
    String circlePath,
    CircleObject circleObject,
    String imageName,
    // bool thumbnail,
    // String extension,
  ) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /*if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_videos',
        circleObject.storageID!,
      );
    } else {*/
    ///videos that existed pre storageID
    if (FileSystemEntity.typeSync(
            join(circlePath, 'albums', circleObject.seed)) ==
        FileSystemEntityType.notFound) {
      String pathMade = join(circlePath, 'albums', circleObject.seed!);
      Directory(pathMade).createSync(recursive: true);
    }

    pathBuilder = join(
      circlePath,
      'albums',
      circleObject.seed!,
      imageName,
    );
    //  }

    return pathBuilder;
  }

  static String returnAlbumVideoPath(
    String circlePath,
    CircleObject circleObject,
    String mediaIndex,
    bool thumbnail,
    String extension,
  ) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /*if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_videos',
        circleObject.storageID!,
      );
    } else {*/
    ///videos that existed pre storageID
    if (FileSystemEntity.typeSync(
            join(circlePath, 'albums', circleObject.seed!)) ==
        FileSystemEntityType.notFound) {
      String pathMade = join(circlePath, 'albums', circleObject.seed!);
      Directory(pathMade).createSync(recursive: true);
    }

    pathBuilder = join(
      circlePath,
      'albums',
      circleObject.seed!,
      mediaIndex,
    );
    //  }

    thumbnail
        ? pathBuilder = '${pathBuilder}_preview.jpg'
        : pathBuilder = '$pathBuilder.$extension';

    return pathBuilder;
  }

  static String returnVideoPath(
      CircleObject circleObject, String circlePath, String extension) {
    return _getPath(circleObject, circlePath,
        thumbnail: false, extension: extension);
  }

  static String returnNewVideoPath(
      CircleObject circleObject, String circlePath, String extension) {
    String videoPath = returnVideoPath(circleObject, circlePath, extension) +
        SecureRandomGenerator.generateString(length: 3);

    /*String pathBuilder = join(
      circlePath,
      'videos',
      "$seed${SecureRandomGenerator.generateString(length: 3)}.$extension",
    );

     */

    return videoPath;
  }

  /*static String _createVideoPath(String circlePath, String seed, File video) {
    if (FileSystemEntity.typeSync(join(circlePath, 'videos')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(join(circlePath, 'videos')).createSync(recursive: true);
    }

    String extension = FileSystemService.getExtension(video.path);

    String pathBuilder = join(circlePath, 'videos', '$seed.$extension');

    return pathBuilder;
  }

   */

  static Future<File> cacheAlbumVideo(UserCircleCache userCircleCache,
      CircleObject circleObject, File video, String mediaIndex) async {
    try {
      String videoPath = returnAlbumVideoPath(
          userCircleCache.circlePath!,
          circleObject,
          mediaIndex,
          false,
          FileSystemService.getExtension(video.path));

      //copy the video
      await video.copy(videoPath);

      return File(videoPath);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("VideoCacheService.cacheAlbumVideo: $error");
      rethrow;
    }
  }

  static Future<File> cacheVideo(UserCircleCache userCircleCache,
      CircleObject circleObject, File video) async {
    try {
      String videoPath = returnVideoPath(
          circleObject,
          userCircleCache.circlePath!,
          FileSystemService.getExtension(video.path));

      //copy the video
      await video.copy(videoPath);

      return File(videoPath);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("VideoCacheService.cacheVideo: $err");
      rethrow;
    }
  }

  static Future<File> getThumbnail(String source, String destination, int frame) async {
    try {
      //if (globalState.isDesktop()) {
        final plugin = FcNativeVideoThumbnail();

        final thumbnailGenerated = await plugin.getVideoThumbnail(
            srcFile: source,
            destFile: destination,
            width: 800,
            height: 800,
            //keepAspectRatio: true,
            format: 'jpeg',
            quality: 100);

        File file = File(destination);

        if (thumbnailGenerated && file.existsSync()) {
          debugPrint(file.path);
          return file;
        } else
          throw ('could not create video thumbnail');
      // } else {
      //   String? file = await VideoThumbnail.thumbnailFile(
      //       video: source,
      //       thumbnailPath: destination,
      //       imageFormat: ImageFormat.JPEG,
      //       //maxHeight: 200,
      //       // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
      //       quality: 100,
      //       timeMs: frame);
      //
      //   if (file != null)
      //     return File(file);
      //   else
      //     throw ('could not create video thumbnail');
      // }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("VideoCacheService.cacheVideoThumbnail: $err");
      return cacheFromAssets(File(destination), 'images/nopreview.jpg');
    }
  }

  static Future<File> cacheTempVideoPreview(
      String videoPath, int thumbNailFrame) async {
    String previewPath = await FileSystemService.returnTempPathAndImageFile();
    try {
      await getThumbnail(videoPath, previewPath, thumbNailFrame);

      return (File(previewPath));
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<File> cacheFromAssets(File thumbnail, String path) async {
    final byteData = await rootBundle.load('assets/$path');

    await thumbnail.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return thumbnail;
  }

  static setItemSize(AlbumItem item, String filePath) {
    image_lib.Image? fileImage =
        image_lib.decodeImage(File(filePath).readAsBytesSync());

    item.video!.width = fileImage!.width;
    item.video!.height = fileImage.height;
  }

  static setSize(CircleObject circleObject, String filePath) {
    image_lib.Image? fileImage =
        image_lib.decodeImage(File(filePath).readAsBytesSync());

    circleObject.video!.width = fileImage!.width;
    circleObject.video!.height = fileImage.height;
  }

  static Future<File> cacheAlbumVideoPreview(
    UserCircleCache userCircleCache,
    CircleObject circleObject,
    File cachedVideo,
    int? thumbNailFrame,
    bool orientationNeeded,
    String mediaIndex,
    AlbumItem item,
  ) async {
    try {
      // String previewPath = returnAlbumVideoPath(
      //     userCircleCache.circlePath!, circleObject, mediaIndex, true, '');
      //
      // String? file;
      //
      // if (orientationNeeded) {
      //   String? needsOrientation = await VideoThumbnail.thumbnailFile(
      //       video: cachedVideo.path,
      //       thumbnailPath: "${previewPath}temp.jpg",
      //       imageFormat: ImageFormat.JPEG,
      //       maxHeight: 0,
      //       maxWidth: 0,
      //       quality: 100,
      //       timeMs: thumbNailFrame ?? 0);
      //
      //   image_lib.Image? fileImage =
      //       image_lib.decodeImage(File(needsOrientation!).readAsBytesSync());
      //
      //   item.video!.width = fileImage!.width;
      //   item.video!.height = fileImage.height;
      //
      //   if (fileImage.width > fileImage.height) {
      //     XFile? fixedImage = await FlutterImageCompress.compressAndGetFile(
      //       needsOrientation,
      //       previewPath,
      //       rotate: 180,
      //       quality: 100,
      //       keepExif: false,
      //       autoCorrectionAngle: true,
      //       format: CompressFormat.jpeg,
      //     );
      //
      //     file = fixedImage!.path;
      //   } else {
      //     await File(needsOrientation).rename(previewPath);
      //     file = previewPath;
      //   }
      // } else {
      //   file = await VideoThumbnail.thumbnailFile(
      //       video: cachedVideo.path,
      //       thumbnailPath: previewPath,
      //       imageFormat: ImageFormat.JPEG,
      //       maxHeight: 0,
      //       maxWidth: 0,
      //       quality: 100,
      //       timeMs: thumbNailFrame ?? 0);
      // }
      //
      // if (file != null) {
      //   image_lib.Image? fileImage =
      //       image_lib.decodeImage(File(file).readAsBytesSync());
      //
      //   item.video!.width = fileImage!.width;
      //   item.video!.height = fileImage.height;
      //
      //   return File(file);
      // } else
      //   throw ('could not create video thumbnail');

      return File("remove");
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("VideoCacheService.cacheAlbumVideoThumbnail: $err");
      rethrow;
      //return cacheFromAssets(File(returnPreviewPath(userCircleCache.circlePath!, circleObject.seed!)), 'images\\white.jpg');
    }
  }

  static Future<File> cacheVideoPreview(
      String tempPreview,
      UserCircleCache userCircleCache,
      CircleObject circleObject,
      File cachedVideo,
      int? thumbNailFrame,
      bool orientationNeeded) async {
    try {
      String previewPath =
          returnPreviewPath(circleObject, userCircleCache.circlePath!);

      if (globalState.isDesktop()) {
        File temp = File(tempPreview);
        await temp.copy(previewPath);

        ///remove the temp preview
        temp.delete();

        File file = File(previewPath);

        if (file.existsSync()) {
          image_lib.Image? fileImage =
              image_lib.decodeImage(file.readAsBytesSync());

          circleObject.video!.width = fileImage!.width;
          circleObject.video!.height = fileImage.height;

          return file;
        } else
          throw ('could not create video thumbnail');
      } else {
        File? file;

        if (orientationNeeded) {
          File? needsOrientation = await
              getThumbnail(cachedVideo.path, previewPath, thumbNailFrame ?? 0);

          image_lib.Image? fileImage =
              image_lib.decodeImage(needsOrientation.readAsBytesSync());

          circleObject.video!.width = fileImage!.width;
          circleObject.video!.height = fileImage.height;

          if (fileImage.width > fileImage.height) {
            await ImageCacheService.compressImage(
                needsOrientation, previewPath, 100);

            file = File(previewPath);
          } else {
            await needsOrientation.rename(previewPath);
            file = File(previewPath);
          }
        } else {
          // file = await VideoThumbnail.thumbnailFile(
          //     video: cachedVideo.path,
          //     thumbnailPath: previewPath,
          //     imageFormat: ImageFormat.JPEG,
          //     maxHeight: 0,
          //     maxWidth: 0,
          //     quality: 100,
          //     timeMs: thumbNailFrame ?? 0);

          file =
              await getThumbnail(cachedVideo.path, previewPath, thumbNailFrame ?? 0);
        }

        if (file != null) {
          image_lib.Image? fileImage =
              image_lib.decodeImage(file.readAsBytesSync());

          circleObject.video!.width = fileImage!.width;
          circleObject.video!.height = fileImage.height;

          return file;
        } else
          throw ('could not create video thumbnail');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("VideoCacheService.cacheVideoThumbnail: $err");
      rethrow;
      //return cacheFromAssets(File(returnPreviewPath(userCircleCache.circlePath!, circleObject.seed!)), 'images\\white.jpg');
    }
  }

  static Future<bool> deleteItemCache(
    String circlePath,
    CircleObject circleObject,
    AlbumItem item,
  ) async {
    bool retValue = false;

    try {
      File video = File(returnAlbumVideoPath(circlePath, circleObject,
          item.video!.video!, false, item.video!.extension!));

      if (PremiumFeatureCheck.wipeFileOn()) {
        FileSystemService.wipeFile([video.path]);
      } else {
        if (video.existsSync()) video.delete();
      }

      retValue = true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("VideoCacheService.deleteItemCache: $error");
    }
    return retValue;
  }

  static Future<bool> deleteCache(
      String circlePath, CircleObject circleObject) async {
    bool retValue = false;

    try {
      File video = File(returnVideoPath(
          circleObject, circlePath, circleObject.video!.extension!));

      if (PremiumFeatureCheck.wipeFileOn()) {
        ///rename the file to a random name so the UI can refresh before the wipe finishes
        await video.rename(returnNewVideoPath(
            circleObject, circlePath, circleObject.video!.extension!));

        ///then delete the file
        FileSystemService.wipeFile([video.path]);
      } else {
        if (video.existsSync()) video.delete();
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleObjectImage: $err");
    }

    return retValue;
  }

  static Future<bool> deleteAlbumVideo(
    String circlePath,
    CircleObject circleObject,
    AlbumItem item,
  ) async {
    bool retValue = false;

    try {
      if (circleObject.video != null) {
        File video = File(returnAlbumVideoPath(circlePath, circleObject,
            item.video!.video!, false, item.video!.extension!));
        File preview = File(returnAlbumVideoPath(
            circlePath, circleObject, item.video!.preview!, true, ""));

        if (PremiumFeatureCheck.wipeFileOn()) {
          FileSystemService.wipeFile([video.path, preview.path]);
        } else {
          if (video.existsSync()) video.delete();
          if (preview.existsSync()) preview.delete();
        }

        retValue = true;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("VideoCacheService.deleteAlbumVideo: $error");
    }
    return retValue;
  }

  static Future<bool> deleteVideo(
      String circlePath, CircleObject circleObject) async {
    bool retValue = false;

    try {
      if (circleObject.video != null) {
        File video = File(returnVideoPath(
            circleObject, circlePath, circleObject.video!.extension!));
        File preview = File(returnPreviewPath(circleObject, circlePath));

        if (PremiumFeatureCheck.wipeFileOn()) {
          FileSystemService.wipeFile([video.path, preview.path]);
        } else {
          if (video.existsSync()) video.delete();
          if (preview.existsSync()) preview.delete();
        }

        retValue = true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleObjectImage: $err");
    }

    return retValue;
  }
}
