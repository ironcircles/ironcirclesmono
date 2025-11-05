import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';

class GiphyPreviewSingle extends StatelessWidget {
  final GiphyOption? giphyOption;
  final Function cancel;

  const GiphyPreviewSingle({
    required this.giphyOption, required this.cancel
  });

  @override
  Widget build(BuildContext context) {
    return giphyOption == null ? Container() : Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Stack(alignment: Alignment.bottomRight, children: <Widget>[
          /*ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 90),
              child: Image.asset('assets/giphy.gif')),
          Padding(
            padding: EdgeInsets.only(left: 20),
          ),*/
        Padding(
        padding: const EdgeInsets.only(bottom: 0, right: 5),
        child: Column(children: <Widget>[
            ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 170,
                    maxHeight: 160,
                    minWidth: 170,
                    minHeight: 120),
                child: giphyOption!.url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: giphyOption!.url, fit: BoxFit.fitHeight,
                        /*placeholder: (context, url) =>
                            CircularProgressIndicator(
                          color: globalState.theme.buttonIcon,
                        ),
                         */
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ) /*Image.network(url!, fit: BoxFit.cover)*/
                    : Container()),
           // ConstrainedBox(
            //    constraints: BoxConstraints(maxHeight: 15),
             //   child: Image.asset('assets/images/giphy3.png')),
          ])),
          /*IconButton(
            icon: Icon(Icons.cancel_rounded,
                color: globalState.theme.buttonDisabled),
            /*iconSize: 22,*/
            //constraints: BoxConstraints(maxHeight: 20),
            onPressed: () {
              cancel(true);
              // _openRegistration(context);
            },
          ),*/
        ]));
  }
}
