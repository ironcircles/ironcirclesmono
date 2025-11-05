
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogshareto.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenGif extends StatefulWidget {
  const FullScreenGif(
      {this.imageProvider,
      this.circleObject,
      this.userCircleCache,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      this.initialScale,
      this.basePosition = Alignment.center,
      this.circle});

  final Circle? circle;
  final ImageProvider? imageProvider;
  final Widget? loadingChild;
  final Decoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
  final Alignment basePosition;
  final CircleObject? circleObject;
  final UserCircleCache? userCircleCache;

  @override
  FullScreenGifState createState() => FullScreenGifState();
}

class FullScreenGifState extends State<FullScreenGif> {
  ImageProvider? _imageProvider;
  CircleBloc _circleBloc = CircleBloc();
  Circle? _circle;

  @override
  void initState() {
    if (widget.circleObject!.gif != null) {
      _imageProvider = Image.network(
        widget.circleObject!.gif!.giphy!,
      ).image;
    }

    _circleBloc.fetchedResponse.listen((circle) {
      if (mounted) {
        if (_circle == null) {
          setState(() {
            _circle = circle;
          });
        }
      }
    }, onError: (err) {
      debugPrint("ThumbnailWidget.listen: $err");
    }, cancelOnError: false);

    if (widget.circle == null) {
      _circleBloc.fetchCircle(widget.circleObject!.userFurnace!,
          widget.circleObject!.userCircleCache!.circle!, null);
    } else
      _circle = widget.circle;

    super.initState();
  }

  void _share() async {
    DialogShareTo.shareToPopup(
        context, widget.userCircleCache!, widget.circleObject!, ShareCircleObject.shareToDestination);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globalState.theme.background,
        /*appBar: AppBar(
          automaticallyImplyLeading: true,
          iconTheme: IconThemeData(
            color: globalState.theme.menuIcons, //change your color here
          ),
          //title: Text("Title"),
        ),

         */
        body: Stack(children: [
          Container(
              color: globalState.theme.background,
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
                      //loadingChild: widget.loadingChild,
                      //backgroundDecoration: widget.backgroundDecoration,
                      minScale: widget.minScale,
                      maxScale: widget.maxScale,
                      initialScale: widget.initialScale,
                      basePosition: widget.basePosition,
                    )),
          Align(
              alignment: Alignment.topLeft,
              child: Padding(
                  padding: const EdgeInsets.only(top: 45, left: 0),
                  child: FloatingActionButton(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0))
                      ),
                      heroTag: "back",
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back,
                          color: globalState.theme.menuIcons)))),
        ]),
        floatingActionButton: _circle != null
            ? _circle!.privacyShareGif == true
                ? FloatingActionButton(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0))
                    ),
                    heroTag: 'share',
                    backgroundColor: globalState.theme.button,
                    onPressed: _share,
                    child: Icon(
                      Icons.share,
                      color: globalState.theme.background,
                    ))
                : null
            : null);
  }
}
