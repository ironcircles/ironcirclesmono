import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';

enum VoiceOption { voiceMemo, voiceToText }

class DialogVoiceOptions {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static Future<VoiceOption?> show(BuildContext context) async {
    return await showDialog<VoiceOption>(
      context: context,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => Theme(
          data: ThemeData(
              dialogBackgroundColor:
                  globalState.theme.dialogTransparentBackground),
          child: _SystemPadding(
            child: AlertDialog(
              backgroundColor: globalState.theme.dialogTransparentBackground,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              contentPadding: const EdgeInsets.all(5.0),
              content: VoiceOptionsContent(scaffoldKey),
              surfaceTintColor: Colors.transparent,
            ),
          )),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300), child: child);
  }
}

class VoiceOptionsContent extends StatefulWidget {
  final GlobalKey scaffoldKey;

  const VoiceOptionsContent(
    this.scaffoldKey, {
    Key? key,
  }) : super(key: key);

  @override
  VoiceOptionsContentState createState() => VoiceOptionsContentState();
}

class VoiceOptionsContentState extends State<VoiceOptionsContent> {
  Widget _buttonRow(String text, VoiceOption option, Color? color1, Color? color2) {
    return Row(children: [
      Expanded(
          child: GradientButton(
              text: text,
              color1: color1,
              color2: color2,
              onPressed: () {
                Navigator.pop(context, option);
              }))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 136,
        child: Scaffold(
            backgroundColor: globalState.theme.dialogTransparentBackground,
            key: widget.scaffoldKey,
            resizeToAvoidBottomInset: false,
            body: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Padding(padding: EdgeInsets.only(top: 9)),
                  _buttonRow(
                    'Record Voice Memo',
                    VoiceOption.voiceMemo,
                    Colors.blue[500],
                    Colors.blue[300],
                  ),
                  _buttonRow(
                    'Voice to Text',
                    VoiceOption.voiceToText,
                    Colors.cyan[500],
                    Colors.cyan[300],
                  ),
                ])));
  }
}

