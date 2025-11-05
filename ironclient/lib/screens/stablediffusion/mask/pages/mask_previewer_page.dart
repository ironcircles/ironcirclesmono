import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/enum/tool_type.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/gesture_recognizers/pan_gesture_recognizer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/image_writer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/mask_generator.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/pages/mask_page_menu.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/widgets/image_viewer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/widgets/mask_viewer.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/widgets/selection_overlay.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/widgets/tool_button.dart';

class MaskPreviewerStackPage extends StatefulWidget {
  ImageDetails imageDetails;
  StableDiffusionPrompt prompt;
  MaskPreviewerStackPage(
    this.imageDetails,
    this.prompt,
  );

  @override
  _MaskPreviewerStackPageState createState() => _MaskPreviewerStackPageState();
}

class _MaskPreviewerStackPageState extends State<MaskPreviewerStackPage> {
  List<SelectionWithTool> screenPointsWithTool = [
    const SelectionWithTool([], ToolType.circle_brush)
  ]; // Stores the positions where the user taps/swipes
  //ImageDetails imageDetails = TestImageDetailsGenerator.dog800x763;

  Image? maskImage;
  Uint8List? maskImageBytes;

  //UI settings
  bool _showOriginal = true;
  bool _showSelection = true;
  bool _showMask = false;

  bool loadIn = true;

  ToolType selectedTool = ToolType.rect_area;

  double screenBrushRadius = 10.0;

  bool menuOpened = true;

  @override
  initState() {
    screenPointsWithTool.last =
        SelectionWithTool([], selectedTool, toolRadius: screenBrushRadius);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    generateMask(context);
  }

  resetSelection() {
    setState(() {
      screenPointsWithTool = [
        SelectionWithTool([], ToolType.rect_area, toolRadius: screenBrushRadius)
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    double W = MediaQuery.of(context).size.width;
    double H =
        MediaQuery.of(context).size.height - ScreenSizes.maskPreviewToolbar;
    Offset imageScreenDimensions =
        MaskGenerator.calculateContainedImageDimensions(
            W,
            H,
            widget.imageDetails.width.toDouble(),
            widget.imageDetails.height.toDouble());
    double screenToImageRatio = MaskGenerator.getScreenToImageRatioFromContext(
        widget.imageDetails, context);

    if (loadIn == true) {
      if (widget.prompt.screenPoints != null) {
        screenPointsWithTool = widget.prompt.screenPoints!;
        generateMask(context);
      }
      loadIn = false;
    }

    // final topAppBar = AppBar(
    //   elevation: 0,
    //   toolbarHeight: 45,
    //   centerTitle: false,
    //   titleSpacing: 0.0,
    //   iconTheme: IconThemeData(
    //     color: globalState.theme.menuIcons,
    //   ),
    //   backgroundColor: Colors.transparent,
    //
    //   leading: IconButton(
    //       icon: const Icon(Icons.arrow_back),
    //       onPressed: () {
    //         Navigator.pop(context);
    //       }),
    //   // actions: <Widget>[
    //   //   menuOpened == true
    //   //     ? IconButton(
    //   //     icon: Icon(
    //   //       Icons.expand_more,
    //   //       color: globalState.theme.button,
    //   //     ),
    //   //       onPressed: () {
    //   //         setState(() {
    //   //           menuOpened = false;
    //   //         });
    //   //       }
    //   //   )
    //   //       : IconButton(
    //   //       icon: Icon(
    //   //           Icons.expand_less,
    //   //           color: globalState.theme.button,
    //   //       ),
    //   //       onPressed: () {
    //   //         setState(() {
    //   //           menuOpened = true;
    //   //         });
    //   //       }
    //   //   )
    //   // ]
    // );

    return SafeArea(
        top: false,
        bottom: true,
        child: Stack(alignment: Alignment.topLeft, children: [
          Center(
            child: SizedBox(
              //color: Colors.pink,
              width: W,
              height: H,
              child: Stack(children: <Widget>[
                ///gradient background
                Positioned(
                  top: 0,
                  left: 0,
                  width: W,
                  height: H,
                  child: Container(
                    decoration: BoxDecoration(
                      color: globalState.theme.background,
                      // border: Border.all(
                      //     width: 1, color: globalState.theme.inactiveThumbColor)
                    ),
                  ),
                ),

                ///image and mask viewer
                Padding(
                    padding:
                        EdgeInsets.only(bottom: ScreenSizes.maskPreviewToolbar),
                    child: Center(
                        child: Stack(children: <Widget>[
                      Positioned(
                        top: MaskGenerator.isLimitedByWidth(
                                W,
                                H,
                                widget.imageDetails.width.toDouble(),
                                widget.imageDetails.height.toDouble())
                            ? (H - imageScreenDimensions.dy) / 2
                            : 0, //W>H?0: (l-L)/2,
                        left: MaskGenerator.isLimitedByWidth(
                                W,
                                H,
                                widget.imageDetails.width.toDouble(),
                                widget.imageDetails.height.toDouble())
                            ? 0
                            : (W - imageScreenDimensions.dx) /
                                2, //H>W?0:(l-L)/2,
                        width: imageScreenDimensions.dx,
                        height: imageScreenDimensions.dy,
                        child: Container(
                          width: imageScreenDimensions
                              .dx, // imageDetails.getWidthInSquareContainer(L).dx,
                          height: imageScreenDimensions
                              .dy, //imageDetails.getWidthInSquareContainer(L).dy,
                          color: Colors.red,
                          child: RawGestureDetector(
                            gestures: {
                              ImmediatePanGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                      ImmediatePanGestureRecognizer>(
                                () => ImmediatePanGestureRecognizer(),
                                (ImmediatePanGestureRecognizer instance) {
                                  instance
                                    ..onStart = (details) {
                                      // Do not return anything here, it's a void callback
                                    }
                                    ..onUpdate = (details) {
                                      //register swipe move
                                      setState(() {
                                        final widgetPosition =
                                            details.localPosition;
                                        screenPointsWithTool.last.screenPoints
                                            .add(widgetPosition);
                                      });
                                    }
                                    ..onEnd = (details) {
                                      storeLastStroke();
                                      //generate and store new mask on swipe end
                                      generateMask(context);
                                      // Do not return anything here, it's a void callback
                                    };
                                },
                              )
                            },
                            child: Center(
                                child: Stack(children: [
                              if (_showOriginal)
                                ImageViewer(imageDetails: widget.imageDetails),
                              if (_showSelection)
                                ImageSelectionOverlay(screenPointsWithTool,
                                    screenToImageRatio, screenBrushRadius),
                              if (_showMask)
                                IgnorePointer(
                                    child: Opacity(
                                        opacity: 1.0,
                                        child: MaskPreviewer(
                                            imageDetails: widget.imageDetails,
                                            imageBytes: maskImageBytes)))
                            ])),
                          ),
                        ),
                      ),
                    ]))),

                // ///appbar
                // Positioned(
                //   top: 0,
                //   left: 0,
                //   width: W,
                //   height: 100,
                //   child: const ICAppBar(title: 'Select area to change',),
                // ),
                //

                ///menu
                Positioned(
                    bottom: 50,
                    left: 0,
                    width: W,
                    height: ScreenSizes.maskPreviewToolbar,
                    child: Row(children: [
                      TextButton(
                        onPressed: () {
                          if (screenPointsWithTool.length == 1) return;

                          setState(() {
                            screenPointsWithTool
                                .removeAt(screenPointsWithTool.length - 1);
                            screenPointsWithTool.last = SelectionWithTool(
                                [], selectedTool,
                                toolRadius: screenBrushRadius);
                          });
                          generateMask(context);
                        },
                        child: Text(
                          "Undo",
                          style: TextStyle(color: globalState.theme.button),
                        ),
                      ),
                      TextButton(
                        onPressed:() {
                                setState(() {
                                  screenPointsWithTool = [
                                    SelectionWithTool([], selectedTool,
                                        toolRadius: screenBrushRadius)
                                  ];
                                });
                                generateMask(context);
                              },
                        child: Text(
                          "Clear",
                          style: TextStyle(color: globalState.theme.button),
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed:saveResult,
                        child: Text(
                          "Done",
                          style: TextStyle(color: globalState.theme.button),
                        ),
                      ),
                      // Opacity(
                      //   opacity: 1.0, //0.9
                      //   child: MaskPageMenu(
                      //     menuOpened: menuOpened,
                      //     openMenu: openMenu,
                      //     closeMenu: closeMenu,
                      //     selectedTool: selectedTool,
                      //     onSaveResult: () {
                      //       saveResult();
                      //     },
                      //     onLassoToolSelected: () {
                      //       const tool = ToolType.lasso;
                      //       screenPointsWithTool.last = SelectionWithTool([], tool,
                      //           toolRadius: screenBrushRadius);
                      //       setState(() {
                      //         selectedTool = tool;
                      //       });
                      //     },
                      //     onRectToolSelected: () {
                      //       const tool = ToolType.rect_area;
                      //       screenPointsWithTool.last = SelectionWithTool([], tool,
                      //           toolRadius: screenBrushRadius);
                      //       setState(() {
                      //         selectedTool = tool;
                      //       });
                      //     },
                      //     onBrushToolSelected: () {
                      //       const tool = ToolType.circle_brush;
                      //       screenPointsWithTool.last = SelectionWithTool([], tool,
                      //           toolRadius: screenBrushRadius);
                      //       setState(() {
                      //         selectedTool = tool;
                      //       });
                      //     },
                      //     screenPointsWithTool: screenPointsWithTool,
                      //     onClear: () {
                      //       setState(() {
                      //         screenPointsWithTool = [
                      //           SelectionWithTool([], selectedTool,
                      //               toolRadius: screenBrushRadius)
                      //         ];
                      //       });
                      //       generateMask(context);
                      //     },
                      //     onUndo: () {
                      //       if (screenPointsWithTool.length == 1) return;
                      //
                      //       setState(() {
                      //         screenPointsWithTool
                      //             .removeAt(screenPointsWithTool.length - 1);
                      //         screenPointsWithTool.last = SelectionWithTool(
                      //             [], selectedTool,
                      //             toolRadius: screenBrushRadius);
                      //       });
                      //       generateMask(context);
                      //     },
                      //     showOriginal: _showOriginal,
                      //     showMask: _showMask,
                      //     showSelection: _showSelection,
                      //     imageDetails: widget.imageDetails,
                      //     onSwitchShowMask: (a) {
                      //       setState(() {
                      //         _showMask = a;
                      //       });
                      //     },
                      //     onSwitchShowSelection: (a) {
                      //       setState(() {
                      //         _showSelection = a;
                      //       });
                      //     },
                      //     onSwitchShowOriginal: (a) {
                      //       setState(() {
                      //         _showOriginal = a;
                      //       });
                      //     },
                      //     onSwitchImage: (val) {
                      //       setState(() {
                      //         if (val != null) {
                      //           widget.imageDetails = val!;
                      //         }
                      //       });
                      //       resetSelection();
                      //     },
                      //   ),
                      // ),

                      //   menuOpened == true
                      //     ? IconButton(
                      //     icon: Icon(
                      //       Icons.expand_more,
                      //       color: globalState.theme.button,
                      //     ),
                      //       onPressed: () {
                      //         setState(() {
                      //           menuOpened = false;
                      //         });
                      //       }
                      //   )
                      //       :
                      // Positioned(
                      //     bottom: 0,
                      //     left: 0,
                      //     width: W,
                      //     height: 50,
                      //     child: Container(
                      //         color: globalState
                      //             .theme.background, //Colors.grey.shade200,
                      //         child: Row(children: [
                      //           const Spacer(),
                      //           IconButton(
                      //               icon: Icon(
                      //                 Icons.expand_less,
                      //                 color: globalState.theme.button,
                      //               ),
                      //               onPressed: openMenu)
                      //         ]))),
                    ]))
              ]),
            ),
          ),
          SafeArea(
              top: true,
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_rounded)))
        ]));
  }

  openMenu() {
    setState(() {
      menuOpened = true;
    });
  }

  closeMenu() {
    setState(() {
      menuOpened = false;
    });
  }

  storeLastStroke() {
    screenPointsWithTool.add(SelectionWithTool([], selectedTool));
  }

  saveResult() async {
    await ImageWriter.saveImageAsPngFromUrl(
        widget.imageDetails.url, "original.png");
    if (maskImageBytes != null) {
      final path = await ImageWriter.saveImageBytesToAppDirectory(
          maskImageBytes!, "mask.png");
      widget.prompt.maskImage = File(path);
      widget.prompt.screenPoints = screenPointsWithTool;
      Navigator.pop(context, widget.prompt);
    }
  }

  generateMask(BuildContext context) async {
    final imageBytes1 = await MaskGenerator.generateMask(
        context, screenPointsWithTool, widget.imageDetails);

    setState(() {
      maskImageBytes = imageBytes1;
    });
  }
}
