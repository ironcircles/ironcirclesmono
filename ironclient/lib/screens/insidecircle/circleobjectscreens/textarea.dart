// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
// import 'package:ironcirclesapp/services/tenor_service.dart';
//
// class TextArea extends StatefulWidget {
//   //final List<UserFurnace> userFurnaces;
//   //final List<CircleObject> circleObjects;
//
//   const TextArea({
//     //this.circleObjects,
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   TextAreaState createState() => TextAreaState();
// }
//
// class TextAreaState extends State<TextArea> {
//
//   quill.QuillController _quillController = quill.QuillController.basic();
//
//   final ScrollController _scrollController = ScrollController();
//   //ScrollController _scrollController = ScrollController();
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   bool filter = false;
//   //var _tapPosition;
//   final double _iconSize = 45;
//
//   @override
//   void initState() {
//     //Listen for membership load
//
//     super.initState();
//   }
//
//   _return(GiphyOption preview) {
//     Navigator.of(context).pop(preview);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   final spinner = SpinKitThreeBounce(
//     size: 20,
//     color: globalState.theme.threeBounce,
//   );
//
//   @override
//   Widget build(BuildContext context) {
//
//     final topAppBar = AppBar(
//       elevation: 0,
//       toolbarHeight: 45,
//       centerTitle: false,
//       titleSpacing: 0.0,
//       iconTheme: IconThemeData(
//         color: globalState.theme.menuIcons, //change your color here
//       ),
//       backgroundColor: globalState.theme.appBar,
//       title: Text("Expanded Text Area", textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
//           style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
//       actions: const <Widget>[
//       ],
//     );
//
//     return Scaffold(
//       backgroundColor: globalState.theme.background,
//       key: _scaffoldKey,
//       appBar: topAppBar,
//       //drawer: NavigationDrawer(),
//       body: const SafeArea(
//           left: false,
//           top: false,
//           right: false,
//           bottom: true,
//           child: Padding(
//               padding: EdgeInsets.only(left: 25, right: 10, bottom: 5),
//               child: Column(
//                 children: [
//                   // quill.QuillToolbar.simple(configurations: quill.QuillSimpleToolbarConfigurations),
//                   // quill.QuillToolbar.basic(controller: _quillController),
//                   // Expanded(
//                   //   child: Container(
//                   //     child: quill.QuillEditor.basic(
//                   //       controller: _quillController,
//                   //       readOnly: false, // true for view only mode
//                   //     ),
//                   //   ),
//                   // )
//                 ],
//               )))
//
//     );
//   }
// }
