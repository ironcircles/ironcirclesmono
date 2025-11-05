import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class Walkthrough {
  late TutorialCoachMark tutorialCoachMark;

  init(Function createTargets, {Function? finish}) {
    tutorialCoachMark = TutorialCoachMark(
      pulseEnable: false,
      targets: createTargets(),
      colorShadow: globalState.theme.tutorialBackground,
      textSkip: "EXIT",
      textStyleSkip: TextStyle(fontSize: (16 / globalState.labelScaleFactor), color: Colors.white),
      paddingFocus: 10,
      opacityShadow: 0.9,
      onSkip: () {
        if (finish != null) finish();
        return true;
      },
      onFinish: () {
        if (finish != null) finish();
      },
      onClickTarget: (target) {
        //print('onClickTarget: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        //print("target: $target");
       // print(
        //    "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        //print('onClickOverlay: $target');
      },
    );
  }

  Widget tutorialTitle(String text, int index, int total,
      {Color color = Colors.white,
      bool suppressFirst = false,
      double fontSize = 25,
      double indexOfSize = 13,
      double bottomPadding = 30}) {
    return InkWell(
      child: Column(
        children: [
          ICText(
            text,
            color: color,
            fontSize: fontSize,
            textAlign: TextAlign.center,
          ),
          (index == 1 && suppressFirst)
              ? Container()
              : ICText(
                  '($index  of $total)',
                  color: color,
                  fontSize: indexOfSize,
                  textAlign: TextAlign.center,
                ),
          Padding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
      onTap: _advance,
    );
  }

  Widget tutorialLineItem(String text,
      {Color color = Colors.white,
      double fontSize = 18,
      double bottomPadding = 30}) {
    return Column(
      children: [
        InkWell(
          child: ICText(
            text,
            color: color,
            fontSize: fontSize,
            textAlign: TextAlign.center,
          ),
          onTap: _advance,
        ),
        Padding(padding: EdgeInsets.only(bottom: bottomPadding)),
      ],
    );
  }

  Widget tapToExit() {
    return tutorialLineItem("tap anywhere to finish",
        color: Colors.grey.shade400, bottomPadding: 50);
  }

  Widget tapToContinue() {
    return tutorialLineItem("tap anywhere to continue",
        color: Colors.grey.shade400, bottomPadding: 50);
  }

  _advance() {
    tutorialCoachMark.next();
  }
}
