import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialogvoiceoptions.dart';

enum VoiceButtonState {
  idle, // Static waveform
  recordingMemo, // Animated waveform
  voiceToText, // Microphone + waveform combo
}

class VoiceButtonWidget extends StatefulWidget {
  final Function(VoiceOption) onOptionSelected;
  final VoidCallback? onStopVoiceMemo;
  final VoidCallback? onStopVoiceToText;
  final VoiceButtonState buttonState;
  final double? soundLevel; // For animated waveform (0.0 to 1.0)

  const VoiceButtonWidget({
    Key? key,
    required this.onOptionSelected,
    this.onStopVoiceMemo,
    this.onStopVoiceToText,
    this.buttonState = VoiceButtonState.idle,
    this.soundLevel,
  }) : super(key: key);

  @override
  State<VoiceButtonWidget> createState() => _VoiceButtonWidgetState();
}

class _VoiceButtonWidgetState extends State<VoiceButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    switch (widget.buttonState) {
      case VoiceButtonState.idle:
        final option = await DialogVoiceOptions.show(context);
        if (option != null) {
          widget.onOptionSelected(option);
        }
        break;
      case VoiceButtonState.recordingMemo:
        widget.onStopVoiceMemo?.call();
        break;
      case VoiceButtonState.voiceToText:
        widget.onStopVoiceToText?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;

    switch (widget.buttonState) {
      case VoiceButtonState.idle:
        iconColor = globalState.theme.buttonDisabled;
        break;
      case VoiceButtonState.recordingMemo:
      case VoiceButtonState.voiceToText:
        iconColor = Colors.red;
        break;
    }

    return IconButton(
      icon: _buildIcon(iconColor),
      iconSize: 28,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: _handleTap,
    );
  }

  Widget _buildIcon(Color color) {
    switch (widget.buttonState) {
      case VoiceButtonState.idle:
        return _buildWaveformIcon(color, animated: false);
      case VoiceButtonState.recordingMemo:
        return _buildWaveformIcon(color, animated: true);
      case VoiceButtonState.voiceToText:
        return _buildMicIcon(color);
    }
  }

  Widget _buildWaveformIcon(Color color, {required bool animated}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(28, 28),
          painter: WaveformPainter(
            color: color,
            animationValue: animated ? _animationController.value : 0.0,
            soundLevel: widget.soundLevel,
          ),
        );
      },
    );
  }

  Widget _buildMicIcon(Color color) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(28, 28),
                painter: MicArcPainter(
                  color: color,
                  animationValue: _animationController.value,
                ),
              ),
              Icon(Icons.mic, color: color, size: 20),
            ],
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double? soundLevel;
  static const List<double> _barPhases = [0.15, 0.75, 1.45, 0.35, -0.55, -1.2];

  WaveformPainter({
    required this.color,
    required this.animationValue,
    this.soundLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    final barWidth = 2.0;
    final spacing = 2.0;
    final numBars = 6;
    final totalWidth = (numBars * barWidth) + ((numBars - 1) * spacing);
    final startX = (size.width - totalWidth) / 2;

    // Half-heights in pixels (center line at y=14) -> 2, 9, 6, 12, 6, 2
    final baseHalfHeights = [2.0, 9.0, 6.0, 12.0, 6.0, 2.0];

    for (int i = 0; i < numBars; i++) {
      final x = startX + (i * (barWidth + spacing));

      double halfHeight = baseHalfHeights[i];

      if (animationValue > 0) {
        // Strong pulse on the inner bars, especially the center
        final speedFactor = (i == 3) ? 0.7 : 1.0;
        final phaseOffset = _barPhases[i % _barPhases.length];
        final double wave = math.sin(
          (animationValue * 2 * math.pi * speedFactor) + phaseOffset,
        );
        final double intensity;
        if (i == 3) {
          intensity = 0.35; // center bar
        } else if (i == 2 || i == 4) {
          intensity = 0.28;
        } else if (i == 1 || i == 5) {
          intensity = 0.18;
        } else {
          intensity = 0.1;
        }
        halfHeight += halfHeight * intensity * wave;
      }

      if (soundLevel != null) {
        halfHeight += halfHeight * 0.3 * soundLevel!;
      }

      final top = centerY - halfHeight;
      final bottom = centerY + halfHeight;

      canvas.drawLine(
        Offset(x + (barWidth / 2), top),
        Offset(x + (barWidth / 2), bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.color != color;
  }
}

class MicArcPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  MicArcPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final arcPaintStrong =
        Paint()
          ..color = color.withOpacity(0.55 - (animationValue * 0.25))
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final arcPaintSoft =
        Paint()
          ..color = color.withOpacity(0.35 - (animationValue * 0.18))
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final outerRadiusStrong = 12 + (animationValue * 6);
    final outerRadiusSoft = 8 + (animationValue * 4);

    _drawArcPair(
      canvas,
      centerX,
      centerY,
      outerRadiusStrong,
      0.1,
      arcPaintStrong,
    );

    _drawArcPair(canvas, centerX, centerY, outerRadiusSoft, 0.0, arcPaintSoft);
  }

  void _drawArcPair(
    Canvas canvas,
    double centerX,
    double centerY,
    double radius,
    double angleOffset,
    Paint paint,
  ) {
    final rect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    );

    final sweep = math.pi * (0.9 - angleOffset);
    final leftStart = (math.pi / 2) + angleOffset;
    final rightStart = -(math.pi / 2) - angleOffset - sweep;

    canvas.drawArc(rect, leftStart, sweep, false, paint);
    canvas.drawArc(rect, rightStart, sweep, false, paint);
  }

  @override
  bool shouldRepaint(MicArcPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
