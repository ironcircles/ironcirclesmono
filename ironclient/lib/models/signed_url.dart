// To parse this JSON data, do
//
//     final circleGif = circleGifFromJson(jsonString);

import 'dart:convert';

SignedUrl signedUrlFromJson(String str) => SignedUrl.fromJson(json.decode(str));

String signedUrlToJson(SignedUrl data) => json.encode(data.toJson());

class SignedUrl {
  String? video;
  String? preview;
  String? videoFilename;
  String? previewFilename;

  SignedUrl({
    this.video,
    this.preview,
    this.videoFilename,
    this.previewFilename,
  });

  factory SignedUrl.fromJson(Map<String, dynamic> json) => SignedUrl(
    video: json["video"],
    preview: json["preview"],
    videoFilename:  json["videoFilename"],
    previewFilename:  json["previewFilename"],

  );

  Map<String, dynamic> toJson() => {
    "video": video,
    "preview": preview,
    "videoFilename": videoFilename,
    "previewFilename": previewFilename,
  };


}
