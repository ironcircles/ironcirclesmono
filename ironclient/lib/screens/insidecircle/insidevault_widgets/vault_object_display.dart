import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipetemplate_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/fullscreen/pdfviewer.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_edit_tabs.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_new.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlerecipescreen.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/subtype_credential.dart';
import 'package:ironcirclesapp/screens/insidecircle/dialoghandlefile.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidecircle_widgets/circleobject_body.dart';
import 'package:ironcirclesapp/screens/insidecircle/localsearch.dart';
import 'package:ironcirclesapp/screens/utilities/populatemedia.dart';
import 'package:ironcirclesapp/screens/utilities/sharecircleobject.dart';
import 'package:ironcirclesapp/screens/walkthroughs/insidecircle_walkthrough.dart';
import 'package:ironcirclesapp/screens/widgets/backwithdoticon.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/link_widget.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/utils/emojiutil.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

enum DisplayType { Notes, Recipes, Credentials, Lists, Links, Files, AgoraCalls }

class VaultObjectDisplay extends StatefulWidget {
  final DisplayType displayType;
  final UserFurnace userFurnace;
  final List<CircleObject>? circleObjects;
  final GlobalEventBloc globalEventBloc;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;
  final CircleImageBloc circleImageBloc;
  final CircleVideoBloc circleVideoBloc;
  final CircleObjectBloc circleObjectBloc;
  final CircleFileBloc circleFileBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final bool shuffle;
  final UserCircleCache userCircleCache;
  final Function unpinObject;
  final Function send;
  final Function? sendLink;
  final CircleRecipeBloc circleRecipeBloc;
  final UserCircleBloc userCircleBloc;
  final CircleListBloc circleListBloc;
  final Function deleteObject;
  final Function downloadFile;
  final Function export;
  final Function pickFiles;
  final String sharedText;
  final bool Function(ScrollEndNotification) onNotification;
  final Future<void> Function() refresh;
  final CircleObject? scrollToObject;

  const VaultObjectDisplay({
    required this.refresh,
    required this.deleteObject,
    required this.userCircleCache,
    required this.displayType,
    required this.userFurnace,
    required this.circleObjects,
    required this.globalEventBloc,
    required this.videoControllerBloc,
    required this.videoControllerDesktopBloc,
    required this.circleAlbumBloc,
    required this.circleVideoBloc,
    required this.circleImageBloc,
    required this.circleObjectBloc,
    required this.circleFileBloc,
    required this.shuffle,
    required this.unpinObject,
    required this.pickFiles,
    required this.downloadFile,
    required this.export,
    required this.send,
    this.sendLink,
    this.sharedText = '',
    this.scrollToObject,
    required this.circleRecipeBloc,
    required this.userCircleBloc,
    required this.circleListBloc,
    required this.onNotification,
    Key? key,
  }) : super(key: key);

  @override
  VaultObjectDisplayState createState() => VaultObjectDisplayState();
}

class VaultObjectDisplayState extends State<VaultObjectDisplay> {
  final double _floatingActionSize = 55;

  //ScrollController _scrollController = ScrollController();
  late InsideCircleWalkthrough _insideCircleWalkthrough;
  CircleObject? _selected;
  final double _iconSize = 25;
  final double _iconPadding = 12;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final CircleRecipeTemplateBloc _circleRecipeTemplateBloc =
      CircleRecipeTemplateBloc();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  CircleObject? _lastSelected;

  final ItemScrollController _itemScrollController = ItemScrollController();

  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  CircleObject? _editingObject;
  bool _editing = false;
  bool _sendEnabled = false;
  final _message = TextEditingController();
  late FocusNode _focusNode;

  bool filter = false;
  List<CircleObject> _circleObjects = [];
  bool _toggleIcons = false;

  int _lastIndex = 0;
  bool _alreadyScrolled = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _itemPositionsListener.itemPositions.addListener(() {
      _calculateDirection();
    });

    _insideCircleWalkthrough = InsideCircleWalkthrough(_finish);
    _focusNode = FocusNode();
    super.initState();

    if (!widget.shuffle) {
      _circleObjects.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });
    }

    widget.circleObjectBloc.refreshVault.listen((refresh) async {
      if (mounted) {
        setState(() {});
      }
    }, onError: (err) {
      //_clearSpinner();
      debugPrint("CentralCalendar._firebaseBloc.calendarRefresh: $err");
    }, cancelOnError: false);

    if (widget.displayType == DisplayType.Links ||
        widget.displayType == DisplayType.Notes) {
      ///Something was shared
      if (widget.sharedText.isNotEmpty) {
        _message.text = widget.sharedText;
        _sendEnabled = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToObject != null && _alreadyScrolled == false) {
        _alreadyScrolled = true;

        int index = _circleObjects.indexWhere(
            (element) => element.seed == widget.scrollToObject!.seed);

        if (index >= 0) {
          _scrollToIndex(index);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _circleRecipeTemplateBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 75;

    IconData icon = Icons.cancel;
    _circleObjects = [];
    _circleObjects.addAll(widget.circleObjects!);
    if (widget.displayType == DisplayType.Notes) {
      _circleObjects.retainWhere((element) =>
          ((element.type == CircleObjectType.CIRCLEMESSAGE &&
              element.subType == null)));
    } else if (widget.displayType == DisplayType.Recipes) {
      _circleObjects.retainWhere(
          (element) => (element.type == CircleObjectType.CIRCLERECIPE));
      icon = Icons.restaurant;
    } else if (widget.displayType == DisplayType.Credentials) {
      _circleObjects.retainWhere((element) => (element.subType != null));
      icon = Icons.login;
    } else if (widget.displayType == DisplayType.Lists) {
      _circleObjects.retainWhere(
          (element) => (element.type == CircleObjectType.CIRCLELIST));
      icon = Icons.assignment;
    } else if (widget.displayType == DisplayType.Links) {
      _circleObjects.retainWhere(
          (element) => (element.type == CircleObjectType.CIRCLELINK));

      // debugPrint('THERE SHOULD BE ${_circleObjects.length} LINKS');
    } else if (widget.displayType == DisplayType.Files) {
      _circleObjects.retainWhere(
          (element) => (element.type == CircleObjectType.CIRCLEFILE));

      // debugPrint('THERE SHOULD BE ${_circleObjects.length} LINKS');
    } else if (widget.displayType == DisplayType.AgoraCalls) {
      _circleObjects.retainWhere(
          (element) => (element.type == CircleObjectType.CIRCLEAGORACALL));
      icon = Icons.videocam;
    }

    debugPrint('THERE SHOULD BE ${_circleObjects.length} FILTERED OBJECTS');

    ListTile makeFileTile(int index, CircleObject object) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          leading: Container(
            padding: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        width: 1.0, color: globalState.theme.cardSeparator))),
            child: Icon(Icons.attach_file_rounded,
                color: globalState.theme.cardLeadingIcon),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              object.file!.name!,
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
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
                          widget.userFurnace.alias!,
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              color: globalState.theme.furnace), //furnace
                        ))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          '${object.date!} ${object.time!}',
                          textScaler: const TextScaler.linear(1.0),
                          style: TextStyle(
                              color: globalState.theme.cardLabel), //furnace
                        ))),
              ],
            ),
            // Row(
            //   children: <Widget>[
            //     Expanded(
            //         flex: 1,
            //         child: Padding(
            //             padding: const EdgeInsets.only(
            //                 left: 5.0, bottom: 5, top: 10),
            //             child: Text(
            //               'updated: ${object.date!} ${object.time!}',
            //               textScaler: const TextScaler.linear(1.0),
            //               style: TextStyle(
            //                   color: globalState.theme.cardLabel), //furnace
            //             ))),
            //   ],
            // ),
          ]),
          trailing: Icon(Icons.keyboard_arrow_right,
              color: globalState.theme.cardTrailingIcon, size: 30.0),
          onLongPress: () {
            _longPress(object);
          },
          onTap: () {
            _tapHandler(index, object);
          },
        );

    Card makeFileCard(int index, CircleObject object) => Card(
        surfaceTintColor: Colors.transparent,
        color: globalState.theme.card,
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          makeFileTile(index, object),
        ]));

    ListTile makeListTile(int index, CircleObject object) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          leading: Container(
              padding: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          width: 1.0, color: globalState.theme.cardSeparator))),
              child: Icon(icon, color: globalState.theme.cardLeadingIcon)),
          title: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              widget.displayType == DisplayType.Recipes
                  ? object.recipe!.name!
                  : widget.displayType == DisplayType.Lists
                      ? object.list!.name!
                      : widget.displayType == DisplayType.Links
                          ? object.link!.title!
                          : widget.displayType == DisplayType.Notes
                              ? object.body!
                              : object.subString1!,
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
                    flex: 0,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          //object.userFurnace!.alias!
                          widget.userFurnace.alias!,
                          textScaler:
                              TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.furnace),
                        ))),
              ],
            ),
            // Row(
            //   children: <Widget>[
            //     Expanded(
            //         flex: 8,
            //         child: Padding(
            //             padding: const EdgeInsets.only(
            //                 left: 5.0, bottom: 5, top: 10),
            //             child: Text(
            //               //object.userCircleCache!.prefName!
            //               'created ' + DateFormat.yMMMd()
            //                   .format(object.created!) + ' ' + (object.created == null ? '' : globalState.language == Language.ENGLISH ?  DateFormat.jm().format(object.created!.toLocal()) : DateFormat('HH:mm').format(object.created!.toLocal())),
            //               textScaler:
            //                   TextScaler.linear(globalState.cardScaleFactor),
            //               style: TextStyle(color: globalState.theme.textTitle),
            //             ))),
            //   ],
            // ),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 5, top: 10),
                        child: Text(
                          //object.userCircleCache!.prefName!
                          '${object.date!} ${object.lastUpdate == null ? '' : object.lastUpdatedTime}',
                          textScaler:
                              TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.textTitle),
                        ))),
              ],
            ),
          ]),
          trailing: Icon(Icons.keyboard_arrow_right,
              color: globalState.theme.cardTrailingIcon, size: 30.0),
          onLongPress: () {
            _longPress(object);
          },
          onTap: () {
            //openDetail(context, userFurnace);
            _tapHandler(index, object);
          },
        );

    Stack makeNoteCard(int index, CircleObject object) => Stack(children: [
          Card(
              surfaceTintColor: Colors.transparent,
              //color: globalState.theme.cardAlternate,
              elevation: 8.0,
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              // child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              //   makeNoteTile(index, object),
              // ])
              child: GestureDetector(
                onLongPress: () {
                  _longPress(object);
                },
                onTap: () {
                  //openDetail(context, userFurnace);
                  _tapHandler(index, object);
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: globalState.theme.userObjectBackground,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(5.0),
                            bottomRight: Radius.circular(5.0),
                            topLeft: Radius.circular(5.0),
                            topRight: Radius.circular(5.0))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                Stack(
                                    alignment: Alignment.topLeft,
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Column(children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10, left: 7),
                                            child: Row(children: [
                                              Expanded(
                                                  child: ICText(
                                                '${object.date!} @ ${object.time}',
                                                textScaleFactor: globalState
                                                    .messageScaleFactor,
                                                //color: globalState.theme.userObjectText,
                                              ))
                                            ]),
                                          ),
                                          Row(children: [
                                            Expanded(
                                                child: Container(
                                                    padding: const EdgeInsets.only(
                                                        left: 15.0,
                                                        right: 15.0,
                                                        bottom: 10.0,
                                                        top: 10.0),
                                                    decoration: BoxDecoration(
                                                        color: globalState.theme
                                                            .userObjectBackground,
                                                        borderRadius: const BorderRadius
                                                            .only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    5.0),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    5.0),
                                                            topLeft:
                                                                Radius.circular(
                                                                    5.0),
                                                            topRight:
                                                                Radius.circular(
                                                                    5.0))),
                                                    child: ICText(
                                                      object.body!,
                                                      textScaleFactor: globalState
                                                          .messageScaleFactor,
                                                      color: globalState
                                                          .theme.userObjectText,
                                                    ))),
                                          ])
                                        ]),
                                      ),
                                    ])
                              ]))
                        ])),
              )),
          object.id == null
              ? Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    radius: 7.0,
                    backgroundColor: globalState.theme.sentIndicator,
                  ))
              : Container()
        ]);

    Stack makeCard(int index, CircleObject object) => Stack(children: [
          Card(
              surfaceTintColor: Colors.transparent,
              color: globalState.theme.card,
              elevation: 8.0,
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                makeListTile(index, object),
              ])),
          object.id == null
              ? Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    radius: 7.0,
                    backgroundColor: globalState.theme.sentIndicator,
                  ))
              : Container()
        ]);

    Stack makeLinkCard(int index, CircleObject object) {
      return Stack(children: [
        Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                      margin: const EdgeInsets.only(bottom: 6.0),
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                          color: globalState.theme.card,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10.0),
                              bottomRight: Radius.circular(10.0),
                              topLeft: Radius.circular(10.0),
                              topRight: Radius.circular(10.0))),
                      child: InkWell(
                          // onTap: () => LaunchURLs.launchURLForCircleObject(
                          //     context, circleObject),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                            Padding(
                                padding: EdgeInsets.only(
                                    top: index == 0 ? 0 : 15, bottom: 5
                                    //bottom: Library.getPadding(width)
                                    ),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                          child: ICText(
                                        '${object.date!} @ ${object.time}',
                                      )),
                                    ])),
                            object.body!.isNotEmpty
                                ? Padding(
                                    padding: EdgeInsets.only(
                                      top: index == 0 ? 0 : 0,
                                      //bottom: Library.getPadding(width)
                                    ),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: CircleObjectBody(
                                                circleObject: object,
                                                userCircleCache:
                                                    widget.userCircleCache,
                                                messageColor: globalState
                                                    .theme.userObjectText,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                maxWidth: 275),
                                          ),
                                        ]))
                                : Container(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  LinkWidget(
                                    longPress: _longPress,
                                    shortPress: _shortPress,
                                    anythingSelected: _selected != null,
                                    // > 0, _selectedObjects.length == 1
                                    isSelected: _selected == object,
                                    //.contains(circleObject)
                                    circleObject: object,
                                    libraryObjects: _circleObjects,
                                    isSelecting:
                                        _selected != null, //.length == 1
                                  )
                                ])
                          ])))
                ])),
        object.id == null
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: CircleAvatar(
                      radius: 7.0,
                      backgroundColor: globalState.theme.sentIndicator,
                    )))
            : Container(),
      ]);
    }

    final makeList = Stack(children: [
      RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: widget.refresh,
          color: globalState.theme.buttonIcon,
          child: _circleObjects.isEmpty
              ? Center(
                  child: Container(
                      decoration: BoxDecoration(
                        color: globalState.theme.background,
                      ),
                      child: _showSpinner ? spinkit : Container()))
              : NotificationListener<ScrollEndNotification>(
                  onNotification: widget.onNotification,
                  child: ScrollablePositionedList.separated(
                      itemCount: _circleObjects.length,
                      reverse: false, //true
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      physics: const AlwaysScrollableScrollPhysics(),
                      separatorBuilder: (context, index) {
                        return Container(
                          color: globalState.theme.background,
                          width: double.maxFinite,
                        );
                      },
                      itemBuilder: (context, index) {
                        final CircleObject item = _circleObjects[index];

                        return Stack(children: [
                          widget.displayType == DisplayType.Recipes ||
                                  widget.displayType == DisplayType.Lists ||
                                  widget.displayType == DisplayType.Credentials
                              ? makeCard(index, item)
                              : widget.displayType == DisplayType.Links
                                  ? makeLinkCard(index, item)
                                  : widget.displayType == DisplayType.Notes
                                      ? makeNoteCard(index, item)
                                      : makeFileCard(index, item),
                          _selected == null ||
                                  widget.displayType == DisplayType.Links
                              ? const Padding(
                                  padding: EdgeInsets.all(0),
                                )
                              : _selected == item
                                  ? Padding(
                                      padding: const EdgeInsets.all(0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: globalState.theme.buttonIcon,
                                      ))
                                  : _selected != item
                                      ? Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Icon(
                                            Icons.circle_outlined,
                                            color: globalState.theme.buttonIcon,
                                          ))
                                      : Container(),
                        ]);
                      })))
    ]);

    _openLocalSearch() async {
      CircleObject? circleObject = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LocalSearch(
                  type: widget.displayType.name,
                  //mode: widget.displayType,
                  userCircleCache: widget.userCircleCache,
                  userFurnace: widget.userFurnace,
                  circleObjectBloc: widget.circleObjectBloc,
                  userMessageColors: [widget.userFurnace.user],
                  //members
                  circle: widget.userCircleCache.cachedCircle!,
                  //_circle
                  videoControllerBloc: widget.videoControllerBloc,
                  videoControllerDesktopBloc: widget.videoControllerDesktopBloc,
                  globalEventBloc: widget.globalEventBloc,
                  circleVideoBloc: widget.circleVideoBloc,
                  circleImageBloc: widget.circleImageBloc,
                  circleRecipeBloc: widget.circleRecipeBloc,
                  circleFileBloc: widget.circleFileBloc,
                  circleAlbumBloc: widget.circleAlbumBloc,
                  unpinObject: widget.unpinObject,
                  populateFile: PopulateMedia.populateFile,
                  populateImageFile: PopulateMedia.populateImageFile,
                  populateVideoFile: PopulateMedia.populateVideoFile,
                  populateAlbum: PopulateMedia.populateAlbum,
                  populateRecipeImageFile:
                      PopulateMedia.populateRecipeImageFile,
                  searchText: "")));

      if (circleObject != null) {
        int index = _circleObjects
            .indexWhere((element) => element.seed == circleObject.seed);

        if (index >= 0) _scrollToIndex(index);
      }
    }

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: AppBar(
              elevation: 0,
              toolbarHeight: 45,
              centerTitle: false,
              titleSpacing: 0.0,
              backgroundColor: globalState.theme.background,
              title: Text(widget.displayType.name,
                  style: ICTextStyle.getStyle(
                      context: context,
                      color: globalState.theme.textTitle,
                      fontSize: ICTextStyle.appBarFontSize)),
              leading: BackWithDotIcon(
                userFurnaces: [widget.userFurnace],
                goHome: () {
                  _goHome(true);
                },
                forceRefresh: false, //should it be true?
                circleID: widget.userCircleCache.circle!,
              ),
              actions: <Widget>[
                IconButton(
                    key: _insideCircleWalkthrough.keyButton7,
                    icon:
                        Icon(Icons.search, color: globalState.theme.menuIcons),
                    onPressed: _openLocalSearch),
              ]),
          //drawer: NavigationDrawer(),
          body: Padding(
              padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _toggleIcons
                      ? Row(children: [
                          IconButton(
                            color: globalState.theme.background,
                            onPressed: () {
                              setState(() {
                                //_selectedObjects = [];
                                _selected = null;
                                _toggleIcons = false;
                              });
                            },
                            icon: Icon(
                              Icons.cancel,
                              color: globalState.theme.buttonIcon,
                            ),
                          ),
                          const Spacer(),
                          Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    widget.deleteObject(_selected!);
                                    deleteEffect();
                                  },
                                  child: Icon(Icons.delete,
                                      color: globalState.theme.buttonIcon))),
                          Padding(
                              padding: EdgeInsets.only(left: _iconPadding),
                              child: InkWell(
                                  onTap: () {
                                    ShareCircleObject.shareToDestination(
                                        context,
                                        widget.userCircleCache,
                                        //_selected!.userCircleCache!
                                        _selected!,
                                        true);
                                  },
                                  child: Icon(Icons.share,
                                      size: _iconSize,
                                      color: globalState.theme.buttonIcon))),
                          widget.displayType == DisplayType.Notes
                              ? Padding(
                                  padding: EdgeInsets.only(left: _iconPadding),
                                  child: InkWell(
                                      onTap: () {
                                        _editObject(_selected!);
                                      },
                                      child: Icon(Icons.edit,
                                          size: _iconSize,
                                          color: globalState.theme.buttonIcon)))
                              : Container()
                        ])
                      : Container(),
                  //header,
                  // Spacer(),
                  Expanded(
                    child: makeList,
                  ),
                  Container(
                    child: widget.displayType == DisplayType.Links ||
                            widget.displayType == DisplayType.Notes
                        ? Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                              color: globalState.theme.buttonIcon,
                            ))),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 0,
                                          top: 10,
                                          bottom: 0),
                                      child: Row(children: <Widget>[
                                        Expanded(
                                          flex: 100,
                                          child: Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxHeight: 125),
                                                    child: TextField(
                                                        cursorColor: globalState
                                                            .theme.textField,
                                                        controller: _message,
                                                        focusNode: _focusNode,
                                                        textInputAction: globalState
                                                                .isDesktop()
                                                            ? TextInputAction
                                                                .done
                                                            : TextInputAction
                                                                .newline,
                                                        maxLines: null,
                                                        onSubmitted: (text) {
                                                          if (globalState
                                                              .isDesktop()) {
                                                            _send(widget
                                                                .displayType);
                                                          }
                                                        },
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        style: TextStyle(
                                                            fontSize: (globalState
                                                                        .userSetting
                                                                        .fontSize /
                                                                    globalState
                                                                        .mediaScaleFactor) *
                                                                globalState
                                                                    .textFieldScaleFactor,
                                                            color: globalState
                                                                .theme
                                                                .userObjectText),
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: globalState
                                                              .theme
                                                              .messageBackground,
                                                          hintText:
                                                              'stash in vault',
                                                          hintStyle: TextStyle(
                                                              color: globalState
                                                                  .theme
                                                                  .messageTextHint),
                                                          contentPadding:
                                                              EdgeInsets.only(
                                                                  left: 14,
                                                                  bottom: 10,
                                                                  top: 10,
                                                                  right:
                                                                      _sendEnabled
                                                                          ? 42
                                                                          : 0),
                                                          focusedBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: globalState
                                                                    .theme
                                                                    .messageBackground),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          enabledBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: globalState
                                                                    .theme
                                                                    .messageBackground),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        onChanged: (text) {
                                                          bool enableSend =
                                                              true;

                                                          if (text.isEmpty) {
                                                            if (_editing) {
                                                              if (_editingObject !=
                                                                  null) {
                                                                if (_editingObject!
                                                                        .type ==
                                                                    CircleObjectType
                                                                        .CIRCLEMESSAGE) {
                                                                  enableSend =
                                                                      false;
                                                                }
                                                              }
                                                            } else {
                                                              enableSend =
                                                                  false;
                                                            }
                                                          } else {
                                                            String testText = text
                                                                .toLowerCase()
                                                                .replaceAll(
                                                                    " ", "");
                                                            if (testText
                                                                    .isEmpty ||
                                                                testText ==
                                                                    "\n") {
                                                              enableSend =
                                                                  false;
                                                            } else {
                                                              enableSend = true;
                                                            }
                                                            if (enableSend !=
                                                                _sendEnabled) {
                                                              setState(() {
                                                                _sendEnabled =
                                                                    enableSend;
                                                              });
                                                            }
                                                          }
                                                        })),
                                                // _sendEnabled
                                                //     ? IconButton(
                                                //         icon: Icon(
                                                //             Icons
                                                //                 .cancel_rounded,
                                                //             color: globalState
                                                //                 .theme
                                                //                 .buttonDisabled),
                                                //         iconSize: 22,
                                                //         onPressed: () {
                                                //           _clear(true);
                                                //         },
                                                //       )
                                                //     : Container(),
                                              ]),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.only(left: 8)),
                                        Column(children: <Widget>[
                                          _editingObject == null
                                              ? SizedBox(
                                                  height: 40,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.send_rounded,
                                                      size: 30,
                                                      color: _sendEnabled
                                                          ? globalState.theme
                                                              .bottomHighlightIcon
                                                          : globalState.theme
                                                              .buttonDisabled,
                                                    ),
                                                    onPressed: () {
                                                      _send(widget.displayType);
                                                    },
                                                  ))
                                              : SizedBox(
                                                  height: 40,
                                                  child: TextButton(
                                                    child: Text(
                                                      'EDIT',
                                                      textScaler:
                                                          const TextScaler
                                                              .linear(1.0),
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color: _sendEnabled
                                                              ? globalState
                                                                  .theme
                                                                  .bottomHighlightIcon
                                                              : globalState
                                                                  .theme
                                                                  .buttonDisabled),
                                                    ),
                                                    onPressed: () {
                                                      // widget.send(); //_send(widget.displayType);
                                                      _send(widget.displayType);
                                                    },
                                                  )),
                                        ]),
                                        const Padding(
                                            padding: EdgeInsets.only(left: 5)),
                                      ])),
                                  const Padding(
                                      padding: EdgeInsets.only(bottom: 5)),
                                ]))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: _floatingActionSize,
                                height: _floatingActionSize,
                                child: FloatingActionButton(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30.0))),
                                  //key: widget.walkthrough.add,
                                  heroTag: null,
                                  onPressed: () async {
                                    widget.displayType == DisplayType.Files
                                        ? widget.pickFiles()
                                        : await Navigator.push(
                                            context,
                                            widget.displayType ==
                                                    DisplayType.Credentials
                                                ? MaterialPageRoute(
                                                    builder: (context) =>
                                                        SubtypeCredential(
                                                          //userFurnaces: widget.userFurnaces,
                                                          //circleObject: widget.circleObjects!.first, //widget.circleObjects!.first
                                                          circleObjectBloc: widget
                                                              .circleObjectBloc,
                                                          userCircleCache: widget
                                                              .userCircleCache,
                                                          userFurnace: widget
                                                              .userFurnace,
                                                          userCircleBloc: widget
                                                              .userCircleBloc,
                                                          userFurnaces: [
                                                            widget.userFurnace
                                                          ],
                                                          screenMode:
                                                              ScreenMode.ADD,
                                                          globalEventBloc: widget
                                                              .globalEventBloc,
                                                          //update: _update,
                                                          timer: 0,
                                                          replyObject: null,
                                                          //circleRecipeBloc: _circleRecipeBloc,
                                                        ))
                                                : widget.displayType ==
                                                        DisplayType.Recipes
                                                    ? MaterialPageRoute(
                                                        builder: (context) =>
                                                            CircleRecipeScreen(
                                                              userFurnaces: [
                                                                widget
                                                                    .userFurnace
                                                              ],
                                                              circleObjectBloc:
                                                                  widget
                                                                      .circleObjectBloc,
                                                              userCircleCache:
                                                                  widget
                                                                      .userCircleCache,
                                                              userFurnace: widget
                                                                  .userFurnace,
                                                              screenMode:
                                                                  ScreenMode
                                                                      .ADD,
                                                              circleRecipeBloc:
                                                                  widget
                                                                      .circleRecipeBloc,
                                                              globalEventBloc:
                                                                  widget
                                                                      .globalEventBloc,
                                                              //update: _update,
                                                              timer: 0,
                                                              //_timer
                                                              replyObject: null,
                                                            ))
                                                    : //widget.displayType == "Lists" ?
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            CircleListNew(
                                                          userFurnace: widget
                                                              .userFurnace,
                                                          circleObjectBloc: widget
                                                              .circleObjectBloc,
                                                          userCircleCache: widget
                                                              .userCircleCache,
                                                          circleObject: null,
                                                          userFurnaces: [
                                                            widget.userFurnace
                                                          ],
                                                          circleListBloc: widget
                                                              .circleListBloc,
                                                          //update: _update,
                                                          // refresh:
                                                          //     widget.refreshObjects(),
                                                          timer: 0,
                                                          replyObject: null,
                                                        ),
                                                      ));
                                    setState(() {});
                                  },
                                  backgroundColor: globalState.theme.homeFAB,
                                  child: Icon(
                                    Icons.add,
                                    size: _iconSize +
                                        5 -
                                        globalState.scaleDownIcons,
                                    color: globalState.theme.background,
                                  ),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.only(right: 10))
                            ],
                          ),
                  ),
                ],
              )),
        ));
  }

  _calculateDirection() {
    //debugPrint(_itemPositionsListener.itemPositions.value.first.index);

    if (_itemPositionsListener.itemPositions.value.isEmpty) return;

    _lastIndex = _itemPositionsListener.itemPositions.value.first.index;
  }

  /*_closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

   */

  void _editObject(CircleObject circleObject) async {
    String? body;
    //_clearPreviews();
    body = circleObject.body;
    setState(() {
      _editingObject = circleObject;
      if (body != null) _message.text = body;
      _sendEnabled = true;
      _editing = true;
      _focusNode.requestFocus();
    });
  }

  // _update(CircleObject circleObject) {
  //   setState(() {
  //     _circleObjects.add(circleObject);
  //   });
  // }

  void _scrollToIndex(int index) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (index != -1)
      setState(() {
        _itemScrollController.scrollTo(
            index: index,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutCubic);
      });
  }

  CircleLink? _checkForLink() {
    CircleLink? circleLink;

    try {
      final exp = RegExp(
          r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");

      Iterable<RegExpMatch> matches = exp.allMatches(_message.text);

      for (var match in matches) {
        circleLink = CircleLink();
        circleLink.url = _message.text.substring(match.start, match.end);

        break;
      }

      if (circleLink != null) {
        if (circleLink.url != null) {
          String temp = _message.text.replaceAll(circleLink.url!, '');

          //if (temp != null) {
          if (temp != '') circleLink.body = temp;
          //}
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("InsideCircle._checkForLink: $err");
    }

    return circleLink;
  }

  _clear(bool closeKeyboard) {
    setState(() {
      _message.text = '';
      _message.clear();
      _sendEnabled = false;
      _editingObject = null;
      //_cancelEnabled = false;
      _editing = false;
      //_showEmojiPicker = false;
      if (_lastSelected != null) _lastSelected!.showOptionIcons = false;
      //_replyObject = null;

      //_clearPreviews();
    });
  }

  Future<CircleObject> _prepNewCircleObject({bool skipBody = false}) async {
    String messageText = '';

    if (!skipBody) messageText = _message.text;

    CircleObject newCircleObject = CircleObject.prepNewCircleObject(
        widget.userCircleCache,
        widget.userFurnace,
        messageText,
        _circleObjects.length - 1,
        null);

    newCircleObject.emojiOnly =
        await EmojiUtil.checkForOnlyEmojis(_message.text);

    return newCircleObject;
  }

  void _tapHandler(int index, CircleObject object) async {
    object.userCircleCache = widget.userCircleCache;
    if (object.id != null) {
      if (_toggleIcons) {
        if (object != _selected) {
          setState(() {
            _selected = object;
          });
        } else if (object == _selected) {
          setState(() {
            _selected = null;
            _toggleIcons = false;
          });
        }
      } else {
        if (widget.displayType == DisplayType.Files) {
          if (object.file!.extension! == 'pdf') {
            _openPDF(object, true);
          } else {
            _handleFile(object);
          }
        } else if (widget.displayType == DisplayType.Notes) {
          _selected = null;
        } else {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      widget.displayType == DisplayType.Recipes
                          ? CircleRecipeScreen(
                              //template: object,
                              circleObject: object,
                              userFurnace: widget.userFurnace,
                              userCircleCache: widget.userCircleCache,
                              circleObjectBloc: widget.circleObjectBloc,
                              userFurnaces: [widget.userFurnace],
                              //screenMode: ScreenMode.TEMPLATE,
                              screenMode: ScreenMode.EDIT,
                              circleRecipeBloc:
                                  CircleRecipeBloc(widget.globalEventBloc),
                              globalEventBloc: widget.globalEventBloc,
                              timer: UserDisappearingTimer.OFF,
                              replyObject: null,
                              //update: _update,
                            )
                          : widget.displayType == DisplayType.Credentials
                              ? SubtypeCredential(
                                  //userFurnaces: widget.userFurnaces,
                                  circleObject: object,
                                  circleObjectBloc: widget.circleObjectBloc,
                                  userCircleCache: widget.userCircleCache,
                                  userFurnace: widget.userFurnace,
                                  userCircleBloc: widget.userCircleBloc,
                                  screenMode: ScreenMode.EDIT,
                                  userFurnaces: [widget.userFurnace],
                                  //ScreenMode.EDIT, TEMPLATE
                                  globalEventBloc: widget.globalEventBloc,
                                  timer: 0,
                                  replyObject: null,
                                  //circleRecipeBloc: _circleRecipeBloc,
                                )
                              : CircleListEditTabs(
                                  circleObject: object,
                                  userCircleCache: widget.userCircleCache,
                                  userFurnace: widget.userFurnace,
                                  isNew: true,
                                  readOnly: false,
                                )));

          setState(() {});

          _circleRecipeTemplateBloc.sinkCache([widget.userFurnace]);
          //do I need this, and do i need more of these?
        }
      }
    } else if (object.draft == true) {
      widget.circleObjects!.remove(object);
      widget.circleObjectBloc.deleteDraft(object);

      if (object.type == CircleObjectType.CIRCLERECIPE) {
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CircleRecipeScreen(
                circleObject: object,
                //_circleObjects[index],
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                screenMode: ScreenMode.ADD,
                userFurnaces: [widget.userFurnace],
                circleRecipeBloc: widget.circleRecipeBloc,
                circleObjectBloc: widget.circleObjectBloc,
                globalEventBloc: widget.globalEventBloc,
                timer: 0,
                replyObject: null,
              ),
            ));
      } else if (object.type == CircleObjectType.CIRCLELIST) {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CircleListNew(
                      userFurnace: widget.userFurnace,
                      userCircleCache: widget.userCircleCache,
                      circleObject: object,
                      circleObjectBloc: widget.circleObjectBloc,
                      userFurnaces: [widget.userFurnace],
                      circleListBloc: widget.circleListBloc,
                      timer: 0,
                      replyObject: null,
                    )));
      } else if (object.subType != null &&
          object.subType == SubType.LOGIN_INFO) {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SubtypeCredential(
                    //userFurnaces: widget.userFurnaces,
                    circleObject: object,
                    circleObjectBloc: widget.circleObjectBloc,
                    userCircleCache: widget.userCircleCache,
                    userFurnace: widget.userFurnace,
                    userCircleBloc: widget.userCircleBloc,
                    screenMode: ScreenMode.ADD,
                    userFurnaces: [widget.userFurnace],
                    globalEventBloc: widget.globalEventBloc,
                    timer: 0,
                    replyObject: null,
                    //circleRecipeBloc: _circleRecipeBloc,
                  )),
        );
      } /*else {
        _sendEnabled = true;

        if (circleObject.body != null) _message.text = circleObject.body!;

        if (circleObject.draftMediaCollection != null) {
          _mediaCollection = _mediaCollection ?? MediaCollection();
          _mediaCollection!.media = circleObject.draftMediaCollection!;

          _circleObjects.remove(circleObject);
          _circleObjectBloc.deleteDraft(circleObject);
        } else if (circleObject.gif != null) {
          _giphyOption = GiphyOption(
              preview: circleObject.gif!.giphy!,
              url: circleObject.gif!.giphy!,
              width: circleObject.gif!.width,
              height: circleObject.gif!.height);

          _circleObjects.remove(circleObject);
          _circleObjectBloc.deleteDraft(circleObject);
        }}*/

      if (mounted) setState(() {});
    }
  }

  _goHome(bool samePosition) async {
    debugPrint('***********POPPED****************');
    Navigator.pop(context);
    //widget.refresh();
  }

  _shortPress(CircleObject circleObject, Circle? circle) {
    if (_toggleIcons) {
      if (circleObject == _selected) {
        setState(() {
          _selected = null;
          _toggleIcons = false;
        });
      } else if (circleObject != _selected) {
        setState(() {
          _selected = circleObject;
        });
      }
    } else if (_toggleIcons == false) {
      LaunchURLs.launchURLForCircleObject(context, circleObject);
    }
  }

  _longPress(CircleObject circleObject) {
    setState(() {
      if (_toggleIcons) {
        _selected = null;
        _toggleIcons = false;
      } else {
        _selected = circleObject;
        _toggleIcons = !_toggleIcons;
      }
    });
  }

  _send(DisplayType displayType, {overrideButton = false}) async {
    if (_sendEnabled == false && overrideButton == false) return;

    setState(() {
      _sendEnabled = false;
    });

    //_firebaseBloc.removeNotification();
    CircleObject? circleObject;
    if (_editingObject != null) {
      circleObject = _editingObject;
      await _editAndClear(circleObject!);
      //await _editAndClear(circleObject!);
    } else {
      CircleLink? circleLink = _checkForLink();
      if (displayType == DisplayType.Links) {
        if (circleLink != null) {
          //_sendLink(circleLink);
          //circleLink. = CircleObjectType.CIRCLELINK;

          //widget.send(overrideButton: true, vaultObject: circleLink);
          widget.sendLink!(circleLink, null);
          // setState(() {
          //   //_circleObjects.remove(circleObject);
          //   //_circleObjects.add(circleObject!);
          // });
          _clear(false);
        } else {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.missingLinkFromText, "", 1, false);
          return;
        }
      } else if (displayType == DisplayType.Notes) {
        if (circleLink != null) {
          FormattedSnackBar.showSnackbarWithContext(
              context,
              AppLocalizations.of(context)!.noteShouldNotContainLink,
              "",
              1,
              false);
          return;
        } else {
          if (_message.text.isNotEmpty) {
            circleObject = await _prepNewCircleObject();

            circleObject.type = CircleObjectType.CIRCLEMESSAGE;
            widget.send(overrideButton: true, vaultObject: circleObject);

            _clear(false);
          }
        }
      }
    }
  }

  _editAndClear(CircleObject circleObject) async {
    bool ready = false;
    String body = _message.text;
    if (_message.text.isNotEmpty) {
      if (body.isNotEmpty) {
        circleObject.body = _message.text;
        ready = true;
      }
    }
    if (ready) {
      widget.circleObjectBloc
          .updateCircleObject(circleObject, widget.userFurnace);
      _clear(false);
      _toggleIcons = false;
      _selected = null;
    }
  }

  void deleteEffect() {
    setState(() {
      _toggleIcons = false;
      _selected = null;
    });
  }

  // void delete(CircleObject object) {
  //   if (widget.displayType == "Recipes") {
  //     widget.circleRecipeBloc.removeFromDeviceCache([object]);
  //   } else {
  //     /// for deleting credentials and links
  //     widget.circleObjectBloc.deleteCircleObject(
  //         widget.userCircleCache, widget.userFurnace, object);
  //   }
  //   setState(() {
  //     //_circleObjects.remove(circleObject);
  //     _circleObjects.remove(object);
  //     _toggleIcons = false;
  //     _selected = null;
  //   });
  //   setState(() {});
  // }

  // void _askToDelete(CircleObject object) async {
  //   DialogYesNo.askYesNo(
  //       context,
  //       "Confirm delete",
  //       "Are you sure you want to delete this object from the vault?",
  //       delete,
  //       null,
  //       object);
  // }

  _openPDF(CircleObject circleObject, bool download) async {
    File internal = File(FileCacheService.returnFilePath(
        widget.userCircleCache.circlePath!,
        '${circleObject.seed!}.${circleObject.file!.extension!}'));

    if (!internal.existsSync()) {
      if (download) {
        ///download the file
        widget.circleFileBloc.downloadFile(
            widget.userFurnace, widget.userCircleCache, circleObject);
      }

      return;
    }

    File external = File(FileCacheService.returnFilePath(
        widget.userCircleCache.circlePath!, circleObject.file!.name!));

    if (external.existsSync()) {
      external.deleteSync();
    }

    internal.copySync(external.path);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PDFViewer(
                  circleObject: circleObject,
                  userCircleCache: widget.userCircleCache,
                  name: circleObject.file!.name!,
                  path: external.path)));
    }
  }

  _handleFileResult(BuildContext context, CircleObject circleObject,
      HandleFile handleFile) async {
    if (mounted) {
      if (handleFile == HandleFile.download) {
        widget.export(circleObject);
      } else if (handleFile == HandleFile.inside) {
        ShareCircleObject.shareToDestination(
            context, widget.userCircleCache, circleObject, true);
      } else if (handleFile == HandleFile.outside) {
        ShareCircleObject.shareToDestination(
            context, widget.userCircleCache, circleObject, false);
      }
    }
  }

  _handleFile(CircleObject circleObject) async {
    File internal = File(FileCacheService.returnFilePath(
        widget.userCircleCache.circlePath!,
        '${circleObject.seed!}.${circleObject.file!.extension!}'));

    if (!internal.existsSync()) {
      widget.downloadFile(circleObject);
      return;
    }

    if (mounted) {
      DialogHandleFile.handleFilePopup(
          context, circleObject, _handleFileResult);
    }
  }

  void _finish() {
    //_circlesWalkthrough.tutorialCoachMark.show(context: context);
  }

  void _doNothing() {}
}
