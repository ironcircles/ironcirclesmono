import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
import 'package:ironcirclesapp/screens/stablediffusion/mask/shaders/paint_shader_utils.dart';

class SelectionCircleBrushToolPainter extends CustomPainter {
  final List<Offset> screenPoints;
  final double screenBrushSize;

  final double screenToImageRatio;
  const SelectionCircleBrushToolPainter({required this.screenPoints,required this.screenToImageRatio,required this.screenBrushSize});

  @override
  void paint(Canvas canvas, Size size) {
    final radius=screenBrushSize;
    // Create a checkerboard pattern shader
    final  paint = PaintShaderUtils.createCheckerboardPaint();

    for (var point in screenPoints) {
      canvas.drawCircle(point, radius, paint);
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}









class SelectionCircleBrushToolPainter__Unstable extends CustomPainter {
  final List<Offset> points;
  final double screenToImageRatio;
  final ui.Image texture;
  final double screenBrushSize;
  const SelectionCircleBrushToolPainter__Unstable(this.points, this.screenToImageRatio,this.texture,this.screenBrushSize);

  @override
  void paint(Canvas canvas, Size size) {
    final radius=screenBrushSize;
    // Paint object for the texture
    final texturePaint = Paint()..shader = ImageShader(texture, TileMode.repeated, TileMode.repeated, Float64List.fromList([
      1, 0, 0,
      0, 1, 0,
      0, 0, 1,
    ]));

    // Draw the texture across the entire canvas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), texturePaint);

    // Clip and reveal the texture within each disk
    for (Offset point in points) {
      // Save the canvas state
      canvas.save();
      // Apply a circular clip
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: point, radius: radius)));
      // Re-draw the texture, which will only appear within the clipped area
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), texturePaint);
      // Restore the canvas to remove the clip
      canvas.restore();
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}