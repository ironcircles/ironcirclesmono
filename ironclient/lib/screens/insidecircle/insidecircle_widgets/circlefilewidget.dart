import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleFileWidget extends StatelessWidget {
  final String name;
  final String extension;
  final bool preview;
  final double maxWidth;
  final Color backgroundColor;
  final Color textColor;
  final bool showBottomPadding;
  final bool suppressFilename;
  final bool largePreview;
  final int fileSize;
  final bool showDownload;

  const CircleFileWidget({
    required this.name,
    required this.extension,
    this.preview = false,
    required this.backgroundColor,
    required this.textColor,
    this.showBottomPadding = false,
    required this.maxWidth, // = 150,
    this.suppressFilename = false,
    this.largePreview = false,
    this.showDownload = false,
    required this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
          bottom: preview ? 0 : 1,
        ),
        child: SizedBox(
            width: maxWidth,
            height: preview
                ? 80
                : largePreview
                    ? 200
                    : null,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: globalState.theme.background,
                  border: Border.all(
                    color: globalState.theme.fileOutline,
                    width: 1,
                  ),

                  //color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                    //topLeft: Radius.circular(10.0),
                    //topRight: Radius.circular(10.0)),
                  )),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                  color: backgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 2, color: backgroundColor)),
                              child: Center(
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ICText(extension,
                                          color: textColor, fontSize: 14)))),
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                          ),
                          suppressFilename
                              ? Container()
                              : Flexible(
                                  child: ICText(name,
                                      color: textColor,
                                      textAlign: TextAlign.center,
                                      maxLines: preview ? 2 : null,
                                      overflow: preview
                                          ? TextOverflow.ellipsis
                                          : null,
                                      fontSize: largePreview
                                          ? 18
                                          : preview
                                              ? 12
                                              : 14),
                                ),
                        ]),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                          child: Container(
                              padding: const EdgeInsets.all(5),
                              child: ICText(
                                // '${((fileSize / (1024 * 1024)).toStringAsFixed(2))} MB',
                                formatBytes(fileSize, 2),
                                color: textColor,
                              ))),
                      showDownload
                          ? ClipOval(
                              child: Material(
                                color: backgroundColor, // button color
                                child: InkWell(
                                  splashColor: globalState
                                      .theme.chewieRipple, // inkwell color
                                  child: SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: Icon(
                                        Icons.play_for_work,
                                        color: textColor,
                                        size: 25,
                                      )),
                                ),
                              ),
                            )
                          : Container(),
                    ])
                  ]),
            )));
  }

  ///Function that converts kb into mb, gb, tb, etc.
  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
