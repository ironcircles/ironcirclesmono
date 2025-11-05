import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/hostedfurnaceimage.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

_wipeFileIsolate(List<String> paths) async {
  //Create a buffer
  List<int> buffer = [];
  int bufferLength = 4000;

  for (int i = 0; i < bufferLength; i++) {
    buffer.add(9223372036854775807); //largest int dart can handle
  }

  for (String path in paths) {
    try {
      File file = File(path);
      debugPrint("wipe file start: ${DateTime.now()}");

      int totalBytes = file.lengthSync();

      RandomAccessFile raf = await file.open(mode: FileMode.append);

      ///shred the file
      for (int i = 0; i < 3; i++) {
        int position = 0;
        do {
          raf.setPositionSync(position);
          raf = await raf.writeFrom(buffer);

          debugPrint('shredding $position');
          position = position + bufferLength;
        } while (position < totalBytes);
      }

      ///now delete the shredded file
      await raf.close();

      file.delete();

      debugPrint("wipe file end: ${DateTime.now()}");
    } catch (err, trace) {
      //LogBloc.insertError(err, trace);
      debugPrint("FileSystem._wipeFileIsolate: $err");
    }
  }
}

class FileSystemService {
  FileSystemService._();

  static const String androidCameraPath = '/storage/emulated/0/DCIM/Camera';
  static const String downloadPath = '/storage/emulated/0/Download';

  static wipeFile(List<String> paths) async {
    await compute(_wipeFileIsolate, paths);
  }

  static cleanUpSystemCache() async {
    //delete from root of cache
    /*Directory cacheDirectory = await getTemporaryDirectory();

    List<FileSystemEntity> files = cacheDirectory.listSync(recursive: false);

    for (var fileSystemEntity in files) {
      if (fileSystemEntity is File) {
        //if (fileSystemEntity.path.contains('image_picker') ||
        //fileSystemEntity.path.contains('.jpg')) {
        try {
          fileSystemEntity.delete();
        } catch (err, trace) {
          debugPrint('$err');
          debugPrint('$trace');
        }
      }
    }

     */

    List<FileSystemEntity> keychains =
        Directory(await globalState.getAppPath()).listSync(recursive: false);

    for (var fileSystemEntity in keychains) {
      if (fileSystemEntity is File) {
        //if (fileSystemEntity.path.contains('image_picker') ||

        try {
          if (fileSystemEntity.path.contains('.encenc')) {
            fileSystemEntity.delete();
          }
        } catch (err, trace) {
          debugPrint('$err');
          debugPrint('$trace');
        }
      }
    }

    //************************  keep below

    try {
      //delete temp
      Directory temp =
          Directory(p.join(await globalState.getAppPath(), 'temp'));

      if (temp.existsSync()) temp.delete(recursive: true);
    } catch (err, trace) {
      debugPrint('$err');
      debugPrint('$trace');
    }

    try {
      List<FileSystemEntity> keychains =
          Directory(p.join(await globalState.getAppPath(), 'temp_images'))
              .listSync(recursive: false);

      for (var fileSystemEntity in keychains) {
        if (fileSystemEntity is File) {
          fileSystemEntity.delete();
        }
      }
    } catch (err, trace) {
      debugPrint('$err');
      debugPrint('$trace');
    }

    try {
      //delete keychains
      Directory keychains =
          Directory(p.join(await globalState.getAppPath(), 'keychains'));
      if (keychains.existsSync()) keychains.delete(recursive: true);
    } catch (err, trace) {
      debugPrint('$err');
      debugPrint('$trace');
    }
  }

  static Future<String> makeUserPath(String? userID) async {
    String userPath = p.join(await globalState.getAppPath(), 'users', userID);

    if (FileSystemEntity.typeSync(userPath) == FileSystemEntityType.notFound) {
      Directory(userPath).createSync(recursive: true);
    }

    return userPath;
  }

  static makePaths() async {
    String appPath = await globalState.getAppPath();

    if (FileSystemEntity.typeSync(appPath) == FileSystemEntityType.notFound) {
      Directory(appPath).createSync(recursive: true);
    }

    await _makeDiscoverableNetworkImageFolder(appPath);
    await _makeMediaStorageFolder(appPath);
    await _makeTempImageFolder(appPath);
  }

  static _makeTempImageFolder(String appPath) async {
    String folderPath = p.join(appPath, 'temp_images');
    if (FileSystemEntity.typeSync(folderPath) ==
        FileSystemEntityType.notFound) {
      Directory(folderPath).createSync();
    }
  }

  static Future<File> getNewTempImageFile() async {
    String path = p.join(await globalState.getAppPath(), 'temp_images');

    return File(p.join(path, '${const Uuid().v4()}.jpg'));
  }

  static _makeMediaStorageFolder(String appPath) async {
    String folderPath = p.join(appPath, 'storage_images');
    if (FileSystemEntity.typeSync(folderPath) ==
        FileSystemEntityType.notFound) {
      Directory(folderPath).createSync();
    }

    folderPath = p.join(await globalState.getAppPath(), 'storage_videos');
    if (FileSystemEntity.typeSync(folderPath) ==
        FileSystemEntityType.notFound) {
      Directory(folderPath).createSync();
    }
  }

  static _makeDiscoverableNetworkImageFolder(String appPath) async {
    String folderPath = p.join(appPath, 'network_images');
    if (FileSystemEntity.typeSync(folderPath) ==
        FileSystemEntityType.notFound) {
      Directory(folderPath).createSync();
    }
  }

  static Future<String> getKeyChainBackupPath() async {
    String path = p.join(await globalState.getAppPath(), 'keychains');

    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      Directory(path).createSync(recursive: true);
    }

    return path;
  }

  static Future<String> copyToDrafts(File file) async {
    String path = await getDraftFilesPath();

    File newFile = await file.copy(path);

    return newFile.path;
  }

  static Future<String> getDraftFilesPath() async {
    String path = p.join(await globalState.getAppPath(), 'drafts');

    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      Directory(path).createSync(recursive: true);
    }

    return p.join(path, const Uuid().v4());
  }

  static Future<String> makeCirclePath(String? user, String? circle) async {
    String circlePath = p.join(
        await globalState.getAppPath(), 'users', '$user', 'circles', '$circle');

    //debugPrint(FileSystemEntity.typeSync(circlePath));

    if (FileSystemEntity.typeSync(circlePath) ==
        FileSystemEntityType.notFound) {
      Directory(circlePath).createSync(recursive: true);
    }

    if (FileSystemEntity.typeSync(p.join(circlePath, 'files')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(p.join(circlePath, 'files')).createSync(recursive: true);
    }

    if (FileSystemEntity.typeSync(p.join(circlePath, 'images')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(p.join(circlePath, 'images')).createSync(recursive: true);
    }

    if (FileSystemEntity.typeSync(p.join(circlePath, 'videos')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(p.join(circlePath, 'videos')).createSync(recursive: true);
    }

    if (FileSystemEntity.typeSync(p.join(circlePath, 'temp')) ==
        FileSystemEntityType.notFound) {
      //Also create the images directory
      Directory(p.join(circlePath, 'temp')).createSync(recursive: true);
    }

    return circlePath;
  }

  static Future returnUserDirectory(String? userid) async {
    String retPath;

    try {
      retPath = p.join(
        await globalState.getAppPath(),
        'users',
        userid,
      );

      return retPath;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.returnUserDirectory: $err");
    }
  }

  static Future<String> returnCirclesDirectory(
      String? userid, String? circleid) async {
    String retPath;

    try {
      retPath = p.join(
        await globalState.getAppPath(),
        'users',
        userid,
        'circles',
        circleid,
      );

      return retPath;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.returnCirclesDirectory: $err");
      rethrow;
    }
  }

  /*
  static Future<bool> avatarExists(String? userid, Avatar? avatar) async {
    bool retValue = false;

    try {

      if (avatar == null || userid == null) return retValue;


      String avatarPath = p.join(
          documentsDirectory.path, 'users', userid, avatar.name);

      if (FileSystemEntity.typeSync(avatarPath) !=
          FileSystemEntityType.notFound) {
        retValue = true;
      }
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint("FileSystem.avatarExists: $err");
    }

    return retValue;
  }

   */

  static bool avatarExistsSync(String? userid, Avatar? avatar) {
    bool retValue = false;

    // debugPrint('userid $userid : avatar $avatar');

    if (avatar == null || userid == null) return retValue;

    String avatarPath =
        p.join(globalState.getAppPathSync(), 'users', userid, avatar.name);

    if (fileExists(avatarPath)) {
      retValue = false;

      File file = File(avatarPath);
      var length = file.lengthSync();

      if (length == avatar.size) retValue = true;
    }

    return retValue;
  }

  static Future<String?> getMaskImagePath() async {
    try {
      String imagePath =
          p.join(await globalState.getAppPath(), 'temp_images', 'mask.png');

      File file = File(imagePath);

      if (file.existsSync()) {
        return imagePath;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('FileSystemService:getMaskImagePath $error');
    }

    return null;
  }

  static Future<bool> deleteDiscoverableHostedFurnaceImage(
      HostedFurnaceImage img) async {
    bool retValue = false;

    try {
      String imagePath =
          p.join(await globalState.getAppPath(), 'network_images', img.name);

      File file = File(imagePath);

      if (file.existsSync()) await file.delete(recursive: false);

      retValue = true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('FileSystemService:deleteHostedFurnaceImage $error');
    }

    return retValue;
  }

  static String returnDiscoverableFurnaceImagePathSync(HostedFurnaceImage img) {
    String retValue = p.join(globalState.getAppPathSync(), 'network_images');

    if (FileSystemEntity.typeSync(retValue) == FileSystemEntityType.notFound) {
      Directory(retValue).createSync(recursive: true);
    }

    retValue = p.join(retValue, img.name);

    return retValue;
  }

  static bool discoverableFurnaceImageExistsSync(HostedFurnaceImage? img) {
    bool retValue = false;

    if (img == null) return retValue;

    String imagePath =
        p.join(globalState.getAppPathSync(), 'network_images', img.name);

    if (fileExists(imagePath)) {
      retValue = false;

      File file = File(imagePath);
      var length = file.lengthSync();

      if (length == img.size) retValue = true;
    }

    return retValue;
  }

  static bool furnaceImageExistsSync(String? userid, HostedFurnaceImage? img) {
    bool retValue = false;

    if (img == null || userid == null) return retValue;

    String imagePath =
        p.join(globalState.getAppPathSync(), 'users', userid, img.name);

    if (fileExists(imagePath)) {
      retValue = false;

      File file = File(imagePath);
      var length = file.lengthSync();

      if (length == img.size) retValue = true;
    }

    return retValue;
  }

  static String returnFurnaceImagePathSync(
      String userid, HostedFurnaceImage img) {
    String retValue = p.join(globalState.getAppPathSync(), 'users', userid);

    if (FileSystemEntity.typeSync(retValue) == FileSystemEntityType.notFound) {
      Directory(retValue).createSync(recursive: true);
    }

    retValue = p.join(retValue, img.name);

    return retValue;
  }

  static String? returnAnyFurnaceImagePath(String userid) {
    ///UserFurnace userFurnace
    String? retValue;

    //find correct user folder, each folder is the user's info for each network
    String userPath = p.join(globalState.getAppPathSync(), 'users',
        userid); //userFurnace.userid, //globalState.user.id

    Directory userDirectory = Directory(userPath);

    if (!userDirectory.existsSync()) {
      userDirectory.create();
    }

    List contents = userDirectory.listSync();

    //loops through stuff under user folder (circle folder, avatar image, etc)
    for (var f in contents) {
      if (f is File) {
        if (f.path.contains('furnaceImage')) {
          retValue = f.path;
        }
      }
    }

    return retValue;

    //return furnaceDirectory.path;
    //String id = Uuid().v4(); put this in hosted furnace bloc
  }

  static Future<bool> deleteHostedFurnaceImage(
      String userid, HostedFurnaceImage img) async {
    bool retValue = false;

    try {
      String imagePath =
          p.join(await globalState.getAppPath(), 'users', userid, img.name);

      File file = File(imagePath);

      if (file.existsSync()) await file.delete(recursive: false);

      retValue = true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('FileSystemService:deleteHostedFurnaceImage $error');
    }

    return retValue;
  }

  static String? returnDiscoverableNetworkImagePath(HostedFurnaceImage img) {
    String? retValue;

    String folderPath = p.join(globalState.getAppPathSync(), 'network_images');

    Directory networkDirectory = Directory(folderPath);

    if (!networkDirectory.existsSync()) {
      networkDirectory.create();
    }

    while (!networkDirectory.existsSync()) {
      ///wait
    }

    List contents = networkDirectory.listSync();

    for (var f in contents) {
      if (f is File) {
        if (f.path.contains(img.name) && f.path.endsWith('enc') == false) {
          retValue = f.path;
        }
      }
    }

    return retValue;
  }

  static String? returnAnyUserAvatarPath(String? userid, {Avatar? avatar}) {
    String? retValue;

    if (avatar != null) {
      ///try finding it by name
      retValue = returnAvatarPathSync(userid!, avatar);

      if (File(retValue).existsSync()) return retValue;
    }

    String userPath = p.join(globalState.getAppPathSync(), 'users',
        userid); //, avatar + '_avatar.jpg');

    Directory userDirectory = Directory(userPath);

    if (!userDirectory.existsSync()) return null;

    List contents = userDirectory.listSync();

    for (var f in contents) {
      if (f is File) {
        if (f.path.contains('avatar')) {
          retValue = f.path;
        }
      }
    }

    return retValue;
  }

/*
  static Future<String> returnAvatarPath(String userid, String avatar) async {
    String retValue =
    join(globalState.appPath, 'users', userid);



    if (FileSystemEntity.typeSync(retValue) !=
        FileSystemEntityType.notFound) {
      Directory(retValue).createSync(recursive: true);

    }

    retValue = join (retValue, avatar + '_avatar.jpg');


    return retValue;
  }
*/

  static String returnAvatarPathSync(String userid, Avatar avatar) {
    String retValue = p.join(globalState.getAppPathSync(), 'users', userid);

    if (FileSystemEntity.typeSync(retValue) == FileSystemEntityType.notFound) {
      Directory(retValue).createSync(recursive: true);
    }

    retValue = p.join(retValue, avatar.name);

    return retValue;
  }

  static Future<bool> deleteAvatar(String userid, Avatar avatar) async {
    bool retValue = false;

    try {
      String avatarPath =
          p.join(await globalState.getAppPath(), 'users', userid, avatar.name);

      File file = File(avatarPath);

      if (file.existsSync()) await file.delete(recursive: false);

      retValue = true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('FileSystemService:deleteAvatar $error');
    }

    return retValue;
  }

  static deleteAnyUsersAvatar(String? userid) async {
    String userPath = p.join(await globalState.getAppPath(), 'users',
        userid); //, avatar + '_avatar.jpg');

    Directory userDirectory = Directory(userPath);

    if (!userDirectory.existsSync()) return null;

    List contents = userDirectory.listSync();

    for (var f in contents) {
      if (f is File) {
        if (f.path.contains('avatar')) {
          await f.delete(recursive: false);
        }
      }
    }
  }

  static Future<bool> deleteCircleCacheDirectly(String circlePath) async {
    bool retValue = false;

    try {
      File file = File(circlePath);
      await file.delete(recursive: true);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleCache: $err");
    }

    return retValue;
  }

  static Future<bool> deleteCircleCache(String circlePath) async {
    bool retValue = false;

    try {
      File file = File(circlePath);

      if (PremiumFeatureCheck.wipeFileOn()) {
        Directory directory = Directory(circlePath);

        List<String> paths = [];

        directory.list(recursive: false).forEach((f) async {
          if (file.statSync().type == FileSystemEntityType.file)
            paths.add(file.path);
        });

        await wipeFile(paths);
      } else
        await file.delete(recursive: true);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCircleCache: $err");
    }

    return retValue;
  }

  static Future<int> databaseSize() async {
    try {
      String path = p.join(
        await globalState.getAppPath(),
        'ironcircles.db',
      );

      File file = File(path);

      return file.lengthSync();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCache: $err");

      return -1;
    }
  }

  static Future<bool> deleteCache() async {
    bool retValue = false;

    try {
      cleanUpSystemCache();

      String path = p.join(
        await globalState.getAppPath(),
        'users',
      );
      File file = File(path);
      await file.delete(recursive: true);

      retValue = true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileSystem.deleteCache: $err");
    }

    return retValue;
  }

  /*static String returnCircleImagesDirectory(String circlePath) {
    return p.join(circlePath, 'images');
  }*/

  static String returnCircleTempDirectory(String circlePath) {
    return p.join(circlePath, 'temp');
  }
  /*
  static Future <String> makeCircleImagePath(String user, String circle) async {

    String circlePath =
    join(documentsDirectory.path, 'users/$user/circles/$circle/images/');

    debugPrint(FileSystemEntity.typeSync(circlePath));

    if (FileSystemEntity.typeSync(circlePath) ==
        FileSystemEntityType.notFound) {
      Directory(circlePath).createSync(recursive: true);
    }
    return circlePath;
  }*/

  static bool fileExists(String? path) {
    bool retValue = false;

    // debugPrint (path);
    //test the file
    if (path != null) {
      if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
        //FileSystemEntityType.
        //FileSystemEntity.

        retValue = true;
      }
    }

    return retValue;
  }

  static String returnCircleBackgroundPath(String circlePath, String image) {
    String pathBuilder = p.join(
      circlePath,
      image,
    );

    return pathBuilder;
  }

  static Future<String> returnTempPath() async {
    String tempPath = p.join(await globalState.getAppPath(), 'temp');

    if (FileSystemEntity.typeSync(tempPath) == FileSystemEntityType.notFound) {
      Directory(tempPath).createSync(recursive: true);
    } // else {
    return tempPath;
    //}
  }

  static Future<String> returnTempPathAndImageFile() async {
    String path = p.join(await returnTempPath(), '${const Uuid().v4()}.jpg');
    debugPrint(path);
    return path;
    //}
  }

  static Future<String> returnTempPathAndFile({String extension = ""}) async {
    if (extension.isEmpty) extension = 'dft';

    String path =
        p.join(await returnTempPath(), '${const Uuid().v4()}.$extension');
    debugPrint(path);
    return path;
    //}
  }

  static Future<String> returnTempPathAndFileKeepFilename(String source) async {
    String ext = getExtension(source);

    String path = p.join(await returnTempPath(), '${const Uuid().v4()}.$ext');
    return path;
    //}
  }

  static String returnCircleBackgroundNewPath(
      String circlePath, String circleID) {
    String pathBuilder = p.join(
      //circlePath, image,
      circlePath, '$circleID.jpg',
    );

    return pathBuilder;
  }

  static String returnUserCircleBackgroundPath(
      String circlePath, String image) {
    String pathBuilder = p.join(
      circlePath,
      image,
    );

    return pathBuilder;
  }

  static String returnUserCircleBackgroundNewPath(String circlePath) {
    String pathBuilder = p.join(
      circlePath,
      '${const Uuid().v4()}.jpg',
    );

    return pathBuilder;
  }

  /*
  static bool isCircleBackgroundCached(String path, String image) {
    return fileExists(p.join(path, image + '.jpg'));
  }

   */

  static bool isUserCircleBackgroundCached(String path, String image) {
    return fileExists(p.join(path, image));
  }

  static String getFilename(String? path) {
    if (path != null) {
      String? retValue;

      // if (Platform.isWindows) {
      //   retValue = path.split("\\").last;
      // } else {
      //   retValue = path.split("/").last;
      // }

      debugPrint("getFilename: $path");
      retValue = path.split(Platform.pathSeparator).last;
      debugPrint("getFilename retValue: $retValue");

      return retValue;
    }

    throw ("FileSystemService.getExtension: path is null");
  }

  static String getExtension(String path) {
    try {
      //if (path == null) throw ("FileSystemService.getExtension: path is null");
      String retValue = p.extension(path).split('?').first;

      retValue = retValue.replaceAll('.', '');

      debugPrint(retValue);
      return retValue;
    } catch (err) {
      debugPrint('FileSystemService.getExtension: $err');
      rethrow;
    }
  }

  static safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('FileSystemService.safeDelete: $err');
    }
  }

  static bool isStringVideo(String url) {
    try {
      String extension = url.split('.').last.toUpperCase();

      if (extension == 'FMP4' ||
          extension == 'WEBM' ||
          extension == 'MP4' ||
          extension == 'M4P' ||
          extension == 'M4V' ||
          extension == 'M4A' ||
          extension == 'MP3' ||
          extension == 'OGG' ||
          extension == 'OGV' ||
          extension == 'GIFV' ||
          extension == 'WAV' ||
          extension == 'MPG' ||
          extension == 'MP2' ||
          extension == 'MP3' ||
          extension == 'MPEG' ||
          extension == 'MPV' ||
          extension == 'MPE' ||
          extension == 'M2V' ||
          extension == 'FLV' ||
          extension == 'ADTS' ||
          extension == 'AMR' ||
          extension == 'RM' ||
          extension == 'AMV' ||
          extension == 'WMV' ||
          extension == 'VOB' ||
          extension == 'MKV' ||
          extension == 'MNG' ||
          extension == 'AVI' ||
          extension == 'MTS' ||
          extension == 'M2TS' ||
          extension == 'TS' ||
          extension == 'MOV' ||
          extension == 'QT' ||
          extension == 'RM' ||
          extension == 'AMV' ||
          extension == '3GP' ||
          extension == '3G2') return true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return false;
  }

  static bool isStringImage(String url) {
    try {
      String extension = url.split('.').last.toUpperCase();

      if (extension == 'JPG' ||
          extension == 'JPEG' ||
          extension == 'MK4' ||
          extension == 'TTML' ||
          extension == 'BMP' ||
          extension == 'GIF' ||
          extension == 'PNG' ||
          extension == 'PNG') return true;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return false;
  }

  static bool isFile(String url) {
    try {
      if (url.startsWith("file:///")) {
        ///also check the extension

        if (isStringImage(url) || isStringVideo(url)) {
          return true;
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }

    return false;
  }

  static Future<DirectoryAndFile> cacheJson(Map map) async {
    try {
      DirectoryAndFile directoryAndFile =
          DirectoryAndFile('json', '${const Uuid().v4()}.json');

      String jsonFolderPath =
          p.join(globalState.getAppPathSync(), directoryAndFile.directory);

      if (FileSystemEntity.typeSync(jsonFolderPath) ==
          FileSystemEntityType.notFound) {
        //Also create the images directory
        Directory(jsonFolderPath).createSync(recursive: true);
      }

      File file = File(directoryAndFile.path);

      ///save the file
      await file.writeAsString(jsonEncode(map));

      return directoryAndFile;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("FileCacheService.cacheFile: $err");
      rethrow;
    }
  }
}

class DirectoryAndFile {
  String directory;
  String fileName;
  late String path;

  DirectoryAndFile(this.directory, this.fileName) {
    path = p.join(globalState.getAppPathSync(), 'json', fileName);
  }
}
