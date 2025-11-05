import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:path/path.dart';

class AvatarService {
  static final BlobGenericService _blobGenericService = BlobGenericService();
  static final BlobUrlsService _blobUrlsService = BlobUrlsService();

  Future<void> _progressCallback(
    UserFurnace userFurnace,
    String fileName,
    String key,
    String location,
    bool upload,
    int progress,
  ) async {
    if (upload) {
      if (progress == -1) {
        //_globalEventBloc.removeOnError(circleObject);

        return;
      } else if (progress == 100) {
        //save the avatar
        await _updateAvatarObject(userFurnace, File(key), location);
        //_updateKeyChainBackup(userFurnace, keychain, lastKeychainBackup);
      }
    }
  }

  Future<void> validateCurrentAvatars(UserFurnace userFurnace,
      UserCircleCollection userCircleCollection) async {
    for (UserCircle userCircle in userCircleCollection.userCircles) {
      if (userCircle.user!.avatar != null) {
        if (FileSystemService.avatarExistsSync(
                userCircle.user!.id, userCircle.user!.avatar!) ==
            false) {
          imageCache.clear();
          PaintingBinding.instance.imageCache.clear();
          downloadAvatar(userFurnace, userCircle.user!);
        }
      }
    }
  }

  Future<void> validateCurrentAvatarsByUser(
      UserFurnace userFurnace, UserCollection members) async {
    for (User user in members.users) {
      if (user.avatar != null) {
        if (FileSystemService.avatarExistsSync(user.id, user.avatar!) ==
            false) {
          imageCache.clear();
          PaintingBinding.instance.imageCache.clear();
          downloadAvatar(userFurnace, user);
        }
      }
    }
  }

  Future<bool> downloadAvatar(UserFurnace userFurnace, User user) async {
    try {
      if (user.avatar == null) return false;

      //does the file already exist?
      if (FileSystemService.avatarExistsSync(user.id, user.avatar)) {
        return false;
      }

      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.AVATAR, user.avatar!.name);

      String imagePath =
          FileSystemService.returnAvatarPathSync(user.id!, user.avatar!);

      await _blobGenericService.get(userFurnace, user.avatar!.location,
          blobUrl.fileNameUrl, imagePath, userFurnace.userid!,
          progressCallback: _progressCallback);

      await FileSystemService.deleteAvatar(user.id!, user.avatar!);

      File file = File('${imagePath}enc');

      if (file.existsSync()) {
        await file.rename(imagePath);

        userFurnace.avatar = user.avatar;
        await TableUserFurnace.upsert(userFurnace);
      } else
        debugPrint('avatar file not found');

      return true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("AvatarService.downloadAvatar: $err");
    }

    return false;
  }

  Future<String> updateAvatarCache(UserFurnace userFurnace, File source) async {
    try {
      ///remove existing avatars
      await FileSystemService.deleteAnyUsersAvatar(userFurnace.userid);

      //Compress to a temporary file
      String usersPath =
          await (FileSystemService.returnUserDirectory(userFurnace.userid));
      //var uuid = Uuid();

      String filePath = join(usersPath, '${userFurnace.userid!}_avatar.jpg');

      await ImageCacheService.compressImage(source, filePath, 20);

      return filePath;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("AvatarService.updateAvatar $err");
      rethrow;
    }
  }

  Future<bool> updateAvatar(UserFurnace userFurnace, File source,
      {bool delete = true}) async {
    try {
      String filePath = "";

      if (delete) {
        filePath = await updateAvatarCache(userFurnace, source);
      } else {
        String usersPath =
            await (FileSystemService.returnUserDirectory(userFurnace.userid));
        filePath = join(usersPath, '${userFurnace.userid!}_avatar.jpg');
      }

      String url = ''; //userFurnace.url! + Urls.AVATAR;

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(
          userFurnace, BlobType.AVATAR, userFurnace.userid!, filePath);

      if (urls.location == BlobLocation.S3 ||
          urls.location == BlobLocation.PRIVATE_S3 ||
          urls.location == BlobLocation.PRIVATE_WASABI) {
        url = urls.fileNameUrl;
      }

      userFurnace.avatar = Avatar(name: urls.fileName, location: urls.location);
      await TableUserFurnace.upsert(userFurnace);

      await _blobGenericService.put(
          userFurnace, url, filePath, urls.location, File(filePath),
          progressCallback: _progressCallback);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("AvatarService.updateAvatar $err");
      rethrow;

      //return false;
    }

    return false;
  }

/*
  Future<void> updateAvatar2(UserFurnace userFurnace, File image) async {
    //find out if the avatar exists
    bool exists = false;

    if (userFurnace.avatar != null)
      exists = await FileSystemService.avatarExists(
          userFurnace.userid, userFurnace.avatar!);

    await _updateAvatar(userFurnace, image, exists);
  }

 */

  Future<bool> _updateAvatarObject(
      UserFurnace userFurnace, File image, String location) async {
    try {
      String url = userFurnace.url! + Urls.AVATAR;

      debugPrint(url);

      Map map = {
        'size': image.lengthSync(),
        'location': location,
        'name': FileSystemService.getFilename(image.path),
      };

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

        if (jsonResponse.containsKey('exists')) {
          if (jsonResponse['exists'] == true) {
            await FileSystemService.deleteAvatar(
                userFurnace.userid!, userFurnace.avatar!);
          }
        }

        //imageCache.clear();

        var oldAvatar = userFurnace.avatar;

        userFurnace.avatar = Avatar.fromJson(jsonResponse["avatar"]);

        if (userFurnace.authServer!) {
          globalState.user.avatar = userFurnace.avatar;
          globalState.userFurnace!.avatar = userFurnace.avatar;
        }

        if (userFurnace.pk != null) TableUserFurnace.upsert(userFurnace);

        List<UserFurnace> linkedNetworks =
            await TableUserFurnace.readLinkedForUser(userFurnace.userid!);

        for (UserFurnace linkedNetwork in linkedNetworks) {
          if (linkedNetwork.avatar != null && oldAvatar != null) {
            if (linkedNetwork.avatar!.name != oldAvatar.name) continue;
          }

          linkedNetwork.avatar = userFurnace.avatar;

          await FileSystemService.deleteAvatar(
              linkedNetwork.userid!, linkedNetwork.avatar!);

          String usersPath = await (FileSystemService.returnUserDirectory(
              linkedNetwork.userid));
          //var uuid = Uuid();

          String filePath =
              join(usersPath, '${linkedNetwork.userid!}_avatar.jpg');

          image.copy(filePath);

          await TableUserFurnace.upsert(linkedNetwork);
        }

        imageCache.clear();

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
      debugPrint("AvatarService._updateAvatar: $err");
      throw (err);
    }

    return false;
  }

  Future<List<UserCircle>?> getMembershipList(
      UserCircleCache userCircleCache, UserFurnace userFurnace) async {
    try {
      String url =
          userFurnace.url! + Urls.CIRCLEMEMBERS_GET;
      debugPrint(url);

      Map map = {
        'circleID': userCircleCache.circle!,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          }, body: json.encode(map)
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        UserCircleCollection userCircleCollection =
            UserCircleCollection.fromJSON(jsonResponse, "usercircles");

        return userCircleCollection.userCircles;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(err.toString());
    }

    return null;
  }
}
