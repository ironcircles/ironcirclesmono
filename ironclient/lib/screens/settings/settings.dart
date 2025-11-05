import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/settings/settings_general.dart';
import 'package:ironcirclesapp/screens/settings/settings_security.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class TAB {
  static const int PROFILE = 0;
  //static const int PREMIUM = 1;
  static const int SECURITY = 1;
  //static const int GENERAL = 3;
  //static const int TRANSPARENCY = 3;
}

class Settings extends StatelessWidget {
  final int tab;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Settings({
    Key? key,
    this.tab = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 2,
      initialIndex: tab,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: PreferredSize(
            preferredSize: const Size(30.0, 40.0),
            child: TabBar(
              dividerHeight: 0.0,
              padding: const EdgeInsets.only(left: 3, right: 3),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: -10.0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
              tabAlignment: globalState.isDesktop() ? TabAlignment.center : TabAlignment.start,
              unselectedLabelColor: globalState.theme.unselectedLabel,
              labelColor: globalState.theme.buttonIcon,
              isScrollable: true,
              indicatorColor: Colors.black,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Creates border
                  color: Colors.lightBlueAccent.withOpacity(.1)),

              tabs: [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.general, textScaler: const TextScaler.linear(1.0), style: const TextStyle(fontSize: 15.0)),
                  ),
                ),
                // Tab(
                //   child: Align(
                //     alignment: Alignment.center,
                //     child: Text(AppLocalizations.of(context)!.privacy, textScaler: TextScaler.linear(1.0),style: TextStyle(fontSize: 15.0)),
                //   ),
                // ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.security, textScaler: const TextScaler.linear(1.0),style: const TextStyle(fontSize: 15.0)),
                  ),
                ),
                /*Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("GENERAL", textScaleFactor: 1.0,style: TextStyle(fontSize: 15.0)),
                  ),
                ),*/

                // Text('TRANSPARENCY',
                //    style: TextStyle(color: globalState.theme.tabText, fontSize: 18.0)),
                // Text('FLUTTERIN', style: TextStyle(color: Colors.white, fontSize: 18.0)),
                //Tab(icon: Icon(Icons.directions_car)),
                //Tab(icon: Icon(Icons.directions_transit)),
                //  Tab(icon: Icon(Icons.directions_bike)),
              ],
            )),
        body: TabBarView(
          children: [
            SettingsGeneral(
              userFurnace: globalState.userFurnace,
              fromFurnaceManager: false,
            ),
            // SettingsPremium(
            //   userFurnace: globalState.userFurnace,
            //   fromFurnaceManager: false,
            // ),
            SettingsSecurity(
              user: globalState.user,
              userFurnace: globalState.userFurnace,
            ),
           /* SettingsGeneral(
              user: globalState.user,
              userFurnace: globalState.userFurnace,
            ),

            */

            //TransparencySettings(),
            // FlutteringSettings()
          ],
        ),
      ),
    );



    return Scaffold(
      key: _scaffoldKey,
      appBar: ICAppBar(title: AppLocalizations.of(context)!.settings,),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 10, bottom: 5, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: body),
              //makeBottom,
            ],
          )),
    );
  }
}
