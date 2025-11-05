import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';
import 'package:provider/provider.dart';

class AlbumWidget extends StatefulWidget {
  final double width;
  final double height;
  final CircleObject circleObject;
  final UserCircleCache userCircleCache;
  final bool isUser;
  final Function longPress;
  final Function shortPress;
  final Function fullScreen;
  final bool anythingSelected;
  final bool isSelected;
  final bool isSelecting;
  final List<CircleObject>? libraryObjects;
  final CircleObjectBloc circleObjectBloc;

  const AlbumWidget(
      {required this.userCircleCache,
        required this.height,
        required this.width,
        required this.circleObject,
        this.libraryObjects,
        required this.isSelected,
        required this.anythingSelected,
        required this.fullScreen,
        required this.longPress,
        required this.shortPress,
        this.isUser = false,
        required this.isSelecting,
        required this.circleObjectBloc});

  @override
  _AlbumWidgetState createState() => _AlbumWidgetState();
}

class _AlbumWidgetState extends State<AlbumWidget> {
  late CircleAlbumBloc _circleAlbumBloc;
  late GlobalEventBloc _globalEventBloc;
  late CircleObjectBloc _circleObjectBloc;

  List<AlbumItem> _currentItems = [];

  final spinkit = Padding(
      padding: const EdgeInsets.only(left: 0),
      child: SpinKitThreeBounce(
        size: 20,
        color: globalState.theme.threeBounce,
      ));

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  // double width = 200;
  // double height = 200;

  @override
  void initState() {

    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _circleAlbumBloc = CircleAlbumBloc(_globalEventBloc);
    _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);

    _circleAlbumBloc.notifyWhenAlbumReady(
      globalState.userFurnace!,
      widget.userCircleCache,
      widget.circleObject,
      _circleObjectBloc,
    );

    widget.circleObjectBloc!.refreshVault.listen((refresh) async {
      debugPrint('album widget vault refresh:' + refresh.toString());
      if (mounted) {
        setState(() {
          if (widget.circleObject.album!.media.isNotEmpty) {
            _currentItems = widget.circleObject.album!.media.where((element) => element.removeFromCache == false).toList();
            _currentItems.sort((a, b) => a.index.compareTo(b.index));
          }
        });
      }
    }, onError: (err) {
      debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
    }, cancelOnError: false);

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Circle? _circle;

    double gridSize = globalState.isDesktop() ? widget.width : 200;
    double gridItemSize = gridSize / 2;

    _currentItems = [];

    for (AlbumItem item in widget.circleObject.album!.media) {
      if (item.removeFromCache == false) {
        _currentItems.add(item);
      }
    }
    if (_currentItems.isNotEmpty) {
      _currentItems.sort((a, b) => a.index.compareTo(b.index));
    }

    return Expanded(
        child: InkWell(
            onLongPress: () {
              widget.longPress(widget.circleObject);
            },
            onTap: () {
              widget.shortPress(widget.circleObject, _circle);
            },
            child: Padding(
                padding: EdgeInsets.all(widget.isSelected ? 0 : 0),
                child:
                Stack(alignment: Alignment.topLeft, children: <Widget>[
                  SizedBox(
                      width: gridSize,
                      height: gridSize,
                      //color: globalState.theme.background,
                      child: _currentItems.isNotEmpty
                          ? GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 3) {
                              return SizedBox(
                                  width: gridItemSize,//100,
                                  height: gridItemSize, //100,
                                  child: ClipRect(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState.theme.memberObjectBackground,
                                              //borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10.0))
                                              ),
                                          child: Center(
                                              child: Icon(
                                                Icons.photo_library,
                                                size: 30,
                                                color: globalState.theme.buttonIcon,
                                              )))));
                            } else {

                              if (index >= _currentItems.length) {
                                return SizedBox(
                                    width: gridItemSize,//100,
                                    height: gridItemSize, //100,
                                    child: ClipRRect(
                                        child: Container(
                                            decoration: BoxDecoration(
                                              color: globalState.theme.objectDisabled,
                                            ),
                                            child: Center(
                                                child: Icon(
                                                  Icons.add_box_outlined,
                                                  size: 30,
                                                  color: globalState.theme.buttonIcon,
                                                )))));
                              } else {
                                AlbumItem item = _currentItems[index];

                                try {
                                  return SizedBox(
                                      width: gridItemSize, //100,
                                      height: gridItemSize, //100,
                                      child: ClipRRect(
                                        // borderRadius: index == 0
                                        //     ? const BorderRadius.only(
                                        //     topLeft: Radius.circular(10.0))
                                        //     : index == 1
                                        //     ? const BorderRadius.only(
                                        //     topRight: Radius.circular(10.0))
                                        //     : const BorderRadius.only(
                                        //     bottomLeft: Radius.circular(10.0)),
                                          child: item.type ==
                                              AlbumItemType.IMAGE
                                              ? (ImageCacheService.isAlbumThumbnailCached(
                                              widget.circleObject,
                                              item,
                                              widget.userCircleCache
                                                  .circlePath!,
                                              ))
                                              ? Image.file(
                                            File(ImageCacheService
                                                .returnExistingAlbumImagePath(
                                                widget.userCircleCache
                                                    .circlePath!,
                                                widget.circleObject,
                                                item.image!
                                                    .thumbnail!)),
                                            fit: BoxFit.cover,
                                          )
                                              : spinkit
                                              : (VideoCacheService.isAlbumPreviewCached(
                                              widget.circleObject,
                                              widget.userCircleCache
                                                  .circlePath!,
                                              item))
                                              ? Image.file(
                                            File(VideoCacheService
                                                .returnExistingAlbumVideoPath(
                                                widget.userCircleCache
                                                    .circlePath!,
                                                widget.circleObject,
                                                item.video!
                                                    .preview!)),
                                            fit: BoxFit.cover,
                                          )
                                              : spinkit));
                                } catch (err, trace) {
                                  LogBloc.insertError(err, trace);
                                  return Expanded(child: spinner);
                                }
                              }
                            }
                          })
                          : Container()
                  ),
                  widget.isSelected
                      ? Container(
                    color: const Color.fromRGBO(124, 252, 0, 0.5),
                    alignment: Alignment.center,
                    width: widget.width,
                    height: widget.height,
                  )
                      : Container(),
                  widget.isSelected
                      ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.check_circle,
                        color: globalState.theme.buttonIcon,
                      ))
                      : widget.anythingSelected
                      ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.circle_outlined,
                        color: globalState.theme.buttonDisabled,
                      ))
                      : Container(),
                  widget.circleObject.circle!.id == DeviceOnlyCircle.circleID
                      ? Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.save,
                            color: globalState.theme.buttonIconHighlight,
                          )))
                      : Container(),
                  widget.isSelecting
                      ? Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          widget.fullScreen(widget.circleObject);
                        },
                      ))
                      : Container(),
                  widget.circleObject.id == null
                      ? Align(
                      alignment: Alignment.topRight,
                      child: CircleAvatar(
                        radius: 7.0,
                        backgroundColor: globalState.theme.sentIndicator,
                      ))
                      : Container()
                ]))));
  }
}