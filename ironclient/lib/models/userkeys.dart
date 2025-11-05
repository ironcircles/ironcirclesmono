//import "package:pointycastle/export.dart";
/*
class KeyIndex {
  String pk;
  String keyIndex;
  String userid;
  bool generatedHere;
  //int created;

  KeyIndex({
    this.pk = '',
    required this.keyIndex,
    required this.userid,
    required this.generatedHere,
  });

  factory KeyIndex.fromJson(Map<String, dynamic> json) => KeyIndex(
        pk: json['pk'],
        keyIndex: json['index'],
        userid: json['userid'],
        generatedHere: json['generatedhere'] == 1 ? true : false,
      );

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'keyindex': keyIndex,
        'userid': userid,
        'generatedhere': generatedHere ? 1 : 0,
      };
}

class KeyIndexCollection {
  final List<KeyIndex> userCircles;

  KeyIndexCollection.fromJSON(Map<String, dynamic> json)
      : userCircles = (json['keyindex'] as List)
            .map((json) => KeyIndex.fromJson(json))
            .toList();
}

class UserPublicKey {
  String keyIndex;
  String public;
  String userid;

  UserPublicKey({
    required this.userid,
    required this.keyIndex,
    required this.public,
  });

  factory UserPublicKey.fromJson(Map<String, dynamic> json) =>
      UserPublicKey(
        userid: json["userid"],
        public: json['public'],
        keyIndex: json['keyIndex'],
      );

  Map<String, dynamic> toJson() => {
        'public': public,
        'keyIndex': keyIndex,
        'userid': userid,
      };
}

class UserPublicKeyCollection {
  final List<UserPublicKey> nextKeys;

  UserPublicKeyCollection.fromJSON(Map<String, dynamic> json)
      : nextKeys = (json['nextKeys'] as List)
            .map((json) => UserPublicKey.fromJson(json))
            .toList();
}

class UserPrivateKey {
  String keyName;
  String modulus;
  String d; //exponent
  String p;
  String q;

  UserPrivateKey({
    this.keyName = '',
    this.modulus = '',
    this.d = '',
    this.p = '',
    this.q = '',
  });

  factory UserPrivateKey.fromJson(Map<String, dynamic> json) =>
      UserPrivateKey(
        keyName: json['keyName'],
        modulus: json['modulus'],
        d: json['d'],
        p: json['p'],
        q: json['q'],
      );

  factory UserPrivateKey.fromRSAKey(String userID, RSAPrivateKey privateKey) =>
      UserPrivateKey(
        keyName: userID,
        modulus: privateKey.n.toString(),
        d: privateKey.d.toString(),
        p: privateKey.p.toString(),
        q: privateKey.q.toString(),
      );

  Map<String, dynamic> toJson() => {
        'keyName': keyName,
        'modulus': modulus,
        'd': d,
        'p': p,
        'q': q,
      };
}
*/

import 'dart:io';

import 'package:ironcirclesapp/models/ratchetkey.dart';

class KeyExport {
  List<UserKeys> keys;

  KeyExport({required this.keys});

  factory KeyExport.fromJson(Map<String, dynamic> json) => KeyExport(
        keys: UserKeysCollection.fromJSON(json).keys,
      );

  Map<String, dynamic> toJson() => {
        'keys': keys,
      };
}

class UserKeys {
  List<RatchetKey> userKeys;
  List<RatchetKey> senderKeys;
  List<RatchetKey> receiverKeys;

  UserKeys(
      {required this.userKeys,
      required this.senderKeys,
      required this.receiverKeys});

  factory UserKeys.fromJson(Map<String, dynamic> json) => UserKeys(
        userKeys: RatchetKeyCollection.fromJSON(json, 'userKeys').ratchetKeys,
        senderKeys:
            RatchetKeyCollection.fromJSON(json, 'senderKeys').ratchetKeys,
        receiverKeys:
            RatchetKeyCollection.fromJSON(json, 'receiverKeys').ratchetKeys,
      );

  Map<String, dynamic> toJson() => {
        'userKeys': userKeys,
        'senderKeys': senderKeys,
        'receiverKeys': receiverKeys,
      };

/*
  Map<String, dynamic> reduce(){

    Map<String, dynamic> reduced = Map();

    for(RatchetKey ratchetKey in )

    return reduced;
  }

 */
}

class UserKeysCollection {
  final List<UserKeys> keys;

  UserKeysCollection.fromJSON(Map<String, dynamic> json)
      : keys = (json['keys'] as List)
            .map((json) => UserKeys.fromJson(json))
            .toList();
}

class OldKeys {
  RatchetKey userKey;
  List<RatchetKey> senderKeys;
  List<RatchetKey> receiverKeys;

  OldKeys(
      {required this.userKey,
      required this.senderKeys,
      required this.receiverKeys});

  factory OldKeys.fromJson(Map<String, dynamic> json) => OldKeys(
        userKey: RatchetKey.fromJson(json['userKey']),
        senderKeys:
            RatchetKeyCollection.fromJSON(json, 'senderKeys').ratchetKeys,
        receiverKeys:
            RatchetKeyCollection.fromJSON(json, 'receiverKeys').ratchetKeys,
      );

  Map<String, dynamic> toJson() => {
        'userKey': userKey,
        'senderKeys': senderKeys,
        'receiverKeys': receiverKeys,
      };
}

/*
class KeyChainBackup {
  String keychain;
  String device;


  KeyChainBackup({
    required this.keychain,
    required this.device,
  });

  factory KeyChainBackup.fromJson(Map<String, dynamic> json) => KeyChainBackup(
    keychain: json['keychain'],
    b: json['b'].cast<int>(),
    //keys: (json['keys'] as List).map((e) => e as int).toList(),
    keys: json['keys'].cast<int>(),
  );

  Map<String, dynamic> toJson() => {
    'a': a,
    'b': b,
    'keys': keys,
  };
}

 */

class KeyFile {
  List<int> a;
  List<int> b;
  List<int> keys;
  File? receiverKeys;

  KeyFile({
    required this.a,
    required this.b,
    required this.keys,
  });

  factory KeyFile.fromJson(Map<String, dynamic> json) => KeyFile(
        a: json['a'].cast<int>(),
        b: json['b'].cast<int>(),
        //keys: (json['keys'] as List).map((e) => e as int).toList(),
        keys: json['keys'].cast<int>(),
      );

  Map<String, dynamic> toJson() => {
        'a': a,
        'b': b,
        'keys': keys,
      };
}
