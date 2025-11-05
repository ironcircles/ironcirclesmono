// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);

import 'dart:convert';

import 'package:ironcirclesapp/models/ratchetindex.dart';

CircleObjectLineItem circleObjectLineItemFromJson(String str) =>
    CircleObjectLineItem.fromJson(json.decode(str));

class CircleObjectLineItem {
  String id;
  RatchetIndex ratchetIndex;
  int version;

  int order = 0; //UI only

  CircleObjectLineItem({
    this.id = '',
    this.version = 1,
    required this.ratchetIndex,
  });

  ///To the API
  Map<String, dynamic> toJson() =>
      {"_id": id, "version": version, "ratchetIndex": ratchetIndex.toJson()};

  factory CircleObjectLineItem.fromJson(Map<String, dynamic> json) =>
      CircleObjectLineItem(
        id: json["_id"] ?? '',
        version: json["version"] ?? '',
        ratchetIndex: RatchetIndex.fromJson(json["ratchetIndex"]),
      );
}

class CircleObjectLineItemCollection {
  final List<CircleObjectLineItem> objects;

  CircleObjectLineItemCollection.fromJSON(Map<String, dynamic> json, String key)
      : objects = (json[key] as List)
            .map((json) => CircleObjectLineItem.fromJson(json))
            .toList();
}
