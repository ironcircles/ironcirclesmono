import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/webmedia_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:ironcirclesapp/utils/mediascanner.dart';
//import 'package:media_scanner_scan_file/media_scanner_scan_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DialogDownload {
  static Future<void> showDialogOnly(
    BuildContext context,
    String title,
  ) async {
    return showDialog<void>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: Text(
            AppLocalizations.of(context)!.pleaseWait,
            style: TextStyle(color: globalState.theme.labelText),
          ),
        );
      },
    );
  }

  static Future<void> showAndDownloadFiles(
      BuildContext context, String title, List<File> files,
      {generateFileNames = false}) async {
    _downloadFiles(context, files, generateFileNames);

    // flutter defined function
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: Text(
            AppLocalizations.of(context)!.pleaseWait,
            style: TextStyle(color: globalState.theme.labelText),
          ),
        );
      },
    );
  }

  static Future<void> showAndDownloadCircleObjects(BuildContext context,
      String title, List<CircleObject> circleObjects) async {
    _downloadObjects(context, circleObjects);

    // flutter defined function
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          title: Center(
              child: Text(
            title,
            style: TextStyle(color: globalState.theme.bottomIcon),
          )),
          content: Text(
            AppLocalizations.of(context)!.pleaseWait,
            style: TextStyle(color: globalState.theme.labelText),
          ),
        );
      },
    );
  }

  static Future<void> showAndDownloadAlbumItems(
      BuildContext context,
      String title,
      List<AlbumItem> albumItems,
      CircleObject circleObject,
      UserCircleCache userCircleCache) async {
    _downloadAlbumItems(context, albumItems, circleObject, userCircleCache);

    // flutter defined function
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
              surfaceTintColor: Colors.transparent,
              backgroundColor: globalState.theme.dialogBackground,
              title: Center(
                  child: Text(title,
                      style: TextStyle(color: globalState.theme.bottomIcon))),
              content: Text(
                AppLocalizations.of(context)!.pleaseWait,
                style: TextStyle(color: globalState.theme.labelText),
              ));
        });
  }

  static _downloadObjects(
    BuildContext context,
    List<CircleObject> objects,
  ) async {
    try {
      Directory dir = Directory(FileSystemService.downloadPath);

      if (globalState.isDesktop()) {
        Directory? desktop = await getDownloadsDirectory();
        if (desktop != null) {
          if (Platform.isMacOS) {
            String path = desktop.path;
            List<String> splitPath = path.split("/");
            dir = Directory(p.join('/Users', splitPath[2], 'Downloads'));
          } else {
            dir = desktop;
          }
        }
      }

      for (var circleObject in objects) {
        File? existing;
        String destination = '';

        bool copied = false;

        try {
          if (circleObject.type == CircleObjectType.CIRCLEIMAGE &&
              circleObject.image != null) {
            destination = p.join(
                dir.path, '${SecureRandomGenerator.generateFileName()}.jpg');
            existing = File(ImageCacheService.returnFullImagePath(
                circleObject.userCircleCache!.circlePath!, circleObject));

            if (globalState.isDesktop()) {
              await EncryptBlob.decryptBlobToFile(
                  DecryptArguments(
                    encrypted: existing,
                    nonce: circleObject.image!.fullCrank!,
                    mac: circleObject.image!.fullSignature!,
                    key: circleObject.secretKey,
                  ),
                  destination);

              copied = true;
            }
          } else if (circleObject.type == CircleObjectType.CIRCLEGIF) {
            destination = p.join(
                dir.path, '${SecureRandomGenerator.generateFileName()}.gif');
            existing = File(await _cacheUrl(circleObject.gif!.giphy!));
          } else if (circleObject.type == CircleObjectType.CIRCLEVIDEO &&
              circleObject.video != null) {
            destination = p.join(dir.path,
                '${SecureRandomGenerator.generateFileName()}.${circleObject.video!.extension!}');
            existing = File(VideoCacheService.returnVideoPath(
                circleObject,
                circleObject.userCircleCache!.circlePath!,
                circleObject.video!.extension!));

            if (globalState.isDesktop() && circleObject.video!.streamable == false) {
              await EncryptBlob.decryptBlobToFile(
                  DecryptArguments(
                    encrypted: existing,
                    nonce: circleObject.video!.fullCrank!,
                    mac: circleObject.video!.fullSignature!,
                    key: circleObject.secretKey,
                  ),
                  destination);

              copied = true;
            }
          } else if (circleObject.type == CircleObjectType.CIRCLEFILE &&
              circleObject.file != null) {
            destination = p.join(dir.path, circleObject.file!.name);

            if (File(destination).existsSync()) {
              String path = destination.replaceAll(
                  '.${circleObject.file!.extension!}', '');

              for (var i = 1; i < 100; i++) {
                destination = p.join(dir.path,
                    '$path${i.toString()}.${circleObject.file!.extension!}');
                if (!File(destination).existsSync()) {
                  break;
                }
              }
            }

            existing = File(FileCacheService.returnFilePath(
                circleObject.userCircleCache!.circlePath!,
                '${circleObject.seed!}.${circleObject.file!.extension!}'));

            if (globalState.isDesktop()) {
              await EncryptBlob.decryptBlobToFile(
                  DecryptArguments(
                    encrypted: existing,
                    nonce: circleObject.file!.fileCrank!,
                    mac: circleObject.file!.fileSignature!,
                    key: circleObject.secretKey,
                  ),
                  destination);

              copied = true;
            }
          } else {
            //Navigator.of(context).pop();
            LogBloc.insertLog(
                'Tried to download CircleObject with no matching type: ${circleObject.type}',
                'DialogDownload');
          }

          if (copied == false && existing != null && destination.isNotEmpty) {
            await existing.copy(destination);

            if (Platform.isAndroid) {
              MediaScanner.scanFile(destination);

              ///TODO this throws a harmless error but works
              //await MediaScannerScanFile.scanFile(destination);
            }
          }
        } catch (error, trace) {
          debugPrint(error.toString());
          if (error.toString() !=
              "type '_Map<Object?, Object?>' is not a subtype of type 'FutureOr<Map<String, dynamic>>'") {
            LogBloc.insertError(error, trace);
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      // AndroidContentResolver.instance.notifyChange(uri: FileSystemService.downloadPath);

      Navigator.of(context).pop();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      Navigator.of(context).pop();
    }
  }

  static _downloadAlbumItems(
    BuildContext context,
    List<AlbumItem> albumItems,
    CircleObject circleObject,
    UserCircleCache userCircleCache,
  ) async {
    try {
      Directory dir = Directory(FileSystemService.downloadPath);

      for (AlbumItem item in albumItems) {
        File? existing;
        String destination = '';

        try {
          if (item.type == AlbumItemType.IMAGE) {
            destination = p.join(
                dir.path, '${SecureRandomGenerator.generateFileName()}.jpg');
            existing = File(ImageCacheService.returnExistingAlbumImagePath(
                userCircleCache.circlePath!,
                circleObject,
                item.image!.fullImage!));
          } else if (item.type == AlbumItemType.GIF) {
            destination = p.join(
                dir.path, '${SecureRandomGenerator.generateFileName()}.gif');
            existing = File(await _cacheUrl(item.gif!.giphy!));
          } else if (item.type == AlbumItemType.VIDEO) {
            destination = p.join(dir.path,
                '${SecureRandomGenerator.generateFileName()}.${item.video!.extension!}');
            existing = File(VideoCacheService.returnExistingAlbumVideoPath(
                userCircleCache.circlePath!, circleObject, item.video!.video!));
          } else {
            LogBloc.insertLog(
                'Tried to download AlbumItem with no matching type: ${item.type}',
                'DialogDownload');
          }

          if (existing != null && destination.isNotEmpty) {
            await existing.copy(destination);

            MediaScanner.scanFile(destination);
            ///TODO this throws a harmless error but works
            //await MediaScannerScanFile.scanFile(destination);
          }
        } catch (error, trace) {
          debugPrint(error.toString());
          if (error.toString() !=
              "type '_Map<Object?, Object?>' is not a subtype of type 'FutureOr<Map<String, dynamic>>'") {
            LogBloc.insertError(error, trace);
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 10000));

      Navigator.of(context).pop();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      Navigator.of(context).pop();
    }
  }

  static _downloadFiles(
      BuildContext context, List<File> files, bool generateFileNames) async {
    try {
      Directory dir = Directory(FileSystemService.downloadPath);

      for (var file in files) {
        String destination = '';

        try {
          if (generateFileNames) {
            destination = p.join(
                dir.path, '${SecureRandomGenerator.generateFileName()}.enc');
          } else {
            destination =
                p.join(dir.path, FileSystemService.getFilename(file.path));

            String extension = FileSystemService.getExtension(destination);

            if (File(destination).existsSync()) {
              String path = destination.replaceAll('.$extension', '');

              for (var i = 1; i < 100; i++) {
                destination =
                    p.join(dir.path, '$path${i.toString()}.$extension');
                if (!File(destination).existsSync()) {
                  break;
                }
              }
            }
          }

          await file.copy(destination);

          ///TODO this throws a harmless error but works
          await MediaScanner.scanFile(destination);
          //await MediaScannerScanFile.scanFile(destination);
        } catch (err) {
          debugPrint(err.toString());
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      // AndroidContentResolver.instance.notifyChange(uri: FileSystemService.downloadPath);

      Navigator.of(context).pop();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      Navigator.of(context).pop();
    }
  }

  static Future<String> _cacheUrl(String url) async {
    try {
      return await WebMediaBloc.getMedia(url);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);

      rethrow;
    }
  }
}
