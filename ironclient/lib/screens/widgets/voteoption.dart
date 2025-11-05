import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class VoteOption extends StatefulWidget {
  final CircleRecipeInstruction? circleRecipeInstruction;
  final Function? remove;
  final int? index;
  final bool isNew;
  final Function? add;

  const VoteOption({
    Key? key,
    required this.isNew,
    this.circleRecipeInstruction,
    this.remove,
    this.add,
    this.index,
  }) : super(key: key);

  @override
  VoteOptionState createState() => VoteOptionState();
}

class VoteOptionState extends State<VoteOption> {
  final double _iconSize = 45;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        //height:  widget.circleListTask.expanded ? 100 : 55,
        // child: SingleChildScrollView(
            //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
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
                        padding: const EdgeInsets.only(left: 2, bottom: 0),
                        child: CircleAvatar(
                            backgroundColor: globalState.theme.buttonIcon,
                            child: Text(widget.circleRecipeInstruction!.order
                                .toString()))),
                    //child: Text('1')),
                    const Padding(padding: EdgeInsets.only(right: 0)),
                    Expanded(
                      flex: 1,
                      child: ExpandingLineText(labelText: '',
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
                        maxLines: 1,
                        underline: globalState.theme.underline,
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: globalState.theme.buttonLineBackground, // button color
                        child: InkWell(
                          splashColor: globalState.theme.buttonLineForeground, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: const Icon(Icons.remove_circle)),
                          onTap: () {
                            setState(() {
                              widget.remove!(widget.index);
                            });
                          },
                        ),
                      ),
                    ),

                    /*IconButton(
                    color: globalState.theme.darkGrey,
                    icon: Icon(Icons.calendar_today),
                    onPressed: () {
                      _getDateTime(widget.circleListTask.due);
                    },
                  ),*/
                  ]),
            ])));
  }
}
