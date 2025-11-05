import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/enum/tool_type.dart';

/// Encapsulates a selection made on a screen with a specific tool.
///
/// This class stores details about a user's graphical selection, which includes a series
/// of screen coordinates where the selection occurred and the type of tool used for making
/// the selection.
///
/// Attributes:
///   screenPoints (List<Offset>): A list of screen coordinates representing the points
///     selected by the user. These are typically captured during a touch or mouse event.
///   tool (ToolType): An enum value indicating the type of tool used for the selection.
///     Different tools might include options like lasso, brush, rectangle, etc., each
///     modifying how selections are interpreted or rendered.
///
/// Example Usage:
///   var selection = SelectionWithTool(
///     [Offset(150, 200), Offset(160, 210)],
///     ToolType.brush
///   );
///   // This instance represents a selection made with a brush tool, starting at
///   // the point (150, 200) and ending at (160, 210).
///
class SelectionWithTool {
  final List<Offset> screenPoints;
  final ToolType tool;
  final double? toolRadius;

  const SelectionWithTool(this.screenPoints, this.tool,{this.toolRadius});
}