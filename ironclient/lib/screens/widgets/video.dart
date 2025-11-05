import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:ironcirclesapp/screens/widgets/loop_restart_indicator.dart';

class VideoWidget extends StatefulWidget {
  final CircleObject? circleObject;
  final UserCircleCache? userCircleCache;
  //final UserFurnace userFurnace;
  final bool isUser;
  final Function? share;
  final Function? download;
  final Function? export;
  final Function? cancel;
  final Function? play;
  final Function? deleteCache;
  //final Circle? circle;
  // final int state;
  final ChewieController? chewieController;
  final VideoControllerBloc videoControllerBloc;
  final Function dispose;

  const VideoWidget(
      {this.userCircleCache,
      //this.circle,
      //this.userFurnace,
      this.circleObject,
      this.share,
      this.download,
      this.export,
      this.play,
      this.cancel,
      this.deleteCache,
      this.isUser = false,
      //this.circle,
      //this.state,
      this.chewieController,
      required this.videoControllerBloc,
      required this.dispose});

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {


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
    widget.dispose(widget.circleObject);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.videoControllerBloc.disposeObject(widget.circleObject);
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
                                            widget.circleObject!.seed !=
                                                    null
                                                ? ConstrainedBox(
                                                    constraints: const BoxConstraints(
                                                        minWidth:
                                                            InsideConstants
                                                                .MESSAGEBOXSIZE,
                                                        maxWidth:
                                                            InsideConstants
                                                                    .MESSAGEBOXSIZE +
                                                                35),
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
                                                            ? widget.circleObject!
                                                                        .video ==
                                                                    null
                                                                ? ConstrainedBox(
                                                                    constraints:
                                                                        const BoxConstraints(maxWidth: InsideConstants.MESSAGEBOXSIZE),
                                                                    child: Padding(padding: const EdgeInsets.only(left: 5, right: 5), child: Center(child: spinkit)
                                                                        //  File(FileSystemServicewidget
                                                                        //.circleObject.gif.giphy),
                                                                        // ),
                                                                        ))
                                                                : widget.circleObject!.video!.videoState == VideoStateIC.DOWNLOADING_VIDEO
                                                                    ? Stack(alignment: Alignment.center, children: [
                                                                        SizedBox(
                                                                            width: 300,
                                                                            height: 250,
                                                                            child: Image.file(
                                                                              File(VideoCacheService.returnPreviewPath( widget.circleObject!, widget.userCircleCache!.circlePath!)),
                                                                              fit: BoxFit.contain,
                                                                            )),
                                                                        Padding(
                                                                            padding: const EdgeInsets.only(right: 0),
                                                                            child: CircularPercentIndicator(
                                                                              radius: 30.0,
                                                                              lineWidth: 5.0,
                                                                              percent: (widget.circleObject!.transferPercent == null ? 0.01 : widget.circleObject!.transferPercent! / 100),
                                                                              center: Text(widget.circleObject!.transferPercent == null ? '0%' : '${widget.circleObject!.transferPercent}%' , textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                              progressColor: globalState.theme.progress,
                                                                            ))
                                                                      ])
                                                                    : widget.circleObject!.video!.videoState == VideoStateIC.PREVIEW_DOWNLOADED
                                                                        ? Stack(
                                                                            alignment: Alignment.center,
                                                                            children: [
                                                                              SizedBox(
                                                                                  width: 300,
                                                                                  height: 250,
                                                                                  child: Image.file(
                                                                                    File(VideoCacheService.returnPreviewPath( widget.circleObject!, widget.userCircleCache!.circlePath!)),
                                                                                    fit: BoxFit.contain,
                                                                                  )),
                                                                              /*TextButton(child:Text('download', style: TextStyle(fontSize: 24, color: globalState.theme.buttonIcon),
                                                                          ), onPressed: () {},),

                                                                           */
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
                                                                                              Icons.download_rounded,
                                                                                              color: globalState.theme.chewiePlayForeground,
                                                                                              size: 35,
                                                                                            )),
                                                                                        onTap: () {
                                                                                          setState(() {
                                                                                            widget.download!(widget.circleObject);
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  ))
                                                                            ],
                                                                          )
                                                                        : widget.circleObject!.video!.videoState == VideoStateIC.UPLOADING_VIDEO
                                                                            ? Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                children: [
                                                                                  Padding(
                                                                                      padding: const EdgeInsets.only(right: 20, bottom: 10, top: 10),
                                                                                      child: Text(
                                                                                        "Uploading Video",
                                                                                        style: TextStyle(color: globalState.theme.buttonIcon),
                                                                                      )),
                                                                                  Padding(
                                                                                      padding: const EdgeInsets.only(right: 35),
                                                                                      child: CircularPercentIndicator(
                                                                                        radius: 30.0,
                                                                                        lineWidth: 5.0,
                                                                                        percent: (widget.circleObject!.transferPercent == null ? 0 : widget.circleObject!.transferPercent! / 100),
                                                                                        center: Text(widget.circleObject!.transferPercent == null ? '...' : '${widget.circleObject!.transferPercent}%', textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                                        progressColor: globalState.theme.progress,
                                                                                      ))
                                                                                ],
                                                                              )
                                                                            : widget.circleObject!.video!.videoState == VideoStateIC.NEEDS_CHEWIE
                                                                                ? Stack(
                                                                                    alignment: Alignment.center,
                                                                                    children: [
                                                                                      SizedBox(
                                                                                          width: 300,
                                                                                          height: 250,
                                                                                          child: Image.file(
                                                                                            File(VideoCacheService.returnPreviewPath( widget.circleObject!, widget.userCircleCache!.circlePath!)),
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
                                                                                                    widget.play!(widget.circleObject);
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
                                                                width: 300,
                                                                height: 250,
                                                                child: AspectRatio(
                                                                    aspectRatio: widget.chewieController!.aspectRatio ?? widget.chewieController!.videoPlayerController.value.aspectRatio,
                                                                    child: LoopRestartIndicator(
                                                                      controller: widget.chewieController!.videoPlayerController,
                                                                      child: Chewie(
                                                                        controller: widget.chewieController!,
                                                                      ),
                                                                    )))))
                                                : ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxWidth: 230),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
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
