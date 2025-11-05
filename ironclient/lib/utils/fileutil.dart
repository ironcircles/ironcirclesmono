import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';

abstract class FileUtil {
  FileUtil._();

  static Future<void> writeByteDataToFile(String path, ByteData data) async {
    final buffer = data.buffer;
    await File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static Future<File?> writeBytesToFile(String path, Uint8List bytes) async {
    File? retValue;

    try {
      retValue = File(path);
      retValue = await retValue.writeAsBytes(bytes);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('FileUtil.writeBytesToFile: $err');
    }

    return retValue;
  }
}
