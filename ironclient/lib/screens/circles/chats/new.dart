/*import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/circles/chats/new_circle.dart';
import 'package:ironcirclesapp/screens/circles/chats/new_dm.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

import 'package:ironcirclesapp/models/export_models.dart';

class New extends StatelessWidget {
  final List<UserFurnace> userFurnaces;
  final List<UserCircleCache> userCircleCaches;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  New({Key? key, required this.userFurnaces, required this.userCircleCaches})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: PreferredSize(
            preferredSize: const Size(30.0, 30.0),
            child: TabBar(
              padding: const EdgeInsets.only(left: 3, right: 3),
              //indicatorSize: TabBarIndicatorSize.label,
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
                    child: Text("Circle",
                        textScaleFactor: 1.0, style: TextStyle(fontSize: 15.0)),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Direct Message",
                        textScaleFactor: 1.0, style: TextStyle(fontSize: 15.0)),
                  ),
                ),
              ],
            )),
        body: TabBarView(
          children: [
            NewCircle(),
            NewDM(
              userFurnaces: userFurnaces,
              userCircleCaches: userCircleCaches,
            ),
          ],
        ),
      ),
    );

    return SafeArea(
        left: false,
        top: false,
        right: false,
        bottom: true,
        child:Scaffold(
      key: _scaffoldKey,
          //extendBodyBehindAppBar: true,
      appBar: ICAppBar(
        title: 'Create New',
      ),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 10, bottom: 0, top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: body),
              //makeBottom,
            ],
          )),
    ));
  }
}

 */
