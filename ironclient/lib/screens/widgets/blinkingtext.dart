import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class BlinkingText extends StatefulWidget {
  final String text;
  final Color color;
  final double size;

  BlinkingText(
      {required this.text,
      required this.color, this.size=11});

  @override
  _BlinkIconState createState() => _BlinkIconState();
}

class _BlinkIconState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Color?>? _colorAnimation;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _colorAnimation = ColorTween(
            begin: widget.color, end: globalState.theme.background)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
      setState(() {});
    });
    _controller.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return
            Text(widget.text,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(
                  fontSize: widget.size,
                  color: _colorAnimation!.value,
                ));

      },
    );
  }
}
