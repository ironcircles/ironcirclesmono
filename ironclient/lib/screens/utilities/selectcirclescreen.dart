import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/selectcircle.dart';

class SelectCircleScreen extends StatefulWidget {
  //final String buttonText;
  final Function selected;

  SelectCircleScreen({
    Key? key,
    required this.selected,
  }) : super(key: key);
  // FlutterDetail({Key key, this.flutterbug}) : super(key: key);
  // final String title;

  @override
  _SelectCircleScreenState createState() => _SelectCircleScreenState();
}

class _SelectCircleScreenState extends State<SelectCircleScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.selectACircleDMToShareTo,),
        //drawer: NavigationDrawer(),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: SelectCircle(
              selected: _selected,
            )));
  }

  _selected(UserFurnace userFurnace, UserCircleCache userCircleCache) {
    Navigator.pop(context);
    widget.selected(userFurnace, userCircleCache);


  }
}
