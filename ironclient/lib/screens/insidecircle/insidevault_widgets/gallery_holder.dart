import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/library/librarygallery.dart';
import 'package:ironcirclesapp/screens/widgets/backwithdoticon.dart';
import 'package:ironcirclesapp/screens/widgets/extendedfab.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class GalleryHolder extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<CircleObject>? circleObjects;
  final List<CircleObject> memCacheObjects;
  final GlobalEventBloc globalEventBloc;
  final Function captureMedia;
  final Function selectMedia;
  //final Function selectVideos;
  final UserCircleCache userCircleCache;
  final CircleObjectBloc circleObjectBloc;
  final bool Function(ScrollEndNotification) onNotification;
  final Future<void> Function() refresh;
  final Function searchGiphy;
  final Function generateImage;

  const GalleryHolder({
    Key? key,
    required this.refresh,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleObjects,
    required this.memCacheObjects,
    required this.globalEventBloc,
    required this.captureMedia,
    required this.searchGiphy,
    required this.generateImage,
    required this.selectMedia,
    //required this.selectVideos,
    required this.circleObjectBloc,
    required this.onNotification,
  }) : super(key: key);

  @override
  GalleryHolderState createState() => GalleryHolderState();
}

class GalleryHolderState extends State<GalleryHolder> {
  final double _floatingActionSize = 55;
  final double _iconSize = 31;

  //bool shuffle = false;

  @override
  void initState() {
    if (widget.circleObjects != null && globalState.isDesktop()) {
      for (CircleObject item in widget.circleObjects!) {
        if (item.type == CircleObjectType.CIRCLEIMAGE &&
            item.image!.imageBytes == null) {
          int index = widget.memCacheObjects
              .indexWhere((element) => element.seed == item.seed);

          if (index != -1) {
            item.image!.imageBytes =
                widget.memCacheObjects[index].image!.imageBytes;
          }
        } else if (item.type == CircleObjectType.CIRCLEVIDEO &&
            item.video!.previewBytes == null) {
          int index = widget.memCacheObjects
              .indexWhere((element) => element.seed == item.seed);

          if (index != -1) {
            item.video!.previewBytes =
                widget.memCacheObjects[index].video!.previewBytes;
          }
        }
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final generate = InkWell(
        onTap: () {
          widget.generateImage();
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Container(
              width: 65,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: globalState.theme.buttonGenerate.withOpacity(.2),
              ),
              child: Center(
                  child: ICText(
                    AppLocalizations.of(context)!.generate.toLowerCase(),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: globalState.theme.buttonGenerate,
                  )),
                  ),
        ));

    final media = ExtendedFAB(
      label: AppLocalizations.of(context)!.fromDevice,
      color: globalState.theme.libraryFAB,
      onPressed: () {
        widget.selectMedia();
      },
      icon: Icons.add,
    );

    final gif = InkWell(
        onTap: () {
          widget.searchGiphy();
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.withOpacity(0.85),
              ),
              child: const Center(
                child: Icon(
                  Icons.gif_box,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            )));

    final camera = InkWell(
        onTap: () {
          widget.captureMedia();
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.withOpacity(0.85),
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            )));

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
            //key: _scaffoldKey,
            appBar: AppBar(
                elevation: 0,
                toolbarHeight: 45,
                centerTitle: false,
                titleSpacing: 0.0,
                backgroundColor: globalState.theme.background,
                title: Text("Media",
                    style: ICTextStyle.getStyle(
                        context: context,
                        color: globalState.theme.textTitle,
                        fontSize: ICTextStyle.appBarFontSize)),
                leading: BackWithDotIcon(
                  userFurnaces: [widget.userFurnace],
                  goHome: () {
                    _goHome(true);
                  },
                  forceRefresh: false,
                  circleID: widget.userCircleCache.circle!,
                )),
            backgroundColor: globalState.theme.background,
            body: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: LibraryGallery(
                          refresh: widget.refresh,
                          onNotification: widget.onNotification,
                          userCircleCache: widget.userCircleCache,
                          userFurnace: widget.userFurnace,
                          globalEventBloc: widget.globalEventBloc,
                          circleObjects: widget.circleObjects,
                          shuffle: false,
                          captureMedia: widget.captureMedia,
                          circleObjectBloc: widget.circleObjectBloc,
                          mode: "vault",
                          slideUpPanel: false,
                        ),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                        ),
                        camera,
                        gif,
                        generate,
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                        ),
                        const Spacer(),
                        media,
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                        ),
                      ])
                    ]))));
  }

  _goHome(bool samePosition) async {
    debugPrint('***********POPPED****************');
    Navigator.pop(context);
    //widget.refresh();
  }
}
