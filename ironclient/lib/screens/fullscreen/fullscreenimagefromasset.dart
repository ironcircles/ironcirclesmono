import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageAsset extends StatefulWidget {
  const FullScreenImageAsset(
      {required this.assetPath,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      this.initialScale,
      this.basePosition = Alignment.center});

  final String assetPath;
  final Widget? loadingChild;
  final Decoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
  final Alignment basePosition;

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<FullScreenImageAsset> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    _imageProvider = Image.asset(widget.assetPath).image;

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
                                    globalState.theme.button)),
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
