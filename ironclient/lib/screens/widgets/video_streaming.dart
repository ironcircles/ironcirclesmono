import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class VideoStreamingWidget extends StatefulWidget {
  final CircleObject? circleObject;
  final UserCircleCache? userCircleCache;
  //final UserFurnace userFurnace;
  final Function? share;
  final Function? download;
  final Function? cancel;
  final Function? play;
  final Function? deleteCache;
  final Function stream;
  final bool isUser;
  final Circle? circle;
  // final int state;
  final ChewieController? chewieController;
  final VideoControllerBloc videoControllerBloc;
  final Function dispose;

  const VideoStreamingWidget(
      {this.userCircleCache,
      //this.circle,
      //this.userFurnace,
      this.circleObject,
      this.share,
      this.download,
      this.isUser = false,
      required this.stream,
      this.play,
      this.cancel,
      this.deleteCache,
      this.circle,
      //this.state,
      this.chewieController,
      required this.videoControllerBloc,
      required this.dispose});

  @override
  _VideoStreamingWidgetState createState() => _VideoStreamingWidgetState();
}

class _VideoStreamingWidgetState extends State<VideoStreamingWidget> {
  final double _iconSize = 35;
  //final double _iconPadding = 12;

  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 150),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  final spinkitNoPadding = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.dispose(widget.circleObject);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.videoControllerBloc.disposeObject(widget.circleObject);
    });

    super.dispose();
  }

  Widget build(BuildContext context) {
    //_initializeControllers();

    return Stack(alignment: Alignment.bottomLeft, children: <Widget>[
      Container(
          //padding: EdgeInsets.only(bottom: 2.0),
          // width: 150.0,
          // height: 150.0,
          child: Column(children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            widget.circleObject!.seed != null
                                                ? ConstrainedBox(
                                                    constraints: const BoxConstraints(
                                                        minWidth: InsideConstants
                                                            .MESSAGEBOXSIZE,
                                                        maxWidth: InsideConstants
                                                                .MESSAGEBOXSIZE +
                                                            35),
                                                    child: Padding(
                                                        padding: const EdgeInsets.only(
                                                            top: .0,
                                                            left: 0,
                                                            right: 0,
                                                            bottom: 0),
                                                        child: widget.chewieController ==
                                                                null
                                                            ? widget.circleObject!
                                                                        .video ==
                                                                    null
                                                                ? ConstrainedBox(
                                                                    constraints: const BoxConstraints(
                                                                        maxWidth: InsideConstants
                                                                            .MESSAGEBOXSIZE),
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.all(5.0),
                                                                        child: Center(child: spinkit)
                                                                        //  File(FileSystemServicewidget
                                                                        //.circleObject.gif.giphy),
                                                                        // ),
                                                                        ))
                                                                : widget.circleObject!.video!.videoState == VideoStateIC.VIDEO_UPLOADED || widget.circleObject!.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED || widget.circleObject!.video!.videoState == VideoStateIC.NEEDS_CHEWIE
                                                                    ? Stack(
                                                                        alignment:
                                                                            Alignment.center,
                                                                        children: [
                                                                          SizedBox(
                                                                              width: 300,
                                                                              height: 250,
                                                                              child: Image.file(
                                                                                File(VideoCacheService.returnPreviewPath( widget.circleObject!, widget.userCircleCache!.circlePath!)),
                                                                                fit: BoxFit.contain,
                                                                              )),
                                                                          Padding(
                                                                                  padding: const EdgeInsets.only(right: 5, bottom: 5),
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
                                                                                              size: _iconSize,
                                                                                            )),
                                                                                        onTap: () {
                                                                                          setState(() {
                                                                                            widget.stream(widget.circleObject);
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  ))
                                                                        ],
                                                                      )
                                                                    : ConstrainedBox(
                                                                        constraints:
                                                                            const BoxConstraints(maxWidth: 230),
                                                                        child: Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(5.0),
                                                                            child: Center(child: spinkit)
                                                                            //  File(FileSystemServicewidget
                                                                            //.circleObject.gif.giphy),
                                                                            // ),
                                                                            ),
                                                                      )

                                                            //  File(FileSystemServicewidget
                                                            //.circleObject.gif.giphy),
                                                            // ),

                                                            : /*Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )*/
                                                            SizedBox(
                                                                width: 300,
                                                                height: 250,
                                                                child: AspectRatio(
                                                                    aspectRatio: widget.chewieController!.aspectRatio ?? widget.chewieController!.videoPlayerController.value.aspectRatio,
                                                                    child: Chewie(
                                                                      controller:
                                                                          widget
                                                                              .chewieController!,
                                                                    )))))
                                                : ConstrainedBox(
                                                    constraints: const BoxConstraints(
                                                        maxWidth: 230),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                5.0),
                                                        child: Center(
                                                            child: spinkit)
                                                        //  File(FileSystemServicewidget
                                                        //.circleObject.gif.giphy),
                                                        // ),
                                                        ),
                                                  )
                                          ]),
                                    ]),
                              ),
                            )),
                        widget.circleObject!.id == null
                            ? Align(
                            alignment: Alignment.topRight,
                            child: CircleAvatar(
                              radius: 7.0,
                              backgroundColor:
                              globalState.theme.sentIndicator,
                            ))
                            : Container()
                      ])
                    ],
                  ),
                ),
              ),
            ]),
        const Padding(
          padding: EdgeInsets.only(bottom: 30),
        )
      ])),
    ]);
  }
}
