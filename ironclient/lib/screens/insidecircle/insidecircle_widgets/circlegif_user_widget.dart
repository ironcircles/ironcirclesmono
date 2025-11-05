import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleGifUserWidget extends StatelessWidget {
  final CircleObject circleObject;
  final CircleObject? replyObject;
  final Function? replyObjectTapHandler;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Circle? circle;
  final Color? replyMessageColor;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  CircleGifUserWidget(
      this.circleObject,
      this.replyObject,
      this.replyObjectTapHandler,
      this.userCircleCache,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.circle,
      this.replyMessageColor,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    double width = 200;
    double height = 200;

    double thumbnailWidth = maxWidth;

    if (circleObject.gif != null) {
      if (circleObject.gif!.width != null) {
        if (circleObject.gif!.height! > circleObject.gif!.width!){
          thumbnailWidth = thumbnailWidth * 0.75;
        }
        if (circleObject.gif!.width! <= thumbnailWidth) {
          ///scale up
          double ratio = thumbnailWidth / circleObject.gif!.width!;

          width = thumbnailWidth;

          height = (circleObject.gif!.height! * ratio).toDouble();
        } else if (circleObject.gif!.width! >= thumbnailWidth) {
          ///scale down
          double ratio = circleObject.gif!.width! / thumbnailWidth;

          width = thumbnailWidth;

          height = (circleObject.gif!.height! / ratio).toDouble();
        }
      }
    }

    return Padding(
        padding:
            EdgeInsets.only(top: showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      circleObject, showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                    circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(
                    showDate: showDate,
                    circleObject: circleObject),
                PinnedObject(
                  circleObject: circleObject,
                  unpinObject: unpinObject,
                  isUser: true,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    /*new Text(
                        circleObject.creator.username,
                        style: TextStyle(
                          color: globalState.theme.userUsername,
                          fontWeight: FontWeight.w600,
                          fontSize: globalState.userSetting.fontSize,
                        ),
                      ),*/
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                    ),
                                    showTime || circleObject.showOptionIcons
                                        ? Text(
                                            circleObject.showOptionIcons
                                                ? ('${circleObject.date!}  ${circleObject.time!}')
                                                : circleObject.time!,
                                            textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                            style: TextStyle(
                                              color: globalState.theme.time,
                                              fontWeight: FontWeight.w600,
                                              fontSize: globalState
                                                  .userSetting.fontSize,
                                            ),
                                          )
                                        : Container(),
                                  ]),
                              Stack(children: <Widget>[
                                Align(
                                  alignment: Alignment.topRight,
                                  child: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: maxWidth),

                                      //maxWidth: 250,
                                      //height: 20,
                                      child: Column(children: <Widget>[
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: <Widget>[
                                              Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius
                                                                  .only(
                                                              bottomLeft:
                                                                  Radius
                                                                      .circular(
                                                                          10.0),
                                                              bottomRight: Radius
                                                                  .circular(
                                                                      10.0),
                                                              topLeft: Radius
                                                                  .circular(
                                                                      10.0),
                                                              topRight: Radius
                                                                  .circular(
                                                                      10.0)),
                                                      color: globalState.theme
                                                          .userObjectBackground),
                                                  child:
                                                      CircleObjectBodyWrapped(
                                                    circleObject: circleObject,
                                                    replyObject: replyObject,
                                                    replyObjectTapHandler: replyObjectTapHandler,
                                                    userCircleCache:
                                                        userCircleCache,
                                                    messageColor: globalState
                                                        .theme.userObjectText,
                                                    replyMessageColor:
                                                        replyMessageColor,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    maxWidth: maxWidth,
                                                  ))
                                            ]),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: <Widget>[
                                              circleObject.gif != null &&
                                                      circleObject.draft ==
                                                          false
                                                  ? SizedBox(
                                                      width: width, //width
                                                      height: height, //height
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(15),
                                                        child:
                                                            CachedNetworkImage(
                                                          fit: BoxFit.contain,
                                                          imageUrl: circleObject
                                                              .gif!.giphy!,
                                                          placeholder:
                                                              (context, url) =>
                                                                  spinkit,
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        ), /*Image.network(
                                              circleObject.gif!.giphy!,
                                            ),*/
                                                      ),
                                                    )
                                                  : Container(),
                                            ]),
                                      ])),
                                ),
                                circleObject.id == null
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: CircleAvatar(
                                          radius: 7.0,
                                          backgroundColor:
                                              globalState.theme.sentIndicator,
                                        ))
                                    : Container()
                              ]),
                              CircleObjectDraft(
                                circleObject: circleObject,
                                showTopPadding: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AvatarWidget(
                          refresh: refresh,
                          userFurnace: userFurnace,
                          user: circleObject.creator,
                          showAvatar: showAvatar,
                          isUser: true),
                    ]),
              ])),
          CircleObjectTimer(circleObject: circleObject, isMember: false),
        ]));
  }
}
