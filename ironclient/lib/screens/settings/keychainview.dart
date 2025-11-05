// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/encryption/externalkeys.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
// import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
// import 'package:ndialog/ndialog.dart';
//
// class KeychainView extends StatefulWidget {
//   final UserFurnace userFurnace;
//   final User user;
//   const KeychainView({required this.userFurnace, required this.user});
//
//   @override
//   State<StatefulWidget> createState() {
//     return _KeychainViewState();
//   }
// }
//
// class _KeychainViewState extends State<KeychainView> {
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//   //KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();
//
//   //TextEditingController _passcodeController = TextEditingController();
//   ProgressDialog? progressDialog;
//   ProgressDialog? importingData;
//
//   String _numberOfKeys = '';
//
//   bool _showSpinner = true;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//   List<String> plainTextLines = [];
//
//   populateFile() async {
//     try {
//       List<UserFurnace>? userFurnaces =
//           await TableUserFurnace.readAllForUser(widget.userFurnace.userid!);
//
//       File plainText = await ExternalKeys.saveToFile(
//           widget.userFurnace.userid!,
//           widget.userFurnace.username!,
//           '',
//           true,
//           widget.userFurnace,
//           userFurnaces,
//           globalState.userSetting,
//           encrypted: false);
//
//       plainTextLines = plainText.readAsLinesSync();
//
//       setState(() {
//         _numberOfKeys = plainTextLines.length.toString();
//
//         _showSpinner = false;
//       });
//     } catch (err, trace) {
//       if (!err.toString().contains('backup is up to date'))
//         LogBloc.insertError(err, trace);
//       debugPrint("KeychainBackupService.backup $err");
//     }
//   }
//
//   @override
//   void initState() {
//     populateFile();
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: globalState.theme.background,
//         key: _scaffoldKey,
//         appBar: AppBar(
//           actions: const <Widget>[],
//           iconTheme: IconThemeData(
//             color: globalState.theme.menuIcons, //change your color here
//           ),
//           backgroundColor: globalState.theme.background,
//           title: Text('${AppLocalizations.of(context)!.rawKeychainData}: $_numberOfKeys',
//               style: ICTextStyle.getStyle(context: context,
//                   color: globalState.theme.textTitle,
//                   fontSize: ICTextStyle.appBarFontSize)),
//         ),
//         body: SafeArea(
//           left: false,
//           top: false,
//           right: false,
//           bottom: true,
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
//                 child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     //mainAxisSize: MainAxisSize.max,
//                     children: <Widget>[
//                       Expanded(
//                         child: plainTextLines.isNotEmpty
//                             ? ListView.separated(
//                                 separatorBuilder: (context, index) {
//                                   return Divider(
//                                     height: 10,
//                                     color: globalState.theme.background,
//                                   );
//                                 },
//                                 itemCount: plainTextLines.length,
//                                 itemBuilder: (BuildContext context, int index) {
//                                   var row = plainTextLines[index];
//
//                                   return Text('$index: $row');
//                                 })
//                             : Container(),
//                       )
//                     ]),
//               ),
//               _showSpinner ? Center(child: spinkit) : Container(),
//             ],
//           ),
//         ));
//   }
// }
