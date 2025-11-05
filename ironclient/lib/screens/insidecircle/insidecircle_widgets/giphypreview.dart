import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class GiphyPreview extends StatelessWidget {
  final String url;
  final Function shuffle;
  final Function cancel;
  final Function send;

  const GiphyPreview(
      {required this.url,
      required this.shuffle,
      required this.cancel,
      required this.send});

  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          /*ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 90),
              child: Image.asset('assets/giphy.gif')),
          Padding(
            padding: EdgeInsets.only(left: 20),
          ),*/
          Column(children: <Widget>[
            ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 170,
                    maxHeight: 160,
                    minWidth: 170,
                    minHeight: 120),
                child:
                    Image.network(url, fit: BoxFit.cover)),

            ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 15),
                child: Image.asset('assets/giphy3.png')),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 0, right: 5, left: 5),
          ),
          Column(children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100, maxHeight: 30),
              child: TextButton(
                onPressed: send as void Function()?,
                child: Text('Post',
                    style: TextStyle(
                        color: globalState.theme.buttonIcon, fontSize: 20)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100, maxHeight: 30),
              child: TextButton(
                onPressed: shuffle as void Function()?,
                child: Text('Shuffle',
                    style: TextStyle(
                        color: globalState.theme.buttonIcon, fontSize: 20)),
              ),
            ),
          ]),
        ]));
  }
}
