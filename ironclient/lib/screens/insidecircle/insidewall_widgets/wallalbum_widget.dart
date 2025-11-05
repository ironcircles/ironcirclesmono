import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/album_item.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/videocache_service.dart';

class WallAlbumWidget extends StatelessWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Color messageColor;
  final Color? replyMessageColor;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  WallAlbumWidget(
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.userCircleCache,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.messageColor,
      this.replyMessageColor,
      this.circle,
      this.unpinObject,
      this.refresh,
      this.maxWidth
      );

  Widget build(BuildContext context) {
    List<AlbumItem> _currentItems = [];

    double gridSize = globalState.isDesktop() ? maxWidth : 200;
    double gridItemSize = gridSize / 2;

    if (circleObject.album!.media.isNotEmpty) {
      _currentItems = circleObject.album!.media.where((element) => element.removeFromCache == false).toList();
      _currentItems.sort((a, b) => a.index.compareTo(b.index));
    }

    final spinkit = SpinKitThreeBounce(
      size: 20,
      color: globalState.theme.threeBounce,
    );

    final spinner = SpinKitThreeBounce(
      size: 20,
      color: globalState.theme.threeBounce,
    );


    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
      child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: SharedFunctions.calculateTopPadding(circleObject, showDate),
          bottom: SharedFunctions.calculateBottomPadding(
            circleObject
          )),
          child: Column(children: <Widget>[
            DateWidget(showDate: showDate, circleObject: circleObject),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 0.0),
                ),
                AvatarWidget(
                  refresh: refresh,
                  userFurnace: userFurnace,
                  user: circleObject.creator,
                  showAvatar: true,
                  isUser: false
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        CircleObjectMember(
                          creator: circleObject.creator!,
                          circleObject: circleObject,
                          userFurnace: userFurnace,
                          messageColor: messageColor,
                          interactive: true,
                          isWall: true,
                          showTime: true,
                          refresh: refresh,
                          maxWidth: maxWidth,
                        )
                      ]))),
              ]),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  circleObject.body != null
                                  ? (circleObject.body!.isNotEmpty
                                    ? ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxWidth
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        InsideConstants.MESSAGEPADDING
                                      ),
                                      decoration: BoxDecoration(
                                        color: globalState.theme.memberObjectBackground,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(10.0),
                                          bottomRight: Radius.circular(10.0),
                                          topLeft: Radius.circular(10.0),
                                          topRight: Radius.circular(10.0))),
                                      child: CircleObjectBody(
                                        replyObject: replyObject,
                                        replyMessageColor: replyMessageColor,
                                        userCircleCache: userCircleCache,
                                        circleObject: circleObject,
                                        messageColor: globalState.theme.userObjectText,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        maxWidth: maxWidth,
                                      )
                                    )
                                  )
                                  : Container())
                                      : Container(),
                                ]),
                              Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: gridSize, //200
                                    height: gridSize, //200
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
                                                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10.0))),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.photo_library,
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
                                                borderRadius: index == 0
                                                    ? const BorderRadius.only(
                                                  topLeft: Radius.circular(10.0))
                                                    : index == 1
                                                    ? const BorderRadius.only(
                                                  topRight: Radius.circular(10.0))
                                                    : const BorderRadius.only(
                                                  bottomLeft: Radius.circular(10.0)),
                                                child: item.type ==
                                                    AlbumItemType.IMAGE
                                                    ? (ImageCacheService.isAlbumThumbnailCached(
                                                    circleObject,
                                                    item,
                                                    userCircleCache
                                                        .circlePath!,
                                                    ))
                                                    ? Image.file(
                                                  File(ImageCacheService
                                                      .returnExistingAlbumImagePath(
                                                      userCircleCache
                                                          .circlePath!,
                                                      circleObject,
                                                      item.image!
                                                          .thumbnail!)),
                                                  fit: BoxFit.cover,
                                                )
                                                    : spinkit
                                                    : (VideoCacheService.isAlbumPreviewCached(
                                                    circleObject,
                                                    userCircleCache
                                                        .circlePath!,
                                                    item))
                                                    ? Image.file(
                                                  File(VideoCacheService
                                                      .returnExistingAlbumVideoPath(
                                                      userCircleCache
                                                          .circlePath!,
                                                      circleObject,
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
                                      })
                                        : Container()
                                  )
                                ]
                              )
                            ]
                          )
                        )
                      ]
                    )
                  )
                )
              ]
            )
          ])),
        CircleObjectTimer(circleObject: circleObject, isMember: true),
      ]));

  }
}