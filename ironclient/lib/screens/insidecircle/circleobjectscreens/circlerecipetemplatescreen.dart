import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circlerecipetemplate_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class CircleRecipeTemplateScreen extends StatefulWidget {
  final List<UserFurnace>? userFurnaces;

  const CircleRecipeTemplateScreen({
    Key? key,
    this.userFurnaces,
  }) : super(key: key);

  @override
  _CircleRecipeTemplateScreenState createState() =>
      _CircleRecipeTemplateScreenState();
}

class _CircleRecipeTemplateScreenState
    extends State<CircleRecipeTemplateScreen> {
  ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  CircleRecipeTemplateBloc _circleRecipeTemplateBloc =
      CircleRecipeTemplateBloc();
  UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  List<CircleRecipeTemplate> _templates = [];

  bool filter = false;
  //var _tapPosition;
  final double _iconSize = 45;

  @override
  void initState() {
    _circleRecipeTemplateBloc.circleRecipeTemplate.listen((templates) {
      if (mounted)
        setState(() {
          _templates = templates;
        });
    }, onError: (err) {
      debugPrint("CircleListMasterScreen.circleListMaster: $err");
    }, cancelOnError: false);

    _circleRecipeTemplateBloc.deleted.listen((circleListTemplates) {
      setState(() {
        _templates.remove(circleListTemplates);
      });
    }, onError: (err) {
      debugPrint("CircleListMasterScreen.deleted: $err");
    }, cancelOnError: false);

    _userFurnaceBloc.userfurnaces.listen((userfurnaces) {
      //get the list of items
      _circleRecipeTemplateBloc.get(userfurnaces!, true);
    }, onError: (err) {
      debugPrint("CircleListMasterScreen.userfurnaces: $err");
    }, cancelOnError: false);

    _userFurnaceBloc.request(globalState.user.id);

    super.initState();
  }

  @override
  void dispose() {
    _circleRecipeTemplateBloc.dispose();
    _userFurnaceBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Padding row(int index, CircleRecipeTemplate item) => Padding(
        padding: const EdgeInsets.only(top: 0, left: 15, right: 0, bottom: 0),
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(
                flex: 1,
                child: InkWell(
                    onTap: () => _tapHandler(item),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            top: 5, left: 0, right: 0, bottom: 5),
                        child: Text(item.name!,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            style: TextStyle(
                                fontSize: 18,
                                color: globalState.theme.buttonIcon))))),
            ClipOval(
              child: Material(
                color: globalState.theme.background, // button color
                child: InkWell(
                  splashColor:
                      globalState.theme.buttonIconSplash, // inkwell color
                  child: SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: const Icon(Icons.delete)),
                  onTap: () {
                    _askToDelete(item);
                  },
                ),
              ),
            ),
          ])
        ]));

    final makeList = Container(
        // child: SingleChildScrollView(
        //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ListView.separated(
            // Let the ListView know how many items it needs to build
            itemCount: _templates.length,
            //reverse: true,
            //shrinkWrap: true,
            //scrollDirection: Scro,
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: 1500,
            //addAutomaticKeepAlives: true,

            separatorBuilder: (context, index) => Divider(
                  color: globalState.theme.divider,
                ),
            itemBuilder: (context, index) {
              //debugPrint(index);
              final CircleRecipeTemplate item = _templates[index];

              //return Text(item.name);
              return row(index, item);

              //return makeCard(index, item);
            }));

    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: const ICAppBar(
          title: 'Select a list template',
        ),
        //drawer: NavigationDrawer(),
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
                    //makeFilter,
                    // Spacer(),
                    Expanded(
                      child: makeList,
                    ),
                  ],
                ))),
      ),
    );
  }

  void _tapHandler(CircleRecipeTemplate template) async {
    Navigator.pop(context, template);
  }

  void delete(CircleRecipeTemplate template) {
    _circleRecipeTemplateBloc.delete(template);
  }

  void _askToDelete(CircleRecipeTemplate template) async {
    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.confirmDeleteTitle,
        AppLocalizations.of(context)!.confirmDeleteMessage,
        delete,
        null,
        false,
        template);
  }
}
