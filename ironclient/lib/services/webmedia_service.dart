import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/services/blob_generic_service.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class WebMediaService {
  static Future<String> downloadMedia(String url) async {
    final BlobGenericService _blobGenericService = BlobGenericService();

    try {
      String imagePath = await FileSystemService.returnTempPathAndImageFile();

      await _blobGenericService.getFromWeb(url, imagePath);

      return imagePath;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("AvatarService.downloadAvatar: $err");
      rethrow;
    }
  }
}
