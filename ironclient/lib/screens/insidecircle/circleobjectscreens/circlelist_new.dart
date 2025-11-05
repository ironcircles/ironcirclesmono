import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelisttemplatescreen.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/task_edit.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class CircleListNew extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final CircleObjectBloc circleObjectBloc;
  final CircleListBloc circleListBloc;
  final CircleObject? replyObject;
  final CircleObject? circleObject;
  final int timer;
  final DateTime? scheduledFor;
  final int? increment;
  final Function? setNetworks;
  final bool wall;

  const CircleListNew({
    Key? key,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleObjectBloc,
    this.circleObject,
    required this.userFurnaces,
    this.wall = false,
    required this.circleListBloc,
    this.setNetworks,
    required this.timer,
    this.scheduledFor,
    this.increment,
    required this.replyObject,
  }) : super(key: key);

  @override
  CircleListNewState createState() => CircleListNewState();
}

class CircleListNewState extends State<CircleListNew> {
  final ScrollController _scrollController = ScrollController();
  late GlobalEventBloc _globalEventBloc;
  bool? _saveList = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  List<UserFurnace> _selectedNetworks = [];
  List<String?> _members = [];
  List<User?> _membersList = [];
  bool _popping = false;

  final CircleBloc _circleBloc = CircleBloc();
  CircleList _circleList = CircleList(complete: false, checkable: true);
  CircleList _validateChanged = CircleList(complete: false, checkable: true);

  final TextEditingController _listName = TextEditingController();

  // String _saveTemplateQuestion = "save template?";
  // final String _checkableText = 'checkable?'
  //     '';
  bool _checkable = true;
  bool _saving = false;

  final double _iconSize = 45;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  late FocusNode _currentFocus;

  _nextFocus() {
    _currentFocus.unfocus();

    _currentFocus =
        _circleList.tasks![_circleList.tasks!.length - 1].focusNode!;

    _currentFocus.requestFocus();
  }

  _onFieldSubmitted(String value) {
    setState(() {
      _addNew();
    });

    _nextFocus();
  }

  _addNew() {
    bool scroll = false;

    if (_circleList.tasks!.isNotEmpty) scroll = true;

    _circleList.addNewTask();

    if (scroll) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 80);
    } else
      _currentFocus =
          _circleList.tasks![_circleList.tasks!.length - 1].focusNode!;
  }

  // popReturnData(CircleObject circleObject) {
  //   if (circleObject.id == null) {
  //     Navigator.pop(context, circleObject);
  //     return Future<bool>.value(true);
  //   }
  // }

  @override
  void initState() {
    super.initState();

    if (widget.circleObject != null && widget.circleObject!.list != null) {
      _circleList = CircleList.deepCopy(widget.circleObject!.list!);
      _validateChanged = widget.circleObject!.list!;
    } else {
      _validateChanged = CircleList.deepCopy(_circleList);
    }

    if (_circleList.name != null) {
      _listName.text = _circleList.name!;
    }

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    _circleList.initUIControls();

    if (_circleList.tasks!.isEmpty) {
      _addNew();
      //_addNew();
    }

    //Listen for membership load
    _circleBloc.membershipList.listen((memberList) {
      if (mounted) {
        setState(() {
          _members = [];
          _membersList = memberList;
          _members.add('');
          for (User? user in memberList) {
            _members.add(user!.username);
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.circleListBloc.created.listen((circleObject) {
      if (mounted) {
        if (circleObject.id == null) {
          _exit(circleObject: circleObject);
        }
      }
    }, onError: (err) {
      debugPrint("error $err");

      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context, err.toString(), "", 2, true);

        _saving = false;
      }
    }, cancelOnError: false);

    _circleBloc.getMembershipList(widget.userCircleCache, widget.userFurnace);
  }

  @override
  void dispose() {
    _circleList.disposeUIControls();

    super.dispose();
  }

  _saveDraft() async {
    CircleObject circleObject = _prepObject();

    await widget.circleObjectBloc.saveDraft(
        widget.userFurnace, widget.userCircleCache, '', null, null,
        preppedObject: circleObject);

    _exit();
  }

  _exitCheckToSave() async {
    if (widget.circleObject != null && widget.circleObject!.draft) {
      await widget.circleObjectBloc.saveDraft(
          widget.userFurnace, widget.userCircleCache, '', null, null,
          preppedObject: widget.circleObject!);
    }

    _exit();
  }

  _exit({CircleObject? circleObject}) {
    _closeKeyboard();
    if (circleObject != null && _popping == false) {
      _popping = true;
      Navigator.of(context).pop(circleObject);
    } else if (_popping == false) {
      _popping = true;
      Navigator.pop(context);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      const Padding(padding: EdgeInsets.only(top: 10)),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        globalState.isDesktop()
            ? Container()
            : Padding(
                padding: const EdgeInsets.only(top: 5),
                child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    //iconSize: 25 - globalState.scaleDownIcons,
                    icon: Icon(
                      Icons.arrow_back,
                      color: globalState.theme.menuIcons,
                      //size: 30 - globalState.scaleDownIcons,
                    ),
                    onPressed: () {
                      _prepObject();

                      _pop();
                    })),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: ExpandingLineText(
                maxLength: TextLength.Smallest,
                labelText: AppLocalizations.of(context)!.enterNameForList,
                maxLines: 4,
                controller: _listName,
                validator: (value) {
                  if (_saveList!) {
                    if (value.toString().isEmpty) {
                      return AppLocalizations.of(context)!
                          .errorRequiredToSaveList;
                    }
                  }
                  return null;
                },
              ),
            )),
        Padding(
            padding: const EdgeInsets.only(top: 5),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              //iconSize: 25 - globalState.scaleDownIcons,
              icon: Icon(
                Icons.search,
                color: globalState.theme.menuIcons,
                //size: 30 - globalState.scaleDownIcons,
              ),
              onPressed: () => _search(),
            )),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              "${AppLocalizations.of(context)!.tasks}:",
              textScaler: TextScaler.linear(globalState.labelScaleFactor),
              style:
                  TextStyle(fontSize: 18, color: globalState.theme.labelText),
            ),
          ),
          // IconButton(icon: Icon(Icons.add), color: globalState.theme.buttonIcon,)
          Padding(
              padding: const EdgeInsets.only(right: 3.85),
              child: Ink(
                decoration: ShapeDecoration(
                  color: globalState.theme.button,
                  shape: const CircleBorder(),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 40 - globalState.scaleDownIcons,
                  icon: Icon(
                    Icons.add,
                    size: 25 - globalState.scaleDownIcons,
                  ),
                  color: globalState.theme.checkBoxCheck,
                  onPressed: () {
                    setState(() {
                      _addNew();
                    });
                    _nextFocus();
                  },
                ),
              ))
        ]),
      ),
    ]);

    onChanged(int order, String text) {}

    final makeList =
        // Theme(
        //     data: ThemeData(canvasColor: Colors.transparent),
        //     child:
        ReorderableListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollController: _scrollController,
            children: [
              for (var item in _circleList.tasks!)
                TaskEdit(
                  onFieldSubmitted: _onFieldSubmitted,
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
            });

    final makeBottom = Padding(
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
                        child: Theme(
                            data: ThemeData(
                                unselectedWidgetColor:
                                    globalState.theme.checkUnchecked),
                            child: CheckboxListTile(
                              activeColor: globalState.theme.buttonIcon,
                              checkColor: globalState.theme.checkBoxCheck,
                              title: ICText(
                                  "${AppLocalizations.of(context)!.checkable.toLowerCase()}?",
                                  textScaleFactor: globalState.labelScaleFactor,
                                  fontSize: 13,
                                  color: globalState.theme.labelText),

                              value: _checkable,
                              onChanged: (newValue) {
                                setState(() {
                                  _checkable = newValue!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity
                                  .leading, //  <-- leading Checkbox
                            )),
                      )),
                ]),

            ///select a furnace to post to
            widget.userFurnaces.length > 1 &&
                    widget.wall &&
                    widget.setNetworks != null
                ? Row(children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 10, left: 2, right: 2),
                          child: SelectNetworkTextButton(
                            userFurnaces: widget.userFurnaces,
                            selectedNetworks: _selectedNetworks,
                            callback: _setNetworks,
                          ),
                        ))
                  ])
                : Container(),
            Row(children: <Widget>[
              Expanded(
                flex: 1,
                child: GradientButton(
                    width: MediaQuery.of(context).size.width,
                    text: AppLocalizations.of(context)!.cREATELIST,
                    onPressed: () {
                      _save();
                    }),
              ),
            ]),
          ]),
    );

    final _formWidget = Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        body: SafeArea(
            left: true,
            top: true,
            right: true,
            bottom: true,
            child: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5, bottom: 0),
                child: Stack(
                  children: [
                    globalState.isDesktop()
                        ? Row(
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.only(left: 10, top: 5),
                                  child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      //iconSize: 25 - globalState.scaleDownIcons,
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: globalState.theme.menuIcons,
                                        //size: 30 - globalState.scaleDownIcons,
                                      ),
                                      onPressed: () {
                                        _prepObject();

                                        _pop();
                                      })),
                            ],
                          )
                        : Container(),
                    WrapperWidget(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        makeHeader,
                        // Spacer(),
                        Expanded(
                          child: makeList,
                        ),
                        makeBottom,
                      ],
                    )),
                    _showSpinner ? Center(child: spinkit) : Container(),
                  ],
                ))),
      ),
    );

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          _pop();
        },
        child: Platform.isIOS
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _pop();
                  }
                },
                child: _formWidget)
            : _formWidget);
  }

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
          context,
          AppLocalizations.of(context)!.completedTasksCannotBeReordered,
          "",
          2,
          false);
    }

    return stop;
  }

  _sortList() {
    setState(() {
      _circleList.sortList();
    });
  }

  _search() async {
    CircleListTemplate? template = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CircleListTemplateScreen(userFurnaces: widget.userFurnaces)),
    );

    if (template != null) {
      setState(() {
        _circleList = CircleList.initFromTemplate(template);
        _listName.text = _circleList.name!;
        //_saveTemplateQuestion = AppLocalizations.of(context)!.updateTemplate;
      });
    }
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

  _pop() {
    if (widget.wall == false &&
        CircleList.deepCompareChanged(_circleList, _validateChanged)) {
      DialogYesNo.askYesNo(
          context,
          widget.circleObject == null || widget.circleObject!.id != null
              ? AppLocalizations.of(context)!.saveDraftTitle
              : AppLocalizations.of(context)!.updateDraftTitle,
          widget.circleObject == null || widget.circleObject!.id != null
              ? AppLocalizations.of(context)!.saveDraftMessage
              : AppLocalizations.of(context)!.updateDraftMessage,
          _saveDraft,
          _exitCheckToSave,
          false);
    } else {
      _exitCheckToSave();
    }
  }

  CircleObject _prepObject() {
    FocusScope.of(context).requestFocus(FocusNode());

    _circleList.tasks!.removeWhere((element) => element.name == null);

    _circleList.name = _listName.text;
    _circleList.checkable = _checkable;

    CircleObject circleObject = CircleObject.prepNewCircleObject(
        widget.userCircleCache, widget.userFurnace, '', 0, widget.replyObject, type: CircleObjectType.CIRCLELIST);

    //circleObject.type = CircleObjectType.CIRCLELIST;
    circleObject.list = _circleList;

    return circleObject;
  }

  _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      if (widget.wall) {
        if (_selectedNetworks.isEmpty) {
          if (widget.userFurnaces.length == 1) {
            _setNetworksAndPost(widget.userFurnaces);
          } else {
            List<UserFurnace>? selectedNetworks =
                await DialogSelectNetworks.selectNetworks(
                    context: context,
                    networks: widget.userFurnaces,
                    callback: _setNetworksAndPost,
                    existingNetworksFilter: _selectedNetworks);

            if (selectedNetworks == null) {
              setState(() {
                _showSpinner = false;
              });
            }
          }
        } else {
          _saveCircleObject();
        }
      } else {
        _saveCircleObject();
      }
    }
  }

  _saveCircleObject() {
    if (_saving) return;

    if (_formKey.currentState!.validate()) {
      _saving = true;

      CircleObject circleObject = _prepObject();

      if (widget.wall) {
        ///Don't save the object if it's a wall post. The User might have selected multiple networks
        _exit(circleObject: circleObject);
      } else {
        if (widget.timer != UserDisappearingTimer.OFF)
          circleObject.timer = widget.timer;

        if (widget.scheduledFor != null) {
          circleObject.scheduledFor = widget.scheduledFor;
          circleObject.dateIncrement = widget.increment!;
        }

        widget.circleListBloc.createList(widget.userCircleCache, circleObject,
            _saveList, widget.userFurnace, _globalEventBloc);
      }
    }
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;

      _saveCircleObject();
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;
      setState(() {});
    }
  }
}
