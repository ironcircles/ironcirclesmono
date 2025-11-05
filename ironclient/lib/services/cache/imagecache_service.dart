import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart';
//import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/utils/fileutil.dart';
import 'package:path/path.dart';

class CallbackType {
  static const int FULLIMAGE = 0;
  static const int THUMBNAIL = 1;
}

class ImageCacheService {
  static String getFilenameForAPI(
      CircleObject circleObject, String knownPath, String circlePath) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /*if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_images',
        circleObject.seed!,

          pathBuilder = '${pathBuilder}_thumbnail.jpg'
      );
    } else {
      pathBuilder = knownPath;
    }*/

    pathBuilder = knownPath;

    return pathBuilder;
  }

  static String _getPath(CircleObject circleObject, String circlePath,
      {required bool thumbnail}) {
    String pathBuilder = '';

    ///commented out until feed is implemented
    /* if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_images',
        circleObject.storageID!,
      );
    } else {*/

    ///images that existed pre storageID
    if (FileSystemEntity.typeSync(join(circlePath, 'images')) ==
        FileSystemEntityType.notFound) {
      Directory(join(circlePath, 'images')).createSync(recursive: true);
    }

    if (globalState.isDesktop()) {
      ///the path is seed plus enc
      pathBuilder = join(
        circlePath,
        'images',
        circleObject.seed!,
      );
      // }

      thumbnail
          ? pathBuilder = '${pathBuilder}_thumbnail.enc'
          : pathBuilder = '${pathBuilder}_full.enc';
    } else {
      pathBuilder = join(
        circlePath,
        'images',
        circleObject.seed!,
      );
      // }

      thumbnail
          ? pathBuilder = '${pathBuilder}_thumbnail.jpg'
          : pathBuilder = '${pathBuilder}_full.jpg';
    }

    return pathBuilder;
  }

  writeByteDataToFile(
      ByteData byteData, String path, Function? callback) async {
    await FileUtil.writeByteDataToFile(path, byteData);

    if (callback != null) callback();

    debugPrint('byte data cached + ${DateTime.now().toLocal()}');
  }

  static String returnAlbumImagePath(
      String circlePath,
      CircleObject circleObject,
      bool thumbnail,
      String mediaIndex,
      String extension,
      ) {
    try {
      String pathBuilder = '';

      ///commented out until feed is implemented
      /* if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_images',
        circleObject.storageID!,
      );
    } else {*/
      ///images that existed pre storageID
      // if (FileSystemEntity.typeSync(join(circlePath, 'albums')) ==
      //     FileSystemEntityType.notFound) {
      //   Directory(join(circlePath, 'albums')).createSync(recursive: true);
      // }

      if (FileSystemEntity.typeSync(join(circlePath, 'albums', circleObject.seed!)) ==
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
      // }

      if (extension == "gif") {
        thumbnail
            ? pathBuilder = '${pathBuilder}_thumbnail.gif'
            : pathBuilder = '${pathBuilder}_full.gif';
      } else {
        thumbnail
            ? pathBuilder = '${pathBuilder}_thumbnail.jpg'
            : pathBuilder = '${pathBuilder}_full.jpg';
      }

      return pathBuilder;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static String returnExistingAlbumImagePath(
      String circlePath,
      CircleObject circleObject,
      String imageName
      ) {
    try {
      String pathBuilder = '';

      ///commented out until feed is implemented
      /* if (circleObject.storageID != null && circleObject.storageID!.isNotEmpty) {
      pathBuilder = join(
        globalState.getAppPath(),
        'storage_images',
        circleObject.storageID!,
      );
    } else {*/
      ///images that existed pre storageID
      // if (FileSystemEntity.typeSync(join(circlePath, 'albums')) ==
      //     FileSystemEntityType.notFound) {
      //   Directory(join(circlePath, 'albums')).createSync(recursive: true);
      // }

      if (FileSystemEntity.typeSync(join(circlePath, 'albums', circleObject.seed!)) ==
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
      // }

      return pathBuilder;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static String returnThumbnailPath(
    String circlePath,
    CircleObject circleObject,
  ) {
    try {
      return _getPath(circleObject, circlePath, thumbnail: true);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static String returnFullImagePath(
    String circlePath,
    CircleObject circleObject,
  ) {
    try {
      return _getPath(circleObject, circlePath, thumbnail: false);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static Future<String> compressImage(
      File source, String destination, int quality,
      {bool rotate = false}) async {
    try {
      if (globalState.isDesktop()) {
        // String path = '$thumbnail.jpg';

        final image =decodeImage(source.readAsBytesSync());
        if (image != null) {
          final output =encodeJpg(image, quality: 80);
          await FileUtil.writeBytesToFile(destination, output);
        }

        // ImageFile input = ImageFile(
        //     filePath: destination, //path,
        //     rawBytes: source.readAsBytesSync()); // set the input image file
        // Configuration config = Configuration(
        //   outputType: ImageOutputType.webpThenJpg,
        //   // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
        //   useJpgPngNativeCompressor: false,
        //   // set quality between 0-100
        //   quality: quality,
        // );
        //
        // final param = ImageFileConfiguration(input: input, config: config);
        // final output = await compressor.compress(param);
        //

        //
        // print("Input size : ${input.sizeInBytes}");
        // print("Output size : ${output.sizeInBytes}");
      } else {
        if (rotate) {
          await FlutterImageCompress.compressAndGetFile(
            source.path,
            destination,
            minWidth: 800,
            quality: quality,
            rotate: 180,
            keepExif: false,
            autoCorrectionAngle: true,
          );
        } else {
          //create a thumbnail
          await FlutterImageCompress.compressAndGetFile(
            source.path,
            destination,
            minWidth: 800,
            quality: quality,
            //rotate: 180,
          );
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      ///use the full image
      await source.copy(destination);
    }

    return destination;
  }

  createThumbnail(CircleObject circleObject, String thumbnail, File source,
      bool compress) async {
    try {
      debugPrint('copying thumbnail + ${DateTime.now().toLocal()}');

      int length = await source.length();

      if (length < 150000 || !compress) {
        //don't compress it
        await source.copy(thumbnail);
      } else {
        int quality = 100;

        if (length > 25000000)
          quality = 10;
        else if (length > 18000000)
          quality = 14;
        else if (length > 15000000)
          quality = 20;
        else if (length > 12000000)
          quality = 22;
        else if (length > 9000000)
          quality = 25;
        else if (length > 1000000)
          quality = 35;
        else if (length > 750000)
          quality = 45;
        else if (length > 500000)
          quality = 55;
        else if (length > 250000)
          quality = 75;
        else if (length > 150000)
          quality = 95;
        else if (length > 80000) quality = 98;

        thumbnail = await compressImage(source, thumbnail, quality);
      }

      File thumbnailFile = File(thumbnail);
      if (!thumbnailFile.existsSync()) throw ('compression failed');

      ///there are instances where the compressed image is larger than the original if the original is small
      if (thumbnailFile.lengthSync() > source.lengthSync()) {
        await thumbnailFile.delete();
        await source.copy(thumbnail);
      }
      // } else if (globalState.isDesktop()) {
      //   ///image compression library won't create a thumbnail with an .enc extension
      //   ///rename the file
      //   await thumbnailFile.rename(thumbnail);
      //   thumbnailFile = File(thumbnail);
      // }

      debugPrint('thumbnail created + ${DateTime.now().toLocal()}');
    } on UnsupportedError catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("ImageCacheService.createFullImage: $err");
      rethrow;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("ImageCacheService.createFullImage: $err");
      rethrow;
    }
  }

  createFullFallback(
      CircleObject circleObject, String thumbnail, File source) async {
    try {
      debugPrint('copying thumbnail + ${DateTime.now().toLocal()}');

      int length = await source.length();

      int quality = 100;

      if (length > 10000000)
        quality = 15;
      else if (length > 9000000)
        quality = 16;
      else if (length > 8000000)
        quality = 18;
      else if (length > 7000000)
        quality = 20;
      else if (length > 6000000)
        quality = 20;
      else if (length > 5000000)
        quality = 25;
      else if (length > 4000000)
        quality = 25;
      else if (length > 3000000)
        quality = 25;
      else if (length > 2000000)
        quality = 25;
      else if (length > 1000000)
        quality = 35;
      else if (length > 750000)
        quality = 45;
      else if (length > 500000)
        quality = 55;
      else if (length > 250000)
        quality = 55;
      else if (length > 150000)
        quality = 85;
      else if (length > 80000) quality = 98;

      await compressImage(source, thumbnail, quality);
      if (!File(thumbnail).existsSync()) throw ('compression failed');

      debugPrint('thumbnail created + ${DateTime.now().toLocal()}');
    } on UnsupportedError catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static int getFullImageQuality(bool hiRes, int length) {
    int quality = 100;

    if (hiRes) return 100;

    if (length > 10000000)
      hiRes ? quality = 100 : quality = 25;
    else if (length > 9000000)
      hiRes ? quality = 98 : quality = 25;
    else if (length > 8000000)
      hiRes ? quality = 98 : quality = 25;
    else if (length > 7000000)
      hiRes ? quality = 98 : quality = 25;
    else if (length > 6000000)
      hiRes ? quality = 98 : quality = 25;
    else if (length > 5000000)
      hiRes ? quality = 99 : quality = 55;
    else if (length > 4000000)
      hiRes ? quality = 99 : quality = 55;
    else if (length > 3000000)
      hiRes ? quality = 99 : quality = 55;
    else if (length > 2000000)
      hiRes ? quality = 99 : quality = 55;
    else if (length > 1000000)
      hiRes ? quality = 99 : quality = 55;
    else if (length > 750000)
      hiRes ? quality = 100 : quality = 60;
    else if (length > 500000)
      hiRes ? quality = 100 : quality = 65;
    else if (length > 250000)
      hiRes ? quality = 100 : quality = 80;
    else if (length > 200000) hiRes ? quality = 100 : quality = 90;

    return quality;
  }

  createFull(CircleObject circleObject, String fullImage, File source,
      bool compress, bool hiRes) async {
    try {
      debugPrint('copying full + ${DateTime.now().toLocal()}');

      int length = await source.length();

      if (length < 999999 || !compress) {
        ///don't compress it
        await source.copy(fullImage);
      } else {
        int quality = getFullImageQuality(hiRes, length);

        await compressImage(source, fullImage, quality);
        if (!File(fullImage).existsSync()) throw ('compression failed');
      }

      if (!File(fullImage).existsSync()) throw ('compression failed');

      debugPrint('thumbnail created + ${DateTime.now().toLocal()}');
    } on UnsupportedError catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("ImageCacheService.createFullImage: $err");
      rethrow;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("ImageCacheService.createFullImage: $err");
      rethrow;
    }
  }

  copyFullAndThumbnail(CircleObject circleObject, String thumbnail, String full,
      File source, bool compress,
      {hiRes = false}) async {
    try {
      debugPrint('creating fullimage + ${DateTime.now().toLocal()}');

      //await source.copy(full);
      await createFull(circleObject, full, source, compress, hiRes);
      debugPrint('fullimage created + ${DateTime.now().toLocal()}');

      await createThumbnail(circleObject, thumbnail, source, compress);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("ImageCacheService.createFullImage: $err");
      rethrow;
    }
  }

  Future<File> cacheMarkup(Uint8List bytes) async {
    try {
      String filePath = await FileSystemService.returnTempPathAndImageFile();

      File? file = await FileUtil.writeBytesToFile(filePath, bytes);

      if (file == null) throw ('could not create markup');

      return file;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("CircleImageService.cacheTempAssets: $err");
      rethrow;
    }
  }

  static Future<bool> deleteCircleObjectImage(
      CircleObject circleObject, String circlePath) async {
    bool retValue = false;

    try {
      File thumbnail = File(returnThumbnailPath(circlePath, circleObject));
      File full = File(returnFullImagePath(circlePath, circleObject));

      if (PremiumFeatureCheck.wipeFileOn()) {
        List<String> paths = [thumbnail.path, full.path];

        FileSystemService.wipeFile(paths);
      } else {
        if (thumbnail.existsSync()) thumbnail.delete();

        if (full.existsSync()) full.delete();
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleObjectImage: $err");
    }

    return retValue;
  }

  static Future<bool> deleteAlbumImage(
      CircleObject circleObject, String circlePath, AlbumItem item) async {
    bool retValue = true;

    try {
      File thumbnail = File(returnExistingAlbumImagePath(
          circlePath, circleObject, item.image!.thumbnail!));

      File full = File(returnExistingAlbumImagePath(
        circlePath, circleObject, item.image!.fullImage!));

      if (PremiumFeatureCheck.wipeFileOn()) {
        List<String> paths = [thumbnail.path, full.path];

        FileSystemService.wipeFile(paths);
      } else {
        if (thumbnail.existsSync()) thumbnail.delete();

        if (full.existsSync()) full.delete();
      }
      retValue = true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("FileSystem.deleteAlbumImage: $error");
    }
    return retValue;
  }

  static bool isRecipeImageCached(int? size, String path, String seed) {
    String fullPath = join(path, 'images', '${seed}_thumbnail.jpg');

    bool retValue = FileSystemService.fileExists(fullPath);

    if (retValue) {
      retValue = false;
      //also test the size
      if (size != null) {
        var file = File(join(path, 'images', '${seed}_thumbnail.jpg'));
        var length = file.lengthSync();

        if (length == size) retValue = true;
      }
    }

    return retValue;
  }

  static bool isThumbnailCached(
      CircleObject? circleObject, String path, String seed) {
    //String thumbPath = join(path, 'images', '${seed}_thumbnail.jpg');
    String thumbPath = returnThumbnailPath(path, circleObject!);
    bool retValue = FileSystemService.fileExists(thumbPath);

    if (retValue) {
      retValue = false;
      //also test the size
      if (circleObject.image != null) {
        //test for old images
        if (circleObject.image!.thumbnailSize != 0) {
          //var file = File(join(path, 'images', seed + '_thumbnail.jpg'));
          File file = (File(thumbPath));
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == circleObject.image!.thumbnailSize) retValue = true;

          // debugPrint('size matches: $retValue');
          //else if (length > 50) {
          // debugPrint('image size: $length for image ${circleObject.seed}');
          // retValue = true;
          //}
        } else {
          LogBloc.insertLog(
              "Thumbnail has no size", "ImageCacheService.isThumbnailCached");
          //retValue = true;
        }
      }
    }

    return retValue;
  }

  static bool isAlbumThumbnailCached(CircleObject circleObject,
      AlbumItem item, String path) {

    if (item.image == null || item.image!.thumbnail == null) {
      return false;
    }

    String thumbPath = returnExistingAlbumImagePath(
        path, circleObject, item.image!.thumbnail!);
    bool retValue = FileSystemService.fileExists(thumbPath);

    if (retValue) {
      retValue = false;
      //also test the size
      if (item.image != null) {
        //test for old images
        if (item.image!.thumbnailSize != 0) {
          var file = File(thumbPath);
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == item.image!.thumbnailSize) retValue = true;
          //else if (length > 50) {
          // debugPrint('image size: $length for image ${circleObject.seed}');
          // retValue = true;
          //}
        } else
          retValue = true; //test for old images
      }
    }

    return retValue;
  }

  static bool isAlbumFullImageCached(CircleObject circleObject,
      AlbumItem item, String path, String seed) {

    String fullPath = returnExistingAlbumImagePath(
        path, circleObject, item.image!.fullImage!);
    bool retValue = FileSystemService.fileExists(fullPath);

    if (retValue) {
      retValue = false;
      //also test the size
      if (item.image != null) {
        //test for old images
        if (item.image!.fullImageSize != 0) {
          var file = File(fullPath);
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == item.image!.fullImageSize) retValue = true;
          //else if (length > 50) {
          // debugPrint('image size: $length for image ${circleObject.seed}');
          // retValue = true;
          //}
        } else
          retValue = true; //test for old images
      }
    }

    return retValue;
  }

  static bool isFullImageCached(
      CircleObject? circleObject, String path, String seed) {
    // bool retValue =
    //    FileSystemService.fileExists(join(path, 'images', '${seed}_full.jpg'));

    String fullPath = returnFullImagePath(path, circleObject!);
    bool retValue = FileSystemService.fileExists(fullPath);

    if (retValue) {
      retValue = false;
      //also test the size
      if (circleObject.image != null) {
        //test for old images
        if (circleObject.image!.fullImageSize != 0) {
          var file = File(fullPath);
          var length = file.lengthSync();

          //debugPrint ('image size: $length for image ${circleObject.seed}');

          if (length == circleObject.image!.fullImageSize) retValue = true;
          //else if (length > 50) {
          // debugPrint('image size: $length for image ${circleObject.seed}');
          // retValue = true;
          //}
        } else
          retValue = true; //test for old images
      }
    }

    return retValue;
  }
}
