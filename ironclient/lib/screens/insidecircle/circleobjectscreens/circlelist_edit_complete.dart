import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/task_edit.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CircleListEditComplete extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  final CircleObject? circleObject;
  final CircleList circleList;
  final bool isNew;

  const CircleListEditComplete(
      {Key? key,
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      required this.circleList,
      required this.isNew})
      : super(key: key);

  @override
  _CircleListEditCompleteState createState() => _CircleListEditCompleteState();
}

class _CircleListEditCompleteState extends State<CircleListEditComplete> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String?> _members = [];
  List<User?> _membersList = [];

  final CircleBloc _circleBloc = CircleBloc();
  //List<CircleListTask> _filteredTasks = [];

  //final double _iconSize = 45;

  late CircleList _filteredList;

  void filterList() {
    _filteredList = CircleList.deepCopy(widget.circleList);
    _filteredList.tasks!.removeWhere((element) => !element.complete!);
    _filteredList.initUIControls();
  }

  @override
  void initState() {
    super.initState();

    filterList();
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

  onChanged(int order, String text) {}

  @override
  Widget build(BuildContext context) {
    final makeList = Theme(
        data: ThemeData(canvasColor: Colors.transparent),
        child: ReorderableListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollController: _scrollController,
            children: [
              for (var item in _filteredList.tasks!)
                TaskEdit(
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
              FormattedSnackBar.showSnackbarWithContext(
                  context,
                  AppLocalizations.of(context)!.completedTasksCannotBeReordered,
                  "",
                  2,
                  false);
              return;
            }));

    return Scaffold(
      backgroundColor: globalState.theme.tabBackground,
      key: _scaffoldKey,
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
        child: Stack(
          children: [
            WrapperWidget(child:Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
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
      _filteredList.sortListByCompleted();
      widget.circleList.sortList();
    });
  }

  _addAboveIndex(int index) {
    setState(() {
      widget.circleList.addAboveIndex(index);

      filterList();
    });
  }

  _remove(int index) {
    CircleListTask circleListTask = _filteredList.tasks![index];

    setState(() {
      _filteredList.tasks!.removeAt(index);
      widget.circleList.tasks!
          .removeWhere((element) => element.seed == circleListTask.seed);
      widget.circleList.setOrder(_filteredList);
    });

    /* CircleListTask circleListTask = _filteredList.tasks![index];

    setState(() {
      int priorOrder = circleListTask.order;

      // _filteredList.tasks!.removeAt(index);
      widget.circleList.tasks!
          .removeWhere((element) => element.order == priorOrder);

      //decrement the order
      for (int i = 0; i < widget.circleList.tasks!.length; i++) {
        CircleListTask reorder = widget.circleList.tasks![i];

        if (reorder.order > priorOrder) reorder.order--;
      }

      filterList();
    });

    */
  }

  _markComplete(CircleListTask circleListTask, bool checked) {
    setState(() {
      circleListTask.complete = checked;

      CircleListTask mainTask = widget.circleList.tasks!
          .singleWhere((element) => element.order == circleListTask.order);
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

      //

      _sortList();
      filterList();
    });
  }
}
