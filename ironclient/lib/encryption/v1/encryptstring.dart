/*/// Encrypt/decrypt a string (or json converted to string)
import 'dart:async';
import 'dart:convert';
import 'package:cryptography_one/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:uuid/uuid.dart';

class IsolateEncryptStringParams {
  String plainText;
  Cipher cipher;
  SecretKey secretKey;
  String userID;

  IsolateEncryptStringParams({
    required this.plainText,
    required this.cipher,
    required this.secretKey,
    required this.userID,
  });
}

class IsolateDecryptStringsParams {
  List<RatchetIndex> ratchetIndexes;
  SecretKey secretKey;

  IsolateDecryptStringsParams({
    required this.secretKey,
    required this.ratchetIndexes,
  });
}

Future<RatchetIndex> _encryptString(IsolateEncryptStringParams params) async {
  try {
    final encrypted = await params.cipher.encrypt(utf8.encode(params.plainText),
        secretKey: params.secretKey, nonce: params.cipher.newNonce());

    RatchetIndex ratchetIndex = RatchetIndex(
        ratchetIndex: const Uuid().v4(),
        user: params.userID,
        crank: base64UrlEncode(encrypted.nonce),
        signature: base64UrlEncode(encrypted.mac.bytes),
        ratchetValue: base64UrlEncode(encrypted.cipherText));

    return ratchetIndex;
  } catch (err) {
    //LogBloc.insertError(err, trace);  //TODO can't access the database in an isolate
    debugPrint('EncryptString._encryptString: $err');
    throw (err);
  }
}

//caller will convert to json
Future<List<String>> _decryptStrings(IsolateDecryptStringsParams params) async {
  List<String> retValue = [];

  debugPrint('EncryptString: start decryption:  ${DateTime.now()}');

  final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

  for (RatchetIndex ratchetIndex in params.ratchetIndexes) {
    try {
      SecretBox secretBox = SecretBox(base64Url.decode(ratchetIndex.ratchetValue),
          nonce: base64Url.decode(ratchetIndex.crank),
          mac: Mac(base64Url.decode(ratchetIndex.signature)));

      final decrypt = await cipher.decrypt(
        secretBox,
        secretKey: params.secretKey,
      );
      retValue.add(utf8.decode(decrypt));
    } catch (err, trace) {
       debugPrint('$trace');
      //LogBloc.insertError(err, trace);  //TODO can't access the database in an isolate
      debugPrint('EncryptString._decryptStrings: $err');
    }
  }

  debugPrint('EncryptString: end decryption:  ${DateTime.now()}');
  return retValue;
}

class EncryptString {
  static Future<List<String>> decryptStrings(
    SecretKey secretKey,
    List<RatchetIndex> ratchetIndexes,
  ) async {
    try {
      IsolateDecryptStringsParams params = IsolateDecryptStringsParams(
        ratchetIndexes: ratchetIndexes,
        secretKey: secretKey,
      );

      late List<String> retValue;

      if (ratchetIndexes.length > 2)
        retValue = await compute(_decryptStrings, params);
      else
        retValue = await _decryptStrings(params);

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('EncryptString.decryptStrings: $err');
      throw (err);
    }
  }

  static Future<RatchetIndex> encryptString(String plainText, String userID,
      {SecretKey? messageKey}) async {
    try {
      final cipher = Xchacha20(macAlgorithm: Hmac.sha256());

      late SecretKey secretKey;

      if (messageKey != null)
        secretKey = messageKey;
      else
        secretKey = await cipher.newSecretKey();

      debugPrint('start: ' + DateTime.now().toLocal().toString());

      IsolateEncryptStringParams isolateEncryptCircleObjectParams =
          IsolateEncryptStringParams(
        plainText: plainText,
        cipher: cipher,
        secretKey: secretKey,
        userID: userID,
      );

      //don't use an isolate for one String
      RatchetIndex ratchetIndex =
          await _encryptString(isolateEncryptCircleObjectParams);

      debugPrint('stop: ' + DateTime.now().toLocal().toString());

      return ratchetIndex;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('EncryptString.encryptString: $err');
      throw (err);
    }
  }
}

 */
