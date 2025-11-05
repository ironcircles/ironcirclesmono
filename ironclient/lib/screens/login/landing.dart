import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/applink.dart';
import 'package:ironcirclesapp/screens/login/discoverable_landing.dart';
import 'package:ironcirclesapp/screens/login/generatenetwork.dart';
import 'package:ironcirclesapp/screens/login/login.dart';
import 'package:ironcirclesapp/screens/login/network_joinfriends.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/walkthroughswiper.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';

class Landing extends StatefulWidget {
  final String? toast;
  final bool fromFurnaceManager;
  final List<UserFurnace>? userFurnaces;

  const Landing({
    Key? key,
    this.toast,
    this.fromFurnaceManager = false,
    this.userFurnaces,
  }) : super(key: key);

  @override
  _LandingState createState() {
    return _LandingState();
  }
}

class _LandingState extends State<Landing> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  late FirebaseBloc _firebaseBloc;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  final ScrollController _scrollController = ScrollController();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late GlobalEventBloc _globalEventBloc;

  String assigned = '';
  String? _toast;
  bool _showForge = true;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  late double width;
  late double height;

  /*static const colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];*/

  static final colorizeColors = [
    //Colors.teal,
    Colors.teal[500]!,
    Colors.amber,
    Colors.teal[200]!,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Righteous',
    fontWeight: FontWeight.w700,
  );

  @override
  void initState() {
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _postLoad(context));

    super.initState();

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;

    if (widget.toast != null) _toast = widget.toast;

    if (widget.userFurnaces != null) {
      for (UserFurnace userFurnace in widget.userFurnaces!) {
        if (userFurnace.alias == "IronForge") {
          _showForge = false;
          break;
        }
      }
    }

    _globalEventBloc.magicLinkBroadcast.listen((dynamicLinkData) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppLink(
              link: dynamicLinkData,
            ),
          ));
    }, onError: (error, trace) {
      setState(() {
        _showSpinner = false;
      });

      LogBloc.insertError(error, trace);
      debugPrint("error $error");
    }, cancelOnError: false);

    _userFurnaceBloc.userFurnace.listen((success) {
      if (widget.fromFurnaceManager == false)
        globalState.showHomeTutorial = true;
      globalState.showPrivateVaultPrompt = true;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );
    }, onError: (error, trace) {
      setState(() {
        _showSpinner = false;
      });

      LogBloc.insertError(error, trace);

      debugPrint("error $error");

      //DialogUsernameAndTerms.show(context, _generateNetwork, _username,
      //  error.toString().replaceAll('Exception: ', ''));
    }, cancelOnError: false);

    //_checkClipBoardData();
  }

  _postLoad(BuildContext context) {
    if (_toast != null) {
      FormattedSnackBar.showSnackbarWithContext(
          context, widget.toast!, "", 2, false);
      _toast = null;
    } else if (globalState.initialLink != null) {
      String link = globalState.initialLink!.link.toString();
      globalState.initialLink = null;

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppLink(
              link: link,
            ),
          ));
    } else {
      //_showWalkthrough(context);
    }
  }

  @override
  void dispose() {
    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  static showWalkthroughSwiper(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _SystemPadding(
                child: AlertDialog(
                    surfaceTintColor: Colors.transparent,
                    backgroundColor:
                        globalState.theme.dialogTransparentBackground,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0))),
                    titlePadding: const EdgeInsets.all(0.0),
                    contentPadding: const EdgeInsets.all(12.0),
                    content: Column(children: <Widget>[
                      ICText(
                        AppLocalizations.of(context)!.welcomeToHome,
                        textScaleFactor: 1,
                        color: globalState.theme.dialogTitle,
                        fontSize: 23,
                      ),
                      const WalkthroughSwiper(),
                    ]),
                    actionsPadding: const EdgeInsets.only(top: 0),
                    actions: <Widget>[
                  TextButton(
                      child: Text(AppLocalizations.of(context)!.closeUpperCase,
                          textScaler:
                              TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonCancel,
                              fontSize: 14 - globalState.scaleDownButtonFont)),
                      onPressed: () {
                        Navigator.pop(context);
                      })
                ])));
  }

  Widget desktopHaveAccount(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 0),
                child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: GradientButton(
                        color1: Colors.green,
                        color2: Colors.green[200],
                        text: AppLocalizations.of(context)!
                            .loginWithAnExistingAccount,
                        onPressed: () {
                          UserFurnace userFurnace = UserFurnace.initForge(true);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Login(
                                  userFurnace: userFurnace,
                                  fromFurnaceManager: false,
                                ),
                              ));
                        })))
          ])
        ]));
  }

  Widget haveAccount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0),
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.green,
                    color2: Colors.green[200],
                    text: AppLocalizations.of(context)!
                        .loginWithAnExistingAccount, //'Login With an Existing Account',
                    onPressed: () {
                      UserFurnace userFurnace = UserFurnace.initForge(true);

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(
                              userFurnace: userFurnace,
                              fromFurnaceManager: false,
                            ),
                          ));
                    })),
          )),
        ])
      ]),
    );
  }

  Widget desktopNeedAccount(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
                padding: EdgeInsets.only(
                    top: globalState.isDesktop() ? 0 : 20, bottom: 0),
                child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: GradientButton(
                        color1: Colors.teal[500],
                        color2: Colors.teal[200],
                        text: AppLocalizations.of(context)!
                            .generateAnEncryptedSocialNetwork,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GenerateNetwork(
                                  caller: GenerateNetworkCaller.new_network,
                                  linkedAccount: false,
                                ),
                              ));
                        })))
          ])
        ]));
  }

  Widget needAccount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
            child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        ButtonType.getWidth(MediaQuery.of(context).size.width)),
                child: GradientButton(
                    color1: Colors.teal[500],
                    color2: Colors.teal[200],
                    text: AppLocalizations.of(context)!
                        .generateAnEncryptedSocialNetwork, //'Generate an Encrypted Social Network',
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GenerateNetwork(
                              caller: GenerateNetworkCaller.new_network,
                              linkedAccount: false,
                            ),
                          ));
                    })),
          ),

          //),
        ])
      ]),
    );
  }

  Widget desktopHaveMagicCode(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 0),
                child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: GradientButton(
                        color1: Colors.blue[500],
                        color2: Colors.blue[200],
                        text: AppLocalizations.of(context)!.joinAFriendsNetwork,
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NetworkJoinFriends(
                                    fromNetworkManager: false),
                              ));
                          //_checkClipBoardData();
                        })))
          ])
        ]));
  }

  Widget haveMagicCode(BuildContext context) {
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
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: ButtonType.getWidth(
                            MediaQuery.of(context).size.width)),
                    child: GradientButton(
                        color1: Colors.blue[500],
                        color2: Colors.blue[200],
                        text: AppLocalizations.of(context)!
                            .joinAFriendsNetwork, //'Join a Friend\'s Network',
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NetworkJoinFriends(
                                    fromNetworkManager: false),
                              ));
                          //_checkClipBoardData();
                        }),
                  ))),

          //),
        ])
      ]),
    );
  }

  Widget joinWithDiscoverable(BuildContext context) {
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
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: ButtonType.getWidth(
                              MediaQuery.of(context).size.width)),
                      child: GradientButton(
                          color1: Colors.yellow[500],
                          color2: Colors.yellow[200],
                          text:
                              AppLocalizations.of(context)!.joinAPublicNetwork,
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const DiscoverableFromLanding()));
                          }),
                    ))),
          ])
        ]));
  }

  Widget desktopJoinWithDiscoverable(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 0),
                child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: GradientButton(
                        color1: Colors.yellow[500],
                        color2: Colors.yellow[200],
                        text: AppLocalizations.of(context)!.joinAPublicNetwork,
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DiscoverableFromLanding()));
                          //_checkClipBoardData();
                        })))
          ])
        ]));
  }

  @override
  Widget build(BuildContext context) {
    globalState.setScaler(MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));

    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    double widthMax = MediaQuery.of(context).size.width;

    var animatedText = Padding(
        padding: const EdgeInsets.only(left: 0,),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            //const Spacer(),
            SizedBox(
              width: 300.0,
              //height: 30,
              child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1),
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      /*ColorizeAnimatedText(
                'new?',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
                textAlign: TextAlign.end,
              ),*/
                      ColorizeAnimatedText(
                        AppLocalizations.of(context)!
                            .newTapHereToGetStarted, //'new? tap here to get started',
                        textStyle: colorizeTextStyle,
                        colors: colorizeColors,
                        textAlign: TextAlign.end,
                      ),
                    ],
                    isRepeatingAnimation: true,
                    repeatForever: true,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GenerateNetwork(
                              caller: GenerateNetworkCaller.new_network,
                              linkedAccount: false,
                            ),
                          ));
                    },
                  )),
            ),
            const Padding(padding: EdgeInsets.only(right: 20)),
          ]),
          /* Row(
        children: [Spacer(), Center(child: Icon(Icons.arrow_downward)), Spacer()],
      )*/
        ]));

    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        appBar: widget.fromFurnaceManager
            ? const ICAppBar(title: 'Add a Network')
            : null,
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
                    child: Platform.isMacOS ||
                            Platform.isWindows ||
                            Platform.isLinux
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                          padding: const EdgeInsets.only(
                                              top: 80,
                                              bottom: 20,
                                              left: 20,
                                              right: 100),
                                          constraints: const BoxConstraints(
                                            maxWidth: 650,
                                            //  maxHeight: 100,
                                          ),
                                          child: Image.asset(
                                            'assets/images/landing.png',
                                          ))
                                    ]),
                                animatedText,
                                desktopNeedAccount(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 20)),
                                desktopHaveAccount(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 20)),
                                desktopHaveMagicCode(context),
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 20)),
                                desktopJoinWithDiscoverable(context),
                              ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 100,
                                      bottom: 20,
                                      left: 20,
                                      right: 20),
                                  child: Image.asset(
                                    'assets/images/landing.png',
                                  )),
                              animatedText,
                              needAccount(context),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 15)),
                              haveMagicCode(context),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 20)),
                              haveAccount(context),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 20)),
                              joinWithDiscoverable(context),
                            ],
                          ),
                  )),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
        ),
      ),
    );
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
            'Proceed to registration on the network?',
            _proceed,
            null,
            magicCode);
      }
    }
  }

   */

  void _showWalkthrough(context) {
    if (height > 600 && width > 300) {
      showWalkthroughSwiper(context);
    }
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300), child: child);
  }
}
