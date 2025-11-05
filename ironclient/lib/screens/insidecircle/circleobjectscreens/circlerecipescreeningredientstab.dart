import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/recipeingredient.dart';

class CircleRecipeIngredientsTab extends StatefulWidget {
  final CircleRecipe? circleRecipe;
  final int? screenMode;

  const CircleRecipeIngredientsTab({
    Key? key,
    this.circleRecipe,
    this.screenMode,
  }) : super(key: key);

  @override
  CircleRecipeIngredientsTabState createState() =>
      CircleRecipeIngredientsTabState();
}

class CircleRecipeIngredientsTabState extends State<CircleRecipeIngredientsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  //final _scaffoldKey = GlobalKey<ScaffoldState>();
  //final _formKey = GlobalKey<FormState>();

  //TextEditingController _listName = TextEditingController();

  final double _iconSize = 40;

  _addNew() {
    widget.circleRecipe!.addIngredient();
  }

  @override
  bool get wantKeepAlive => true;


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Container(
            color: globalState.theme.tabBackground,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                      padding: EdgeInsets.only(
                    top: 10,
                  )),
                  widget.screenMode == ScreenMode.READONLY
                      ? Container()
                      : Padding(
                          padding: const EdgeInsets.only(
                            right: 10,
                          ),
                          child: ClipOval(
                            child: Material(
                              color: globalState.theme.buttonIcon, // button color
                              child: InkWell(
                                splashColor: globalState.theme.buttonIconSplash, // inkwell color
                                child: SizedBox(
                                    width: _iconSize,
                                    height: _iconSize,
                                    child: Icon(
                                      Icons.add,
                                      color: globalState.theme.checkBoxCheck,
                                    )),
                                onTap: () {
                                  setState(() {
                                    _addNew();
                                  });
                                },
                              ),
                            ),
                          )),
                  Expanded(
                      child: Theme(
                          data: ThemeData(canvasColor: Colors.transparent),
                          child: ReorderableListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          scrollController: _scrollController,

                          children: [
                            for (var item in widget.circleRecipe!.ingredients!)
                              RecipeIngredient(
                                isNew: true,
                                screenMode: widget.screenMode,
                                key: ObjectKey(item),
                                index: widget.circleRecipe!.ingredients!
                                    .indexOf(item),
                                add: _addAboveIndex,
                                remove: _remove,
                                circleRecipeIngredient: item,
                              ),
                          ],
                          onReorder: (oldIndex, newIndex) {
                            if (_invalidSort(oldIndex, newIndex)) return;

                            int? oldOrder =
                                widget.circleRecipe!.ingredients![oldIndex].order;

                            int newOrder = 0;

                            if (newIndex == 0 || newIndex < oldIndex) {
                              newOrder = widget
                                  .circleRecipe!.ingredients![newIndex].order;
                            } else if (newIndex > oldIndex) {
                              newOrder = widget
                                  .circleRecipe!.ingredients![newIndex - 1].order;
                            }

                            if (newIndex > oldIndex) {
                              //ITEM WENT DOWN
                              for (CircleRecipeIngredient ingredient
                                  in widget.circleRecipe!.ingredients!) {
                                if (ingredient.order > oldOrder &&
                                    ingredient.order <= newOrder)
                                  ingredient.order--;
                              }

                              setState(() {
                                final item =
                                    widget.circleRecipe!.ingredients![oldIndex];
                                item.order = newOrder;
                                widget.circleRecipe!.ingredients!
                                    .insert(newIndex, item);

                                widget.circleRecipe!.ingredients!
                                    .removeAt(oldIndex);
                                _sortList();
                              });
                            } else {
                              //ITEM WENT UP
                              for (CircleRecipeIngredient ingredient
                                  in widget.circleRecipe!.ingredients!) {
                                if (ingredient.order < oldOrder &&
                                    ingredient.order >= newOrder)
                                  ingredient.order++;
                              }

                              setState(() {
                                final item = widget.circleRecipe!.ingredients!
                                    .removeAt(oldIndex);
                                item.order = newOrder;
                                widget.circleRecipe!.ingredients!
                                    .insert(newIndex, item);
                                _sortList();
                              });
                            }
                          })))
                ])));
  }

  bool _invalidSort(int oldIndex, int newIndex) {
    bool stop = false;

    //glitch with the sort widget, this is a partial move down
    if (oldIndex == 0 && newIndex == 1) {
      return true;
    }

    //prevent manual resorting of complete items, because that's dumb
    if (widget.screenMode == ScreenMode.READONLY) stop = true;

    if (stop) {
      // FormattedSnackBar.showSnackbar(
      //    _scaffoldKey, 'can not reorder completed tasks', "", 2);
    }

    return stop;
  }

  _sortList() {
    setState(() {
      //widget.circleRecipe.sortList();
    });
  }

  _addAboveIndex(int index) {
    setState(() {
      //widget.circleRecipe.ingredients.addAboveIndex(index);
    });
  }

  _remove(int index) {
    setState(() {
      widget.circleRecipe!.ingredients!.removeAt(index);

      //decrement the order
      for (int i = index; i < widget.circleRecipe!.ingredients!.length; i++) {
        widget.circleRecipe!.ingredients![i].order--;
      }
    });
  }

  /*
  _moveUp(int index) {
    setState(() {
      _tasks.insert(index - 1, _tasks[index]);
      _tasks.removeAt(index + 1);

      _expandList.insert(index - 1, _expandList[index]);
      _expandList.removeAt(index + 1);

      _assignees.insert(index - 1, _assignees[index]);
      _assignees.removeAt(index + 1);

      _due.insert(index - 1, _due[index]);
      _due.removeAt(index + 1);
    });
  }

  _moveDown(int index) {
    setState(() {
      _tasks.insert(index + 2, _tasks[index]);
      _tasks.removeAt(index);

      _expandList.insert(index + 2, _expandList[index]);
      _expandList.removeAt(index);

      _assignees.insert(index + 2, _assignees[index]);
      _assignees.removeAt(index);

      _due.insert(index + 2, _due[index]);
      _due.removeAt(index);
    });
  }
  */

}
