import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';

class DebugPanel extends StatelessWidget{
  final List<SelectionWithTool> screenPointsWithTool;

  const DebugPanel(this.screenPointsWithTool); //{super.key}
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: EdgeInsets.all(10),    color: Colors.white.withOpacity(0.9),
      child: ListView(
        children: [
          Text(
            screenPointsWithTool.length.toString() + " stroke" + (screenPointsWithTool.length > 1 ? "s" : ""),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Divider(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tool",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Length",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
              children: screenPointsWithTool
                  .map((c) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.tool.toString()),
                  Text(c.screenPoints.length.toString()),
                ],
              ))
                  .toList()),

        ],

      ),
    )  ;
  }
}