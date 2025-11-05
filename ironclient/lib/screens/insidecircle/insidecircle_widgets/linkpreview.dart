import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class LinkPreview extends StatefulWidget {
  final CircleLink circleLink;
  //final Function cancel;
  final Function send;

  const LinkPreview({required this.circleLink, required this.send});

  @override
  LinkPreviewState createState() => LinkPreviewState();
}

class LinkPreviewState extends State<LinkPreview> {
  int _urlHeight = 1;
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    if (widget.circleLink.title!.isEmpty) _urlHeight += 2;

    if (widget.circleLink.description!.isEmpty) _urlHeight += 2;

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Row(children: <Widget>[
        widget.circleLink.previewFailed
            ? Column(children: <Widget>[
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      ClipOval(
                        child: Image.asset(
                          'assets/images/link.png',
                          fit: BoxFit.cover,
                          height: 120,
                          width: 120,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                      ),
                      ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 150,
                            maxHeight: 100,
                          ),
                          child: Text(
                            widget.circleLink.url!,
                            style: TextStyle(
                                fontSize: 12, color: globalState.theme.url),
                          )),
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 0,
                          left: 12,
                        ),
                      ),
                      Column(children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 20,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 100, maxHeight: 30),
                          child: TextButton(
                            onPressed: widget.send as void Function()?,
                            child: Text('Post',
                                style: TextStyle(
                                    color: globalState.theme.buttonIcon,
                                    fontSize: 20)),
                          ),
                        ),
                      ]),
                    ]),
                const Text('could not load link preview'),
              ])
            : Column(children: <Widget>[
                Row(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      widget.circleLink.image!.isNotEmpty
                          ? Image.network(
                              widget.circleLink.image!,
                              fit: BoxFit.fitWidth,
                              // height: 100,
                              width: 100,
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/link.png',
                                fit: BoxFit.cover,
                                height: 120,
                                width: 120,
                              ),
                            ),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                      ),
                      Column(children: <Widget>[
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 150,
                            maxHeight: 120,
                          ),
                          child: Wrap(
                              direction:
                                  Axis.horizontal, //Vertical || Horizontal
                              children: <Widget>[
                                Text(
                                  widget.circleLink.title!,
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: globalState.theme.linkTitle),
                                ),
                                Text(
                                  widget.circleLink.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: globalState.theme.linkDescription),
                                ),
                                Text(
                                  widget.circleLink.url!,
                                  maxLines: _urlHeight,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: globalState.theme.url),
                                ),
                              ]), //<widget>  )//wr
                        )
                      ]),
                      Column(children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 0,
                            left: 120,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 100, maxHeight: 30),
                          child: TextButton(
                            onPressed: widget.send as void Function()?,
                            child: Text('Post',
                                style: TextStyle(
                                    color: globalState.theme.buttonIcon,
                                    fontSize: 20)),
                          ),
                        ),
                      ]),
                    ])
              ]),
        const Padding(
          padding: EdgeInsets.only(top: 0, right: 5, left: 5),
        ),
      ]),
    );
  }
}
