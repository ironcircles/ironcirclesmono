// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:ironcirclesapp/blocs/imagineai_bloc.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
// import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class DialogImagineAIConfiguration {
//   static final scaffoldKey = GlobalKey<ScaffoldState>();
//
//   static showConfigure(BuildContext context, ImagineAIParams params,
//       Function callback) async {
//     ImagineAIParams newParams = params;
//
//     await showDialog<String>(
//       context: context,
//       builder: (BuildContext context) => _SystemPadding(
//         child: AlertDialog(
//           backgroundColor: globalState.theme.dialogTransparentBackground,
//           shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(30.0))),
//           title: const Text('Configure Image Generation'),
//           contentPadding: const EdgeInsets.all(12.0),
//           content:
//               ImagineAIConfiguration(scaffoldKey, newParams, _ok, callback),
//         ),
//       ),
//     );
//   }
//
//   static _ok(BuildContext context) {
//     Navigator.pop(context);
//   }
// }
//
// class _SystemPadding extends StatelessWidget {
//   final Widget? child;
//
//   const _SystemPadding({Key? key, this.child}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//         //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
//         duration: const Duration(milliseconds: 300),
//         child: child);
//   }
// }
//
// class ImagineAIConfiguration extends StatefulWidget {
//   final Key scaffoldKey;
//   final ImagineAIParams params;
//   final Function ok;
//   final Function callback;
//
//   const ImagineAIConfiguration(
//     this.scaffoldKey,
//     this.params,
//     this.ok,
//     this.callback,
//   );
//
//   @override
//   _ImagineAIConfigurationState createState() => _ImagineAIConfigurationState();
// }
//
// class _ImagineAIConfigurationState extends State<ImagineAIConfiguration> {
//   ImagineAIParams _params = ImagineAIParams();
//   final TextEditingController _promptController = TextEditingController();
//   final TextEditingController _negativePromptController =
//       TextEditingController();
//   final TextEditingController _seedController = TextEditingController();
//   double _currentSliderValue = 7.5;
//   //double _endSliderValue = 7.5;
//   final ScrollController _scrollController = ScrollController();
//   double _currentStepsSliderValue = 30;
//   //double _endStepsSliderValue = 30;
//   late ListItem? _selectedStyle;
//   late ListItem? _selectedAspectRatio;
//
//   @override
//   void initState() {
//
//     _initScreenWidgets();
//
//     super.initState();
//   }
//
//   _initScreenWidgets(){
//
//     _params.deepCopy(widget.params);
//
//     _selectedStyle =
//         styles.singleWhere((element) => element.object == _params.style);
//     _selectedAspectRatio = aspectRatio
//         .singleWhere((element) => element.object == _params.aspectRatio);
//     _currentSliderValue = _params.cfg;
//     _currentStepsSliderValue = _params.steps.toDouble();
//     _promptController.text = _params.prompt;
//     _negativePromptController.text = _params.negativePrompt;
//     _seedController.text = _params.seed.toString();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = globalState.setScale(MediaQuery.of(context).size.width);
//
//     return SizedBox(
//         width: (width >= 350 ? 350 : width),
//         height: 400, //widget.firstTime ? 340  : 340,
//         child: Scaffold(
//             backgroundColor: globalState.theme.dialogTransparentBackground,
//             body: Stack(children: [
//               Column(crossAxisAlignment: CrossAxisAlignment.end, children: <
//                   Widget>[
//                 Expanded(
//                     child: Scrollbar(
//                         controller: _scrollController,
//                         //thumbVisibility: true,
//                         child: SingleChildScrollView(
//                             keyboardDismissBehavior:
//                                 ScrollViewKeyboardDismissBehavior.onDrag,
//                             controller: _scrollController,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Column(children: [
//                                   const Padding(
//                                       padding: EdgeInsets.only(top: 10)),
//                                   ConstrainedBox(
//                                       constraints:
//                                           const BoxConstraints(maxHeight: 125),
//                                       child: Padding(
//                                           padding: const EdgeInsets.only(
//                                             left: 20,
//                                             right: 20,
//                                           ),
//                                           child: ExpandingLineText(
//                                               onChanged: (value) {
//                                                 _params.prompt = value;
//                                               },
//                                               maxLines: 3,
//                                               maxLength: 250,
//                                               controller: _promptController,
//                                               labelText:
//                                                   "enter your prompt (required)"))),
//                                   ConstrainedBox(
//                                       constraints:
//                                           const BoxConstraints(maxHeight: 125),
//                                       child: Padding(
//                                           padding: const EdgeInsets.only(
//                                             left: 20,
//                                             right: 20,
//                                           ),
//                                           child: ExpandingLineText(
//                                               onChanged: (value) {
//                                                 _params.negativePrompt = value;
//                                               },
//                                               maxLines: 3,
//                                               maxLength: 250,
//                                               controller:
//                                                   _negativePromptController,
//                                               labelText:
//                                                   "negative prompt (optional)"))),
//                                   Row(children: <Widget>[
//                                     Expanded(
//                                         flex: 1,
//                                         child: Padding(
//                                             padding: const EdgeInsets.only(
//                                                 left: 20, right: 20, bottom: 0),
//                                             child: FormattedDropdownObject(
//                                               hintText: 'style',
//                                               selected: _selectedStyle,
//                                               list: styles,
//                                               // selected: _selectedOne,
//                                               underline: globalState
//                                                   .theme.bottomHighlightIcon,
//                                               onChanged: (ListItem? value) {
//                                                 setState(() {
//                                                   _selectedStyle = value;
//                                                   _params.style = value!.object;
//                                                 });
//                                               },
//                                             ))),
//                                   ]),
//                                   const Padding(
//                                       padding: EdgeInsets.only(
//                                     top: 10,
//                                   )),
//                                   Row(children: <Widget>[
//                                     Expanded(
//                                         flex: 1,
//                                         child: Padding(
//                                             padding: const EdgeInsets.only(
//                                                 left: 20, right: 20, bottom: 0),
//                                             child: FormattedDropdownObject(
//                                               hintText: 'aspect ratio',
//                                               selected: _selectedAspectRatio,
//                                               list: aspectRatio,
//                                               // selected: _selectedOne,
//                                               underline: globalState
//                                                   .theme.bottomHighlightIcon,
//                                               onChanged: (ListItem? value) {
//                                                 setState(() {
//                                                   _selectedAspectRatio = value;
//                                                   _params.aspectRatio =
//                                                       value!.object;
//                                                 });
//                                               },
//                                             ))),
//                                   ]),
//                                   const SizedBox(height: 15),
//                                   Padding(
//                                       padding: const EdgeInsets.only(left: 20),
//                                       child: ICText(
//                                           'Creative control slider: ${_params.cfg.toStringAsFixed(2)}')),
//                                   Slider(
//                                     activeColor: globalState.theme.button,
//                                     value: _currentSliderValue,
//                                     max: 15,
//                                     min: 3,
//                                     divisions: 50,
//                                     label:
//                                         _currentSliderValue.toStringAsFixed(2),
//                                     onChanged: (double value) {
//                                       setState(() {
//                                         _currentSliderValue = value;
//                                       });
//                                     },
//                                     onChangeEnd: (double value) {
//                                       setState(() {
//                                         _params.cfg = value;
//                                       });
//                                     },
//                                   ),
//                                   const SizedBox(height: 15),
//                                   Padding(
//                                       padding: const EdgeInsets.only(left: 20),
//                                       child: ICText(
//                                           'Iterations slider: ${_params.steps.round().toString()}')),
//                                   Slider(
//                                     activeColor: globalState.theme.button,
//                                     value: _currentStepsSliderValue,
//                                     max: 50,
//                                     min: 30,
//                                     divisions: 20,
//                                     label: _currentStepsSliderValue
//                                         .round()
//                                         .toString(),
//                                     onChanged: (double value) {
//                                       setState(() {
//                                         _currentStepsSliderValue = value;
//                                       });
//                                     },
//                                     onChangeEnd: (double value) {
//                                       setState(() {
//                                         _params.steps = value.round();
//                                       });
//                                     },
//                                   ),
//                                   const SizedBox(height: 15),
//                                   Padding(
//                                       padding: const EdgeInsets.only(
//                                         left: 20,
//                                         right: 20,
//                                       ),
//                                       child: ExpandingLineText(
//                                           onChanged: (value) {
//                                             _params.seed = int.parse(value);
//                                           },
//                                           numbersOnly: true,
//                                           maxLength: 10,
//                                           controller: _seedController,
//                                           labelText: "seed (optional)")),
//                                   const SizedBox(height: 20),
//                                 ]),
//
//                                 /* Row(children: [
//                               Expanded(
//                                   child: Container(
//                                       height: 400,
//                                       //width: 400,
//                                       decoration: BoxDecoration(
//                                           image: DecorationImage(
//                                               fit: BoxFit.fitHeight,
//                                               image: AssetImage(
//                                                   'assets/images/avatar.jpg')))))
//                             ]),*/
//
//                                 /*SizedBox(
//                     height: 48,
//                     width: double.maxFinite,
//                     child: ElevatedButton.icon(
//                         style: ButtonStyle(
//                             backgroundColor:
//                                 MaterialStateProperty.all( globalState.theme.button,)),
//                         onPressed: () {
//                           if (controller.text.isNotEmpty) {}
//                         },
//                         icon: const Icon(Icons.generating_tokens),
//                         label: const Text("Generate")),
//                   )*/
//                               ],
//                             )))),
//                 Row(children: [
//                   const Spacer(),
//                   TextButton(
//                       child: Text('RESET',
//                           textScaleFactor: globalState.labelScaleFactor,
//                           style: TextStyle(
//                               color: globalState.theme.buttonCancel,
//                               fontSize: 14 - globalState.scaleDownButtonFont)),
//                       onPressed: () {
//                         setState(() {
//                           _params = ImagineAIParams();
//                           _initScreenWidgets();
//                         });
//                         //newParams = params;
//                       }),
//                   TextButton(
//                       child: Text('OK',
//                           textScaleFactor: globalState.labelScaleFactor,
//                           style: TextStyle(
//                               color: globalState.theme.button,
//                               fontSize: 14 - globalState.scaleDownButtonFont)),
//                       onPressed: () {
//                         widget.callback(_params);
//                         widget.ok(context);
//                       })
//                 ]),
//               ]),
//             ])));
//   }
// }
