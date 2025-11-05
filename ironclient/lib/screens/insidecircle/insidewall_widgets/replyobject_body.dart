// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/utils/emojiutil.dart';

class ReplyObjectBody extends StatelessWidget {
  //final CircleObject? replyObject;
  final Function tapHandler;
  final UserCircleCache? userCircleCache;
  //final CircleObject circleObject;
  final ReplyObject replyObject;
  final Color messageColor;
  final Color? replyMessageColor;
  //final CrossAxisAlignment crossAxisAlignment;
  final double maxWidth;
  final Function longPressHandler;
  final bool isUser;

  const ReplyObjectBody({
    Key? key,
    required this.replyObject,
    required this.tapHandler,
    required this.userCircleCache,
    //required this.circleObject,
    required this.messageColor,
    //required this.crossAxisAlignment,
    this.replyMessageColor,
    required this.maxWidth,
    required this.longPressHandler,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    // debugPrint("message color: " + messageColor.toString());
    final spinkit = SpinKitThreeBounce(
      size: 20,
      color: globalState.theme.threeBounce,
    );

    String alias = '';
    //if (circleObject.reply != null)
    if (replyObject.creator != null) {
      alias =
          Member.returnAlias(replyObject.creator!.id!,//replyObject.replyUserID!,
              globalState.members);
    }

    final bodyWidget = replyObject.body == null || replyObject.body!.isEmpty
        ? Container()
        : replyObject.emojiOnly == null || replyObject.emojiOnly == false
        ? EmojiUtil.containsEmoji(replyObject.body!)
        ||
        (replyObject.taggedUsers != null &&
            replyObject.taggedUsers!.isNotEmpty)
        ? TextBold(
      text: replyObject.body!,
      messageColor: messageColor,
      taggedUsers: replyObject.taggedUsers,
    )
        : Text(replyObject.body!,
        //textAlign: TextAlign.end,
        textScaler:
        TextScaler.linear(globalState.messageScaleFactor),
        style: TextStyle(
            height: 1.4,
            color: messageColor,
            fontSize: globalState.userSetting.fontSize))
        : Text(
      replyObject.body!,
      textScaler: TextScaler.linear(globalState.messageScaleFactor),
      style: TextStyle(
          height: 1.4,
          color: messageColor,
          fontSize: globalState.emojiOnlySize),
    );

    return GestureDetector(
      onLongPress: () {
        longPressHandler(replyObject, isUser);
      },
      onTap: () {
        tapHandler(replyObject);
      },
      child: bodyWidget,
    );

    //return
      // circleObject.reply != null || circleObject.replyObjectID != null
      //   ? InkWell(
      //   onTap: () {
      //     replyObjectTapHandler!(circleObject);
      //   },
      //   child: Column(crossAxisAlignment: crossAxisAlignment, children: [
      //     circleObject.replyObjectID == null
      //         ? Text(
      //       "reply to ${circleObject.replyUsername!}${alias.isEmpty ? '' : ' ($alias)'}: ${circleObject.reply!}",
      //       textScaler:
      //       TextScaler.linear(globalState.messageScaleFactor),
      //       style: TextStyle(
      //           fontStyle: FontStyle.italic,
      //           fontSize: globalState.userSetting.fontSize,
      //           color: replyMessageColor),
      //     )
      //         : Column(crossAxisAlignment: crossAxisAlignment, children: [
      //       Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Flexible(
      //                 child: Text(
      //                   "reply to ${circleObject.replyUsername!}${alias.isEmpty ? '' : ' ($alias)'}: ${replyObject!.type == CircleObjectType.CIRCLELINK ? '[link]' : circleObject.reply!}",
      //                   softWrap: true,
      //                   textScaler: TextScaler.linear(
      //                       globalState.messageScaleFactor),
      //                   style: TextStyle(
      //                       fontStyle: FontStyle.italic,
      //                       fontSize: globalState.userSetting.fontSize,
      //                       color: replyMessageColor),
      //                 ))
      //           ]),
      //       const Padding(
      //         padding: EdgeInsets.only(bottom: 8),
      //       ),
      //       replyObject == null
      //           ? Container()
      //           : ShowReplyWidget(
      //         replyObject: replyObject!,
      //         mainObject: circleObject,
      //         userCircleCache: userCircleCache!,
      //         maxWidth: maxWidth - 25,
      //       )
      //     ]),
      //     const Padding(
      //       padding: EdgeInsets.only(bottom: 8),
      //     ),
      //     bodyWidget,
      //   ]))
      //   :
    // replyObject.verificationFailed.isNotEmpty &&
    //     globalState.user.role == Role.IC_ADMIN
    //     ? Column(
    //     crossAxisAlignment: crossAxisAlignment,
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Container(
    //           padding: const EdgeInsets.all(10),
    //           child: Text(
    //             replyObject.verificationFailed,
    //             style: TextStyle(
    //                 fontStyle: FontStyle.italic,
    //                 fontSize: globalState.userSetting.fontSize,
    //                 color: Colors.red),
    //           )),
    //       bodyWidget,
    //     ])
        //:
    //bodyWidget;
  }
}

class ReplyObjectBodyWrapped extends StatelessWidget {
  final CircleObject circleObject;
  //final CircleObject? replyObject;
  final ReplyObject? replyObject;
  final UserCircleCache userCircleCache;
  final Color messageColor;
  final Color? replyMessageColor;
  final CrossAxisAlignment crossAxisAlignment;
  final double maxWidth;
  final Function longPressHandler;
  final bool isUser;
  final Function tapHandler;

  const ReplyObjectBodyWrapped(
      {Key? key,
        required this.circleObject,
        required this.userCircleCache,
        this.replyObject,
        //this.replyObject,
        required this.messageColor,
        required this.crossAxisAlignment,
        this.replyMessageColor,
        required this.maxWidth,
        required this.longPressHandler,
        required this.isUser,
        required this.tapHandler})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
      circleObject.body != null
          ? (circleObject.body!.isNotEmpty ||
          circleObject.replyUsername != null)
          ? ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        //maxWidth: 250,
        //height: 20,
        child: Container(
          padding:
          const EdgeInsets.all(InsideConstants.MESSAGEPADDING),
          //color: globalState.theme.dropdownBackground,
          decoration: const BoxDecoration(
            //color: globalState.theme.memberObjectBackground,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0))),
          child: ReplyObjectBody(
            replyObject: replyObject!,
            tapHandler: tapHandler,
            //circleObject: circleObject,
            userCircleCache: userCircleCache,
            messageColor: messageColor,
            replyMessageColor: replyMessageColor,
            //crossAxisAlignment: crossAxisAlignment,
            maxWidth: maxWidth,
            longPressHandler: longPressHandler,
            isUser: isUser,
          ),
        ),
      )
          : Container()
          : Container(),
    ]);
  }
}

class TextBold extends StatelessWidget {
  final String text;
  //final String regex;
  final Color messageColor;

  final List<User>? taggedUsers;
  //List<Member> taggedMembers = [];

  const TextBold(
      {Key? key,
        required this.text,
        required this.messageColor,
        required this.taggedUsers})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final parts = splitJoin();

    return Text.rich(
      TextSpan(
          children: parts
              .map((e) => TextSpan(
              text: e.text,
              style: (e.isEmoji)
                  ? TextStyle(
                height: 1.1,
                fontSize: (globalState.emojiEmbededSize),
                color: messageColor,
              )
                  : (taggedUsers != null && taggedUsers!.isNotEmpty)
                  ? (taggedUsers!
                  .where((element) =>
              element.username == e.text.substring(1))
                  .isNotEmpty)
                  ? TextStyle(
                height: 1.4,
                fontSize: globalState.userSetting.fontSize,
                color: Colors.yellow,
                backgroundColor:
                Colors.brown[400]!.withOpacity(.7),
              )
                  : TextStyle(
                height: 1.4,
                fontSize: globalState.userSetting.fontSize,
                color: messageColor,
              )
                  : TextStyle(
                height: 1.4,
                fontSize: globalState.userSetting.fontSize,
                color: messageColor,
              )))
              .toList()),
      textScaler: TextScaler.linear(globalState.messageScaleFactor),
    );
  }

  /// Splits text using separator, tag ones to be font increased using regex
  /// and rejoin equal parts back when possible
  List<TextPart> splitJoin() {
    //assert(text != null);

    final tmp = <TextPart>[];

    final parts = text.characters;

    List<String> tagCheck = [];
    if (taggedUsers != null && taggedUsers!.isNotEmpty) {
      taggedUsers!.forEach((element) {
        tagCheck.add("@${element.username!}");
      });
    }

    // increase font
    for (final p in parts) {
      bool maybeEmoji = p.contains(EmojiUtil.regexEmoji);

      if (maybeEmoji) {
        // debugPrint(EmojiUtil.excludeEmoji.contains(p.codeUnits.toString()));
        //debugPrint('$p + ${p.codeUnits.toString()}');

        if (EmojiUtil.excludeEmoji.contains(p.codeUnits.toString())) {
          maybeEmoji = false;
        }
      }
      tmp.add(TextPart(p, maybeEmoji));

      /// make loop here to change color
    }

    final result = <TextPart>[]; //[tmp[0]]
    bool tagging = false;
    // Fold it
    if (tmp.length > 1) {
      int resultIdx = 0;
      if (tmp[0].text == ("@")) {
        tagging = true;
        result.add(tmp[0]);
        //resultIdx++;
      } else {
        result.add(tmp[0]);
      }
      for (int i = 1; i < tmp.length; i++) {
        if (tmp[i].text == ("@")) {
          tagging = true;
          result.add(tmp[i]);
          resultIdx++;
        } else if (tmp[i].text == " " && tagging == true) {
          String current = result[resultIdx].text;

          if (tagCheck.contains(current)) {
            tagging = false;
            result.add(tmp[i]);
            resultIdx++;
            tagCheck.remove(current);
          } else {
            result[resultIdx].text = result[resultIdx].text + tmp[i].text;
          }
        } else if (tagging == true) {
          result[resultIdx].text = result[resultIdx].text + tmp[i].text;
        } else if (tmp[i - 1].isEmoji != tmp[i].isEmoji) {
          result.add(tmp[i]);
          resultIdx++;
        } else {
          result[resultIdx].text = result[resultIdx].text + tmp[i].text;
        }
      }
    } else {
      /// Added this line because some single emojis were not showing up
      result.add(tmp[0]);
    }

    return result;
  }

}

class TextPart {
  String text;
  bool isEmoji;

  TextPart(this.text, this.isEmoji);
}
