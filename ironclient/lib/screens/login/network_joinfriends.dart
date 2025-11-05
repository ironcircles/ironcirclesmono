import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/registration_short.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';

///Called from landing

class NetworkJoinFriends extends StatefulWidget {
  final bool fromNetworkManager;
  final List<UserFurnace>? userFurnaces;

  const NetworkJoinFriends({
    Key? key,
    required this.fromNetworkManager,
    this.userFurnaces,
  }) : super(key: key);

  @override
  _LandingState createState() {
    return _LandingState();
  }
}

class _LandingState extends State<NetworkJoinFriends> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final databaseBloc = DatabaseBloc();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  final ScrollController _scrollController = ScrollController();
  String assigned = '';
  UserFurnace? localFurnace;

  final bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    globalState.globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4, left: 25, right: 25),
        child: Divider(
          color: globalState.theme.divider,
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ));

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
            title: AppLocalizations.of(context)!
                .joinFriendsNetwork), //'Join Friend\'s Network'),
        body: SafeArea(
            left: false,
            top: false,
            right: true,
            bottom: true,
            child: Stack(
              children: [
                Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _scrollController,
                        child: WrapperWidget(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, left: 25, right: 25),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                            child: ICText(
                                          AppLocalizations.of(context)!
                                              .easyWay, //'Easy way:',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: globalState.theme.buttonIcon,
                                        )),
                                      ])),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, left: 25, right: 25),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                            child: ICText(AppLocalizations.of(
                                                    context)!
                                                .askYourFriendForAMagicLink)),
                                        // 'Ask your friend for a MagicLink and then tap on it. You will be prompted to join.')),
                                      ])),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 50)),
                              /*divider,
                        Padding(padding: EdgeInsets.only(bottom: 10)),*/
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, left: 25, right: 25),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                            child: ICText(
                                          AppLocalizations.of(context)!
                                              .manualWay, //'Manual way:',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: globalState.theme.buttonIcon,
                                        )),
                                      ])),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, left: 25, right: 25, bottom: 10),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                            child: ICText(
                                                AppLocalizations.of(context)!
                                                    .joinManually)),
                                      ])),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Spacer(),
                                    GradientButtonDynamic(
                                        color:
                                            globalState.theme.labelTextSubtle,
                                        text: AppLocalizations.of(context)!
                                            .manuallyJoinNetwork,
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RegistrationShort(
                                                        linkedAccount: true,
                                                        fromNetworkManager: widget
                                                            .fromNetworkManager,
                                                        userFurnaces:
                                                            widget.userFurnaces,
                                                        caller:
                                                            RegistrationShortCaller
                                                                .join_friends),
                                              ));
                                        }),
                                  ]),
                            ],
                          ),
                        ))),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            )),
      ),
    );
  }

  handleAppLifecycleState(AppLifecycleState msg) {
    switch (msg) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (mounted) {
          setState(() {});
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
