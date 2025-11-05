import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';

CircleFile circleFileFromJson(String str) =>
    CircleFile.fromJson(json.decode(str));

String circleFileToJson(CircleFile data) => json.encode(data.toJson());

class CircleFile {
  String? file;
  String? name;
  String? extension;
  int? fileSize;
  String? fileCrank;
  String? fileSignature;
  String? id;
  String seed;
  String? location;

  //UI
  File? actualFile;
  String? sourceFile;

  CircleFile(
      {this.id,
      this.file,
      this.name,
      this.extension,
      this.sourceFile,
      this.fileSize,
      this.location,
      this.fileCrank,
      this.fileSignature,
      this.seed = ''});

  factory CircleFile.fromJson(Map<String, dynamic> json) => CircleFile(
        id: json["_id"],
        file: json["file"],
        name: json["name"],
        extension: json["extension"],
        fileSize: json["fileSize"] ?? 0,
        location: json["location"] ?? BlobLocation.GRIDFS,
        fileCrank: json["fileCrank"],
        fileSignature: json["fileSignature"],
        seed: json["seed"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "extension": extension,
        "file": file,
        "fileSize": fileSize,
        "location": location ?? BlobLocation.GRIDFS,
        "fileCrank": fileCrank,
        "fileSignature": fileSignature,
        "seed": seed,
      };

  void revertEncryptionFields(CircleFile original) {
    fileSize = original.fileSize;
    extension = original.extension;
    name = original.name;
  }

  void blankEncryptionFields() {
    fileSize = null;
    extension = null;
    name = null;
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    if (json.containsKey("file")) {
      fileSize = json["file"]["fileSize"];
      name = json["file"]["name"];
      extension = json["file"]["extension"];
    }
  }

  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      ///set the seed value as we are about to remove the list and task names
      Map<String, dynamic> retValue = <String, dynamic>{};

      retValue["fileSize"] = fileSize;
      retValue["name"] = name;
      retValue["extension"] = extension;

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleList.fetchFieldsToEncrypt: ${err.toString()}');
      throw Exception(err);
    }
  }
}
