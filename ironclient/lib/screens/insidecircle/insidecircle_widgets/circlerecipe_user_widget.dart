import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircleRecipeUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final UserFurnace userFurnace;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final Function unpinObject;
  final UserCircleCache userCircleCache;
  final Function refresh;
  final double maxWidth;

  //final Function submitVote;
  //final User user;

  //int _radioValue = -1;
  //int groupValue;

  const CircleRecipeUserWidget(
      this.circleObject,
      this.userFurnace,
      this.showAvatar,
      this.showDate,
      this.showTime,
      this.userCircleCache,
      this.unpinObject,
      this.refresh,
      this.maxWidth);

  @override
  CircleRecipeUserWidgetState createState() => CircleRecipeUserWidgetState();
}

class CircleRecipeUserWidgetState extends State<CircleRecipeUserWidget> {
  //final bool showDate;
  //int _radioValue = -1;

  @override
  void initState() {
    super.initState();
  }

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

  CircleRecipe? _circleRecipe;
  bool refresh = false;

  @override
  Widget build(BuildContext context) {
    if (_circleRecipe == null) {
      setState(() {
        refresh = true;
      });
    } else {
      if (_circleRecipe!.lastUpdate != widget.circleObject.recipe!.lastUpdate) {
        setState(() {
          refresh = true;
        });
      }
    }
    if (refresh) {
      _refreshRecipe();
    }

    return Padding(
        padding: EdgeInsets.only(
            top: widget.showAvatar ? UIPadding.BETWEEN_MESSAGES : 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: SharedFunctions.calculateTopPadding(
                      widget.circleObject, widget.showDate),
                  bottom: SharedFunctions.calculateBottomPadding(
                    widget.circleObject,
                  )),
              child: Column(children: <Widget>[
                DateWidget(
                    showDate: widget.showDate,
                    circleObject: widget.circleObject),
                PinnedObject(
                  circleObject: widget.circleObject,
                  unpinObject: widget.unpinObject,
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
                              Container(
                                child: widget.showTime ||
                                        widget.circleObject.showOptionIcons
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 5.0),
                                            ),
                                            Text(
                                              widget.circleObject
                                                      .showOptionIcons
                                                  ? ('${widget.circleObject.lastUpdatedDate!}  ${widget.circleObject.lastUpdatedTime!}')
                                                  : widget.circleObject
                                                      .lastUpdatedTime!,
                                              textScaler: TextScaler.linear(
                                                  globalState
                                                      .messageHeaderScaleFactor),
                                              style: TextStyle(
                                                color: globalState.theme.time,
                                                fontWeight: FontWeight.w600,
                                                fontSize: globalState
                                                    .userSetting.fontSize,
                                              ),
                                            )
                                          ])
                                    : Container(),
                              ),
                              Stack(children: <Widget>[
                                Align(
                                    alignment: Alignment.topRight,
                                    child: widget.circleObject.draft
                                        ? Container()
                                        : ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: widget.maxWidth),
                                            //maxWidth: 250,
                                            //height: 20,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              //color: globalState.theme.dropdownBackground,
                                              decoration: BoxDecoration(
                                                  color: globalState.theme
                                                      .userObjectBackground,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10.0),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  10.0),
                                                          topLeft:
                                                              Radius.circular(
                                                                  10.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  10.0))),
                                              child: refresh == true
                                                  ? Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                          Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <Widget>[
                                                                Text(AppLocalizations.of(context)!.recipe,
                                                                    textScaler: TextScaler.linear(
                                                                        globalState
                                                                            .messageHeaderScaleFactor),
                                                                    style:
                                                                        TextStyle(
                                                                      color: globalState
                                                                          .theme
                                                                          .listTitle,
                                                                      fontSize:
                                                                          globalState
                                                                              .titleSize,
                                                                    ))
                                                              ]),
                                                          Center(
                                                              child:
                                                                  spinkitNoPadding)
                                                        ])
                                                  : Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                          Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <Widget>[
                                                                Text(
                                                                  AppLocalizations.of(context)!.recipe,
                                                                  textScaler: TextScaler.linear(
                                                                      globalState
                                                                          .messageHeaderScaleFactor),
                                                                  style:
                                                                      TextStyle(
                                                                    color: globalState
                                                                        .theme
                                                                        .listTitle,
                                                                    fontSize:
                                                                        globalState
                                                                            .titleSize,
                                                                  ),
                                                                ),
                                                              ]),
                                                          widget.circleObject
                                                                      .body ==
                                                                  null
                                                              ? Container()
                                                              : //Row(mainAxisAlignment: MainAxisAlignment.end ,children: <Widget>[
                                                              Text(
                                                                  widget
                                                                      .circleObject
                                                                      .body!,
                                                                  textScaler: TextScaler.linear(
                                                                      globalState
                                                                          .messageScaleFactor),
                                                                  style: TextStyle(
                                                                      color: globalState
                                                                          .theme
                                                                          .userObjectText,
                                                                      fontSize: globalState
                                                                          .userSetting
                                                                          .fontSize)),
                                                          widget.circleObject
                                                                      .recipe ==
                                                                  null
                                                              ? Container()
                                                              : widget
                                                                          .circleObject
                                                                          .recipe!
                                                                          .image !=
                                                                      null
                                                                  ? widget.circleObject.thumbnailTransferState ==
                                                                              BlobState
                                                                                  .ENCRYPTING ||
                                                                          widget.circleObject.thumbnailTransferState ==
                                                                              BlobState
                                                                                  .DECRYPTING
                                                                      ? Column(
                                                                          crossAxisAlignment: CrossAxisAlignment
                                                                              .center,
                                                                          children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.only(right: 25),
                                                                                child: ICText(widget.circleObject.thumbnailTransferState == BlobState.ENCRYPTING ? 'Encrypting' : 'Decrypting', color: globalState.theme.labelText),
                                                                              ),
                                                                              spinkit,
                                                                            ])
                                                                      : (ImageCacheService.isRecipeImageCached(
                                                                              widget.circleObject.recipe!.image!.thumbnailSize,
                                                                              widget.userCircleCache.circlePath!,
                                                                              widget.circleObject.seed!)
                                                                          ? Stack(alignment: Alignment.center, children: [
                                                                              Image.file(
                                                                                File(ImageCacheService.returnThumbnailPath(widget.userCircleCache.circlePath!, widget.circleObject)),
                                                                                fit: BoxFit.contain,
                                                                              ),
                                                                              widget.circleObject.thumbnailTransferState == BlobState.DOWNLOADING || widget.circleObject.thumbnailTransferState == BlobState.UPLOADING
                                                                                  ? Padding(
                                                                                      padding: const EdgeInsets.only(right: 0),
                                                                                      child: CircularPercentIndicator(
                                                                                        radius: 30.0,
                                                                                        lineWidth: 5.0,
                                                                                        percent: (widget.circleObject.transferPercent == null ? 0.01 : widget.circleObject.transferPercent! / 100),
                                                                                        center: Text(widget.circleObject.transferPercent == null ? '0%' : '${widget.circleObject.transferPercent}%', textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                                        progressColor: globalState.theme.progress,
                                                                                      ))
                                                                                  : Container(),
                                                                            ])
                                                                          : ConstrainedBox(
                                                                              constraints: BoxConstraints(maxWidth: widget.maxWidth),
                                                                              child: Padding(padding: const EdgeInsets.all(5.0), child: Center(child: spinkit)
                                                                                  //  File(FileSystemServicewidget
                                                                                  //.circleObject.gif.giphy),
                                                                                  // ),
                                                                                  ),
                                                                            ))
                                                                  : Container(),
                                                          widget.circleObject
                                                                      .recipe ==
                                                                  null
                                                              ? Container()
                                                              : widget
                                                                          .circleObject
                                                                          .recipe!
                                                                          .notes ==
                                                                      null
                                                                  ? Container()
                                                                  : widget
                                                                          .circleObject
                                                                          .recipe!
                                                                          .notes!
                                                                          .isEmpty
                                                                      ? Container()
                                                                      : Text(
                                                                          widget.circleObject.recipe!.notes!.length < 292
                                                                              ? widget
                                                                                  .circleObject.recipe!.notes!
                                                                              : '${widget.circleObject.recipe!.notes!.substring(0, 291)}...',
                                                                          textScaler: TextScaler.linear(globalState
                                                                              .messageScaleFactor),
                                                                          style: TextStyle(
                                                                              color: globalState.theme.listLoadMore,
                                                                              fontSize: 12)),
                                                        ]),
                                            ),
                                          )),
                                widget.circleObject.id == null
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: CircleAvatar(
                                          radius: 7.0,
                                          backgroundColor:
                                              globalState.theme.sentIndicator,
                                        ))
                                    : Container(),
                              ]),
                              CircleObjectDraft(
                                circleObject: widget.circleObject,
                                showTopPadding: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AvatarWidget(
                          refresh: widget.refresh,
                          userFurnace: widget.userFurnace,
                          user: widget.circleObject.creator,
                          showAvatar: widget.showAvatar,
                          isUser: true),
                    ]),
              ])),
          CircleObjectTimer(circleObject: widget.circleObject, isMember: false),
        ]));
  }

  _refreshRecipe() {
    _circleRecipe = CircleRecipe.deepCopy(widget.circleObject.recipe!);
    setState(() {
      refresh = false;
    });
  }
}
