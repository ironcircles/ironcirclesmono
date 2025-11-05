import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/keychainbackup_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/discoverablenetworkdetail.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogyesno.dart';
import 'package:ironcirclesapp/screens/widgets/formattedtext.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class NetworkSearch extends StatefulWidget {
  final bool fromLanding;
  final UserFurnace? userFurnace;
  final bool authServer;
 // final List<UserFurnace> userFurnaces;

  const NetworkSearch({
    Key? key,
    required this.fromLanding,
    required this.userFurnace,
    this.authServer = false,
    //required this.userFurnaces,
  }) : super(key: key);

  @override
  _NetworkSearch createState() => _NetworkSearch();
}

class _NetworkSearch extends State<NetworkSearch> {
  late GlobalEventBloc _globalEventBloc;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  final _userFurnaceBloc = UserFurnaceBloc();
  List<HostedFurnace> _networks = [];
  List<HostedFurnace> _allNetworks = [];
  List<HostedFurnace> _non18Networks = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchtext = TextEditingController();
  final _authBloc = AuthenticationBloc();
  final KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();

  ProgressDialog? progressDialog;
  bool imgsDownloaded = false;

  final joinText = 'JOIN';
  final buttonJoined = 'LEAVE';
  final joinedText = 'JOINED';
  UserFurnace? localFurnace;
  double radius = 50;
  bool _adultVisible = false;

  bool? ageRestrict;
  List<HostedFurnace>? networksRetrieved;

  bool _showSpinner = true;
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

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    ///create the network image folder if it's not already existing
    ///moved to main
    //FileSystemService.makeDiscoverableNetworkImageFolder();

    super.initState();
    ageRestrict = globalState.user.minor == true ? true : false;

    _hostedFurnaceBloc.notConnectedPublicNetworks.listen((networks) {
      if (networks.isNotEmpty) {
        networksRetrieved = networks;
        for (HostedFurnace network in networksRetrieved!) {
          if (network.hostedFurnaceImage != null) {
            if (!FileSystemService.discoverableFurnaceImageExistsSync(network.hostedFurnaceImage)) {
              _hostedFurnaceBloc.downloadDiscoverableImage(_globalEventBloc, widget.userFurnace, network);
            }
          }
        }
        _allNetworks = networksRetrieved!;
        _allNetworks.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _non18Networks = List.from(_allNetworks);
        _non18Networks.retainWhere((a) => a.adultOnly == false);

      }

      setState(() {
        //_allNetworks = _allNetworks;
        _showSpinner = false;
      });
    });

    _hostedFurnaceBloc.discoverableNetworks.listen((hostedFurnaces) {
      networksRetrieved = hostedFurnaces;
      if (widget.fromLanding == true) {
        for (HostedFurnace network in networksRetrieved!) {
          if (network.hostedFurnaceImage != null) {
            if (!FileSystemService.discoverableFurnaceImageExistsSync(network.hostedFurnaceImage)) {
              _hostedFurnaceBloc.downloadDiscoverableImage(_globalEventBloc, null, network);
            }
          }
        }
        _allNetworks = networksRetrieved!;
        _allNetworks.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _non18Networks = List.from(_allNetworks);
        _non18Networks.retainWhere((a) => a.adultOnly == false);

      } else {
        _hostedFurnaceBloc.checkIfAlreadyOnNetworks(networksRetrieved!);
      }

      setState(() {
        _showSpinner = false;
      });
    });

    if (widget.fromLanding == true) {
      _hostedFurnaceBloc.getAllDiscoverable();
    } else {
      _hostedFurnaceBloc.getDiscoverable(widget.userFurnace!, ageRestrict!);
    }

    _globalEventBloc.progressFurnaceImageIndicator.listen((hostedFurnaceImage) {
      if (mounted) setState(() {});
    });

    _userFurnaceBloc.userFurnace.listen((userFurnace) {
      if (userFurnace!.user!.autoKeychainBackup != null) {
        if (userFurnace.user!.autoKeychainBackup!) {
          UserBloc userBloc = UserBloc();
          userBloc.updateKeysExported(userFurnace);
        }
      }

      _determineRoute(userFurnace);

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
        DialogNotice.showNotice(context, AppLocalizations.of(context)!.usernameExists,
            AppLocalizations.of(context)!.usernameDifferent, null, null, null, false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(context, AppLocalizations.of(context)!.usernameReserved,
            AppLocalizations.of(context)!.usernameDifferent, null, null, null, false);
      } else
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.errorGenericTitle,
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
                        globalState.theme.button)
                ),
                dialogStyle: DialogStyle(backgroundColor: globalState.theme.background, elevation: 0),
                dismissable: false,
                message: Text(
                  AppLocalizations.of(context)!.generatingSecurityKeys, //"Generating Security Keys",
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
  }

  @override
  Widget build(BuildContext context) {
    Widget _adultNetwork = Stack(alignment: Alignment.bottomRight, children: [
      Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: globalState.theme.buttonIcon, //card
          ),
          child: Text('18+',
              style: TextStyle(
                fontSize: 15,
                color: globalState.theme.background,
              )))
    ]);

    final _searchResults = _networks.isNotEmpty
        ? ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) {
              return Divider(
                height: 10,
                color: globalState.theme.background,
              );
            },
            itemCount: _networks.length,
            itemBuilder: (BuildContext context, int index) {
              HostedFurnace network = _networks[index];
              bool _adultOnly = network.adultOnly;

              try {
                return InkWell(
                    onTap: () {
                      _openPublicNetworkDetails(network);
                    },
                    child: Card(
                        surfaceTintColor: Colors.transparent,
                        color: globalState.theme.trainingCard,
                        elevation: 8.0,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 10, right: 10),
                          child: Stack(
                            alignment: Alignment.centerRight,
                              children: [
                                Column(children: <Widget>[
                                  Row(children: <Widget>[
                                    Stack(
                                  alignment: _adultOnly == true
                                      ? Alignment.bottomRight
                                      : Alignment.center,
                                  children: [
                                    ClipOval(
                                        child: InkWell(
                                            child: network.hostedFurnaceImage ==
                                                null
                                                ? Image.asset(
                                                'assets/images/ios_icon.png',
                                                height: radius,
                                                width: radius,
                                                fit: BoxFit.fitHeight)
                                                : network.hostedFurnaceImage!.thumbnailTransferState == BlobState.READY ||
                                                FileSystemService.returnDiscoverableNetworkImagePath(
                                                    network.hostedFurnaceImage!) != null
                                                ? Image.file(
                                                File(FileSystemService.returnDiscoverableNetworkImagePath(network.hostedFurnaceImage!)!),
                                                height: radius,
                                                width: radius,
                                                fit: BoxFit.cover)
                                                : SpinKitThreeBounce(
                                                size: 12,
                                                color: globalState.theme.threeBounce))),
                                    _adultOnly == true
                                        ? _adultNetwork
                                        : Container(),
                                  ]),
                              const Padding(
                                  padding: EdgeInsets.only(
                                      left: 0.0,
                                      top: 0.0,
                                      bottom: 0.0,
                                      right: 8.0)),
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0.0, left: 7.0, right: 7.0),
                                      child: Text(
                                        network.name,
                                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                            fontSize:
                                                18, //ICTextStyle.appBarFontSize, //20,
                                            color: globalState
                                                .theme.trainingCardTitle,
                                            //fontWeight: FontWeight.bold
                                            fontWeight: FontWeight.normal),
                                      ))),
                            ]),
                            network.description != ''
                                ? Padding(
                              padding: const EdgeInsets.only(right: 22, top: 5),
                              child: Row(children: [
                                Expanded(
                                  child: ICText(
                                    network.description,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                )
                              ])
                            )
                                : Container(),
                          ]),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.keyboard_arrow_right,
                                    size: 22,
                                    color: globalState.theme.buttonIcon,
                                  )
                                )
                              ]))));
              } catch (err, trace) {
                LogBloc.insertError(err, trace);
                return Expanded(child: spinkit);
              }
            })
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: Text(AppLocalizations.of(context)!.noResults,
                style: ICTextStyle.getStyle(context: context, 
                    color: globalState.theme.buttonDisabled, fontSize: 14)));

    final _non18NetworkResults = _non18Networks.isNotEmpty
        ? ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) {
          return Divider(
            height: 10,
            color: globalState.theme.background,
          );
        },
        itemCount: _non18Networks.length,
        itemBuilder: (BuildContext context, int index) {
          HostedFurnace network = _non18Networks[index];
          bool _adultOnly = network.adultOnly;

          try {
            return InkWell(
              onTap: () {
                _openPublicNetworkDetails(network);
              },
              child: Card(
                  surfaceTintColor: Colors.transparent,
                  color: globalState.theme.trainingCard,
                  elevation: 8.0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  child: Padding(
                      padding: const EdgeInsets.only(
                          top: 10, bottom: 10, left: 10, right: 10),
                      child: Stack( alignment: Alignment.centerRight, children: [
                        Column(children: <Widget>[
                          Row(children: <Widget>[
                            Stack(
                              alignment: _adultOnly == true
                                  ? Alignment.bottomRight
                                  : Alignment.center,
                              children: [
                                ClipOval(
                                    child: InkWell(
                                        child: network.hostedFurnaceImage ==
                                            null
                                            ? Image.asset(
                                            'assets/images/ios_icon.png',
                                            height: radius,
                                            width: radius,
                                            fit: BoxFit.fitHeight)
                                            : network.hostedFurnaceImage!.thumbnailTransferState == BlobState.READY ||
                                            FileSystemService.returnDiscoverableNetworkImagePath(
                                                network.hostedFurnaceImage!) != null
                                            ? Image.file(
                                            File(FileSystemService.returnDiscoverableNetworkImagePath(network.hostedFurnaceImage!)!),
                                            height: radius,
                                            width: radius,
                                            fit: BoxFit.cover)
                                            : SpinKitThreeBounce(
                                            size: 12,
                                            color: globalState.theme.threeBounce)
                                    )),
                                _adultOnly == true
                                    ? _adultNetwork
                                    : Container(),
                              ],
                            ),
                            const Padding(
                                padding: EdgeInsets.only(
                                    left: 0.0,
                                    top: 0.0,
                                    bottom: 0.0,
                                    right: 8.0)),
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 0.0, left: 7.0, right: 7.0),
                                    child: Text(
                                      network.name,
                                      maxLines: 3,
                                      textScaler: TextScaler.linear(globalState.cardScaleFactor),
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                          fontSize:
                                          18, //ICTextStyle.appBarFontSize
                                          color: globalState
                                              .theme.trainingCardTitle,
                                          //fontWeight: FontWeight.bold
                                          fontWeight: FontWeight.normal),
                                    ))),
                          ]),
                          network.description != ''
                              ? Padding(
                              padding: const EdgeInsets.only(right: 22, top: 5),
                              child: Row(children: [
                                Expanded(
                                    child:
                                    ICText(
                                      network.description,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ))
                              ])
                          )
                              : Container(),
                        ]),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            size: 22,
                            color: globalState.theme.buttonIcon,
                          ),
                        )
                      ]))),
            );
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            return Expanded(child: spinkit);
          }
        })
        : _showSpinner ? spinkit : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Text(AppLocalizations.of(context)!.noPublicNetworks,
            style: ICTextStyle.getStyle(context: context, 
                color: globalState.theme.buttonDisabled, fontSize: 14)));

    final _defaultResults = _allNetworks.isNotEmpty
        ? ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) {
              return Divider(
                height: 10,
                color: globalState.theme.background,
              );
            },
            itemCount: _allNetworks.length,
            itemBuilder: (BuildContext context, int index) {
              HostedFurnace network = _allNetworks[index];
              bool _adultOnly = network.adultOnly;

              try {
                return InkWell(
                  onTap: () {
                    _openPublicNetworkDetails(network);
                  },
                  child: Card(
                      surfaceTintColor: Colors.transparent,
                      color: globalState.theme.trainingCard,
                      elevation: 8.0,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 10, right: 10),
                          child: Stack( alignment: Alignment.centerRight, children: [
                            Column(children: <Widget>[
                              Row(children: <Widget>[
                                Stack(
                                  alignment: _adultOnly == true
                                      ? Alignment.bottomRight
                                      : Alignment.center,
                                  children: [
                                    ClipOval(
                                        child: InkWell(
                                            child: network.hostedFurnaceImage ==
                                                null
                                                ? Image.asset(
                                                'assets/images/ios_icon.png',
                                                height: radius,
                                                width: radius,
                                                fit: BoxFit.fitHeight)
                                                : network.hostedFurnaceImage!.thumbnailTransferState == BlobState.READY ||
                                                FileSystemService.returnDiscoverableNetworkImagePath(
                                                network.hostedFurnaceImage!) != null
                                                ? Image.file(
                                                File(FileSystemService.returnDiscoverableNetworkImagePath(network.hostedFurnaceImage!)!),
                                                height: radius,
                                                width: radius,
                                                fit: BoxFit.cover)
                                                : SpinKitThreeBounce(
                                                size: 12,
                                                color: globalState.theme.threeBounce)
                                        )),
                                    _adultOnly == true
                                        ? _adultNetwork
                                        : Container(),
                                  ],
                                ),
                                const Padding(
                                    padding: EdgeInsets.only(
                                        left: 0.0,
                                        top: 0.0,
                                        bottom: 0.0,
                                        right: 8.0)),
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0.0, left: 7.0, right: 7.0),
                                        child: Text(
                                          network.name,
                                          maxLines: 3,
                                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                              fontSize:
                                                  18, //ICTextStyle.appBarFontSize
                                              color: globalState
                                                  .theme.trainingCardTitle,
                                              //fontWeight: FontWeight.bold
                                              fontWeight: FontWeight.normal),
                                        ))),
                              ]),
                              network.description != ''
                                  ? Padding(
                                    padding: const EdgeInsets.only(right: 22, top: 5),
                                    child: Row(children: [
                                    Expanded(
                                      child:
                                      ICText(
                                        network.description,
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ))
                                    ])
                                  )
                                  : Container(),
                            ]),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.keyboard_arrow_right,
                                size: 22,
                                color: globalState.theme.buttonIcon,
                              ),
                            )
                          ]))),
                );
              } catch (err, trace) {
                LogBloc.insertError(err, trace);
                return Expanded(child: spinkit);
              }
            })
        : _showSpinner ? spinkit : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: Text(AppLocalizations.of(context)!.noPublicNetworks,
                style: ICTextStyle.getStyle(context: context, 
                    color: globalState.theme.buttonDisabled, fontSize: 14)));

    final _makeBody = Column(children: [
      Padding(
          padding:
              const EdgeInsets.only(top: 4, bottom: 4, left: 10, right: 10),
          child: Row(children: <Widget>[
            Expanded(
                flex: 20,
                child: FormattedText(
                  labelText: AppLocalizations.of(context)!.searchForADiscoverableNetwork, //'Search for a discoverable network',
                  controller: _searchtext,
                ))
          ])),
      Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(children: <Widget>[
            Expanded(
                flex: 20,
                child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: ButtonType.getWidth(
                            MediaQuery.of(context).size.width)),
                    child: GradientButton(
                        text: AppLocalizations.of(context)!.search, //'Search',
                        onPressed: () {
                          _searchAction(_searchtext.text);
                        })))
          ])),
              globalState.user.minor == false || widget.fromLanding == true
                ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SwitchListTile(
                        inactiveThumbColor: globalState.theme.inactiveThumbColor,
                        inactiveTrackColor: globalState.theme.inactiveTrackColor,
                      trackOutlineColor: MaterialStateProperty.resolveWith(globalState.getSwitchColor),
                      title: ICText(
                        AppLocalizations.of(context)!.show18Networks, //'Show 18+ networks',
                        color: globalState.theme.buttonIcon,
                        fontSize: 15,
                      ),
                      value: _adultVisible,
                      activeColor: globalState.theme.button,
                      onChanged: (bool value) {
                          if (widget.fromLanding == true && value == true) {
                            DialogYesNo.askYesNo(context, AppLocalizations.of(context)!.verifyYourAge, AppLocalizations.of(context)!.verifyYourAgeLine1, _yes, null, false);
                          } else {
                            _setAdultNetworkVisibility(value);
                          }
                      }
                    )
                  )
                ]
              )
                  : Container(),
              _searchtext.text.isNotEmpty
                  ? _searchResults
                  : _adultVisible == true
                    ? _defaultResults
                    : _non18NetworkResults
    ]);

    return
        Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
                _makeBody
            ]);
  }

  _yes() {
    _setAdultNetworkVisibility(true);
  }

  _searchAction(String searchText) async {
    _networks = [];
    if (_adultVisible == false) {
      for (HostedFurnace network in _allNetworks) {
        if (network.name.toLowerCase().contains(searchText.toLowerCase())
          && network.adultOnly == false) {
          _networks.add(network);
        }
      }
    } else {
      for (HostedFurnace network in _allNetworks) {
        if (network.name.toLowerCase().contains(searchText.toLowerCase())) {
          _networks.add(network);
        }
      }
    }
    setState(() {});
  }

  void _openPublicNetworkDetails(HostedFurnace network) async {
    bool? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DiscoverableNetworkDetail(
                  //userFurnaces: widget.userFurnaces,
                  userFurnace: widget.userFurnace,
                  network: network,
                  fromPending: false,
                )));
    if (result == true) {
      setState(() {
        _hostedFurnaceBloc.getDiscoverable(widget.userFurnace!, ageRestrict!);
      });
    }
  }

  _setAdultNetworkVisibility(bool value) {
    setState(() {
      _adultVisible = value;
    });
    if (_searchtext.text.isNotEmpty) {
      _searchAction(_searchtext.text);
    }
  }

  // void _showApplyToNetwork(HostedFurnace network) async {
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => JoinDiscoverableNetwork(
  //             userFurnaces: widget.userFurnaces,
  //             userFurnace: widget.userFurnace,
  //             network: network,
  //           )
  //       )
  //   );
  // }
}
