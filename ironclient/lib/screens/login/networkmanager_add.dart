import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/login.dart';
import 'package:ironcirclesapp/screens/login/network_joinfriends.dart';
import 'package:ironcirclesapp/screens/login/networkmanager_create.dart';
import 'package:ironcirclesapp/screens/login/networksearch.dart';
import 'package:ironcirclesapp/screens/login/pendingnetworks.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';

class NetworkManagerAdd extends StatefulWidget {
  final String? toast;
  final bool fromFurnaceManager;
  final List<UserFurnace> userFurnaces;

  const NetworkManagerAdd({
    Key? key,
    this.toast,
    this.fromFurnaceManager = false,
    required this.userFurnaces,
  }) : super(key: key);

  @override
  _LandingState createState() {
    return _LandingState();
  }
}

class _LandingState extends State<NetworkManagerAdd> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  late FirebaseBloc _firebaseBloc;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  final ScrollController _scrollController = ScrollController();
  //bool showPasswordReset = false;

  String assigned = '';
  String? _toast;
  bool _showForge = true;

  final bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));

    super.initState();

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;

    if (widget.toast != null) _toast = widget.toast;

    if (widget.userFurnaces != null) {
      for (UserFurnace userFurnace in widget.userFurnaces) {
        if (userFurnace.alias == "IronForge") {
          _showForge = false;
          break;
        }
      }
    }
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
    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  /* Widget haveMagicCode(BuildContext context) {
    return Container(
        //color: Colors.grey[800],
        child: Padding(
      padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 0,
            ),
            child: GradientButton(
                color1: Colors.blue[500],
                color2: Colors.blue[200],
                text: 'I have a magic code',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) => AppCode(
                              fromFurnaceManager: true,
                              //      authServer: !widget.fromFurnaceManager,
                            )
                        //userFurnace: widget.userFurnace,
                        ),
                  );

                  _checkClipBoardData();
                }),
          )),

          //),
        ])
      ]),
    ));
  }*/

  // Widget joinAFriendsNetwork(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
  //     child: Column(children: [
  //       Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
  //         Expanded(
  //           child: Container(
  //               margin: EdgeInsets.symmetric(
  //                   horizontal:
  //                       ButtonType.getWidth(MediaQuery.of(context).size.width)),
  //               child: GradientButton(
  //                   color1: Colors.teal[500],
  //                   color2: Colors.green[200],
  //                   text: AppLocalizations.of(context)!.joinAFriendsNetwork,
  //                   onPressed: () {
  //                     Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (context) => NetworkConnectTabs(
  //                             userFurnace: widget.userFurnaces[0],
  //                             source: Source.fromNetworkManager,
  //                             authServer: false,
  //                             //furnaceName: 'IronForge',
  //                           ),
  //                         ));
  //                   })),
  //         ),
  //       ])
  //     ]),
  //   );
  // }

  Widget loginWithExisting(BuildContext context) {

    ///use the globalState furnace
    UserFurnace userFurnace = globalState.userFurnace!;


    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.teal[500],
                    color2: Colors.green[200],
                    text: AppLocalizations.of(context)!.loginWithAnExistingAccount,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(
                              userFurnace: userFurnace,
                              fromFurnaceManager:true,
                              allowChangeUser: true,

                              //furnaceName: 'IronForge',
                            ),
                          ));
                    })),
          ),
        ])
      ]),
    );
  }


  Widget joinAFriends(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                    ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.blue[500],
                    color2: Colors.blue[200],
                    text: AppLocalizations.of(context)!.joinAFriendsNetwork,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  NetworkJoinFriends(fromNetworkManager: true, userFurnaces: widget.userFurnaces,
                              // userFurnace: widget.userFurnaces[0],
                              // source: Source.fromNetworkManager,
                              // authServer: false,
                              //furnaceName: 'IronForge',
                            ),
                          ));
                    })),
          ),
        ])
      ]),
    );
  }

  Widget viewPendingNetworks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 10),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.teal[500],
                    color2: Colors.green[200],
                    text: AppLocalizations.of(context)!
                        .viewPendingNetworks
                        .toLowerCase(),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PendingNetworks(
                              userFurnace: widget.userFurnaces[0],
                            ),
                          ));
                    })),
          ),
        ])
      ]),
    );
  }

  // Widget joinPublicNetwork(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
  //     child: Column(children: [
  //       Row(
  //         crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
  //           Expanded(
  //             child: Padding(
  //               padding: const EdgeInsets.only(top: 20, bottom: 0),
  //               child: Container(
  //                 margin: EdgeInsets.symmetric(horizontal: ButtonType.getWidth(MediaQuery.of(context).size.width)),
  //                 child: GradientButton(
  //                   color1: Colors.green,
  //                   color2: Colors.green[200],
  //                   text: 'I want to join a discoverable network',
  //                   onPressed: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) => NetworkSearch(
  //                           userFurnaces: widget.userFurnaces,
  //                           userFurnace: widget.userFurnaces[0],
  //                         )
  //                       )
  //                     );
  //                   }
  //                 )
  //               )
  //             )
  //           )
  //       ]
  //       )
  //     ])
  //   );
  // }

  Widget generateNetwork(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(
              top: 0,
              bottom: 0,
            ),
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.teal[500],
                    color2: Colors.teal[200],
                    text: AppLocalizations.of(context)!.generateAnEncryptedSocialNetwork,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                NetworkManagerCreate(
                                  userFurnaces: widget.userFurnaces,
                                  authServer: !widget.fromFurnaceManager,
                                  userFurnace: widget.userFurnaces[0],
                                )
                            //userFurnace: widget.userFurnace,
                            ),
                      );
                    })),
          )),

          //),
        ])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: widget.fromFurnaceManager
            ? ICAppBar(title: AppLocalizations.of(context)!.addNetwork)
            : null,
        body: SafeArea(
          left: false,
          top: false,
          right: true,
          bottom: true,
          child: Stack(
            children: [
              Column(children: [
                Expanded(
                    child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            controller: _scrollController,
                            child: WrapperWidget(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                generateNetwork(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 10)),
                                loginWithExisting(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 10)),
                                joinAFriends(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 10)),
                                globalState.user.role == Role.IC_ADMIN
                                    ? viewPendingNetworks(context)
                                    : Container(),
                                const Padding(
                                    padding:
                                        EdgeInsets.only(top: 10, bottom: 20),
                                    child: Divider(
                                      color: Colors.grey,
                                      height: 2,
                                      thickness: 2,
                                      indent: 0,
                                      endIndent: 0,
                                    )),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Padding(
                                          padding: EdgeInsets.only(left: 15)),
                                      ICText(
                                          AppLocalizations.of(context)!
                                              .discoverableNetworks,
                                          fontSize: 20,
                                          textAlign: TextAlign.center,
                                          color: globalState.theme.button),
                                      const Spacer()
                                    ]),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 15)),
                                NetworkSearch(
                                  fromLanding: false,
                                  userFurnace: globalState.userFurnace!,
                                  //userFurnaces: widget.userFurnaces,
                                )
                              ],
                            ))))),
              ]),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
