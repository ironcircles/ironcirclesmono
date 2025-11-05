// To parse this JSON data, do
//
//     final circleGif = circleGifFromJson(jsonString);

import 'dart:convert';

CircleGif circleGifFromJson(String str) => CircleGif.fromJson(json.decode(str));

String circleGifToJson(CircleGif data) => json.encode(data.toJson());

class CircleGif {
  String? id;
  String? circle;
  int? width;
  int? height;
  String? giphy;
  String? created;
  String? lastUpdate;

  CircleGif({
    this.id,
    this.circle,
    this.giphy,
    this.created,
    this.width,
    this.height,
    this.lastUpdate,
  });

  factory CircleGif.fromJson(Map<String, dynamic> json) => CircleGif(
    id: json["id"],
    //circle: json["circle"],
    giphy: json["giphy"],
    width: json["width"],
    height: json["height"],
    created: json["created"],
    lastUpdate: json["lastUpdate"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "circle": circle,
    "giphy": giphy,
    "width": width,
    "height": height,
    "created": created,
    "lastUpdate": lastUpdate,
  };
}
