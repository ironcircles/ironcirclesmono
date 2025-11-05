import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideo extends StatefulWidget {
  final String url;
  final String title;
  final String description;
  final bool fullScreenByDefault;
  const FullScreenVideo(
      {required this.url,
      required this.title,
      required this.description,
      required this.fullScreenByDefault});

  _FullScreenVideoState createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;

  _initController() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      allowFullScreen: true,
      allowedScreenSleep: false,
      //fullScreenByDefault: widget.fullScreenByDefault,
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      allowPlaybackSpeedChanging: true,
    );

    setState(() {});
  }

  @override
  void initState() {
    _initController();
    super.initState();
  }

  @override
  void dispose() {
    _chewieController!.pause();
    _videoPlayerController!.dispose();
    _chewieController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = _chewieController == null
        ? Container()
        : Center(child :ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: (MediaQuery.of(context).size.width-50),
                maxHeight: (MediaQuery.of(context).size.height-150)),
            child: AspectRatio(
                aspectRatio: _chewieController!.aspectRatio ??
                    _chewieController!.videoPlayerController.value.aspectRatio,
                child: Chewie(
                  controller: _chewieController!,
                ))));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      appBar: AppBar(
        backgroundColor: globalState.theme.appBar,
        iconTheme: IconThemeData(
          color: globalState.theme.menuIcons, //change your color here
        ),
        title: Text(widget.title),
      ),
      body: Column(
        //crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          //Expanded(child: makeBody),
          makeBody,

          /* Container(
            //  color: Colors.white,
            padding: EdgeInsets.all(0.0),
            child: makeBottom,
          ),*/
        ],
      ),
    );
  }
}
