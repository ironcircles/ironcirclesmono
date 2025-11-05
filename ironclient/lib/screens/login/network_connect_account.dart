import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/login.dart';
import 'package:ironcirclesapp/screens/login/network_connect_hosted.dart';
import 'package:ironcirclesapp/screens/login/registration.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ndialog/ndialog.dart';

class NetworkConnectAccount extends StatefulWidget {
  final UserFurnace userFurnace;
  final Source source;

  const NetworkConnectAccount({
    Key? key,
    required this.userFurnace,
    required this.source,
  }) : super(key: key);

  @override
  _LandingState createState() {
    return _LandingState();
  }
}

class _LandingState extends State<NetworkConnectAccount> {
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
  final bool _showForge = true;

  final bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  Widget createNewSocialNetwork(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0),
            child: GradientButton(
                color1: Colors.green,
                color2: Colors.green[200],
                text:  AppLocalizations.of(context)!.haveAccount,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(
                          userFurnace: widget.userFurnace,
                          fromFurnaceManager: true,
                          //furnaceName: 'IronForge',
                        ),
                      ));
                }),
          )),
        ])
      ]),
    );
  }

  Widget needAccount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 0,
            ),
            child: GradientButton(
                color1: Colors.teal[500],
                color2: Colors.teal[200],
                text: AppLocalizations.of(context)!.needAccount,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) => Registration(
                              source: widget.source,
                              userFurnace: widget.userFurnace,
                              showChangeNetwork: false,
                            )
                        //userFurnace: widget.userFurnace,
                        ),
                  );
                }),
          )),

          //),
        ])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    //globalState.mediaScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: const ICAppBar(title: 'Account'),
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
                    child: WrapperWidget(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        needAccount(context),
                        const Padding(padding: EdgeInsets.only(bottom: 20)),
                        createNewSocialNetwork(context),
                      ],
                    )),
                  )),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
        ),
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
