import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/librarybloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
import 'package:ironcirclesapp/screens/library/centralcalendarscreen.dart';
import 'package:ironcirclesapp/screens/library/librarycredentials.dart';
import 'package:ironcirclesapp/screens/library/libraryfiles.dart';
import 'package:ironcirclesapp/screens/library/librarygallery.dart';
import 'package:ironcirclesapp/screens/library/librarylinks.dart';
import 'package:ironcirclesapp/screens/library/librarylists.dart';
import 'package:ironcirclesapp/screens/library/libraryrecipes.dart';
import 'package:ironcirclesapp/screens/library/libraryvotes.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

enum SelectedLibraryTab {
  gallery,
  links,
  files,
  lists,
  recipes,
  events,

  votes,
  credentials,
}

class LibraryScreen extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final UserFurnace? filteredFurnace;
  final Function refreshCallback;
  final bool slideUpPanel;
  final Function? updateSelected;
  final Function? updateTab;
  final CircleVideoBloc? circleVideoBloc;
  final Function? setEventDateTime;
  final bool showFilter;
  final List<CircleObject> crossObjects;

  const LibraryScreen({
    Key? key,
    required this.userFurnaces,
    required this.filteredFurnace,
    required this.refreshCallback,
    this.updateSelected,
    this.circleVideoBloc,
    this.slideUpPanel = false,
    this.showFilter = true,
    this.updateTab,
    required this.crossObjects,
    this.setEventDateTime,
  }) : super(key: key);

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late LibraryBloc _crossBloc;
  final List<CircleObject> _filteredCircleObjects = [];
  final List<CircleObject> _completeList = [];
  late GlobalEventBloc _globalEventBloc;
  late CircleVideoBloc _circleVideoBloc;
  late CircleObjectBloc _circleObjectBloc;
  late TabController _tabController;
  var _libraryGalleryKey = GlobalKey();
  var _libraryStaticKey = GlobalKey();

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  bool spinner = true;
  bool spinnerRefresh = false;
  bool firstLoad = true;

  List<UserCircleCache> _allUserCircles = [];
  final List<UserCircleCache> _networkFilteredUserCircles = [];

  ///filtered by user selection
  List<UserCircleCache> _selectedUserCircles = [];

  ///User picks
  UserFurnace? _filteredUserFurnace;

  bool _shuffle = false;

  ///got initial load, either from widget.crossObjects or from the database
  _processInitialLoad(List<CircleObject> circleObjects) {
    ///TODO uncomment when unique storage is finished
    final ids = <dynamic>{};
    circleObjects
        .retainWhere((x) => ids.add(x.storageID) || x.storageID == null);

    _filteredCircleObjects.clear();
    _completeList.clear();
    _completeList.addAll(circleObjects);
    _filteredCircleObjects.addAll(circleObjects);

    ///apply the network filter
    if (widget.filteredFurnace != null) {
      _networkFilteredUserCircles.clear();
      _networkFilteredUserCircles.addAll(_allUserCircles);
      _networkFilteredUserCircles.retainWhere(
          (element) => element.userFurnace! == widget.filteredFurnace!.pk);

      _filteredCircleObjects.retainWhere(
          (element) => element.userFurnace!.pk == widget.filteredFurnace!.pk);
    }

    if (_completeList.isNotEmpty) {
      ///for the first load only, grab the next set for the user so scrolling is smoother
      if (_selectedUserCircles.isNotEmpty) {
        _crossBloc.requestOlderThan(_selectedUserCircles, widget.userFurnaces,
            _filteredCircleObjects.last.created!);
      } else if (_networkFilteredUserCircles.isNotEmpty) {
        _crossBloc.requestOlderThan(_networkFilteredUserCircles,
            widget.userFurnaces, _filteredCircleObjects.last.created!);
      } else {
        _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
            _filteredCircleObjects.last.created!);
      }
    }

    if (mounted) {
      setState(() {
        spinner = false;
      });
    }
  }

  @override
  void initState() {
    try {
      _tabController = TabController(length: 8, initialIndex: 0, vsync: this);
      _tabController.addListener(_handleTabSelection);

      _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
      _crossBloc = LibraryBloc(globalEventBloc: _globalEventBloc);
      _circleObjectBloc = CircleObjectBloc(globalEventBloc: _globalEventBloc);
      _circleVideoBloc =
          widget.circleVideoBloc ?? CircleVideoBloc(_globalEventBloc);

      _globalEventBloc.memCacheCircleObjectsRemoveAllHidden.listen(
          (success) async {
        _allUserCircles.removeWhere((element) => element.hidden == true);
        _selectedUserCircles.removeWhere((element) => element.hidden == true);
        _networkFilteredUserCircles
            .removeWhere((element) => element.hidden == true);

        widget.crossObjects.clear();
      }, onError: (err) {
        debugPrint("error $err");
      }, cancelOnError: false);

      _crossBloc.allCircleObjects.listen((circleobjects) {
        if (circleobjects != null) {
          _processInitialLoad(circleobjects);
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.refreshWall.listen((success) {
        if (_filteredCircleObjects.isNotEmpty) {
          _crossBloc.requestNewerThan(_allUserCircles, widget.userFurnaces,
              _filteredCircleObjects.first.created!);
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.addToLibrary.listen((List<CircleObject> circleObjects) {
        _libraryGalleryKey = GlobalKey();
        for (CircleObject circleObject in circleObjects) {
          int index = _completeList
              .indexWhere((element) => element.seed == circleObject.seed);

          if (index == -1) {
            _completeList.add(circleObject);
          } else {
            _completeList[index] = circleObject;
          }
        }

        if (mounted) setState(() {});
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.removeFromLibrary.listen(
          (List<CircleObject> circleObjects) {
        ///remove the objects
        _completeList.removeWhere(
            (element) => circleObjects.any((x) => x.seed == element.seed));
        _filteredCircleObjects.removeWhere(
            (element) => circleObjects.any((x) => x.seed == element.seed));

        if (mounted) setState(() {});
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _globalEventBloc.deletedObject.listen((circleObject) {
        if (mounted) {
          ///remove the object
          setState(() {
            _filteredCircleObjects
                .removeWhere((x) => x.seed == circleObject.seed);
            _completeList.removeWhere((x) => x.seed == circleObject.seed);
          });
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _crossBloc.newerCircleObjects.listen((circleobjects) {
        if (circleobjects.isNotEmpty) {
          _globalEventBloc.broadcastMemCacheCircleObjectsAdd(circleobjects);

          List<CircleObject> notAlreadyThere = [];

          for (var i = 0; i < circleobjects.length; i++) {
            if (!_completeList.any((x) => x.seed == circleobjects[i].seed)) {
              notAlreadyThere.add(circleobjects[i]);
            } else {
              int index = _completeList
                  .indexWhere((x) => x.seed == circleobjects[i].seed);
              _completeList[index] = circleobjects[i];
              _filteredCircleObjects[index] = circleobjects[i];
            }
          }

          _completeList.addAll(notAlreadyThere);
          _filteredCircleObjects.addAll(notAlreadyThere);

          _completeList.sort((a, b) => b.created!.compareTo(a.created!));
          _filteredCircleObjects
              .sort((a, b) => b.created!.compareTo(a.created!));

          if (mounted) setState(() {});
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _crossBloc.olderCircleObjects.listen((circleobjects) {
        if (mounted) {
          if (firstLoad) {
            firstLoad = false;

            _completeList.addAll(circleobjects);
            _filteredCircleObjects.addAll(circleobjects);

            // var ids = <dynamic>{};
            // _completeList.retainWhere(
            //     (x) => ids.add(x.storageID) || x.storageID == null);
            //
            // ids = <dynamic>{};
            // _filteredCircleObjects.retainWhere(
            //     (x) => ids.add(x.storageID) || x.storageID == null);

            ///make sure there is at least 500 of each object type
            ///Events are handled differently
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLEIMAGE);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLEVIDEO);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLECREDENTIAL);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLELINK);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLEFILE);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLERECIPE);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLELIST);
            _crossBloc.requestOlderThan(_allUserCircles, widget.userFurnaces,
                _filteredCircleObjects.first.created!,
                amount: 500, type: CircleObjectType.CIRCLEVOTE);
          } else {
            for (CircleObject circleObject in circleobjects) {
              int index = _completeList.indexWhere((element) =>
                  element.id != null && element.id == circleObject.id);

              if (index == -1) {
                _completeList.add(circleObject);
                _filteredCircleObjects.add(circleObject);
              }
            }

            var ids = <dynamic>{};
            _completeList.retainWhere(
                (x) => ids.add(x.storageID) || x.storageID == null);

            ids = <dynamic>{};
            _filteredCircleObjects.retainWhere(
                (x) => ids.add(x.storageID) || x.storageID == null);
          }

          setState(() {
            spinnerRefresh = false;
          });
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _crossBloc.circles.listen((userCircleCaches) async {
        _allUserCircles = userCircleCaches;

        if (widget.crossObjects.isNotEmpty) {
          _processInitialLoad(widget.crossObjects);
          _crossBloc.requestNewerThan(_allUserCircles, widget.userFurnaces,
              widget.crossObjects.first.created!);
        } else {
          _crossBloc.initialLoad(widget.userFurnaces, true);
        }

        _networkFilteredUserCircles.clear();
        _networkFilteredUserCircles.addAll(_allUserCircles);
        _networkFilteredUserCircles.add(UserCircleCache(
            circlePath: await FileSystemService.returnCirclesDirectory(
                globalState.user.id!, DeviceOnlyCircle.circleID),
            prefName: DeviceOnlyCircle.prefName,
            circle: DeviceOnlyCircle.circleID,
            user: globalState.user.id!,
            userFurnace: globalState.userFurnace!.pk));
        _networkFilteredUserCircles.sort((a, b) =>
            a.prefName!.toLowerCase().compareTo(b.prefName!.toLowerCase()));

        if (mounted) {
          setState(() {
            spinner = false;
          });
        }
      }, onError: (err) {
        debugPrint("Library.listen: $err");
      }, cancelOnError: false);

      _crossBloc.sinkCircles(widget.userFurnaces);

      // if (widget.crossObjects.isNotEmpty) {
      //   _processInitialLoad(widget.crossObjects);
      //   // _crossBloc.requestNewerThan(_userCircles, widget.userFurnaces,
      //   //     widget.crossObjects.first.created!);
      // } else {
      //   _crossBloc.initialLoad(widget.userFurnaces, true);
      // }

      super.initState();
    } catch (err, trace) {
      LogBloc.postLog(err.toString(), trace.toString());
    }
  }

  _shuffleObjects() {
    _shuffle = !_shuffle;

    setState(() {
      _filteredCircleObjects.clear();
      _filteredCircleObjects.addAll(_completeList);
      _filterObjectsNoState();

      if (widget.filteredFurnace != null)
        _filteredCircleObjects.retainWhere(
            (element) => element.userFurnace!.pk == widget.filteredFurnace!.pk);

      if (_shuffle) {
        _filteredCircleObjects.shuffle();
      }
    });
  }

  _filterObjectsNoState() {
    _filteredCircleObjects.clear();
    if (_selectedUserCircles.isNotEmpty) {
      for (UserCircleCache userCircleCache in _selectedUserCircles) {
        List<CircleObject>? subList = _completeList
            .where((element) =>
                element.userCircleCache!.circle! == userCircleCache.circle!)
            .toList();

        if (subList.isEmpty) {
          _crossBloc.requestOlderThan(
              [userCircleCache], widget.userFurnaces, DateTime.now(), amount: 500);
        } else if (subList.length < 100){
          _crossBloc.requestOlderThan(
              [userCircleCache], widget.userFurnaces, subList.last.created!, amount: 500);
        }

        _filteredCircleObjects.addAll(subList);
      }
    } else {
      _filteredCircleObjects.addAll(_completeList);

      if (widget.filteredFurnace != null) {
        _filteredCircleObjects.retainWhere(
            (element) => element.userFurnace!.pk == widget.filteredFurnace!.pk);
      }
    }
  }

  _filterObjects() {
    _filterObjectsNoState();

    setState(() {});
  }

  _handleTabSelection() {
    if (widget.updateTab != null) {
      widget.updateTab!(SelectedLibraryTab.values[_tabController.index]);
    }
    //debugPrint('tab index: ${_tabController.index}');
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScalerOf(context).scale(1);

    if (_completeList.isNotEmpty) {
      ///did the network filter change?
      if (_filteredUserFurnace != widget.filteredFurnace) {
        _filteredUserFurnace = widget.filteredFurnace;

        _selectedUserCircles.clear();

        _filteredCircleObjects.clear();
        _filteredCircleObjects.addAll(_completeList);

        if (widget.filteredFurnace != null) {
          _networkFilteredUserCircles.clear();
          _networkFilteredUserCircles.addAll(_allUserCircles);
          _networkFilteredUserCircles.retainWhere(
              (element) => element.userFurnace! == widget.filteredFurnace!.pk);

          _filteredCircleObjects.retainWhere((element) =>
              element.userFurnace!.pk == widget.filteredFurnace!.pk);
        }
      }
      // _filterObjectsNoState();
    }

    final circleFilter = MultiSelectDialogField(
      items: _networkFilteredUserCircles
          .map((e) => MultiSelectItem(e, e.prefName!))
          .toList(),
      listType: MultiSelectListType.CHIP,
      backgroundColor: globalState.theme.dialogBackground,
      //initialValue:   globalState.selectedUserCircles, //.map((e) => Object(e.prefName!)).toList(),
      title: Text(
        AppLocalizations.of(context)!.filterCircles,
        textScaler: const TextScaler.linear(1.0),
        style: TextStyle(fontSize: 18, color: globalState.theme.labelText),
      ),
      //searchHint: 'filter Circles',
      selectedColor: Colors.teal.withOpacity(.4),
      buttonText: Text(AppLocalizations.of(context)!.filterCircles,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(fontSize: 16, color: globalState.theme.labelText)),
      buttonIcon: const Icon(Icons.filter_list_alt),
      confirmText: Text(AppLocalizations.of(context)!.filter,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(fontSize: 16, color: globalState.theme.button)),
      itemsTextStyle: TextStyle(
          fontSize: 14 / textScale, color: globalState.theme.textField),
      searchTextStyle: TextStyle(
          fontSize: 14 / textScale, color: globalState.theme.textField),
      selectedItemsTextStyle: TextStyle(
          fontSize: 14 / textScale, color: globalState.theme.textField),
      cancelText: Text(AppLocalizations.of(context)!.cancel,
          textScaler: const TextScaler.linear(1.0),
          style:
              TextStyle(fontSize: 16, color: globalState.theme.buttonDisabled)),
      searchable: true,
      searchIcon: Icon(
        Icons.search,
        color: globalState.theme.button,
      ),
      onConfirm: (values) {
        _selectedUserCircles = values as List<UserCircleCache>;

        _filterObjects();
      },
      chipDisplay: MultiSelectChipDisplay(
        chipColor: globalState.theme.menuBackground,
        textStyle: TextStyle(
            fontSize: 14 / globalState.chipDividerFactor,
            color: globalState.theme.textField),
        items: _selectedUserCircles
            .map((e) => MultiSelectItem(e, e.prefName!))
            .toList(),
        onTap: (value) {
          //setState(() {
          _selectedUserCircles.remove(value);
          _filterObjects();

          return _selectedUserCircles;
          //});
        },
      ),
    );

    final body = DefaultTabController(
        length: 6,
        //initialIndex: 0,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: PreferredSize(
              preferredSize: const Size(40.0, 40.0),
              child: TabBar(
                  dividerHeight: 0.0,
                  controller: _tabController,
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: -10.0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  unselectedLabelColor: globalState.theme.unselectedLabel,
                  labelColor: globalState.theme.buttonIcon,
                  //isScrollable: true,
                  indicatorColor: Colors.black,
                  indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Creates border
                      color: Colors.lightBlueAccent.withOpacity(.1)),
                  tabs: const [
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("GALLERY",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),
                                    */
                            Icon(Icons.photo_library_rounded),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("CALENDAR",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.link_rounded),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(Icons.attach_file_rounded),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("CREDENTIALS",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.check_box),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("RECIPES",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.restaurant_rounded),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("CALENDAR",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.event_rounded),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("CREDENTIALS",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.poll),
                      ),
                    ),
                    Tab(
                      child: Align(
                        alignment: Alignment.center,
                        child: /*Text("CREDENTIALS",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize:
                                    14.0 - globalState.scaleDownTextFont)),*/
                            Icon(Icons.login),
                      ),
                    ),
                  ])),
          body: TabBarView(
            controller: _tabController,
            children: [
              LibraryGallery(
                key: widget.slideUpPanel == true
                    ? _libraryGalleryKey
                    : _libraryStaticKey,
                refresh: _refresh,
                onNotification: onNotification,
                globalEventBloc: _globalEventBloc,
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                captureMedia: _captureMedia,
                mode: "",
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
                circleObjectBloc: _circleObjectBloc,
              ),
              /*LibraryVideo(
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
              ),

               */
              LibraryLinks(
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                globalEventBloc: _globalEventBloc,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
              LibraryFiles(
                globalEventBloc: _globalEventBloc,
                userFurnaces: widget.userFurnaces,
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
              LibraryLists(
                globalEventBloc: _globalEventBloc,
                userFurnaces: widget.userFurnaces,
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
              LibraryRecipes(
                globalEventBloc: _globalEventBloc,
                userFurnaces: widget.userFurnaces,
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
              CentralCalendarScreen(
                  //key: _actionRequiredKey,
                  setEventDateTime: widget.setEventDateTime,
                  slideUpPanel: widget.slideUpPanel,
                  userFurnaces: widget.userFurnaces,
                  refreshCallback: widget.refreshCallback),
              LibraryVotes(
                globalEventBloc: _globalEventBloc,
                userFurnaces: widget.userFurnaces,
                circleObjects: _filteredCircleObjects,
                shuffle: _shuffle,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
              LibraryCredentials(
                //key: GlobalKey(),
                globalEventBloc: _globalEventBloc,
                userFurnaces: widget.userFurnaces,
                circleObjects: _filteredCircleObjects,
                libraryBloc: _crossBloc,
                shuffle: _shuffle,
                slideUpPanel: widget.slideUpPanel,
                updateSelected: widget.updateSelected,
              ),
            ],
          ),
        ));

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          //appBar: topAppBar,
          //drawer: NavigationDrawer(),
          appBar: globalState.isDesktop()
              ? const ICAppBar(
                  title: "Library",
                  leadingIndicator: false,
                )
              : null,
          body: Padding(
              padding:
                  const EdgeInsets.only(left: 0, right: 0, bottom: 5, top: 0),
              child: Stack(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    widget.showFilter
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(child: circleFilter),
                                // _selectedIndex == 0 ?
                                widget.slideUpPanel
                                    ? Container()
                                    : IconButton(
                                        onPressed: _shuffleObjects,
                                        icon: Icon(
                                          Icons.shuffle,
                                          color: _shuffle
                                              ? globalState.theme.menuIconsAlt
                                              : globalState.theme.menuIcons,
                                        )) //: Container()
                              ])
                        : Container(),

                    Expanded(child: spinner ? spinkit : body),
                    //makeBottom,
                  ],
                ),
                Center(child: spinnerRefresh ? spinkit : Container()),
              ])),
          //bottomNavigationBar: ICBottomNavigation(),
        ));
  }

  Future<void> _refresh() async {
    // if (_showSpinner) return;
    //
    // _circleObjectBloc.resendFailedCircleObjects(_globalEventBloc);
    //
    // setState(() {
    //   _startSpinner(1);
    // });
    //
    // _refreshCircleObjects();
    //
    // if (_itemScrollController.isAttached)
    //   _itemScrollController.scrollTo(
    //       index: 0,
    //       duration: const Duration(seconds: 1),
    //       curve: Curves.easeInOutCubic);
  }

  bool onNotification(ScrollEndNotification t) {
    try {
      if (t.metrics.pixels > 0 && t.metrics.atEdge) {
        CircleObject oldest =
            _filteredCircleObjects[_filteredCircleObjects.length - 1];
        DateTime created = oldest.created!;

        if (_selectedUserCircles.isNotEmpty) {
          _crossBloc.requestOlderThan(
              _selectedUserCircles, widget.userFurnaces, created);
        } else if (_networkFilteredUserCircles.isNotEmpty) {
          _crossBloc.requestOlderThan(
              _networkFilteredUserCircles, widget.userFurnaces, created);
        } else {
          _crossBloc.requestOlderThan(
              _allUserCircles, widget.userFurnaces, created);
        }

        setState(() {
          spinnerRefresh = true;
        });
        //FormattedSnackBar.showSnackbarWithContext(context,
        //    'loading additional posts...', "", 2);

        return true;
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle.onNotification: $err');
    }

    return false;
  }

  _captureMedia() async {
    try {
      FileSystemService.makeCirclePath(
          globalState.user.id!, DeviceOnlyCircle.circleID);

      CapturedMediaResults? results = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CaptureMedia()),
      ); //.then(_circleObjectBloc.requestNewerThan(

      if (results != null) {
        setState(() {
          spinnerRefresh = true;
        });

        if (results.mediaCollection.media.length >= 3) {
          CircleAlbumBloc circleAlbumBloc = CircleAlbumBloc(_globalEventBloc);
          _filteredCircleObjects.add(await circleAlbumBloc.cacheToDevice(
              results.mediaCollection.media, true, _circleObjectBloc));
        } else {
          CircleImageBloc circleImageBloc = CircleImageBloc(_globalEventBloc);
          _filteredCircleObjects.addAll(await circleImageBloc.cacheToDevice(
              results.mediaCollection, true));

          CircleVideoBloc circleVideoBloc = CircleVideoBloc(_globalEventBloc);
          _filteredCircleObjects.addAll(
              await circleVideoBloc.cacheToDevice(results.mediaCollection));
        }

        if (widget.slideUpPanel == false) {
          ///refresh library after adding new picture
          _libraryStaticKey = GlobalKey();
        }

        setState(() {
          spinnerRefresh = false;
        });

        //}
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._captureMedia: $err');
    }
  }
}
