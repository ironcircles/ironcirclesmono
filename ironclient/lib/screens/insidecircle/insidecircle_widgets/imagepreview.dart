import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  //final Function shuffle;
  //final Function cancel;
  //final Function send;
  final Function crop;
  final Function markup;
  final Function swap;
  final Function cancel;
  final bool editing;
  final bool isPhoto;

  ImagePreview(
      {required this.image,
      required this.crop,
      required this.markup,
      required this.swap,
      required this.cancel,
      required this.editing,
      this.isPhoto = false});

  final spinkit = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

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
        Stack(alignment: Alignment.bottomRight, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 25, right: 5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170, maxWidth: 250),
                child: image == null
                    ? spinkit
                    : Image.file(image!, fit: BoxFit.cover),
              )),

          /* Padding(
          padding: EdgeInsets.only(right: 5, left: 5),
        ),*/
          Row(children: [
            editing
                ? IconButton(
                    icon: Icon(isPhoto ? Icons.camera_alt : Icons.image,
                        color: globalState.theme.buttonIcon),
                    onPressed: () {
                      swap();
                    },
                  )
                : Container(),
            IconButton(
              icon: Icon(Icons.brush, color: globalState.theme.buttonIcon),
              onPressed: () {
                markup(image, isPhoto);
              },
            ),
            IconButton(
              icon: Icon(Icons.crop, color: globalState.theme.buttonIcon),
              onPressed: () {
                crop(image, isPhoto);
              },
            ),

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
          ])
        ]),
        /*
          Column(children: <Widget>[
            ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 85, maxHeight: 30),
                child: GradientButton(
                  text: "Send->",
                  color2: Colors.grey[800],
                  color1: Colors.grey[800],
                  textColor: Colors.white,
                  onPressed: send,
                )),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 85, maxHeight: 30),
                child: GradientButton(
                  text: "Shuffle",
                  color2: Colors.grey[800],
                  color1: Colors.grey[800],
                  textColor: Colors.white,
                  onPressed: shuffle,
                )),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 85, maxHeight: 30),
                child: GradientButton(
                  text: "Cancel",
                  color2: Colors.grey[800],
                  color1: Colors.grey[800],
                  textColor: Colors.white,
                  onPressed: cancel,
                )),
          ]),*/
      ]),
    );
  }
}
