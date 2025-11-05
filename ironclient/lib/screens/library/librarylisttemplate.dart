import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circlelisttemplate_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/task_edit.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class LibraryListTemplate extends StatefulWidget {
  final UserFurnace? userFurnace;
  final List<UserFurnace> userFurnaces;
  final CircleListTemplate template;
  final bool isNew;

  const LibraryListTemplate(
      {Key? key,
      this.userFurnace,
      required this.userFurnaces,
      required this.isNew,
      required this.template})
      : super(key: key);

  @override
  _LibraryListTemplateState createState() => _LibraryListTemplateState();
}

class _LibraryListTemplateState extends State<LibraryListTemplate> {
  bool? _saveList = true;

  //ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  CircleListTemplateBloc _templateBloc = CircleListTemplateBloc();

  List<String?> _members = [];
  List<User?> _membersList = [];

  CircleList _circleList = CircleList(complete: false, checkable: true);

  TextEditingController _listName = TextEditingController();

  String _checkableText = 'checkable?';
  bool _checkable = true;

  String? _furnace = '';
  List<String> _furnaceList = [];

  _addNew() {
    _circleList.addNewTask();
  }

  @override
  void initState() {
    super.initState();

    _circleList = CircleList.initFromTemplate(widget.template);
    if (_circleList.name != null) _listName.text = _circleList.name!;

    if (widget.isNew) {
      for (UserFurnace userFurnace in widget.userFurnaces) {
        if (userFurnace.connected!) _furnaceList.add(userFurnace.alias!);
      }

      _furnace = _furnaceList[0];

      _addNew();
      _addNew();
    }

    _templateBloc.upsertFinished.listen((success) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(context, AppLocalizations.of(context)!.templateUpdatedSuccessfully, "", 2, false);
        Navigator.of(context).pop();
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }, cancelOnError: false);
  }

  @override
  void dispose() {
    _circleList.disposeUIControls();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      widget.isNew
          ? Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: FormField(
                    builder: (FormFieldState<String> state) {
                      return FormattedDropdown(
                        hintText: 'select a furnace',
                        list: _furnaceList,
                        selected: _furnace,
                        errorText: state.hasError ? state.errorText : null,
                        onChanged: (String? value) {
                          setState(() {
                            if (value != null) {
                              _furnace = value!;
                              if (value!.isEmpty) value = null;
                              state.didChange(value);
                            }
                          });
                        },
                      );
                    },
                    validator: (dynamic value) {
                      return _furnace == null ? 'select a furnace' : null;
                    },
                  ),
                )
              ]),
            )
          : Container(),
      Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          /* Text(
            "Name:",
            style: TextStyle(fontSize: 18, color: globalState.theme.labelText),
          ),*/
          Expanded(
            flex: 1,
            child: ExpandingLineText(
              labelText: "enter name for list",
              maxLines: 4,
              controller: _listName,
              validator: (value) {
                if (_saveList!) {
                  if (value.toString().isEmpty) {
                    return 'required to save list';
                  }
                }
                return null;
              },
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              "Tasks:",
              style:
                  TextStyle(fontSize: 18, color: globalState.theme.labelText),
            ),
          ),
          // IconButton(icon: Icon(Icons.add), color: globalState.theme.buttonIcon,)
          Padding(
              padding: const EdgeInsets.only(right: 3.85),
              child: Container(
                child: Ink(
                  decoration: ShapeDecoration(
                    color: globalState.theme.buttonIcon,
                    shape: const CircleBorder(),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    color: globalState.theme.checkBoxCheck,
                    onPressed: () {
                      setState(() {
                        _addNew();
                      });
                    },
                  ),
                ),
              ))
        ]),
      ),
    ]);

    final makeList = Container(
        // child: SingleChildScrollView(
            //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ReorderableListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
          for (var item in _circleList.tasks!)
            TaskEdit(
              onChanged: onChanged,
              isNew: true,
              key: ObjectKey(item),
              membersList: _membersList,
              checkable: _checkable,
              members: _members,
              circleListTask: item,
              index: _circleList.tasks!.indexOf(item),
              changeComplete: null,
              add: _addAboveIndex,
              remove: _remove,
              templateMode: true,
            ),
        ],
            onReorder: (oldIndex, newIndex) {
              if (_invalidSort(oldIndex, newIndex)) return;

              int oldOrder = _circleList.tasks![oldIndex].order;

              int newOrder = 0;

              if (newIndex == 0 || newIndex < oldIndex) {
                newOrder = _circleList.tasks![newIndex].order;
              } else if (newIndex > oldIndex) {
                newOrder = _circleList.tasks![newIndex - 1].order;
              }

              if (newIndex > oldIndex) {
                //ITEM WENT DOWN
                for (CircleListTask task in _circleList.tasks!) {
                  if (task.order > oldOrder && task.order <= newOrder)
                    task.order--;
                }

                setState(() {
                  final item = _circleList.tasks![oldIndex];
                  item.order = newOrder;
                  _circleList.tasks!.insert(newIndex, item);

                  _circleList.tasks!.removeAt(oldIndex);
                  _sortList();
                });
              } else {
                //ITEM WENT UP
                for (CircleListTask task in _circleList.tasks!) {
                  if (task.order < oldOrder && task.order >= newOrder)
                    task.order++;
                }

                setState(() {
                  final item = _circleList.tasks!.removeAt(oldIndex);
                  item.order = newOrder;
                  _circleList.tasks!.insert(newIndex, item);
                  _sortList();
                });
              }
            }));

    final makeBottom = Container(
      //height: 120.0,
      //width: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 5),
        child: Column(
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: CheckboxListTile(
                            activeColor: globalState.theme.buttonIcon,
                            checkColor: Colors.black,
                            title: Text(
                              _checkableText,
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: _checkable,
                            onChanged: (newValue) {
                              setState(() {
                                _checkable = newValue!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity
                                .leading, //  <-- leading Checkbox
                          ),
                        )),
                    Expanded(flex: 1, child: Container())
                  ]),
              Row(children: <Widget>[
                Expanded(
                  flex: 1,
                  child: GradientButton(
                      text: 'UPDATE TEMPLATE',
                      onPressed: () {
                        _updateTemplate();
                      }),
                ),
              ]),
            ]),
      ),
    );
    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: globalState.theme.background,
      title: const Text("List Template"),
      actions: const <Widget>[],
    );

    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: topAppBar,
        body: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                makeHeader,
                // Spacer(),
                Expanded(
                  child: makeList,
                ),
                Container(
                  //  color: Colors.white,
                  padding: const EdgeInsets.all(0.0),
                  child: makeBottom,
                ),
              ],
            )),
      ),
    );
  }

  onChanged(int order, String text) {}

  bool _invalidSort(int oldIndex, int newIndex) {
    bool stop = false;

    //glitch with the sort widget, this is a partial move down
    if (oldIndex == 0 && newIndex == 1) {
      return true;
    }

    //prevent manual resorting of complete items, because that's dumb
    if (_circleList.tasks![oldIndex].complete!) stop = true;

    if (newIndex > oldIndex) {
      //ITEM WENT DOWN
      if (_circleList.tasks![newIndex - 1].complete!) stop = true;
    } else {
      if (_circleList.tasks![newIndex].complete!) stop = true;
    }

    if (stop) {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.cannotReorderCompletedTasks, "", 2,  false);
    }

    return stop;
  }

  _sortList() {
    setState(() {
      _circleList.sortList();
    });
  }

  bool blankDate(int index) {
    if (_circleList.tasks![index].due == null) return true;

    return (_circleList.tasks![index].due!.difference(DateTime(1)).inSeconds ==
        0);
  }

  _addAboveIndex(int index) {
    setState(() {
      _circleList.addAboveIndex(index);
    });
  }

  _remove(int index) {
    setState(() {
      _circleList.tasks!.removeAt(index);

      //decrement the order
      for (int i = index; i < _circleList.tasks!.length; i++) {
        _circleList.tasks![i].order--;
      }
    });
  }

  _updateTemplate() {
    if (_formKey.currentState!.validate()) {
      _circleList.name = _listName.text;
      _circleList.checkable = _checkable;

      late UserFurnace userFurnace;

      if (widget.isNew) {
        for (UserFurnace testFurnace in widget.userFurnaces) {
          if (testFurnace.alias == _furnace) {
            userFurnace = testFurnace;
            break;
          }
        }
      } else
        userFurnace = widget.userFurnace!;

      _templateBloc.upsert(_circleList, userFurnace);
    }
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
