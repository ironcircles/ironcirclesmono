import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/enum/tool_type.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/widgets/tool_button.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class MaskPageMenu extends StatelessWidget {
  Function(ImageDetails?) onSwitchImage;
  ImageDetails imageDetails;
  bool showOriginal;
  Function(bool) onSwitchShowOriginal;
  Function() onUndo;
  ToolType selectedTool;
  Function() onClear;
  Function() onBrushToolSelected;
  Function() onSaveResult;
  Function() onRectToolSelected;
  Function() onLassoToolSelected;
  bool showMask;
  Function(bool) onSwitchShowMask;
  bool showSelection;
  Function(bool) onSwitchShowSelection;
  List<SelectionWithTool> screenPointsWithTool;
  Function openMenu;
  Function closeMenu;
  bool menuOpened;

  MaskPageMenu({
    required,
    required this.showOriginal,
    required this.onSwitchShowOriginal,
    required this.onBrushToolSelected,
    required this.onRectToolSelected,
    required this.onLassoToolSelected,
    required this.showMask,
    required this.onSwitchShowMask,
    required this.onUndo,
    required this.onClear,
    required this.selectedTool,
    required this.showSelection,
    required this.onSwitchShowSelection,
    required this.screenPointsWithTool,
    required this.onSaveResult,
    required this.onSwitchImage,
    required this.imageDetails,
    required this.openMenu,
    required this.closeMenu,
    required this.menuOpened,
  });

  @override
  Widget build(BuildContext context) {
    final mainWidget = Container(
        color: globalState.theme.background, //Colors.grey.shade200,
        //padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row(children: [
          //   const Spacer(),
          //   IconButton(
          //       icon: Icon(
          //         Icons.expand_more,
          //         color: globalState.theme.button,
          //       ),
          //       onPressed: () {
          //         closeMenu();
          //       })
          // ]),
          // const Padding(
          //   padding: EdgeInsets.only(top: 10),
          // ),
          // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          //   Text("Image"),
          //   DropdownButton<ImageDetails>(
          //       items: TestImageDetailsGenerator.choices,
          //       value: imageDetails,
          //       onChanged: (ImageDetails? val) {
          //         onSwitchImage(val);
          //       }),
          // ]),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text("Base image"),
          //     Switch(value: showOriginal, onChanged: onSwitchShowOriginal),
          //   ],
          // ),

          // Row(
          //   //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     // Text("Selection"),
          //     // Switch(value: showSelection, onChanged: onSwitchShowSelection),
          //     Expanded(
          //         child: SwitchListTile(
          //             activeColor: globalState.theme.button,
          //             inactiveThumbColor: globalState.theme.inactiveThumbColor,
          //             inactiveTrackColor: globalState.theme.inactiveTrackColor,
          //             trackOutlineColor: MaterialStateProperty.resolveWith(
          //                 globalState.getSwitchColor),
          //             value: showSelection,
          //             onChanged: onSwitchShowSelection,
          //             title: const ICText("Selection")))
          //   ],
          // ),
          // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          //   // Text("Mask"),
          //   // Switch(value: showMask, onChanged: onSwitchShowMask),
          //   Expanded(
          //       child: SwitchListTile(
          //           activeColor: globalState.theme.button,
          //           inactiveThumbColor: globalState.theme.inactiveThumbColor,
          //           inactiveTrackColor: globalState.theme.inactiveTrackColor,
          //           trackOutlineColor: MaterialStateProperty.resolveWith(
          //               globalState.getSwitchColor),
          //           value: showMask,
          //           onChanged: onSwitchShowMask,
          //           title: const ICText("Mask")))
          // ]),
        // SizedBox(height: 5,),

                Opacity(
                  opacity: (screenPointsWithTool.length > 1) ? 1 : 0.3,
                  child: ToolButton(
                    icon: Icons.undo,
                    text: "Undo",
                    isSelected: false,
                    onTap: onUndo,
                  ),
                ),
                ToolButton(
                    icon: Icons.clear,
                    text: "Clear",
                    isSelected: false,
                    onTap: onClear),
                // ToolButton(
                //   icon: Icons.square_outlined,
                //   text: "Rect",
                //   isSelected: selectedTool == ToolType.rect_area,
                //   onTap: onRectToolSelected,
                //),
                // ToolButton(
                //     icon: const IconData(0xf6d4,
                //         fontFamily: CupertinoIcons.iconFont,
                //         fontPackage: CupertinoIcons.iconFontPackage),
                //     text: "Lasso",
                //     isSelected: selectedTool == ToolType.lasso,
                //     onTap: onLassoToolSelected),
                // ToolButton(
                //   icon: Icons.brush,
                //   text: "Brush",
                //   isSelected: selectedTool == ToolType.circle_brush,
                //   onTap: onBrushToolSelected,
                // ),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //
                //     Padding(
                //         padding: const EdgeInsets.only(
                //             left: 5, right: 5, bottom: 0, top: 0),
                //         child: FloatingActionButton.extended(
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(30.0),
                //           ),
                //           label: ICText("Done",
                //               color: globalState.theme.background,
                //               fontWeight: FontWeight.bold),
                //           heroTag: null,
                //           onPressed: onSaveResult,
                //           backgroundColor: globalState.theme.homeFAB,
                //           icon: Icon(
                //             Icons.check,
                //             size: 25, //_iconSize - globalState.scaleDownIcons,
                //             color: globalState.theme.background,
                //           ),
                //         ))
                //   ],
                // )
              ],
            ),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     Padding(
          //         padding: const EdgeInsets.only(
          //             left: 5, right: 5, bottom: 5, top: 15),
          //         child: FloatingActionButton.extended(
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(30.0),
          //           ),
          //           label: ICText("Done",
          //               color: globalState.theme.background,
          //               fontWeight: FontWeight.bold),
          //           heroTag: null,
          //           onPressed: onSaveResult,
          //           backgroundColor: globalState.theme.homeFAB,
          //           icon: Icon(
          //             Icons.check,
          //             size: 25, //_iconSize - globalState.scaleDownIcons,
          //             color: globalState.theme.background,
          //           ),
          //         ))
          //   ],
          // )
        );

    return Scaffold(
      body: mainWidget,
    );
  }
}
