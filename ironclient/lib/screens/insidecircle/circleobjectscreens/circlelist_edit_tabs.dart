import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_edit.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/circlelist_edit_complete.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

final _formKey = GlobalKey<FormState>();

class CircleListEditTabs extends StatefulWidget {
  final UserCircleCache? userCircleCache;
  final UserFurnace? userFurnace;
  final CircleObject? circleObject;
  final bool isNew;
  final bool readOnly;
  //CircleListBloc _circleListBloc = CircleListBloc();

  const CircleListEditTabs(
      {Key? key,
      this.userCircleCache,
      this.userFurnace,
      this.circleObject,
      this.readOnly = false,
      required this.isNew})
      : super(key: key);

  @override
  _CircleListEditTabsState createState() => _CircleListEditTabsState();
}

class _CircleListEditTabsState extends State<CircleListEditTabs> {
  final TextEditingController _listName = TextEditingController();
  late CircleList _circleList;
  final bool _saveList = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final CircleListBloc _circleListBloc = CircleListBloc();

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _circleList = CircleList.deepCopy(widget.circleObject!.list!);

    if (_circleList.name != null) {
      _listName.text = _circleList.name!;
    }

    _circleListBloc.updated.listen((success) {
      if (mounted) {
        //FormattedSnackBar.showSnackbar(
        //  _scaffoldKey, "List created successfully", "", 2);
        // Navigator.of(context).pop();
        FocusScope.of(context).requestFocus(FocusNode());
        Navigator.pop(context, success);
      }
    }, onError: (err) {
      debugPrint("error $err");
      if (mounted)
        FormattedSnackBar.showSnackbarWithContext(
            context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    super.initState();
  }

  /*popReturnData() {
    //Navigator.of(cont,).pop(widget.userCircleCache);
    Navigator.pop(context, widget.userCircleCache);

    return Future<bool>.value(true);
  }*/

  _exit() {
    FocusScope.of(context).requestFocus(FocusNode());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final makeHeader =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      const Padding(padding: EdgeInsets.only(top: 0)),
      Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: globalState.theme.buttonDisabled,
                ),
                onPressed: () {
                  _circleList.name = _listName.text;

                  _pop();
                }),
            Expanded(
                flex: 1,
                child: Center(
                    child: Container(
                        constraints: BoxConstraints(
                            maxWidth: ScreenSizes.getFormScreenWidth(width)),
                        child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ExpandingLineText(
                              maxLength: TextLength.Smallest,
                              labelText:
                                  AppLocalizations.of(context)!.nameOfList,
                              maxLines: 4,
                              //counterText: 'asdfasf',
                              controller: _listName,
                              validator: (value) {
                                if (_saveList) {
                                  if (value.toString().isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .errorRequiredToSaveList;
                                  }
                                }
                                return null;
                              },
                            ))))),
          ]),
    ]);

    final uncheckable = CircleListEdit(
      circleObject: widget.circleObject,
      userCircleCache: widget.userCircleCache,
      userFurnace: widget.userFurnace,
      isNew: true,
      circleList: _circleList,
    );

    final body = DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          appBar: TabBar(
              dividerHeight: 0.0,
              unselectedLabelColor: globalState.theme.unselectedLabel,
              labelColor: globalState.theme.tabIndicatorRecipe,
              indicatorColor: globalState.theme.tabIndicatorRecipe,
              indicator: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  color: globalState.theme.tabBackground),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0),
              tabs: [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.oPENTASKS,
                        textScaler: const TextScaler.linear(1.0),
                        style: const TextStyle(fontSize: 14.0)),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                        AppLocalizations.of(context)!.completed.toUpperCase(),
                        textScaler: TextScaler.linear(1.0),
                        style: TextStyle(fontSize: 14.0)),
                  ),
                ),
              ]),

          //drawer: NavigationDrawer(),
          body: TabBarView(
            children: [
              CircleListEdit(
                circleObject: widget.circleObject,
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                isNew: true,
                circleList: _circleList,
              ),
              CircleListEditComplete(
                circleObject: widget.circleObject,
                userCircleCache: widget.userCircleCache,
                userFurnace: widget.userFurnace,
                isNew: true,
                circleList: _circleList,
              ),
              // FlutteringSettings()
            ],
          ),
        ));

    final makeBottom = SizedBox(
      height: 70.0,
      //width: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 0),
        child: Column(
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(children: <Widget>[
                /*Platform.isIOS
                    ? IconButton(
                  constraints: BoxConstraints(minWidth: 10),
                  onPressed: () {
                    KeyboardUtil.closeKeyboard(context);
                  },
                  icon: Icon(
                    Icons.expand_more,
                    color: globalState.theme.buttonIcon,
                  ),
                  iconSize: 20,
                )
                    : Container(),

                 */
                Expanded(
                    flex: 1, //lobalState.isDesktop() ? 0 : 1,
                    child: Center(
                      child: Container(
                          constraints: BoxConstraints(
                              maxWidth:
                                  ScreenSizes.getMaxButtonWidth(width, true)),
                          // margin: EdgeInsets.symmetric(
                          //     horizontal: ButtonType.getWidth(
                          //         MediaQuery.of(context).size.width)),
                          child: GradientButton(
                              text: AppLocalizations.of(context)!.uPDATELIST,
                              onPressed: () {
                                _updateList();
                              })),
                    )),
              ]),
            ]),
      ),
    );

    final _formWidget = Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            /*appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0), // here the desired height
    child:ICAppBar(
              title: 'Edit List',
            )),*/
            body: SafeArea(
                left: false,
                top: true,
                right: false,
                bottom: true,
                child: Padding(
                    padding:
                        const EdgeInsets.only(left: 5, right: 10, bottom: 0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            makeHeader,
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                            ),
                            Expanded(
                                child: widget.circleObject!.list!.checkable
                                    ? WrapperWidget(child: body)
                                    : uncheckable),
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                            ),
                            widget.readOnly ? Container() : makeBottom,
                          ],
                        ),
                        _showSpinner ? Center(child: spinkit) : Container(),
                      ],
                    )))));

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
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

  _pop() {
    if (CircleList.deepCompareChanged(
        widget.circleObject!.list!, _circleList)) {
      DialogYesNo.askYesNo(
          context,
          AppLocalizations.of(context)!.saveChangesTitle,
          AppLocalizations.of(context)!.saveChangesMessage,
          _updateList,
          _exit,
          false);
    } else {
      _exit();
    }
  }

  _updateList() {
    debugPrint('update list at ${DateTime.now()}');

    if (_showSpinner) return;

    if (_formKey.currentState!.validate()) {
      _showSpinner = true;

      _circleList.tasks!.removeWhere((element) => element.name == null);

      setState(() {
        _showSpinner = true;
      });

      _circleList.name = _listName.text;

      _circleListBloc.updateList(widget.userCircleCache!, widget.circleObject!,
          _circleList, _saveList, widget.userFurnace!);
    }
  }
}
