import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class RecipeInstruction extends StatefulWidget {
  final CircleRecipeInstruction? circleRecipeInstruction;
  final Function? remove;
  final int? index;
  final bool isNew;
  final Function? add;
  final int? screenMode;

  const RecipeInstruction({
    Key? key,
    required this.isNew,
    this.circleRecipeInstruction,
    this.remove,
    this.add,
    this.index,
    this.screenMode,
  }) : super(key: key);

  @override
  RecipeInstructionState createState() => RecipeInstructionState();
}

class RecipeInstructionState extends State<RecipeInstruction> {
  final double _iconSize = 45;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding:
            const EdgeInsets.only(top: 4, bottom: 0, left: 5, right: 9),
        child:
            Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                /*Text(
                (index + 1).toString(),
                style:
                    TextStyle(fontSize: 18, color: globalState.theme.buttonIcon),
              ),*/
                Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 0, right:5),
                    child: CircleAvatar(radius: 18,
                        backgroundColor: globalState.theme.recipeIconBackground,
                        child: Text(widget.circleRecipeInstruction!.order
                            .toString(), style: TextStyle(fontSize: 13, color: globalState.theme.recipeIconForeground),))),
                //child: Text('1')),
                const Padding(padding: EdgeInsets.only(right: 0)),
                Expanded(
                  flex: 1,
                  child: ExpandingLineText(
                    maxLength: TextLength.Small,
                    counterText: '',
                    readOnly: widget.screenMode == ScreenMode.READONLY
                        ? true
                        : false,
                    //labelText: 'instruction',
                    /*validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'name of task is required';
                      }
                    },*/
                    onChanged: (text) {
                      widget.circleRecipeInstruction!.name = text;
                    },
                    controller: widget.circleRecipeInstruction!.controller,
                    /*labelText: _tasks[index].text.isEmpty
                      ? "task " + (index + 1).toString()
                      : null,

                   */
                    //labelText: "task " + (index + 1).toString(),
                    //labelText: 'task',
                    //labelText: widget.circleListTask.controller.text.toString().isEmpty ? "task" : null, //+ (index + 1).toString(),
                    //labelText: (index + 1).toString() ,
                    maxLines: 6,
                    textColor: globalState.theme.recipeLineText,
                    underline: globalState.theme.recipeLineText,
                    fontSize: 14,

                  ),
                ),
                widget.screenMode == ScreenMode.READONLY
                    ? Container()
                    : ClipOval(
                        child: Material(
                          color: globalState.theme.tabBackground, // button color
                          child: InkWell(
                            splashColor: globalState.theme.buttonLineBackground, // inkwell color
                            child: SizedBox(
                                width: _iconSize,
                                height: _iconSize,
                                child: Icon(Icons.remove_circle, color: globalState.theme.recipeIconAltBackground)),
                            onTap: () {
                              setState(() {
                                widget.remove!(widget.index);
                              });
                            },
                          ),
                        ),
                      ),
                globalState.isDesktop() ? Padding(padding: EdgeInsets.only(right: _iconSize/2)) : Container(),

                /*IconButton(
                color: globalState.theme.darkGrey,
                icon: Icon(Icons.calendar_today),
                onPressed: () {
                  _getDateTime(widget.circleListTask.due);
                },
              ),*/
              ]),
        ]));
  }
}
