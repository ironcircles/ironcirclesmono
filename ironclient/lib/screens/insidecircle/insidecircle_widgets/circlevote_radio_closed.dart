import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class CircleVoteRadioClosed extends StatelessWidget {
  final CircleVote? circleVote;
  final CircleVoteOption circleVoteOption;
  final int index;
  final int? radioValue;

  const CircleVoteRadioClosed(
      this.circleVote, this.circleVoteOption, this.index, this.radioValue);

  Widget build(BuildContext context) {
    return Center(
        child: Stack(children: <Widget>[
      index == radioValue
          ? Padding(
              padding: const EdgeInsets.only(bottom: 0.0, right: 9),
              child: SizedBox(
                  height: 23,
                  width: 23,
                  child: Radio(
                      fillColor: MaterialStateProperty.resolveWith(globalState.getRadioColor),
                      activeColor: globalState.theme.listTitle,
                      value: index,
                      groupValue: radioValue,
                      onChanged: null
                      //_handleRadioValueChange,
                      )))
          : const Padding(padding: EdgeInsets.only(bottom: 25.0, right: 32)),
      CircleVote.isWinner(circleVoteOption, circleVote!)
          ? Padding(
              padding: const EdgeInsets.only(top: 0.0, right: 5),
              child: Icon(Icons.check, color: globalState.theme.buttonIcon))
          : const Padding(
              padding: EdgeInsets.only(right: 0),
            )
    ]));
  }
}
