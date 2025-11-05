import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';

MagicCode magicCodeFromJson(String str) => MagicCode.fromJson(json.decode(str));

String magicCodeToJson(MagicCode data) => json.encode(data.toJson());

class MagicCode {
  int? pk;
  int userFurnaceKey;
  String code;
  MagicCodeType type;

  final GlobalKey key = GlobalKey();

  MagicCode({
    this.pk,
    required this.userFurnaceKey,
    required this.code,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        "userFurnaceKey": userFurnaceKey,
        "code": code,
        "type": type.index,
      };

  //from sqlite
  factory MagicCode.fromJson(Map<String, dynamic> json) => MagicCode(
        pk: json["pk"],
        userFurnaceKey: json["userFurnaceKey"],
        code: json["code"],
        type: MagicCodeType.values.elementAt(json["type"]),
      );
}

class MagicCodeCollection {
  final List<MagicCode> magicCodes;

  MagicCodeCollection.fromJSON(Map<String, dynamic> json, String key)
      : magicCodes = (json[key] as List)
            .map((json) => MagicCode.fromJson(json))
            .toList();
}
