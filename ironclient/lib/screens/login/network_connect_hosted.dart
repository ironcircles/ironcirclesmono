import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/actionneededbloc.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/screens/login/network_connect_account.dart';
import 'package:ironcirclesapp/screens/login/networkdetail.dart';
//import 'package:ironcirclesapp/screens/login/networkdetail_members.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as toggle;

enum Source {
  fromNetworkManager,
  fromNetworkRequests,
  fromLanding,
  fromActionRequired
}

class NetworkConnectHosted extends StatefulWidget {
  final String? toast;
  //final bool fromFurnaceManager;
  final Source source;
  final bool authServer;
  final UserFurnace userFurnace;
  final NetworkRequest? request;
  final ActionRequired? actionRequired;
  final HostedFurnace? network;

  const NetworkConnectHosted({
    Key? key,
    this.toast,
    required this.source,
    //this.fromFurnaceManager = false,
    this.authServer = false,
    required this.userFurnace,
    this.request,
    this.actionRequired,
    this.network,
  }) : super(key: key);

  @override
  _NetworkConnectHostedState createState() {
    return _NetworkConnectHostedState();
  }
}

class _NetworkConnectHostedState extends State<NetworkConnectHosted> {
  final _userFurnaceBloc = UserFurnaceBloc();
  late HostedFurnaceBloc _hostedFurnaceBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  late FirebaseBloc _firebaseBloc;
  late GlobalEventBloc _globalEventBloc;
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  final KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();
  final ScrollController _scrollController = ScrollController();
  final ActionNeededBloc _actionNeededBloc = ActionNeededBloc();
  //bool showPasswordReset = false;
  final bool _showForge = true;
  String assigned = '';
  String? _toast;
  bool _showAPIKey = false;
  final TextEditingController _apikey = TextEditingController();
  final TextEditingController _url = TextEditingController();
  late UserCircleBloc _userCircleBloc;
  UserFurnace? localFurnace;
  bool _linkedAccount = true;
  int _initialIndex = 0;
  late List<NetworkRequest> _requests;
  late HostedFurnace hostedFurnace;
  bool _publicNetworkJoin = false;
  late HostedFurnace network;
  File? _image;
  double radius = 200 - (globalState.scaleDownTextFont * 2);
  UserFurnace? newUserFurnace;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  _determineRoute(UserFurnace userFurnace) async {
    if (userFurnace.user != null) {
      ///check to see if the user has receiving keys
      List<UserCircle> missing = await ForwardSecrecy.keysMissing(
          userFurnace.user!.id!, userFurnace.user!.userCircles);

      if (missing.isNotEmpty) {
        //if (furnaceConnection.user.autoKeychainBackup!) {
        if (globalState.user.autoKeychainBackup!) {
          String backupKey = '';

          if (userFurnace.linkedUser == null) {
            UserSetting? userSetting =
                await TableUserSetting.read(userFurnace.userid!);
            backupKey = userSetting!.backupKey;
          } else {
            backupKey = globalState.userSetting.backupKey;
          }

          // String backupKey = await SecureStorageService.readKey(
          //    KeyType.USER_KEYCHAIN_BACKUP + globalState.user.id!);

          _keychainBackupBloc.restore(
              globalState.userFurnace!, globalState.user, backupKey, false);
        } else {
          await Future.delayed(const Duration(milliseconds: 100));

          ///ratchet the receiving keys for this device
          _authBloc.generateCircleKeys(
              userFurnace.user!, userFurnace, userFurnace.user!.userCircles);
        }
      } else {
        ///ratchet the receiving keys for this device
        _authBloc.generateCircleKeys(
            userFurnace.user!, userFurnace, userFurnace.user!.userCircles);
      }
    } else {
      if (mounted)
        setState(() {
          _showSpinner = false;
        });
      //_userFurnaceBloc.connect(_userFurnace, false);
    }
  }

  @override
  void initState() {
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _hostedFurnaceBloc.imageDownloaded.listen((userFurnace) {
      setState(() {
        _image = File(FileSystemService.returnDiscoverableNetworkImagePath(
            network.hostedFurnaceImage!)!);
      });
    });

    _hostedFurnaceBloc.requests.listen((requests) {
      if (mounted) {
        setState(() {
          _requests = requests;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    /*_userCircleBloc.refreshedUserCircles
        .listen((refreshUserCircleCaches) async {
      ///deletes from cache and API
      if (widget.request != null) {
        _actionNeededBloc
            .dismissNetworkNotification([widget.userFurnace], widget.request!);
      }
      _determineRoute(newUserFurnace!);
    });*/

    _userFurnaceBloc.userFurnace.listen((userFurnace) async {
      if (userFurnace!.user!.autoKeychainBackup != null) {
        if (userFurnace.user!.autoKeychainBackup!) {
          /*UserBloc userBloc = UserBloc();
          userBloc.updateKeysExported(userFurnace);
           */
        }
      }

      newUserFurnace = userFurnace;

      if (_publicNetworkJoin == true) {
        if (widget.request != null) {
          if (widget.request!.status == NetworkRequestStatus.ACCEPTED) {
            _actionNeededBloc.dismissNetworkNotification(
                [widget.userFurnace], widget.request!);
            _determineRoute(newUserFurnace!);

            _globalEventBloc.broadcastRefreshHome();

            ///reload action required
            // _userCircleBloc.fetchUserCircles([widget.userFurnace], true, true);
          } else {
            ///delete request API side
            widget.request!.status = NetworkRequestStatus.CANCELED;
            _hostedFurnaceBloc.updateRequest(
              widget.userFurnace,
              widget.request!,
            );
            _determineRoute(newUserFurnace!);
          }
        } else {
          for (NetworkRequest request in _requests) {
            if (request.hostedFurnace.id == userFurnace.id) {
              request.status = NetworkRequestStatus.CANCELED;
              _hostedFurnaceBloc.updateRequest(
                widget.userFurnace,
                request,
              );
            }
          }
          _determineRoute(newUserFurnace!);
        }
      } else {
        _determineRoute(newUserFurnace!);
      }

      /* Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
        arguments: globalState.user,
      );*/
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.usernameExists,
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.usernameReserved,
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .errorGenericTitle, //'Something went wrong',
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            true);

      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _userCircleBloc.refreshedUserCirclesSync.listen((success) {
      if (mounted) {
        importingData!.dismiss();
        importingData = null;
        if (widget.source == Source.fromNetworkManager) {
          Navigator.pop(context);
          Navigator.pop(context);
        } else if (widget.source == Source.fromNetworkRequests) {
          Navigator.pop(context);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (Route<dynamic> route) => false,
            arguments: globalState.user,
          );
        }
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _keychainBackupBloc.restoreSuccess.listen((show) {
      if (mounted) {
        setState(() {
          if (show) {
            if (progressDialog != null) {
              progressDialog!.dismiss();
              progressDialog = null;
            }

            progressDialog = ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .importingChatHistory, //"Importing chat history",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            progressDialog!.show();
          } else {
            progressDialog!.dismiss();
            progressDialog = null;

            //Navigator.of(context).pop(true);

            importingData = ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .decryptingData, //"Decrypting data",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            importingData!.show();

            //import data
            _userCircleBloc.fetchUserCirclesSync(true);
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
      FormattedSnackBar.showSnackbarWithContext(context, err, "", 2, true);
      if (progressDialog != null) {
        progressDialog!.dismiss();
        progressDialog = null;
      }
    }, cancelOnError: false);

    _authBloc.keyGenerated.listen((show) {
      if (mounted) {
        setState(() {
          if (show) {
            setState(() {
              //_loggingIn = false;
              _showSpinner = false;
            });
            progressDialog ??= ProgressDialog(context,
                backgroundColor: globalState.theme.dialogTransparentBackground,
                defaultLoadingWidget: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        globalState.theme.button)),
                dialogStyle: DialogStyle(
                    backgroundColor: globalState.theme.background,
                    elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!
                      .generatingSecurityKeys, //"Generating Security Keys",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ),
                title: Text(
                  AppLocalizations.of(context)!.pleaseWait, //"Please wait...",
                  textScaler: const TextScaler.linear(1.0),
                  style: TextStyle(color: globalState.theme.labelText),
                ));
            progressDialog!.show();
          } else {
            if (progressDialog != null) {
              progressDialog!.dismiss();
              progressDialog = null;
            }

            if (widget.source == Source.fromNetworkManager) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else if (widget.source == Source.fromNetworkRequests) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: globalState.user,
              );
            }
          }
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.network != null) {
      network = widget.network!;
      _publicNetworkJoin = true;

      if (network.hostedFurnaceImage != null) {
        if (!FileSystemService.discoverableFurnaceImageExistsSync(
            network.hostedFurnaceImage)) {
          _hostedFurnaceBloc.downloadDiscoverableImage(
              _globalEventBloc, widget.userFurnace, network);
        }
      }

      if (FileSystemService.discoverableFurnaceImageExistsSync(
          network.hostedFurnaceImage)) {
        setState(() {
          _image = File(FileSystemService.returnDiscoverableNetworkImagePath(
              network.hostedFurnaceImage!)!);
        });
      }
    }

    if (widget.request != null) {
      network = widget.request!.hostedFurnace;
      _publicNetworkJoin = true;
      if (network.hostedFurnaceImage != null) {
        if (!FileSystemService.discoverableFurnaceImageExistsSync(
            network.hostedFurnaceImage)) {
          _hostedFurnaceBloc.downloadDiscoverableImage(
              _globalEventBloc, widget.userFurnace, network);
        }
      }

      if (FileSystemService.discoverableFurnaceImageExistsSync(
          network.hostedFurnaceImage)) {
        setState(() {
          _image = File(FileSystemService.returnDiscoverableNetworkImagePath(
              network.hostedFurnaceImage!)!);
        });
      }
    }

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);
    globalState.loggingOut = false;
    if (widget.toast != null) _toast = widget.toast;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));

    super.initState();

    _globalEventBloc.applicationStateChanged.listen((msg) {
      handleAppLifecycleState(msg);
    }, onError: (error, trace) {
      LogBloc.insertError(error, trace);
    }, cancelOnError: false);

    _hostedFurnaceBloc.getRequests(widget.userFurnace, globalState.user);
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

  Widget _networkWidgets(BuildContext context, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 5, bottom: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(
          children: [
            Expanded(
              child: ICText(
                  AppLocalizations.of(context)!
                      .enterTheNameAndAccessCode, //'Enter the name and access code',
                  fontSize: globalState.userSetting.fontSize,
                  color: globalState.theme.buttonIcon),
            )
          ],
        ),
        const Padding(
            padding: EdgeInsets.only(
          top: 10,
        )),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 49),
          child: FormattedText(
            labelText: AppLocalizations.of(context)!.networkName,
            maxLength: 50,
            controller: _url,
            validator: (value) {
              if (value.isEmpty) {
                return AppLocalizations.of(context)!
                    .errorFieldRequired; //'field is required';
              }
              return null;
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(
            top: 5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: FormattedText(
                    labelText: AppLocalizations.of(context)!
                        .accessCode, //'access code',
                    obscureText: !_showAPIKey,
                    maxLength: 25,
                    maxLines: 1,
                    controller: _apikey,
                    validator: (value) {
                      if (value.isEmpty) {
                        return AppLocalizations.of(context)!.errorFieldRequired;
                      }

                      return null;
                    },
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.remove_red_eye,
                        color: _showAPIKey
                            ? globalState.theme.buttonIcon
                            : globalState.theme.buttonDisabled),
                    onPressed: () {
                      setState(() {
                        _showAPIKey = !_showAPIKey;
                      });
                    })
              ]),
        ),
        widget.authServer
            ? Container()
            : Padding(
                padding: const EdgeInsets.only(top: 15),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  toggle.ToggleSwitch(
                    minWidth: 150.0,
                    //minHeight: 70.0,
                    initialLabelIndex: _initialIndex,
                    cornerRadius: 20.0,
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    totalSwitches: 2,
                    radiusStyle: true,
                    labels: [
                      AppLocalizations.of(context)!.linkedAccount,
                      AppLocalizations.of(context)!.separateAccount
                    ],
                    customTextStyles: [
                      TextStyle(
                          fontSize:
                              14 / MediaQuery.textScalerOf(context).scale(1)),
                      TextStyle(
                          fontSize:
                              14 / MediaQuery.textScalerOf(context).scale(1))
                    ],
                    activeBgColors: const [
                      [
                        Colors.tealAccent,
                        Colors.teal,
                      ],
                      [Colors.yellow, Colors.orange]
                    ],
                    animate:
                        true, // with just animate set to true, default curve = Curves.easeIn
                    curve: Curves
                        .bounceInOut, // animate must be set to true when using custom curve
                    onToggle: (index) {
                      debugPrint('switched to: $index');
                      //_hiRes = !_hiRes;

                      setState(() {
                        _linkedAccount = !_linkedAccount;
                        _initialIndex = index!;
                      });
                    },
                  ),
                  IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        DialogNotice.showNoticeOptionalLines(
                            context,
                            AppLocalizations.of(context)!
                                .linkExistingAccountTitle,
                            '${AppLocalizations.of(context)!.linkExistingAccountMessage1} ${globalState.user.username} ${AppLocalizations.of(context)!.linkExistingAccountMessage2}',
                            false,
                            line2: AppLocalizations.of(context)!
                                .linkExistingAccountMessage3);
                      },
                      icon: const Icon(
                        Icons.help,
                        size: 20,
                      ))
                ])),
        const Padding(
          padding: EdgeInsets.only(top: 20),
        ),
      ]),
    );
  }

  Widget _publicNetworkWidgets(BuildContext context, double screenWidth) {
    return Padding(
        padding: const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 5),
        child: Column(children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Column(children: [
                  ClipOval(
                      child: _image != null
                          ? Image.file(_image!,
                              height: radius, width: radius, fit: BoxFit.cover)
                          : FileSystemService
                                      .discoverableFurnaceImageExistsSync(
                                          network.hostedFurnaceImage) !=
                                  false
                              ? Image.file(
                                  File(FileSystemService
                                      .returnDiscoverableFurnaceImagePathSync(
                                          network.hostedFurnaceImage!)),
                                  height: radius,
                                  width: radius,
                                  fit: BoxFit.cover)
                              : Image.asset(
                                  'assets/images/ios_icon.png',
                                  height: radius,
                                  width: radius,
                                  fit: BoxFit.fitHeight,
                                )),
                  const Padding(
                    padding: EdgeInsets.only(top: 0, bottom: 10),
                  )
                ])
              ]),
          Padding(
              padding: const EdgeInsets.only(left: 49, right: 49, top: 10),
              child: ICText(network.name,
                  fontSize: (20 - globalState.scaleDownTextFont) /
                      globalState.mediaScaleFactor)),
          network.description != null
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 49, right: 49, top: 10, bottom: 10),
                  child: SizedBox(
                      width: screenWidth > 300 ? 500 : screenWidth - 20,
                      child: ICText(
                        network.description,
                        fontSize: (20 - globalState.scaleDownTextFont) /
                            globalState.mediaScaleFactor,
                        overflow: TextOverflow.visible,
                      )))
              : Container(),
          widget.authServer
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        toggle.ToggleSwitch(
                          minWidth: 150.0,
                          initialLabelIndex: _initialIndex,
                          cornerRadius: 20.0,
                          activeFgColor: Colors.white,
                          inactiveBgColor: Colors.grey,
                          inactiveFgColor: Colors.white,
                          totalSwitches: 2,
                          radiusStyle: true,
                          labels: [
                            AppLocalizations.of(context)!.linkedAccount,
                            AppLocalizations.of(context)!.separateAccount
                          ],
                          customTextStyles: [
                            TextStyle(
                                fontSize: 13 /
                                    MediaQuery.textScalerOf(context).scale(1)),
                            TextStyle(
                                fontSize: 13 /
                                    MediaQuery.textScalerOf(context).scale(1))
                          ],
                          activeBgColors: const [
                            [
                              Colors.tealAccent,
                              Colors.teal,
                            ],
                            [Colors.yellow, Colors.orange]
                          ],
                          animate: true,
                          curve: Curves.bounceInOut,
                          onToggle: (index) {
                            debugPrint('switched to: $index');
                            setState(() {
                              _linkedAccount = !_linkedAccount;
                              _initialIndex = index!;
                            });
                          },
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              DialogNotice.showNoticeOptionalLines(
                                  context,
                                  AppLocalizations.of(context)!
                                      .linkExistingAccountTitle,
                                  '${AppLocalizations.of(context)!.linkExistingAccountMessage1} ${globalState.user.username} ${AppLocalizations.of(context)!.linkExistingAccountMessage2}',
                                  false,
                                  line2: AppLocalizations.of(context)!
                                      .linkExistingAccountMessage3);
                            },
                            icon: const Icon(
                              Icons.help,
                              size: 20,
                            ))
                      ])),
          const Padding(
            padding: EdgeInsets.only(top: 20),
          )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final connectButton =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 5, top: 20, bottom: 0),
              child: GradientButton(
                  //color1: Colors.blue,
                  //color2: Colors.blue,
                  width: screenWidth - 20,
                  text: AppLocalizations.of(context)!
                      .joinNetwork, //'JOIN NETWORK',
                  onPressed: () {
                    _publicNetworkJoin == true
                        ? _connectToPublicNetwork()
                        : _connectToNetwork();
                  }))),

      //),
    ]);

    return Form(
        key: _formKey,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: _publicNetworkJoin == true
              ? const ICAppBar(title: '')
              : widget.source == Source.fromLanding
                  ? ICAppBar(
                      title: AppLocalizations.of(context)!
                          .whichNetwork) //'Which network?')
                  : null, //const ICAppBar(title: 'Join Network'),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
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
                        child: WrapperWidget(child:Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _publicNetworkJoin == true
                                ? _publicNetworkWidgets(context, screenWidth)
                                : _networkWidgets(context, screenWidth),
                            connectButton,
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

  _connectToPublicNetwork() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (mounted) {
          if (await _hostedFurnaceBloc.checkIfAlreadyOnNetwork(network.name)) {
            if (mounted) {
              DialogNotice.showNoticeOptionalLines(
                  context,
                  AppLocalizations.of(context)!
                      .alreadyConnectedTitle, //'Already connected',
                  AppLocalizations.of(context)!.alreadyConnectedMessage,
                  false);
              return;
            }
          }
        }

        setState(() {
          _showSpinner = true;
        });

        localFurnace ??= UserFurnace.initFurnace(
            url: network.name, apikey: network.key, authServer: false);

        localFurnace!.authServer = widget.authServer;

        bool hosted = true;

        if (network.name.toLowerCase() == IRONFORGE) {
          hosted = false;

          localFurnace!.hostedId = '';
          localFurnace!.hostedName = '';
          localFurnace!.type = NetworkType.FORGE;
          localFurnace!.alias = 'IronForge';
          localFurnace!.url = urls.forge;
          localFurnace!.apikey = urls.forgeAPIKEY;
        } else if (hosted) {
          localFurnace!.type = NetworkType.HOSTED;
          localFurnace!.hostedName = network.name;
          localFurnace!.hostedAccessCode = network.key;
          localFurnace!.url = urls.spinFurnace;
          localFurnace!.apikey = urls.spinFurnaceAPIKEY;

          ///Verify the furnace already exists
          String nameAvailable = await _hostedFurnaceBloc.valid(
              widget.userFurnace, network.name, network.key, true);

          bool avail = false;

          ///network requests do not return the network access code so validate there is an approved request
          if (nameAvailable != NetworkJoinAttemptMessage.VALID) {
            avail = await _hostedFurnaceBloc.requestApproved(
                widget.userFurnace, network.name);

            if (avail == false) {
              if (mounted) {
                setState(() {
                  _showSpinner = false;
                });
                DialogNotice.showNotice(
                    context,
                    AppLocalizations.of(context)!.networkNotFoundTitle,
                    AppLocalizations.of(context)!.networkNotFoundMessage,
                    null,
                    null,
                    null,
                    false);
                return;
              }
            }
          }
          localFurnace!.alias = network.name;
        }
        FurnaceConnection? furnaceConnection;
        // if (widget.fromFurnaceManager) {
        if (_linkedAccount) {
          localFurnace!.username = globalState.user.username!;
          localFurnace!.password = '';
          localFurnace!.pin = '';

          _userFurnaceBloc.register(
              localFurnace!, null, globalState.user.minor, _linkedAccount, primaryNetwork: globalState.userFurnace);
        } else {
          if (mounted) {
            furnaceConnection = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NetworkConnectAccount(
                          userFurnace: localFurnace!,
                          source: widget.source,
                        )));
          }
        }

        if (furnaceConnection != null) {
          setState(() {
            localFurnace = furnaceConnection!.userFurnace;
            _showSpinner = false;
          });
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        FormattedSnackBar.showSnackbarWithContext(
            context, error.toString(), "", 2, true);

        setState(() {
          _showSpinner = false;
        });
      }
    }
  }

  void _connectToNetwork() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (mounted) {
          if (await _hostedFurnaceBloc.checkIfAlreadyOnNetwork(_url.text)) {
            ///yes, need this twice
            if (mounted) {
              DialogNotice.showNoticeOptionalLines(
                  context,
                  AppLocalizations.of(context)!.alreadyConnectedTitle,
                  AppLocalizations.of(context)!.alreadyConnectedMessage,
                  false);

              return;
            }
          }
        }

        localFurnace ??= UserFurnace.initFurnace(
            url: _url.text, apikey: _apikey.text, authServer: false);

        localFurnace!.authServer = widget.authServer;

        bool hosted = true;

        if (_url.text.toLowerCase() == IRONFORGE.toLowerCase()) {
          hosted = false;

          localFurnace!.hostedId = '';
          localFurnace!.hostedName = '';
          localFurnace!.type = NetworkType.FORGE;
          localFurnace!.alias = IRONFORGE;
          localFurnace!.url = urls.forge;
          localFurnace!.apikey = urls.forgeAPIKEY;
        } else if (hosted) {
          localFurnace!.type  = NetworkType.HOSTED;
          localFurnace!.hostedName = _url.text;
          localFurnace!.hostedAccessCode = _apikey.text;
          localFurnace!.url = urls.spinFurnace;
          localFurnace!.apikey = urls.spinFurnaceAPIKEY;

          ///Verify the furnace already exists
          String nameAvailable = await _hostedFurnaceBloc.valid(
              widget.userFurnace, _url.text, _apikey.text, false);

          bool avail = false;
          if (nameAvailable == NetworkJoinAttemptMessage.INVALID) {
            avail = await _hostedFurnaceBloc.requestApproved(
                widget.userFurnace, _url.text);
          } else if (nameAvailable == NetworkJoinAttemptMessage.VALID) {
            avail = true;
            localFurnace!.alias = _url.text;
          } else if (nameAvailable == NetworkJoinAttemptMessage.EXCEEDED) {
            FormattedSnackBar.showSnackbarWithContext(context,
                AppLocalizations.of(context)!.joinExceeded, "", 3, false);
            return;
          } else if (nameAvailable == NetworkJoinAttemptMessage.FAILED) {
            if (mounted) {
              DialogNotice.showNotice(
                  context,
                  AppLocalizations.of(context)!.networkNotFoundTitle,
                  AppLocalizations.of(context)!.joinFailed,
                  null,
                  null,
                  null,
                  false);
            }
            return;
          } else {
            FormattedSnackBar.showSnackbarWithContext(
                context,
                AppLocalizations.of(context)!.joinWait1 +
                    nameAvailable +
                    AppLocalizations.of(context)!.joinWait2,
                "",
                2,
                false);
            return;
          }

          if (!avail) {
            if (mounted) {
              DialogNotice.showNotice(
                  context,
                  AppLocalizations.of(context)!.networkNotFoundTitle,
                  AppLocalizations.of(context)!.networkNotFoundMessage,
                  null,
                  null,
                  null,
                  false);
            }
            return;
          }
        }

        FurnaceConnection? furnaceConnection;

        // if (widget.fromFurnaceManager) {
        if (_linkedAccount) {
          localFurnace!.username = globalState.user.username!;
          localFurnace!.password = '';
          localFurnace!.pin = '';

          _userFurnaceBloc.register(
              localFurnace!, null, globalState.user.minor, _linkedAccount, primaryNetwork: globalState.userFurnace);
        } else {
          if (mounted) {
            furnaceConnection = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NetworkConnectAccount(
                    userFurnace: localFurnace!,
                    source: widget.source,
                  ),
                ));
          }
        }
        // } else {
        //   if (mounted) {
        //     Navigator.pop(context, localFurnace!);
        //   }
        //  }

        if (furnaceConnection != null) {
          setState(() {
            localFurnace = furnaceConnection!.userFurnace;
          });
        }
      } catch (error, trace) {
        LogBloc.insertError(error, trace);
        FormattedSnackBar.showSnackbarWithContext(
            context, error.toString(), "", 2, true);
      }
    }
  }
}
