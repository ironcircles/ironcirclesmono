import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/ratchetpublickey_service.dart';

//part 'ratchetkey.g.dart';

//@HiveType(typeId: 3)
class RatchetKey {
  String keyIndex;
  String? public;
  String private;
  String? device;
  String? userCircle;
  String user;
  DateTime? lastUpdate;
  DateTime? created;
  RatchetKeyType? type;

  RatchetKey(
      {required this.keyIndex,
      this.public,
      required this.private,
      this.device,
      this.userCircle,
      this.type,
      required this.user,
      this.lastUpdate,
      this.created});

  //static const String RECEIVER = "_receiver";
  //static const String SENDER = "_sender";

  factory RatchetKey.fromJson(Map<String, dynamic> json) => RatchetKey(
        keyIndex: json['keyIndex'],
        public: json['public'],
        private: json['private'] ?? '',
        device: json['device'],
        user: json['user'] ?? '',
        type: json['type'] == null
            ? null
            : RatchetKeyType.values.elementAt(json['type']),
        userCircle: json['userCircle'] ?? '',
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? DateTime.now()
            : DateTime.parse(json["created"]).toLocal(),
      );

  factory RatchetKey.fromJsonSQL(Map<String, dynamic> json) => RatchetKey(
        keyIndex: json['keyIndex'],
        public: json['public'],
        private: json['private'] ?? '',
        device: json['device'],
        user: json['user'] ?? '',
        type: json['type'] == null
            ? null
            : RatchetKeyType.values.elementAt(json['type']),
        userCircle: json['userCircle'] ?? '',
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["created"]).toLocal(),
      );

  factory RatchetKey.blank() => RatchetKey(
        keyIndex: '',
        public: '',
        private: '',
        device: '',
        type: null,
        user: '',
        userCircle: '',
        created: DateTime.now(),
      );

  Map<String, dynamic> toJsonSQL() => {
        'keyIndex': keyIndex,
        'public': public,
        'private': private,
        'device': device,
        'user': user,
        'type': type?.index,
        'userCircle': userCircle,
        "lastUpdate":
            lastUpdate?.millisecondsSinceEpoch,
        "created": created?.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toJson() => {
        'keyIndex': keyIndex,
        'public': public,
        'private': private,
        'type': type?.index,
        'device': device,
        'user': user,
        'userCircle': userCircle,
      };

  static Future<RatchetKey> ratchetSenderKeyPair(
      {required String userID, required String userCircle}) async {
    try {
      RatchetKey ratchetKey =
          await ForwardSecrecy.generateKeyPair(userID, userCircle);
      await TableRatchetKeySender.upsert(ratchetKey);

      return ratchetKey;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.ratchetSenderKeyPair: $err');
      rethrow;
    }
  }

  /*static Future<void> ratchetBlankReceiverPrivateKeys() async {
    try {
      /// this is a one time fix for ratchet private keys that were not save on Circle creation
      /// this can be removed after everyone is on 104
      var blankKeys = await TableRatchetKeyReceiver.findBlankPrivateKeys();

      for (var blankKey in blankKeys) {
        try {
          if (blankKey.userCircle != null && blankKey.userCircle!.isNotEmpty) {
            UserCircleCache userCircleCache =
                await TableUserCircleCache.read(blankKey.userCircle!);

            if (userCircleCache.user != null) {
              UserFurnace userFurnace =
                  await TableUserFurnace.read(userCircleCache.userFurnace);

              ratchetReceiverKeyPair(userFurnace, userCircleCache.circle!);
            }
          }

          ///The key doesn't work, update it so that we don't ratchet the Circle every time the app is opened.
          blankKey.private = 'defunct';
          await TableRatchetKeyReceiver.upsert(blankKey);
        } catch (err) {
          debugPrint(err.toString());
        }
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }*/

  static Future<void> ratchetReceiverKeyPair(
      UserFurnace userFurnace, String circleID) async {
    try {
      String userCircle = await TableUserCircleCache.getUserCircleID(
          userFurnace.userid!, circleID);

      RatchetKey ratchetKey =
          await ForwardSecrecy.generateKeyPair(userFurnace.userid!, userCircle);
      int id = await TableRatchetKeyReceiver.insert(ratchetKey);

      if (id > 0) {
        //update the server
        RatchetPublicKeyService()
            .ratchetPublicKey(userFurnace, ratchetKey, circleID);
      } else{
        throw Exception('RatchetKey.ratchetReceiverKeyPair: failed to insert');
      }

      return;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.ratchetReceiverKeyPair: $err');
      //throw (err);
    }
  }

  static Future<RatchetKey> ratchetUserKeyPair(
      String userID, String userCircleID) async {
    try {
      RatchetKey ratchetKey =
          await ForwardSecrecy.generateKeyPair(userID, userCircleID);
      await TableRatchetKeyUser.upsert(ratchetKey);

      return ratchetKey;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.ratchetUserKeyPair: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> generateReceiverKeyPair(
      String userCircle, String user) async {
    try {
      RatchetKey retValue =
          await ForwardSecrecy.generateKeyPair(user, userCircle);

      int id = await TableRatchetKeyReceiver.insert(retValue);

      if (id < 1) throw Exception('RatchetKey.generateReceiverKeyPair: failed to insert receiver key');

      debugPrint('generateKeyPairAndSave key stop: ${DateTime.now()}');

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.generateReceiverKeyPair: $err');
      rethrow;
    }
  }

  static Future<RatchetPair> findReceiverRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return await TableRatchetKeyReceiver.findRatchetPair(keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findReceiverRatchetPair: $err');
      rethrow;
    }
  }

  static Future<RatchetPair> findSenderRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return await TableRatchetKeySender.findRatchetPair(keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findSenderRatchetPair: $err');
      rethrow;
    }
  }

  static Future<RatchetPair> findUserRatchetPair(
      List<RatchetIndex> keyIndexes) async {
    try {
      return await TableRatchetKeyUser.findRatchetPair(keyIndexes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findUserRatchetPair: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> findRatchetKeysByIndex(
      String keyIndex) async {
    try {
      List<RatchetKey> ratchetKeys =
          await TableRatchetKeyUser.findRatchetKeysByIndex(keyIndex);

      if (ratchetKeys.isEmpty) {
        ///There was a bug pre 1.1.10 where the UserKey was cached to Receiver and not both (meaning also UserKey)
        ratchetKeys =
            await TableRatchetKeyReceiver.findRatchetKeysByIndex(keyIndex);
      }

      return ratchetKeys;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findUserRatchetPair: $err');
      rethrow;
    }
  }

  static Future<List<RatchetKey>> findRatchetKeysForAllUsers() async {
    try {
      return await TableRatchetKeyUser.findRatchetKeysForAllUsers();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findUserRatchetPair: $err');
      rethrow;
    }
  }

  static Future<RatchetKey> getLatestUserKeyPair(String userID) async {
    try {
      return TableRatchetKeyUser.getKeyPairByType(userID, RatchetKeyType.user);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.getLatestUserKeyPair: $err');
      rethrow;
    }
  }

  static Future<bool> receiverKeysMissing(
      String userID, String userCircleID) async {
    try {
      return TableRatchetKeyReceiver.keysMissing(userID, userCircleID);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.receiverKeysMissing: $err');
      rethrow;
    }
  }

  static Future<void> saveReceiverKeyPair(
      RatchetKey ratchetKey, String userCircle) async {
    try {
      ratchetKey.userCircle = userCircle;

      await TableRatchetKeyReceiver.insert(ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.saveReceiverKeyPair: $err');
      rethrow;
    }
  }
/*
  static Future<void> saveSenderKeyPair(
      RatchetKey ratchetKey, String userCircle) async {
    try {
      ratchetKey.userCircle = userCircle;

      await TableRatchetKeySender.upsert(ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.saveSenderKeyPair: $err');
      rethrow;
    }
  }

  static Future<void> saveUserKeyPair(
      RatchetKey ratchetKey, String userCircle) async {
    try {
      ratchetKey.userCircle = userCircle;

      await TableRatchetKeyUser.upsert(ratchetKey);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.saveUserKeyPair: $err');
      rethrow;
    }
  }

 */

  /*
  static Future<List<RatchetKey>> fetchKeysForUser(String userID,
      List<UserCircleCache> userCircleCaches, String boxSuffix) async {
    List<RatchetKey> retValue = [];

    for (UserCircleCache userCircleCache in userCircleCaches) {
      final encryptedBox =
          await openEncryptedBox(userCircleCache.usercircle! + boxSuffix);

      retValue.addAll(encryptedBox.values
          .where((encryptedRatchetKey) => encryptedRatchetKey.user == userID));
    }

    return retValue;
  }

   */

  /*
  static Future<Map<String, RatchetPair>> fetchKeysByCircle(
    String boxName,
    List<CircleObject> circleObjects,
  ) async {
    Map<String, RatchetPair> retValue = Map();

    debugPrint('open box:  ${DateTime.now()}');

    final encryptedBox = await openEncryptedBox(boxName);

    debugPrint('start finding keys:  ${DateTime.now()}');

    for (CircleObject circleObject in circleObjects) {
      for (RatchetIndex ratchetIndex in circleObject.ratchetIndexes) {
        RatchetKey ratchetKey = encryptedBox.values.firstWhere(
            (encryptedRatchetKey) =>
                encryptedRatchetKey.keyIndex == ratchetIndex.ratchetIndex,
            orElse: () => RatchetKey.blank());

        if (ratchetKey.keyIndex.isNotEmpty) {
          retValue[circleObject.id!] =
              RatchetPair(ratchetIndex: ratchetIndex, ratchetKey: ratchetKey);
          break;
        }
      }
    }

    debugPrint('done finding keys:  ${DateTime.now()}');

    return retValue;
  }

   */

  /*
  //find a keypair based on a list keyIndexes
  static Future<RatchetPair> findRatchetPair(
      List<RatchetIndex> keyIndexes, String boxName) async {
    Iterable<RatchetKey> list = [];

    // debugPrint('wtf');
    debugPrint('findRatchetPair keyIndex.length: ${keyIndexes.length}');

    RatchetPair retValue = RatchetPair.blank();
    final encryptedBox = await openEncryptedBox(boxName);

    try {
      for (RatchetIndex ratchetIndex in keyIndexes) {
        list = encryptedBox.values
            .where((item) => item.keyIndex == ratchetIndex.ratchetIndex);

        if (list.isNotEmpty) {
          retValue = RatchetPair(
              ratchetKey: list.first,
              ratchetIndex: ratchetIndex); //should only be one
          break;
        }
      }
    } catch (err, trace) { LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.findRatchetPair: $err');
      throw (err);
    }

    return retValue;
  }

   */

  /*
  static Future<String> _getLocalEncryptKey(String boxName) async {
    String localEncryptKey = '';

    if (await SecureStorageService.keyExists(boxName)) {
      localEncryptKey = await SecureStorageService.readKey(boxName);
    } else {
      final secureKey = Hive.generateSecureKey();
      localEncryptKey = base64UrlEncode(secureKey);
      SecureStorageService.writeKey(boxName, localEncryptKey);
    }

    return localEncryptKey;
  }

   */

  /*
  static Future<RatchetKey> generateKeyPairAndSave(
      String userCircle, String user, Box<RatchetKey> encryptedBox) async {
    late RatchetKey retValue;

    final x25519 = Cryptography.instance.x25519();
    debugPrint('generateKeyPairAndSave key start: ${DateTime.now()}');

    final localKeyPair = await x25519.newKeyPair();

    //generate a unique index for this key
    String keyIndex = Uuid().v4();
    String public =
        base64UrlEncode((await localKeyPair.extractPublicKey()).bytes);
    String private =
        base64UrlEncode(await localKeyPair.extractPrivateKeyBytes());

    retValue = RatchetKey(
        keyIndex: keyIndex,
        public: public,
        private: private,
        device: globalState.deviceID,
        user: user,
        userCircle: userCircle);

    encryptedBox.add(retValue);

    debugPrint('generateKeyPairAndSave key stop: ${DateTime.now()}');

    return retValue;
  }

   */

  /*
  static RatchetPair _getRatchetPair(
      Box<RatchetKey> encryptedBox, List<RatchetIndex> ratchetIndexes) {
    RatchetPair ratchetPair = RatchetPair.blank();

    for (RatchetIndex ratchetIndex in ratchetIndexes) {
      RatchetKey ratchetKey = encryptedBox.values.firstWhere(
          (encryptedRatchetKey) =>
              encryptedRatchetKey.keyIndex == ratchetIndex.ratchetIndex,
          orElse: () => RatchetKey.blank());

      if (ratchetKey.keyIndex.isNotEmpty) {
        ratchetPair =
            RatchetPair(ratchetKey: ratchetKey, ratchetIndex: ratchetIndex);
        break;
      }
    }

    return ratchetPair;
  }

   */

  //find a keypair based on a list keyIndexes
  static Future<Map<String, RatchetPair>> getRecipeTemplateUserRatchetPairs(
      List<CircleRecipeTemplate> templates, String userID) async {
    Map<String, RatchetPair> retValue = {};

    try {
      for (CircleRecipeTemplate template in templates) {
        RatchetPair ratchetPair =
            await findUserRatchetPair(template.ratchetIndexes);

        if (ratchetPair.ratchetKey.keyIndex.isNotEmpty) {
          retValue[template.id!] = ratchetPair;
          //break;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.getRecipeTemplateUserRatchetPairs: $err');
      rethrow;
    }

    return retValue;
  }

  //find a keypair based on a list keyIndexes
  static Future<Map<String, RatchetPair>> getListTemplateUserRatchetPairs(
      List<CircleListTemplate> templates, String userID) async {
    Map<String, RatchetPair> retValue = {};

    try {
      for (CircleListTemplate template in templates) {
        RatchetPair ratchetPair =
            await findUserRatchetPair(template.ratchetIndexes);

        if (ratchetPair.ratchetKey.keyIndex.isNotEmpty) {
          retValue[template.id!] = ratchetPair;
          //break;
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.getListTemplateUserRatchetPairs: $err');
      rethrow;
    }

    return retValue;
  }

  static importUserKeys(List<RatchetKey> userKeys) async {
    await TableRatchetKeyUser.bulkInsert(userKeys);
  }

  static importReceiverKeys(List<RatchetKey> userKeys) async {
    await TableRatchetKeyReceiver.bulkInsert(userKeys);
  }

  /*static importKeys2(UserKeys userKeys) async {
    try {
      for (RatchetKey importRatchetKey in userKeys.userKeys) {
        saveUserKeyPair(importRatchetKey, '');
      }

      /*
      for (RatchetKey importRatchetKey in userKeys.senderKeys) {
        saveSenderKeyPair(importRatchetKey, importRatchetKey.userCircle);
      }

       */

      for (RatchetKey importRatchetKey in userKeys.receiverKeys) {
        saveReceiverKeyPair(importRatchetKey, importRatchetKey.userCircle!);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.importKeys: $err');
      throw (err);
    }
  }

   */

  removePrivateKey() {
    private = '';

    return this;
  }

  safePublicCopy() {
    return RatchetKey(
        private: '',
        public: public,
        keyIndex: keyIndex,
        user: user,
        device: device,
        userCircle: userCircle,
        lastUpdate: lastUpdate,
        created: created);
  }

  /*

  static _importKeys(List<RatchetKey> keys, String boxSuffix) async {
    for (RatchetKey importRatchetKey in keys) {
      Box<RatchetKey> keyBox = await RatchetKey.openEncryptedBox(
          importRatchetKey.userCircle + boxSuffix);

      await keyBox.add(importRatchetKey);
    }
  }

   */
}

class RatchetKeyCollection {
  final List<RatchetKey> ratchetKeys;

  RatchetKeyCollection.fromJSON(Map<String, dynamic> json, String key)
      : ratchetKeys = (json[key] as List)
            .map((json) => RatchetKey.fromJson(json))
            .toList();
/*
  static removePrivateKeys(RatchetKeyCollection collection) {
    for (RatchetKey ratchetKey in collection.ratchetKeys) {
      ratchetKey.private = '';
    }

    return;
  }
*/

  static removePrivateKeys(List<RatchetKey> keys) {
    for (RatchetKey ratchetKey in keys) {
      ratchetKey.private = '';
    }

    return keys;
  }
  /*
      : ratchetKeys = (json[key] as List)
      .map((json) => RatchetKey.fromJson(json))
      .toList();

   */
}
