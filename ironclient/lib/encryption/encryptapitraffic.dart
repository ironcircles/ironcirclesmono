import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:http/http.dart' as http;
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:media_kit/generated/libmpv/bindings.dart';

class EncryptAPITraffic {
  // Future<void> kyberTest(String url, Device device, Map map) async {
  //
  //   // Map map = {
  //   //   'uuid': device.uuid,
  //   //   //'sk': tempResults.sk,
  //   // };
  //
  //   map = await encrypt(device, map);
  //
  //   final response = await http.post(Uri.parse(url),
  //       headers: {
  //         'Content-Type': "application/json",
  //       },
  //       body: json.encode(map));
  //
  //   if (response.statusCode == 200) {
  //     Map<String, dynamic> jsonResponse = json.decode(response.body);
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



  static Future<Map<String, dynamic>> encryptb(Map<String, dynamic> map, {Device? device}) async {

    if (Platform.isIOS) {
      return map;
    }

    device ??= await globalState.getDevice();

    ///if the user opened the app in airplane mode before kyber was init, there won't be a shared secret
    ///remove POSTKYBER
    if (device.kyberSharedSecret == null || device.kyberSharedSecret!.isEmpty) {
      return map;
    }

    var data = jsonEncode(map);
    //final algorithm = AesGcm.with256bits();
    final algorithm = DartAesGcm
        .with256bits(); //final secretKey = await algorithm.newSecretKey();

    final secretKey = SecretKey(base64Url.decode(device.kyberSharedSecret!));
    final nonce = algorithm.newNonce();

    // var enc = [51,49,51,48,100,55,99,50,56,55,56,50,49,101,97,48,53,97,55,55,100,56,49,101,100,102,48,53,97,51];
    // List<int> enc =base64Url.decode(sEnc);
    //List<int> enc = utf8.encode(sEnc);
    // List<int> iv = utf8.encode(jsonResponse["encryptedPayload"]["iv"]);
    //var ivMap = jsonResponse["encryptedPayload"]["iv"];
    //List<int> iv = ivMap['data'].cast<int>();

    /// Encrypt
    final secretBox = await algorithm.encrypt(
      utf8.encode(data),
      secretKey: secretKey,
      nonce: nonce,
    );

    Map<String, dynamic> results = {
      'uuid': device.uuid,
      'enc': secretBox.cipherText,
      'iv': nonce,
      'mac': secretBox.mac.bytes,
    };

    // print("enc: ${results['enc']}");
    // print("iv: ${results['iv']}");
    // print("mac: ${results['mac']}");

    return results;
  }

  static Future<Map> encrypt(Map map, {Device? device}) async {

    if (Platform.isIOS) {
      return map;
    }

    device ??= await globalState.getDevice();

    ///if the user opened the app in airplane mode before kyber was init, there won't be a shared secret
    ///remove POSTKYBER
    if (device.kyberSharedSecret == null || device.kyberSharedSecret!.isEmpty) {
      return map;
    }

    var data = jsonEncode(map);
    //final algorithm = AesGcm.with256bits();
    final algorithm = DartAesGcm
        .with256bits(); //final secretKey = await algorithm.newSecretKey();

    final secretKey = SecretKey(base64Url.decode(device.kyberSharedSecret!));
    final nonce = algorithm.newNonce();

    // var enc = [51,49,51,48,100,55,99,50,56,55,56,50,49,101,97,48,53,97,55,55,100,56,49,101,100,102,48,53,97,51];
    // List<int> enc =base64Url.decode(sEnc);
    //List<int> enc = utf8.encode(sEnc);
    // List<int> iv = utf8.encode(jsonResponse["encryptedPayload"]["iv"]);
    //var ivMap = jsonResponse["encryptedPayload"]["iv"];
    //List<int> iv = ivMap['data'].cast<int>();

    /// Encrypt
    final secretBox = await algorithm.encrypt(
      utf8.encode(data),
      secretKey: secretKey,
      nonce: nonce,
    );

    Map results = {
      'uuid': device.uuid,
      'enc': secretBox.cipherText,
      'iv': nonce,
      'mac': secretBox.mac.bytes,
    };

    // print("enc: ${results['enc']}");
    // print("iv: ${results['iv']}");
    // print("mac: ${results['mac']}");

    return results;
  }

  static Future<Map<String, dynamic>> decryptJson(
       String body, {Device? device}) async {

    device ??= await globalState.getDevice();

    Map<String, dynamic> jsonResponse = jsonDecode(body);

    if (jsonResponse["enc"] != null) {
      String decrypted = await decryptString(device, jsonResponse);

      jsonResponse = jsonDecode(decrypted);
    }

    return jsonResponse;
  }

  static Future<String> decryptString(
      Device device, Map<String, dynamic> jsonResponse) async {
    String sEnc = jsonResponse["enc"];
    List<int> enc = hex.decode(sEnc);

    var ivMap = jsonResponse["iv"];
    List<int> iv = ivMap['data'].cast<int>();

    var macMap = jsonResponse["tag"];
    List<int> mac = macMap['data'].cast<int>();

    final algorithm = DartAesGcm.with256bits();
    final SecretBox secretBox = SecretBox(enc, nonce: iv, mac: Mac(mac));

    var keyList = base64Url.decode(device.kyberSharedSecret!);
    final secretKey = SecretKey(keyList);

    // print("sEnc: $sEnc");
    // print("enc: $enc");
    // print("iv: $iv");
    // print("mac: $mac");
    // print("keyList: $keyList");
    // print("secretKey: $secretKey");
    // print("secretKey: ${device.kyberSharedSecret!}");

    final clearIntArray = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    var clearText = utf8.decode(clearIntArray);
    //var json = jsonDecode(clearText);

    return clearText;
  }

  static Future<String> decryptTest(
      Device device,
      Map<dynamic, dynamic>
          encrypted /*List<int> enc, List<int> iv, List<int> mac*/) async {
    List<int> enc = encrypted["enc"];
    List<int> iv = encrypted["iv"];
    List<int> mac = encrypted["mac"];

    // print("enc: $enc");
    // print("iv: $iv");
    // print("mac: $mac");

    // List<int> mac = utf8.encode(jsonResponse["encryptedPayload"]["mac"]);

    final algorithm = AesGcm.with256bits();
    final SecretBox secretBox = SecretBox(enc, nonce: iv, mac: Mac(mac));

    final clearIntArray = await algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(base64Url.decode(device.kyberSharedSecret!)),
    );

    var clearText = utf8.decode(clearIntArray);
    //var json = jsonDecode(clearText);

    return clearText;
  }
}
