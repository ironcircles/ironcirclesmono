import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/utils/network.dart';

class BlobUrlsService {
  Future<BlobUrl> getUploadUrls(UserFurnace userFurnace, int blobType,
      String circleID, String filePath, String thumbnailPath) async {
    try {
      //throw('chaos');

      if (await Network.isConnected() == false) {
        throw ("internet not detected");
      }
      String url = userFurnace.url! + Urls.BLOB_UPLOAD_DUAL_LINKS;

      // var client = RetryClient(new http.Client(), retries: 3);

      debugPrint(url);

      Map map = {
        'blobtype': blobType.toString(),
        'filename': FileSystemService.getFilename(filePath),
        'thumbnail': FileSystemService.getFilename(thumbnailPath),
        'circleID': circleID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        //final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map),
      ).timeout(const Duration(seconds: RETRIES.TIMEOUT_API_IMAGE));

      debugPrint(
          'file:${FileSystemService.getFilename(filePath)}, thumb: ${FileSystemService.getFilename(thumbnailPath)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        //throw('chaos');

        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

        return urls;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return BlobUrl.blank();
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (err) {
      //LogBloc.insertError(err, trace); //caller can determine whether to log or not after retries
      debugPrint("BlobUrlsService.getUploadUrls: $err");

      rethrow;
    }
  }

  Future<BlobUrl> getDownloadUrls(UserFurnace userFurnace, int blobType,
      String circleID, String fileName, String thumbnail) async {
    String url = userFurnace.url! + Urls.BLOB_DOWNLOAD_DUAL_LINKS;

    debugPrint(url);

    Map map = {
      'blobtype': blobType.toString(),
      'filename': fileName,
      'thumbnail': thumbnail,
      'circleID': circleID,
    };

    map = await EncryptAPITraffic.encrypt(map);


    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

      return urls;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return BlobUrl.blank();
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<BlobUrl> getUserUploadUrl(
      UserFurnace userFurnace, int blobType, String circleID, String filePath) async {
    try {
      String url = userFurnace.url! + Urls.BLOB_UPLOAD_USER_LINK;

      debugPrint(url);

      Map map = {
        'blobtype': blobType.toString(),
        'filename': FileSystemService.getFilename(filePath),
        'circleID': circleID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

        return urls;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return BlobUrl.blank();
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobUrlsService.getUploadUrls: $err");

      rethrow;
    }
  }

  ///getting avatars for public networks from the landing
  Future<BlobUrl> getUnauthorizedNetworkDownloadUrl(
      HostedFurnace network,
      int blobType,
      String fileName) async {
    try {

      String url = urls.forge + Urls.BLOB_DOWNLOAD_UNAUTHORIZED_LINK;

      debugPrint(url);

      Map map = {
        'blobtype': blobType.toString(),
        'filename': fileName,
        'networkid': network.id,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': urls.forgeAPIKEY,
            'Content-Type': "application/json",
          }, body: json.encode(map),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

        return urls;
      } else if (response.statusCode == 401) {
        //await navService.logout(userFurnace);
        return BlobUrl.blank();
      } else {
        debugPrint("${response.statusCode}: ${response.body}");
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['msg']);
      }

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('BlobUrlsService: getUnauthorizedNetworkDownloadUrl: $error');
      rethrow;
    }
  }

  Future<BlobUrl> getUserDownloadUrl(
    UserFurnace userFurnace,
    int blobType,
    String fileName,
  ) async {
    String url = userFurnace.url! + Urls.BLOB_DOWNLOAD_USER_LINK;

    debugPrint(url);

    Map map = {
      'blobtype': blobType.toString(),
      'filename': fileName,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

      return urls;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return BlobUrl.blank();
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<BlobUrl> getUploadUrl(
      UserFurnace userFurnace, int blobType, String circleID, String filePath) async {
    try {
      String url = userFurnace.url! + Urls.BLOB_UPLOAD_LINK;

      debugPrint(url);

      Map map = {
        'blobtype': blobType.toString(),
        'filename': FileSystemService.getFilename(filePath),
        'circleID': circleID,
      };

      map = await EncryptAPITraffic.encrypt(map);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        }, body: json.encode(map),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonResponse =
        await EncryptAPITraffic.decryptJson(response.body);

        BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

        return urls;
      } else if (response.statusCode == 401) {
        await navService.logout(userFurnace);
        return BlobUrl.blank();
      } else {
        debugPrint("${response.statusCode}: ${response.body}");

        Map<String, dynamic> jsonResponse = json.decode(response.body);

        throw Exception(jsonResponse['msg']);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("BlobUrlsService.getUploadUrls: $err");

      rethrow;
    }
  }

  Future<BlobUrl> getDownloadUrl(
      UserFurnace userFurnace, int blobType, String circleID, String fileName) async {
    String url = userFurnace.url! + Urls.BLOB_DOWNLOAD_LINK;

    debugPrint(url);

    Map map = {
      'blobtype': blobType.toString(),
      'filename': fileName,
      'circleID': circleID,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> jsonResponse =
      await EncryptAPITraffic.decryptJson(response.body);

      BlobUrl urls = BlobUrl.fromJson(jsonResponse["urls"]);

      return urls;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return BlobUrl.blank();
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      throw Exception(jsonResponse['msg']);
    }
  }
}
