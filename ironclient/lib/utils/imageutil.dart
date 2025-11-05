import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/utils/dartimagecropper.dart';
import 'package:ironcirclesapp/utils/permissions.dart';

class ImageUtil {
  static Future<File?> selectImage(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }

      // ImagePicker imagePicker = ImagePicker();
      //
      // var imageFile = await imagePicker.pickImage(
      //   source: ImageSource.gallery,
      // );
      //
      // if (imageFile != null) {
      //   return File(imageFile.path);
      // }
    } catch (err, trace) {
      if (err.toString().contains('photo_access_denied')) {
        Permissions.askOpenSettings(context);
      } else {
        LogBloc.insertError(err, trace);
        debugPrint('$err');
      }
    }

    return null;
  }

  static Future<File?> cropImage(BuildContext context, File? image) async {
    if (image == null) return null;

    File? croppedFile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DartImageCropper(source: image),
        ));

    return croppedFile;
  }

  //
  // static Future<File?> cropImage(String imagePath) async {
  //   ImageCropper imageCropper = ImageCropper();
  //
  //   CroppedFile? croppedFile = await imageCropper.cropImage(
  //       sourcePath: imagePath,
  //       aspectRatioPresets: Platform.isAndroid
  //           ? [
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio16x9
  //             ]
  //           : [
  //               CropAspectRatioPreset.original,
  //               CropAspectRatioPreset.square,
  //               CropAspectRatioPreset.ratio3x2,
  //               CropAspectRatioPreset.ratio4x3,
  //               CropAspectRatioPreset.ratio5x3,
  //               CropAspectRatioPreset.ratio5x4,
  //               CropAspectRatioPreset.ratio7x5,
  //               CropAspectRatioPreset.ratio16x9
  //             ],
  //       uiSettings: [
  //         AndroidUiSettings(
  //             toolbarTitle: 'Adjust image',
  //             backgroundColor: globalState.theme.background,
  //             activeControlsWidgetColor: Colors.blueGrey[600],
  //             toolbarColor: globalState.theme.background,
  //             statusBarColor: globalState.theme.background,
  //             toolbarWidgetColor: globalState.theme.menuIcons,
  //             initAspectRatio: CropAspectRatioPreset.original,
  //             lockAspectRatio: false
  //         ),
  //         IOSUiSettings(
  //           title: 'Adjust image',
  //         )
  //       ]
  //       );
  //   if (croppedFile != null) {
  //     return File(croppedFile.path);
  //   }
  //
  //   return null;
  // }
}
