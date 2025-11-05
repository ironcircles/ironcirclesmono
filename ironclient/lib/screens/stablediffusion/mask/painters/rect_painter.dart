import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/shaders/paint_shader_utils.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/utils/image_utils.dart';
class RectAreaPainter extends CustomPainter {
  final List<Offset> screenPoints;

  RectAreaPainter({required this.screenPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // Ensure there are points to calculate the boundaries
    if (screenPoints.isEmpty) return;

    final bounds=ImageUtils.getRectangleEnvelope(screenPoints);    // Initialize min and max values with the first point

    final paint = PaintShaderUtils.createCheckerboardPaint(); // Ensure the circles are filled

    // Draw the rectangle using the calculated boundaries
    canvas.drawRect(Rect.fromLTRB(bounds.minX, bounds.minY, bounds.maxX,bounds. maxY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // You can optimize this to compare against the old swipe points if needed
    return true;
  }
}