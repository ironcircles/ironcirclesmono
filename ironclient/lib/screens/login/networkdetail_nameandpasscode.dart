// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
// import 'package:ironcirclesapp/blocs/log_bloc.dart';
// import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
// import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class NetworkDetailNameAndPasscode extends StatefulWidget {
//   final UserFurnace userFurnace;
//
//   // FlutterManager({Key key, this.title}) : super(key: key);
//   const NetworkDetailNameAndPasscode({Key? key, required this.userFurnace})
//       : super(key: key);
//   // final String title;
//
//   @override
//   FurnaceDetailState createState() => FurnaceDetailState();
// }
//
// class FurnaceDetailState extends State<NetworkDetailNameAndPasscode> {
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//   final _formKey = GlobalKey<FormState>();
//   final userFurnaceBloc = UserFurnaceBloc();
//   late final GlobalEventBloc _globalEventBloc;
//   final List _members = [];
//   late HostedFurnaceBloc _hostedFurnaceBloc;
//
//   final TextEditingController _name = TextEditingController();
//   //TextEditingController _url = TextEditingController();
//   final TextEditingController _apikey = TextEditingController();
//
//   bool _forge = false;
//   bool _showAPIKey = true;
//   bool validatedOnceAlready = false;
//
//   bool _showSpinner = false;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//   final ScrollController _scrollController = ScrollController();
//   @override
//   void initState() {
//     _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
//     _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);
//
//     widget.userFurnace.hostedAccessCode == null
//         ? _name.text = widget.userFurnace.alias!
//         : _name.text = widget.userFurnace.hostedName!;
//
//     _apikey.text = widget.userFurnace.hostedAccessCode == null
//         ? widget.userFurnace.apikey!
//         : widget.userFurnace.hostedAccessCode!;
//
//     _forge = widget.userFurnace.alias == "IronForge";
//
//     _hostedFurnaceBloc.nameAndAccessCodeChanged.listen((result) {
//       if (mounted) {
//         //setState(() {
//         _showSpinner = false;
//         widget.userFurnace.hostedName = _name.text;
//         widget.userFurnace.hostedAccessCode = _apikey.text;
//
//         if (widget.userFurnace.authServer!) {
//           globalState.userFurnace!.hostedName = _name.text;
//           globalState.userFurnace!.hostedAccessCode = _apikey.text;
//         }
//         // });
//
//         Navigator.pop(context, widget.userFurnace);
//
//         FormattedSnackBar.showSnackbarWithContext(context, 'updated', "", 2, false);
//       }
//     }, onError: (err) {
//       FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
//       debugPrint("error $err");
//       setState(() {
//         _showSpinner = false;
//       });
//     }, cancelOnError: false);
//
//     super.initState();
//
//     if (_forge) _apikey.text = 'IronForge';
//   }
//
//   @override
//   void dispose() {
//     userFurnaceBloc.dispose();
//
//     _name.dispose();
//     _apikey.dispose();
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final makeBody = Container(
//       // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
//         padding: const EdgeInsets.only(left: 8, right: 10, top: 10, bottom: 10),
//         child: SingleChildScrollView(
//           keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//           child: ConstrainedBox(
//               constraints: const BoxConstraints(),
//               child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: <Widget>[
//                     Padding(
//                         padding:
//                         const EdgeInsets.only(top: 4, bottom: 0, left: 0),
//                         child: Row(children: [
//                           Expanded(
//                               child: FormattedText(
//                                 labelText: 'network name',
//                                 readOnly: false,
//                                 controller: _name,
//                                 onChanged: _revalidate,
//                                 validator: (value) {
//                                   if (value.toString().endsWith(' ')) {
//                                     return 'cannot end with a space';
//                                   } else if (value.toString().length < 3) {
//                                     return 'must be at least 3 chars';
//                                   } else if (value.toString().startsWith(' ')) {
//                                     return 'cannot start with a space';
//                                   }
//
//                                   return null;
//                                 },
//                               ))
//                         ])),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4, bottom: 4),
//                       child: Row(children: <Widget>[
//                         Expanded(
//                           child: FormattedText(
//                             labelText: 'access code',
//                             maxLength: 25,
//                             obscureText: !_showAPIKey,
//                             readOnly: (widget.userFurnace.role == Role.OWNER ||
//                                 widget.userFurnace.role == Role.ADMIN)
//                                 ? false
//                                 : true,
//                             controller: _apikey,
//                             onChanged: _revalidate,
//                             validator: (value) {
//                               if (value.toString().endsWith(' ')) {
//                                 return AppLocalizations.of(context)!.errorCannotEndWithASpace;
//                               } else if (value.toString().length < 6) {
//                                 return AppLocalizations.of(context)!.mustBeAtLeast6Chars;
//                               } else if (value.toString().startsWith(' ')) {
//                                 return AppLocalizations.of(context)!.errorCannotStartWithASpace;
//                               }
//
//                               return null;
//                             },
//                           ),
//                         ),
//                         Padding(
//                             padding: const EdgeInsets.only(top: 15),
//                             child: _showAPIKey
//                                 ? IconButton(
//                                 icon: Icon(Icons.visibility,
//                                     color: globalState.theme.buttonIcon),
//                                 onPressed: () {
//                                   setState(() {
//                                     _showAPIKey = false;
//                                   });
//                                 })
//                                 : IconButton(
//                                 icon: Icon(Icons.visibility,
//                                     color:
//                                     globalState.theme.buttonDisabled),
//                                 onPressed: () {
//                                   setState(() {
//                                     _showAPIKey = true;
//                                   });
//                                 })),
//                       ]),
//                     ),
//                   ])),
//         ));
//
//     final makeBottom = Container(
//       height: 55.0,
//       child: Padding(
//         padding: const EdgeInsets.only(top: 0, bottom: 0),
//         child: Row(children: <Widget>[
//           Expanded(
//             child: GradientButton(
//                 text: 'UPDATE',
//                 onPressed: () {
//                   _update();
//                 }),
//           )
//         ]),
//       ),
//     );
//
//     return Form(
//         key: _formKey,
//         child: Scaffold(
//             key: _scaffoldKey,
//             backgroundColor: globalState.theme.background,
//             appBar: const ICAppBar(title: 'Change name or passcode'),
//             body: SafeArea(
//               left: false,
//               top: false,
//               right: false,
//               bottom: true,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: <Widget>[
//                   Expanded(child: makeBody),
//                   Container(
//                     //  color: Colors.white,
//                     padding: const EdgeInsets.all(0.0),
//                     child: makeBottom,
//                   ),
//                 ],
//               ),
//             )));
//   }
//
//   void _update() {
//     try {
//       if (_formKey.currentState!.validate()) {
//         setState(() {
//           _showSpinner = true;
//
//           _hostedFurnaceBloc.changeNameAndAccessCode(
//               widget.userFurnace, _name.text, _apikey.text);
//         });
//       } else {
//         validatedOnceAlready = true;
//       }
//     } catch (err, trace) {
//       LogBloc.insertError(err, trace);
//       debugPrint('MembersInvitations._getMagicLink: $err');
//
//       setState(() {
//         _showSpinner = false;
//       });
//     }
//   }
//
//   void _revalidate(String value) {
//     if (validatedOnceAlready) {
//       _formKey.currentState!.validate();
//     }
//   }
// }