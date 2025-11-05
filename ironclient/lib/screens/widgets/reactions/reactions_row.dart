import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidewall_widgets/wallreplies_widget.dart';

class ReactionsRow extends StatelessWidget {
  final Function shortPress;
  final Function longPress;
  final Function reactionChanged;
  final Function showReactions;
  final bool isUser;
  final String userID;
  final CircleObject circleObject;
  final bool wall;

  final List<ReplyObject> replyObjects;
  UserFurnace userFurnace;
  ReplyObjectBloc? replyObjectBloc;
  Color? messageColor;
  Function? refresh;
  final double maxWidth;
  final UserCircleCache userCircleCache;
  final GlobalEventBloc globalEventBloc;
  MemberBloc? memberBloc;

  static double iconFontSize = 25;
  static double countFontSize = 12;
  static double radius = 10;
  static double padding = 2;
  static double iconPaddingBetween = 5;

  ReactionsRow({
    Key? key,
    required this.circleObject,
    required this.shortPress,
    required this.longPress,
    required this.reactionChanged,
    required this.isUser,
    required this.userID,
    required this.showReactions,
    required this.maxWidth,
    required this.globalEventBloc,
    required this.userCircleCache,
    required this.memberBloc,
    required this.replyObjectBloc,
    required this.userFurnace,
    this.refresh,
    this.wall = false,
    this.replyObjects = const [],
    this.messageColor,
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
    double maxRowWidth = 400;

    if (circleObject.reactions == null) return Container();
    int crossAxisCount = (maxRowWidth - 45) ~/ 45;

    // if (isUser)
    //   circleObject.reactions!.sort((a, b) => b.index!.compareTo(a.index!));
    // else
    //   circleObject.reactions!.sort((a, b) => a.index!.compareTo(b.index!));

    bool noReactions = emptyReactions(circleObject);

    return !noReactions || wall
        ? Padding(
            padding: EdgeInsets.only(
                bottom: 10,
                top: 0,
                left: isUser ? 0 : 55,
                right: isUser ? 45 : 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Directionality(
                    textDirection:
                        isUser ? TextDirection.rtl : TextDirection.ltr,
                    child: GridView.builder(
                        itemCount: circleObject.reactions!.length + 2,
                        padding: const EdgeInsets.only(right: 0, left: 0),
                        controller: _scrollController,
                        shrinkWrap: true,
                        //reverse: isUser ? true : false,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 50),
                        itemBuilder: (BuildContext context, int index) {
                          ///Wall always goes one direction
                          if (wall) {
                            if (index == 0) {
                              return Row(children: [
                                WallRepliesWidget(
                                    replyObjects: replyObjects,
                                    circleObject: circleObject,
                                    userFurnace: userFurnace,
                                    replyObjectBloc: replyObjectBloc!,
                                    messageColor: messageColor!,
                                    refresh: refresh!,
                                    maxWidth: maxWidth,
                                    userCircleCache: userCircleCache,
                                    globalEventBloc: globalEventBloc,
                                    memberBloc: memberBloc!)
                              ]);
                            } else

                            ///Show the icon first
                            if (index == 1) {
                              return Row(children: [
                                icon(),
                              ]);
                            } else {
                              ///then show all the emojis
                              var arrayIndex = index - 1;

                              if (arrayIndex >
                                  circleObject.reactions!.length - 1) {
                                return Container();
                              }

                              CircleObjectReaction reaction =
                                  circleObject.reactions![arrayIndex];

                              return Row(children: [determineEmoji(reaction)]);
                            }
                          } else {
                            ///Show the icon first
                            if (index == 0) {
                              return Row(children: [
                                icon(),
                              ]);
                            } else {
                              ///then show all the emojis
                              var arrayIndex = index - 1;

                              if (arrayIndex >
                                  circleObject.reactions!.length - 1) {
                                return Container();
                              }

                              CircleObjectReaction reaction =
                                  circleObject.reactions![arrayIndex];

                              return Row(children: [determineEmoji(reaction)]);
                            }
                          }
                        })),
              )
            ]),
          )
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
        // onHover: globalState.isDesktop()
        //     ? (value) {
        //         if (value == true) {
        //           showReactions(circleObject);
        //         } else {
        //           Navigator.pop(widget.context);
        //         }
        //       }
        //     : null,
        onTap: () {
          showReactions(circleObject);
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
          longPress(circleObject, index);
        },
        onTap: () {
          shortPress(circleObject, index, "");
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
                  Text(getEmoji(index),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(fontSize: iconFontSize)),
                  Text(getCountString(index),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                          fontSize: 12, color: globalState.theme.menuIcons))
                ]))));
  }

  Widget emojiKeyboard(string) {
    return GestureDetector(
        onLongPress: () {
          longPress(circleObject, -1);
        },
        onTap: () {
          shortPress(circleObject, -1, string);
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

    for (CircleObjectReaction reaction in circleObject.reactions!) {
      for (User user in reaction.users) {
        if (user.id == userID) userReactions += 1;
      }
    }

    return userReactions;
  }

  String getCountStringEmoji(String emoji) {
    String retValue = '';
    for (CircleObjectReaction reaction in circleObject.reactions!) {
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

    for (CircleObjectReaction reaction in circleObject.reactions!) {
      if (reaction.index != null && reaction.index == index) {
        if (reaction.users.length > 1)
          retValue = reaction.users.length.toString();
        break;
      }
    }

    return retValue;
  }
}
