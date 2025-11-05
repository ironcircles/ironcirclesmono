import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class Link extends StatelessWidget {
  final CircleObject circleObject;
  final double? width;

  const Link({
    Key? key,
    this.width,
    required this.circleObject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (circleObject.link == null)
      return Container();
    else
      return Column(children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              circleObject.link == null
                  ? Text(
                      'could not load link',
                      textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(
                          top: 0, bottom: 0, left: 0, right: 0),
                      child: Column(children: <Widget>[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth - 40,
                            //maxHeight: 160,
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                circleObject.link!.image == null
                                    ? Container()
                                    : _networkImage(circleObject.link!.image,
                                        screenWidth - 40),
                                circleObject.link == null
                                    ? Container()
                                    : circleObject.link!.title!.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 3, top: 10),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text(
                                                circleObject.link!.title!,
                                                textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                                maxLines: 4,
                                                textAlign: TextAlign.left,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: globalState
                                                        .theme.linkTitle),
                                              ))
                                            ]))
                                        : Container(),
                                circleObject.link!.description!.isNotEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: Row(children: [
                                          Expanded(
                                              child: Text(
                                            circleObject.link!.description!,
                                            textScaler: TextScaler.linear(globalState.messageScaleFactor),
                                            maxLines: 4,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: globalState
                                                    .theme.linkDescription),
                                          ))
                                        ]))
                                    : Container(),
                                Text(
                                  circleObject.link!.url!,
                                  //maxLines: _urlHeight,
                                  textAlign: TextAlign.left,
                                  textScaler: TextScaler.linear(globalState.messageHeaderScaleFactor),
                                  //overflow:
                                  // TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: circleObject.link!.title == ""
                                          ? 14
                                          : 11,
                                      color: globalState.theme.url),
                                ),
                              ]), //<widget>  )//wr
                        )
                      ]),
                    )
            ])
      ]);
  }

  _networkImage(image, width) {
    return SizedBox(
        width: width,
        child: Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: width - 10),
                child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 10),
                    child: CachedNetworkImage(
                      imageUrl: image, fit: BoxFit.scaleDown,
                      //placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Container(),
                    )))));
  }
}
