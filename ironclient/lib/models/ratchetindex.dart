class RatchetIndex {
  String ratchetIndex;
  String user;
  String ratchetValue;
  String userIndex;
  String crank;
  String signature;
  String? kdfNonce;
  String device;
  bool active;

  ///these are not used in base CircleObjects, only in Events (soon to be Lists and Recipes), Circle names, backgrounds, templates, etc
  String? cipher;
  String? cipherCrank;
  String? cipherSignature;
  String? senderRatchetPublic;

  RatchetIndex(
      {required this.ratchetIndex,
      required this.user,
      required this.crank,
      required this.signature,
      required this.ratchetValue,
      this.active = true,
      this.userIndex = '',
      this.device = '',
      this.kdfNonce,
      this.cipher,
      this.cipherCrank,
      this.cipherSignature,
      this.senderRatchetPublic});

  factory RatchetIndex.fromJson(Map<String, dynamic> json) => RatchetIndex(
        ratchetIndex: json['ratchetIndex'],
        user: json['user'],
        active: json['active'] ?? true,
        crank: json['crank'],
        device: json['device'] ?? '',
        signature: json['signature'],
        kdfNonce: json['kdfNonce'],
        ratchetValue: json['ratchetValue'],
        cipher: json['cipher'],
        cipherCrank: json['cipherCrank'],
        cipherSignature: json['cipherSignature'],
        senderRatchetPublic: json['senderRatchetPublic'],
        //userIndex: json['userIndex'],
      );

  factory RatchetIndex.blank() => RatchetIndex(
        ratchetIndex: '',
        user: '',
        active: true,
        crank: '',
        signature: '',
        ratchetValue: '',
      );

  Map<String, dynamic> toJson() => {
        'ratchetIndex': ratchetIndex,
        'crank': crank,
        'signature': signature,
        'user': user,
        'active': active,
        'device': device,
        'ratchetValue': ratchetValue,
        'kdfNonce': kdfNonce,
        'cipher': cipher,
        'cipherCrank': cipherCrank,
        'cipherSignature': cipherSignature,
        'senderRatchetPublic': senderRatchetPublic,
      };
}

class RatchetIndexCollection {
  final List<RatchetIndex> ratchetIndexes;

  RatchetIndexCollection.fromJSON(Map<String, dynamic> json, String key)
      : ratchetIndexes = (json[key] as List)
            .map((json) => RatchetIndex.fromJson(json))
            .toList();
}
