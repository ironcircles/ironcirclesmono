import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class LibraryBottomIcons extends StatelessWidget {
  final CircleObject? circleObject;
  final Function? share;
  final Function? openExternalBrowser;
  final Function? cancel;
  final Function? deleteCache;

  final double _iconSize = 31;
  final double _iconPadding = 12;

  const LibraryBottomIcons(
      {required this.circleObject,
      required this.share,
       this.openExternalBrowser,
      required this.cancel,
      required this.deleteCache});

  Widget build(BuildContext context) {
    return circleObject!.showOptionIcons
        ? Positioned(
            bottom: 13,
            left: 40,
            child: SizedBox(
                height: 100,
                // padding: EdgeInsets.all(5.0),
                //alignment: Alignment.bottomRight,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    //mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      deleteCache != null
                          ? InkWell(
                              onTap: () {
                                deleteCache!(circleObject);
                              },
                              child: Icon(Icons.cancel,
                                  size: _iconSize,
                                  color: globalState.theme.bottomIcon))
                          : Container(),
                      cancel != null
                          ? InkWell(
                              onTap: () {
                                cancel!(circleObject);
                              },
                              child: Icon(Icons.stop_circle_outlined,
                                  size: _iconSize,
                                  color: globalState.theme.bottomIcon))
                          : Container(),
                      share != null
                          ? InkWell(
                              onTap: () {
                                share!(circleObject);
                              },
                              child: Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: Icon(Icons.share,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      openExternalBrowser != null
                          ? InkWell(
                              onTap: () {
                                openExternalBrowser!(context, circleObject);
                              },
                              child: Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: Icon(Icons.open_in_browser,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                    ])))
        : Container();
  }
}
