import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class BlinkIcon extends StatefulWidget {
  @override
  _BlinkIconState createState() => _BlinkIconState();
}

class _BlinkIconState extends State<BlinkIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Color?>? _colorAnimation;

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _colorAnimation = ColorTween(begin: globalState.theme.buttonIcon, end: globalState.theme.background)
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
        return  Padding(
            padding: const EdgeInsets.only(left: 0, top: 0),
            child: Container(
                padding: const EdgeInsets.only(left: 0, top: 0),
                decoration: BoxDecoration(
                  color: _colorAnimation!.value,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  maxWidth: 8,
                  maxHeight: 8,
                )));
      },
    );
  }
}
