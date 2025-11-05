// import 'package:flutter/material.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
//
// class TypeAndSendMessage extends StatefulWidget {
//   final UserCircleCache userCircleCache;
//   final UserFurnace userFurnace;
//
//   const TypeAndSendMessage({
//     Key? key,
//     required this.userCircleCache,
//     required this.userFurnace,
//   }) : super(key: key);
//
//   @override
//   _TypeAndSendMessageState createState() => _TypeAndSendMessageState();
// }
//
// class _TypeAndSendMessageState extends State<TypeAndSendMessage> {
//   bool _editing = false;
//   String memberSearch = "";
//   bool memberSearchBegin = false;
//   List<Member> membersFiltered = [];
//   String clickedMember = "";
//   List<Member> messageMembers = [];
//
//   /// get current cursor position
//   int currentIndex = 0;
//
//   /// get text from start to cursor
//   String textChunk = "";
//
//   /// trim to text from @ to cursor
//   int whereTag = 0;
//   String typingTag = "";
//   List<Member> oldMembersFiltered = [];
//   List<User> members = [];
//   CircleObject? _editingObject;
//   CircleObject? _replyObject;
//   final ScrollController _scrollController = ScrollController();
//   List<Member> _members = [];
//   List<User> taggedUsers = [];
//   final _message = TextEditingController();
//   bool _sendEnabled = false;
//   bool _membersList = false;
//   late Circle _circle;
//   late FocusNode _focusNode; // = FocusNode();
//
//   final separator = Container(
//     color: globalState.theme.background,
//     height: 1,
//     width: double.maxFinite,
//   );
//
//   @override
//   void initState() {
//     _circle = widget.userCircleCache.cachedCircle!;
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = globalState.setScale(MediaQuery.of(context).size.width,
//         mediaScaleFactor: MediaQuery.of(context).textScaleFactor);
//
//     double maxWidth = InsideConstants.getCircleObjectSize(screenWidth);
//
//     final makeBottom =
//         Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
//       Padding(
//           padding: const EdgeInsets.only(
//             left: 10,
//           ),
//           child: Row(children: <Widget>[
//             Expanded(
//               flex: 100,
//               child: Stack(alignment: Alignment.topRight, children: [
//                 ConstrainedBox(
//                     constraints: const BoxConstraints(
//                         maxHeight:
//                             125 //put here the max height to which you need to resize the textbox
//                         ),
//                     child: TextField(
//                         controller: _message,
//                         focusNode: _focusNode,
//                         maxLines: null,
//                         maxLength: TextLength.Largest,
//                         //lines < maxLines ? null : maxLines,
//                         textCapitalization: TextCapitalization.sentences,
//                         style: TextStyle(
//                             fontSize: (globalState.userSetting.fontSize /
//                                     globalState.mediaScaleFactor) *
//                                 globalState.textFieldScaleFactor, //18,
//                             color: globalState.theme.userObjectText),
//                         decoration: InputDecoration(
//                           counterText: '',
//                           filled: true,
//                           fillColor: globalState.theme.messageBackground,
//                           hintText: _replyObject != null
//                               ? 'reply to ironclad message'
//                               : _circle.type! == CircleType.VAULT
//                                   ? 'stash in vault'
//                                   : 'send ironclad message',
//                           hintStyle: TextStyle(
//                             color: globalState.theme.messageTextHint,
//                             fontSize: ((globalState.userSetting.fontSize -
//                                         globalState.scaleDownTextFont) /
//                                     globalState.mediaScaleFactor) *
//                                 globalState.textFieldScaleFactor,
//                           ),
//                           contentPadding: EdgeInsets.only(
//                               left: 14,
//                               bottom: 10,
//                               top: 10,
//                               right: _sendEnabled ? 42 : 0),
//                           focusedBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(
//                                 color: globalState.theme.messageBackground),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           enabledBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(
//                                 color: globalState.theme.messageBackground),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onChanged: (text) {
//                           bool enableSend = true;
//                           clickedMember = "";
//
//                           if (text.isEmpty) {
//                             taggedUsers = [];
//                             setState(() {
//                               _membersList = false;
//                             });
//                             if (_editing) {
//                               if (_editingObject != null) {
//                                 if (_editingObject!.type ==
//                                     CircleObjectType.CIRCLEMESSAGE) {
//                                   enableSend = false;
//                                 }
//                               }
//                             } else
//                               enableSend = false;
//                           } else {
//                             enableSend = true;
//
//                             if (text.contains("@")) {
//                               for (Member m in _members) {
//                                 User user =
//                                     User(id: m.memberID, username: m.username);
//                                 bool taggedAlready = taggedUsers
//                                     .where((element) =>
//                                         element.username == m.username)
//                                     .isNotEmpty;
//                                 if (text.contains(m.username) &&
//                                     taggedAlready == false) {
//                                   taggedUsers.add(user);
//                                 }
//                               }
//
//                               oldMembersFiltered = membersFiltered;
//
//                               /// set username list to all members
//                               membersFiltered = _members;
//
//                               /// filter out members already tagged, KEEP IN MIND THE CHANGE HERE
//                               membersFiltered = membersFiltered
//                                   .where((element) =>
//                                       !text.contains("${element.username} "))
//                                   .toList();
//
//                               /// filter out user
//                               membersFiltered = membersFiltered
//                                   .where((element) =>
//                                       element.memberID != element.userID)
//                                   .toList();
//
//                               if (membersFiltered.isNotEmpty) {
//                                 /// get current cursor position
//                                 currentIndex = _message.selection.base.offset;
//
//                                 /// get text from start to cursor
//                                 textChunk = text.substring(0, currentIndex);
//
//                                 /// trim to text from @ to cursor
//                                 whereTag = textChunk.lastIndexOf("@");
//                                 typingTag = textChunk.substring(
//                                     whereTag + 1, currentIndex);
//
//                                 ///get letter to the left
//                                 String leftLetter = text.substring(
//                                     currentIndex - 1, currentIndex);
//
//                                 if (leftLetter == "@") {
//                                   ///if that letter is @ symbol, show username menu
//                                   setState(() {
//                                     _membersList = true;
//                                   });
//                                 } else if (leftLetter == " ") {
//                                   ///if user is done tagging member
//                                   setState(() {
//                                     _membersList = false;
//                                   });
//                                 } else if (_membersList == true ||
//                                     !typingTag.contains(" ")) {
//                                   /// if user types letter of tag
//                                   /// filter by typed tag so far
//                                   membersFiltered = membersFiltered
//                                       .where((element) => element.username
//                                           .toLowerCase()
//                                           .startsWith(typingTag.toLowerCase()))
//                                       .toList();
//                                   setState(() {
//                                     _membersList = true;
//                                   });
//                                 }
//                               }
//                             } else {
//                               ///added this line to improve performance when typing fast
//                               if (_membersList == true) {
//                                 taggedUsers = [];
//                                 setState(() {
//                                   _membersList = false;
//                                 });
//                               }
//                             }
//                           }
//
//                           if (enableSend != _sendEnabled) {
//                             setState(() {
//                               _sendEnabled = enableSend;
//                             });
//                           }
//                         })),
//                 _sendEnabled
//                     ? IconButton(
//                         icon: Icon(Icons.cancel_rounded,
//                             color: globalState.theme.buttonDisabled),
//                         iconSize: 22,
//                         onPressed: () {
//                           _clear(true);
//                         },
//                       )
//                     : Container(),
//               ]),
//               //}),
//             ),
//             const Padding(padding: EdgeInsets.only(left: 8)),
//             Column(children: <Widget>[
//               _editingObject == null
//                   ? SizedBox(
//                       height: 40,
//                       //width:80,
//                       child: IconButton(
//                         icon: Icon(
//                           Icons.send_rounded,
//                           size: 30,
//                           color: _sendEnabled
//                               ? globalState.theme.bottomHighlightIcon
//                               : globalState.theme.buttonDisabled,
//                         ),
//                         onPressed: () {
//                           _send();
//                         },
//                       ))
//                   : SizedBox(
//                       height: 40,
//                       //width:80,
//                       child: TextButton(
//                         child: Text(
//                           'EDIT',
//                           textScaleFactor: 1.0,
//                           style: TextStyle(
//                               fontSize: 18,
//                               color: _sendEnabled
//                                   ? globalState.theme.bottomHighlightIcon
//                                   : globalState.theme.buttonDisabled),
//                         ),
//                         onPressed: () {
//                           _send();
//                         },
//                       )),
//             ]),
//             const Padding(padding: EdgeInsets.only(left: 5)),
//           ]
//               // decoration: BoxDecoration(color: Colors.black),
//               )),
//       const Padding(padding: EdgeInsets.only(bottom: 5)),
//     ]);
//
//     return Stack(children: [
//       Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
//         _membersList
//             ? SizedBox(
//                 height: 100,
//                 child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Expanded(
//                           child: SingleChildScrollView(
//                         child: Container(
//                             color: globalState.theme.messageBackground,
//                             width: 200,
//                             height: 200,
//                             padding: const EdgeInsets.only(
//                                 left: 0, right: 0, top: 0, bottom: 0),
//                             child: ListView.builder(
//                               // itemBuilder: (context, index) => Divider(
//                               //   color: globalState.theme.divider,
//                               // ),
//                               scrollDirection: Axis.vertical,
//                               controller: _scrollController,
//                               shrinkWrap: true,
//                               itemCount: membersFiltered.length,
//                               //_members
//                               itemBuilder: (BuildContext context, int index) {
//                                 Member row = membersFiltered[index]; //_members
//                                 User user = User(
//                                     id: row.memberID,
//                                     username: row.username); //User row
//
//                                 return Container(
//                                     child: Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 10, top: 15, bottom: 10, right: 10),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     children: <Widget>[
//                                       InkWell(
//                                           onTap: () {
//                                             setState(() {
//                                               if (!taggedUsers
//                                                   .contains(row.username)) {
//                                                 taggedUsers.add(user);
//                                               }
//
//                                               /// add tag to text
//                                               _message.text = _message.text
//                                                   .replaceFirst(
//                                                       typingTag,
//                                                       "${row.username} ",
//                                                       whereTag + 1);
//
//                                               /// move cursor to end of added tag
//                                               _message.selection =
//                                                   TextSelection.collapsed(
//                                                       offset: whereTag +
//                                                           row.username.length +
//                                                           2);
//
//                                               /// close this menu
//                                               _membersList = false;
//                                             });
//                                           },
//                                           child: Row(children: [
//                                             AvatarWidget(
//                                                 user: user,
//                                                 userFurnace: widget.userFurnace,
//                                                 radius: 30,
//                                                 refresh: _refresh,
//                                                 showDM: true,
//                                                 isUser: user.id ==
//                                                     widget.userFurnace.userid),
//                                             const Padding(
//                                               padding:
//                                                   EdgeInsets.only(right: 10),
//                                             ),
//                                             Text(
//                                               row.username.length > 20
//                                                   ? user
//                                                       .getUsernameAndAlias(
//                                                           globalState)
//                                                       .substring(0, 19)
//                                                   : user.getUsernameAndAlias(
//                                                       globalState),
//                                               textScaleFactor:
//                                                   globalState.labelScaleFactor,
//                                               style: TextStyle(
//                                                   fontSize: 17,
//                                                   color: Member.returnColor(
//                                                       user.id!,
//                                                       globalState.members)),
//                                             )
//                                           ])),
//                                     ],
//                                   ),
//                                 ));
//                               },
//                             )),
//                       ))
//                     ]))
//             // MemberList(
//             // userCircleCache: userCircleCache,
//             // userFurnace: userFurnace,
//             // ),
//             : Container(),
//         Container(
//           //  color: Colors.white,
//           padding: const EdgeInsets.all(0.0),
//           child: makeBottom,
//         ),
//       ])
//     ]);
//   }
//
//   _clear(bool value) {}
//   _send() {}
//   _refresh() {}
// }
