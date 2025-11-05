import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';

class AlbumThumbnailWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserCircleCache userCircleCache;
  final AlbumItem item;
  final Function longPress;
  final Function tap;
  final bool isSelected;
  final bool anythingSelected;
  final bool isReordering;
  final Function fullScreen;

  const AlbumThumbnailWidget({
    required this.circleObject,
    required this.userCircleCache,
    required this.item,
    required this.longPress,
    required this.tap,
    required this.isSelected,
    required this.anythingSelected,
    required this.isReordering,
    required this.fullScreen,
  });

  @override
  AlbumThumbnailWidgetState createState() => AlbumThumbnailWidgetState();
}

class AlbumThumbnailWidgetState extends State<AlbumThumbnailWidget> {
  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
        onLongPress: widget.isReordering
          ? null
          : () {
          widget.longPress(widget.item);
        },
        onTap: widget.isReordering
          ? null
          : () {
          widget.tap(widget.item);
        },
      child:ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.item.type == AlbumItemType.IMAGE
               ? (ImageCacheService.isAlbumThumbnailCached(
                widget.circleObject,
                widget.item,
                widget.userCircleCache.circlePath!,
                ))
              ? Image.file(
                File(ImageCacheService.returnExistingAlbumImagePath(
                    widget.userCircleCache.circlePath!,
                    widget.circleObject,
                    widget.item.image!.thumbnail!)),
                fit: BoxFit.cover,
              )
                  : spinkit
              : widget.item.gif != null
                ? CachedNetworkImage(
                fit: BoxFit.contain,
                imageUrl: widget.item.gif!.giphy!,
                placeholder: (context, url) => spinkit,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
              : spinkit,
              widget.isSelected
                  ? Container(
                color: const Color.fromRGBO(124, 252, 0, 0.5),
                alignment: Alignment.center,
              )
                  : Container(),
              widget.isSelected
                  ? Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.check_circle,
                      color: globalState.theme.buttonIcon,
                    ))
              )
                  : widget.anythingSelected
                  ? Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.circle_outlined,
                      color: globalState.theme.buttonDisabled,
                    ))
              )
                  : Container(),
              widget.anythingSelected
                  ? Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      widget.fullScreen(
                        widget
                            .item, /*widget.circleObject!.circle*/
                      );
                    },
                  ))
                  : Container()
            ],
          ))
    );

  }
}
