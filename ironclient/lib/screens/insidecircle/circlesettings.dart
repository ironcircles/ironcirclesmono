import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circlesettings_personal.dart';
import 'package:ironcirclesapp/screens/insidecircle/circlesettings_wide.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class CircleSettings extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final Circle circle;
  final FirebaseBloc firebaseBloc;
  final CircleBloc circleBloc;

  const CircleSettings(
      {Key? key,
      required this.userCircleCache,
      required this.userFurnace,
      required this.userFurnaces,
      required this.circle,
      required this.firebaseBloc,
      required this.circleBloc})
      : super(key: key);

  @override
  CircleSettingsState createState() => CircleSettingsState();
}

class CircleSettingsState extends State<CircleSettings> {
  late UserCircleCache _userCircleCache;

  bool _showID = false;

  @override
  void initState() {
    _userCircleCache = widget.userCircleCache;

    super.initState();
  }

  popReturnData() {
    //Navigator.of(cont,).pop(widget.userCircleCache);
    Navigator.pop(context, widget.userCircleCache);

    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final makeHeader = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: InkWell(
                onTap: () {
                  setState(() {
                    _showID = !_showID;
                  });
                },
                child: Row(children: <Widget>[
                  Text(
                    widget.circle.dm ? "${AppLocalizations.of(context)!.dm}: " : "${AppLocalizations.of(context)!.name}:  ",
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.labelTextSubtle, fontSize: 16),
                  ),
                  Expanded(
                      child: Text(
                            widget.circle.type == CircleType.VAULT
                                ? _userCircleCache.prefName == null
                                    ? ''
                                    : _userCircleCache.prefName!
                                : _userCircleCache.circleName != null
                                    ? _userCircleCache.circleName!
                                    : _userCircleCache.prefName == null
                                        ? ''
                                        : _userCircleCache.prefName!,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                                color: widget.circle.dm
                                    ? globalState.members.first.color
                                    : globalState.theme.labelReadOnlyValue,
                                fontSize: 16),
                          )),
                ])),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "${AppLocalizations.of(context)!.network}: ",
                    textScaler: TextScaler.linear(globalState.labelScaleFactor),
                    style: TextStyle(
                        color: globalState.theme.labelTextSubtle, fontSize: 16),
                  ),
                  Expanded(
                      child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.userFurnace.alias!,
                      textScaler: TextScaler.linear(globalState.labelScaleFactor),
                      style: TextStyle(
                        color: globalState.theme.furnace,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  )),
                ]),
          ),
          _showID
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(children: <Widget>[
                    Text(
                      "${AppLocalizations.of(context)!.id}:  ",
                      textScaler: TextScaler.linear(globalState.labelScaleFactor),
                      style: TextStyle(
                          color: globalState.theme.labelTextSubtle,
                          fontSize: 16),
                    ),
                    SelectableText(
                      widget.userCircleCache.circle!,
                      textScaler: TextScaler.linear(globalState.labelScaleFactor),
                      style: TextStyle(
                          color: globalState.theme.labelTextSubtle,
                          fontSize: 16),
                    ),
                  ]),
                )
              : Container(),
          /*!kReleaseMode
          ? Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(children: <Widget>[
                Text(
                  "CircleID:  ",
                  style: TextStyle(color: globalState.theme.labelText, fontSize: 16),
                ),
                SelectableText(
                  _userCircleCache.circle,
                  style: TextStyle(
                      color: globalState.theme.labelReadOnlyValue, fontSize: 16),
                ),
              ]),
            )
          : Container(),

       */
        ]);

    final body = DefaultTabController(
        length: widget.circle.type == CircleType.VAULT ? 1 : 2,
        initialIndex: 0,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: PreferredSize(
              preferredSize: const Size(30.0, 40.0),
                child: TabBar(
                    dividerHeight: 0.0,
                    padding: const EdgeInsets.only(left: 3, right: 3),
                    unselectedLabelColor: globalState.theme.unselectedLabel,
                    labelColor: globalState.theme.buttonIcon,
                    isScrollable: true,
                    indicatorColor: Colors.black,
                    indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10), // Creates border
                        color: Colors.lightBlueAccent.withOpacity(.1)),
                    tabAlignment: TabAlignment.center,
                    // dividerHeight: 0.0,
                    // padding: const EdgeInsets.only(left: 3, right: 3),
                    // indicatorSize: TabBarIndicatorSize.label,
                    // indicatorPadding: const EdgeInsets.symmetric(horizontal: -10.0),
                    // labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    // unselectedLabelColor: globalState.theme.unselectedLabel,
                    // labelColor: globalState.theme.buttonIcon,
                    // isScrollable: true,
                    // indicatorColor: Colors.black,
                    // indicator: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(10), // Creates border
                    //     color: Colors.lightBlueAccent.withOpacity(.1)),
                    tabs: widget.circle.type == CircleType.VAULT
                        ? [
                       Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(AppLocalizations.of(context)!.options,
                              textScaler: const TextScaler.linear(1.0),
                              style: const TextStyle(fontSize: 18.0)),
                        ),
                      ),
                    ]
                        : [
                       Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(AppLocalizations.of(context)!.pERSONAL,
                              textScaler: const TextScaler.linear(1.0),
                              style: const TextStyle(fontSize: 18.0)),
                        ),
                      ),
                      Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              widget.circle.dm
                                  ? AppLocalizations.of(context)!.eNTIREDM
                                  : AppLocalizations.of(context)!.eNTIRECIRCLE,
                              textScaler: const TextScaler.linear(1.0),
                              style: const TextStyle(fontSize: 18.0)),
                        ),
                      )
                    ])),

          //drawer: NavigationDrawer(),
          body: TabBarView(
            children: widget.circle.type == CircleType.VAULT
                ? [
                    PersonalCircleSettings(
                      userCircleCache: widget.userCircleCache,
                      userFurnace: widget.userFurnace,
                      update: _updateUserCircle,
                      circle: widget.circle,
                      firebaseBloc: widget.firebaseBloc,
                      userFurnaces: widget.userFurnaces,
                    ),
                  ]
                : [
                    PersonalCircleSettings(
                      userCircleCache: widget.userCircleCache,
                      userFurnace: widget.userFurnace,
                      update: _updateUserCircle,
                      circle: widget.circle,
                      firebaseBloc: widget.firebaseBloc,
                      userFurnaces: widget.userFurnaces,
                    ),
                    CircleWideSettings(
                      userCircleCache: widget.userCircleCache,
                      userFurnace: widget.userFurnace,
                      circle: widget.circle,
                      circleBloc: widget.circleBloc,
                    )
                  ],
          ),
        ));

    return Scaffold(
      backgroundColor: globalState.theme.background,
      appBar: ICAppBar(
        title: widget.circle.type == CircleType.VAULT
            ? AppLocalizations.of(context)!.vaultSettings
            : widget.circle.dm
                ? AppLocalizations.of(context)!.directMessageSettings
                : AppLocalizations.of(context)!.circleSettings,
      ),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  makeHeader,
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                  ),
                  Expanded(child: body),
                  //makeBottom,
                ],
              ))),
    );
  }

  _updateUserCircle(UserCircle userCircle) {
    setState(() {
      _userCircleCache.prefName = userCircle.prefName;
    });
  }
}
