/*import 'dart:convert';
import 'dart:io';
import 'package:cryptography_one/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';

class EncryptArguments {
  String source;
  List<int> secretKey;

  EncryptArguments({
    required this.source,
    required this.secretKey,
  });
}

class DecryptArguments {
  String nonce;
  String mac;
  List<int>? key;
  File encrypted;

  DecryptArguments(
      {required this.encrypted,
      required this.nonce,
      required this.mac,
      this.key});
}

class EncryptBlob {
  //static final int maxForEncrypted = 104857600; //100MB
  //static const int maxForEncrypted = 262144000; //250MB
  static const int maxForEncrypted = 314572800;
  //static const int maxForEncrypted = 1000; //testing

  static Future<DecryptArguments> encryptBlob(String path,
      {List<int>? secretKey}) async {
    try {
      if (secretKey == null) {
        final cipher = Chacha20(macAlgorithm: Hmac.sha256());
        SecretKey sk = await cipher.newSecretKey();

        secretKey = await sk.extractBytes();
      }

      File source = File(path);
      if (source.lengthSync() > maxForEncrypted) {
        throw ('video file too large for E2E'); //todo encrypt stream
      } else {
        //in memory processing
        DecryptArguments args = await compute(_encryptInMemory,
            EncryptArguments(source: path, secretKey: secretKey));

        //debugPrint('est');
        return args;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('EncryptBlob.encryptBlob: $err');
      rethrow;
    }
  }

  static Future<bool> decryptBlob(DecryptArguments args) async {
    try {
      File source = args.encrypted;

      if (source.lengthSync() > maxForEncrypted) {
        throw ('file too large'); //todo encrypt stream
      } else {
        bool success = await _decryptInMemory(args);

        if (success) {
          try {
            ///successful, delete the enc copy
            if (args.encrypted.existsSync()) args.encrypted.delete();
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
          }
          return true;
        } else
          return false;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace, source: 'EncryptBlob.decryptBlob');
      rethrow;
    }
  }

  static Future<bool> _decryptInMemory(DecryptArguments blobArguments) async {
    try {
      debugPrint('start decryption + ${DateTime.now()}');
      /* debugPrint(blobArguments.key);
      //debugPrint(blobArguments.mac);
      debugPrint (base64Url.decode(blobArguments.mac));
      debugPrint (Mac(base64Url.decode(blobArguments.mac)).bytes);
      debugPrint(base64Url.decode(blobArguments.nonce));

      */

      File decryptedCopy = File(blobArguments.encrypted.path
          .substring(0, blobArguments.encrypted.path.length - 3));

      // final cipher = Cryptography.instance.aesGcm();
      final cipher = Chacha20(macAlgorithm: Hmac.sha256());

      List<int> bytesToDecrypt = await blobArguments.encrypted.readAsBytes();

      //decrypt
      SecretBox secretBoxKey = SecretBox(bytesToDecrypt,
          nonce: base64Url.decode(blobArguments.nonce),
          mac: Mac(base64Url.decode(blobArguments.mac)));

      var decrypted = await cipher.decrypt(secretBoxKey,
          secretKey: SecretKey(blobArguments.key!));

      await decryptedCopy.writeAsBytes(decrypted);

      debugPrint('end decryption + ${DateTime.now()}');

      return true;
    } catch (err, trace) {
      LogBloc.insertError(err, trace, source: 'EncryptBlob._decryptInMemory');
    }

    return false;
  }

  static Future<DecryptArguments> _encryptInMemory(
      EncryptArguments args) async {
    try {
      debugPrint('start encryption + ${DateTime.now()}');

      //final cipher = Cryptography.instance.aesGcm();
      final cipher = Chacha20(macAlgorithm: Hmac.sha256());
      //final secretKey = args.secretKey;
      //final nonce = cipher.newNonce();

      File source = (File(args.source));
      //File source = File('/data/user/0/com.ironcircles.ironcirclesapp/app_flutter/Lin.mp4');
      //File source = File('/data/user/0/com.ironcircles.ironcirclesapp/app_flutter/Sandlot-1.m4v');

      File encryptedCopy = File(source.path + "enc");

      //debugPrint('read file + ${DateTime.now()}');
      List<int> bytesToEncrypt = await source.readAsBytes();

      //debugPrint('encrypting + ${DateTime.now()}');

      var encrypted = await cipher.encrypt(bytesToEncrypt,
          secretKey: SecretKey(args.secretKey));

      await encryptedCopy.writeAsBytes(encrypted.cipherText);

      //clear memory
      //bytesToEncrypt.clear();

      /*
      debugPrint(args.secretKey);
      debugPrint(encrypted.mac.bytes);
      debugPrint(encrypted.nonce);

       */

      debugPrint('stop encryption + ${DateTime.now()}');

      return DecryptArguments(
        encrypted: encryptedCopy,
        nonce: base64UrlEncode(encrypted.nonce),
        mac: base64UrlEncode(encrypted.mac.bytes),
        key: args.secretKey,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('EncryptBlob.encrypt: $err');
      rethrow;
    }
  }
}

/*
//AES encrypt
void encryptAES() async {
  try {
    debugPrint('start encryption + ${DateTime.now()}');

    //debugPrint(source.path);
    String tempPasscode = "asdfasdfsaf";

    var crypt = AesCrypt();
    var iv = crypt.createIV();
    crypt.aesSetKeys(Uint8List.fromList(utf8.encode(tempPasscode)), iv);

    //VID-20200621-WA0042.mp4
    //Sandlot-1.m4v

    File largeSource =
        File('/data/user/0/com.ironcircles.ironcirclesapp/app_flutter/Lin.mp4');

    File encryptedCopy = File(largeSource.path + "enc");
    File decryptedCopy = File(largeSource.path + "dec");

    var decrypt = AesCrypt();
    decrypt.aesSetKeys(Uint8List.fromList(utf8.encode(tempPasscode)), iv);

    await decrypt.encryptFile(largeSource.path, encryptedCopy.path);

    debugPrint('end encryption + ${DateTime.now()}');

    debugPrint('start decryption + ${DateTime.now()}');
    await crypt.decryptFile(encryptedCopy.path, decryptedCopy.path);
    debugPrint('end decryption + ${DateTime.now()}');
  } catch (e) {
    debugPrint(e);
    throw (e);
  }
}

 */

/*
  static encrypt(File source) async {
    try {
      File encryptedCopy = File(source.path + "enc");

      var sink = encryptedCopy.openWrite();

      //sink.

      //final cipher = Cryptography.instance.aesGcm();

      /*
      final cbc = CBCBlockCipher(AESFastEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

      final cipherText = Uint8List(paddedPlaintext.length); // allocate space

      var offset = 0;
      while (offset < paddedPlaintext.length) {
        offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
      }
      assert(offset == paddedPlaintext.length);


    */

      final cipher = Cryptography.instance.aesGcm();

      var nonce = cipher.newNonce();
      var secret = await cipher.newSecretKey();
      List<List<int>> macs = [];

      debugPrint('start encryption + ${DateTime.now()}');

      //var lines = await source.readAsLines(encoding: utf8);

      var stream = source.openRead();
      await for (var line in stream) {
        var encrypted =
            await cipher.encrypt(line, secretKey: secret, nonce: nonce);
        //encryptedCopy.writeAsBytes(line, mode: FileMode.append);
        // debugPrint(encrypted.mac);
        debugPrint ('${encrypted.cipherText}'); // ${encrypted.mac.bytes}');
        debugPrint ('${encrypted.mac.bytes}');
        macs.add(encrypted.mac.bytes);
        //encryptedCopy.writeAsBytes(encrypted.cipherText, mode: FileMode.append);

        sink.writeln(utf8.decode(encrypted.cipherText));
      }

      sink.close();

      debugPrint('end encryption + ${DateTime.now()}');

      File decryptedCopy = File(source.path + "dec");

      int counter = 0;

      debugPrint('start decryption + ${DateTime.now()}');
      var lines2 = await encryptedCopy.readAsLines(encoding: utf8);

      for (var line in lines2) {

        debugPrint(line);
        debugPrint ('${line.codeUnits}');
        //debugPrint ('${BinaryWriter.utf8Encoder.convert(line)}');
        debugPrint ('${macs[counter]}');

        var decrypted = await cipher.decrypt(
           // SecretBox(BinaryWriter.utf8Encoder.convert(line), nonce: nonce, mac: Mac(macs[counter])),
            SecretBox(line.codeUnits, nonce: nonce, mac: Mac(macs[counter])),
            secretKey: secret);
        decryptedCopy.writeAsBytes(decrypted, mode: FileMode.append);

        debugPrint('counter: $counter');
        counter = counter + 1;
      }
      debugPrint('end decryption + ${DateTime.now()}');
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('EncryptBlob.encrypt: $err');

      //throw(err);
    }
  }

   */

/*


  static encrypt(File source) async {
    try {
      File encryptedCopy = File(source.path + "enc");

      //final cipher = Cryptography.instance.aesGcm();

      /*
      final cbc = CBCBlockCipher(AESFastEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

      final cipherText = Uint8List(paddedPlaintext.length); // allocate space

      var offset = 0;
      while (offset < paddedPlaintext.length) {
        offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
      }
      assert(offset == paddedPlaintext.length);


    */

      final cipher = Cryptography.instance.aesGcm();

      var nonce = cipher.newNonce();
      var secret = await cipher.newSecretKey();
      List<List<int>> macs = [];

      debugPrint('start encryption + ${DateTime.now()}');

      var lines = await source.readAsLines();

      //var stream = source.openRead();
     for (var line in lines){
        var encrypted =
            await cipher.encrypt(utf8.encode(line), secretKey: secret, nonce: nonce);
        //encryptedCopy.writeAsBytes(line, mode: FileMode.append);
        // debugPrint(encrypted.mac);
        macs.add(encrypted.mac.bytes);
        encryptedCopy.writeAsBytes(encrypted.cipherText, mode: FileMode.append);
      }

      debugPrint('end encryption + ${DateTime.now()}');

      File decryptedCopy = File(source.path + "dec");

      int counter = macs.length-1;

      debugPrint('start decryption + ${DateTime.now()}');
      var stream2 = encryptedCopy.openRead();
      await for (var line in stream2) {
        var decrypted = await cipher.decrypt(
            SecretBox(line, nonce: nonce, mac: Mac(macs[counter])),
            secretKey: secret);
        decryptedCopy.writeAsBytes(decrypted, mode: FileMode.append);

        counter = counter - 1;
      }
      debugPrint('end decryption + ${DateTime.now()}');
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('EncryptBlob.encrypt: $err');
    }
  }
   */

 */
