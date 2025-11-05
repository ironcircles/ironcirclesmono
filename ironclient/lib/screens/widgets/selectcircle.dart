import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/utilities/stringhelper.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

///Called from the Central Calendar

class SelectCircle extends StatefulWidget {
  final Function selected;

  const SelectCircle({
    Key? key,
    required this.selected,
  }) : super(key: key);

  @override
  _SelectCircleState createState() => _SelectCircleState();
}

class _SelectCircleState extends State<SelectCircle> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late DropDownPair _dropDownPair; // = DropDownPair(id: 'blank', value: ' ');
  final DropDownPair _blankDropDownPair = DropDownPair(id: 'blank', value: ' ');

  late DropDownPair _selectedFurnace;
  List<DropDownPair> _furnaceList = [];

  late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  List<UserFurnace>? _userFurnaces;
  late List<UserCircleCache> _userCircles;
  List<DropDownPair> _filteredDropDownPairs = [];

  bool checkedMatch = false;
  bool _allowRemember = true;

  @override
  void initState() {
    super.initState();

    _dropDownPair = _blankDropDownPair;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);

    _userFurnaceBloc.userfurnaces.listen((furnaces) {
      if (mounted) {
        _userFurnaces = furnaces;
        _userCircleBloc.sinkCache(_userFurnaces!);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCircles.listen((refreshedUserCircleCaches) {
      if (mounted) {
        setState(() {
          _furnaceList = [];

          for (UserFurnace userFurnace in _userFurnaces!) {
            if (userFurnace.connected!)
              _furnaceList.add(DropDownPair(
                  id: userFurnace.pk!.toString(),
                  value: '${StringHelper.truncate(userFurnace.alias!, 15)} (${StringHelper.truncate(userFurnace.username!, 15)})'));
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

    _userFurnaceBloc.request(globalState.user.id);
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
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: <
              Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Text(
                    'Furnace filter:',
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                  ),
                ),
              ]),
            ),
            _furnaceList.isEmpty
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(left: 11, top: 4, bottom: 0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 20,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            hintText: 'select a network',
                            hintStyle: TextStyle(
                                color: globalState.theme.textFieldLabel),
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
                                      textScaler: TextScaler.linear(globalState.dropdownScaleFactor),
                                      style: ICTextStyle.getStyle(context: context, 
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
              padding: const EdgeInsets.only(
                left: 11,
                top: 40,
                bottom: 0,
              ),
              child: Row(children: <Widget>[
                Expanded(
                  flex: 20,
                  child: Text(
                    AppLocalizations.of(context)!.selectACircleDMToShareTo,//'Select a Circle/DM to share to',
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                  ),
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
                      hintText: 'select a circle/dm',
                      hintStyle:
                          TextStyle(color: globalState.theme.textFieldLabel),
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
                                textScaler: TextScaler.linear(globalState.dropdownScaleFactor),
                                style: ICTextStyle.getStyle(context: context, 
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
          ]),
        ),
      ),
    );

    final makeBottom = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
            child: GradientButton(
                text: 'SELECT',
                onPressed: () {
                  _select();
                }),
          ),
        ]),
      ),
    );

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        /*appBar: AppBar(
            automaticallyImplyLeading: true,
            //`true` if you want Flutter to automatically add Back Button when needed,
            //or `false` if you want to force your own back button every where
            leading: IconButton(
              icon: Icon(Icons.arrow_back), color: globalState.theme.menuIcons,
              onPressed: () => Navigator.pop(context, false),
            )),

         */
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: makeBody,
            ),
            SizedBox(
                height: 25.0,
                width: double.infinity,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Spacer(),
                  Text(
                    'Remember last shared to?',
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        //fontSize: globalState.userSetting.fontSize,
                        color: globalState.theme.labelText),
                  ),
                  Theme(
                      data: ThemeData(
                          unselectedWidgetColor:
                              globalState.theme.checkUnchecked),
                      child: Checkbox(
                          activeColor: globalState.theme.buttonIcon,
                          checkColor: globalState.theme.checkBoxCheck,
                          value: _allowRemember,
                          onChanged: (newValue) async {
                            if (newValue != null) {
                              if (!newValue)
                                globalState.userSetting.setLastSharedTo(
                                    newValue,
                                    globalState.userSetting.lastSharedToNetwork,
                                    '');
                              else
                                globalState.userSetting.setLastSharedTo(
                                    newValue,
                                    globalState.userSetting.lastSharedToNetwork,
                                    globalState.userSetting.lastSharedToCircle);
                              setState(() {
                                _allowRemember = newValue;
                              });
                            }
                          }))
                ])),
            const Padding(padding: EdgeInsets.only(bottom: 20)),
            Container(
              padding: const EdgeInsets.all(0.0),
              child: makeBottom,
            ),
          ],
        ));
  }

  _select() async {
    late UserFurnace userFurnace;

    userFurnace = _userFurnaces!
        .firstWhere((element) => element.pk.toString() == _selectedFurnace.id);

    /*for (UserFurnace testFurnace in _userFurnaces!) {
      if (testFurnace.alias == _furnace) {
        userFurnace = testFurnace;
        break;
      }
    }

     */

    late UserCircleCache userCircleCache;

    for (UserCircleCache possibleUserCircleCache in _userCircles) {
      if (possibleUserCircleCache.usercircle! == _dropDownPair.id &&
          possibleUserCircleCache.userFurnace! == userFurnace.pk) {
        userCircleCache = possibleUserCircleCache;
        break;
      }
    }

    if (_allowRemember)
      globalState.userSetting.setLastSharedTo(
          _allowRemember, _selectedFurnace.id, _dropDownPair.id);

    widget.selected(userFurnace, userCircleCache);
  }

  void _populateCirclesByFurnace(String id, bool loading) async {
    String lastFurnacePK = '';
    String lastUserCircleID = '';

    if (loading) {
      _allowRemember = globalState.userSetting.allowLastSharedToCircle;
      if (globalState.userSetting.lastSharedToNetwork != null)
        lastFurnacePK = globalState.userSetting.lastSharedToNetwork!;

      if (_allowRemember) if (globalState.userSetting.lastSharedToCircle !=
          null) lastFurnacePK = globalState.userSetting.lastSharedToCircle!;

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
        UserFurnace userFurnace = _userFurnaces![_userFurnaces!.indexWhere(
            (element) => element.pk.toString() == _selectedFurnace.id)];

        for (UserFurnace testFurnace in _userFurnaces!) {
          if (testFurnace.alias == _selectedFurnace.value) {
            userFurnace = testFurnace;
            break;
          }
        }

        _filteredDropDownPairs = [];
        _filteredDropDownPairs.add(_blankDropDownPair);

        for (UserCircleCache userCircleCache in _userCircles) {
          if (userCircleCache.userFurnace ==
              userFurnace.pk) if (userCircleCache.prefName!.length > 50)
            _filteredDropDownPairs.add(DropDownPair(
                id: userCircleCache.usercircle!,
                value: userCircleCache.prefName!.substring(0, 49)));
          else
            _filteredDropDownPairs.add(DropDownPair(
                id: userCircleCache.usercircle!,
                value: userCircleCache.prefName!));
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
}
