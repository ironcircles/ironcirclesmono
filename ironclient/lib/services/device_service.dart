import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/kyber/kyber.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

// class KyberResult {
//   List<int> ct;
//   List<int> ss;
//
//   KyberResult(this.ct, this.ss);
// }

class DeviceService {
  static const String android = 'android';
  static const String iOS = 'iOS';
  static const String macos = "macos";

  // Future<void> updateDeviceID(UserFurnace userFurnace, Device device) async {
  //   String url = userFurnace.url! + Urls.DEVICE_UPDATEID;
  //
  //   Device device = await globalState.getDevice();
  //   Map map = {
  //     'uuid': device.uuid,
  //     'patchID': true
  //   };
  //
  //   final response = await http.post(Uri.parse(url),
  //       headers: {
  //         'Authorization': userFurnace.token!,
  //         'Content-Type': "application/json",
  //       },
  //       body: json.encode(map));
  //
  //   if (response.statusCode == 200) {
  //
  //     TableDevice.upsert(device);
  //     globalState.setDevice(device);
  //
  //     return;
  //   } else {
  //     debugPrint("${response.statusCode}: ${response.body}");
  //
  //     Map<String, dynamic> jsonResponse = json.decode(response.body);
  //
  //     LogBloc.insertError(
  //         jsonResponse['err'], StackTrace.fromString('DeviceService.get'));
  //
  //     throw Exception(jsonResponse['msg']);
  //   }
  // }

  Future<void> kyberTest(String url) async {
    url = url + Urls.DEVICE_KYBERTEST;

    Device device = await globalState.getDevice();
    Map map = {
      'uuid': device.uuid,
    };
    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      //["encryptedPayload"]['enc'], jsonResponse["encryptedPayload"]['iv'], jsonResponse["encryptedPayload"]['tag']);

       //print(jsonResponse);
      // debugPrint('break');

      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['err'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['msg']);
    }
  }

  KyberEncryptionResult calculateCipher(Map<String, dynamic> jsonResponse){

    final pk = List<int>.empty(growable: true);
    jsonResponse['pk'].forEach((String k, dynamic v) => pk.add(v as int));
    //final pk = jsonResponse['pk'].cast<int>();

    final cipher = Kyber.k1024().encrypt(pk);

    debugPrint("\n\n ss: ${cipher.sharedSecret}\n\n");

    return cipher;
  }

  Future<KyberEncryptionResult> getNewKyberPublicKey(
      Device device, String url) async {
    url = url + Urls.DEVICE_KYBERPUBLICKEY_POST;

    var keys = Kyber.k1024().generateKeys();

    final cipher = Kyber.k1024().encrypt(keys.publicKey.bytes);
    final cipherText = Kyber.k768().decrypt(
      cipher.cipherText.bytes,
      keys.privateKey.bytes,
    );

    //print(cipherText);

    Map map = {
      'uuid': device.uuid,
      'devicePublic': keys.publicKey.bytes,
      //'ct': cipher.cipherText.bytes,
    };



    final response = await http.post(Uri.parse(url),
        headers: {
          //'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      //List<int> ct = jsonResponse['ct'].cast<int>();
      //final cipherText = Kyber.k1024().decrypt(ct, keys.privateKey.bytes);
      //print(cipherText.bytes);

      //final sk = jsonResponse['sk'].cast<int>();

      ///try to get a cc from server public key
      return calculateCipher(jsonResponse);

      // final pk = List<int>.empty(growable: true);
      // jsonResponse['pk'].forEach((String k, dynamic v) => pk.add(v as int));
      // //final pk = jsonResponse['pk'].cast<int>();
      //
      // final cipher = Kyber.k1024().encrypt(pk);
      //
      // debugPrint("\n\n ss: ${cipher.sharedSecret}\n\n");
      //
      // return cipher;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['err'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['err']);
    }
  }

  Future<KyberEncryptionResult> updateKyberPublicKey(
      UserFurnace userFurnace, Device device, String url) async {
    url = url + Urls.DEVICE_KYBERPUBLICKEY_PUT;

    var keys = Kyber.k1024().generateKeys();

    final cipher = Kyber.k1024().encrypt(keys.publicKey.bytes);
    final cipherText = Kyber.k768().decrypt(
      cipher.cipherText.bytes,
      keys.privateKey.bytes,
    );

    //print(cipherText);

    Map map = {
      'uuid': device.uuid,
      'devicePublic': keys.publicKey.bytes,
    };

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      ///try to get a cc from server public key
      final pk = List<int>.empty(growable: true);
      jsonResponse['pk'].forEach((String k, dynamic v) => pk.add(v as int));

      final cipher = Kyber.k1024().encrypt(pk);

      //debugPrint("\n\n ss: ${cipher.sharedSecret}\n\n");

      return cipher;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['err'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['err']);
    }
  }

  Future<void> postCipherText(
      Device device, String url, List<int> cipherText) async {
    url = url + Urls.DEVICE_KYBERCIPHER_POST;

    Map map = {
      'ct': cipherText,
      'uuid': device.uuid,
    };

    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      //Map<String, dynamic> jsonResponse = json.decode(response.body);

      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['err'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> putCipherText(
      UserFurnace userFurnace, Device device, String url, List<int> cipherText) async {
    url = url + Urls.DEVICE_KYBERCIPHER_PUT;

    Map map = {
      'ct': cipherText,
      'uuid': device.uuid,
    };

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': userFurnace.token!,
          'Content-Type': "application/json",
        },
        body: json.encode(map));

    if (response.statusCode == 200) {
      //Map<String, dynamic> jsonResponse = json.decode(response.body);

      return;
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['err'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<List<Device>> get(UserFurnace userFurnace) async {
    String url = userFurnace.url! + Urls.DEVICE_GET;
    debugPrint(url);

    Map map = {
      'userID': userFurnace.userid!,
    };

    map = await EncryptAPITraffic.encrypt(map);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': userFurnace.token!,
        'Content-Type': "application/json",
      }, body: json.encode(map),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          await EncryptAPITraffic.decryptJson(response.body);

      DeviceCollection devices = DeviceCollection.fromJSONAddFurnace(
          jsonResponse, 'devices', userFurnace);

      return devices.devices;
    } else if (response.statusCode == 401) {
      await navService.logout(userFurnace);
      return [];
    } else {
      debugPrint("${response.statusCode}: ${response.body}");

      Map<String, dynamic> jsonResponse = json.decode(response.body);

      LogBloc.insertError(
          jsonResponse['msg'], StackTrace.fromString('DeviceService.get'));

      throw Exception(jsonResponse['msg']);
    }
  }

  Future<void> remoteWipe(Device device) async {
    try {
      Map map;
      String url;

      url = device.userFurnace!.url! + Urls.DEVICE_REMOTEWIPE;

      map = {
        'uuid': device.uuid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': device.userFurnace!.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);
      } else if (response.statusCode == 401) {
        await navService.logout(device.userFurnace!);
      } else {
        debugPrint(response.statusCode.toString());
        throw ('could not remote wipe device');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  Future<void> deactivate(Device device) async {
    try {
      Map map;
      String url;

      url = device.userFurnace!.url! + Urls.DEVICE_DEACTIVATE;

      map = {
        'uuid': device.uuid,
      };

      map = await EncryptAPITraffic.encrypt(map);

      debugPrint(url);

      final response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': device.userFurnace!.token!,
            'Content-Type': "application/json",
          },
          body: json.encode(map));

      if (response.statusCode == 200) {
        // Map<String, dynamic> jsonResponse =
        // await EncryptAPITraffic.decryptJson(response.body);
      } else if (response.statusCode == 401) {
        await navService.logout(device.userFurnace!);
      } else {
        debugPrint(response.statusCode.toString());
        throw Exception('Could not deactivate device');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<void> updateFireToken(String pushToken) async {
    try {
      List<UserFurnace> userFurnaces = await TableUserFurnace.readAll();

      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue;

        Map map;
        String url;

        url = userFurnace.url! + Urls.REGISTER_DEVICE;

        Device device = await globalState.getDevice();

        map = {
          'apikey': userFurnace.apikey,
          'uuid': device.uuid,
          'pushtoken': pushToken,
          'platform': device.platform == null || device.platform!.isNotEmpty
              ? device.platform
              : DeviceBloc.getPlatformString(),
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
          // Map<String, dynamic> jsonResponse =
          // await EncryptAPITraffic.decryptJson(response.body);

          //debugPrint(jsonResponse);
        } else if (response.statusCode == 401) {
          //await navService.logout(userFurnace);
        } else {
          debugPrint(response.statusCode.toString());
          // If that call was not successful, throw an error.
          //throw Exception('Invalid username or password');
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }
}
