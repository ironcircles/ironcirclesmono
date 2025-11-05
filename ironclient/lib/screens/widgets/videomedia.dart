import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/videocontrollermedia_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class VideoMediaWidget extends StatefulWidget {
  final Media video;
  final Function? play;
  final ChewieController? chewieController;
  final VideoControllerMediaBloc videoControllerBloc;
  final Function dispose;
  final double width;
  final double height;


  const VideoMediaWidget(
      {required this.video,
      this.play,
      this.chewieController,
      required this.videoControllerBloc,
      required this.dispose, this.width = 300, this.height=250});

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoMediaWidget> {
  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 150),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.dispose(widget.video);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.videoControllerBloc.disposeObject(widget.video);
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //_initializeControllers();

    return Stack(alignment: Alignment.bottomLeft, children: <Widget>[
      Column(children: <Widget>[
        Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.only(left: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Stack(children: <Widget>[
                        Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      (MediaQuery.of(context).size.width)),
                              //maxWidth: 250,
                              //height: 20,
                              child: Container(
                                padding: const EdgeInsets.all(0.0),
                                //color: globalState.theme.dropdownBackground,

                                child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                             ConstrainedBox(
                                                    constraints:  BoxConstraints(
                                                        minWidth:
                                                            widget.width,
                                                        maxWidth:
                                                        widget.width),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: .0,
                                                                left: 0,
                                                                right: 0,
                                                                bottom: 0),
                                                        child: widget.chewieController ==
                                                                null

                                                                   ? widget.video.videoState == VideoStateIC.NEEDS_CHEWIE
                                                                                ? Stack(
                                                                                    alignment: Alignment.center,
                                                                                    children: [
                                                                                      SizedBox(
                                                                                          width: widget.width,
                                                                                          height: widget.height,
                                                                                          child: Image.file(
                                                                                            File(widget.video.thumbnail),
                                                                                            fit: BoxFit.contain,
                                                                                          )),
                                                                                      /*TextButton(child:Text('download', style: TextStyle(fontSize: 24, color: globalState.theme.buttonIcon),
                                                                          ), onPressed: () {},),

                                                                           */
                                                                                      Padding(
                                                                                          padding: const EdgeInsets.only(right: 0, bottom: 0),
                                                                                          child: ClipOval(
                                                                                            child: Material(
                                                                                              color: globalState.theme.chewiePlayBackground, // button color
                                                                                              child: InkWell(
                                                                                                splashColor: globalState.theme.chewieRipple, // inkwell color
                                                                                                child: SizedBox(
                                                                                                    width: 65,
                                                                                                    height: 65,
                                                                                                    child: Icon(
                                                                                                      Icons.play_arrow,
                                                                                                      color: globalState.theme.chewiePlayForeground,
                                                                                                      size: 35,
                                                                                                    )),
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    widget.play!(widget.video);
                                                                                                  });
                                                                                                },
                                                                                              ),
                                                                                            ),
                                                                                          ))
                                                                                    ],
                                                                                  )
                                                                                : ConstrainedBox(
                                                                                    constraints: const BoxConstraints(maxWidth: InsideConstants.MESSAGEBOXSIZE),
                                                                                    child: Padding(padding: const EdgeInsets.all(5.0), child: Center(child: spinkit)
                                                                                        //  File(FileSystemServicewidget
                                                                                        //.circleObject.gif.giphy),
                                                                                        // ),
                                                                                        ),
                                                                                  )
                                                            : SizedBox(
                                                                width: widget.width,
                                                                height: widget.height,
                                                                child: AspectRatio(
                                                                    aspectRatio: widget.chewieController!.aspectRatio ?? widget.chewieController!.videoPlayerController.value.aspectRatio,
                                                                    child: Chewie(
                                                                      controller:
                                                                          widget.chewieController!,
                                                                    )))))


                                          ]),
                                    ]),
                              ),
                            )),
                      ])
                    ],
                  ),
                )),
          ),
        ]),
        /*widget.circleObject!.showOptionIcons
        ? Padding(
            padding: EdgeInsets.only(bottom: 30),
          )
        : Container(),

         */
      ]),
      /*LibraryBottomIcons(
        circleObject: widget.circleObject,
        cancel: widget.cancel,
        deleteCache: widget.deleteCache,
        share: widget.circleObject!.video!.videoState == VideoStateIC.VIDEO_READY
            ? widget.circle != null
                ? widget.circle!.privacyShareImage == null
                    ? null
                    : widget.circle!.privacyShareImage!
                        ? widget.share
                        : null
                : null
            : null,
      )

       */
    ]);
  }

  /*
  bool _isThumbnailCached(CircleObject circleObject) {
    if (circleObject.seed == null) return false;

    bool retValue = FileSystemService.isThumbnailCached(
        widget.userCircleCache.circlePath, circleObject.seed);

    if (retValue == false &&
        _fetchingImage == false &&
        circleObject.image != null) {
      //request the object be cached
      _circleObjectBloc.downloadCircleImageThumbnail(
          widget.userCircleCache, widget.userFurnace, circleObject);
      _circleObjectBloc.downloadCircleImageFull(
          widget.userCircleCache, widget.userFurnace, circleObject);

      // _fetchingImage = true;
    }

    return retValue;
  }
  */

}
