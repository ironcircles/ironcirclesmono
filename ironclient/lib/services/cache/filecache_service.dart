import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:path/path.dart';

class FileCacheService {
  static bool isFileCached(CircleObject circleObject, String path) {

    if (circleObject.file == null || circleObject.file!.extension ==null) return false;

    String extension = circleObject.file!.extension!;

    if (globalState.isDesktop()){
      extension = "enc"; ///desktop files are encrypted
    }

    bool retValue = FileSystemService.fileExists(join(path, 'files',
        '${circleObject.seed!}.$extension'));

    if (retValue) {
      retValue = false;
      //also test the size because somehow flutter was returning events before the file completely downloaded
      if (circleObject.file != null) {
        //test for old images
        if (circleObject.file!.fileSize != null &&
            circleObject.file!.fileSize != 0) {
          var file = File(join(path, 'files',
              '${circleObject.seed!}.$extension'));
          var length = file.lengthSync();

          if (length == circleObject.file!.fileSize) retValue = true;
        } else {
          retValue = true;
        }
      }
    }

    return retValue;
  }

  static String returnFilePath(String circlePath, String name) {
    String pathBuilder = join(circlePath, 'files', name);
    return pathBuilder;
  }

  static String _createFilePath(String circlePath, String seed, File file) {
    String extension = FileSystemService.getExtension(file.path);

    if (FileSystemEntity.typeSync(join(circlePath, 'files')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(join(circlePath, 'files')).createSync(recursive: true);
    }

    String pathBuilder = join(circlePath, 'files', '$seed.$extension');

    return pathBuilder;
  }

  static Future<File> cacheFile(UserCircleCache userCircleCache,
      CircleObject circleObject, File file) async {
    try {
      String filePath = _createFilePath(
          userCircleCache.circlePath!, circleObject.seed!, file);

      ///copy the file
      await file.copy(filePath);

      return File(filePath);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileCacheService.cacheFile: $err");
      rethrow;
    }
  }

  static Future<bool> deleteCache(
      String circlePath, CircleObject circleObject) async {
    bool retValue = false;

    try {
      File file = File(returnFilePath(circlePath,
          '${circleObject.seed!}.${circleObject.file!.extension!}'));

      if (PremiumFeatureCheck.wipeFileOn()) {
        FileSystemService.wipeFile([file.path]);
      } else {
        if (file.existsSync()) file.delete();
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleObjectImage: $err");
    }

    return retValue;
  }

  static Future<bool> deleteFile(
      String circlePath, CircleObject circleObject) async {
    bool retValue = false;

    try {
      File file = File(returnFilePath(
          circlePath, circleObject.seed! + (globalState.isDesktop() ? '.enc': '.${circleObject.file!.extension!}')));

      if (PremiumFeatureCheck.wipeFileOn()) {
        FileSystemService.wipeFile([file.path]);
      } else {
        if (file.existsSync()) file.delete();
      }

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleObjectFile: $err");
    }

    return retValue;
  }
}
