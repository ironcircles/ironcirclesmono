import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/widgets/reactions/reactions.dart';

class DialogReactions {
  static final scaffoldKey = GlobalKey<ScaffoldState>();
  static final ScrollController _scrollController = ScrollController();
  static double iconFontSize = 18;
  static double countFontSize = 12;
  static double radius = 10;
  static double padding = 5;
  static double iconPaddingBetween = 5;

  static String getCountString(CircleObject circleObject, int index) {
    String retValue = '';

    for (CircleObjectReaction reaction in circleObject.reactions!) {
      if (reaction.index == index) {
        if (reaction.users.length > 1)
          retValue = reaction.users.length.toString();
        break;
      }
    }

    return retValue;
  }

  static String getReplyUsers(ReplyObject replyObject, int index) {
    String retValue = '';
    bool first = true;
    replyObject.reactions![index].users
        .sort((a, b) => a.username!.compareTo(b.username!));

    for (User user in replyObject.reactions![index].users) {
      if (!first) retValue = "$retValue, ";

      retValue = retValue + user.getUsernameAndAlias(globalState);

      first = false;
    }

    return retValue;
  }

  static String getUsers(CircleObject circleObject, int index) {
    String retValue = '';
    bool first = true;
    circleObject.reactions![index].users
        .sort((a, b) => a.username!.compareTo(b.username!));

    for (User user in circleObject.reactions![index].users) {
      if (!first) retValue = "$retValue, ";

      retValue = retValue + user.getUsernameAndAlias(globalState);

      first = false;
    }

    return retValue;
  }

  static showReplyReactions(
      BuildContext context,
      String title,
      ReplyObject replyObject,
      ) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              title,
              style: TextStyle(color: globalState.theme.bottomIcon),
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 20.0, top: 15),
          content: SizedBox(
              height: 175,
              width: 250,
              child: ListView.builder(
                  itemCount: replyObject.reactions!.length,
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  //shrinkWrap: true,
                  //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // crossAxisCount: 1,
                  //  ),
                  itemBuilder: (BuildContext context, int index) {
                    CircleObjectReaction reaction = replyObject.reactions![index];
                    return Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Container(
                              height: 29,
                              padding: EdgeInsets.only(
                                  left: padding, right: padding),
                              //color: globalState.theme.dropdownBackground,
                              decoration: BoxDecoration(
                                  color: globalState.theme.messageBackground,
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(radius),
                                      bottomRight: Radius.circular(radius),
                                      topLeft: Radius.circular(radius),
                                      topRight: Radius.circular(radius))),
                              child: Row(children: [
                                Text(
                                    reaction.index != null
                                        ? Reactions.getEmoji(replyObject.reactions![index].index!)
                                        : reaction.emoji!,
                                    style: TextStyle(fontSize: iconFontSize)),
                                /*Text(
                                  getCountString(circleObject, index),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: globalState.theme.buttonIcon),
                                )*/
                              ]))),
                      Expanded(
                          child: Text(
                            getReplyUsers(replyObject, index),
                            style: TextStyle(
                                color: globalState.theme.buttonIconHighlight),
                          )),
                    ]);
                  })),
          actions: <Widget>[
            TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: globalState.theme.buttonIcon,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  static showReactions(
    BuildContext context,
    String title,
    CircleObject circleObject,
  ) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Center(
            child: Text(
              title,
              style: TextStyle(color: globalState.theme.bottomIcon),
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 20.0, top: 15),
          content: SizedBox(
              height: 175,
              width: 250,
              child: ListView.builder(
                  itemCount: circleObject.reactions!.length,
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  //shrinkWrap: true,
                  //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // crossAxisCount: 1,
                  //  ),
                  itemBuilder: (BuildContext context, int index) {
                    CircleObjectReaction reaction = circleObject.reactions![index];
                    return Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Container(
                              height: 29,
                              padding: EdgeInsets.only(
                                  left: padding, right: padding),
                              //color: globalState.theme.dropdownBackground,
                              decoration: BoxDecoration(
                                  color: globalState.theme.messageBackground,
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(radius),
                                      bottomRight: Radius.circular(radius),
                                      topLeft: Radius.circular(radius),
                                      topRight: Radius.circular(radius))),
                              child: Row(children: [
                                Text(
                                  reaction.index != null
                                    ? Reactions.getEmoji(circleObject.reactions![index].index!)
                                    : reaction.emoji!,
                                    style: TextStyle(fontSize: iconFontSize)),
                                /*Text(
                                  getCountString(circleObject, index),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: globalState.theme.buttonIcon),
                                )*/
                              ]))),
                      Expanded(
                          child: Text(
                        getUsers(circleObject, index),
                        style: TextStyle(
                            color: globalState.theme.buttonIconHighlight),
                      )),
                    ]);
                  })),
          actions: <Widget>[
            TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: globalState.theme.buttonIcon,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}
