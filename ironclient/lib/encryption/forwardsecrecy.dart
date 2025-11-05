///  IronCircles Elliptic Curve Diffie–Hellman (ECDH) key agreement scheme (Curve25519)
///  Achieves forward secrecy by ratcheting a key for each message
import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptstring.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/circleeventrespondent.dart';
import 'package:ironcirclesapp/models/circleobjectlineitem.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_memberdevice.dart';
import 'package:ironcirclesapp/services/cache/table_ratchetkey_receiver.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/ratchetpublickey_service.dart';
import 'package:uuid/uuid.dart';

class IsolateSharedSecretParams {
  List<RatchetKey> ratchetKeys;
  RatchetKey senderKey;
  SecretKey secretKey;
  Cipher cipher;

  IsolateSharedSecretParams({
    required this.ratchetKeys,
    required this.senderKey,
    required this.secretKey,
    required this.cipher,
    /*required this.crank*/
  });
}

class IsolateEncryptReplyObjectParams {
  ReplyObject replyObject;
  Cipher cipher;
  SecretKey secretKey;
  String userID;

  IsolateEncryptReplyObjectParams({
    required this.replyObject,
    required this.cipher,
    required this.secretKey,
    required this.userID,
  });
}

class IsolateEncryptCircleObjectParams {
  CircleObject circleObject;
  Cipher cipher;
  SecretKey secretKey;
  String userID;

  //List<int> crank;

  IsolateEncryptCircleObjectParams({
    required this.circleObject,
    required this.cipher,
    required this.secretKey,
    required this.userID,
    /*required this.crank*/
  });
}

class IsolateDecryptCircleObjectsParams {
  List<CircleObject> circleObjects;
  String userCircleID;
  String userID;
  bool importing;
  List<Device> memberDevices;
  Map<String, RatchetPair> ratchetPairs; //TODO don't think this is used

  IsolateDecryptCircleObjectsParams({
    required this.circleObjects,
    required this.userCircleID,
    required this.userID,
    required this.importing,
    required this.memberDevices,
    required this.ratchetPairs,
  });
}

class IsolateDecryptReplyObjectsParams {
  List<ReplyObject> replyObjects;
  String userCircleID;
  String userID;
  bool importing;
  List<Device> memberDevices;
  Map<String, RatchetPair> ratchetPairs;

  IsolateDecryptReplyObjectsParams({
    required this.replyObjects,
    required this.userCircleID,
    required this.userID,
    required this.importing,
    required this.memberDevices,
    required this.ratchetPairs,
  });
}

class IsolateDecryptCircleObjectParams {
  CircleObject circleObject;
  RatchetPair ratchetPair;

  IsolateDecryptCircleObjectParams({
    required this.circleObject,
    required this.ratchetPair,
  });
}

class IsolateDecryptReplyObjectParams {
  ReplyObject replyObject;
  RatchetPair ratchetPair;

  IsolateDecryptReplyObjectParams({
    required this.replyObject,
    required this.ratchetPair,
  });
}

Future<CircleObject> _encryptCircleObject(
    IsolateEncryptCircleObjectParams params) async {
  try {
    var encoded = json.encode(params.circleObject.toJson()).toString();
    CircleObject encryptedCopy = CircleObject.fromJson(json.decode(encoded));

    String ciphertext = json.encode(encryptedCopy.fetchFieldsToEncrypt());

    ///encrypt the message payload using the unique message key
    final encrypted = await params.cipher.encrypt(utf8.encode(ciphertext),
        secretKey: params.secretKey, nonce: params.cipher.newNonce());

    encryptedCopy.body = base64UrlEncode(encrypted.cipherText);
    encryptedCopy.crank = base64UrlEncode(encrypted.nonce);
    encryptedCopy.signature = base64UrlEncode(encrypted.mac.bytes);

    if (encryptedCopy.type == CircleObjectType.CIRCLEEVENT) {
      if (encryptedCopy.id == null) {
        ///it's so there is only one respondent
        String plainText =
            json.encode(params.circleObject.event!.respondents[0].toJson());

        CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
            ratchetIndex: await EncryptString.encryptString(
                plainText, params.userID,
                messageKey: params.secretKey));
        encryptedCopy.event!.encryptedLineItems.add(circleObjectLineItem);
      } else {
        ///it's not so find the right respondent
        for (CircleEventRespondent circleEventRespondent
            in params.circleObject.event!.respondents) {
          if (circleEventRespondent.respondent.id == params.userID) {
            String plainText = json.encode(circleEventRespondent.toJson());

            CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
                ratchetIndex: await EncryptString.encryptString(
                    plainText, params.userID,
                    messageKey: params.secretKey));

            //has this user responded before?
            if (encryptedCopy.event!.encryptedLineItems.isEmpty)
              encryptedCopy.event!.encryptedLineItems.add(circleObjectLineItem);
            else {
              encryptedCopy.event!.encryptedLineItems[0].ratchetIndex =
                  circleObjectLineItem
                      .ratchetIndex; //server will update the version number
            }
          }
        }
      }
    } else if (encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
      for (int i = 0; i < params.circleObject.album!.media.length; i++) {
        AlbumItem item = params.circleObject.album!.media[i];
        if (item.type == AlbumItemType.IMAGE) {
          String imageText = json.encode(item.image!.toJson());

          CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
              ratchetIndex: await EncryptString.encryptString(
                  imageText, params.userID,
                  messageKey: params.secretKey));

          encryptedCopy.album!.media[i].encryptedLineItem =
              circleObjectLineItem;
        } else if (item.type == AlbumItemType.VIDEO) {
          String videoText = json.encode(item.video!.toJson());

          CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
              ratchetIndex: await EncryptString.encryptString(
                  videoText, params.userID,
                  messageKey: params.secretKey));

          encryptedCopy.album!.media[i].encryptedLineItem =
              circleObjectLineItem;
        } else if (item.type == AlbumItemType.GIF) {
          String gifText = json.encode(item.gif!.toJson());

          CircleObjectLineItem circleObjectLineItem = CircleObjectLineItem(
              ratchetIndex: await EncryptString.encryptString(
                  gifText, params.userID,
                  messageKey: params.secretKey));

          encryptedCopy.album!.media[i].encryptedLineItem =
              circleObjectLineItem;
        }
        encryptedCopy.album!.media[i].gif = null;
        encryptedCopy.album!.media[i].video = null;
        encryptedCopy.album!.media[i].image = null;
      }
    }

    return encryptedCopy;
  } catch (err) {
    //LogBloc.insertError(err, trace);  //Can't access the database in an isolate
    debugPrint('ForwardSecrecy._encryptCircleObject: $err');
    rethrow;
  }
}

Future<List<int>> _getSecretKey(IsolateDecryptCircleObjectParams params) async {
  try {
    final x25519 = Cryptography.instance.x25519();
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    List<int> retValue = [];

    if (params.ratchetPair.ratchetIndex.crank.isNotEmpty) {
      var privateKey = await x25519.newKeyPairFromSeed(
          base64Url.decode(params.ratchetPair.ratchetKey.private));
      var publicKey = SimplePublicKey(
          base64Url.decode(params.circleObject.senderRatchetPublic),
          type: x25519.keyPairType);

      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);

      SecretBox secretBoxKey = SecretBox(
          base64Url.decode(params.ratchetPair.ratchetIndex.ratchetValue),
          nonce: base64Url.decode(params.ratchetPair.ratchetIndex.crank),
          mac:
              Mac(base64Url.decode(params.ratchetPair.ratchetIndex.signature)));

      final secret = await cipher.decrypt(
        secretBoxKey,
        secretKey: sharedSecret,
      );

      retValue = secret;
    }

    return retValue;
  } catch (err, trace) {
    debugPrint('$trace');
    //LogBloc.insertError(err, trace);  //TODO can't access the database in an isolate
    debugPrint('ForwardSecrecy._getSecretKey" $err');

    rethrow;
  }
}

Future<List<int>> _getReplyObjectSecretKey(
    IsolateDecryptReplyObjectParams params) async {
  try {
    final x25519 = Cryptography.instance.x25519();
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

    List<int> retValue = [];

    if (params.ratchetPair.ratchetIndex.crank.isNotEmpty) {
      var privateKey = await x25519.newKeyPairFromSeed(
          base64Url.decode(params.ratchetPair.ratchetKey.private));
      var publicKey = SimplePublicKey(
          base64Url.decode(params.replyObject.senderRatchetPublic),
          type: x25519.keyPairType);

      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey, remotePublicKey: publicKey);

      SecretBox secretBoxKey = SecretBox(
          base64Url.decode(params.ratchetPair.ratchetIndex.ratchetValue),
          nonce: base64Url.decode(params.ratchetPair.ratchetIndex.crank),
          mac:
              Mac(base64Url.decode(params.ratchetPair.ratchetIndex.signature)));

      final secret = await cipher.decrypt(
        secretBoxKey,
        secretKey: sharedSecret,
      );

      retValue = secret;
    }

    return retValue;
  } catch (err, trace) {
    debugPrint('$trace');
    debugPrint('ForwardSecrecy._getSecretKey $err');

    rethrow;
  }
}

Future<List<CircleObject>> _decryptCircleObjects(
    IsolateDecryptCircleObjectsParams params) async {
  List<CircleObject> retValue = [];

  debugPrint('Forward Secrecy: start decryption:  ${DateTime.now()}');

  final x25519 = Cryptography.instance.x25519();
  //final cipher = Cryptography.instance.aesGcm();
  final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

  for (CircleObject circleObject in params.circleObjects) {
    if (circleObject.ratchetIndexes.isEmpty ||
        circleObject.type == CircleObjectType.DELETED) {
      if (circleObject.type != CircleObjectType.SYSTEMMESSAGE) {
        //blank out the body, there were a few instances where the encrypted message appeared instead of the decrypted; not needed once the cipher isn't stored in the "body" field

        circleObject.body = "";
      }

      if (circleObject.oneTimeView ==
          true) //already viewed, just suppress and move one
        continue;
      else
        retValue.add(circleObject);
    } else {
      try {
        ///The verification isNotEmpty check should go away after everyone is on 1.1.14
        if (!params.importing &&
            circleObject.verification.isNotEmpty &&
            circleObject.creator!.id != params.userID) {
          try {
            ///verify the identity of the sender
            circleObject.verificationFailed = await validateSignedMac(
                circleObject.creator!.id!,
                circleObject.device,
                params.memberDevices,
                circleObject.verification,
                circleObject.signature);

            //circleObject.verificationFailed = true;
          } catch (err, trace) {
            debugPrint(err.toString());
            debugPrint(trace.toString());
          }
        }

        RatchetPair? ratchetPair = circleObject.ratchetPair;

        if (ratchetPair == null ||
            circleObject.senderRatchetPublic.isEmpty ||
            circleObject.crank.isEmpty) {
          if (circleObject.oneTimeView ==
              true) //already viewed, just suppress and move one
            continue;
          else
            throw ("missing keys");
        } else {
          if (ratchetPair.ratchetIndex.active == false) continue;

          var privateKey = await x25519.newKeyPairFromSeed(
              base64Url.decode(ratchetPair.ratchetKey.private));
          var publicKey = SimplePublicKey(
              base64Url.decode(circleObject.senderRatchetPublic),
              type: x25519.keyPairType);

          ///calculate the ratcheted shared secret
          var sharedSecret = await x25519.sharedSecretKey(
              keyPair: privateKey, remotePublicKey: publicKey);

          SecretBox secretBoxKey = SecretBox(
              base64Url.decode(ratchetPair.ratchetIndex.ratchetValue),
              nonce: base64Url.decode(ratchetPair.ratchetIndex.crank),
              mac: Mac(base64Url.decode(ratchetPair.ratchetIndex.signature)));

/*
          debugPrint(ratchetPair.ratchetIndex.device);
          debugPrint(ratchetPair.ratchetIndex.ratchetIndex);
          debugPrint(ratchetPair.ratchetIndex.ratchetValue);
          debugPrint(ratchetPair.ratchetIndex.crank);
          debugPrint(ratchetPair.ratchetIndex.signature);

 */

          //throw('test');

          ///decrypt the message key
          final secret = await cipher.decrypt(
            secretBoxKey,
            secretKey: sharedSecret,
          );

          SecretBox secretBox = SecretBox(base64Url.decode(circleObject.body!),
              nonce: base64Url.decode(circleObject.crank),
              mac: Mac(base64Url.decode(circleObject.signature)));

          ///use the message key to decrypt the message payload
          final decrypt = await cipher.decrypt(
            secretBox,
            secretKey: SecretKey(secret),
          );

          if (circleObject.type == CircleObjectType.CIRCLEIMAGE ||
              circleObject.type == CircleObjectType.CIRCLEVIDEO ||
              circleObject.type == CircleObjectType.CIRCLERECIPE ||
              circleObject.type == CircleObjectType.CIRCLEFILE ||
              circleObject.type == CircleObjectType.CIRCLEEVENT ||
              circleObject.type == CircleObjectType.CIRCLEALBUM) {
            ///in memory temporarily to use for decrypting blobs
            circleObject.secretKey = secret;
          }

          circleObject.mapDecryptedFields(json.decode(utf8.decode(decrypt)));

          if (circleObject.type == CircleObjectType.CIRCLEEVENT) {
            ///also need to decrypt the responses

            List<RatchetIndex> ratchetIndexes = [];

            for (var encryptedLineItem
                in circleObject.event!.encryptedLineItems) {
              ratchetIndexes.add(encryptedLineItem.ratchetIndex);
            }

            List<String> jsonStrings = await EncryptString.decryptStrings(
                SecretKey(circleObject.secretKey!), ratchetIndexes);

            for (var jsonStrings in jsonStrings) {
              var decode = json.decode(jsonStrings);

              CircleEventRespondent circleEventRespondent =
                  CircleEventRespondent.fromJson(decode);

              circleObject.event!.respondents.add(circleEventRespondent);
            }
          } else if (circleObject.type == CircleObjectType.CIRCLEALBUM) {
            for (int i = 0; i < circleObject.album!.media.length; i++) {
              AlbumItem item = circleObject.album!.media[i];

              List<String> jsonString = await EncryptString.decryptStrings(
                  SecretKey(circleObject.secretKey!),
                  [item.encryptedLineItem!.ratchetIndex]);

              var decode = json.decode(jsonString[0]);

              if (item.type == AlbumItemType.IMAGE) {
                CircleImage img = CircleImage.fromJson(decode);

                circleObject.album!.media[i].image = img;
              } else if (item.type == AlbumItemType.VIDEO) {
                CircleVideo video = CircleVideo.fromJson(decode);

                circleObject.album!.media[i].video = video;
              } else if (item.type == AlbumItemType.GIF) {
                CircleGif gif = CircleGif.fromJson(decode);

                circleObject.album!.media[i].gif = gif;
              }
            }
          }
        }
      } catch (err, trace) {
        debugPrint('$trace');
        debugPrint('ForwardSecrecy._decryptObject: $err');
        circleObject.typeOriginal = circleObject.type;
        circleObject.type = CircleObjectType.UNABLETODECRYPT;
        circleObject.encryptedBody = circleObject.body;
        circleObject.body =
            "Chat contents unavailable"; //"Missing decryption keys\nMessage(s) not available";
        circleObject.isolateError = err.toString();
        circleObject.isolateTrace = trace.toString();
      }
      retValue.add(circleObject);
    }
  }
  debugPrint('Forward Secrecy: end decryption:  ${DateTime.now()}');
  return retValue;
}

Future<List<ReplyObject>> _decryptReplyObjects(
    IsolateDecryptReplyObjectsParams params) async {
  List<ReplyObject> retValue = [];

  debugPrint('Forward Secrecy: start decryption: ${DateTime.now()}');

  final x25519 = Cryptography.instance.x25519();
  final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

  for (ReplyObject replyObject in params.replyObjects) {
    if (replyObject.ratchetIndexes.isEmpty ||
        replyObject.type == CircleObjectType.DELETED) {
      if (replyObject.type != CircleObjectType.SYSTEMMESSAGE) {
        replyObject.body = "";
      }

      retValue.add(replyObject);
    } else {
      try {
        if (!params.importing &&
            replyObject.verification.isNotEmpty &&
            replyObject.creator!.id != params.userID) {
          try {
            ///verify the identity of the sender
            replyObject.verificationFailed = await validateSignedMac(
              replyObject.creator!.id!,
              replyObject.device,
              params.memberDevices,
              replyObject.verification,
              replyObject.signature,
            );
          } catch (error, trace) {
            debugPrint(error.toString());
            debugPrint(trace.toString());
          }
        }

        RatchetPair? ratchetPair = replyObject.ratchetPair;

        if (replyObject.type == "systemmessage") {
          ///do nothing
        } else if (ratchetPair == null ||
            replyObject.senderRatchetPublic.isEmpty ||
            replyObject.crank.isEmpty) {
          throw ("missing keys");
        } else {
          if (ratchetPair.ratchetIndex.active == false) continue;

          var privateKey = await x25519.newKeyPairFromSeed(
              base64Url.decode(ratchetPair.ratchetKey.private));
          var publicKey = SimplePublicKey(
              base64Url.decode(replyObject.senderRatchetPublic),
              type: x25519.keyPairType);

          ///calculate the ratcheted shared secret
          var sharedSecret = await x25519.sharedSecretKey(
              keyPair: privateKey, remotePublicKey: publicKey);

          SecretBox secretBoxKey = SecretBox(
              base64Url.decode(ratchetPair.ratchetIndex.ratchetValue),
              nonce: base64Url.decode(ratchetPair.ratchetIndex.crank),
              mac: Mac(base64Url.decode(ratchetPair.ratchetIndex.signature)));

          ///decrypt the message key
          final secret =
              await cipher.decrypt(secretBoxKey, secretKey: sharedSecret);

          SecretBox secretBox = SecretBox(base64Url.decode(replyObject.body!),
              nonce: base64Url.decode(replyObject.crank),
              mac: Mac(base64Url.decode(replyObject.signature)));

          ///use the message key to decrypt the message payload
          final decrypt = await cipher.decrypt(
            secretBox,
            secretKey: SecretKey(secret),
          );

          replyObject.mapDecryptedFields(json.decode(utf8.decode(decrypt)));
        }
      } catch (err, trace) {
        debugPrint('$trace');
        debugPrint('ForwardSecrecy._decryptReplyObject: $err');
        replyObject.typeOriginal = replyObject.type;
        replyObject.type = CircleObjectType.UNABLETODECRYPT;
        replyObject.encryptedBody = replyObject.body;
        replyObject.body = "Chat contents unavailable";
        replyObject.isolateError = err.toString();
        replyObject.isolateTrace = trace.toString();
      }
      retValue.add(replyObject);
    }
  }
  debugPrint('Forward Secrecy: end decryption: ${DateTime.now()}');
  return retValue;
}

Future<List<RatchetIndex>> _calculateSharedSecrets(
    IsolateSharedSecretParams params) async {
  try {
    final x25519 = Cryptography.instance.x25519();

    List<RatchetIndex> retValue = [];
    var privateKey = await x25519
        .newKeyPairFromSeed(base64Url.decode(params.senderKey.private));

    //const cipher = aesGcm;
    //final crank = cipher.newNonce();

    for (RatchetKey remotePublicKey in params.ratchetKeys) {
      var sharedSecret = await x25519.sharedSecretKey(
          keyPair: privateKey,
          remotePublicKey: SimplePublicKey(
              base64Url.decode(remotePublicKey.public!),
              type: x25519.keyPairType));

      final encrypted = await params.cipher.encrypt(
        await params.secretKey.extractBytes(),
        secretKey: sharedSecret,
        nonce: params.cipher.newNonce(),
      );

      RatchetIndex ratchetIndex = RatchetIndex(
          ratchetIndex: remotePublicKey.keyIndex,
          user: remotePublicKey.user,
          crank: base64UrlEncode(encrypted.nonce),
          signature: base64UrlEncode(encrypted.mac.bytes),
          ratchetValue: base64UrlEncode(encrypted.cipherText),
          device: remotePublicKey.device!);
      retValue.add(ratchetIndex);
    }

    return retValue;
  } catch (err, trace) {
    debugPrint('$trace');
    //LogBloc.insertError(err, trace);  //can't access the database in an isolate
    debugPrint('ForwardSecrecy._calculateSharedSecrets: $err');
    rethrow;
  }
}

Future<String> validateSignedMac(String memberID, String uuid,
    List<Device> memberDevices, String signedMac, String encryptedMac) async {
  //bool retValue = false;

  try {
    ///TODO remove this when validation is complete
    return '';

    final signatureAlgorithm = Ed25519();

    /*RatchetKey userSigningKey =
        await ForwardSecrecyUser.getSignatureKey(userFurnace);

    var simplePublicKey = SimplePublicKey(
        base64Url.decode(userSigningKey.public!),
        type: signatureAlgorithm.keyPairType);

     */

    Device senderDevice = memberDevices.firstWhere(
        (element) => (element.uuid == uuid && element.ownerID == memberID),
        orElse: () => Device());

    Device oldDevice = memberDevices.firstWhere(
        (element) => (element.uuid != uuid && element.ownerID == memberID),
        orElse: () => Device());

    if (oldDevice.uuid == null || oldDevice.uuid!.isEmpty) {
      debugPrint('there was not an old device so assume the user is new');
      return '';
    }

    ///give everyone time to load 1.1.14 then nuke this
    if (senderDevice.uuid == null || senderDevice.uuid!.isEmpty) {
      throw Exception(VerificationFailed.DEVICE_NOT_FOUND);
    }

    String memberSigningKey = senderDevice.identity!;

    if (senderDevice.warningShown == false) {
      return '${VerificationFailed.NEW_DEVICE} ${senderDevice.model}.';
    }

    var simplePublicKey = SimplePublicKey(base64Url.decode(memberSigningKey),
        type: signatureAlgorithm.keyPairType);

    var signatureToVerify =
        Signature(base64Decode(signedMac), publicKey: simplePublicKey);

    ///verify the signature
    bool valid = await signatureAlgorithm.verify(
      base64Decode(encryptedMac),
      signature: signatureToVerify,
    );

    debugPrint(
        '***************************************************Signature validation: $valid');

    if (valid) {
      return '';
    } else {
      return '${VerificationFailed.NEW_DEVICE} ${senderDevice.model}.';
    }

/*print('signature key: ${signature.publicKey}');
      print('signingKeyPair: ${await signingKeyPair.extractPublicKey()}');
      print('simplePublicKey: $simplePublicKey');
      print('signatureToVerify: ${signatureToVerify.publicKey}');
      //print('privateKey: ${await privateKey.extractPublicKey()}');

       */
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    return VerificationFailed.FAILED;
// rethrow;
  }
}

class ForwardSecrecy {
  static Future<String> signEncryptedMac(
      UserFurnace userFurnace, String encryptionMac) async {
    try {
      final signatureAlgorithm = Ed25519();

      RatchetKey userSigningKey =
          await ForwardSecrecyUser.getSignatureKey(userFurnace);

      ///encrypt the signature with the sender's public identity key

      var signingKeyPair = await signatureAlgorithm.newKeyPairFromSeed(
        base64Url.decode(userSigningKey.private),
      );

      final signature = await signatureAlgorithm.sign(
        base64Url.decode(encryptionMac),
        keyPair: signingKeyPair,
      );

      return base64UrlEncode(signature.bytes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      return 'couldn\'t sign mac';
      // rethrow;
    }
  }

  static Future<List<int>> getReplySecretKey(
      String userCircleID, ReplyObject replyObject) async {
    try {
      List<int> retValue =
          await _getReplyObjectSecretKey(IsolateDecryptReplyObjectParams(
              replyObject: replyObject,
              ratchetPair: await RatchetKey.findReceiverRatchetPair(
                replyObject.ratchetIndexes,
              )));

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<List<int>> getSecretKey(
      String userCircleID, CircleObject circleObject) async {
    try {
      List<int> retValue = await _getSecretKey(IsolateDecryptCircleObjectParams(
          circleObject: circleObject,
          ratchetPair: await RatchetKey.findReceiverRatchetPair(
            circleObject.ratchetIndexes,
          )));

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      rethrow;
    }
  }

  static Future<List<CircleObject>> decryptCircleObjects(String userID,
      String userCircleID, List<CircleObject> circleObjects) async {
    try {
      ///populate the RatchetPair for each object
      circleObjects = await TableRatchetKeyReceiver.fetchKeysByCircle(
          userID, circleObjects);

      int counter = 0;
      try {
        //
        ///Mitigate against objects with no ratchet pairs
        List<CircleObject> noRatchetPair = circleObjects
            .where((element) => (element.ratchetPair == null &&
                element.type != CircleObjectType.SYSTEMMESSAGE &&
                element.type != CircleObjectType.CIRCLEVOTE))
            .toList();

        for (CircleObject circleObject in noRatchetPair) {
          ///there is a case when a new user joins a circle, then someone reacts to an older post, the
          ///new user won't have ratchetindexes, just show nothing.
          if (circleObject.lastReactedDate != null &&
              circleObject.lastReactedDate! == circleObject.lastUpdate) {
            circleObjects
                .removeWhere((element) => element.id == circleObject.id);
            continue;
          }

          if (counter > 10) {
            ///only log the first 10
            break;
          }
          LogBloc.postLog(
              'Could not find ratchet pair for this object\nid: ${circleObject.id}\nuser: $userID\nbody: ${circleObject.body}\nencryptedBody: ${circleObject.encryptedBody}\npublicKey: ${circleObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(circleObject.ratchetIndexes)}}',
              'decryptCircleObjects');

          counter++;
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }

      List<Device> memberDevices = await TableMemberDevice.getAll(userID);

      ///temporarily only validate signatures for admins
      bool importing = true;
      if (globalState.user.role == Role.IC_ADMIN) {
        importing = globalState.importing;
      }

      IsolateDecryptCircleObjectsParams params = IsolateDecryptCircleObjectsParams(
          circleObjects: circleObjects,
          userCircleID: userCircleID,
          userID: userID,
          importing: importing,
          memberDevices: memberDevices,
          ratchetPairs: {} /*await RatchetKey.fetchKeysByCircle(
                  userCircleID + RatchetKey.RECEIVER, circleObjects)*/
          );

      late List<CircleObject> retValue;

      ///use an isolate if there are more than 2 objects. Not worth it otherwise.
      if (circleObjects.length > 2)
        retValue = await compute(_decryptCircleObjects, params);
      else
        retValue = await _decryptCircleObjects(params);

      var failedToDecrypt = retValue
          .where((element) => element.body == 'Chat history unavailable')
          .toList();

      ///only log the last 3
      counter = 0;

      for (CircleObject circleObject in failedToDecrypt) {
        try {
          if (counter > 10) {
            break;
          }
          if (circleObject.ratchetPair == null) {
            LogBloc.postLog(
                "Could not decrypt this object\nerror: ${circleObject.isolateError}\nid: ${circleObject.id}\nuser: $userID\nbody: ${circleObject.body}\ncrank: ${circleObject.crank}\nsignature: ${circleObject.signature}\nratchetIndexes: ${json.encode(circleObject.ratchetIndexes)}}",
                'decryptCircleObjects');
          } else {
            LogBloc.postLog(
                "Could not decrypt this object\nerror: ${circleObject.isolateError}\nid: ${circleObject.id}\nuser: $userID\nbody: ${circleObject.body}\ncrank: ${circleObject.crank}\nsignature: ${circleObject.signature}\nratchetIndexes: ${json.encode(circleObject.ratchetIndexes)}\nratchetKey: ${circleObject.ratchetPair!.ratchetKey.toJson()}\nratchetIndex: ${circleObject.ratchetPair!.ratchetIndex.toJson()}}",
                'decryptCircleObjects');
          }

          counter++;
        } catch (e, trace) {
          LogBloc.insertError(e, trace);
        }
      }

      List<CircleObject> failedVerification = retValue
          .where((element) => element.verificationFailed.isNotEmpty)
          .toList();

      failedVerification.sort((a, b) => b.created!.compareTo(a.created!));

      if (failedVerification.isNotEmpty) {
        List<Device> updated = [];

        for (CircleObject circleObject in failedVerification) {
          Device device = memberDevices.firstWhere(
              (element) => (element.uuid == circleObject.device &&
                  element.ownerID == circleObject.creator!.id!),
              orElse: () => Device());

          if (updated.contains(device)) {
            circleObject.verificationFailed = '';
            continue;
          }

          if (circleObject.verificationFailed == VerificationFailed.NEW_USER) {
            circleObject.verificationFailed = '';
          }

          if (device.uuid != null && device.uuid!.isNotEmpty) {
            TableMemberDevice.setWarningShown(device);
          } else {}

          updated.add(device);
        }
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'ForwardSecrecy.decryptCircleObjects');
      rethrow;
    }
  }

  static Future<List<ReplyObject>> decryptReplyObjects(String userID,
      String userCircleID, List<ReplyObject> replyObjects) async {
    try {
      ///populate the RatchetPair for each object
      replyObjects = await TableRatchetKeyReceiver.fetchReplyKeysByCircle(
          userID, replyObjects);

      int counter = 0;
      try {
        ///Mitigate against objects with no ratchet pairs
        List<ReplyObject> noRatchetPair = replyObjects
            .where((element) => (element.ratchetPair == null &&
                element.type != CircleObjectType.SYSTEMMESSAGE))
            .toList();

        for (ReplyObject replyObject in noRatchetPair) {
          if (counter > 10) {
            break;
          }
          LogBloc.postLog(

              ///\nencryptedBody: ${replyObject.encryptedBody}'
              'Could not find ratchet pair for this object\nid: ${replyObject.id}\nuser: $userID\nbody: ${replyObject.body}'
                  '\npublicKey: ${replyObject.senderRatchetPublic}\nratchetIndexes: ${json.encode(replyObject.ratchetIndexes)}}',
              'decryptReplyObjects');

          counter++;
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }

      List<Device> memberDevices = await TableMemberDevice.getAll(userID);

      ///temporarily only validate signatures for admins
      bool importing = true;
      if (globalState.user.role == Role.IC_ADMIN) {
        importing = globalState.importing;
      }

      IsolateDecryptReplyObjectsParams params =
          IsolateDecryptReplyObjectsParams(
              replyObjects: replyObjects,
              userCircleID: userCircleID,
              userID: userID,
              importing: importing,
              memberDevices: memberDevices,
              ratchetPairs: {});

      late List<ReplyObject> retValue;

      ///use an isolate if there are more than 2 objects. Not worth it otherwise.
      if (replyObjects.length > 2)
        retValue = await compute(_decryptReplyObjects, params);
      else
        retValue = await _decryptReplyObjects(params);

      var failedToDecrypt = retValue
          .where((element) => element.body == 'Chat history unavailable')
          .toList();

      ///only log the last 3
      counter = 0;

      for (ReplyObject replyObject in failedToDecrypt) {
        try {
          if (counter > 10) {
            break;
          }
          if (replyObject.ratchetPair == null) {
            LogBloc.postLog(
                "Could not decrypt this object\nerror: ${replyObject.isolateError}\nid: ${replyObject.id}\nuser: $userID\nbody: ${replyObject.body}\ncrank: ${replyObject.crank}\nsignature: ${replyObject.signature}\nratchetIndexes: ${json.encode(replyObject.ratchetIndexes)}}",
                'decryptCircleObjects');
          } else {
            LogBloc.postLog(
                "Could not decrypt this object\nerror: ${replyObject.isolateError}\nid: ${replyObject.id}\nuser: $userID\nbody: ${replyObject.body}\ncrank: ${replyObject.crank}\nsignature: ${replyObject.signature}\nratchetIndexes: ${json.encode(replyObject.ratchetIndexes)}\nratchetKey: ${replyObject.ratchetPair!.ratchetKey.toJson()}\nratchetIndex: ${replyObject.ratchetPair!.ratchetIndex.toJson()}}",
                'decryptCircleObjects');
          }

          counter++;
        } catch (e, trace) {
          LogBloc.insertError(e, trace);
        }
      }

      List<ReplyObject> failedVerification = retValue
          .where((element) => element.verificationFailed.isNotEmpty)
          .toList();

      failedVerification.sort((a, b) => b.created!.compareTo(a.created!));

      if (failedVerification.isNotEmpty) {
        List<Device> updated = [];

        for (ReplyObject replyObject in failedVerification) {
          Device device = memberDevices.firstWhere(
              (element) => (element.uuid == replyObject.device &&
                  element.ownerID == replyObject.creator!.id!),
              orElse: () => Device());

          if (updated.contains(device)) {
            replyObject.verificationFailed = '';
            continue;
          }

          if (replyObject.verificationFailed == VerificationFailed.NEW_USER) {
            replyObject.verificationFailed = '';
          }

          if (device.uuid != null && device.uuid!.isNotEmpty) {
            TableMemberDevice.setWarningShown(device);
          } else {}

          updated.add(device);
        }
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: "ForwardSecrecy.decryptReplyObjects");
      rethrow;
    }
  }

  static Future<RatchetKey> getLatestUserKeyPair(String userID) async {
    try {
      return await RatchetKey.getLatestUserKeyPair(userID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.getLatestUserKeyPair: $err');
      //throw (err);
      rethrow;
    }
  }

  static Future<RatchetKey> generateUserKeyPair(String userID) async {
    //Box<RatchetKey> encryptedBox = await RatchetKey.openEncryptedBox(userID);

    RatchetKey userKey = await RatchetKey.ratchetUserKeyPair(userID, '');

    return userKey;
  }

  static Future<List<int>> genSecretKey() async {
    final cipher = Xchacha20(macAlgorithm: Hmac.sha256());
    return await (await cipher.newSecretKey()).extractBytes();
  }

  static Future<CircleObject> encryptCircleObject(
      UserFurnace userFurnace, CircleObject circleObject) async {
    try {
      ///This took 3 hours of my life.  Ensure other CircleObject fields are primitive types or null before calling an isolate
      circleObject.cancelTokens = null;
      circleObject.cancelToken = null;

      if (circleObject.type == CircleObjectType.CIRCLERECIPE) {
        for (CircleRecipeIngredient circleRecipeIngredient
            in circleObject.recipe!.ingredients!) {
          circleRecipeIngredient.controller = null;
        }

        for (CircleRecipeInstruction circleRecipeInstruction
            in circleObject.recipe!.instructions!) {
          circleRecipeInstruction.controller = null;
        }
      } else if (circleObject.type == CircleObjectType.CIRCLELIST) {
        for (CircleListTask task in circleObject.list!.tasks!) {
          task.controller = null;
        }
      }

      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      late SecretKey secretKey;
      String userCircleID = await TableUserCircleCache.getUserCircleID(
          userFurnace.userid!, circleObject.circle!.id!);

      ///reuse the secret key for edits. Always use a new MAC and nonce!
      if (circleObject.id == null) {
        if (circleObject.secretKey != null)
          secretKey = SecretKey(circleObject.secretKey!);
        else
          secretKey = await cipher.newSecretKey();
      } else {
        if (circleObject.secretKey != null)
          secretKey = SecretKey(circleObject.secretKey!);
        else
          secretKey = SecretKey(await getSecretKey(userCircleID, circleObject));
      }

      debugPrint('encrypting start: ${DateTime.now().toLocal()}');
      List<RatchetKey> ratchetKeys =
          await _fetchPublicKeys(userFurnace, circleObject.circle!);

      RatchetKey senderKey = await RatchetKey.ratchetSenderKeyPair(
          userID: userFurnace.userid!, userCircle: userCircleID);

      IsolateSharedSecretParams isolateParams = IsolateSharedSecretParams(
        secretKey: secretKey,
        ratchetKeys: ratchetKeys,
        cipher: cipher,
        senderKey: senderKey,
      );

      IsolateEncryptCircleObjectParams isolateEncryptCircleObjectParams =
          IsolateEncryptCircleObjectParams(
        userID: userFurnace.userid!,
        circleObject: circleObject,
        cipher: cipher,
        secretKey: secretKey,
      );

      late CircleObject encryptedCopy;

      ///Don't use an isolate to encrypt the object, not worth the overhead for one object encryption
      ///TODO List should be encrypted in an isolate and each line item change should be encrypted separately to allow simultaneous updates by different users

      //CircleObject encryptedCopy =
      //    await compute(_encryptCircleObject, isolateEncryptCircleObjectParams);
      encryptedCopy =
          await _encryptCircleObject(isolateEncryptCircleObjectParams);

      late List<RatchetIndex> ratchetIndexes;

      encryptedCopy.verification =
          await signEncryptedMac(userFurnace, encryptedCopy.signature);

      ///Use an isolate if there are more than 2 recipients
      if (ratchetKeys.length > 2)
        ratchetIndexes = await compute(_calculateSharedSecrets, isolateParams);
      else
        ratchetIndexes = await _calculateSharedSecrets(isolateParams);

      encryptedCopy.senderRatchetPublic = senderKey.public!;
      encryptedCopy.ratchetIndexes = ratchetIndexes;

      if (encryptedCopy.type == CircleObjectType.CIRCLEIMAGE ||
          encryptedCopy.type == CircleObjectType.CIRCLEVIDEO ||
          encryptedCopy.type == CircleObjectType.CIRCLERECIPE ||
          encryptedCopy.type == CircleObjectType.CIRCLEALBUM) {
        ///in memory temporarily to use for encrypting blobs
        encryptedCopy.secretKey = await secretKey.extractBytes();
      }

      debugPrint('encrypting stop: ${DateTime.now().toLocal()}');

      return encryptedCopy;
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'ForwardSecrecy.encryptCircleObject');
      debugPrint('ForwardSecrecy.encryptCircleObject: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> _fetchPublicKeys(
      UserFurnace userFurnace, Circle circle) async {
    if (circle.memberSessionKeys.isEmpty) {
      circle.memberSessionKeys = await RatchetPublicKeyService.fetchMemberPublicKeys(
          userFurnace, circle.id!);
    }

    return circle.memberSessionKeys;
  }

  static final RatchetPublicKeyService _ratchetPublicKeyService =
      RatchetPublicKeyService();

  /*
  static updateRatchetPublicKeys(
      String userCircle, List<RatchetKey> ratchetKeys) async {
    Box<RatchetKey> encryptedBox = await _openEncryptedBox(userCircle + SENDER);
  }

   */

  //
  static Future<List<UserCircle>> keysMissing(
      String userID, List<UserCircle> userCircles) async {
    try {
      List<UserCircle> missing = [];

      RatchetKey ratchetKey = await ForwardSecrecy.getLatestUserKeyPair(userID);
      if (ratchetKey.keyIndex.isEmpty) {
        return userCircles;
      }

      for (UserCircle userCircle in userCircles) {
        //String userCircleID = userCircle.id!;

        if (userCircle.removeFromCache == null &&
            userCircle.circle != null &&
            userCircle.hidden != true) {
          bool isMissing =
              await RatchetKey.receiverKeysMissing(userID, userCircle.id!);

          if (isMissing) missing.add(userCircle);
        }
      }

      return missing;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.keysmissing: $err');
      rethrow;
    }
  }

  static Future<bool> ratchetMissingServerSideKeys(
      UserFurnace userFurnace, User user, List<UserCircle> userCircles) async {
    try {
      List<UserCircle> missing = [];

      for (UserCircle userCircle in userCircles) {
        if (userCircle.ratchetKeys.isEmpty) missing.add(userCircle);
      }

      if (missing.isNotEmpty) ratchetReceiverKeys(user, userFurnace, missing);

      return missing.isNotEmpty;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.ratchetMissingServerSideKeys: $err');
      rethrow;
    }
  }

  ///this is called to update multiple Circles at once, not when a single UserCircle ratchets after receiving a message
  static ratchetReceiverKeys(
      User user, UserFurnace userFurnace, List<UserCircle> userCircles) async {
    try {
      List<RatchetKey> ratchetKeys = [];

      for (UserCircle userCircle in userCircles) {
        String userCircleID = userCircle.id!;

        if (userCircle.removeFromCache == null) {
          ratchetKeys.add(await RatchetKey.generateReceiverKeyPair(
              userCircleID, userFurnace.userid!));
        }
      }

      ///update the server
      await _ratchetPublicKeyService.updateRatchetPublicKeys(
          userFurnace, ratchetKeys, user.keyGen!);

      //if (globalState.user.autoKeychainBackup!) KeychainBackupService.backup();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.generateNewKeys: $err');
      rethrow;
    }
  }

  static ratchetReceiverKey(
      UserFurnace userFurnace, String circleID, String userCircleID,
      {List<CircleObject>? circleObjects}) async {
    try {
      // ForwardSecrecy.generateUserKeyPair(userFurnace.userid!); //async ok

      RatchetKey ratchetKey = await RatchetKey.generateReceiverKeyPair(
          userCircleID, userFurnace.userid!);

      ///update the server
      await _ratchetPublicKeyService.ratchetPublicKey(
          userFurnace, ratchetKey, circleID,
          circleObjects: circleObjects);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.generateNewKeys: $err');
      //throw (err);
    }
  }

  static generateUserKey(User user, UserFurnace userFurnace) async {
    try {
      RatchetKey ratchetKey = await ForwardSecrecy.generateUserKeyPair(
          userFurnace.userid!); //async ok

      ///update the server
      await _ratchetPublicKeyService.updateUserKey(userFurnace, ratchetKey);

      return ratchetKey;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.generateNewKeys: $err');
      rethrow;
    }
  }

  static generateCircleKeys(User user, UserFurnace userFurnace,
      List<UserCircle> userCircles, Function callback) async {
    try {
      List<RatchetKey> ratchetKeys = [];

      //RatchetKey ratchetKey = await ForwardSecrecy.generateUserKeyPair(userFurnace.userid!); //async ok

      for (UserCircle userCircle in userCircles) {
        String userCircleID = userCircle.id!;
        //Box<RatchetKey> encryptedBox;

        if (userCircle.removeFromCache == null) {
          //encryptedBox = await RatchetKey.openEncryptedBox(
          //userCircleID + RatchetKey.RECEIVER);

          // if (userCircle.ratchetKeys.isEmpty) {
          //second, are there keys here?

          //if (encryptedBox.isNotEmpty) {
          ratchetKeys.add(await RatchetKey.generateReceiverKeyPair(
              userCircleID, userFurnace.userid!));

          ///update the UI
          callback(true);
          // }
          // }
        }
      }

      ///update the server
      await _ratchetPublicKeyService.updateRatchetPublicKeys(
          userFurnace, ratchetKeys, user.keyGen!);

      callback(false);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ForwardSecrecy.generateNewKeys: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> generateBlankKeyPair() async {
    try {
      late RatchetKey retValue;

      final x25519 = Cryptography.instance.x25519();

      final localKeyPair = await x25519.newKeyPair();

      //generate a unique index for this key
      String keyIndex = const Uuid().v4();
      String public =
          base64UrlEncode((await localKeyPair.extractPublicKey()).bytes);
      String private =
          base64UrlEncode(await localKeyPair.extractPrivateKeyBytes());

      Device device = await globalState.getDevice();

      retValue = RatchetKey(
        keyIndex: keyIndex,
        public: public,
        private: private,
        created: DateTime.now(),
        device: device.uuid,
        user: '',
      );

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.generateKeyPair: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> generateKeyPair(
      String user, String userCircle) async {
    try {
      late RatchetKey retValue;

      debugPrint('generateKeyPair gen key start: ${DateTime.now()}');

      final x25519 = Cryptography.instance.x25519();

      final localKeyPair = await x25519.newKeyPair();

      //generate a unique index for this key
      String keyIndex = const Uuid().v4();
      String public =
          base64UrlEncode((await localKeyPair.extractPublicKey()).bytes);
      String private =
          base64UrlEncode(await localKeyPair.extractPrivateKeyBytes());

      Device device = await globalState.getDevice();

      if (device.uuid!.isEmpty) {
        LogBloc.insertLog(
            'Device load fail safe failed', 'RatchetKey.generateKeyPair');
      }

      retValue = RatchetKey(
          keyIndex: keyIndex,
          public: public,
          private: private,
          created: DateTime.now(),
          device: device.uuid,
          user: user,
          userCircle: userCircle);

      debugPrint('generateKeyPair gen key stop: ${DateTime.now()}');

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.generateKeyPair: $err');
      rethrow;
    }
  }

  static Future<ReplyObject> _encryptReplyObject(
      IsolateEncryptReplyObjectParams params) async {
    try {
      var encoded = json.encode(params.replyObject.toJson()).toString();
      ReplyObject encryptedCopy = ReplyObject.fromJson(json.decode(encoded));

      String ciphertext = json.encode(encryptedCopy.fetchFieldsToEncrypt());

      ///encrypt the message payload using the unique message key
      final encrypted = await params.cipher.encrypt(utf8.encode(ciphertext),
          secretKey: params.secretKey, nonce: params.cipher.newNonce());

      encryptedCopy.body = base64UrlEncode(encrypted.cipherText);
      encryptedCopy.crank = base64UrlEncode(encrypted.nonce);
      encryptedCopy.signature = base64UrlEncode(encrypted.mac.bytes);

      ///encrypt line item or nah?

      return encryptedCopy;
    } catch (err) {
      debugPrint('ForwardSecrecy._encryptReplyObject: $err');
      rethrow;
    }
  }

  static Future<ReplyObject> encryptReplyObject(UserFurnace userFurnace,
      ReplyObject replyObject, UserCircleCache userCircleCache) async {
    try {
      // replyObject.cancelTokens = null;
      // replyObject.cancelToken = null;

      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      late SecretKey secretKey;
      String userCircleID = await TableUserCircleCache.getUserCircleID(
          userFurnace.userid!, userCircleCache.circle!);

      ///reuse the secret key for edits. Always use a new MAC and nonce!
      if (replyObject.secretKey != null) {
        secretKey = SecretKey(replyObject.secretKey!);
      } else {
        if (replyObject.id == null) {
          secretKey = await cipher.newSecretKey();
        } else {
          secretKey =
              SecretKey(await getReplySecretKey(userCircleID, replyObject));
        }
      }

      debugPrint('encrypting start: ${DateTime.now().toLocal()}');
      List<RatchetKey> ratchetKeys =
          await _fetchPublicKeys(userFurnace, replyObject.circle!);

      RatchetKey senderKey = await RatchetKey.ratchetSenderKeyPair(
          userID: userFurnace.userid!, userCircle: userCircleID);

      IsolateSharedSecretParams isolateParams = IsolateSharedSecretParams(
        secretKey: secretKey,
        ratchetKeys: ratchetKeys,
        cipher: cipher,
        senderKey: senderKey,
      );

      IsolateEncryptReplyObjectParams isolateEncryptReplyObjectParams =
          IsolateEncryptReplyObjectParams(
        userID: userFurnace.userid!,
        replyObject: replyObject,
        cipher: cipher,
        secretKey: secretKey,
      );

      late ReplyObject encryptedCopy;

      encryptedCopy =
          await _encryptReplyObject(isolateEncryptReplyObjectParams);

      late List<RatchetIndex> ratchetIndexes;

      encryptedCopy.verification =
          await signEncryptedMac(userFurnace, encryptedCopy.signature);

      ///Use an isolate if there are more than 2 recipients
      if (ratchetKeys.length > 2)
        ratchetIndexes = await compute(_calculateSharedSecrets, isolateParams);
      else
        ratchetIndexes = await _calculateSharedSecrets(isolateParams);

      encryptedCopy.senderRatchetPublic = senderKey.public!;
      encryptedCopy.ratchetIndexes = ratchetIndexes;

      debugPrint('encrypting stop: ${DateTime.now().toLocal()}');

      return encryptedCopy;
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'ForwardSecrecy.encryptReplyObject');
      debugPrint('ForwardSecrecy.encryptReplyObject: $err');
      rethrow;
    }
  }
}
