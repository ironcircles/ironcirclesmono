import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_tabs.dart';
import 'package:ironcirclesapp/screens/login/networkmanager_add.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:provider/provider.dart';

class NetworkManager extends StatefulWidget {
  final String? toast;
  final HomeNavToScreen openScreen;
  final UserFurnaceBloc userFurnaceBloc;

  const NetworkManager(
      {Key? key,
      this.toast,
      required this.openScreen,
      required this.userFurnaceBloc})
      : super(key: key);

  // final String title;

  @override
  FurnaceManagerState createState() => FurnaceManagerState();
}

class FurnaceManagerState extends State<NetworkManager> {
  late List<UserFurnace> _userFurnaces;

  late HostedFurnaceBloc _hostedFurnaceBloc;
  final double _iconSize = 25;
  final double _floatingActionSize = 55;
  String? _toast;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late GlobalEventBloc _globalEventBloc;
  double radius = 50;

  bool loaded = false;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    //setup();

    //WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));
    _toast = widget.toast;

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _globalEventBloc.refreshHome.listen((refresh) {
      widget.userFurnaceBloc.request(globalState.user.id!);
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    //_checkClipBoardData();

    super.initState();

    _globalEventBloc.progressFurnaceImageIndicator.listen((success) {
      if (mounted) setState(() {});
    });

    _hostedFurnaceBloc.imageDownloaded.listen((userFurnace) {
      if (mounted)
        setState(() {
          int index = _userFurnaces
              .indexWhere((element) => element.id == userFurnace.id);

          if (index != -1) {
            _userFurnaces[index].hostedFurnaceImageId =
                userFurnace.hostedFurnaceImageId;
          }
        });
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.imageChanged.listen((UserFurnace userFurnace) {
      if (mounted)
        setState(() {
          int index = _userFurnaces
              .indexWhere((element) => element.id == userFurnace.id);

          if (index != -1) {
            _userFurnaces[index].hostedFurnaceImageId =
                userFurnace.hostedFurnaceImageId;
          }
        });
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    widget.userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      if (mounted && userFurnaces != null) {
        for (UserFurnace furnace in userFurnaces) {
          ///fire all of these off at once to run in parallel
          _hostedFurnaceBloc.getHostedFurnace(_globalEventBloc, furnace);
        }

        if (widget.openScreen != HomeNavToScreen.nothing &&
            globalState.homeShortCutResultScreen != HomeNavToScreen.nothing) {
          globalState.homeShortCutResultScreen = HomeNavToScreen.nothing;
          add(context, userFurnaces);
        }

        ///don't need a setstate because the furnace list is built with a stream builder
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showToast(context);
    });

    widget.userFurnaceBloc.request(globalState.user.id!);
  }

  _showToast(BuildContext context) {
    if (_toast != null) {
      FormattedSnackBar.showSnackbarWithContext(
          context, widget.toast!, "", 2, false);
      _toast = null;
    }
  }

  @override
  void dispose() {
    widget.userFurnaceBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //userFurnaceBloc.request(globalState.user.id, false);

    ListTile makeListTile(UserFurnace userFurnace) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
              padding: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          width: 1.0, color: globalState.theme.boxOutline))),
              child: ClipOval(
                  child: FileSystemService.returnAnyFurnaceImagePath(
                              userFurnace.userid!) !=
                          null
                      ? Image.file(
                          File(FileSystemService.returnAnyFurnaceImagePath(
                              userFurnace.userid!)!),
                          key: GlobalKey(),
                          height: radius,
                          width: radius,
                          fit: BoxFit.cover)
                      : Image.asset('assets/images/ios_icon.png',
                          height: radius,
                          width: radius,
                          fit: BoxFit.fitHeight))),
          title: ICText(
            userFurnace.alias!,
            textScaleFactor: globalState.cardScaleFactor,
            color: globalState.theme.furnace,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            fontWeight: FontWeight.bold,
          ),
          // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

          subtitle: Row(
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: userFurnace.connected!
                      ? ICText(
                          AppLocalizations.of(context)!.connected,
                          textScaleFactor: 1.0,
                          fontSize: 13,
                          color: globalState.theme.buttonIcon,
                        )
                      : ICText(
                          AppLocalizations.of(context)!.disconnected,
                          textScaleFactor: 1.0,
                          fontSize: 13,
                          color: globalState.theme.warning,
                        )),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: ICText(userFurnace.username!,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textScaleFactor: 1.0,
                        color: globalState.theme.textFieldPerson)),
              )
            ],
          ),
          trailing: Icon(Icons.keyboard_arrow_right,
              color: globalState.theme.menuIcons, size: 30.0),
          onTap: () {
            openDetail(context, userFurnace);
          },
        );

    Card makeCard(UserFurnace userFurnace) => Card(
          color: globalState.theme.card,
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: makeListTile(userFurnace),

          /* child: Container(
            decoration: BoxDecoration(
                color: Color(
                    0xFF404040) /*color: Color.fromRGBO(64, 75, 96, .9)*/),
            child: makeListTile(flutterbug),
          ),*/
        );

    Widget makeBody(List<UserFurnace> userFurnaces) => ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: userFurnaces.length,
          itemBuilder: (BuildContext context, int index) {
            UserFurnace furnace = userFurnaces[index];
            return makeCard(furnace);
          },
        );

    return Scaffold(
      key: _scaffoldKey,
      //backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
      backgroundColor: globalState.theme.background,
      //drawer: NavigationDrawer(),
      //body: (userFurnaces is null) :makeBody ? null

      body: StreamBuilder(
        stream: widget.userFurnaceBloc.userfurnaces,
        builder: (context, AsyncSnapshot<List<UserFurnace>?> snapshot) {
          if (snapshot.hasData) {
            _userFurnaces = snapshot.data!;
            //if (_hostedFurnaces.isNotEmpty) {
            return WrapperWidget(
                child: makeBody(snapshot.data!)
            );
            //}
          } else if (snapshot.hasError) {
            return Container(
                decoration: BoxDecoration(
                  color: globalState.theme.background,
                ),
                child: Text(snapshot.error.toString()));
          }
          return Center(
              child: Container(
                  decoration: BoxDecoration(
                    color: globalState.theme.background,
                  ),

                  //  child: Text(snapshot.error.toString())),
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          globalState.theme.button)
                      //backgroundColor: Colors.black,
                      )));
        },
      ),

      //bottomNavigationBar: makeBottom,
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        //key: widget.walkthrough.add,
        label: ICText(AppLocalizations.of(context)!.addNetwork,
            color: globalState.theme.background, fontWeight: FontWeight.bold),
        heroTag: null,
        onPressed: () async {
          add(context, _userFurnaces);
        },
        backgroundColor: globalState.theme.homeFAB,
        icon: Icon(
          Icons.add,
          size: _iconSize + 5 - globalState.scaleDownIcons,
          color: globalState.theme.background,
        ),
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  _backPressed() {
    debugPrint('backPress CALLED');

    if (ModalRoute.of(context)!.isFirst) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        // arguments: user,
      );
    } else {
      Navigator.pop(context);
    }
  }

  /*
  setup() async {
    List<UserFurnace> userFurnaces =
        await _userFurnaceBloc.requestConnected(globalState.user.id!);

    for (UserFurnace furnace in userFurnaces) {
      HostedFurnace? network =
          await _hostedFurnaceBloc.getHostedFurnace(furnace);

      ///RBR
      if (network == null) return;

      if (_hostedFurnaces.indexWhere((element) => element.id == network!.id) ==
          -1) {
        setState(() {
          _hostedFurnaces.add(network!);
        });
      }
      if (network!.hostedFurnaceImage != null) {
        if (!FileSystemService.furnaceImageExistsSync(
            furnace.userid!, network.hostedFurnaceImage)) {
          setState(() {
            _hostedFurnaceBloc.downloadImage(
                _globalEventBloc, furnace, network);
          });
        }
      }
    }
  }

   */

  void add(BuildContext context, List<UserFurnace> userFurnaces) async {
    if (mounted) {
      bool canAddNetwork =
          await PremiumFeatureCheck.canAddNetwork(context, userFurnaces);

      if (canAddNetwork) {
        ///need to check mounted twice as the screen could have exited after the above awaits
        if (mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NetworkManagerAdd(
              fromFurnaceManager: true, userFurnaces: userFurnaces,
              //userFurnace: userFurnace,
            ),
          ));

          widget.userFurnaceBloc.request(globalState.user.id!);
          _globalEventBloc.broadcastRefreshHome();
        }
      }
    }
  }

  _refresh() {
    widget.userFurnaceBloc.request(globalState.user.id!);
  }

  void openDetail(BuildContext context, UserFurnace? userFurnace) async {
    //Navigator.pop(context);

    if (userFurnace != null) {
      if (userFurnace.connected!) {
        userFurnace.populateNonColumn();
      }
    }

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => NetworkDetailTabs(
        userFurnace: userFurnace!,
        userFurnaces: _userFurnaces,
        refreshNetworkManager: _refresh,
      ),
    ));

    ///refresh this screen
    widget.userFurnaceBloc.request(globalState.user.id!);
    _globalEventBloc.broadcastRefreshHome();
  }

  /*_checkClipBoardData() async {
    String magicCode = await StringHelper.testClipboardForMagicCode();

    List<MagicCode> checkExisting = await TableMagicCode.readByCode(
        StringHelper.getMagicCodeFromString(magicCode));

    if (checkExisting.isEmpty) {
      if (magicCode.isNotEmpty && mounted) {
        DialogYesNo.askYesNo(
            context,
            'Magic Code Detected',
            'Join the network now?',
            _proceed,
            null,
            magicCode);
      }
    }
  }

  _proceed(String magicCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) => AppCode(
                fromFurnaceManager: true, token: magicCode,
                //      authServer: !widget.fromFurnaceManager,
              )
          //userFurnace: widget.userFurnace,
          ),
    );
  }*/
}
