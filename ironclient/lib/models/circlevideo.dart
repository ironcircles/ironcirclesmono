import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';

CircleVideo circleVideoFromJson(String str) =>
    CircleVideo.fromJson(json.decode(str));

String circleVideoToJson(CircleVideo data) => json.encode(data.toJson());

class CircleVideo {
  String? preview;
  String? video;
  //String? s3Video;
  //String? s3Preview;
  String? extension;
  String? location;
  int? previewSize;
  int? videoSize;
  int? videoState;
  bool? streamable;
  bool streamableCached;
  String streamingUrl = ''; //don't persist this
  int? width;
  int? height;
  String? thumbCrank;
  String? fullCrank;
  String? thumbSignature;
  String? fullSignature;

  //UI
  File? previewFile;
  File? videoFile;
  String? sourceVideo;
  int? videoPlayerIndex;
  Uint8List? previewBytes;
  Uint8List? videoBytes;
  bool caching =false;

  //int? transferPercent;
  //CancelToken? cancelToken;

  CircleVideo(
      {this.preview,
      this.video,
      //this.s3Video,
      //this.s3Preview,
      this.width,
      this.height,
      this.extension,
      this.location,
      this.previewSize,
      this.videoSize,
      this.videoState,
      this.sourceVideo,
      this.thumbCrank,
      this.fullCrank,
      this.thumbSignature,
      this.fullSignature,
      this.streamable,
      this.streamableCached = false});

  factory CircleVideo.fromJson(Map<String, dynamic> json) => CircleVideo(
        preview: json["preview"],
        video: json["video"],
        height: json["height"],
        width: json["width"],
        //s3Video: json["s3Video"] == null ? null : json["s3Video"],
        extension: json["extension"],
        videoState: json["videoState"],
        //s3Preview: json["s3Preview"] == null ? null : json["s3Preview"],
        location:
            json["location"] ?? BlobLocation.GRIDFS,
        videoSize: json["videoSize"] ?? 0,
        previewSize: json["previewSize"] ?? 0,
        sourceVideo: json["sourceVideo"],
        thumbCrank: json["thumbCrank"],
        fullCrank: json["fullCrank"],
        thumbSignature:
            json["thumbSignature"],
        fullSignature:
            json["fullSignature"],
        streamable: json["streamable"],
        streamableCached:
            json["streamableCached"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "preview": preview,
        "video": video,
        "height": height,
        "width": width,
        "extension": extension,
        "videoState": videoState ?? 0,
        "location": location ?? BlobLocation.GRIDFS,
        "previewSize": previewSize ?? 0,
        "videoSize": videoSize ?? 0,
        "sourceVideo": sourceVideo,
        "thumbCrank": thumbCrank,
        "fullCrank": fullCrank,
        "thumbSignature": thumbSignature,
        "fullSignature": fullSignature,
        "streamable": streamable,
        "streamableCached": streamableCached,
      };

  void revertEncryptionFields(CircleVideo original) {
    previewSize = original.previewSize;
    videoSize = original.videoSize;
    height = original.height;
    width = original.width;
  }

  void blankEncryptionFields() {
    previewSize = null;
    videoSize = null;
    height = null;
    width = null;
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    if (json.containsKey("video")) {
      previewSize = json["video"]["previewSize"];
      videoSize = json["video"]["videoSize"];
      height = json["video"]["height"];
      width = json["video"]["width"];
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      //set the seed value as we are about to remove the list and task names
      Map<String, dynamic> retValue = Map<String, dynamic>();

      retValue["previewSize"] = previewSize;
      retValue["videoSize"] = videoSize;
      retValue["height"] = height;
      retValue["width"] = width;

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleVideo.fetchFieldsToEncrypt: ${err.toString()}');
      throw Exception(err);
    }
  }
}
