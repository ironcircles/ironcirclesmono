import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PaintShaderUtils{
  static Paint createCheckerboardPaint(){
    // Create a checkerboard pattern shader
    final Shader checkerboardShader = PaintShaderUtils.createCheckerboardShader();

    return   Paint()
      ..shader = checkerboardShader // Use the shader as the paint fill
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill; // Ensure the circles are filled

  }
  static Paint createRedPaint(){
    return   Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1; // Ensure the circles are filled

  }
  static Shader createCheckerboardShader() {
    // Size of each checkerboard square
    const squareSize = 7.0;
    // Colors for the checkerboard squares
    const colors = [Colors.black, Colors.white];

    // Create a shader from a built-in Flutter method
    return ui.Gradient.radial(
      Offset.zero,
      squareSize,
      colors,
      [0.0, 1.0],
      ui.TileMode.mirror,
      null,
      Offset(squareSize / 2, squareSize / 2),
    );
  }
}