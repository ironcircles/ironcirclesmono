import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/user.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class LogDetailService {
  static final BlobGenericService _blobGenericService = BlobGenericService();
  static final BlobUrlsService _blobUrlsService = BlobUrlsService();

  static Future<void> _progressCallback(
      UserFurnace userFurnace,
      String fileName,
      String key,
      String location,
      bool upload,
      int progress,
      GlobalEventBloc? globalEventBloc) async {
    if (upload) {
      if (progress == -1) {
        return;
      } else if (progress == 100) {
        ///save the logdetail
        await _updateLogDetailObject(userFurnace, File(key), location);

        if (globalEventBloc != null) {
          globalEventBloc.broadcastProgress(progress.toDouble());
        }

        FileSystemService.safeDelete(File(key));
      } else {
        if (globalEventBloc != null) {
          globalEventBloc.broadcastProgress(progress.toDouble());
        }

      }
    }
  }

  static sendDetailedLog(UserFurnace userFurnace, User user,
      GlobalEventBloc globalEventBloc) async {
    try {
      //if (user.joinBeta == false) return;

      String path = p.join(await globalState.getAppPath(),
          'backup-${const Uuid().v4()}.dat');

      File backup = File(path);

      if (backup.existsSync()) {
        await FileSystemService.safeDelete(backup);
      }
      File data = File(p.join(
          await globalState.getAppPath(), 'ironcircles.db'));

      data.copy(path);

      _uploadDetailedLog(userFurnace, backup, globalEventBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  static Future<bool> _uploadDetailedLog(UserFurnace userFurnace, File logDetail,
      GlobalEventBloc globalEventBloc) async {
    try {
      String url = userFurnace.url! + Urls.LOGS_DETAIL;

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(userFurnace,
          BlobType.LOG_DETAIL, userFurnace.userid!, logDetail.path);

      url = urls.fileNameUrl;

      await _blobGenericService.put(
          userFurnace, url, logDetail.path, urls.location, logDetail,
          progressCallback: _progressCallback,
          globalEventBloc: globalEventBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("LogDetailService.uploadDetailedLog $err");
      rethrow;
    }

    return false;
  }

  static Future<bool> _updateLogDetailObject(
      UserFurnace userFurnace, File logDetail, String location) async {
    try {
      String url = userFurnace.url! + Urls.LOGS_DETAIL;
      debugPrint(url);

      SecureStorageService secureStorageService = SecureStorageService();
      String dbKey = await secureStorageService.readKey(kDebugMode && globalState.isDesktop() ? KeyType.DB_SECRET_KEY_DEBUG : KeyType.DB_SECRET_KEY);

      Map map = {
        'size': logDetail.lengthSync(),
        'location': location,
        'blob': FileSystemService.getFilename(logDetail.path),
        'dbKey': dbKey,
        'backupKey': globalState.userSetting.backupKey,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint(
            'LogDetailService._updateLogDetailObject failed: ${response.statusCode}');
        //debugPrint(response.data);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("LogDetailService._updateLogDetailObject: $err");
      rethrow;
    }

    return false;
  }
}
