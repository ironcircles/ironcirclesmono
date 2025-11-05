import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/globalstate.dart';

class ToolButton extends StatelessWidget {
  final bool isSelected;
  final Function onTap;
  final IconData icon;
  final String text;

  const ToolButton({required this.icon, required this.text, required this.isSelected, required this.onTap}); //{super.key},

  @override
  Widget build(BuildContext context) {
    return  Scaffold(body:Container(
        margin: EdgeInsets.only(right: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
            color: isSelected
                ? globalState.theme.inactiveThumbColor
                : globalState.theme.button.withOpacity(.2)
        ),
        padding: const EdgeInsets.fromLTRB(10.0, 5, 10, 5),
        child: InkWell(
          child:Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : globalState.theme.button,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              text,
              softWrap: false,
              overflow: TextOverflow.fade,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(
                fontFamily: 'Righteous',
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : globalState.theme.button
              //Colors.grey.shade700
              ),
            ),
          )
        ]),
          onTap: () {
            onTap();
          },
      )),

    );
  }
}