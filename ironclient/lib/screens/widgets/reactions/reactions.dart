import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/flutter_reaction_button.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/reaction.dart';

class Reactions extends StatelessWidget {
  static const double iconFontSize = 32;
  final Function reactionChanged;
  final CircleObject circleObject;
  static double radius = 10;
  static double padding = 5;
  // final bool showOptionIcons;

  const Reactions(
      {Key? key, required this.reactionChanged, required this.circleObject
      //required this.showOptionIcons,
      })
      : super(key: key);

  int getIndex(String emoji) {
    if (emoji == '👍') return 1;
    if (emoji == '🥰') return 2;
    if (emoji == '🤣') return 3;
    if (emoji == '😯') return 4;
    if (emoji == '😥') return 5;
    if (emoji == '😡') return 6;
    if (emoji == '👎') return 7;
    return 0;
  }

  static String getEmoji(int index) {
    if (index == 1) return '👍';
    if (index == 2) return '🥰';
    if (index == 3) return '🤣';
    if (index == 4) return '😯';
    if (index == 5) return '😥';
    if (index == 6) return '😡';
    if (index == 7) return '👎';

    return '';
  }

  static bool emptyReactions(CircleObject circleObject) {
    bool retValue = true;

    if (circleObject.reactions!.isNotEmpty) {
      //for (CircleObjectReaction reaction in circleObject.reactions!) {
      //if (reaction.users.isNotEmpty) {
      retValue = false;
      //break;
      // }
      //}
    }

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Container(
            height: 29,
            padding: EdgeInsets.only(left: padding, right: padding),
            //color: globalState.theme.dropdownBackground,
            decoration: BoxDecoration(
                color: globalState.theme.userObjectBackground,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius))),
            child: Icon(
              Icons.add_reaction_outlined,
              color: globalState.theme.insertEmoji,
              size: 21,
            )));

    return FlutterReactionButton(
      onReactionChanged: (reaction, index) {
        String emoji = reaction.previewIcon.toString().characters.elementAt(6);

        int actualIndex = getIndex(emoji);

        if (actualIndex > 0) reactionChanged(circleObject, actualIndex);
      },
      initialReaction: Reaction(icon: icon),
      boxColor: globalState.theme.background.withOpacity(0.9),
      boxRadius: 10,
      //boxPosition: Position.BOTTOM,
      boxItemsSpacing: 5,
      boxDuration: const Duration(milliseconds: 500),
      boxAlignment: AlignmentDirectional.bottomCenter,
      boxPadding: const EdgeInsets.all(10),
      reactions: <Reaction>[
        Reaction(
            previewIcon: const Text('👍', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        Reaction(
            previewIcon: const Text('🥰', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        Reaction(
            previewIcon: const Text('🤣', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        Reaction(
            previewIcon: const Text('😯', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        /*Reaction(
            previewIcon: Text('🙄', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),*/
        Reaction(
            previewIcon: const Text('😥', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        Reaction(
            previewIcon: const Text('😡', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
        Reaction(
            previewIcon: const Text('👎', style: TextStyle(fontSize: iconFontSize)),
            icon: icon),
      ],
    );
  }
}
