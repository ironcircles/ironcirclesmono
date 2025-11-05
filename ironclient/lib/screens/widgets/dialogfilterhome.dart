import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/expandinglinetext.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogFilterHome {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static filterHomePopup(
      {required BuildContext context,
      required List<UserFurnace> networks,
      required List<String> circleTypes,
      required Function setNetworkFilter,
      required Function setCircleTypeFilter,
      required Function sortByAlpha,
      required Function clear,
      required String nameFilter,
      required bool existingSort,
      required bool existingName,
      required Function sortByName,
      required String existingNetworkFilter,
      required String existingCircleFilter,
      required int homeTab}) async {
    await showDialog<String>(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
         backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          /*title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const Spacer(),
                Icon(
                  Icons.filter_list,
                  color: globalState.theme.button,
                  size: 30,
                ),
                /*ICText(
                  "  Filter Options",
                  textScaleFactor: globalState.dialogScaleFactor,
                  fontSize: 18,
                  color: globalState.theme.button,
                ),*/
                const Spacer(),
              ])),*/
          contentPadding: const EdgeInsets.all(10.0),
          content: FilterHome(
            scaffoldKey: scaffoldKey,
            networks: networks,
            circleTypes: circleTypes,
            setNetworkFilter: setNetworkFilter,
            sortByAlpha: sortByAlpha,
            clear: clear,
            existingSort: existingSort,
            existingName: existingName,
            sortByName: sortByName,
            setCircleTypeFilter: setCircleTypeFilter,
            existingNetworkFilter: existingNetworkFilter,
            existingCircleFilter: existingCircleFilter,
            existingNameFilter: nameFilter,
            homeTab: homeTab,
          ),
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;
  const _SystemPadding({Key? key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class FilterHome extends StatefulWidget {
  final Key scaffoldKey;
  final List<UserFurnace> networks;
  final List<String> circleTypes;
  final Function setNetworkFilter;
  final Function sortByAlpha;
  final bool existingSort;
  final bool existingName;
  final Function clear;
  final Function sortByName;
  final Function setCircleTypeFilter;
  final String existingNetworkFilter;
  final String existingCircleFilter;
  final String existingNameFilter;
  final int homeTab;

  const FilterHome({
    required this.scaffoldKey,
    required this.networks,
    required this.circleTypes,
    required this.setNetworkFilter,
    required this.clear,
    required this.sortByAlpha,
    required this.existingSort,
    required this.existingName,
    required this.sortByName,
    required this.setCircleTypeFilter,
    required this.existingNetworkFilter,
    required this.existingCircleFilter,
    required this.existingNameFilter,
    required this.homeTab,
  }
      //this.sortAlpha = false,
      );

  @override
  ItemsToPostState createState() => ItemsToPostState();
}

class ItemsToPostState extends State<FilterHome> {
  final String all = 'All';
  late bool _sortAlpha;
  late bool _sortName;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.existingNameFilter;
    _sortName = widget.existingName;
    _sortAlpha = widget.existingSort;
    if (widget.existingNetworkFilter.isNotEmpty) {
      _networkFilter = widget.existingNetworkFilter;
    }
    if (widget.existingCircleFilter.isNotEmpty) {
      _circleFilter = widget.existingCircleFilter;
    }

    //_circleTypes.add(all);
    _circleTypes.addAll(widget.circleTypes);

    //_networkAliases.add(all);
    for (UserFurnace network in widget.networks) {
      _networkAliases.add(network.alias!);
    }

    _networkAliases.sort((a, b) => a.compareTo(b));
  }

  String _networkFilter = '';
  String _circleFilter = '';
  final List<String> _networkAliases = [];
  final List<String> _circleTypes = [];

  Widget _networkFilterRow(String networkFilter) {
    return InkWell(
        onTap: () {
          if (networkFilter == _networkFilter) {
            widget.setNetworkFilter(all);

            setState(() {
              _networkFilter = '';
            });
          } else {
            widget.setNetworkFilter(networkFilter);
            setState(() {
              _networkFilter = networkFilter;
            });
          }
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 10),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                      child: ICText(networkFilter,
                          textScaleFactor: globalState.dialogScaleFactor,
                          color: networkFilter == _networkFilter
                              ? globalState.theme.bottomIcon
                              : globalState.theme.labelText,
                          fontSize: 15)),
                ])));
  }

  Widget _circleFilterRow(String circleFilter) {
    return InkWell(
        onTap: () {
          if (circleFilter == _circleFilter) {
            widget.setCircleTypeFilter(all);

            setState(() {
              _circleFilter = '';
            });
          } else {
            widget.setCircleTypeFilter(circleFilter);

            setState(() {
              _circleFilter = circleFilter;
            });
          }
        },
        child: Padding(
            padding:
                const EdgeInsets.only(right: 0, top: 10, bottom: 5, left: 15),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                      child: ICText(circleFilter,
                          textScaleFactor: globalState.dialogScaleFactor,
                          color: circleFilter == _circleFilter
                              ? globalState.theme.bottomIcon
                              : globalState.theme.labelText,
                          fontSize: 15)),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    final circleFilterWidget =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Flexible(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 10, top: 10),
            child: ICText(
              AppLocalizations.of(context)!.dialogFilterCircleType,
              fontSize: 16,
              color: globalState.theme.labelText,
              fontStyle: FontStyle.italic,
              //textDecoration: TextDecoration.underline,
            )),
        Flexible(
            child: _circleTypes.isNotEmpty
                ? ListView.builder(
                    itemCount: _circleTypes.length,
                    itemBuilder: (context, index) {
                      return _circleFilterRow(_circleTypes[index]);
                    },
                  )
                : Container())
      ]))
    ]);

    final networkFilterWidget = Column(children: [
      Row(children: [
        const Spacer(),
        ICText(
          AppLocalizations.of(context)!.dialogFilterNetworkOptions,
          textScaleFactor: globalState.dialogScaleFactor,
          fontSize: 18,
          color: globalState.theme.button,
        ),
        const Spacer()
      ]),
      const Padding(
        padding: EdgeInsets.only(top: 5),
      ),
      Expanded(
          child: _networkAliases.isNotEmpty
              ? ListView.builder(
                  itemCount: _networkAliases.length,
                  itemBuilder: (context, index) {
                    return _networkFilterRow(_networkAliases[index]);
                  },
                )
              : Container())
    ]);

    return SizedBox(
        //width: 200,
        height: 425,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          key: widget.scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                widget.homeTab == 0
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                      )
                    : Container(),
                widget.homeTab == 0
                    ? Row(children: [
                        const Spacer(),
                        ICText(
                          AppLocalizations.of(context)!.dialogFilterTitle,
                          textScaleFactor: globalState.dialogScaleFactor,
                          fontSize: 18,
                          color: globalState.theme.button,
                        ),
                        const Spacer()
                      ])
                    : Container(),
                widget.homeTab == 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, left: 10),
                        child: Row(
                          children: [
                            ICText(
                              AppLocalizations.of(context)!.dialogFilterSortAlphabetically,
                              fontSize: 16,
                            ),
                            IconButton(
                                onPressed: () {
                                  widget.sortByAlpha();
                                  setState(() {
                                    _sortAlpha = !_sortAlpha;
                                  });
                                },
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                constraints: const BoxConstraints(),
                                iconSize: 27 - globalState.scaleDownIcons,
                                icon: Icon(Icons.sort_by_alpha,
                                    color: _sortAlpha
                                        ? globalState.theme.menuIconsAlt
                                        : globalState.theme.menuIcons)),
                            const Spacer(),
                          ],
                        ))
                    : Container(),
                widget.homeTab == 0
                    ? Padding(
                        padding:
                            const EdgeInsets.only(left: 8, top: 5, bottom: 0),
                        child: Row(children: [
                          Expanded(
                            child: ExpandingLineText(
                              onChanged: (value) {
                                widget.sortByName(_searchController.text);
                              },
                              labelText: AppLocalizations.of(context)!.dialogFilterByName,
                              controller: _searchController,
                            ),
                          ),
                        ]),
                      )
                    : Container(),
                widget.homeTab == 0
                    ? Flexible(child: circleFilterWidget)
                    : Container(),
                widget.homeTab == 0
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        child: Divider(
                          color: Colors.grey,
                          height: 2,
                          thickness: 2,
                          indent: 0,
                          endIndent: 0,
                        ))
                    : Container(),
                globalState.isDesktop() ? Container() : Expanded(flex: 2, child: networkFilterWidget),
                /*const VerticalDivider(
                    width: 20,
                    thickness: 1,
                    indent: 20,
                    endIndent: 0,
                    color: Colors.grey,
                  ),*/
                //Expanded(child: circleFilterWidget),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                ),
                Row(
                  children: [
                    const Spacer(),
                    GradientButtonDynamic(
                        color: globalState.theme.labelText,
                        onPressed: () {
                          widget.clear();
                          Navigator.pop(context);
                        },
                        text: AppLocalizations.of(context)!.dialogFilterClear),
                    const Padding(padding: EdgeInsets.only(left: 10)),
                    GradientButtonDynamic(
                        onPressed: () {
                          //widget.sortByName(_searchController.text);
                          Navigator.pop(context);
                        },
                        text: AppLocalizations.of(context)!.filter),
                  ],
                )
              ]),
        ));
  }
}
