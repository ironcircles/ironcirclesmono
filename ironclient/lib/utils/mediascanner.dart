import 'dart:io';
import 'package:flutter/services.dart';

class MediaScanner {
  static const MethodChannel _channel = MethodChannel('media_scanner_channel');

  /// Scans a single file to make it immediately visible in the media gallery
  ///
  /// [filePath] The absolute path to the file that needs to be scanned
  ///
  /// Returns a [Future] that completes with true if successful or false if failed
  static Future<bool> scanFile(String filePath) async {
    if (!Platform.isAndroid) {
      // This functionality is only needed on Android
      return true;
    }

    try {
      final result = await _channel.invokeMethod('scanFile', {'filePath': filePath});
      return result == true;
    } on PlatformException catch (e) {
      print('Failed to scan file: ${e.message}');
      return false;
    }
  }

  /// Scans multiple files at once
  ///
  /// [filePaths] List of absolute file paths to scan
  ///
  /// Returns a [Future] that completes with the count of successfully scanned files
  static Future<int> scanFiles(List<String> filePaths) async {
    if (!Platform.isAndroid) {
      // This functionality is only needed on Android
      return filePaths.length;
    }

    int successCount = 0;
    for (String path in filePaths) {
      bool success = await scanFile(path);
      if (success) {
        successCount++;
      }
    }
    return successCount;
  }
}