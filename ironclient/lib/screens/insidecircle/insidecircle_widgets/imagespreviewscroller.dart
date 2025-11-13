import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlefilewidget.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/voice_memo_service.dart';
import 'package:ironcirclesapp/screens/widgets/voice_memo_attachment_chip.dart';

class ImagesPreviewScroller extends StatefulWidget {
  final MediaCollection? mediaCollection;
  final Function onPress;
  final Function onDelete;

  const ImagesPreviewScroller({
    this.mediaCollection,
    required this.onPress,
    required this.onDelete,
  });

  @override
  _ImagesPreviewScrollerState createState() => _ImagesPreviewScrollerState();
}

class _ImagesPreviewScrollerState extends State<ImagesPreviewScroller> {
  final ScrollController _scrollController = ScrollController();

  final int height = 100;
  final int width = 100;

  bool hiRes = false;

  //List<bool> _album = [true, false];

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Column(children: <Widget>[
        SizedBox(
            height: height + 5.0,
            width: MediaQuery.of(context).size.width - 69,
            child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                    itemCount: widget.mediaCollection!.media.length,
                    padding: const EdgeInsets.only(right: 0, left: 0),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      final media =
                          widget.mediaCollection!.media[index];
                      final attachment = media.attachment;
                      final bool isVoiceMemo =
                          attachment is EncryptedVoiceMemo;

                      return Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 5),
                          child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InkWell(
                                    onTap: isVoiceMemo
                                        ? null
                                        : () => widget.onPress(index),
                                    child: Builder(builder: (context) {
                                      Widget preview;
                                      if (attachment is EncryptedVoiceMemo) {
                                        preview = VoiceMemoAttachmentChip(
                                          memo: attachment,
                                        );
                                      } else if (media.mediaType ==
                                          MediaType.file) {
                                        preview = CircleFileWidget(
                                            maxWidth: 150,
                                            extension:
                                                FileSystemService.getExtension(
                                                    media.path),
                                            backgroundColor: globalState
                                                .theme.userObjectBackground,
                                            fileSize: media.file.lengthSync(),
                                            textColor:
                                                globalState.theme.userObjectText,
                                            name: FileSystemService.getFilename(
                                                media.path),
                                            preview: true);
                                      } else if (media.mediaType ==
                                          MediaType.image) {
                                        preview = _isPreviewCached(File(media.path))
                                            ? Image.file(
                                                File(media.path),
                                                fit: BoxFit.contain,
                                              )
                                            : spinkit;
                                      } else if (media.mediaType ==
                                          MediaType.gif) {
                                        preview = CachedNetworkImage(
                                          fit: BoxFit.contain,
                                          imageUrl: media.path,
                                          placeholder: (context, url) => spinkit,
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        );
                                      } else {
                                        preview = _isPreviewCached(
                                                File(media.thumbnail))
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                    Image.file(
                                                      File(media.thumbnail),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    IconButton(
                                                      onPressed: null,
                                                      color: globalState
                                                          .theme
                                                          .chewiePlayBackground,
                                                      icon: Icon(
                                                        Icons.play_arrow,
                                                        color: globalState.theme
                                                            .chewiePlayForeground,
                                                      ),
                                                    )
                                                  ])
                                            : spinkit;
                                      }

                                      return ConstrainedBox(
                                        constraints: isVoiceMemo
                                            ? const BoxConstraints(
                                                maxHeight: 150, maxWidth: 260)
                                            : const BoxConstraints(
                                                maxHeight: 170, maxWidth: 250),
                                        child: preview,
                                      );
                                    })),

                                IconButton(
                                  padding: const EdgeInsets.only(left: 25, bottom: 25),
                                    icon: Icon(
                                      Icons.cancel,
                                      color: globalState.theme.buttonIcon,
                                    ),
                                    color: globalState.theme.background,
                                    onPressed: () {
                                      widget.onDelete(index);
                                    }
                                ),
                              ]));
                    }))),
      ]),
    );
  }

  bool _isPreviewCached(File pickedFile) {
    return true;
    /*
    bool retValue = FileSystemService.fileExists(pickedFile.path);

    return retValue;

     */
  }
}

/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

class ImagesPreviewScroller extends StatefulWidget {
  final List<File>? images;
  final Function setAlbum;
  final Function removeImage;
  final Function crop;
  final Function markup;
  final Function setHiRes;

  //List<bool> album; // = [true, false];
  //final Function shuffle;
  //final Function cancel;
  //final Function send;

  ImagesPreviewScroller(
      {this.images,
      required this.setAlbum,
      required this.removeImage,
      required this.setHiRes,
      required this.crop,
      required this.markup});

  @override
  _ImagesPreviewScrollerState createState() => _ImagesPreviewScrollerState();
}

class _ImagesPreviewScrollerState extends State<ImagesPreviewScroller> {
  final ScrollController _scrollController = ScrollController();

  final int height = 160;
  final int width = 160;

  bool hiRes = false;

  //List<bool> _album = [true, false];

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 0, bottom: 0),
      child:
          //Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
          /*ToggleButtons(
              selectedColor: globalState.theme.button,
              //highlightColor: Colors.yellow,
              children: <Widget>[
                SizedBox(
                    width: 120,
                    child: Center(
                        child: Text(
                      'individual',
                      style: TextStyle(
                          color: _album[0]
                              ? globalState.theme.buttonIcon
                              : globalState.theme.labelTextSubtle),
                    ))),
                SizedBox(
                    width: 120,
                    child: Center(
                        child: Text(
                      'album',
                      style: TextStyle(
                          color: _album[1]
                              ? globalState.theme.buttonIcon
                              : globalState.theme.labelTextSubtle),
                    ))),
              ],
              onPressed: (int index) {
                setState(() {
                  if (index == 0) {
                    _album = [true, false];
                  } else {
                    _album = [false, true];
                  }

                  widget.setAlbum(_album);
                });
              },
              isSelected: _album,
            )*/
          // ]),
          Column(children: <Widget>[
        SizedBox(
            height: height + 5.0,
            width: MediaQuery.of(context).size.width - 20,
            child: Scrollbar(
                controller: _scrollController,
                isAlwaysShown: true,
                child: ListView.builder(
                    itemCount: widget.images!.length,
                    padding: const EdgeInsets.only(right: 0, left: 0),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // crossAxisCount: 1,
                    //  ),
                    itemBuilder: (BuildContext context, int index) {
                      File currentRow = widget.images![index];

                      return _isPreviewCached(currentRow)
                          ? Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.only(
                                            bottom: 25, right: 5),
                                        child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxHeight: 170, maxWidth: 250),
                                            child: Image.file(
                                              File(currentRow.path),
                                              fit: BoxFit.cover,
                                            ))),
                                    ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxHeight: 100, maxWidth: 144),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Expanded(child: SizedBox()),
                                              IconButton(
                                                icon: Icon(Icons.brush,
                                                    color: globalState
                                                        .theme.buttonIcon),
                                                onPressed: () {
                                                  widget.markup(index);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.crop,
                                                    color: globalState
                                                        .theme.buttonIcon),
                                                onPressed: () {
                                                  widget.crop(index);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.cancel_rounded,
                                                    color: globalState
                                                        .theme.buttonDisabled),
                                                /*iconSize: 22,*/
                                                //constraints: BoxConstraints(maxHeight: 20),
                                                onPressed: () {
                                                  widget.removeImage(index);
                                                  // _openRegistration(context);
                                                },
                                              ),
                                            ])),
                                  ]))
                          : spinkit;
                    }))),
        Align(
            alignment: Alignment.centerRight,
            child: Toggle.ToggleSwitch(
              //minWidth: 90.0,
              //minHeight: 70.0,
              initialLabelIndex: 0,
              cornerRadius: 20.0,
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              totalSwitches: 2,
              radiusStyle: true,
              labels: ['efficient', 'hi-res'],
              //iconSize: 30.0,
              activeBgColors: [
                [ Colors.tealAccent, Colors.teal,],
                [Colors.yellow, Colors.orange]
              ],
              animate:
                  true, // with just animate set to true, default curve = Curves.easeIn
              curve: Curves
                  .bounceInOut, // animate must be set to true when using custom curve
              onToggle: (index) {
                debugPrint('switched to: $index');
              },
            )),
      ]),
    );
  }

  bool _isPreviewCached(File pickedFile) {
    return true;
    /*
    bool retValue = FileSystemService.fileExists(pickedFile.path);

    return retValue;

     */
  }
}

 */
