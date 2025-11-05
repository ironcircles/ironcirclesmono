import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class IconOptionsUser2 extends StatelessWidget {
  final CircleObject? circleObject;
  final Function? copy;
  final Function? delete;
  final Function? edit;
  final Function? share;
  final Function? openExternalBrowser;
  final Function? cancel;
  final Function? deleteCache;

  final double _iconSize = 31;
  final double _iconPadding = 12;
  final Function reactionChanged;

  const IconOptionsUser2(
      {this.circleObject,
      this.copy,
      this.delete,
      this.edit,
      this.share,
      this.openExternalBrowser,
      this.cancel,
      this.deleteCache,
      required this.reactionChanged});

  Widget build(BuildContext context) {
    return circleObject!.showOptionIcons
        ? Positioned(
            bottom: 70,
            right: 40,
            child: SizedBox(
                height: 100,
                // padding: EdgeInsets.all(5.0),
                //alignment: Alignment.bottomRight,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      share != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    share!(circleObject);
                                  },
                                  child: Icon(Icons.share,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      copy != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    copy!(circleObject);
                                  },
                                  child: Icon(Icons.content_copy,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      openExternalBrowser != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    openExternalBrowser!(context, circleObject);
                                  },
                                  child: Icon(Icons.open_in_browser,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      edit != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    edit!(circleObject);
                                  },
                                  child: Icon(Icons.edit,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      deleteCache != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    deleteCache!(circleObject);
                                  },
                                  child: Icon(Icons.cancel,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      cancel != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    cancel!(circleObject);
                                  },
                                  child: Icon(Icons.stop_circle_outlined,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      delete != null
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    delete!(circleObject);
                                  },
                                  child: Icon(Icons.delete,
                                      size: _iconSize,
                                      color: globalState.theme.bottomIcon)))
                          : Container(),
                      /*circleObject!.id != null &&
                              circleObject!.reactions ==
                                  null // ||  circleObject!.reactions!.isEmpty)
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: Reactions(
                                circleObject: circleObject!,
                                reactionChanged: reactionChanged,
                              ))
                          : circleObject!.id != null &&
                                  Reactions.emptyReactions(circleObject!)
                              ? Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: Reactions(
                                    circleObject: circleObject!,
                                    reactionChanged: reactionChanged,
                                  ))
                              : Container()

                       */
                    ])))
        : Container();
  }
}
