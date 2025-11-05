import 'dart:io';
import 'dart:ui';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';

class DartImageCropper extends StatefulWidget {
  final File source;

  const DartImageCropper({Key? key, required this.source}) : super(key: key);

  @override
  State<DartImageCropper> createState() => _LocalState();
}

class _LocalState extends State<DartImageCropper> {
  final controller = CropController(
      //aspectRatio: 0.7,
      //defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.cropImage,
        ),
        body: Center(
          child: CropImage(
            controller: controller,

            image: Image.file(widget.source),
            paddingSize: 35.0,
            alwaysMove: true,
            // minimumImageSize: 500,
            // maximumImageSize: 500,
          ),
        ),
        bottomNavigationBar: _buildButtons(),
      );

  Widget _buildButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.rotation = CropRotation.up;
              controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
              controller.aspectRatio = 1.0;
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: _aspectRatios,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
            onPressed: _rotateLeft,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: _rotateRight,
          ),
          TextButton(
            onPressed: _finished,
            child: ICText(AppLocalizations.of(context)!.done,
                color: globalState.theme.button),
          ),
        ],
      );

  Future<void> _aspectRatios() async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.selectAspectRatio),
          children: [
            // special case: no aspect ratio
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, -1.0),
              child: Text(AppLocalizations.of(context)!.free.toLowerCase()),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1.0),
              child: Text(AppLocalizations.of(context)!.square.toLowerCase()),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 2.0),
              child: const Text('2:1'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1 / 2),
              child: const Text('1:2'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 4.0 / 3.0),
              child: const Text('4:3'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 16.0 / 9.0),
              child: const Text('16:9'),
            ),
          ],
        );
      },
    );
    if (value != null) {
      controller.aspectRatio = value == -1 ? null : value;
      controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
    }
  }

  Future<void> _rotateLeft() async => controller.rotateLeft();

  Future<void> _rotateRight() async => controller.rotateRight();

  Future<void> _finished() async {
    var bitmap = await controller.croppedBitmap();
    final pngByteData = await bitmap.toByteData(format: ImageByteFormat.png);

    final bytes = pngByteData!.buffer.asUint8List();
    File file = await FileSystemService.getNewTempImageFile();
    await file.writeAsBytes(
      bytes,
    );

    Navigator.pop(context, file);
  }
}
