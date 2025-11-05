/*
//
//  IronCircles Encryption/Decryption for User specific objects (not messaging)
//  Used for custom backgrounds, Circle names, and list and recipe templates
//
*/

import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_helper.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_receiver.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_user.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/user_service.dart';
import 'package:ironcirclesapp/services/usercircle_service.dart';
import 'package:uuid/uuid.dart';

class RatchetKeyAndMap {
  Map<String, dynamic> map;
  RatchetKey ratchetKey;

  RatchetKeyAndMap({
    required this.map,
    required this.ratchetKey,
  });
}

class IsolateDecryptCircleListTemplate {
  List<CircleListTemplate> circleListTemplates;
  Map<String, RatchetPair> ratchetPairs;

  IsolateDecryptCircleListTemplate({
    required this.circleListTemplates,
    required this.ratchetPairs,
  });
}

class IsolateDecryptCircleRecipeTemplate {
  List<CircleRecipeTemplate> circleRecipeTemplates;
  Map<String, RatchetPair> ratchetPairs;

  IsolateDecryptCircleRecipeTemplate({
    required this.circleRecipeTemplates,
    required this.ratchetPairs,
  });
}

class UserTemplateRatchet {
  String crank;
  String signature;
  List<RatchetIndex> ratchetIndexes;
  String cipherText;
  //List<CircleListTask> tasks;

  UserTemplateRatchet({
    required this.crank,
    required this.signature,
    required this.ratchetIndexes,
    required this.cipherText,
    /*required this.tasks*/
  });

  Map<String, dynamic> toJson() => {
        'crank': crank,
        'body': cipherText,
        'signature': signature,
        'ratchetIndexes': ratchetIndexes,
      };
}

Future<String> _decrypt(Cipher cipher, RatchetPair ratchetPair, String crank,
    String signature, String body) async {
  try {
    final x25519 = Cryptography.instance.x25519();

    var privateKey = await x25519
        .newKeyPairFromSeed(base64Url.decode(ratchetPair.ratchetKey.private));

    //calculate the shared secret
    var sharedSecret = await x25519.sharedSecretKey(
        keyPair: privateKey,
        remotePublicKey: SimplePublicKey(
            base64Url.decode(ratchetPair
                .ratchetKey.public!), //this will have to change for invitations
            type: x25519.keyPairType));

    //decrypt the message key
    SecretBox secretBoxKey = SecretBox(
        base64Url.decode(ratchetPair.ratchetIndex.ratchetValue),
        nonce: base64Url.decode(ratchetPair.ratchetIndex.crank),
        mac: Mac(base64Url.decode(ratchetPair.ratchetIndex.signature)));

    final secretKey = await cipher.decrypt(
      secretBoxKey,
      secretKey: sharedSecret,
    );

    SecretBox secretBox = SecretBox(base64Url.decode(body),
        nonce: base64Url.decode(crank), mac: Mac(base64Url.decode(signature)));

    final decrypt = await cipher.decrypt(
      secretBox,
      secretKey: SecretKey(secretKey),
    );

    return utf8.decode(decrypt);
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint('ForwardSecrecyUser._decrypt: ${err.toString()}');
    throw Exception(err);
  }
}

Future<List<CircleListTemplate>> _decryptListTemplates(
    IsolateDecryptCircleListTemplate params) async {
  List<CircleListTemplate> decryptedList = [];

  try {
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    for (CircleListTemplate circleListTemplate in params.circleListTemplates) {
      RatchetPair? ratchetPair = params.ratchetPairs[circleListTemplate.id];

      if (ratchetPair == null) {
        //throw ("missing keys");
        debugPrint('ForwardSecrecyUser._decryptRecipeTemplates: keys missing');
      } else {
        String decrypted = await _decrypt(
            cipher,
            ratchetPair,
            circleListTemplate.crank,
            circleListTemplate.signature,
            circleListTemplate.body);

        circleListTemplate.mapDecryptedFields(json.decode(decrypted));

        decryptedList.add(circleListTemplate);
      }
    }
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint('ForwardSecrecyUser._decryptListTemplates: ${err.toString()}');
    throw Exception(err);
  }

  return decryptedList;
}

Future<List<CircleRecipeTemplate>> _decryptRecipeTemplates(
    IsolateDecryptCircleRecipeTemplate params) async {
  List<CircleRecipeTemplate> decryptedList = [];

  try {
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    for (CircleRecipeTemplate circleRecipeTemplate
        in params.circleRecipeTemplates) {
      RatchetPair? ratchetPair = params.ratchetPairs[circleRecipeTemplate.id];

      if (ratchetPair == null) {
        //throw ("missing keys");
        debugPrint('ForwardSecrecyUser._decryptRecipeTemplates: keys missing');
      } else {
        String decrypted = await _decrypt(
            cipher,
            ratchetPair,
            circleRecipeTemplate.crank,
            circleRecipeTemplate.signature,
            circleRecipeTemplate.body);

        circleRecipeTemplate.mapDecryptedFields(json.decode(decrypted));

        decryptedList.add(circleRecipeTemplate);
      }
    }
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint('ForwardSecrecyUser._decryptRecipeTemplates: ${err.toString()}');
    throw Exception(err);
  }

  return decryptedList;
}

Future<RatchetKeyAndMap> _decryptUserObject(RatchetIndex ratchetIndex) async {
  try {
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
    final x25519 = Cryptography.instance.x25519();

    ///There was a scenario when pre v65 users could end up with the wrong private key / rachetIndex combo
    ///A fix was made (not inserting the logged in users id with every userkey from a restore)
    ///And this function was tweaked to load all combinations of index and private user keys

    List<RatchetKey> ratchetKeys =
        await RatchetKey.findRatchetKeysByIndex(ratchetIndex.ratchetIndex);
    debugPrint('ratchetIndexes: ${json.encode(ratchetIndex.ratchetIndex)}');
    for (RatchetKey ratchetKey in ratchetKeys) {
      try {
        debugPrint('ratchetIndexes: ${json.encode(ratchetKey)}');

        RatchetPair ratchetPair =
            RatchetPair(ratchetKey: ratchetKey, ratchetIndex: ratchetIndex);

        var privateKey = await x25519.newKeyPairFromSeed(
            base64Url.decode(ratchetPair.ratchetKey.private));

        ///calculate the shared secret
        var sharedSecret = await x25519.sharedSecretKey(
            keyPair: privateKey,
            remotePublicKey: SimplePublicKey(
                base64Url.decode(ratchetIndex.senderRatchetPublic!),
                //this will have to change for invitations
                type: x25519.keyPairType));

        ///decrypt the object key
        SecretBox secretBoxKey = SecretBox(
            base64Url.decode(ratchetIndex.ratchetValue),
            nonce: base64Url.decode(ratchetIndex.crank),
            mac: Mac(base64Url.decode(ratchetIndex.signature)));

        final secretKey = await cipher.decrypt(
          secretBoxKey,
          secretKey: sharedSecret,
        );

        SecretBox secretBox = SecretBox(base64Url.decode(ratchetIndex.cipher!),
            nonce: base64Url.decode(ratchetIndex.cipherCrank!),
            mac: Mac(base64Url.decode(ratchetIndex.cipherSignature!)));

        final decrypt = await cipher.decrypt(
          secretBox,
          secretKey: SecretKey(secretKey),
        );

        return RatchetKeyAndMap(
            ratchetKey: ratchetKey, map: json.decode(utf8.decode(decrypt)));
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        debugPrint("COULD NOT DECRYPT USER OBJECT");
      }
    }

    throw ("COULD NOT DECRYPT USER OBJECT");
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint('ForwardSecrecyUser._decryptUserObject: ${err.toString()}');
    throw Exception(err);
  }
}

class ForwardSecrecyUser {
  static Future<void> fixUserKeyMismatches() async {
    try {
      if (globalState.runOnce) {
        globalState.runOnce = false;
        final x25519 = Cryptography.instance.x25519();

        List<RatchetKey> ratchetKeys =
            await TableRatchetKeyUser.findRatchetKeysForAllUsers();

        bool found = false;

        for (RatchetKey ratchetKey in ratchetKeys) {
          try {
            var privateKey = await x25519
                .newKeyPairFromSeed(base64Url.decode(ratchetKey.private));

            SimplePublicKey legacyKeyMismatchFix =
                await privateKey.extractPublicKey();

            if (base64UrlEncode(legacyKeyMismatchFix.bytes) !=
                ratchetKey.public) {
              ratchetKey.public = base64UrlEncode(legacyKeyMismatchFix.bytes);
              TableRatchetKeyHelper.upsertPublicKeyForPrivateKey(
                  TableRatchetKeyUser.tableName, ratchetKey);

              found = true;
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
          }
        }

        if (found) {
          List<UserFurnace>? userFurnaces =
              await TableUserFurnace.readAllForUser(globalState.user.id!);

          for (UserFurnace userFurnace in userFurnaces) {
            List<UserCircleCache> userCircleCaches =
                await TableUserCircleCache.readAllForBackup(
                    userFurnace.pk, userFurnace.userid!);

            for (UserCircleCache userCircleCache in userCircleCaches) {
              UserCircleService userCircleService = UserCircleService();
              userCircleService.updateEncryptedFields(
                  userCircleCache, userFurnace, null);
            }
          }
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  static Future<Map<String, dynamic>> decryptObjectFromUser(
      RatchetKey ratchetKey, RatchetIndex ratchetIndex) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
      final x25519 = Cryptography.instance.x25519();

      // RatchetPair ratchetPair =
      // await RatchetKey.findUserRatchetPair([ratchetIndex]);

      var privateKey =
          await x25519.newKeyPairFromSeed(base64Url.decode(ratchetKey.private));
      var publicKey = SimplePublicKey(
          base64Url.decode(ratchetIndex.senderRatchetPublic!),
          type: x25519.keyPairType);

      //print(privateKey);

      //calculate the shared secret
      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);

      //print(sharedSecret);

      //decrypt the message key
      SecretBox secretBoxKey = SecretBox(
          base64Url.decode(ratchetIndex.ratchetValue),
          nonce: base64Url.decode(ratchetIndex.crank),
          mac: Mac(base64Url.decode(ratchetIndex.signature)));

      final secretKey = await cipher.decrypt(
        secretBoxKey,
        secretKey: sharedSecret,
      );

      SecretBox secretBox = SecretBox(base64Url.decode(ratchetIndex.cipher!),
          nonce: base64Url.decode(ratchetIndex.cipherCrank!),
          mac: Mac(base64Url.decode(ratchetIndex.cipherSignature!)));

      final decrypt = await cipher.decrypt(
        secretBox,
        secretKey: SecretKey(secretKey),
      );

      return json.decode(utf8.decode(decrypt));
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'ForwardSecrecyUser._decryptObjectFromUser: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<List<CircleListTemplate>> decryptListTemplates(
      List<CircleListTemplate> encryptedList, String userID) async {
    IsolateDecryptCircleListTemplate params = IsolateDecryptCircleListTemplate(
        circleListTemplates: encryptedList,
        ratchetPairs: await RatchetKey.getListTemplateUserRatchetPairs(
            encryptedList, userID));

    List<CircleListTemplate> decryptedList =
        await compute(_decryptListTemplates, params);

    //List<CircleListTemplate> decryptedList =
    //  await _decryptListTemplates(params);

    return decryptedList;
  }

  static Future<List<CircleRecipeTemplate>> decryptRecipeTemplates(
      List<CircleRecipeTemplate> encryptedList, String userID) async {
    try {
      IsolateDecryptCircleRecipeTemplate params =
          IsolateDecryptCircleRecipeTemplate(
              circleRecipeTemplates: encryptedList,
              ratchetPairs: await RatchetKey.getRecipeTemplateUserRatchetPairs(
                  encryptedList, userID));

      List<CircleRecipeTemplate> decryptedList =
          await compute(_decryptRecipeTemplates, params);

      //List<CircleRecipeTemplate> decryptedList =
      //  await _decryptRecipeTemplates(params);

      return decryptedList;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint(
          'ForwardSecrecyUser.decryptRecipeTemplates: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetKeyAndMap> decryptUserObject(
      RatchetIndex ratchetIndex, String userID) async {
    try {
      return await _decryptUserObject(ratchetIndex);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.decryptUserObject: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetIndex> _encryptObjectForUser(
      String userID,
      RatchetKey memberKey,
      RatchetKey userKey,
      Map<String, dynamic> map) async {
    try {
      final x25519 = Cryptography.instance.x25519();
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
      final secretKey = await cipher.newSecretKey();

      ///generate a shared secret between the local and remote users
      var privateKey =
          await x25519.newKeyPairFromSeed(base64Url.decode(userKey.private));

      SimplePublicKey legacyKeyMismatchFix =
          await privateKey.extractPublicKey();
      userKey.public = base64UrlEncode(legacyKeyMismatchFix.bytes);

      var publicKey = SimplePublicKey(base64Url.decode(memberKey.public!),
          type: x25519.keyPairType);

      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);
      //SecretBox secretBoxKey = SecretBox(base64Url.decode(ratchetPair.ratchetIndex.ratchetValue), nonce: base64Url.decode(circleObject.crank), mac: Mac(base64Url.decode(circleObject.signature)) );

      /*var priTemp = await x25519.newKeyPairFromSeed(
          base64Url.decode('cBtnjuBkjE5OsoqfJee__vhFD0Er_C4NabXkEKPlwm0='));

      var pubTemp = SimplePublicKey(
          base64Url.decode('wMrHeQXKOvBo8Md1EtHpwn1KwdksdUbf2cBjOfSx00A='),
          type: x25519.keyPairType);

      var wtf = await x25519.sharedSecretKey(
          keyPair: priTemp, remotePublicKey: pubTemp);

      var priTemp2 = await x25519.newKeyPairFromSeed(
          base64Url.decode('EPvYFxZZV1O8Q4It0l_eTkafgaDZOayFjnh_8COfGnw='));

      var pubTemp2 = SimplePublicKey(
          base64Url.decode('IL2iLE5yALrTlbQ_DqswE-zvPuiKpxBIMmvPrRzsNRU='),
          type: x25519.keyPairType);

      var wtf2 = await x25519.sharedSecretKey(
          keyPair: priTemp2, remotePublicKey: pubTemp2);*/

      ///encrypt a cipher key with the shared secret;
      final encrypted = await cipher.encrypt(
        await secretKey.extractBytes(),
        secretKey: sharedSecret,
        nonce: cipher.newNonce(),
      );

      String plainText = json.encode(map);

      ///encrypt the map with the cipher key
      final encryptedMap = await cipher.encrypt(utf8.encode(plainText),
          secretKey: secretKey, nonce: cipher.newNonce());

      RatchetIndex retValue = RatchetIndex(
        crank: base64UrlEncode(encrypted.nonce),
        signature: base64UrlEncode(encrypted.mac.bytes),
        ratchetIndex: memberKey.keyIndex,
        ratchetValue: base64UrlEncode(encrypted.cipherText),
        user: memberKey.user,
        cipher: base64UrlEncode(encryptedMap.cipherText),
        cipherCrank: base64UrlEncode(encryptedMap.nonce),
        cipherSignature: base64UrlEncode(encryptedMap.mac.bytes),
        senderRatchetPublic: userKey.public,
      );

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser._encryptUserTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetIndex> _encryptUserObject(
      String userID,
      String remotePublicKey,
      RatchetKey userKey,
      Map<String, dynamic> map) async {
    try {
      final x25519 = Cryptography.instance.x25519();
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
      final secretKey = await cipher.newSecretKey();

      var crank = cipher.newNonce();

      var privateKey =
          await x25519.newKeyPairFromSeed(base64Url.decode(userKey.private));
      var publicKey = SimplePublicKey(base64Url.decode(remotePublicKey),
          type: x25519.keyPairType);

      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);

      //SecretBox secretBoxKey = SecretBox(base64Url.decode(ratchetPair.ratchetIndex.ratchetValue), nonce: base64Url.decode(circleObject.crank), mac: Mac(base64Url.decode(circleObject.signature)) );

      final encrypted = await cipher.encrypt(
        await secretKey.extractBytes(),
        secretKey: sharedSecret,
        nonce: crank,
      );

      crank = cipher.newNonce();

      String ciphertext = json.encode(map);

      final encryptedMap = await cipher.encrypt(utf8.encode(ciphertext),
          secretKey: secretKey, nonce: crank);

      RatchetIndex retValue = RatchetIndex(
        crank: base64UrlEncode(encrypted.nonce),
        signature: base64UrlEncode(encrypted.mac.bytes),
        ratchetIndex: userKey.keyIndex,
        ratchetValue: base64UrlEncode(encrypted.cipherText),
        user: userID,
        cipher: base64UrlEncode(encryptedMap.cipherText),
        cipherCrank: base64UrlEncode(encryptedMap.nonce),
        cipherSignature: base64UrlEncode(encryptedMap.mac.bytes),
        senderRatchetPublic: remotePublicKey,
      );

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser._encryptUserObject: ${err.toString()}');
      throw Exception(err);
    }
  }

  //This method ratchets a AES secret key for Library templates (Recipe and List)
  static Future<UserTemplateRatchet> _encryptUserTemplate(
      String userID, Map<String, dynamic> map) async {
    try {
      final x25519 = Cryptography.instance.x25519();
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
      final secretKey = await cipher.newSecretKey();

      var crank = cipher.newNonce();

      RatchetKey userKey = await RatchetKey.getLatestUserKeyPair(
        userID,
      );

      var privateKey =
          await x25519.newKeyPairFromSeed(base64Url.decode(userKey.private));
      var publicKey = SimplePublicKey(base64Url.decode(userKey.public!),
          type: x25519.keyPairType);

      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);

      //SecretBox secretBoxKey = SecretBox(base64Url.decode(ratchetPair.ratchetIndex.ratchetValue), nonce: base64Url.decode(circleObject.crank), mac: Mac(base64Url.decode(circleObject.signature)) );

      final encrypted = await cipher.encrypt(
        await secretKey.extractBytes(),
        secretKey: sharedSecret,
        nonce: crank,
      );

      crank = cipher.newNonce();

      String ciphertext = json.encode(map);

      final encryptedMap = await cipher.encrypt(utf8.encode(ciphertext),
          secretKey: secretKey, nonce: crank);

      UserTemplateRatchet retValue = UserTemplateRatchet(
          cipherText: base64UrlEncode(encryptedMap.cipherText),
          crank: base64UrlEncode(encryptedMap.nonce),
          signature: base64UrlEncode(encryptedMap.mac.bytes),
          ratchetIndexes: [
            RatchetIndex(
                ratchetIndex: userKey.keyIndex,
                user: userID,
                crank: base64UrlEncode(encrypted.nonce),
                signature: base64UrlEncode(encrypted.mac.bytes),
                ratchetValue: base64UrlEncode(encrypted.cipherText))
          ]);

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser._encryptUserTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<UserTemplateRatchet> encryptListTemplate(
      String userID, CircleList circleList) async {
    try {
      var map = circleList.fetchFieldsToEncrypt();

      UserTemplateRatchet userTemplateRatchet =
          await _encryptUserTemplate(userID, map);

      //userTemplateRatchet.tasks = circleList.tasks!;

      return userTemplateRatchet;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.encryptListTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<UserTemplateRatchet> encryptRecipeTemplate(
      String userID, CircleRecipe recipe) async {
    try {
      var map = recipe.fetchFieldsToEncrypt();

      UserTemplateRatchet userTemplateRatchet =
          await _encryptUserTemplate(userID, map);

      //userTemplateRatchet.tasks = circleList.tasks!;

      return userTemplateRatchet;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.encryptRecipeTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetKey> getUserPublicKey(String userID) async {
    RatchetKey userKey = await RatchetKey.getLatestUserKeyPair(
      userID,
    );

    return userKey.removePrivateKey();
  }

  static saveUserKey(RatchetKey userKey, String userID) async {
    try {
      userKey.user = userID;

      //RatchetKey userKey = await RatchetKey.getLatestUserKeyPair(
      //userID,
      //);

      await TableRatchetKeyUser.upsert(userKey);
      //debugPrint('key updated');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.saveUserKeyToReceiver: ${err.toString()}');
      //throw Exception(err);
    }

    //return userKey.removePrivateKey();
  }

  static saveUserKeyToReceiver(RatchetKey userKey, String userID) async {
    try {
      /*RatchetKey testKey = await RatchetKey.getLatestUserKeyPair(
        userID,
      );

        */

      RatchetPair exists = await TableRatchetKeyReceiver.findRatchetPair([
        RatchetIndex(
            ratchetIndex: userKey.keyIndex,
            user: '',
            crank: '',
            signature: '',
            ratchetValue: '')
      ]);

      if (exists.ratchetKey.keyIndex.isEmpty) {
        await TableRatchetKeyReceiver.insert(userKey);
        debugPrint('key inserted');
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.saveUserKeyToReceiver: ${err.toString()}');
      //throw Exception(err);
    }

    //return userKey.removePrivateKey();
  }

  static Future<RatchetIndex> encryptUserObject(
      String userID, Map<String, dynamic> json) async {
    try {
      RatchetKey userKey = await RatchetKey.getLatestUserKeyPair(
        userID,
      );

      RatchetIndex ratchetIndex =
          await _encryptUserObject(userID, userKey.public!, userKey, json);

      return ratchetIndex;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.encryptUserObject: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetIndex> encryptObjectForUserWithRatchetKey(
      UserFurnace userFurnace,
      String userID,
      RatchetKey remotePublicKey,
      RatchetKey userKey,
      Map<String, dynamic> json) async {
    try {
      //send that ratchet public key to the following method
      RatchetIndex ratchetIndex =
          await _encryptObjectForUser(userID, remotePublicKey, userKey, json);

      return ratchetIndex;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.encryptRecipeTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<RatchetIndex> encryptObjectForUser(
      UserFurnace userFurnace,
      String userID,
      RatchetKey remotePublicKey,
      Map<String, dynamic> json) async {
    try {
//      RatchetKey ratchetKey =
      //        await RatchetPublicKeyService.fetchMemberPublicKey(
      //          userFurnace, userID);

      RatchetKey userKey = await RatchetKey.getLatestUserKeyPair(
        userID,
      );

      //send that ratchet public key to the following method
      RatchetIndex ratchetIndex =
          await _encryptObjectForUser(userID, remotePublicKey, userKey, json);

      return ratchetIndex;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecyUser.encryptRecipeTemplate: ${err.toString()}');
      throw Exception(err);
    }
  }

  static Future<String> decryptUserKeysFromLinkedUser(
      RatchetKey publicKey,
      RatchetIndex backupIndex,
      RatchetIndex userIndex,
      String userID,
      String linkedUserID) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      ///save to secure storage
      //String retValue = await SecureStorageService.readKey(
      //    KeyType.USER_KEYCHAIN_BACKUP + linkedUserID);

      UserSetting? userSetting = await TableUserSetting.read(linkedUserID);
      String retValue = userSetting!.backupKey;

      //decrypt user key pair
      SecretBox secretBox2 = SecretBox(base64Url.decode(userIndex.ratchetValue),
          nonce: base64Url.decode(userIndex.crank),
          mac: Mac(base64Url.decode(userIndex.signature)));

      final userPrivate = await cipher.decrypt(
        secretBox2,
        secretKey: SecretKey(base64Decode(retValue)),
      );

      publicKey.private = base64Encode(userPrivate);

      //remove any existing user key pairs (shouldn't be any others after v35)
      await TableRatchetKeyUser.deleteByUser(userID);

      //add the key
      await ForwardSecrecyUser.saveUserKey(publicKey, userID);

      //also add it to the receiving key chain
      RatchetKey.saveReceiverKeyPair(publicKey, '');
      //saveReceiverKeyPair(importRatchetKey, importRatchetKey.userCircle!)

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.decryptBackupAndUserKeys: $err');
      rethrow;
    }
  }

  static Future<String> decryptBackupKey(
      RatchetKey publicKey,
      RatchetIndex backupIndex,
      RatchetIndex userIndex,
      String userID,
      String password,
      String pin) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      String secret = password + pin;

      late List<int> backupSecret;

      if (backupIndex.kdfNonce == null) {
        ///deprecated
        if (password.length > 28) {
          secret = password.substring(0, 27) + pin;
        } else {
          secret = password + pin;
        }

        SecretBox secretBox = SecretBox(
            base64Url.decode(backupIndex.ratchetValue),
            nonce: base64Url.decode(backupIndex.crank),
            mac: Mac(base64Url.decode(backupIndex.signature)));

        backupSecret = await cipher.decrypt(
          secretBox,
          secretKey: SecretKey(utf8.encode(secret)),
        );
      } else {
        UserSecret userSecret =
            await deriveKey(password, pin, kdfNonce: backupIndex.kdfNonce!);

        SecretBox secretBox = SecretBox(
            base64Url.decode(backupIndex.ratchetValue),
            nonce: userSecret.nonce,
            mac: Mac(base64Url.decode(backupIndex.signature)));

        backupSecret =
            await cipher.decrypt(secretBox, secretKey: userSecret.secretKey);
      }

      ///save to secure storage
      String retValue = base64Url.encode(backupSecret);
      globalState.userSetting.setBackupKey(retValue);

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.decryptBackupAndUserKeys: $err');
      rethrow;
    }
  }

  static Future<String> decryptBackupAndUserKeys(
      RatchetKey publicKey,
      RatchetIndex backupIndex,
      RatchetIndex userIndex,
      String userID,
      String password,
      String pin) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      String secret = password + pin;

      late List<int> backupSecret;

      if (backupIndex.kdfNonce == null) {
        ///deprecated
        if (password.length > 28) {
          secret = password.substring(0, 27) + pin;
        } else {
          secret = secret.padRight(32, '9');
        }

        SecretBox secretBox = SecretBox(
            base64Url.decode(backupIndex.ratchetValue),
            nonce: base64Url.decode(backupIndex.crank),
            mac: Mac(base64Url.decode(backupIndex.signature)));

        backupSecret = await cipher.decrypt(
          secretBox,
          secretKey: SecretKey(utf8.encode(secret)),
        );
      } else {
        UserSecret userSecret =
            await deriveKey(password, pin, kdfNonce: backupIndex.kdfNonce!);

        SecretBox secretBox = SecretBox(
            base64Url.decode(backupIndex.ratchetValue),
            nonce: base64Url.decode(backupIndex.crank),
            mac: Mac(base64Url.decode(backupIndex.signature)));

        backupSecret =
            await cipher.decrypt(secretBox, secretKey: userSecret.secretKey);
      }

      ///save to secure storage
      String retValue = base64Url.encode(backupSecret);

      //SecureStorageService.writeKey(
      //    KeyType.USER_KEYCHAIN_BACKUP + userID, retValue);

      TableUserSetting.setBackupKey(userID, retValue);

      ///decrypt user key pair
      SecretBox secretBox2 = SecretBox(base64Url.decode(userIndex.ratchetValue),
          nonce: base64Url.decode(userIndex.crank),
          mac: Mac(base64Url.decode(userIndex.signature)));

      final userPrivate = await cipher.decrypt(
        secretBox2,
        secretKey: SecretKey(base64Decode(retValue)),
      );

      publicKey.private = base64Encode(userPrivate);

      ///remove any existing user key pairs (shouldn't be any others after v35)
      //await TableRatchetKeyUser.deleteByUser(userID);

      ///add the key
      publicKey.type = RatchetKeyType.user;
      await ForwardSecrecyUser.saveUserKey(publicKey, userID);

      //also add it to the receiving key chain
      RatchetKey.saveReceiverKeyPair(publicKey, '');
      //saveReceiverKeyPair(importRatchetKey, importRatchetKey.userCircle!)

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.decryptBackupAndUserKeys: $err');
      rethrow;
    }
  }

  static Future<String> generateBackupSecret() async {
    String backKeyString = '';

    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    var backupKey = await cipher.newSecretKey();

    //debugPrint(await backupKey.extractBytes());

    backKeyString = base64Encode(await backupKey.extractBytes());

    return backKeyString;
  }

  static Future<UserSecret> saltAndHashPassword(String password, String pin,
      {String passwordNonce = ''}) async {
    String secret = password + pin;
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: kDebugMode ? 10000 : 600000,
      bits: 256,
    );

    late List<int> nonce;

    if (passwordNonce.isEmpty) {
      nonce = cipher.newNonce();
    } else {
      nonce = base64Url.decode(passwordNonce);
    }

    debugPrint('${DateTime.now()}');

    final output = await algorithm.deriveKeyFromPassword(
      password: secret,
      nonce: nonce,
    );

    debugPrint('${DateTime.now()}');

    //print(base64Url.encode(await output.extractBytes()));

    return UserSecret(
        output, base64Url.encode(await output.extractBytes()), nonce);
  }

  static Future<UserSecret> deriveKey(String password, String pin,
      {String kdfNonce = ''}) async {
    String secret = password + pin;
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    final algorithm = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );

    late List<int> nonce;

    if (kdfNonce.isEmpty) {
      nonce = cipher.newNonce();
    } else {
      nonce = base64Url.decode(kdfNonce);
    }

    final output = await algorithm.deriveKeyFromPassword(
      password: secret,
      nonce: nonce,
    );

    //print(base64Url.encode(await output.extractBytes()));

    return UserSecret(
        output, base64Url.encode(await output.extractBytes()), nonce);
  }

  static Future<RatchetIndex> encryptBackupSecret(
      String userID, String backupKey, String password, String pin) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      UserSecret userSecret = await deriveKey(password, pin);

      var nonce = cipher.newNonce();

      final encrypted = await cipher.encrypt(base64Url.decode(backupKey),
          secretKey: userSecret.secretKey, nonce: nonce);

      Device device = await globalState.getDevice();

      return RatchetIndex(
          ratchetIndex: const Uuid().v4(),
          user: userID,
          kdfNonce: base64UrlEncode(userSecret.nonce),
          crank: base64UrlEncode(encrypted.nonce),
          signature: base64UrlEncode(encrypted.mac.bytes),
          ratchetValue: base64UrlEncode(encrypted.cipherText),
          device: device.uuid!);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.generateUserBackupKey: $err');
      rethrow;
    }
  }

  ///cannot be called from isolate
  static Future<RatchetKey> createSignatureKey(UserFurnace userFurnace) async {
    final signatureAlgorithm = Ed25519();

    var signingKeyPair = await signatureAlgorithm.newKeyPair();

    Device device = await globalState.getDevice();

    RatchetKey ratchetKey = RatchetKey(
      keyIndex: const Uuid().v4(),
      user: userFurnace.userid!,
      device: device.uuid!,
      type: RatchetKeyType.signature,
      public: base64UrlEncode((await signingKeyPair.extractPublicKey()).bytes),
      private: base64UrlEncode(await signingKeyPair.extractPrivateKeyBytes()),
    );

    TableRatchetKeyUser.upsert(ratchetKey);

    globalState.signatureKeys.add(ratchetKey);

    UserService userService = UserService();
    userService.updateUserIdentityKey(userFurnace, ratchetKey);

    return ratchetKey;
  }

  static Future<RatchetKey> getSignatureKey(UserFurnace userFurnace) async {
    RatchetKey signatureKey = globalState.getSignatureKey(
      userFurnace.userid!,
    );

    if (signatureKey.private.isNotEmpty) {
      return signatureKey;
    } else {
      signatureKey = await TableRatchetKeyUser.getKeyPairByType(
          userFurnace.userid!, RatchetKeyType.signature);

      if (signatureKey.private.isEmpty) {
        LogBloc.insertLog('signature key is missing', 'getSignatureKey');
        return await createSignatureKey(userFurnace);
      } else {
        globalState.signatureKeys.add(signatureKey);
        return signatureKey;
      }
    }
  }

  static Future<RatchetIndex> encryptUserKey(
    String secret,
    String userID,
    RatchetKey ratchetKey,
  ) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
      var nonce = cipher.newNonce();

      //  RatchetKey ratchetKey = await RatchetKey.getLatestUserKeyPair(userID);

      final encrypted = await cipher.encrypt(
          base64Url.decode(ratchetKey.private),
          secretKey: SecretKey(base64Url.decode(secret)),
          nonce: nonce);

      Device device = await globalState.getDevice();

      return RatchetIndex(
          ratchetIndex: const Uuid().v4(),
          user: userID,
          crank: base64UrlEncode(encrypted.nonce),
          signature: base64UrlEncode(encrypted.mac.bytes),
          ratchetValue: base64UrlEncode(encrypted.cipherText),
          device: device.uuid!);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.encryptUserKey: $err');
      rethrow;
    }
  }
}

class UserSecret {
  SecretKey secretKey;
  String secretKeyString = '';
  String nonceString = '';
  List<int> nonce;

  UserSecret(this.secretKey, this.secretKeyString, this.nonce) {
    nonceString = base64Url.encode(nonce);
  }
}
