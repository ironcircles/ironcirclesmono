import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/members_invitations.dart';
import 'package:ironcirclesapp/screens/insidecircle/members_list.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';

class Members extends StatelessWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;

  const Members(
      {Key? key, required this.userCircleCache, required this.userFurnace, required this.userFurnaces})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: PreferredSize(
            preferredSize: const Size(30.0, 40.0),
            child: TabBar(
              dividerHeight: 0.0,
              padding: const EdgeInsets.only(left: 3, right: 3),
              //indicatorSize: TabBarIndicatorSize.label,
              unselectedLabelColor: globalState.theme.unselectedLabel,
              labelColor: globalState.theme.buttonIcon,
              //isScrollable: true,
              indicatorColor: Colors.black,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Creates border
                  color: Colors.lightBlueAccent.withOpacity(.1)),
              tabs:  [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.invitations, //"INVITATIONS",
                        textScaler: const TextScaler.linear(1.0), style: TextStyle(fontSize: 18.0 - globalState.scaleDownTextFont)),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.mEMBERS, //"MEMBERS",
                        textScaler: const TextScaler.linear(1.0), style: TextStyle(fontSize: 18.0- globalState.scaleDownTextFont)),
                  ),
                ),
              ],
            )),

        //drawer: NavigationDrawer(),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: TabBarView(
              children: [
                MemberInvitations(
                  userCircleCache: userCircleCache,
                  userFurnace: userFurnace,
                ),
                MemberList(
                  userCircleCache: userCircleCache,
                  userFurnace: userFurnace, userFurnaces: userFurnaces,
                  circle: userCircleCache.cachedCircle!,
                ),
                // FlutteringSettings()
              ],
            )),
      ),
    );

    return Scaffold(
      appBar: ICAppBar(
        title: AppLocalizations.of(context)!.circleMembers, //'Circle Members',
      ),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      body: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 10, bottom: 5, top: 0),
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
