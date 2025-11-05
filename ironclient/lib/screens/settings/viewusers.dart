// import 'package:flutter/material.dart';
// import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/circles/home.dart';
// import 'package:ironcirclesapp/screens/widgets/furnace_user.dart';
// import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
//
// class ViewUsers extends StatefulWidget {
//   @override
//   ViewUsersState createState() => ViewUsersState();
// }
//
// class ViewUsersState extends State<ViewUsers> {
//   UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
//   List<UserFurnace>? _userFurnaces = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     //Listen for deleted results arrive
//     _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
//       if (mounted) {
//         setState(() {
//           _userFurnaces = userFurnaces;
//         });
//       }
//     }, onError: (err) {
//       debugPrint("ViewUsers.initState: $err");
//     }, cancelOnError: false);
//
//     _userFurnaceBloc.requestAll();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text('Users on this device', style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
//           actions: <Widget>[
//             IconButton(
//               icon: const Icon(Icons.home),
//               onPressed: () {
//                 Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (context) => Home()),
//                     (Route<dynamic> route) => false);
//               },
//             )
//           ],
//         ),
//         //drawer: NavigationDrawer(),
//         body: SingleChildScrollView(
//             keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//             child: Container(
//           // height: 600,
//           // width: 300,
//           margin: const EdgeInsets.all(15),
//           //decoration: BoxDecoration(border: Border.all(color: Colors.teal)),
//           //color: Colors.white,
//           padding: const EdgeInsets.only(left: 0, right: 0),
//           child: ListView.builder(
//               scrollDirection: Axis.vertical,
//               //controller: _scrollController,
//               shrinkWrap: true,
//               itemCount: _userFurnaces!.length,
//               itemBuilder: (BuildContext context, int index) {
//                 UserFurnace currentRow = _userFurnaces![index];
//                 return FurnaceUser(
//                   userFurnace: currentRow,
//                 );
//
//                 //return Text(currentRow.doThis);
//               }),
//         )));
//   }
// }
