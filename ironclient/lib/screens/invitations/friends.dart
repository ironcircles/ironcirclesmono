// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
// import 'package:ironcirclesapp/blocs/librarybloc.dart';
// import 'package:ironcirclesapp/blocs/member_bloc.dart';
// import 'package:ironcirclesapp/screens/invitations/memberprofile.dart';
// import 'package:ironcirclesapp/screens/invitations/network_invite.dart';
// import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
// import 'package:provider/provider.dart';
//
// import 'package:ironcirclesapp/blocs/circle_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
// import '../../blocs/circle_bloc.dart';
// import '../../models/export_models.dart';
// import '../widgets/widget_export.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class Friends extends StatefulWidget {
//   final List<UserFurnace> userFurnaces;
//   final UserFurnace? filteredUserFurnace;
//   //final List<Invitation> invitations;
//
//   const Friends({
//     Key? key,
//     required this.userFurnaces,
//     required this.filteredUserFurnace,
//   }) : super(key: key);
//
//   @override
//   _FriendsState createState() => _FriendsState();
// }
//
// class _FriendsState extends State<Friends> {
//   List<Member> _allMembers = [];
//   final List<Member> _filteredMembers = [];
//   final MemberBloc _memberBloc = MemberBloc();
//   final CircleBloc _circleBloc = CircleBloc();
//   final InvitationBloc _invitationBloc = InvitationBloc();
//   late GlobalEventBloc _globalEventBloc;
//   final TextEditingController _username = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//   bool changed = false;
//   late LibraryBloc _crossBloc;
//   List<UserCircleCache> _userCircles = [];
//   UserFurnace? _filteredFurnace;
//
//   bool _showSpinner = true;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//
//   @override
//   void initState() {
//     _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
//     _crossBloc = LibraryBloc(globalEventBloc: _globalEventBloc);
//
//     _crossBloc.circles.listen((circles) async {
//       _userCircles = circles;
//
//       _memberBloc.getConnectedMembers(widget.userFurnaces, _userCircles,
//           removeDM: false);
//     }, onError: (err) {
//       debugPrint("InsideCircle.listen: $err");
//     }, cancelOnError: false);
//
//     _globalEventBloc.memberRefreshNeeded.listen((event) {
//       _memberBloc.getConnectedMembers(widget.userFurnaces, _userCircles,
//           removeDM: false);
//     }, onError: (err) {
//
//
//       debugPrint("error $err");
//     }, cancelOnError: false);
//
//     _invitationBloc.inviteResponse.listen((invitation) {
//       if (mounted) {
//         _globalEventBloc.broadcastRefreshHome();
//
//         Navigator.pop(context);
//       }
//     }, onError: (err) {
//       debugPrint("error $err");
//     }, cancelOnError: false);
//
//     _invitationBloc.findUsers.listen((users) {
//       if (mounted) {
//         if (users.isEmpty) {
//           DialogNotice.showNotice(
//               context,
//               AppLocalizations.of(context).notice,
//               AppLocalizations.of(context).userNotFound,
//               null,
//               null,
//               null,
//               false);
//         } else if (users.length == 1) {
//           _confirmCreateDirectMessage(
//               ConfirmationParams(
//                   userFurnace: users[0].userFurnace!, user: users[0]),
//               users[0].username!,
//               _createDirectMessageWithNoUserConfirmed);
//         }
//
//         setState(() {
//           _showSpinner = false;
//         });
//       }
//     }, onError: (err) {
//       debugPrint("error $err");
//       setState(() {
//         _showSpinner = false;
//       });
//
//       DialogNotice.showNotice(
//           context,
//           "Notice",
//           err.toString().replaceFirst("Exception:", ''),
//           null,
//           null,
//           null,
//           true);
//     }, cancelOnError: false);
//
//     _circleBloc.createdResponse.listen((response) {
//       ///empty on purpose
//       ///
//     }, onError: (err) {
//       setState(() {
//         _showSpinner = false;
//       });
//
//       ///don't display a warning if the DM is hidden
//       if (err.toString().contains("SILENT")) return;
//
//       DialogNotice.showNotice(
//           context,
//           "Notice",
//           err.toString().replaceFirst("Exception:", ''),
//           null,
//           null,
//           null,
//           true);
//       debugPrint("error $err");
//     }, cancelOnError: false);
//
//     _memberBloc.loaded.listen((members) {
//       if (mounted) {
//         setState(() {
//           _allMembers = members;
//
//           _filteredMembers.clear();
//           _filteredMembers.addAll(_allMembers);
//
//           if (widget.filteredUserFurnace != null)
//             _filteredMembers.retainWhere((element) =>
//                 element.furnaceKey == widget.filteredUserFurnace!.pk);
//
//           _showSpinner = false;
//         });
//       }
//     }, onError: (err) {
//       debugPrint("error $err");
//     }, cancelOnError: false);
//
//     _crossBloc.sinkCircles(widget.userFurnaces);
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_allMembers.isNotEmpty) {
//       if (widget.filteredUserFurnace != _filteredFurnace) {
//         _filteredFurnace = widget.filteredUserFurnace;
//
//         _filteredMembers.clear();
//         _filteredMembers.addAll(_allMembers);
//
//         if (_filteredFurnace != null)
//           _filteredMembers.retainWhere((element) =>
//               element.furnaceKey == widget.filteredUserFurnace!.pk);
//       }
//       _filteredMembers.removeWhere((element) => element.lockedOut == true);
//     }
//
//     final makeBody = SingleChildScrollView(
//         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//         child: ConstrainedBox(
//             constraints: const BoxConstraints(),
//             child: Container(
//               // color: Colors.black,
//               padding: const EdgeInsets.only(
//                   left: 20, right: 20, top: 0, bottom: 10),
//               child:
//                   Column(mainAxisAlignment: MainAxisAlignment.start, children: <
//                       Widget>[
//                 Container(
//                     // color: Colors.black,
//                     padding: const EdgeInsets.only(
//                         left: 10, right: 10, top: 0, bottom: 20),
//                     child: ListView.separated(
//                       separatorBuilder: (context, index) => Divider(
//                         color: globalState.theme.divider,
//                       ),
//                       scrollDirection: Axis.vertical,
//                       controller: _scrollController,
//                       shrinkWrap: true,
//                       itemCount: _filteredMembers.length,
//                       itemBuilder: (BuildContext context, int index) {
//                         Member row = _filteredMembers[index];
//
//                         if (row.lockedOut) return Container();
//
//                         User user =
//                             User(id: row.memberID, username: row.username);
//
//                         int networkIndex = widget.userFurnaces.indexWhere(
//                             (element) => element.pk == row.furnaceKey);
//
//                         if (networkIndex == -1)
//                           return Container();
//                         else {
//                           UserFurnace userFurnace =
//                               widget.userFurnaces[networkIndex];
//
//                           return Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 0.0, top: 0.0, bottom: 0.0, right: 0.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: <Widget>[
//                                 AvatarWidget(
//                                   interactive: true,
//                                   user: user,
//                                   userFurnace: userFurnace,
//                                   radius: 60 - (globalState.scaleDownIcons * 2),
//                                   refresh: _doNothing,
//                                   isUser: false,
//                                   showDM: true,
//                                 ),
//                                 Expanded(
//                                     child: Column(children: [
//                                   Row(children: [
//                                     Expanded(
//                                         child: InkWell(
//                                             onTap: () {
//                                               _showProfile(user, userFurnace);
//                                             },
//                                             child: Padding(
//                                               padding: const EdgeInsets.only(
//                                                   left: 10),
//                                               child: ICText(
//                                                 user.getUsernameAndAlias(
//                                                     globalState),
//                                                 textScaleFactor: globalState
//                                                     .labelScaleFactor,
//                                                 textAlign: TextAlign.left,
//                                                 fontSize: 16,
//                                                 color: Member.returnColor(
//                                                     row.memberID,
//                                                     globalState.members),
//                                               ),
//                                             )))
//                                   ]),
//                                   Row(children: [
//                                     Expanded(
//                                       child: InkWell(
//                                         onTap: () {
//                                           _showProfile(user, userFurnace);
//                                         },
//                                         child: Padding(
//                                             padding:
//                                                 const EdgeInsets.only(left: 10),
//                                             child: ICText(userFurnace.alias!,
//                                                 textScaleFactor: globalState
//                                                     .labelScaleFactor,
//                                                 textAlign: TextAlign.left,
//                                                 fontSize: 16,
//                                                 color:
//                                                     globalState.theme.furnace)),
//                                       ),
//                                     )
//                                   ])
//                                 ]))
//                               ],
//                             ),
//                           );
//                         }
//                       },
//                     ))
//               ]),
//             )));
//
//     return WillPopScope(
//         onWillPop: () {
//           //Navigator.of(context, ).pop(_userCircleCache);
//
//           if (changed)
//             Navigator.pop(context, changed);
//           else
//             Navigator.pop(
//               context,
//             );
//
//           return Future<bool>.value(false);
//         },
//         child: Scaffold(
//             key: _scaffoldKey,
//             backgroundColor: globalState.theme.background,
//             body: Stack(children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: <Widget>[
//                   _filteredMembers.isNotEmpty
//                       ? Expanded(
//                           child: makeBody,
//                         )
//                       : const Spacer(),
//                   Padding(
//                       padding: const EdgeInsets.only(
//                           left: 0, right: 0, top: 5, bottom: 0),
//                       child: Container(
//                           margin: EdgeInsets.symmetric(
//                               horizontal: ButtonType.getWidth(
//                                   MediaQuery.of(context).size.width)),
//                           child: GradientButton(
//                               onPressed: _sendMagicCode,
//                               // fontSize: 20, height: 45,
//                               text:
//                                   AppLocalizations.of(context).inviteFriends))),
//                 ],
//               ),
//               _showSpinner ? Center(child: spinkit) : Container(),
//             ])));
//     //  bottomNavigationBar: makeBottom,
//   }
//
//   void _showProfile(User member, UserFurnace userFurnace) async {
//     await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MemberProfile(
//             userFurnace: userFurnace,
//             userMember: member,
//             refresh: _refresh,
//             showDM: true,
//           ),
//         ));
//
//     if (mounted) setState(() {});
//   }
//
//   _createDirectMessageWithNoUserConfirmed(
//       ConfirmationParams confirmationParams) {
//     try {
//       FocusScope.of(context).requestFocus(FocusNode());
//
//       setState(() {
//         _showSpinner = true;
//       });
//
//       _circleBloc.createDirectMessageWithNewUser(globalState, _invitationBloc,
//           confirmationParams.user!.userFurnace!, confirmationParams.user!);
//     } catch (err) {
//       setState(() {
//         _showSpinner = false;
//       });
//     }
//   }
//
//   _createDirectMessageConfirmed(ConfirmationParams confirmationParams) {
//     try {
//       FocusScope.of(context).requestFocus(FocusNode());
//
//       setState(() {
//         _showSpinner = true;
//       });
//       _circleBloc.createDirectMessage(_invitationBloc,
//           confirmationParams.userFurnace, confirmationParams.member!);
//     } catch (err) {
//       setState(() {
//         _showSpinner = false;
//       });
//     }
//   }
//
//   _confirmCreateDirectMessage(ConfirmationParams confirmationParams,
//       String username, Function confirmed) {
//     DialogYesNo.askYesNo(
//         context,
//         AppLocalizations.of(context).createDMTitle,
//         '${AppLocalizations.of(context).createDMMessage} ($username)',
//         confirmed,
//         null,
//         false,
//         confirmationParams);
//   }
//
//   /*_searchForUser() {
//     // if (_formKey.currentState!.validate()) {
//     setState(() {
//       _showSpinner = true;
//     });
//
//     /*Member member =
//         Member.getMemberByUsername(_username.text, globalState.members);
//
//     if (member.memberID.isNotEmpty) {
//       UserFurnace memberFurnace = _findFurnaceByKey(member.furnaceKey);
//
//       if (memberFurnace.pk != null) {
//         _confirmCreateDirectMessage(
//             ConfirmationParams(userFurnace: memberFurnace, member: member),
//             member.username,
//             _createDirectMessageWithNoUserConfirmed);
//
//         return;
//       }
//     }
//
//      */
//
//     ///default to hitting the server
//     _invitationBloc.findUsersByUsername(_username.text, widget.userFurnaces);
//   }
//
//    */
//
//   /*UserFurnace _findFurnaceByKey(int key) {
//     return widget.userFurnaces.firstWhere((element) => element.pk == key,
//         orElse: () => UserFurnace());
//   }
//
//    */
//
//   _doNothing() {}
//
//   _refresh() {
//     setState(() {});
//   }
//
//   _sendMagicCode() {
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => NetworkInvite(
//             userFurnaces: widget.userFurnaces,
//           ),
//         ));
//   }
// }
//
// class ConfirmationParams {
//   final UserFurnace userFurnace;
//   final Member? member;
//   final User? user;
//
//   ConfirmationParams({required this.userFurnace, this.user, this.member});
// }
