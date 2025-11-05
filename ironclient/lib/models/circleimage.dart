// To parse this JSON data, do
//
//     final circleImage = circleImageFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';

class ThumbnailDimensions {
  int width;
  int height;
  bool errorOccurred;

  ThumbnailDimensions({required this.width, required this.height, this.errorOccurred = false});

  static ThumbnailDimensions getDimensionsFromFile(File image,
      {bool reduceSize = true}) {
    try {
      /*

      EXIF Orientation Value	Row #0 is:	Column #0 is:
      1	Top	Left side
      2*	Top	Right side
      3	Bottom	Right side
      4*	Bottom	Left side
      5*	Left side	Top
      6	Right side	Top
      7*	Right side	Bottom
      8	Left side	Bottom
      */

      late var orientation;

      ThumbnailDimensions thumbnailDimensions =
          ThumbnailDimensions(width: 0, height: 0);
      imageLib.Image? fileImage = imageLib.decodeImage(image.readAsBytesSync());

      if (fileImage == null) throw ('could not load image');

      if (fileImage.exif.containsKey('274)')) {
        orientation = fileImage.exif['274'];

        if (orientation == 1) {
          thumbnailDimensions.width = fileImage.width;
          thumbnailDimensions.height = fileImage.height;
        } else if (orientation == 3) {
          thumbnailDimensions.width = fileImage.width;
          thumbnailDimensions.height = fileImage.height;
        } else if (orientation == 6) {
          thumbnailDimensions.width = fileImage.height;
          thumbnailDimensions.height = fileImage.width;
        } else if (orientation == 8) {
          thumbnailDimensions.width = fileImage.height;
          thumbnailDimensions.height = fileImage.width;
        } else {
          thumbnailDimensions.width = fileImage.width;
          thumbnailDimensions.height = fileImage.height;
        }
      } else {
        thumbnailDimensions.width = fileImage.width;
        thumbnailDimensions.height = fileImage.height;
      }

      if (reduceSize &&
          thumbnailDimensions.width > ImageConstants.THUMBNAIL_WIDTH) {
        double ratio =
            thumbnailDimensions.width / ImageConstants.THUMBNAIL_WIDTH;
        thumbnailDimensions.width = ImageConstants.THUMBNAIL_WIDTH.toInt();

        thumbnailDimensions.height = (thumbnailDimensions.height ~/ ratio);
      }

      return thumbnailDimensions;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      return ThumbnailDimensions(width: 200, height: 200, errorOccurred: true);
    }
  }
}

//part 'circleimage.g.dart';

CircleImage circleImageFromJson(String str) =>
    CircleImage.fromJson(json.decode(str));

String circleImageToJson(CircleImage data) => json.encode(data.toJson());

//@HiveType(typeId: 9)
class CircleImage {
  //@HiveField(0)
  String? thumbnail;
  //@HiveField(1)
  String? fullImage;
  //@HiveField(2)
  int? thumbnailSize;
  //@HiveField(3)
  int? fullImageSize;
  //@HiveField(4)
  String? thumbCrank;
  //@HiveField(5)
  String? fullCrank;
  //@HiveField(6)
  String? thumbSignature;
  //@HiveField(7)
  String? fullSignature;
  //@HiveField(8)
  String? id;
  //@HiveField(9)
  int? height;
  //@HiveField(10)
  int? width;
  //@HiveField(10)
  String seed;

  //DecryptArguments? thumbArgs;
  //DecryptArguments? fullArgs;

  String? location;

  //UI
  File? thumbnailFile;
  File? fullFile;
  Uint8List? imageBytes;

  CircleImage(
      {this.id,
      this.thumbnail,
      this.fullImage,
      this.height,
      this.width,
      //this.imageType,
      this.fullImageSize,
      this.thumbnailSize,
      this.location,
      this.thumbCrank,
      this.fullCrank,
      this.thumbSignature,
      this.fullSignature,
      this.seed = ''});

  factory CircleImage.fromJson(Map<String, dynamic> json) => CircleImage(
        id: json["_id"],
        thumbnail: json["thumbnail"],
        fullImage: json["fullImage"],
        //imageType: json["imageType"] == null ? null : json["imageType"],
        thumbnailSize: json["thumbnailSize"] ?? 0,
        fullImageSize: json["fullImageSize"] ?? 0,
        height: json["height"],
        width: json["width"],
        location: json["location"] ?? BlobLocation.GRIDFS,
        thumbCrank: json["thumbCrank"],
        fullCrank: json["fullCrank"],
        thumbSignature: json["thumbSignature"],
        fullSignature: json["fullSignature"],
        seed: json["seed"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "thumbnail": thumbnail,
        "fullImage": fullImage,
        // "imageType": imageType == null ? null : imageType,
        "thumbnailSize": thumbnailSize ?? 0,
        "fullImageSize": fullImageSize ?? 0,
        "height": height, // == null ? 0 : thumbnailSize,
        "width": width, // == null ? 0 : fullImageSize,
        "location": location ?? BlobLocation.GRIDFS,
        "thumbCrank": thumbCrank,
        "fullCrank": fullCrank,
        "thumbSignature": thumbSignature,
        "fullSignature": fullSignature,
        "seed": seed,
      };

  void revertEncryptionFields(CircleImage original) {
    thumbnailSize = original.thumbnailSize;
    fullImageSize = original.fullImageSize;
    height = original.height;
    width = original.width;
  }

  void blankEncryptionFields() {
    thumbnailSize = null;
    fullImageSize = null;
    height = null;
    width = null;
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    if (json.containsKey("image")) {
      thumbnailSize = json["image"]["thumbnailSize"];
      fullImageSize = json["image"]["fullImageSize"];
      height = json["image"]["height"];
      width = json["image"]["width"];
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      //set the seed value as we are about to remove the list and task names
      Map<String, dynamic> retValue = Map<String, dynamic>();

      retValue["thumbnailSize"] = thumbnailSize;
      retValue["fullImageSize"] = fullImageSize;
      retValue["height"] = height;
      retValue["width"] = width;

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleList.fetchFieldsToEncrypt: ${err.toString()}');
      throw Exception(err);
    }
  }
}

class CircleImageCollection {
  final List<CircleImage> albumImages;

  CircleImageCollection.fromJSON(Map<String, dynamic> json, String key)
      : albumImages = (json[key] as List)
            .map((json) => CircleImage.fromJson(json))
            .toList();
}
