import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenAvatar extends StatefulWidget {
  const FullScreenAvatar(
      {this.imageProvider,
      this.userid,
      this.avatar,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      this.initialScale,
      this.basePosition = Alignment.center});

  final ImageProvider? imageProvider;
  final Widget? loadingChild;
  final Decoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
  final Alignment basePosition;
  final String? userid;
  final Avatar? avatar;

  @override
  FullScreenAvatarState createState() => FullScreenAvatarState();
}

class FullScreenAvatarState extends State<FullScreenAvatar> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    /*
    _isThumbnailCached(
        widget.circleObject)
        ? Image.file(File(FileSystemService
        .returnThumbnailPath(
        widget
            .userCircleCache
            .circlePath,
        widget
            .circleObject
            .seed)))
    */

    String? path = FileSystemService.returnAnyUserAvatarPath(widget.userid);

    if (path != null) {
      _imageProvider = Image.file(File(path)).image;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ICAppBarTransparent(title: ''),
        backgroundColor: globalState.theme.background,
        body: Stack(children: [
          Container(
              constraints: BoxConstraints.expand(
                height: MediaQuery.of(context).size.height,
              ),
              child: _imageProvider == null
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 248),
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    globalState.theme.button)
                            ),
                          )
                          //  File(FileSystemServicewidget
                          //.circleObject.gif.giphy),
                          // ),
                          ),
                    )
                  : PhotoView(
                      backgroundDecoration:
                          BoxDecoration(color: globalState.theme.background),
                      imageProvider: _imageProvider!,
                      //loadingChild: widget.loadingChild!,
                      //backgroundDecoration: widget.backgroundDecoration!,
                      minScale: widget.minScale,
                      maxScale: widget.maxScale,
                      initialScale: widget.initialScale,
                      basePosition: widget.basePosition,
                    )),
        ]));
  }
}
