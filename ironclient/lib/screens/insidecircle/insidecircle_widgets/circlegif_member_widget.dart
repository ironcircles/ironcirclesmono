import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_member.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleGifMemberWidget extends StatelessWidget {
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

  CircleGifMemberWidget(
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
      this.maxWidth);

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

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
                DateWidget(showDate: showDate, circleObject: circleObject),
                PinnedObject(
                  circleObject: circleObject,
                  unpinObject: unpinObject,
                  isUser: false,
                ),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarWidget(
                          refresh: refresh,
                          userFurnace: userFurnace,
                          user: circleObject.creator,
                          showAvatar: showAvatar,
                          isUser: false),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              CircleObjectMember(
                                creator: circleObject.creator!,
                                circleObject: circleObject,
                                userFurnace: userFurnace,
                                messageColor: messageColor,
                                interactive: true,
                                showTime: showTime,
                                refresh: refresh,
                                maxWidth: maxWidth,
                              ),
                              ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: maxWidth),
                                  //maxWidth: 250,
                                  //height: 20,
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: globalState
                                              .theme.memberObjectBackground),
                                      child: Column(children: <Widget>[
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              CircleObjectBodyWrapped(
                                                circleObject: circleObject,
                                                replyObject: replyObject,
                                                replyObjectTapHandler: replyObjectTapHandler,
                                                userCircleCache: userCircleCache,
                                                messageColor: messageColor,
                                                replyMessageColor:
                                                    replyMessageColor,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                maxWidth: maxWidth,
                                              ),
                                            ]),
                                        Row(children: <Widget>[
                                          SizedBox(
                                              width: width, //width
                                              height: height,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.contain,
                                                  imageUrl:
                                                      circleObject.gif!.giphy!,
                                                  placeholder: (context, url) =>
                                                      spinkit,
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      const Icon(Icons
                                                          .error), /*Image.network(
                            circleObject.gif!.giphy!,
                          ),*/
                                                ),
                                              ))
                                        ]),
                                      ])))
                            ],
                          ),
                        ),
                      ),
                    ]),
              ])),
          CircleObjectTimer(circleObject: circleObject, isMember: true),
        ]));
  }
}
