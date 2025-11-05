/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/screens/circles/circle_manage.dart';
import 'package:ironcirclesapp/screens/circles/circle_new.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

import 'package:ironcirclesapp/models/export_models.dart';

class ManageCirclesTab extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final UserCircleBloc userCircleBloc;

  ManageCirclesTab({
    Key? key,
    required this.userFurnaces,
    required this.userCircleBloc,
    //this.tab = 0,
  }) : super(key: key);

  @override
  _CircleManagementTabsState createState() => _CircleManagementTabsState();
}

class _CircleManagementTabsState extends State<ManageCirclesTab> {
  //final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: Scaffold(
            backgroundColor: globalState.theme.background,
            appBar: PreferredSize(
                preferredSize: Size(30.0, 40.0),
                child:TabBar(
                padding: EdgeInsets.only(left: 3, right: 3),
                //indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor:
                globalState.theme.unselectedLabel,
                labelColor: globalState.theme.buttonIcon,
                //isScrollable: true,
                indicatorColor: Colors.black,
                indicator: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(10), // Creates border
                    color: Colors.lightBlueAccent.withOpacity(.1)),
                tabs: [
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text("CREATE", style: TextStyle(fontSize: 16.0)),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child:
                          Text("MUTE/CLOSE", style: TextStyle(fontSize: 16.0)),
                    ),
                  ),
                ])),
            body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: true,
              child: TabBarView(
                children: [
                  CircleNew(),
                  ManageCircles(userCircleBloc: widget.userCircleBloc,),
                  //TransparencySettings(),
                  // FlutteringSettings()
                ],
              ),
            )));

    final topAppBar = AppBar(
      backgroundColor: globalState.theme.appBar,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      elevation: 0.1,
      title: Text("Manage Circles",
          style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      appBar: topAppBar,
      //drawer: NavigationDrawer(),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding: EdgeInsets.only(left: 20, right: 10, bottom: 5, top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(child: body),
                  //makeBottom,
                ],
              ))),
    );
  }
}

 */
