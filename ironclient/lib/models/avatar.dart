// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);

import 'dart:convert';

Avatar avatarFromJson(String str) => Avatar.fromJson(json.decode(str));

String avatarToJson(Avatar data) => json.encode(data.toJson());

class Avatar {
  String id;
  String location;
  String name;
  int size;

  Avatar({
    this.id = '',
    this.location = '',
    this.name = '',
    this.size = -1,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
        id: json["id"] ?? '',
        location: json["location"] ?? '',
        name: json["name"] ?? '',
        size: json["size"] ?? -1,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "location": location,
        "name": name,
        "size": size,
      };
}
