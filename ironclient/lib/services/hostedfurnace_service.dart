import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedfurnaceimage.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/services/avatar_service.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/blob_service.dart';
import 'package:ironcirclesapp/services/bloburls_service.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_member.dart';
import 'package:ironcirclesapp/services/cache/table_membercircle.dart';
import 'package:ironcirclesapp/services/cache/table_memberdevice.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:path/path.dart';

class HostedFurnaceService {
  static final BlobGenericService _blobGenericService = BlobGenericService();
  static final BlobUrlsService _blobUrlsService = BlobUrlsService();
  late GlobalEventBloc _globalEventBloc;
  final BlobService _blobService = BlobService();
  AvatarService avatarService = AvatarService();

  HostedFurnaceService(GlobalEventBloc globalEventBloc) {
    _globalEventBloc = globalEventBloc;
  }

  Future<void> setStorage(
      UserFurnace userFurnace,
      String location,
      String accessKey,
      String secretKey,
      String region,
      String mediaBucket) async {
    String url = userFurnace.url! + Urls.HOSTEDFURNACE_SETSTORAGE;

    String hostedName = 'IronForge';
    String key = 'IronForge';

    if (userFurnace.type != NetworkType.FORGE) {
      hostedName = userFurnace.hostedName!;
      key = userFurnace.hostedAccessCode!;
    }

    Map map = {
      "hostedName": hostedName,
      "key": key,
      "location": location,
      "accessKey": accessKey,
      "secretKey": secretKey,
      "region": region,
      "mediaBucket": mediaBucket,
    };

    debugPrint(url);

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
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> _progressThumbnailCallback(
    HostedFurnaceImage img,
    HostedFurnace network,
    UserFurnace? userFurnace,
    String fileName,
    String key,
    String location,
    bool upload,
    int progress,
    Function failedCallback,
  ) async {
    try {
      if (progress == -1) {
        _globalEventBloc.removeImageOnError(img);
        return;
      }
      if (progress == 100) {
        img.thumbnailTransferState = BlobState.READY;
        _globalEventBloc.broadcastProgressNetworkImageIndicator(img);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'HostedFurnaceService._progressThumbnailCallback');
      //BlobService.safeCancel(cancelToken);
      if (userFurnace != null) {
        failedCallback(userFurnace, network);
      } else {
        failedCallback(network);
      }
    }
  }

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
        await _updateImageObject(userFurnace, File(key), location);
        //_updateKeyChainBackup(userFurnace, keychain, lastKeychainBackup);
      }
    } else {
      if (progress == 100) {
        ///remove from globalstate
        _globalEventBloc.removeGenericObject(userFurnace.hostedFurnaceImageId!);
      }
    }
  }

  Future<HostedFurnaceStorage> getStorage(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.HOSTEDFURNACE_GETSTORAGE;

    String hostedName = 'IronForge';
    String key = 'IronForge';

    if (userFurnace.type != NetworkType.FORGE) {
      hostedName = userFurnace.hostedName!;
      key = userFurnace.hostedAccessCode!;
    }

    Map map = {
      "hostedName": hostedName,
      "key": key,
    };

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

      HostedFurnaceStorage hostedFurnaceStorage =
          HostedFurnaceStorage.fromJson(jsonResponse["hostedFurnaceStorage"]);

      return hostedFurnaceStorage;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return HostedFurnaceStorage(location: '');
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> setRole(UserFurnace userFurnace, User user, int role) async {
    String url = userFurnace.url! + Urls.HOSTEDFURNACE_SETROLE;

    String hostedName = 'IronForge';
    String key = 'IronForge';

    if (userFurnace.type != NetworkType.FORGE) {
      hostedName = userFurnace.hostedName!;
      key = userFurnace.hostedAccessCode!;
    }

    Map map = {
      "hostedName": hostedName,
      "key": key,
      'memberID': user.id,
      'role': role
    };

    debugPrint(url);

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

      if (role == Role.OWNER) {
        if (userFurnace.role == Role.OWNER) {
          userFurnace.role = Role.ADMIN;
          TableUserFurnace.upsert(userFurnace);
        }
      }
      return;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> reportAvatar(
      UserFurnace userFurnace, Violation violation) async {
    String url;
    if (violation.hostedFurnace != null) {
      ///report network
      url = userFurnace.url! + Urls.HOSTEDFURNACE_REPORTNETWORK;
    } else {
      ///report user profile
      url = userFurnace.url! + Urls.HOSTEDFURNACE_REPORTPROFILE;
    }
    debugPrint(url);

    Map map = {
      "violation": violation,
    };

    int retries = 0;

    map = await EncryptAPITraffic.encrypt(map);

    while (retries <= RETRIES.MAX_MESSAGE_RETRIES) {
      try {
        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          // Map<String, dynamic> jsonResponse =
          // await EncryptAPITraffic.decryptJson(response.body);

          return;
        } else if (response.statusCode == 401) {
          await navService.logout(userFurnace);
          return;
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
            LogBloc.insertLog('${response.statusCode} : ${response.body}',
                'HostedFurnaceService.reportAvatar');
          }
        }
      } on SocketException catch (err, trace) {
        debugPrint('HostedFurnaceService.reportAvatar: ${err.toString()}');
        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          LogBloc.insertError(err, trace);
      } catch (err, trace) {
        debugPrint('HostedFurnaceService.reportAvatar: ${err.toString()}');
        if (retries == RETRIES.MAX_MESSAGE_RETRIES)
          LogBloc.insertError(err, trace);
      }

      if (retries == RETRIES.MAX_MESSAGE_RETRIES) {
        throw Exception('failed to report avatar');
      }

      await Future.delayed(const Duration(milliseconds: RETRIES.TIMEOUT));
      retries++;
    }
    return;
  }

  Future<bool> downloadImage(
      UserFurnace userFurnace, HostedFurnace network) async {
    try {
      if (network.hostedFurnaceImage == null) return false;

      ///does the file already exist?
      if (FileSystemService.furnaceImageExistsSync(
          userFurnace.userid, network.hostedFurnaceImage)) {
        await FileSystemService.deleteHostedFurnaceImage(
            network.id, network.hostedFurnaceImage!);
      }

      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.IMAGE, network.hostedFurnaceImage!.name);

      String imagePath = FileSystemService.returnFurnaceImagePathSync(
          userFurnace.userid!, network.hostedFurnaceImage!);

      await _blobGenericService.get(
          userFurnace,
          network.hostedFurnaceImage!.location,
          blobUrl.fileNameUrl,
          imagePath,
          userFurnace.userid!,
          progressCallback: _progressCallback);

      File file = File('${imagePath}enc');

      if (file.existsSync()) {
        await file.rename(imagePath);
      } else {
        debugPrint('image file not found');
      }

      imageCache.clear();
      PaintingBinding.instance.imageCache.clear();

      return true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("HostedFurnaceService.downloadImage: $err");
    }
    return false;
  }

  Future<bool> updateImage(UserFurnace userFurnace, File source) async {
    try {
      //Compress to a temporary file
      String usersPath =
          await (FileSystemService.returnUserDirectory(userFurnace.userid));

      String filePath =
          join(usersPath, '${userFurnace.userid!}_furnaceImage.jpg');

      //clean up the source
      await FileSystemService.safeDelete(File(filePath));

      //create a thumbnail
      await ImageCacheService.compressImage(source, filePath, 20);

      //clean up the source
      //FileSystemService.safeDelete(source);

      //String url = userFurnace.url! + Urls.HOSTEDFURNACE_IMAGE;

      BlobUrl urls = await _blobUrlsService.getUserUploadUrl(
          userFurnace, BlobType.IMAGE, userFurnace.userid!, filePath);

      // if (urls.location == BlobLocation.S3 ||
      //     urls.location == BlobLocation.PRIVATE_S3 ||
      //     urls.location == BlobLocation.PRIVATE_WASABI) {
      //   url = urls.fileNameUrl;
      // }

      bool update = await _blobGenericService.put(userFurnace, urls.fileNameUrl,
          filePath, urls.location, File(filePath),
          progressCallback: _progressCallback);
      return update;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("HostedFurnaceService.updateImage $err");
      rethrow;
    }
    return false;
  }

  Future<bool> _updateImageObject(
      UserFurnace userFurnace, File image, String location) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE_IMAGE;

      debugPrint(url);

      Map map = {
        'size': image.lengthSync(),
        'location': location,
        'name': FileSystemService.getFilename(image.path),
      };

      if (userFurnace.type != NetworkType.FORGE ||
          userFurnace.hostedName != null) {
        map['hostedName'] = userFurnace.hostedName;
        map['key'] = userFurnace.hostedAccessCode;
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

        userFurnace.hostedFurnaceImageId =
            jsonResponse["hostedFurnaceImage"]["_id"];
        TableUserFurnace.upsert(userFurnace);

        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
      } else {
        debugPrint(
            'HostedFurnaceService._updateImage failed: ${response.statusCode}');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("HostedFurnaceService._updateImage: $err");
      rethrow;
    }
    return false;
  }

  Future<void> downloadDiscoverableImageUnauthorized(
      HostedFurnace network, Function _failedThumbnailCallback) async {
    try {
      //does the file already exist?
      if (FileSystemService.discoverableFurnaceImageExistsSync(
          network.hostedFurnaceImage)) {
        return;
      }

      BlobUrl blobUrl =
          await _blobUrlsService.getUnauthorizedNetworkDownloadUrl(
              network, BlobType.IMAGE, network.hostedFurnaceImage!.name);

      String imagePath =
          FileSystemService.returnDiscoverableFurnaceImagePathSync(
              network.hostedFurnaceImage!);

      await _blobGenericService.getUnauthorizedImage(
          network,
          network.hostedFurnaceImage!.location,
          blobUrl.fileNameUrl,
          imagePath,
          network.hostedFurnaceImage!,
          progressCallback: _progressThumbnailCallback,
          failedCallback: _failedThumbnailCallback);

      File file = File('${imagePath}enc');

      if (file.existsSync()) {
        await file.rename(imagePath);
      } else {
        debugPrint('image file not found');
      }

      imageCache.clear();
      PaintingBinding.instance.imageCache.clear();

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          "HostedFurnaceService.downloadDiscoverableImageUnauthorized: $err");
    }
    return;
  }

  Future<void> downloadDiscoverableImage(UserFurnace userFurnace,
      HostedFurnace network, Function _failedThumbnailCallback) async {
    try {
      if (network.hostedFurnaceImage == null) return;

      //does the file already exist?
      if (FileSystemService.discoverableFurnaceImageExistsSync(
          network.hostedFurnaceImage)) {
        return;
      }

      BlobUrl blobUrl = await _blobUrlsService.getUserDownloadUrl(
          userFurnace, BlobType.IMAGE, network.hostedFurnaceImage!.name);

      String imagePath =
          FileSystemService.returnDiscoverableFurnaceImagePathSync(
              network.hostedFurnaceImage!);

      await _blobGenericService.getImage(
          userFurnace,
          network,
          network.hostedFurnaceImage!.location,
          blobUrl.fileNameUrl,
          imagePath,
          userFurnace.userid!,
          network.hostedFurnaceImage!,
          progressCallback: _progressThumbnailCallback,
          failedCallback: _failedThumbnailCallback);

      File file = File('${imagePath}enc');

      if (file.existsSync()) {
        await file.rename(imagePath);
      } else {
        debugPrint('image file not found');
      }

      imageCache.clear();
      PaintingBinding.instance.imageCache.clear();

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("HostedFurnaceService.downloadPublicImage: $err");
    }
    return;
  }

  Future<bool> updateParams(UserFurnace userFurnace,
      {bool? adultOnly,
      String? newName,
      String? accessCode,
      bool? discoverable,
      bool? enableWall,
      String? description,
      String? link,
      bool? autonomy}) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE_CONFIG;

      debugPrint(url);

      Map map = {};

      String hostedName = 'IronForge';
      String key = 'IronForge';

      if (userFurnace.type != NetworkType.FORGE) {
        hostedName = userFurnace.hostedName!;
        key = userFurnace.hostedAccessCode!;
      }

      if (adultOnly != null) {
        map['adultOnly'] = adultOnly;
      }
      if (newName != null) {
        map['newName'] = newName;
        map["hostedName"] = hostedName;
        map["key"] = key;
        map['accessCode'] = key;
      }
      if (link != null) {
        map['link'] = link;
      }
      if (accessCode != null) {
        map['accessCode'] = accessCode;
        map["hostedName"] = hostedName;
        map["key"] = key;
      }
      if (discoverable != null) {
        map['discoverable'] = discoverable;
      }
      if (enableWall != null) {
        map['enableWall'] = enableWall;
      }
      if (description != null) {
        map['description'] = description;
      }
      if (autonomy != null) {
        map['memberAutonomy'] = autonomy;
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

        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);


        return true;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return false;
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  Future<List<HostedFurnace>> getDiscoverable(
      UserFurnace userFurnace, bool ageRestrict) async {
    try {
      String url = userFurnace.url! +
          Urls.HOSTEDFURNACE_DISCOVERABLE;

      Map map = {
        "apikey": urls.forgeAPIKEY,
        "ageRestrict": ageRestrict.toString(),
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map)
      );

      debugPrint(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        HostedFurnaceCollection networks =
            HostedFurnaceCollection.fromJSON(jsonResponse, 'hostedNetworks');
        List<HostedFurnace> hostedFurnaces = networks.objects;
        return hostedFurnaces;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return [];
      } else {
        debugPrint('${response.statusCode}: ${response.body}');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("HostedFurnaceService: getDiscoverable: $error");
      rethrow;
    }
  }

  ///from landing
  Future<List<HostedFurnace>> getAllDiscoverable() async {
    try {
      String url = urls.forge + Urls.HOSTEDFURNACE_ALLDISCOVERABLE;

      if (await Network.isConnected()) {
        Map map = {
          "apikey": urls.forgeAPIKEY,
        };

        map = await EncryptAPITraffic.encrypt(map);
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': urls.forgeAPIKEY,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);
          HostedFurnaceCollection networks =
              HostedFurnaceCollection.fromJSON(jsonResponse, 'hostedNetworks');
          List<HostedFurnace> hostedFurnaces = networks.objects;
          return hostedFurnaces;
        } else if (response.statusCode == 401) {
          return [];
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          Map<String, dynamic> jsonResponse = json.decode(response.body);
          throw Exception(jsonResponse['msg']);
        }
      }
      return [];
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: getAllDiscoverable: $error');
      rethrow;
    }
  }

  Future<List<HostedFurnace>> getPendingDiscoverable(
      UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE_PENDINGDISCOVERABLE;

      Map map = {
        "apikey": urls.forgeAPIKEY,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map)
      );

      debugPrint(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        HostedFurnaceCollection networks =
            HostedFurnaceCollection.fromJSON(jsonResponse, 'hostedNetworks');
        List<HostedFurnace> hostedFurnaces = networks.objects;
        return hostedFurnaces;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return [];
      } else {
        debugPrint('${response.statusCode}: ${response.body}');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("HostedFurnaceService: getPendingDiscoverable: $error");
      rethrow;
    }
  }

  Future<HostedFurnace> setNetworkApproved(
      UserFurnace userFurnace, HostedFurnace furn, bool approved) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE_APPROVED;

      Map map = ({
        'approved': approved,
        'furnaceID': furn.id,
      });

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      debugPrint(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        HostedFurnace hostedFurnace =
            HostedFurnace.fromJson(jsonResponse["hostedFurnace"]);
        return hostedFurnace;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return furn;
      } else {
        debugPrint('${response.statusCode}: ${response.body}');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("HostedFurnaceService: setNetworkApproved: $error");
      rethrow;
    }
  }

  Future<HostedFurnace> setNetworkOverride(
      UserFurnace userFurnace, HostedFurnace furn, bool override) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE_OVERRIDE;

      Map map = ({
        'override': override,
        'furnaceID': furn.id,
      });

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      debugPrint(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        HostedFurnace hostedFurnace =
            HostedFurnace.fromJson(jsonResponse['hostedFurnace']);
        return hostedFurnace;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return furn;
      } else {
        debugPrint('${response.statusCode}: ${response.body}');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("HostedFurnaceService: setNetworkOverride: $error");
      rethrow;
    }
  }

  Future<void> lockout(
      UserFurnace userFurnace, User user, bool lockedOut) async {
    String url = userFurnace.url! + Urls.HOSTEDFURNACE_LOCKOUT;

    String hostedName = 'IronForge';
    String key = 'IronForge';

    if (userFurnace.type != NetworkType.FORGE) {
      hostedName = userFurnace.hostedName!;
      key = userFurnace.hostedAccessCode!;
    }

    debugPrint(url);

    Map map = {
      "hostedName": hostedName,
      "key": key,
      'memberID': user.id,
      'lockedOut': lockedOut
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

      await TableMember.setLockedOut(userFurnace.userid!, user.id!, lockedOut);

      return;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<User>> getMembers(UserFurnace userFurnace,
      {String includeMemberCircles = ''}) async {
    String url = userFurnace.url! + Urls.HOSTEDFURNACE_MEMBERS;

    String hostedName = 'IronForge';
    String key = 'IronForge';

    if (userFurnace.type != NetworkType.FORGE) {
      hostedName = userFurnace.hostedName!;
      key = userFurnace.hostedAccessCode!;
    }

    Map map = {"hostedName": hostedName, "key": key};

    if (includeMemberCircles.isNotEmpty) {
      map['includeMemberCircles'] = includeMemberCircles;
    }

    debugPrint(url);

    if (userFurnace.token == null) return [];

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

      UserCollection members = UserCollection.fromJSON(jsonResponse, 'members');
      User user = User.fromJson(jsonResponse['user']);

      UserCollection connections =
          UserCollection.fromJSON(jsonResponse, 'userConnections');

      await _updateMembers(
          userFurnace, members, connections, user.blockedList!);

      if (includeMemberCircles.isNotEmpty) {
        MemberCircleCollection memberCircleCollection =
            MemberCircleCollection.fromJSON(jsonResponse, "memberCircles");
        await TableMemberCircle.upsertCollection(
            userFurnace.userid!, memberCircleCollection);
      }

      members.users.removeWhere((element) => element.removeFromCache != null);

      return members.users;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<NetworkRequest>> getNetworkRequests(
      UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.NETWORKREQUEST_FORNETWORK;

    Map map = {
      'user': userFurnace.userid,
    };

    map = await EncryptAPITraffic.encrypt(map);

    debugPrint(url);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      NetworkRequestCollection requests =
          NetworkRequestCollection.fromJSON(jsonResponse, 'networkRequests');
      return requests.objects;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> updateRequest(
      UserFurnace userFurnace,
      NetworkRequest networkRequest,
      HostedFurnaceBloc hostedFurnaceBloc) async {
    try {
      String url = userFurnace.url! + Urls.NETWORKREQUEST;

      Map map = {
        'networkRequest': networkRequest,

        ///pass new status through here
        'networkRequestID': networkRequest.id,
        'hostedFurnaceID': networkRequest.hostedFurnace.id,
      };

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

        ///sync the updated network requests so pages refresh
        NetworkRequestCollection requests =
            NetworkRequestCollection.fromJSON(jsonResponse, 'updatedRequests');
        hostedFurnaceBloc.broadcastNetworkRequests(requests.objects);

        return;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return;
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService.updateRequest: $error');
    }
  }

  Future<void> makeRequest(
      UserFurnace userFurnace, NetworkRequest networkRequest) async {
    String url = userFurnace.url! + Urls.NETWORKREQUEST;

    Map map = {
      'user': networkRequest.user,
      'hostedFurnaceID': networkRequest.hostedFurnace,
      'networkRequest': networkRequest,
    };

    debugPrint(url);

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

      return;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<NetworkRequest>> getRequests(
      UserFurnace userFurnace, User user) async {
    String url = userFurnace.url! + Urls.NETWORKREQUEST_USERREQUESTS;

    Map map = {"user": user};

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    debugPrint(url);

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      NetworkRequestCollection requests =
          NetworkRequestCollection.fromJSON(jsonResponse, 'networkRequests');
      return requests.objects;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> postMagicLinkToNetwork(UserFurnace userFurnace, String link,
      String firebaseLink, bool dm, RatchetKey ratchetKey) async {
    // Map body;

    try {
      String url = urls.forge + Urls.MAGICLINK_NETWORK;

      Map map = {
        'hostedName': userFurnace.hostedName ?? '',
        'key': userFurnace.hostedAccessCode ?? '',
        'link': link,
        'firebaseLink': firebaseLink,
        'dm': dm,
        'ratchetPublicKey': ratchetKey.safePublicCopy(),
      };

      debugPrint(url);


      if (await Network.isConnected()) {
        debugPrint(url);

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


          return;
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          await navService.logout(userFurnace); //TODO
          return;
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ("failed to create magic link");
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }
    return;
  }

  Future<String> getMagicLinkToNetwork(UserFurnace userFurnace) async {
    // Map body;

    try {
      String url = urls.forge + Urls.HOSTEDFURNACE_MAGICLINKTONETWORK;

      Map map = {
        'hostedName': userFurnace.hostedName ?? '',
        'key': userFurnace.hostedAccessCode ?? '',
      };


      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          String magicCode = jsonResponse["url"];

          await TableMagicCode.insert(MagicCode(
              userFurnaceKey: userFurnace.pk!,
              code: StringHelper.getMagicCodeFromString(magicCode),
              type: MagicCodeType.network));

          return magicCode;
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          await navService.logout(userFurnace); //TODO
          return '';
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ("failed to create magic link");
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }
    return '';
  }

  Future<String> getMagicLinkToCircle(
      UserFurnace userFurnace, String circleID) async {
    // Map body;

    try {
      String url = urls.forge + Urls.HOSTEDFURNACE_MAGICLINKTOCIRCLE;

      Map map = {
        'circleID': circleID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Authorization': userFurnace.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          return jsonResponse["url"];
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          await navService.logout(userFurnace); //TODO
          return '';
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ("failed to create magic link");
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }
    return '';
  }

  Future<HostedFurnace?> getHostedFurnace(UserFurnace userFurnace) async {
    try {
      String url = userFurnace.url! + Urls.HOSTEDFURNACE;

      Map map = {};

      if (userFurnace.token == null) return null;

      debugPrint(userFurnace.type.toString());
      debugPrint(userFurnace.type.name);
      debugPrint(userFurnace.alias);

      if (userFurnace.type != NetworkType.FORGE) {
        map['hostedName'] = userFurnace.hostedName;
        map['key'] = userFurnace.hostedAccessCode;
      }

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': userFurnace.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      debugPrint(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);
        //debugPrint(json.encode(response.body));

        if (jsonResponse["hostedNetwork"] != null) {
          HostedFurnace network =
              HostedFurnace.fromJson(jsonResponse["hostedNetwork"]);
          return network;
        }
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return null;
      } else {
        debugPrint('${response.statusCode}: ${response.body}');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint("HostedFurnaceService: getHostedFurnaces: $error");
      rethrow;
    }

    return null;
  }

  Future<HostedInvitation?> validateHostedLinkToNetwork(String link) async {
    // Map body;

    try {
      String url = urls.forge + Urls.MAGICLINK_NETWORK_VALIDATE;

      Map map = {
        'link': link,
        'apikey': urls.forgeAPIKEY,
      };

      debugPrint(url);

      if (await Network.isConnected()) {
        debugPrint(url);

        map = await EncryptAPITraffic.encrypt(map);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          return HostedInvitation.fromJson(jsonResponse["magicNetworkLink"]);
        } else if (response.statusCode == 401) {
          throw ("authorization error");
        } else {
          debugPrint("${response.statusCode}: ${response.body}");

          try {
            Map<String, dynamic> jsonResponse = json.decode(response.body);

            String msg = jsonResponse['msg'];
            throw (msg);
          } catch (err) {
            throw ('could not find invitation');
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }
    return null;
  }

  Future<HostedInvitation?> getHostedInvitation(String token) async {
    // Map body;

    try {
      String url = urls.forge + Urls.HOSTEDFURNACE_INVITATION;

      Map map = {
        'token': token,
        'apikey': urls.forgeAPIKEY,
      };


      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

          return HostedInvitation.fromJson(jsonResponse["hostedInvitation"]);
        } else if (response.statusCode == 401) {
          throw ("authorization error");
        } else {
          debugPrint("${response.statusCode}: ${response.body}");

          try {
            Map<String, dynamic> jsonResponse = json.decode(response.body);

            String msg = jsonResponse['msg'];
            throw (msg);
          } catch (err) {
            throw ('could not find invitation');
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }
    return null;
  }

  Future<bool> requestApproved(UserFurnace userFurnace, String name,
      {String networkUrl = ''}) async {
    // Map body;

    try {
      Map map = {"hostedName": name};

      String url =
          networkUrl.isEmpty ? urls.forge : networkUrl; //always check the forge

      url = url + Urls.HOSTEDFURNACE_REQUEST_APPROVED;

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              ///Network request use the auth server so don't use the userFurnace token, there isn't one yet
              'Authorization': globalState.userFurnace!.token!,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          if (jsonResponse["valid"] == true)
            return true;
          else
            return false;
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          //await navService.logout(userFurnace);  //TODO
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ('Could not connect to network. Please check settings.');
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }

    return false;
  }

  ///validating networks from network manager
  Future<String> valid(
      UserFurnace userFurnace, String name, String key, bool fromPublic,
      {String networkUrl = ''}) async {
    try {
      Map map = {
        "hostedName": name,
        "key": key,
        "user": globalState.user,
        "fromPublic": fromPublic,
        'apikey': urls.forgeAPIKEY,
      };

      String url =
          networkUrl.isEmpty ? urls.forge : networkUrl; //always check the forge

      url = url + Urls.HOSTEDFURNACE_VALID;

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              //'apikey': urls.forgeAPIKEY,
              'Content-Type': "application/json",
              'Authorization': userFurnace.token!,
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          return jsonResponse["valid"];
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          //await navService.logout(userFurnace);  //TODO
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw ('Could not connect to network. Please check settings.');
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }

    return '';
  }

  Future<bool> checkName(String name,
      {String? networkUrl, String? networkApiKey}) async {
    try {
      Device device = await globalState.getDevice();
      Map map = {"hostedName": name};

      String url = (networkUrl ?? urls.forge) +
          Urls.HOSTEDFURNACE_CHECKNAME; //always check the forge

      debugPrint(url);

      map = await EncryptAPITraffic.encrypt(map);

      if (await Network.isConnected()) {
        debugPrint(url);

        final response = await http.post(Uri.parse(url),
            headers: {
              'apikey': networkApiKey ?? urls.forgeAPIKEY,
              'Content-Type': "application/json",
            },
            body: json.encode(map));

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
              await EncryptAPITraffic.decryptJson(response.body);

          if (jsonResponse["nameAvailable"] == true)
            return true;
          else
            return false;
        } else if (response.statusCode == 401) {
          //debugPrint('break');
          //await navService.logout(userFurnace);  //TODO
        } else {
          debugPrint("${response.statusCode}: ${response.body}");
          throw (response.body);
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('HostedFurnaceService: fetchUserCircle: $error');
      rethrow;
    }

    return false;
  }

  Future<void> _updateMembers(UserFurnace userFurnace, UserCollection members,
      UserCollection connections, List<User> blockedList) async {
    if (members.users.isNotEmpty) {
      await TableMember.upsertCollection(userFurnace.userid!, userFurnace.pk!,
          members, connections, globalState, blockedList);

      TableMemberDevice.upsertCollection(userFurnace.userid!, members.users);

      avatarService.validateCurrentAvatarsByUser(userFurnace, members);
    } //this is async on purpose
  }
}
