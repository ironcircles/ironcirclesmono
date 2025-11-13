import 'dart:math' as math;

import 'package:flutter/material.dart';

class VoiceWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final bool isRecording;
  final Color activeColor;
  final Color recordingColor;
  final Color markerColor;
  final int targetBarCount;

  const VoiceWaveformPainter({
    required this.samples,
    this.progress = 0.0,
    this.isRecording = false,
    required this.activeColor,
    required this.markerColor,
    this.recordingColor = Colors.redAccent,
    this.targetBarCount = 96,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      final paint = Paint()
        ..color = activeColor.withOpacity(0.3)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final baseline = size.height / 2;
      canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), paint);
      return;
    }

    final List<double> data = _resample(samples, targetBarCount);
    if (data.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = isRecording ? recordingColor : activeColor
      ..strokeCap = StrokeCap.round;

    final double step = size.width / math.max(data.length, 1);
    final double strokeWidth = step.clamp(2.0, 8.0) * 0.6;
    paint.strokeWidth = strokeWidth;

    final double baseline = size.height / 2;
    final double maxHeight = size.height * 0.9;

    for (int i = 0; i < data.length; i++) {
      final double value = data[i].clamp(0.0, 1.0);
      final double height = math.max(2.0, value * maxHeight);
      final double x = (i * step) + step / 2;
      canvas.drawLine(
        Offset(x, baseline - height / 2),
        Offset(x, baseline + height / 2),
        paint,
      );
    }

    if (isRecording) {
      final tailPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width, baseline), strokeWidth, tailPaint);
    } else if (progress > 0) {
      final markerPaint = Paint()
        ..color = markerColor
        ..strokeWidth = 2;
      final double x = (progress.clamp(0.0, 1.0)) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), markerPaint);
    }
  }

  static List<double> _resample(List<double> source, int targetCount) {
    if (source.isEmpty) return const [];
    if (source.length <= targetCount) {
      return List<double>.from(source);
    }

    final List<double> result = List<double>.filled(targetCount, 0);
    final double bucketSize = source.length / targetCount;

    double start = 0;
    for (int i = 0; i < targetCount; i++) {
      final double end = start + bucketSize;
      int left = start.floor();
      int right = end.ceil();

      if (left >= source.length) {
        left = source.length - 1;
      }

      if (right <= left) {
        right = left + 1;
      }
      if (right > source.length) {
        right = source.length;
      }

      double maxVal = 0;
      for (int j = left; j < right; j++) {
        maxVal = math.max(maxVal, source[j]);
      }
      result[i] = maxVal;
      start = end;
    }

    return result;
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.progress != progress ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.recordingColor != recordingColor ||
        oldDelegate.targetBarCount != targetBarCount;
  }
}

