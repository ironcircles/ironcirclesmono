import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/enum/tool_type.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/painters/brush_painter.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/painters/lasso_painter.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/painters/rect_painter.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';

/// `ImageSelectionOverlay` is a stateless widget that overlays selection tools on an image within a Flutter app.
/// It accepts a list of `SelectionWithTool`, which encapsulates the selection details and the tool used for selection,
/// along with `screenToImageRatio` and `screenBrushSize` to accurately scale and display the selections on different screen sizes.
/// This widget renders the selections using different painting tools based on the tool type—circle brush, lasso, or rectangle area—
/// with an overall opacity set to 0.7 for the overlay. Each selection tool is implemented using `CustomPaint` and a corresponding
/// painter class that draws the selection shapes based on the coordinates provided in `screenPoints`. This allows for dynamic and
/// flexible rendering of user selections on images, enhancing the interactive editing capabilities of the app.
class ImageSelectionOverlay extends StatelessWidget {
  final List<SelectionWithTool> selections;
  final double screenToImageRatio;
  final double screenBrushSize;
  const ImageSelectionOverlay(this.selections, this.screenToImageRatio, this.screenBrushSize);

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: 0.7,
        child: Stack(
            children: selections.map((c) {
              switch (c.tool) {
                case ToolType.circle_brush:
                  return CustomPaint(
                    painter: SelectionCircleBrushToolPainter(screenPoints: c.screenPoints, screenToImageRatio: screenToImageRatio,screenBrushSize: screenBrushSize),
                  );
                case ToolType.lasso:
                  return CustomPaint(painter: SelectionLassoToolPainter(screenPoints: c.screenPoints));
                case ToolType.rect_area:
                  return CustomPaint(painter: RectAreaPainter(screenPoints: c.screenPoints));
                default:
                  return Container();
              }
            }).toList()));
  }
}