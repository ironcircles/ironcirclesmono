import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:provider/provider.dart';

///Called from the InsideCircle and when the app receives an external share

class ReceiveShare extends StatefulWidget {
  // final Flutterbug flutterbug;
  final MediaCollection? sharedMedia;
  final List<File>? sharedVideos;
  final String? sharedText;
  final GiphyOption? sharedGif;
  final List<UserFurnace> userFurnaces;

  const ReceiveShare(
      {Key? key,
      required this.userFurnaces,
      this.sharedMedia,
      this.sharedText,
      this.sharedGif,
      this.sharedVideos})
      : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  ReceiveShareState createState() => ReceiveShareState();
}

class ReceiveShareState extends State<ReceiveShare> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  //String? _furnace = '';
  late DropDownPair _dropDownPair; // = DropDownPair(id: 'blank', value: ' ');
  final DropDownPair _blankDropDownPair = DropDownPair(id: 'blank', value: ' ');
  late DropDownPair _selectedFurnace;
  List<DropDownPair> _furnaceList = [];

  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  //List<UserFurnace>? _userFurnaces;
  late List<UserCircleCache> _userCircles;
  List<DropDownPair> _filteredDropDownPairs = [];
  bool _allowRemember = true;
  bool checkedMatch = false;

  @override
  void initState() {
    super.initState();

    _dropDownPair = _blankDropDownPair;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    // _userFurnaceBloc.userfurnaces.listen((furnaces) {
    //   if (mounted) {
    //     _userFurnaces = furnaces;
    //     _userCircleBloc.sinkCache(_userFurnaces!);
    //   }
    // }, onError: (err) {
    //   FormattedSnackBar.showSnackbarWithContext(
    //       context, err.toString(), "", 2, true);
    // }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen((refreshedUserCircleCaches) {
      if (mounted) {
        setState(() {
          _furnaceList = [];

          for (UserFurnace userFurnace in widget.userFurnaces) {
            if (userFurnace.connected!)
              _furnaceList.add(DropDownPair(
                  id: userFurnace.pk!.toString(),
                  value: '${userFurnace.alias!} (${userFurnace.username!})'));
          }

          _furnaceList.sort(
              (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

          _selectedFurnace = _furnaceList[0];

          _userCircles = refreshedUserCircleCaches;

          _populateCirclesByFurnace(_selectedFurnace.id, true);
        });
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      debugPrint("error $err");
    }, cancelOnError: false);

    //_filteredUserCircleList.add(' ');

    //_dropDownPairs = [];
    // _dropDownPairs.add(_dropDownPair);
    _filteredDropDownPairs.add(_blankDropDownPair);

    //_userFurnaceBloc.request(globalState.user.id);
    _userCircleBloc.sinkCache(widget.userFurnaces);
  }

  @override
  void dispose() {
    //_circleName.dispose();
    //_password.dispose();
    //_password2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    globalState.setScaler(MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));



    final makeBottom = Padding(
        padding: const EdgeInsets.only(top: 20),
        child: SizedBox(
          height: 55.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0),
            child: Row(children: <Widget>[
              Expanded(
                child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: ButtonType.getWidth(
                            MediaQuery.of(context).size.width)),
                    child: GradientButton(
                        text: AppLocalizations.of(context)!.preview,
                        onPressed: () {
                          _preview();
                        })),
              ),
            ]),
          ),
        ));

    final lowerScreen = SizedBox(
        height: 25.0,
        width: double.infinity,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.rememberLastShared,
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(
                fontSize: globalState.userSetting.fontSize,
                color: globalState.theme.labelText),
          ),
          Theme(
              data: ThemeData(
                  unselectedWidgetColor: globalState.theme.checkUnchecked),
              child: Checkbox(
                  activeColor: globalState.theme.buttonIcon,
                  checkColor: globalState.theme.checkBoxCheck,
                  value: _allowRemember,
                  onChanged: (newValue) async {
                    if (newValue != null) {
                      if (!newValue)
                        globalState.userSetting.setLastSharedTo(newValue,
                            globalState.userSetting.lastSharedToNetwork, '');
                      else
                        globalState.userSetting.setLastSharedTo(
                            newValue,
                            globalState.userSetting.lastSharedToNetwork,
                            globalState.userSetting.lastSharedToCircle);
                      setState(() {
                        _allowRemember = newValue;
                      });
                      //_userFurnaceBloc.request(
                      //  globalState.user.id, false);
                    }
                  }))
        ]));


    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                        AppLocalizations.of(context)!.furnaceFilter,
                        textScaler:
                            TextScaler.linear(globalState.labelScaleFactor),
                      ),
                    ),
                  ]),
                ),
                _furnaceList.isEmpty
                    ? Container()
                    : Padding(
                        padding:
                            const EdgeInsets.only(left: 11, top: 0, bottom: 0),
                        child: Row(children: <Widget>[
                          Expanded(
                            flex: 20,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.textField),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.textField),
                                ),
                              ),
                              //isEmpty: _furnace == 'first match',
                              child: DropdownButtonHideUnderline(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      canvasColor:
                                          globalState.theme.dropdownBackground),
                                  child: DropdownButton<DropDownPair>(
                                    value: _selectedFurnace,
                                    onChanged: (DropDownPair? newValue) {
                                      setState(() {
                                        _selectedFurnace = newValue!;
                                        _populateCirclesByFurnace(
                                            _selectedFurnace.id, false);
                                      });
                                    },
                                    items: _furnaceList
                                        .map<DropdownMenuItem<DropDownPair>>(
                                            (DropDownPair value) {
                                      return DropdownMenuItem<DropDownPair>(
                                        value: value,
                                        child: Text(
                                          value.value,
                                          textScaler: TextScaler.linear(
                                              globalState.dropdownScaleFactor),
                                          style: ICTextStyle.getStyle(
                                              context: context,
                                              color: globalState
                                                  .theme.dropdownText),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: Text(
                          AppLocalizations.of(context)!
                              .selectACircleDMToShareTo,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: globalState.theme.textField),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: globalState.theme.textField),
                          ),
                        ),
                        //isEmpty: _furnace == 'first match',
                        child: DropdownButtonHideUnderline(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                                canvasColor:
                                    globalState.theme.dropdownBackground),
                            child: DropdownButton<DropDownPair>(
                              value: _dropDownPair,
                              onChanged: (DropDownPair? newValue) {
                                setState(() {
                                  _dropDownPair = newValue!;
                                });
                              },
                              items: _filteredDropDownPairs
                                  .map<DropdownMenuItem<DropDownPair>>(
                                      (DropDownPair value) {
                                return DropdownMenuItem<DropDownPair>(
                                  value: value,
                                  child: Text(
                                    value.value,
                                    textScaler: TextScaler.linear(
                                        globalState.dropdownScaleFactor),
                                    style: ICTextStyle.getStyle(
                                        context: context,
                                        color: globalState.theme.dropdownText),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                globalState.isDesktop()  ? lowerScreen : Container(),
                globalState.isDesktop() ? makeBottom : Container()
              ]),
        ),
      ),
    );

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.shareToIronCircles,
          pop: _back,
        ),
        //drawer: NavigationDrawer(),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: WrapperWidget(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: makeBody,
                ),
                globalState.isDesktop() == false ? lowerScreen : Container(),
                globalState.isDesktop() == false ? makeBottom : Container()
              ],
            ))));
  }

  _back() {
    if (ModalRoute.of(context)!.isFirst) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        // arguments: user,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _populateCirclesByFurnace(String id, bool loading) async {
    String lastFurnacePK = '';
    String lastUserCircleID = '';

    if (loading) {
      _allowRemember = globalState.userSetting.allowLastSharedToCircle;
      if (globalState.userSetting.lastSharedToNetwork != null)
        lastFurnacePK = globalState.userSetting.lastSharedToNetwork!;

      if (_allowRemember) if (globalState.userSetting.lastSharedToCircle !=
          null) lastUserCircleID = globalState.userSetting.lastSharedToCircle!;

      int index = _furnaceList
          .indexWhere((element) => element.id == lastFurnacePK.toString());

      if (index > -1) {
        _selectedFurnace = _furnaceList[index];
        lastFurnacePK = _furnaceList[index].id;

        for (DropDownPair dropDownPair in _filteredDropDownPairs) {
          if (dropDownPair.id == lastUserCircleID) {
            _dropDownPair = dropDownPair;
            break;
          }
        }
        //checkedMatch = true;
      }
    }

    setState(() {
      if (_selectedFurnace.value == 'all') {
        //_filteredUserCircleList = _userCircleList;
      } else {
        int index = widget.userFurnaces.indexWhere(
            (element) => element.pk.toString() == _selectedFurnace.id);

        UserFurnace userFurnace = widget.userFurnaces[index];

        // for (UserFurnace testFurnace in _userFurnaces!) {
        //   if (testFurnace.alias == _selectedFurnace.value) {
        //     userFurnace = testFurnace;
        //     break;
        //   }
        // }

        _filteredDropDownPairs = [];
        _filteredDropDownPairs.add(_blankDropDownPair);

        for (UserCircleCache userCircleCache in _userCircles) {
          if (userCircleCache.cachedCircle!.toggleMemberPosting != false ||
              userCircleCache.cachedCircle!.owner == userFurnace.userid) {
            if (userCircleCache.userFurnace == userFurnace.pk) {
              String prefName = '';

              if (userCircleCache.prefName != null) {
                prefName = userCircleCache.prefName!;
              }

              if (prefName.length > 50)
                prefName = userCircleCache.prefName!.substring(0, 49);

              _filteredDropDownPairs.add(DropDownPair(
                  id: userCircleCache.usercircle!, value: prefName));
            }
          }
        }
        _filteredDropDownPairs.sort(
            (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
      }

      //_userCircleName = ' ';

      _dropDownPair = _blankDropDownPair;

      if (loading) {
        int index =
            _furnaceList.indexWhere((element) => element.id == lastFurnacePK);

        if (index > -1) {
          _selectedFurnace = _furnaceList[index];
          for (DropDownPair dropDownPair in _filteredDropDownPairs) {
            if (dropDownPair.id == lastUserCircleID) {
              _dropDownPair = dropDownPair;
              break;
            }
          }

          //checkedMatch = true;
        }
      }

      debugPrint('test');
    });
  }

  _pinCaptured(List<int> pin) {
    try {
      String pinString = UserCircleCache.pinToString(pin);
      debugPrint(pinString);

      //debugPrint(UserCircleCache.stringToPin(pinString));

      if (_clickedUserCircleCache!.checkPin(pin)) {
        _preview(guardPinAccepted: true);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Home._pinCaputured: $err');
    }
  }

  UserCircleCache? _clickedUserCircleCache;

  _preview({bool guardPinAccepted = false}) async {
    int index = widget.userFurnaces
        .indexWhere((element) => element.pk.toString() == _selectedFurnace.id);

    UserFurnace userFurnace = widget.userFurnaces[index];

    late UserCircleCache userCircleCache;

    if (_clickedUserCircleCache != null) {
      userCircleCache = _clickedUserCircleCache!;
    } else {
      for (UserCircleCache possibleUserCircleCache in _userCircles) {
        if (possibleUserCircleCache.usercircle! == _dropDownPair.id &&
            possibleUserCircleCache.userFurnace! == userFurnace.pk) {
          userCircleCache = possibleUserCircleCache;
          break;
        }
      }
    }

    // if (userCircleCache.guarded! && !guardPinAccepted) {
    //   _clickedUserCircleCache = userCircleCache;
    //
    //   await DialogPatternCapture.capture(
    //       context, _pinCaptured, 'Swipe pattern to enter');
    //
    //   return;
    // }

    //await MemberBloc.populateGlobalState(globalState, [userFurnace]);

    if (_allowRemember)
      globalState.userSetting.setLastSharedTo(
          _allowRemember, _selectedFurnace.id, _dropDownPair.id);

    if (widget.sharedMedia != null && widget.sharedMedia!.isNotEmpty) {
      _globalEventBloc.broadcastPopToHomeEnterCircle(UserCircleCacheAndShare(
          userCircleCache: userCircleCache,
          sharedMediaHolder:
              SharedMediaHolder(sharedMedia: widget.sharedMedia, message: '')));

      // if (userCircleCache.cachedCircle!.type == CircleType.WALL) {
      //   Navigator.pushAndRemoveUntil(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => Home(
      //                 circlesTab: 0,
      //                 sharedMediaHolder: SharedMediaHolder(
      //                     sharedMedia: widget.sharedMedia, message: ''),
      //               )),
      //       ModalRoute.withName("/home"));
      // } else {
      //   Navigator.pop(context);
      //   Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => InsideCircleContainer(
      //                 userCircleCache: userCircleCache,
      //                 userFurnace: userFurnace,
      //                 crossObjects: const [],
      //                 sharedMediaHolder: SharedMediaHolder(
      //                     sharedMedia: widget.sharedMedia, message: ''),
      //                 hiddenOpen: false,
      //                 userFurnaces: _userFurnaces,
      //               )));
      //
      //   // Navigator.pushAndRemoveUntil(
      //   //     context,
      //   //     MaterialPageRoute(
      //   //         builder: (context) => InsideCircleContainer(
      //   //               userCircleCache: userCircleCache,
      //   //               userFurnace: userFurnace,
      //   //               crossObjects: const [],
      //   //               sharedMediaHolder: SharedMediaHolder(
      //   //                   sharedMedia: widget.sharedMedia, message: ''),
      //   //               hiddenOpen: false,
      //   //               userFurnaces: _userFurnaces,
      //   //             )),
      //   //     ModalRoute.withName("/home"));
      // }
    } else if (widget.sharedVideos != null) {
      MediaCollection mediaCollection = MediaCollection();

      mediaCollection.populateFromFiles(widget.sharedVideos!, MediaType.video);
      // if (userCircleCache.cachedCircle!.type == CircleType.WALL) {
      _globalEventBloc.broadcastPopToHomeEnterCircle(UserCircleCacheAndShare(
          userCircleCache: userCircleCache,
          sharedMediaHolder:
              SharedMediaHolder(sharedMedia: mediaCollection, message: '')));

      // } else {
      //   Navigator.pop(context);
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => InsideCircleContainer(
      //               userCircleCache: userCircleCache,
      //               userFurnace: userFurnace,
      //               crossObjects: const [],
      //               sharedMediaHolder: SharedMediaHolder(
      //                   sharedMedia: widget.sharedMedia, message: ''),
      //               hiddenOpen: false,
      //               userFurnaces: _userFurnaces,
      //             )),
      //   );
      //
      //   // Navigator.pushAndRemoveUntil(
      //   //     context,
      //   //     MaterialPageRoute(
      //   //         builder: (context) => InsideCircleContainer(
      //   //               userCircleCache: userCircleCache,
      //   //               userFurnace: userFurnace,
      //   //               crossObjects: const [],
      //   //               sharedMediaHolder: SharedMediaHolder(
      //   //                   sharedMedia: widget.sharedMedia, message: ''),
      //   //               hiddenOpen: false,
      //   //               userFurnaces: _userFurnaces,
      //   //             )),
      //   //     ModalRoute.withName("/home"));
      // }
    } else if (widget.sharedGif != null) {
      _globalEventBloc.broadcastPopToHomeEnterCircle(UserCircleCacheAndShare(
          userCircleCache: userCircleCache,
          sharedMediaHolder:
              SharedMediaHolder(sharedGif: widget.sharedGif, message: '')));
      // Navigator.pop(context);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => InsideCircleContainer(
      //             userCircleCache: userCircleCache,
      //             crossObjects: const [],
      //             userFurnace: userFurnace,
      //             sharedMediaHolder: SharedMediaHolder(
      //                 sharedGif: widget.sharedGif, message: ''),
      //             hiddenOpen: false,
      //             userFurnaces: _userFurnaces,
      //           )),
      // );
    } else if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      _globalEventBloc.broadcastPopToHomeEnterCircle(UserCircleCacheAndShare(
          userCircleCache: userCircleCache,
          sharedMediaHolder:
              SharedMediaHolder(sharedText: widget.sharedText, message: '')));

      //widget.sharedFiles![0].
      // Navigator.pushAndRemoveUntil(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => InsideCircleContainer(
      //               userCircleCache: userCircleCache,
      //               userFurnace: userFurnace,
      //               crossObjects: const [],
      //               sharedMediaHolder: SharedMediaHolder(
      //                   sharedText: widget.sharedText, message: ''),
      //               hiddenOpen: false,
      //               userFurnaces: _userFurnaces,
      //             )),
      //     ModalRoute.withName("/home"));
    }
  }
}
