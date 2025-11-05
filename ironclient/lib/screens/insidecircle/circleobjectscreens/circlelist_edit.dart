import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/task_edit.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CircleListEdit extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  final CircleObject? circleObject;
  final CircleList circleList;
  final bool isNew;

  const CircleListEdit(
      {Key? key,
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      required this.circleList,
      required this.isNew})
      : super(key: key);

  @override
  CircleListEditState createState() => CircleListEditState();
}

class CircleListEditState extends State<CircleListEdit> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String?> _members = [];
  List<User?> _membersList = [];

  final CircleBloc _circleBloc = CircleBloc();
  FocusNode? _currentFocus;

  late CircleList _filteredList;

  void _filterList() {
    _filteredList = CircleList.deepCopy(widget.circleList);
    _filteredList.tasks!.removeWhere((element) => element.complete!);
    _filteredList.initUIControls();
  }

  @override
  void initState() {
    super.initState();
    _filterList();
    _sortList();
    //Listen for membership load
    _circleBloc.membershipList.listen((memberList) {
      if (mounted) {
        setState(() {
          _members = [];
          _membersList = memberList;
          _members.add('');
          for (User? user in memberList) {
            _members.add(user!.getUsernameAndAlias(globalState));
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _circleBloc.getMembershipList(widget.userCircleCache!, widget.userFurnace!);
  }

  @override
  void dispose() {
    _filteredList.disposeUIControls();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(flex: 1, child: Container()),
          Padding(
              padding: const EdgeInsets.only(right: 3.85),
              child: Ink(
                decoration: ShapeDecoration(
                  color: globalState.theme.buttonIcon,
                  shape: const CircleBorder(),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 25 - globalState.scaleDownIcons,
                  ),
                  color: globalState.theme.checkBoxCheck,
                  onPressed: () {
                    _addNew();
                    _nextFocus();
                  },
                ),
              ))
        ]),
      ),
    ]);

    final makeList =
        // Theme(
        // data: ThemeData(canvasColor: Colors.transparent),
        // child:
        ReorderableListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollController: _scrollController,
            children: [
              for (var item in _filteredList.tasks!)
                TaskEdit(
                  onFieldSubmitted: _onFieldSubmitted,
                  onChanged: onChanged,
                  isNew: false,
                  checkable: _filteredList.checkable,
                  key: ObjectKey(item),
                  membersList: _membersList,
                  members: _members,
                  circleListTask: item,
                  index: _filteredList.tasks!.indexOf(item),
                  changeComplete: _markComplete,
                  add: _addAboveIndex,
                  remove: _remove,
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              int oldMainIndexSeed = widget.circleList.tasks!.indexWhere(
                  (element) =>
                      element.seed == _filteredList.tasks![oldIndex].seed!);

              int newMainIndexSeed = widget.circleList.tasks!.indexWhere(
                  (element) =>
                      element.seed == _filteredList.tasks![newIndex].seed!);

              if (oldMainIndexSeed == -1 || newMainIndexSeed == -1) {
                debugPrint(
                    'fatal list error oldMainIndexSeed: $oldMainIndexSeed newMainIndexSeed: $newMainIndexSeed');
                return;
              }

              debugPrint('oldIndex: $oldIndex newIndex: $newIndex');
              debugPrint(
                  'oldMainIndexSeed: $oldMainIndexSeed newMainIndexSeed: $newMainIndexSeed');

              final item = _filteredList.tasks!.removeAt(oldIndex);
              _filteredList.tasks!.insert(newIndex, item);

              final mainListItem =
                  widget.circleList.tasks!.removeAt(oldMainIndexSeed);
              widget.circleList.tasks!.insert(newMainIndexSeed, mainListItem);
              widget.circleList.setOrder(_filteredList);

              _filteredList.initUIControls();
              setState(() {
                _sortList();
              });

              /*int oldFullOrder = _filteredList.tasks![oldIndex].order;

              if (newIndex > oldIndex) {
                ///ITEM WENT DOWN
                int fullListIndex = widget.circleList.tasks!
                    .indexWhere((element) => element.order == oldFullOrder);

                late int newOrder;

                newOrder = _filteredList.tasks![newIndex - 1]
                    .order; // -1 because the newIndex includes the old and position

                int newFullIndex = widget.circleList.tasks!
                    .indexWhere((element) => element.order == newOrder);

                for (CircleListTask task in widget.circleList.tasks!) {
                  if (task.order > oldFullOrder && task.order <= newOrder)
                    task.order--;
                }

                final item = widget.circleList.tasks![fullListIndex];
                item.order = newOrder;
                widget.circleList.tasks!.insert(newFullIndex, item);

                widget.circleList.tasks!.removeAt(fullListIndex);



                //_filterList();
                _filteredList.initUIControls();
                setState(() {
                  _sortList();
                });
              } else {
                ///ITEM WENT UP
                int fullListIndex = widget.circleList.tasks!
                    .indexWhere((element) => element.order == oldFullOrder);

                int newOrder = _filteredList.tasks![newIndex].order;

                int newFullIndex = widget.circleList.tasks!
                    .indexWhere((element) => element.order == newOrder);

                for (CircleListTask task in widget.circleList.tasks!) {
                  if (task.order < oldFullOrder && task.order >= newOrder)
                    task.order++;
                }

                final item = widget.circleList.tasks![fullListIndex];
                item.order = newOrder;
                _filteredList.tasks!.insert(newFullIndex, item);

                //_filterList();
                _filteredList.initUIControls();
                setState(() {
                  _sortList();
                });
              }*/
            });

    return Scaffold(
      backgroundColor: globalState.theme.tabBackground,
      key: _scaffoldKey,
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
        child: Stack(
          children: [
            WrapperWidget(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                makeHeader,
                // Spacer(),
                Expanded(
                  child: makeList,
                ),
                //Expanded(flex: 1,
                //child: makeClosedList,
                //),
              ],
            )),
          ],
        ),
      ),
    );
  }

  bool blankDate(int index) {
    if (widget.circleList.tasks![index].due == null) return true;

    return (widget.circleList.tasks![index].due!
            .difference(DateTime(1))
            .inSeconds ==
        0);
  }

  _sortList() {
    setState(() {
      _filteredList.sortList();
      widget.circleList.sortList();
    });
  }

  onChanged(int order, String text) {
    var circleListTask = widget.circleList.tasks!
        .singleWhere((element) => element.order == order);
    circleListTask.name = text;
  }

  _nextFocus() {
    if (_currentFocus != null) {
      _currentFocus!.unfocus();

      _currentFocus = widget
          .circleList.tasks![widget.circleList.tasks!.length - 1].focusNode!;

      _currentFocus!.requestFocus();
    }
  }

  _onFieldSubmitted(String value) {
    setState(() {
      _addNew();
    });

    _nextFocus();
  }

  _addNew() {
    setState(() {
      CircleListTask circleListTask = widget.circleList.addNewTask();

      _filteredList.tasks!.add(circleListTask);
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 80);

      _currentFocus = widget
          .circleList.tasks![widget.circleList.tasks!.length - 1].focusNode!;

      _filteredList.sortList();
    });
  }

  _addAboveIndex(int index) {
    setState(() {
      widget.circleList.addAboveIndex(index);

      _filterList();
    });
  }

  _remove(int index) {
    CircleListTask circleListTask = _filteredList.tasks![index];

    setState(() {
      _filteredList.tasks!.removeAt(index);
      widget.circleList.tasks!
          .removeWhere((element) => element.seed == circleListTask.seed);
      widget.circleList.setOrder(_filteredList);

      /* int priorOrder = circleListTask.order;

      widget.circleList.tasks!
          .removeWhere((element) => element.order == priorOrder);

      //decrement the order
      for (int i = 0; i < widget.circleList.tasks!.length; i++) {
        CircleListTask reorder = widget.circleList.tasks![i];

        if (reorder.order > priorOrder) reorder.order--;
      }

      _filterList();*/
    });
  }

  _markComplete(CircleListTask circleListTask, bool checked) {
    setState(() {
      circleListTask.complete = checked;

      CircleListTask? mainTask;

      List<CircleListTask> duplicateOrder = widget.circleList.tasks!
          .where((element) => element.order == circleListTask.order)
          .toList();

      if (duplicateOrder.length > 1) {
        ///try to match on something else
        for (CircleListTask task in duplicateOrder) {
          ///try id
          if (task.id == circleListTask.id) {
            mainTask = task;
            break;
          }

          ///try seed
          if (task.seed == circleListTask.seed) {
            mainTask = task;
            break;
          }

          ///try name
          if (task.name == circleListTask.name) {
            mainTask = task;
            break;
          }
        }
      } else if (duplicateOrder.length == 1) {
        mainTask = duplicateOrder[0];
      }

      if (mainTask == null) {
        LogBloc.postLog(
            'unable to find list element', 'CircleListEdit.markComplete');
        return;
      }

      mainTask.complete = checked;

      if (checked) {
        circleListTask.completedBy = globalState.user;
        circleListTask.completed = DateTime.now().toLocal();
        mainTask.completedBy = globalState.user;
        mainTask.completed = DateTime.now().toLocal();
      } else {
        circleListTask.completedBy = null;
        circleListTask.completed = null;
        mainTask.completedBy = null;
        mainTask.completed = null;
      }

      // _filterList();
    });
  }
}
