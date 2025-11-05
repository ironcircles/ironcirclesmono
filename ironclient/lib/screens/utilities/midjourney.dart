// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'dart:typed_data';
// import 'package:ironcirclesapp/blocs/imagineai_bloc.dart';
// import 'package:ironcirclesapp/models/dropdownpair.dart';
// import 'package:ironcirclesapp/models/globalstate.dart';
// import 'package:ironcirclesapp/screens/widgets/expandinglinetext.dart';
// import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
// import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
// import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
// import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
// import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
// import 'package:ironcirclesapp/screens/widgets/ictext.dart';
//
// class MidjourneyPromptScreen extends StatefulWidget {
//   const MidjourneyPromptScreen({Key? key}) : super(key: key);
//
//   @override
//   State<MidjourneyPromptScreen> createState() => _MidjourneyPromptScreenState();
// }
//
// class _MidjourneyPromptScreenState extends State<MidjourneyPromptScreen> {
//   final TextEditingController _promptController = TextEditingController();
//   final TextEditingController _negativePromptController =
//       TextEditingController();
//   final TextEditingController _seedController = TextEditingController();
//   final ImagineAIBloc _imageAIBloc = ImagineAIBloc();
//
//   int _seed = 0;
//
//   double _currentSliderValue = 7.5;
//   double _endSliderValue = 7.5;
//   final ScrollController _scrollController = ScrollController();
//   double _currentStepsSliderValue = 30;
//   double _endStepsSliderValue = 30;
//   Uint8List? _results;
//
//   bool _showSpinner = false;
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 60,
//   );
//
//   late ListItem? _selectedStyle;
//   late ListItem? _selectedAspectRatio;
//   bool _expanded = false;
//
//   @override
//   void initState() {
//     _selectedStyle = styles[10];
//     _selectedAspectRatio = aspectRatio[0];
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: const ICAppBar(title: ("Generate Image")),
//         body: Stack(children: [
//           Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
//             Expanded(
//                 child: Scrollbar(
//                     controller: _scrollController,
//                     //thumbVisibility: true,
//                     child: SingleChildScrollView(
//                         keyboardDismissBehavior:
//                             ScrollViewKeyboardDismissBehavior.onDrag,
//                         controller: _scrollController,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(children: [
//                               const Spacer(),
//                               ICText(_expanded
//                                   ? 'collapse options  '
//                                   : 'expand options  '),
//                               IconButton(
//                                   onPressed: () {
//                                     setState(() {
//                                       _expanded = !_expanded;
//                                     });
//                                   },
//                                   icon: _expanded
//                                       ? const Icon(Icons.expand_less)
//                                       : const Icon(Icons.expand_more))
//                             ]),
//                             _expanded == false
//                                 ? Container()
//                                 : Column(children: [
//                                     Row(children: <Widget>[
//                                       Expanded(
//                                           flex: 1,
//                                           child: Padding(
//                                               padding: const EdgeInsets.only(
//                                                   left: 20,
//                                                   right: 20,
//                                                   bottom: 0),
//                                               child: FormattedDropdownObject(
//                                                 hintText: 'style',
//                                                 selected: _selectedStyle,
//                                                 list: styles,
//                                                 // selected: _selectedOne,
//                                                 underline: globalState
//                                                     .theme.bottomHighlightIcon,
//                                                 onChanged: (ListItem? value) {
//                                                   setState(() {
//                                                     _selectedStyle = value;
//                                                   });
//                                                 },
//                                               ))),
//                                     ]),
//                                     const Padding(
//                                         padding: EdgeInsets.only(
//                                       top: 10,
//                                     )),
//                                     Row(children: <Widget>[
//                                       Expanded(
//                                           flex: 1,
//                                           child: Padding(
//                                               padding: const EdgeInsets.only(
//                                                   left: 20,
//                                                   right: 20,
//                                                   bottom: 0),
//                                               child: FormattedDropdownObject(
//                                                 hintText: 'aspect ratio',
//                                                 selected: _selectedAspectRatio,
//                                                 list: aspectRatio,
//                                                 // selected: _selectedOne,
//                                                 underline: globalState
//                                                     .theme.bottomHighlightIcon,
//                                                 onChanged: (ListItem? value) {
//                                                   setState(() {
//                                                     _selectedAspectRatio =
//                                                         value;
//                                                   });
//                                                 },
//                                               ))),
//                                     ]),
//                                     const SizedBox(height: 15),
//                                     Padding(
//                                         padding:
//                                             const EdgeInsets.only(left: 20),
//                                         child: ICText(
//                                             'Creative control slider: ${_endSliderValue.toStringAsFixed(2)}')),
//                                     Slider(
//                                       activeColor: globalState.theme.button,
//                                       value: _currentSliderValue,
//                                       max: 15,
//                                       min: 3,
//                                       divisions: 50,
//                                       label: _currentSliderValue
//                                           .toStringAsFixed(2),
//                                       onChanged: (double value) {
//                                         setState(() {
//                                           _currentSliderValue = value;
//                                         });
//                                       },
//                                       onChangeEnd: (double value) {
//                                         setState(() {
//                                           _endSliderValue = value;
//                                         });
//                                       },
//                                     ),
//                                     const SizedBox(height: 15),
//                                     Padding(
//                                         padding:
//                                             const EdgeInsets.only(left: 20),
//                                         child: ICText(
//                                             'Iterations slider: ${_endStepsSliderValue.round().toString()}')),
//                                     Slider(
//                                       activeColor: globalState.theme.button,
//                                       value: _currentStepsSliderValue,
//                                       max: 50,
//                                       min: 30,
//                                       divisions: 20,
//                                       label: _currentStepsSliderValue
//                                           .round()
//                                           .toString(),
//                                       onChanged: (double value) {
//                                         setState(() {
//                                           _currentStepsSliderValue = value;
//                                         });
//                                       },
//                                       onChangeEnd: (double value) {
//                                         setState(() {
//                                           _endStepsSliderValue = value;
//                                         });
//                                       },
//                                     ),
//                                     const SizedBox(height: 15),
//                                     Padding(
//                                         padding: const EdgeInsets.only(
//                                           left: 20,
//                                           right: 20,
//                                         ),
//                                         child: ExpandingLineText(
//                                             numbersOnly: true,
//                                             maxLength: 10,
//                                             controller: _seedController,
//                                             labelText: "seed (optional)")),
//                                     const SizedBox(height: 20),
//                                     ConstrainedBox(
//                                         constraints: const BoxConstraints(
//                                             maxHeight: 125),
//                                         child: Padding(
//                                             padding: const EdgeInsets.only(
//                                               left: 20,
//                                               right: 20,
//                                             ),
//                                             child: ExpandingLineText(
//                                                 maxLines: 3,
//                                                 maxLength: 250,
//                                                 controller:
//                                                     _negativePromptController,
//                                                 labelText:
//                                                     "negative prompt (optional)"))),
//                                   ]),
//                             const SizedBox(height: 20),
//                             ConstrainedBox(
//                                 constraints:
//                                     const BoxConstraints(maxHeight: 125),
//                                 child: Padding(
//                                     padding: const EdgeInsets.only(
//                                       left: 20,
//                                       right: 20,
//                                     ),
//                                     child: ExpandingLineText(
//                                         maxLines: 3,
//                                         maxLength: 250,
//                                         controller: _promptController,
//                                         labelText:
//                                             "enter your prompt (required)"))),
//                             _results != null
//                                 ? const SizedBox(height: 20)
//                                 : Container(),
//                             _results != null
//                                 ? Row(children: [
//                                     Expanded(
//                                         child: Container(
//                                             height: 400,
//                                             //width: 400,
//                                             decoration: BoxDecoration(
//                                                 image: DecorationImage(
//                                                     fit: BoxFit.cover,
//                                                     image: MemoryImage(
//                                                         _results!)))))
//                                   ])
//                                 : Container(),
//                             /* Row(children: [
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
//                             const SizedBox(height: 10),
//                             _results != null
//                                 ? Row(children: [
//                                     const Spacer(),
//                                     GradientButtonDynamic(
//                                         text: 'Post image', onPressed: () {})
//                                   ])
//                                 : Container(),
//                             const SizedBox(height: 10),
//                             GradientButton(
//                                 text: _results == null
//                                     ? 'Generate'
//                                     : 'Regenerate',
//                                 onPressed: _generate),
//                             /*SizedBox(
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
//                           ],
//                         ))))
//           ]),
//           _showSpinner ? spinkit : Container()
//         ]));
//   }
//
//   _generate() async {
//
//     _closeKeyboard();
//
//     setState(() {
//       _showSpinner = true;
//     });
//
//     int seedControllerInt =
//         int.parse(_seedController.text.isEmpty ? "1" : _seedController.text);
//
//     if (_seed == seedControllerInt) {
//       _seed = _seed + 1;
//       seedControllerInt = _seed;
//     } else {
//       _seed = seedControllerInt;
//     }
//
//     _seedController.text = seedControllerInt.toString();
//
//     debugPrint("seed: $seedControllerInt");
//
//     ImagineAIParams params = ImagineAIParams(
//         prompt: _promptController.text,
//         negativePrompt: _negativePromptController.text,
//         seed: seedControllerInt,
//         steps: _endStepsSliderValue.round(),
//         cfg: _endSliderValue,
//         aspectRatio: _selectedAspectRatio!.object,
//         style: _selectedStyle!.object);
//
//    _results = await _imageAIBloc.generateImage(params);
//
//     setState(() {
//       _showSpinner = false;
//     });
//   }
//
//   _closeKeyboard() {
//     FocusScope.of(context).requestFocus(FocusNode());
//   }
// }
