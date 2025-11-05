import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_usercircleenvelope.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:path/path.dart';

class CircleBackgroundService {
  static final BlobGenericService _blobGenericService = BlobGenericService();
  static final BlobUrlsService _blobUrlsService = BlobUrlsService();

  Future<void> _progressCallback(UserFurnace userFurnace, String fileName,
      String key, String location, bool upload, int progress) async {
    if (upload) {
      if (progress == -1) {
        //_globalEventBloc.removeOnError(circleObject);

        return;
      } else if (progress == 100) {
        //save the avatar
        //_saveCircleBackground(userFurnace, File(key), location);
        //_updateKeyChainBackup(userFurnace, keychain, lastKeychainBackup);
      }
    }
  }

  bool _alreadyCached(String path) {
    bool retValue = false;

    // String fullPath = join(path, background + ".jpg");

    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      retValue = true;
    }

    return retValue;
  }

  Future<String> makeCirclePath(String? user, String? circle) async {
    return await _makeCirclePath(user, circle);
  }

  Future<String> _makeCirclePath(String? user, String? circle) async {
    String circlePath =
        join(await globalState.getAppPath(), 'users', user, 'circles', circle);

    //debugPrint(FileSystemEntity.typeSync(circlePath));

    if (FileSystemEntity.typeSync(circlePath) ==
        FileSystemEntityType.notFound) {
      Directory(circlePath).createSync(recursive: true);

      /*
       .then((Directory circleDirectory) {
        return circlePath;
      }).catchError((err) {
        debugPrint('$err');
      });
      */
    } // else {
    return circlePath;
    //}
  }

  Future<bool> _backgroundExists(UserCircleCache userCircleCache) async {
    bool retValue = false;

    String pathBuilder = join(await globalState.getAppPath(), 'users',
        userCircleCache.user, 'circles', userCircleCache.circle);

    // 'users/${userCircleCache.user}/circles/${userCircleCache.circle}/');

    if (userCircleCache.background != null) {
      pathBuilder = join(pathBuilder, userCircleCache.background!);
    } else if (userCircleCache.masterBackground != null) {
      pathBuilder = join(pathBuilder, userCircleCache.masterBackground!);
    }

    if (FileSystemEntity.typeSync(pathBuilder) !=
        FileSystemEntityType.notFound) {
      retValue = true;
    }

    return retValue;
  }

  Future<bool> _masterBackgroundExists(UserCircleCache userCircleCache) async {
    bool retValue = false;

    String pathBuilder = join(await globalState.getAppPath(), 'users',
        userCircleCache.user, 'circles', userCircleCache.circle);
        //'users/${userCircleCache.user}/circles/${userCircleCache.circle}/');

    if (userCircleCache.masterBackground != null) {
      pathBuilder = join(pathBuilder, userCircleCache.masterBackground!);
    }

    if (FileSystemEntity.typeSync(pathBuilder) !=
        FileSystemEntityType.notFound) {
      retValue = true;
    }

    return retValue;
  }

  _saveCircleBackground(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      File masterBackground,
      String location) async {
    try {
      String url = userFurnace.url! + Urls.CIRCLEBACKGROUND;

      debugPrint(url);

      Map map = {
        'backgroundSize': masterBackground.lengthSync(),
        'backgroundLocation': location,
        'background': FileSystemService.getFilename(masterBackground.path),
        'circleid': userCircleCache.circle!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        userCircleCache.masterBackground =
            FileSystemService.getFilename(masterBackground.path);
        userCircleCache.masterBackgroundSize = masterBackground.lengthSync();
        await TableUserCircleCache.upsert(userCircleCache);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint(
            'CircleBackgroundService.downloadCircleBackground failed: ${response.statusCode}');
        //debugPrint(response.data);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBackgroundService.saveCircleBackground: $err');
    }
  }

  Future uploadCircleBackground(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      File compressed,
      DecryptArguments decryptArgs) async {
    try {
      //Dio dio = Dio();

      String circlePath =
          await _makeCirclePath(userFurnace.userid, userCircleCache.circle);

      userCircleCache.circlePath ??= circlePath;

      String url = ''; //userFurnace.url! + Urls.CIRCLEBACKGROUND;

      debugPrint(url);

      File background = await compressed.copy(
          FileSystemService.returnCircleBackgroundNewPath(
              circlePath, userCircleCache.usercircle!));

      File masterBackground = await compressed.copy(
          FileSystemService.returnCircleBackgroundNewPath(
              circlePath, userCircleCache.circle!));

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(userFurnace,
          BlobType.BACKGROUND, userFurnace.userid!, masterBackground.path);

      if (urls.location == BlobLocation.S3 ||
          urls.location == BlobLocation.PRIVATE_S3 ||
          urls.location == BlobLocation.PRIVATE_WASABI) {
        url = urls.fileNameUrl;
      }

      await _blobGenericService.put(
          userFurnace,
          url,
          FileSystemService.getFilename(masterBackground.path),
          urls.location,
          decryptArgs.encrypted,
          progressCallback: _progressCallback);

      await _saveCircleBackground(
          userFurnace, userCircleCache, masterBackground, urls.location);

      await uploadUserCircleBackground(userFurnace, userCircleCache, background,
          decryptArgs.encrypted, decryptArgs, null);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('uploadUserCircleBackground: $err');
    }
  }

  Future uploadUserCircleBackground(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      File background,
      File encrypted,
      DecryptArguments args,
      String? oldBackground) async {
    try {
      // String circlePath =
      //  await _makeCirclePath(userFurnace.userid, userCircleCache.circle);

      // if (userCircleCache.circlePath == null)
      //  userCircleCache.circlePath = circlePath;

      String url = '';

      debugPrint(url);

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(userFurnace,
          BlobType.BACKGROUND, userFurnace.userid!, background.path);

      if (urls.location == BlobLocation.S3 ||
          urls.location == BlobLocation.PRIVATE_S3 ||
          urls.location == BlobLocation.PRIVATE_WASABI) {
        url = urls.fileNameUrl;
      }

      await _blobGenericService.put(
          userFurnace,
          url,
          FileSystemService.getFilename(background.path),
          urls.location,
          encrypted,
          progressCallback: _progressCallback);

      FileSystemService.safeDelete(encrypted);

      await _saveUserCircleBackground(userFurnace, userCircleCache, background,
          urls.location, args, oldBackground);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('uploadUserCircleBackground: $err');
    }
  }

  _saveUserCircleBackground(
      UserFurnace userFurnace,
      UserCircleCache userCircleCache,
      File background,
      String location,
      DecryptArguments args,
      String? oldBackground) async {
    try {
      String url = userFurnace.url! + Urls.USERCIRCLEBACKGROUND;

      debugPrint(url);

      UserCircleEnvelope userCircleEnvelope = await TableUserCircleEnvelope.get(
          userCircleCache.usercircle!, userCircleCache.user!);

      userCircleEnvelope.contents.userCircleBackgroundSignature = args.mac;
      userCircleEnvelope.contents.userCircleBackgroundCrank = args.nonce;
      userCircleEnvelope.contents.userCircleBackgroundKey =
          base64UrlEncode(args.key!);

      await ForwardSecrecyUser.encryptUserObject(
          userFurnace.userid!, userCircleEnvelope.toJson());

      Map map = {
        'backgroundSize': background.lengthSync(),
        'backgroundLocation': location,
        'background': FileSystemService.getFilename(background.path),
        'circleid': userCircleCache.circle!,
        'oldBackground': oldBackground,
        //'ratchetIndex': ratchetIndex,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);

        //debugPrint (background.path);

        if (userCircleCache.background != null) {
          // debugPrint(FileSystemService.returnUserCircleBackgroundPath(
          //  userCircleCache.circlePath!, userCircleCache.background!));

          await deleteBlob(FileSystemService.returnUserCircleBackgroundPath(
              userCircleCache.circlePath!, userCircleCache.background!));
        }

        userCircleCache.background = FileSystemService.getFilename(
            background.path); //userCircleCache.usercircle! + ".jpg";
        userCircleCache.backgroundSize = background.lengthSync();
        userCircleCache.backgroundColor == null;
        await TableUserCircleCache.upsert(userCircleCache);

        //this could have taken a while, get the latest before saving
        UserCircleEnvelope userCircleEnvelope =
            await TableUserCircleEnvelope.get(
                userCircleCache.usercircle!, userCircleCache.user!);

        userCircleEnvelope.contents.userCircleBackgroundSignature = args.mac;
        userCircleEnvelope.contents.userCircleBackgroundCrank = args.nonce;
        userCircleEnvelope.contents.userCircleBackgroundKey =
            base64UrlEncode(args.key!);

        TableUserCircleEnvelope.upsert(userCircleEnvelope);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint(
            'CircleBackgroundService._saveUserCircleBackground failed: ${response.statusCode}');
        //debugPrint(response.data);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleBackgroundService._saveUserCircleBackground: $err');
    }
  }

  deleteBlob(String path) async {
    File remove = File(path);

    if (await remove.exists()) await remove.delete();
  }

  Future<String> downloadCircleBackground(
      UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      if (await _masterBackgroundExists(userCircleCache)) return '';

      //String? url = userFurnace.url;

      String circlePath =
          await _makeCirclePath(userFurnace.userid, userCircleCache.circle);

      /* if (userCircleCache.masterBackground != null && url != null) {
        url += Urls.CIRCLEBACKGROUND +
            userCircleCache.masterBackground! +
            "&" +
            userCircleCache.circle!;

        circlePath =
            join(circlePath, userCircleCache.masterBackground! + ".jpg");
      } else {
        return '';
      }

      */

      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.BACKGROUND, userCircleCache.masterBackground!);

      String filePath = FileSystemService.returnCircleBackgroundPath(
          circlePath, userCircleCache.masterBackground!);

      //TODO this needs to use the location stored with the UserCircle
      await _blobGenericService.get(
          userFurnace, 'S3', blobUrl.fileNameUrl, filePath, userFurnace.userid!,
          progressCallback: _progressCallback);

      //is this encrypted?
      UserCircleEnvelope userCircleEnvelope = await TableUserCircleEnvelope.get(
          userCircleCache.usercircle!, userCircleCache.user!);

      if (userCircleEnvelope.contents.circleBackgroundKey != null) {
        DecryptArguments args = DecryptArguments(
            encrypted: File('${filePath}enc'),
            nonce: userCircleEnvelope.contents.circleBackgroundCrank!,
            mac: userCircleEnvelope.contents.circleBackgroundSignature!,
            key: base64Url
                .decode(userCircleEnvelope.contents.circleBackgroundKey!));

        await EncryptBlob.decryptBlob(args);
      } else {
        //This is needed to support versions older than 27
        File file = File('${filePath}enc');
        if (file.existsSync()) file.rename(filePath);
      }

      PaintingBinding.instance.imageCache.clear();
      //debugPrint(url);

      return circlePath;
    } catch (e) {
      debugPrint('CircleBackgroundService.downloadCircleBackground: $e');
    }
    return '';
  }

  Future<String> downloadUserCircleBackground(
      UserFurnace userFurnace, UserCircleCache userCircleCache) async {
    try {
      if (await _backgroundExists(userCircleCache)) return '';

      String circlePath =
          await _makeCirclePath(userFurnace.userid, userCircleCache.circle);

      String filePath = FileSystemService.returnUserCircleBackgroundPath(
          circlePath, userCircleCache.background!);

      //debugPrint(url);

      //Already cached?
      if (_alreadyCached(filePath)) {
        debugPrint('already cached');
        return filePath;
      }

      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.BACKGROUND, userCircleCache.background!);

      //TODO this needs to use the location stored with the UserCircle
      await _blobGenericService.get(
          userFurnace, 'S3', blobUrl.fileNameUrl, filePath, userFurnace.userid!,
          progressCallback: _progressCallback);

      //is this encrypted?
      UserCircleEnvelope userCircleEnvelope = await TableUserCircleEnvelope.get(
          userCircleCache.usercircle!, userCircleCache.user!);

      if (userCircleEnvelope.contents.userCircleBackgroundKey != null) {
        DecryptArguments args = DecryptArguments(
            encrypted: File('${filePath}enc'),
            nonce: userCircleEnvelope.contents.userCircleBackgroundCrank!,
            mac: userCircleEnvelope.contents.userCircleBackgroundSignature!,
            key: base64Url
                .decode(userCircleEnvelope.contents.userCircleBackgroundKey!));

        await EncryptBlob.decryptBlob(args);
      } else {
        //This is needed to support versions older than 27
        File file = File('${filePath}enc');
        if (file.existsSync()) file.rename(filePath);
      }

      PaintingBinding.instance.imageCache.clear();

      return filePath;
    } catch (e) {
      debugPrint('CircleBackgroundService.downloadUserCircleBackground: $e');

      rethrow;
    }
  }
}
