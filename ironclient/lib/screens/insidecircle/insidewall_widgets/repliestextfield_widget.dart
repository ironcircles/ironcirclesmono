import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';

class RepliesTextField extends StatefulWidget {
  final TextEditingController message;
  final Function clear;
  final FocusNode focusNode;
  final CircleObject? replyToObject;
  //final ParentType parentType;
  final bool editing;
  final ReplyObject? editingObject;
  final String replyingObjectID;
  final String clickedMember;
  final List<Member> members;
  final List<User> taggedUsers;
  final String typingTag;
  final Function setTypingTag;
  final Function setSendEnabled;
  final bool sendEnabled;
  final bool membersList;
  final Function setMembersList;
  final int whereTag;
  final Function setWhereTag;
  //final Function setTimer;
  //final Function setScheduled;
  //final Function showSlidingPanel;
  //final bool wall;
  //final int timer;
  //final Key timerKey;
  //final Function passMediaCollection;
  final Function passMembersFiltered;

  const RepliesTextField(
      {required this.message,
        required this.clear,
        required this.focusNode,
        required this.replyToObject,
        //required this.parentType,
        required this.sendEnabled,
        //required this.timerKey,
        required this.editing,
        //required this.timer,
        required this.editingObject,
        required this.replyingObjectID,
        required this.taggedUsers,
        required this.setSendEnabled,
        required this.members,
        required this.membersList,
        required this.setMembersList,
        required this.typingTag,
        required this.setTypingTag,
        //required this.wall,
        required this.whereTag,
        //required this.setTimer,
        //required this.setScheduled,
        //required this.showSlidingPanel,
        required this.setWhereTag,
        required this.clickedMember,
        required this.passMembersFiltered,
        //required this.passMediaCollection
      });

  @override
  _RepliesTextFieldState createState() => _RepliesTextFieldState();
}

class _RepliesTextFieldState extends State<RepliesTextField> {
  /// get current cursor position
  int currentIndex = 0;

  DateTime? _scheduledDate;

  /// get text from start to cursor
  String textChunk = "";
  String tagChunk = "";

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    super.initState();
  }

  IconButton buildButtonColumn(
      IconData icon, Color? color, Function onClick, Key key,
      {double iconSize = 37}) {
    // Color color = Theme.of(context).primaryColor;

    return IconButton(
      key: key,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: iconSize - globalState.scaleDownIcons,
      icon: Icon(
        icon,
        size: iconSize - globalState.scaleDownIcons,
      ),
      onPressed: onClick as void Function()?,

      color: color,
      //size: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ConstrainedBox(
            constraints: const BoxConstraints(
                maxHeight:
                125 //put here the max height to which you need to resize the textbox
            ),
            child: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1),
                ),
                child: TextField(
                    cursorColor: globalState.theme.textField,
                    // contentInsertionConfiguration: ContentInsertionConfiguration(
                    //     onContentInserted: (KeyboardInsertedContent data) {
                    //       if (data.mimeType == "image/png") {
                    //         _getKeyboardMedia(data);
                    //       } else if (data.mimeType == "image/gif") {
                    //         _getKeyboardMedia(data);
                    //       }
                    //     }),
                    controller: widget.message,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    maxLength: TextLength.Largest,
                    //lines < maxLines ? null : maxLines,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: globalState.theme.userObjectText,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: globalState.theme.slideUpPanelBackground,
                      hintText: widget.replyingObjectID.isNotEmpty
                          ? AppLocalizations.of(context)!.respondToReply
                          : AppLocalizations.of(context)!.replyToWallPost,
                      hintStyle: TextStyle(
                          color: globalState.theme.messageTextHint,
                          fontSize: 16),
                      contentPadding: EdgeInsets.only(
                          left: 10,//50,
                          bottom: 10,
                          top: 10,
                          right: widget.sendEnabled ? 50 : 0),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: globalState.theme.messageBackground),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: globalState.theme.messageBackground),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (text) {
                      bool localSendEnable = true;

                      if (text.isEmpty) {
                        widget.taggedUsers.clear();
                        widget.setMembersList(false);
                        if (widget.editing) {
                          if (widget.editingObject != null) {
                            // if (widget.editingObject!.type ==
                            //     CircleObjectType.CIRCLEMESSAGE) {
                            //   localSendEnable = false;
                            // }
                            ///? what
                          }
                        } else
                          localSendEnable = false;
                      } else {
                        localSendEnable = true;

                        ///TAGGING: add back in later
                        if (text.contains("@")) {
                          for (Member m in widget.members) {
                            User user = User(id: m.memberID, username: m.username);
                            bool taggedAlready = widget.taggedUsers
                                .where((element) => element.username == m.username)
                                .isNotEmpty;
                            if (text.contains(m.username) &&
                                taggedAlready == false) {
                              widget.taggedUsers.add(user);
                            }
                          }

                          /// set username list to all members
                          List<Member> membersFiltered = widget.members;

                          /// filter out members already tagged, KEEP IN MIND THE CHANGE HERE
                          membersFiltered = membersFiltered
                              .where((element) =>
                          !text.contains("${element.username} "))
                              .toList();

                          /// filter out user
                          membersFiltered = membersFiltered
                              .where(
                                  (element) => element.memberID != element.userID)
                              .toList();

                          if (membersFiltered.isNotEmpty) {

                            /// get current cursor position
                            currentIndex = widget.message.selection.base.offset;

                            /// get text from start to cursor
                            textChunk = text.substring(0, currentIndex);

                            /// trim to text from @ to cursor
                            tagChunk;
                            widget.setWhereTag(textChunk.lastIndexOf("@"));
                            if ((widget.whereTag + 1) <= currentIndex) {
                              tagChunk = textChunk.substring(widget.whereTag + 1, currentIndex);
                              widget.setTypingTag(tagChunk);
                            }

                            ///get letter to the left
                            String leftLetter =
                            text.substring(currentIndex - 1, currentIndex);

                            if (leftLetter == "@") {
                              ///if that letter is @ symbol, show username menu
                              widget.setMembersList(true);
                              widget.passMembersFiltered(membersFiltered);
                            } else if (leftLetter == " ") {
                              ///if user is done tagging member
                              widget.setMembersList(false);
                            } else if (widget.membersList == true ||
                                !widget.typingTag.contains(" ")) {
                              /// if user types letter of tag
                              /// filter by typed tag so far
                              membersFiltered = membersFiltered
                                  .where((element) => element.username
                                  .toLowerCase()
                                  .contains(tagChunk.toLowerCase())
                                  || element.alias.toLowerCase().contains(tagChunk.toLowerCase()))
                              //.startsWith(widget.typingTag.toLowerCase()))
                                  .toList();
                              widget.passMembersFiltered(membersFiltered);
                              widget.setMembersList(true);
                            }
                          }
                        } else {
                          ///added this line to improve performance when typing fast
                          if (widget.membersList == true) {
                            widget.taggedUsers.clear();
                            widget.setMembersList(false);
                          }
                        }
                      }

                      if (localSendEnable != widget.sendEnabled) {
                        widget.setSendEnabled(localSendEnable);
                      }
                    }))),
        // Align(
        //     alignment: Alignment.centerLeft,
        //     child: IconButton(
        //       icon: Icon(Icons.add, color: globalState.theme.buttonDisabled),
        //       iconSize: 24,
        //       onPressed: () {
        //         widget.showSlidingPanel();
        //       },
        //     )),

        // widget.sendEnabled && widget.editing
        //     ? IconButton(
        //         icon: Icon(Icons.cancel_rounded,
        //             color: globalState.theme.buttonDisabled),
        //         iconSize: 22,
        //         onPressed: () {
        //           DialogYesNo.askYesNo(
        //               context,
        //               'Cancel post?',
        //               'Are you sure you want to cancel this post?',
        //               _confirmCancel,
        //               null,
        //               false);
        //         },
        //       )
        //     : Container(),
      ],

      //}),
    );
  }

// _getKeyboardMedia(KeyboardInsertedContent data) async {
//   String tempDir = await FileSystemService.returnTempPath();
//   int index = data.uri.lastIndexOf('/');
//   String name = data.uri.substring(index);
//   File file = await File('$tempDir/$name').create();
//   file.writeAsBytesSync(data.data!.toList());
//   Media media = Media(mediaType: MediaType.image, path: file.path);
//   widget.setSendEnabled(true);
//   setState(() {
//     widget.passMediaCollection(media);
//   });
// }
//
// _closeKeyboard() {
//   FocusScope.of(context).requestFocus(FocusNode());
// }
}
