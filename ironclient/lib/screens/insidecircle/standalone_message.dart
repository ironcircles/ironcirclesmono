// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
// import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
// import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
// import 'package:ironcirclesapp/screens/insidecircle/insidecircle_determine_widget.dart';
// import 'package:ironcirclesapp/screens/insidecircle/typeandsendmessage.dart';
// import 'package:ironcirclesapp/screens/widgets/dialogyesno.dart';
// import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//
// import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
//
// ///Purpose: This screen shows the user pinned posts for the specific Circle.
// ///User can select one, which will be returned to the calling screen
//
// ///This is a stateful class, meaning in can listen for events and refresh
// class StandaloneMessage extends StatefulWidget {
//   final UserCircleCache userCircleCache;
//   final UserFurnace userFurnace;
//   final Function postMessage;
//   final String title;
//
//   ///As much as possible going forward, don't allow nulls
//   const StandaloneMessage({
//     Key? key,
//     required this.userCircleCache,
//     required this.userFurnace,
//     required this.postMessage,
//     required this.title,
//   }) : super(key: key);
//
//   @override
//   _StandaloneMessageState createState() => _StandaloneMessageState();
// }
//
// ///The state class that does all the work
// class _StandaloneMessageState extends State<StandaloneMessage> {
//   List<CircleObject> _circleObjects = [];
//   final ItemScrollController _itemScrollController = ItemScrollController();
//   final ItemPositionsListener _itemPositionsListener =
//       ItemPositionsListener.create();
//
//   ///spinner
//   //bool _showSpinner = true;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double maxWidth =
//         InsideConstants.getCircleObjectSize(MediaQuery.of(context).size.width);
//
//     ///Structure of the screen. In this case, an appBar (with a back button) and a body section
//     return Scaffold(
//       appBar: ICAppBar(title: widget.title),
//       backgroundColor: globalState.theme.background,
//       body: Padding(
//           padding: const EdgeInsets.only(left: 10, right: 0, bottom: 5, top: 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: <Widget>[
//               const Spacer(),
//               TypeAndSendMessage(
//                 userCircleCache: widget.userCircleCache,
//                 userFurnace: widget.userFurnace,
//               )
//             ],
//           )),
//     );
//   }
// }
