import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circlefilewidget.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_draft.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_timer.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/date.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/pinnedobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/shared_functions.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircleFileUserWidget extends StatefulWidget {
  final CircleObject circleObject;
  final bool showAvatar;
  final bool showDate;
  final bool interactive;
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final bool showTime;
  final Function download;
  final Function retry;
  final Circle? circle;
  final Function unpinObject;
  final Function refresh;
  final double maxWidth;

  const CircleFileUserWidget(
    this.userCircleCache,
    this.interactive,
    this.userFurnace,
    this.circleObject,
    this.showAvatar,
    this.showDate,
    this.showTime,
    this.download,
    this.retry,
    this.circle,
    this.unpinObject,
    this.refresh,
    this.maxWidth,
  );

  @override
  CircleFileUserWidgetState createState() => CircleFileUserWidgetState();
}

class CircleFileUserWidgetState extends State<CircleFileUserWidget> {
  final spinkitNoPadding = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final fileWidget = CircleFileWidget(
        showBottomPadding:
            widget.circleObject.fullTransferState == BlobState.NOT_DOWNLOADED
                ? false
                : true,
        name: widget.circleObject.file!.name == null
            ? ''
            : widget.circleObject.file!.name!,
        fileSize: widget.circleObject.file!.fileSize!,
        extension: widget.circleObject.file!.extension == null
            ? 'FILE'
            : widget.circleObject.file!.extension!,
        maxWidth: widget.maxWidth,
        backgroundColor: globalState.theme.userObjectBackground,
        textColor: globalState.theme.userObjectText,
        preview: false);

    final fileWidgetShowDownload = CircleFileWidget(
        showBottomPadding:
            widget.circleObject.fullTransferState == BlobState.NOT_DOWNLOADED
                ? false
                : true,
        name: widget.circleObject.file!.name == null
            ? ''
            : widget.circleObject.file!.name!,
        fileSize: widget.circleObject.file!.fileSize!,
        extension: widget.circleObject.file!.extension == null
            ? 'FILE'
            : widget.circleObject.file!.extension!,
        maxWidth: widget.maxWidth,
        backgroundColor: globalState.theme.userObjectBackground,
        textColor: globalState.theme.userObjectText,
        showDownload: true,
        preview: false);

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
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                    ),
                                    widget.showTime ||
                                            widget.circleObject.showOptionIcons
                                        ? Text(
                                            widget.circleObject.showOptionIcons
                                                ? ('${widget.circleObject.date!}  ${widget.circleObject.time!}')
                                                : widget.circleObject.time!,
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
                                      constraints: BoxConstraints(
                                          maxWidth: widget.maxWidth),
                                      //maxWidth: 250,
                                      //height: 20,
                                      child: Container(
                                        padding: const EdgeInsets.all(0.0),
                                        //color: globalState.theme.dropdownBackground,

                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    widget.circleObject.body !=
                                                            null
                                                        ? (widget
                                                                .circleObject
                                                                .body!
                                                                .isNotEmpty
                                                            ? ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                        maxWidth:
                                                                            widget.maxWidth),
                                                                //maxWidth: 250,
                                                                //height: 20,
                                                                child: Container(
                                                                    padding: const EdgeInsets.all(InsideConstants.MESSAGEPADDING),
                                                                    //color: globalState.theme.dropdownBackground,
                                                                    decoration: BoxDecoration(
                                                                        color: globalState.theme.userObjectBackground,
                                                                        borderRadius: const BorderRadius.only(
                                                                            //bottomLeft: Radius.circular(10.0),
                                                                            //bottomRight: Radius.circular(10.0),
                                                                            topLeft: Radius.circular(10.0),
                                                                            topRight: Radius.circular(10.0))),
                                                                    child: CircleObjectBody(
                                                                      circleObject:
                                                                          widget
                                                                              .circleObject,
                                                                      userCircleCache: widget
                                                                          .userCircleCache,
                                                                      messageColor: globalState
                                                                          .theme
                                                                          .userObjectText,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .end,
                                                                      maxWidth:
                                                                          widget
                                                                              .maxWidth,
                                                                    )),
                                                              )
                                                            : Container())
                                                        : Container(),
                                                  ]),
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    widget.circleObject.seed !=
                                                            null
                                                        ? ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth: widget
                                                                        .maxWidth),
                                                            child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                        color: globalState
                                                                            .theme
                                                                            .background,
                                                                        borderRadius:
                                                                            const BorderRadius
                                                                                .only(
                                                                          bottomLeft:
                                                                              Radius.circular(10.0),
                                                                          bottomRight:
                                                                              Radius.circular(10.0),
                                                                          //topLeft: Radius.circular(10.0),
                                                                          //topRight: Radius.circular(10.0)),
                                                                        )),
                                                                child: widget.circleObject.fullTransferState ==
                                                                            BlobState
                                                                                .ENCRYPTING ||
                                                                        widget.circleObject.fullTransferState ==
                                                                            BlobState
                                                                                .DECRYPTING
                                                                    ? Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .end,
                                                                        children: [
                                                                            Stack(alignment: Alignment.center, children: [
                                                                              fileWidget,
                                                                              spinkitNoPadding
                                                                            ])
                                                                          ])
                                                                    : widget.circleObject.fullTransferState ==
                                                                            BlobState
                                                                                .DOWNLOADING
                                                                        ? Stack(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            children: [
                                                                                fileWidget,
                                                                                CircularPercentIndicator(
                                                                                  radius: 30.0,
                                                                                  lineWidth: 5.0,
                                                                                  percent: (widget.circleObject.transferPercent == null ? 0.01 : widget.circleObject.transferPercent! / 100),
                                                                                  center: Text(widget.circleObject.transferPercent == null ? '0%' : '${widget.circleObject.transferPercent}%', textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                                  progressColor: globalState.theme.progress,
                                                                                )
                                                                              ])
                                                                        : widget.circleObject.fullTransferState == BlobState.NOT_DOWNLOADED
                                                                            ? fileWidgetShowDownload
                                                                            : widget.circleObject.fullTransferState == BlobState.UPLOADING
                                                                                ? Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Stack(alignment: Alignment.center, children: [
                                                                                        fileWidget,
                                                                                        Padding(
                                                                                            padding: const EdgeInsets.only(right: 0),
                                                                                            child: CircularPercentIndicator(
                                                                                              radius: 30.0,
                                                                                              lineWidth: 5.0,
                                                                                              percent: (widget.circleObject.transferPercent == null ? 0 : widget.circleObject.transferPercent! / 100),
                                                                                              center: Text(widget.circleObject.transferPercent == null ? '...' : '${widget.circleObject.transferPercent}%', textScaler: const TextScaler.linear(1.0), style: TextStyle(color: globalState.theme.progress)),
                                                                                              progressColor: globalState.theme.progress,
                                                                                            ))
                                                                                      ])
                                                                                    ],
                                                                                  )
                                                                                : fileWidget))
                                                        : Container(),
                                                  ]),
                                              widget.circleObject.file != null
                                                  ? widget.circleObject
                                                              .retries >=
                                                          5
                                                      ? TextButton(
                                                          onPressed: () {
                                                            widget.retry(widget
                                                                .circleObject);
                                                          },
                                                          child: const Text(
                                                            'send failed, retry?',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ))
                                                      : Container()
                                                  : Container(),
                                              CircleObjectDraft(
                                                circleObject:
                                                    widget.circleObject,
                                                showTopPadding: true,
                                              ),
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
                                    : Container()
                              ]),
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
}
