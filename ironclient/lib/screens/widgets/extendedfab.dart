import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class ExtendedFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final int iconSize;
  final Function onPressed;
  final Color color;

  const ExtendedFAB({
    Key? key,
    required this.label,
    required this.icon,
    this.iconSize = 25,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 5),
        child: FloatingActionButton.extended(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            heroTag: null,
            label: ICText(label,
                color: globalState.theme.background,
                fontWeight: FontWeight.bold),
            onPressed: () => onPressed(),
            backgroundColor: globalState.theme.homeFAB,
            icon: Icon(
              icon,
              size: iconSize + 5 - globalState.scaleDownIcons,
              color: globalState.theme.background,
            )));
  }
}
