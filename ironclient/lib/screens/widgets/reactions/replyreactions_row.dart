import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';

class ReplyReactionsRow extends StatelessWidget {
  final Function shortPress;
  final Function longPress;
  final Function reactionChanged;
  final Function showReactions;
  final bool isUser;
  final String userID;
  final ReplyObject replyObject;

  static double iconFontSize = 25;
  static double countFontSize = 12;
  static double radius = 10;
  static double padding = 2;
  static double iconPaddingBetween = 5;

  ReplyReactionsRow({
    Key? key,
    required this.replyObject,
    required this.shortPress,
    required this.longPress,
    required this.reactionChanged,
    required this.isUser,
    required this.userID,
    required this.showReactions,
    //required this.showOptionIcons,
  }) : super(key: key);

  final ScrollController _scrollController = ScrollController();

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

  static bool emptyReactions(ReplyObject replyObject) {
    bool retValue = true;

    if (replyObject.reactions!.isNotEmpty) {
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
    if (replyObject.reactions == null) return Container();
    int crossAxisCount = (MediaQuery.of(context).size.width - 45) ~/ 45;

    // if (isUser)
    //   circleObject.reactions!.sort((a, b) => b.index!.compareTo(a.index!));
    // else
    //   circleObject.reactions!.sort((a, b) => a.index!.compareTo(b.index!));

    bool noReactions = emptyReactions(replyObject);

    return !noReactions
        ? Padding(
        padding: EdgeInsets.only(
            bottom: 10,
            top: 0,
            left: 55,
            right: 0,
            //left: isUser ? 0 : 55,
            //right: isUser ? 45 : 0
        ),
        child: SizedBox(
            width: MediaQuery.of(context).size.width - 45,
            child:

            ///if items surpass width allotment of items, display grid
            ///otherwise, display row

            replyObject.reactions!.length > crossAxisCount - 1
                ? GridView.builder(
                itemCount:
                replyObject.reactions!.length + 1,
                padding: const EdgeInsets.only(right: 0, left: 0),
                controller: _scrollController,
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                ),
                itemBuilder: (BuildContext context, int index) {
                  if (index == replyObject.reactions!.length) {
                    return Row(children: [ icon() ]);
                  }
                  if (index == replyObject.reactions!.length || replyObject.reactions![index].users.isEmpty) {
                    return Container();
                  } else {
                    CircleObjectReaction reaction =
                    replyObject.reactions![index];
                    if (!isUser &&
                        replyObject.reactions!.length < crossAxisCount &&
                        index == replyObject.reactions!.length - 1) {
                      return Row(
                        children: [
                          determineEmoji(reaction),
                        ],
                      );
                    } else if (isUser &&
                        index == 0 &&
                        replyObject.reactions!.length < crossAxisCount) {
                      return Row(children: [
                        determineEmoji(reaction),
                      ]);
                    } return Row(
                        children: [
                          determineEmoji(reaction)
                        ]
                    );
                  }
                }
            )
                : SizedBox(
                height: 38,
                child: ListView.builder(
                  reverse: false,
                    //reverse: isUser ? true : false,
                    itemCount:
                    replyObject.reactions!.length,
                    padding: const EdgeInsets.only(right: 0, left: 0),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == replyObject.reactions!.length || replyObject.reactions![index].users.isEmpty) {
                        return Container();
                      }

                      CircleObjectReaction reaction = replyObject.reactions![index];
                      if (!isUser &&
                          replyObject.reactions!.length < crossAxisCount
                          &&
                          index == replyObject.reactions!.length - 1) {
                        return Row(
                          children: [
                            determineEmoji(reaction),
                            icon(),
                          ],
                        );
                      } else if (isUser &&
                          index == 0 &&
                          replyObject.reactions!.length < crossAxisCount ) {
                        return Row(children: [
                          determineEmoji(reaction),
                          icon(),
                        ]);
                      } else
                        return Row(
                            children: [
                              determineEmoji(reaction)
                            ]
                        );
                    }
                )
            )
        ))
        : Container();
  }

  Widget determineEmoji(CircleObjectReaction reaction) {
    if (reaction.index != null && reaction.emoji == null) {
      return emoji(reaction.index);
    } else {
      return emojiKeyboard(reaction.emoji);
    }
  }

  Widget icon() {
    return InkWell(
        onTap: () {
          showReactions(replyObject);
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 5, top: 3),
            child: Container(
                height: 35,
                padding: EdgeInsets.only(left: padding, right: padding),
                //color: globalState.theme.dropdownBackground,
                decoration: BoxDecoration(
                    color: globalState.theme.messageBackground,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius))),
                child: Icon(
                  Icons.add_reaction_outlined,
                  color: globalState.theme.insertEmoji,
                  size: 30,
                ))));
  }

  Widget emoji(index) {
    return GestureDetector(
        onLongPress: () {
          longPress(replyObject, index);
        },
        onTap: () {
          shortPress(replyObject, index, "");
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 5, top: 3),
            child: Container(
                height: 35,
                padding: EdgeInsets.only(left: padding, right: padding),
                //color: globalState.theme.dropdownBackground,
                decoration: BoxDecoration(
                    color: globalState.theme.messageBackground,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius))),
                child: Row(children: [
                  Text(getEmoji(index), textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(fontSize: iconFontSize)),
                  Text(getCountString(index), textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: 12, color: globalState.theme.menuIcons))
                ]))));
  }

  Widget emojiKeyboard(string) {
    return GestureDetector(
        onLongPress: () {
          longPress(replyObject, -1);
        },
        onTap: () {
          shortPress(replyObject, -1, string);
        },
        child: Padding(
            padding: const EdgeInsets.only(right: 5, top: 3),
            child: Container(
                height: 35,
                padding: EdgeInsets.only(left: padding, right: padding),
                decoration: BoxDecoration(
                    color: globalState.theme.messageBackground,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius))),
                child: Row(children: [
                  Text(string,
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: iconFontSize,
                          letterSpacing: 0.0,
                          wordSpacing: 0.0)),
                  Text(getCountStringEmoji(string),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: 12, color: globalState.theme.menuIcons))
                ]))));
  }

  int getUserCount() {
    int userReactions = 0;

    for (CircleObjectReaction reaction in replyObject.reactions!) {
      for (User user in reaction.users) {
        if (user.id == userID) userReactions += 1;
      }
    }

    return userReactions;
  }

  String getCountStringEmoji(String emoji) {
    String retValue = '';
    for (CircleObjectReaction reaction in replyObject.reactions!) {
      if (reaction.emoji != null && reaction.emoji! == emoji) {
        if (reaction.users.length > 1) {
          retValue = reaction.users.length.toString();
          break;
        }
      }
    }
    return retValue;
  }

  String getCountString(int index) {
    String retValue = '';

    for (CircleObjectReaction reaction in replyObject.reactions!) {
      if (reaction.index != null && reaction.index == index) {
        if (reaction.users.length > 1)
          retValue = reaction.users.length.toString();
        break;
      }
    }

    return retValue;
  }
}