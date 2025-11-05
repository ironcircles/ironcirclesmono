import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/shaders/paint_shader_utils.dart';

class SelectionLassoToolPainter extends CustomPainter {
  final List<Offset> screenPoints;
  final Color color;
  final double strokeWidth;

  SelectionLassoToolPainter({required this.screenPoints, this.color = Colors.red, this.strokeWidth = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (screenPoints.isEmpty) return;

    final paint = PaintShaderUtils.createCheckerboardPaint(); // Ensure the circles are filled

    Path path = Path();
    // Start path from the first point
    path.moveTo(screenPoints.first.dx, screenPoints.first.dy);

    // Connect all points with lines
    for (Offset point in screenPoints) {
      path.lineTo(point.dx, point.dy);
    }

    path.close(); // Close the path to form a lasso shape

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}