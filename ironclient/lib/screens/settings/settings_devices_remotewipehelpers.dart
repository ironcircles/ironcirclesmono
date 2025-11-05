import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SettingsDevicesRemoteWipeHelpers extends StatefulWidget {
  const SettingsDevicesRemoteWipeHelpers({
    Key? key,
  }) : super(key: key);

  @override
  _SettingsDevicesState createState() => _SettingsDevicesState();
}

class _SettingsDevicesState extends State<SettingsDevicesRemoteWipeHelpers> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  UserBloc _userBloc = UserBloc();
  final _formKey = GlobalKey<FormState>();
  DeviceBloc _deviceBloc = DeviceBloc();
  List<Device> _devices = [];
  final ScrollController _scrollController = ScrollController();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  UserHelper? _helper;
  bool? _showHelpers;
  List<ListItem> _members = [];

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  ListItem? _selectedOne;
  ListItem? _selectedTwo;
  ListItem? _selectedThree;
  ListItem? _selectedFour;

  bool showThree = false;
  bool showFour = false;

  @override
  void initState() {
    _members.clear();

    _members.add(ListItem(object: User(), name: ''));

    _deviceBloc.devicesLoaded.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2,  true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _deviceBloc.deactivated.listen((device) {
      if (mounted) {
        setState(() {
          _devices.removeWhere((element) => element.id == device.id);
          _showSpinner = false;
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.deactivated, "", 2,  false);
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _deviceBloc.wiped.listen((device) {
      if (mounted) {
        setState(() {
          _devices.removeWhere((element) => element.id == device.id);
          _showSpinner = false;
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.deviceWiped, "", 2, false);
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2,  true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      _deviceBloc.get(userFurnaces!);
    }, onError: (err) {
      // FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    //Listen for membership load
    _userBloc.remoteWipeHelper.listen((helper) {
      if (mounted) {
        setState(() {
          _helper = helper;

          for (User user in _helper!.members!) {
            _members.add(ListItem(
                object: user, name: user.getUsernameAndAlias(globalState)));
            //_members2.add(ListItem(object: user, name: user.username));
          }

          if (_helper!.helpers!.isNotEmpty)
            _showHelpers = false;
          else
            _showHelpers = true;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2,  true);
    }, cancelOnError: false);

    _userFurnaceBloc.requestConnected(globalState.user.id);

    ///TODO this should show users across all furnaces
    _userBloc.fetchRemoteWipeHelpers(
        globalState.userFurnace!, globalState.user.id!);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 20;

    final addHelper = Padding(
        padding: const EdgeInsets.only(right: 0),
        child: Ink(
          decoration: ShapeDecoration(
            color: globalState.theme.buttonIcon,
            shape: const CircleBorder(),
          ),
          child: IconButton(
            iconSize: 25,
            icon: const Icon(Icons.add),
            color: globalState.theme.buttonText,
            onPressed: () {
              setState(() {
                if (!showThree)
                  showThree = true;
                else
                  showFour = true;

                //show = true;
              });
            },
          ),
        ));

    final makeHelpers = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
                flex: 1,
                child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 0),
                    child: FormattedDropdownObject(
                      hintText: AppLocalizations.of(context)!.helper1, //'helper #1',
                      selected: _selectedOne ?? _members[0],
                      list: _members,
                      // selected: _selectedOne,
                      underline: globalState.theme.bottomHighlightIcon,
                      onChanged: (ListItem? value) {
                        setState(() {
                          _selectedOne = value;
                        });
                      },
                    ))),
            Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Container(
                  //child: Ink(
                  child: IconButton(
                    icon: const Icon(Icons.help),
                    iconSize: 25,
                    color: globalState.theme.bottomIcon,
                    onPressed: () {
                      setState(() {
                        DialogNotice.showNotice(
                            context,
                            AppLocalizations.of(context)!.remoteWipeHelpersTitle,
                            AppLocalizations.of(context)
                                !.remoteWipeHelpersMessage1,
                            null,
                            null,
                            null,
                            false);
                      });
                    },
                  ),
                  //),
                )),
          ]),
          Row(children: <Widget>[
            Expanded(
                flex: 1,
                child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 0),
                    child: FormattedDropdownObject(
                      hintText: AppLocalizations.of(context)!.helper2, //'helper #2',
                      selected: _selectedTwo ?? _members[0],
                      list: _members,
                      // selected: _selectedOne,
                      underline: globalState.theme.bottomHighlightIcon,
                      onChanged: (ListItem? value) {
                        setState(() {
                          _selectedTwo = value;
                        });
                      },
                    ))),
            showThree
                ? const Padding(
                    padding: EdgeInsets.only(left: 0, right: 50, bottom: 0),
                  )
                : addHelper,
          ]),
          showThree
              ? Row(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 0),
                          child: FormattedDropdownObject(
                            hintText: AppLocalizations.of(context)!.helper3, //'helper #3',
                            selected: _selectedThree ?? _members[0],
                            list: _members,
                            // selected: _selectedOne,
                            underline: globalState.theme.bottomHighlightIcon,
                            onChanged: (ListItem? value) {
                              setState(() {
                                _selectedThree = value;
                              });
                            },
                          ))),
                  showFour
                      ? const Padding(
                          padding:
                              EdgeInsets.only(left: 0, right: 50, bottom: 0),
                        )
                      : addHelper
                ])
              : Container(),
          showFour
              ? Row(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 0),
                          child: FormattedDropdownObject(
                            hintText: AppLocalizations.of(context)!.helper4, //'helper #4',
                            selected: _selectedFour ?? _members[0],
                            list: _members,
                            // selected: _selectedOne,
                            underline: globalState.theme.bottomHighlightIcon,
                            onChanged: (ListItem? value) {
                              setState(() {
                                _selectedFour = value;
                              });
                            },
                          ))),
                  const Padding(
                    padding: EdgeInsets.only(left: 0, right: 50, bottom: 0),
                  ),
                ])
              : Container(),
          const Padding(
            padding: EdgeInsets.only(left: 0, right: 0, bottom: 10),
          ),
          Row(children: [
            const Spacer(),
            GradientButtonDynamic(
                text: AppLocalizations.of(context)!.updateHelpers, //'UPDATE HELPERS',
                onPressed: () {
                  _updateMembers();
                }),
          ]),
          const Padding(
            padding: EdgeInsets.only(left: 0, right: 0, bottom: 10),
          ),
        ]);

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(title: AppLocalizations.of(context)!.remoteWipeHelpersTitle),
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _showHelpers == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          child: Center(child: spinkit))
                      : _showHelpers!
                          ? makeHelpers
                          : Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Padding(
                                        padding: EdgeInsets.only(
                                            top: 30, bottom: 0)),
                                    Center(
                                        child: Row(children: <Widget>[
                                      Text(
                                        AppLocalizations.of(context)!.remoteWipeAssistanceAllSet, //'Remote wipe assistance all set',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: globalState.theme.labelText),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(left: 10),
                                          child: ClipOval(
                                              child: Material(
                                            color: globalState.theme
                                                .buttonIcon, // button color
                                            child: SizedBox(
                                                width: 25,
                                                height: 25,
                                                child: Icon(
                                                  Icons.check,
                                                  color: globalState
                                                      .theme.buttonText,
                                                )),
                                          )))
                                    ])),
                                    const Padding(
                                        padding: EdgeInsets.only(
                                            top: 10, bottom: 0)),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          GradientButtonDynamic(
                                              text: 'reset  assist members',
                                              onPressed: () {
                                                _setShowHelpers();
                                              })
                                        ]),
                                    const Padding(
                                        padding: EdgeInsets.only(
                                            top: 0, bottom: 10)),
                                  ])),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
  }

  _setShowHelpers() {
    setState(() {
      _showHelpers = true;
    });
  }

  _addMember(ListItem? item) {
    if (item != null) {
      if (item.name!.isNotEmpty) {
        User user = _helper!.members!
            .firstWhere((element) => element.id == item.object.id);

        if (!_helper!.helpers!.contains(user)) _helper!.helpers!.add(user);
      }
    }
  }

  _updateMembers() {
    try {
      if (_helper!.helpers!.isNotEmpty) _helper!.helpers!.clear();

      _addMember(_selectedOne);
      _addMember(_selectedTwo);
      _addMember(_selectedThree);
      _addMember(_selectedFour);

      if (_helper!.helpers!.isEmpty) {
        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.noOneSelected, "", 1,  false);
      } else
        _userBloc.updateRemoteWipeHelpers(globalState.userFurnace!, _helper!);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('SettingsPassword._updateMembers: $err');
    }
  }
}
