import 'dart:io';
import 'package:store_redirect/store_redirect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/leftnavigation/aboutus.dart';
import 'package:ironcirclesapp/screens/leftnavigation/helpcenter.dart';
import 'package:ironcirclesapp/screens/leftnavigation/metricsscreen.dart';
import 'package:ironcirclesapp/screens/leftnavigation/releases.dart';
import 'package:ironcirclesapp/screens/leftnavigation/transfermanager.dart';
import 'package:ironcirclesapp/screens/login/landing.dart';
import 'package:ironcirclesapp/screens/payment/ironstore.dart' hide TAB;
import 'package:ironcirclesapp/screens/payment/ironstore_ironcoin.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_privacyplus.dart';
import 'package:ironcirclesapp/screens/settings/settings.dart';
import 'package:ironcirclesapp/screens/utilities/browser.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ICNavigationDrawer extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final UserCircleBloc userCircleBloc;
  const ICNavigationDrawer(
      {required this.userFurnaces, required this.userCircleBloc});

  @override
  State<StatefulWidget> createState() {
    return NavigationDrawerState();
  }
}

class NavigationDrawerState extends State<ICNavigationDrawer> {
  final String _version = globalState.version; //'v1.0.1+22';
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  // late List<UserFurnace> _userFurnaces;
  final UserFurnace _authServer = globalState.userFurnace!;
  int _counter = 0;
  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  _launchStore() {
    Navigator.pop(context);

    if (Platform.isAndroid) {
      // LaunchReview.launch(
      //   writeReview: false,
      //   androidAppId: "com.ironcircles.ironcirclesapp",
      //   //iOSAppId: "585027354",
      // );

      StoreRedirect.redirect(
        androidAppId: "com.ironcircles.ironcirclesapp",
        iOSAppId: "585027354",
      );
    } else if (Platform.isIOS) {
      launchUrl(Uri.parse('https://apps.apple.com/app/id/1634856740'),
          mode: LaunchMode.externalApplication);
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux){
      launchUrl(Uri.parse('https://ironcircles.com/install'),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    // _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
    //   if (mounted) {
    //     setState(() {
    //       if (userFurnaces == null) {
    //         //_logout(context);
    //       } else {
    //         _userFurnaces = userFurnaces;
    //
    //         /*for (UserFurnace userFurnace in _userFurnaces) {
    //           if (userFurnace.connected!) {
    //             if (userFurnace.authServer!) {
    //               _authServer = userFurnace;
    //             }
    //           }
    //         }*/
    //       }
    //     });
    //   }
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);

    IronCoinBloc.ironCoinFetched.listen((fetched) {
      if (mounted) {
        setState(() {
          //coins = globalState.ironCoinWallet.balance;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    //_userFurnaceBloc.request(globalState.user.id);
    IronCoinBloc().fetchCoins();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _versionNumber = InkWell(
        onTap: globalState.updateAvailable && !globalState.isDesktop() ? _launchStore : _openReleases,
        child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0),
            child: Text(
              _version,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(
                  color: globalState.updateAvailable
                      ? Colors.pink
                      : globalState.theme.username),
            )));

    if (widget.userFurnaces.isEmpty) {
      return Container();
    } else {
      _counter = 0;

      return Theme(
          data: Theme.of(context).copyWith(
              canvasColor: globalState.theme.drawerCanvas,
              splashColor: globalState.theme.drawerSplash),
          child: SafeArea(
            top: true,
            child: Drawer(
                //backgroundColor: globalState.theme.drawerCanvas,
                child: Container(
                    color: globalState.theme.drawerCanvas,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                            color: globalState.theme.background,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 0, left: 5, right: 10, bottom: 0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          SizedBox(
                                            width: 115,
                                            height: 115.0,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.pop(context);

                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            Settings(
                                                                tab: TAB
                                                                    .PROFILE)));
                                              },
                                              child: AvatarWidget(
                                                  radius: 115,
                                                  isUser: true,
                                                  interactive: false,
                                                  user: globalState.user,
                                                  userFurnace:
                                                      globalState.userFurnace!,
                                                  refresh: _doNothing),
                                            ),
                                          ),
                                        ]),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                    ),
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 10),
                                          ),
                                          globalState.user.username == null
                                              ? Text("",
                                                  style: TextStyle(
                                                      color: globalState
                                                          .theme.username,
                                                      fontSize: 14),
                                                  textScaler:
                                                      const TextScaler.linear(
                                                          1.0))
                                              : Expanded(
                                                  child: InkWell(
                                                      onTap: () {
                                                        Navigator.pop(context);

                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    Settings(
                                                                        tab: TAB
                                                                            .PROFILE)));
                                                      },
                                                      child: Text(
                                                        globalState
                                                            .user.username!,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: globalState
                                                                .theme.username,
                                                            fontSize: 14),
                                                        textScaler:
                                                            const TextScaler
                                                                .linear(1.0),
                                                      ))),
                                        ]),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 10),
                                        ),
                                        Text('${AppLocalizations.of(context)!.network}: ' , //'Network: ',
                                            textScaler:
                                                const TextScaler.linear(1.0),
                                            style: ICTextStyle.getStyle(context: context, 
                                                color: globalState
                                                    .theme.buttonDisabled,
                                                fontStyle: FontStyle.italic,
                                                fontSize: 14)),
                                        Expanded(
                                            child: InkWell(
                                                highlightColor:
                                                    Colors.transparent,
                                                splashColor: Colors.transparent,
                                                onTap: () {
                                                  _counter += 1;

                                                  if (_counter > 4)
                                                    globalState.user
                                                        .allowClosed = true;
                                                  globalState.userSetting
                                                      .allowHidden = true;
                                                },
                                                child: Text(_authServer.alias!,
                                                    overflow: TextOverflow.fade,
                                                    softWrap: false,
                                                    maxLines: 1,
                                                    textScaler:
                                                        const TextScaler.linear(
                                                            1.0),
                                                    style: ICTextStyle.getStyle(context: context, 
                                                        color: globalState
                                                            .theme.furnace,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 14)))),
                                        /*globalState.userSetting.accountType !=
                                        AccountType.FREE
                                    ? const Spacer()
                                    : Container(),*/

                                        globalState.userSetting.accountType !=
                                                    AccountType.FREE &&
                                                !globalState.updateAvailable
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 5),
                                                child: _versionNumber)
                                            : Container()
                                      ], // alignment: FractionalOffset.topLeft,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                    ),
                                    InkWell(
                                        onTap: () {
                                          Navigator.pop(context);

                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const IronStoreIronCoin(),
                                              ));
                                        },
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                              ),
                                              ClipOval(
                                                  child: Image.asset(
                                                'assets/images/ironcoin.png',
                                                height: 20,
                                                width: 20,
                                                fit: BoxFit.fitHeight,
                                              )),
                                              const Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 3)),
                                              Text(
                                                  formatter.format(globalState
                                                      .ironCoinWallet.balance),
                                                  style: TextStyle(
                                                      color: globalState
                                                          .theme.buttonDisabled,
                                                      fontSize: 14),
                                                  textScaler:
                                                      const TextScaler.linear(
                                                          1.0))
                                            ])),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                    ),
                                    globalState.userSetting.accountType ==
                                            AccountType.FREE
                                        ? Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 10),
                                                ),
                                                GradientButtonDynamic(
                                                  text: AppLocalizations.of(context)!.upgradeToPrivacyPlus,
                                                  onPressed: () {
                                                    Navigator.pop(context);

                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const IronStorePrivacyPlus(
                                                                  fromFurnaceManager:
                                                                      false,
                                                                )));
                                                  },
                                                ),
                                                const Spacer(),
                                                globalState.updateAvailable
                                                    ? Container()
                                                    : _versionNumber,
                                              ])
                                        : Container(),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                    ),
                                    globalState.updateAvailable && !globalState.isDesktop()
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10, top: 0, bottom: 0),
                                            child: InkWell(
                                                onTap: _launchStore,
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 0,
                                                            top: 9,
                                                            bottom: 9,
                                                            right: 5),
                                                    decoration: BoxDecoration(
                                                        color: Colors.pink
                                                            .withOpacity(.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 10),
                                                          ),
                                                          ICText(
                                                            AppLocalizations.of(context)!.updateAvailable,
                                                            //'UPDATE AVAILABLE',
                                                            fontSize: 16 -
                                                                globalState
                                                                    .scaleDownTextFont,
                                                            textScaleFactor:
                                                                1.0,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontFamily:
                                                                'Righteous',
                                                            color: Colors.pink,
                                                          ),
                                                          const Spacer(),
                                                          _versionNumber,
                                                        ]))))
                                        : Container(),
                                  ]),
                            )),
                        Container(
                            color: globalState.theme.drawerCanvas,
                            child: ListView(
                                padding: const EdgeInsets.only(top: 0),
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 25),
                                    leading: Icon(Icons.store,
                                        color:
                                            globalState.theme.drawerItemText),
                                    title: Text(
                                      AppLocalizations.of(context)!.ironStore,
                                      style: TextStyle(
                                          color:
                                              globalState.theme.drawerItemText),
                                      textScaler: TextScaler.linear(
                                          globalState.menuScaleFactor),
                                    ),
                                    onTap: () {
                                      //_launchURL(context);
                                      Navigator.pop(context);

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const IronStore(),
                                          ));
                                    },
                                  ),
                                  globalState.userSetting.minor == false && (Platform.isAndroid || Platform.isIOS)
                                      ? (ListTile(
                                          contentPadding:
                                              const EdgeInsets.only(left: 25),
                                          leading: Icon(Icons.web,
                                              color: globalState
                                                  .theme.drawerItemText),
                                          title: Text(
                                            AppLocalizations.of(context)!.incognitoBrowser,
                                            style: TextStyle(
                                                color: globalState
                                                    .theme.drawerItemText),
                                            textScaler: const TextScaler.linear(1),
                                          ),
                                          onTap: () {
                                            //_launchURL(context);
                                            Navigator.pop(context);

                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Browser(),
                                                ));
                                          },
                                        ))
                                      : Container(),
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 25),
                                    leading: Icon(Icons.cloud_download,
                                        color:
                                            globalState.theme.drawerItemText),
                                    title: Text(
                                      AppLocalizations.of(context)!.transferManager,
                                      textScaler: const TextScaler.linear(1),
                                      style: TextStyle(
                                          color:
                                              globalState.theme.drawerItemText),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  TransferManager(
                                                    userFurnaces:
                                                        widget.userFurnaces,
                                                  )));

                                      /* Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TransferManagerInProgress(
                                        userFurnaces: _userFurnaces,
                                      )),
                              ModalRoute.withName("/home"));

                          */
                                    },
                                  ),

                                  //const Spacer(),
                                  const Divider(
                                    color: Colors.grey,
                                    height: 2,
                                    thickness: 2,
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                                  globalState.user.role != Role.IC_ADMIN
                                      ? Container()
                                      : ListTile(
                                          contentPadding:
                                              const EdgeInsets.only(left: 25),
                                          leading: Icon(Icons.bar_chart,
                                              color: globalState
                                                  .theme.drawerItemTextAlt),
                                          title: Text(
                                            AppLocalizations.of(context)!.metrics,
                                            textScaler: const TextScaler.linear(1),
                                            style: TextStyle(
                                                color: globalState
                                                    .theme.drawerItemTextAlt),
                                          ),
                                          onTap: () {
                                            //_launchURL(context);
                                            Navigator.pop(context);

                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MetricsScreen(),
                                                ));
                                          },
                                        ),
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 25),
                                    leading: Icon(Icons.settings,
                                        color: globalState
                                            .theme.drawerItemTextAlt),
                                    title: Text(
                                      AppLocalizations.of(context)!.settings,
                                      textScaler: const TextScaler.linear(1),
                                      style: TextStyle(
                                          color: globalState
                                              .theme.drawerItemTextAlt),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Settings(),
                                          ));
                                    },
                                  ),
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 25),
                                    leading: Icon(Icons.help,
                                        color: globalState
                                            .theme.drawerItemTextAlt),
                                    title: Text(
                                      AppLocalizations.of(context)!.helpCenter,
                                      textScaler: const TextScaler.linear(1),
                                      style: TextStyle(
                                          color: globalState
                                              .theme.drawerItemTextAlt),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HelpCenter(),
                                          ));
                                    },
                                  ),
                                  /*ListTile(
                  contentPadding: const EdgeInsets.only(left: 25),
                  leading: Icon(Icons.bug_report,
                      color: globalState.theme.drawerItemText),
                  title: Text(
                    'Issues and Requests',
                    textScaleFactor: globalState.menuScaleFactor,
                    style: TextStyle(
                        color: globalState.theme.drawerItemText),
                  ),
                  onTap: () {
                    //_launchURL(context);
                    Navigator.pop(context);

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportIssue(),
                        ));
                  },
                ),*/

                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 25),
                                    leading: Icon(Icons.info,
                                        color: globalState
                                            .theme.drawerItemTextAlt),
                                    title: Text(
                                      AppLocalizations.of(context)!.aboutIronCircles,
                                      textScaler: const TextScaler.linear(1),
                                      style: TextStyle(
                                          color: globalState
                                              .theme.drawerItemTextAlt),
                                    ),
                                    onTap: () {
                                      //_launchURL(context);
                                      Navigator.pop(context);

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AboutUs(),
                                          ));
                                    },
                                  ),
                                  /*ListTile(
                  contentPadding: const EdgeInsets.only(left: 25),
                  leading:
                      Icon(Icons.logout, color: globalState.theme.labelText),
                  title: Text(
                    'Logout',
                    textScaleFactor: globalState.menuScaleFactor,
                    style: TextStyle(color: globalState.theme.labelText),
                  ),
                  onTap: () {
                    _logout(context);
                  },
                ),*/
                                ])),
                        const Spacer(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: IconButton(
                                    icon: Icon(Icons.logout,
                                        color: globalState
                                            .theme.drawerItemTextAlt),
                                    onPressed: () {
                                      _logout(context);
                                    },
                                  )),
                              Expanded(flex: 2, child: Container()),
                            ]),
                        /*Padding(
                      padding: const EdgeInsets.all(5),
                      child: IconButton(
                        icon: Icon(Icons.help,
                            color: globalState.theme.drawerItemTextAlt),
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Tutorials(),
                              ));
                        },
                      )),
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(Icons.settings,
                            color: globalState.theme.drawerItemTextAlt),
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Settings(),
                              ));
                        },
                      )),
                ]),

                 */
                      ],
                    ))),
          ));
      //  body: _getDrawerItemScreen(_selectedIndex),
    }
  }

  _doNothing() {}

  _openReleases() {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Releases()),
    );
  }

  _yes() async {
    AuthenticationBloc authenticationBloc = AuthenticationBloc();

    FirebaseBloc firebaseBloc =
        Provider.of<FirebaseBloc>(context, listen: false);

    authenticationBloc.logout(firebaseBloc, globalState.user.id!);

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Landing()),
        (Route<dynamic> route) => false);
  }

  _no() {}

  _logout(BuildContext context) async {
    if (globalState.userFurnace!.password != null &&
        globalState.userFurnace!.password!.isNotEmpty &&
        (kReleaseMode || Urls.testingReleaseMode)) {
      DialogNotice.showNoticeOptionalLines(context, AppLocalizations.of(context)!.passwordNotSetTitle,
          AppLocalizations.of(context)!.passwordNotSetMessageOnExit, false);
    } else
      DialogYesNo.askYesNo(context, AppLocalizations.of(context)!.logoutTitle,
          AppLocalizations.of(context)!.logoutMessage, _yes, _no, false);
  }
}
