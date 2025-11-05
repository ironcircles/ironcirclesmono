import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class CircleLinkWidget extends StatefulWidget {
  final CircleObject circleObject;
  final double maxWidth;

  //final Function openExternalBrowser;

  const CircleLinkWidget(
      {Key? key, required this.circleObject, required this.maxWidth})
      : super(key: key);

  @override
  CircleLinkUserWidgetState createState() => CircleLinkUserWidgetState();
}

class CircleLinkUserWidgetState extends State<CircleLinkWidget> {
  //int _urlHeight = 2;
  late CircleObject _circleObject; // = widget.circleObject;
  //LinkBloc _linkBloc = LinkBloc();

  @override
  void initState() {
    _circleObject = widget.circleObject;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            widget.circleObject.link == null
                ? Text(
                    'could not load link',
                    textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                  )
                : widget.circleObject.link!.image!.isEmpty
                    ? _networkImage(widget.circleObject.link!.url)
                    : _networkImage(widget.circleObject.link!.image)
          ]),
      Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth - 5,
                  //maxHeight: 160,
                ),
                child: _circleObject.link == null
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                            _circleObject.link == null
                                ? Container()
                                : _circleObject.link!.title!.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 3, left: 10, right: 5),
                                        child: Text(
                                          widget.circleObject.link!.title!,
                                          textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                          maxLines: 4,
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  globalState.theme.linkTitle),
                                        ))
                                    : Container(),
                            _circleObject.link!.description!.isNotEmpty
                                //&&
                                //  widget.replyObject == null
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 3, left: 10, right: 5),
                                    child: Text(
                                      widget.circleObject.link!.description!,
                                      textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                      maxLines: 4,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: globalState
                                              .theme.linkDescription),
                                    ))
                                : Container(),
                            Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 3, left: 10, right: 5),
                                child: Text(
                                  widget.circleObject.link!.url!,
                                  //maxLines: _urlHeight,
                                  textAlign: TextAlign.left,
                                  textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                  style: TextStyle(
                                      fontSize:
                                          widget.circleObject.link!.title == ""
                                              ? 14
                                              : 11,
                                      color: globalState.theme.url),
                                )),
                          ]), //<widget>  )//wr
              )
            ]),
          ])
    ]);
  }

  _networkImage(image) {
    return SizedBox(
        width: widget.maxWidth - 5,
        child: Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: widget.maxWidth - 10),
                child: Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                      bottom: 10,
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: image, fit: BoxFit.scaleDown,
                          //placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Container(),
                        ))))));
  }
}
