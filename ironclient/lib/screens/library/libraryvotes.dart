import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlevotes_edit.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:provider/provider.dart';

class LibraryVotes extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<CircleObject>? circleObjects;
  final GlobalEventBloc globalEventBloc;
  final bool shuffle;
  final bool slideUpPanel;
  final Function? updateSelected;

  const LibraryVotes({
    required this.circleObjects,
    required this.userFurnaces,
    required this.globalEventBloc,
    required this.shuffle,
    required this.slideUpPanel,
    this.updateSelected,
    Key? key,
  }) : super(key: key);

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<LibraryVotes> {
  final ScrollController _scrollController = ScrollController();
  late GlobalEventBloc _globalEventBloc;
  CircleObject? _selected;
  final double _iconSize = 31;
  final double _iconPadding = 12;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<CircleObject> _emptyList = [];
  //List<CircleRecipeTemplate> _templates = [];

  bool filter = false;
  //var _tapPosition;
  //final double _iconSize = 45;

  List<CircleObject> _circleObjects = [];
  //List<CircleObject> _selectedObjects = [];

  bool _toggleIcons = false;

  @override
  void initState() {
    widget.globalEventBloc.clear.listen((circleObject) {
      if (mounted) {
        setState(() {
          // _selected = null;
          if (widget.slideUpPanel == false) _toggleIcons = false;
        });
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    widget.globalEventBloc.scrollLibraryToTop.listen((value) {
      if (mounted) {
        setState(() {
          if (_scrollController.hasClients) {
            _selected = null;
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 1),
                curve: Curves.easeInOut);
          }
        });
      }
    }, onError: (err) {
      debugPrint("InsideCircle.listen: $err");
    }, cancelOnError: false);

    if (widget.slideUpPanel) {
      _toggleIcons = true;
    }

    super.initState();
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _circleObjects = [];
    _circleObjects.addAll(widget.circleObjects!);
    _circleObjects.retainWhere(
        (element) => (element.type == CircleObjectType.CIRCLEVOTE));

    if (!widget.shuffle) {
      _circleObjects.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });
    }

    ListTile makeListTile(int index, CircleObject object) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0, color: globalState.theme.cardSeparator))),
            child:
                Icon(Icons.poll, color: globalState.theme.cardLeadingIcon),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              object.vote!.question!,
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
              //circleObject.userFurnace.alias,
              style: TextStyle(
                  color: globalState.theme.cardTitle,
                  fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          object.userFurnace!.alias!,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.furnace),
                        ))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          "Status: ",
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.cardLabel),
                        ))),
                Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          object.vote!.open! ? 'Open' : 'Closed',
                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.textTitle),
                        ))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          "Circle: ",
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(color: globalState.theme.cardLabel),
                        ))),
                Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          object.userCircleCache!.prefName!,
                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.textTitle),
                        ))),
              ],
            ),
          ]),
          trailing: widget.slideUpPanel
              ? null
              : Icon(Icons.keyboard_arrow_right,
              color: globalState.theme.cardTrailingIcon, size: 30.0),
          onLongPress: () {
            _longPress(object);
          },
          onTap: () {
            //openDetail(context, userFurnace);
            _tapHandler(index, object);
          },
        );

    Card makeCard(int index, CircleObject object) => Card(
        color: globalState.theme.card,
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          makeListTile(index, object),
        ]));

    final makeList = ListView.separated(

        /// Let the ListView know how many items it needs to build
        itemCount: _circleObjects.length,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 1500,
        separatorBuilder: (context, index) {
          return Container(
            color: globalState.theme.background,
            height: 1,
            width: double.maxFinite,
          );
        },
        itemBuilder: (context, index) {
          //debugPrint(index);
          final CircleObject item = _circleObjects[index];

          //return makeCard(index, item); //make stack here, with on pressed stuff
          return InkWell(
              onLongPress: () {
                _longPress(item);
              },
              onTap: () {
                _tapHandler(index, item);
              },
              child: Stack(children: [
                makeCard(index, item),
                _selected != null && _selected == item
                    ? Positioned.fill(
                        child: Container(
                        color: _selected != null
                            ? const Color.fromRGBO(124, 252, 0, 0.5)
                            : Colors.transparent,
                        alignment: Alignment.center,
                      ))
                    : Container(),
                _selected == null && widget.slideUpPanel == false
                    ? const Padding(
                        padding: EdgeInsets.all(0), //5
                        // child: Icon(
                        //   Icons.circle_outlined,
                        //   color: globalState.theme.buttonIcon,
                        // )
                      )
                    : _selected == item
                        ? Padding(
                            padding: const EdgeInsets.all(0), //5, //5
                            child: Icon(
                              Icons.check_circle,
                              color: globalState.theme.buttonIcon,
                            ))
                        : _selected != item
                            ? Padding(
                                padding: const EdgeInsets.all(0), //5, //5
                                child: Icon(
                                  Icons.circle_outlined,
                                  color: globalState.theme.buttonIcon,
                                ))
                            : Container(),
              ]));
        });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      //appBar: topAppBar,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _toggleIcons && widget.slideUpPanel == false
                  ? Row(children: [
                      IconButton(
                        color: globalState.theme.background,
                        onPressed: () {
                          if (widget.slideUpPanel == false) {
                            setState(() {
                              //_selectedObjects = [];
                              _selected = null;
                              _toggleIcons = false;
                            });

                            if (widget.updateSelected != null) {
                              widget.updateSelected!(_emptyList);
                            }
                          }
                        },
                        icon: Icon(
                          Icons.cancel,
                          color: globalState.theme.buttonIcon,
                        ),
                      ),
                      const Spacer(),
                      widget.slideUpPanel == false
                          ? Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    ShareCircleObject.shareToDestination(
                                        context,
                                        _selected!.userCircleCache!,
                                        _selected!,
                                        true);
                                  },
                                  child: Icon(Icons.share,
                                      size: _iconSize,
                                      color: globalState.theme.buttonIcon)))
                          : Container(),
                    ])
                  : Container(),
              //header,
              // Spacer(),
              Expanded(
                child: makeList,
              ),
            ],
          )),
    );
  }

  void _tapHandler(int index, CircleObject circleObject) async {
    if (_toggleIcons) {
      if (circleObject != _selected) {
        setState(() {
          _selected = circleObject;
        });
      } else if (circleObject == _selected) {
        setState(() {
          _selected = null;
          if (widget.slideUpPanel == false) _toggleIcons = false;
        });
      }

      if (widget.updateSelected != null) {
        if (_selected != null) {
          widget.updateSelected!([_selected!]);
        } else {
          widget.updateSelected!(_emptyList);
        }
      }
    } else {
      ///don't open a vote for someone getting voted out
      if (circleObject.vote!.type != CircleVoteType.REMOVEMEMBER) {
        if (circleObject.vote!.object != circleObject.userFurnace!.userid!) {
          var value = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CircleVoteScreen(
                  circleObject: circleObject,
                  userCircleCache: circleObject.userCircleCache!,
                  userFurnace: circleObject.userFurnace!,
                  screenMode: ScreenMode.EDIT,
                ),
              ));

          if (value != null) {
            setState(() {});
          }
        }
      }
    }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons) {
        _selected = null;
        if (widget.slideUpPanel == false) _toggleIcons = false;
      } else {
        _selected = circleObject;
        _toggleIcons = !_toggleIcons;
      }
    });

    if (widget.updateSelected != null) {
      if (_selected != null) {
        widget.updateSelected!([_selected!]);
      } else {
        widget.updateSelected!(_emptyList);
      }
    }
  }
}
