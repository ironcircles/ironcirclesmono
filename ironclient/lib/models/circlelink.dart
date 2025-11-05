// To parse this JSON data, do
//
//     final linkPreview = linkPreviewFromJson(jsonString);

import 'dart:convert';

CircleLink linkPreviewFromJson(String str) =>
    CircleLink.fromJson(json.decode(str));

String linkPreviewToJson(CircleLink data) => json.encode(data.toJson());

class CircleLink {
  String? title;
  String? description;
  String? image;
  String? url;
  String? body;
  bool previewFailed = false;

  CircleLink({
    this.title = '',
    this.description = '',
    this.image = '',
    this.url,
  });

  factory CircleLink.fromJson(Map<String, dynamic> json) => CircleLink(
        title: json["title"] ?? '',
        description: json["description"] ?? '',
        image: json["image"] ?? '',
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "title": title ?? '',
        "description": description ?? '',
        "image": image ?? '',
        "url": url,
      };
}
