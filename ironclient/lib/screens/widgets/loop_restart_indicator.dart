import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoopRestartIndicator extends StatefulWidget {
  final VideoPlayerController controller;
  final Widget child;

  const LoopRestartIndicator({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<LoopRestartIndicator> createState() => _LoopRestartIndicatorState();
}

class _LoopRestartIndicatorState extends State<LoopRestartIndicator> {
  Duration _lastPosition = Duration.zero;
  bool _showRestart = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant LoopRestartIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTick);
      widget.controller.addListener(_onTick);
      _lastPosition = Duration.zero;
    }
  }

  void _onTick() {
    final value = widget.controller.value;
    if (!value.isInitialized) return;

    final current = value.position;
    final duration = value.duration;

    // Detect loop: either from near-end to near-start OR a backward jump > 500ms
    final bool wasNearEnd = duration > Duration.zero && _lastPosition >= duration - const Duration(milliseconds: 350);
    final bool nowNearStart = current <= const Duration(milliseconds: 350);
    final bool jumpedBack = _lastPosition > current + const Duration(milliseconds: 500);
    if ((wasNearEnd && nowNearStart) || jumpedBack) {
      _triggerIndicator();
    }

    _lastPosition = current;
  }

  void _triggerIndicator() {
    if (!mounted) return;
    setState(() => _showRestart = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showRestart = false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        AnimatedOpacity(
          opacity: _showRestart ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.replay, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Restarted', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


