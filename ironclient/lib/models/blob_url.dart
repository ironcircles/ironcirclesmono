// To parse this JSON data, do
//
//     final circleGif = circleGifFromJson(jsonString);

import 'dart:convert';

import 'package:ironcirclesapp/constants/constants.dart';

BlobUrl blobUrlFromJson(String str) => BlobUrl.fromJson(json.decode(str));

String blobUrlToJson(BlobUrl data) => json.encode(data.toJson());

class BlobUrl {
  String fileNameUrl;
  String thumbnailUrl;
  String fileName;
  String thumbnail;
  String location;

  BlobUrl({
    required this.fileNameUrl,
    required this.thumbnailUrl,
    required this.fileName,
    required this.thumbnail,
    required this.location,
  });

  factory BlobUrl.fromJson(Map<String, dynamic> json) => BlobUrl(
        fileNameUrl: json["fileUrl"] ?? '',
        thumbnailUrl: json["thumbnailUrl"] ?? '',
        fileName: json["fileName"] ?? '',
        thumbnail: json["thumbnail"] ?? '',
        location:
            json["location"] ?? BlobLocation.UNKNOWN,
      );

  factory BlobUrl.blank() => BlobUrl(
        fileNameUrl: '',
        thumbnailUrl: '',
        fileName: '',
        thumbnail: '',
        location: BlobLocation.UNKNOWN,
      );

  Map<String, dynamic> toJson() => {
        "fileNameUrl": fileNameUrl,
        "thumbnailUrl": thumbnailUrl,
        "fileName": fileName,
        "thumbnail": thumbnail,
        "location": location,
      };
}
