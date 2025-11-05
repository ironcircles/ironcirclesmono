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
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/report_post.dart';
import 'package:ironcirclesapp/screens/login/join_discoverable_landing.dart';
import 'package:ironcirclesapp/screens/login/join_discoverable_network.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';

class DiscoverableNetworkDetail extends StatefulWidget {
  //final List<UserFurnace> userFurnaces;
  final UserFurnace? userFurnace;
  final HostedFurnace network;
  final bool fromPending;

  const DiscoverableNetworkDetail({
    Key? key,
    // required this.userFurnaces,
    this.userFurnace,
    required this.network,
    required this.fromPending,
  }) : super(key: key);

  @override
  PublicNetworkDetailState createState() {
    return PublicNetworkDetailState();
  }
}

class PublicNetworkDetailState extends State<DiscoverableNetworkDetail> {
  File? _image;
  late bool _adultOnly;

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
  double radius = 350 - (globalState.scaleDownTextFont * 2);
  UserFurnace? newUserFurnace;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  late bool _approved;
  late bool _override;

  @override
  void initState() {
    super.initState();

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

    _hostedFurnaceBloc.networkApprovedUpdated.listen((hostedFurnace) {
      setState(() {
        widget.network.approved = hostedFurnace.approved;
        _approved = hostedFurnace.approved;
      });
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.networkOverrideUpdated.listen((hostedFurnace) {
      setState(() {
        widget.network.override = hostedFurnace.override;
        _override = hostedFurnace.override;
      });
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    if (widget.network != null) {
      network = widget.network;
      _publicNetworkJoin = true;
      _approved = widget.network.approved;
      _override = widget.network.override;

      _adultOnly = network.adultOnly;
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final overrideNetworkButton = Row(children: <Widget>[
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 5, top: 20, bottom: 0),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                        child: SwitchListTile(
                            inactiveThumbColor:
                                globalState.theme.inactiveThumbColor,
                            inactiveTrackColor:
                                globalState.theme.inactiveTrackColor,
                            trackOutlineColor:
                                MaterialStateProperty.resolveWith(
                                    globalState.getSwitchColor),
                            title: ICText(
                              AppLocalizations.of(context)!.overrideNetwork,
                              color: globalState.theme.buttonIcon,
                              fontSize: 15,
                            ),
                            value: _override,
                            activeColor: globalState.theme.button,
                            onChanged: (bool value) {
                              _setNetworkOverride(value);
                            }))
                  ])))
    ]);

    Widget _adultNetwork = Stack(alignment: Alignment.bottomRight, children: [
      Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: globalState.theme.buttonIcon, //card
          ),
          child: Text('18+',
              style: TextStyle(
                fontSize: (20 - globalState.scaleDownTextFont) /
                    globalState.mediaScaleFactor,
                color: globalState.theme.background,
              )))
    ]);

    final connectButton = Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 5, top: 20, bottom: 0),
                  child: GradientButton(
                      width: screenWidth - 20,
                      text: AppLocalizations.of(context)!
                          .requestToJoinNetwork
                          .toUpperCase(),
                      onPressed: () {
                        _applyToPublicNetwork();
                      })))
        ]);

    final reportNetworkButton = Row(children: <Widget>[
      Expanded(
          child: Center(child:SizedBox(width: 250, child:TextButton(
                  child: ICText(AppLocalizations.of(context)!
                      .reportNetworkAvatar
                      .toLowerCase(), color: globalState.theme.labelText,),
                  onPressed: () {
                    _reportNetwork();
                  }))))
    ]);

    final approveNetworkButton = Row(children: <Widget>[
      Expanded(
          child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 10, bottom: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: SwitchListTile(
                      inactiveThumbColor: globalState.theme.inactiveThumbColor,
                      inactiveTrackColor: globalState.theme.inactiveTrackColor,
                      trackOutlineColor: MaterialStateProperty.resolveWith(
                          globalState.getSwitchColor),
                      title: ICText(
                        AppLocalizations.of(context)!.approveNetwork,
                        color: globalState.theme.buttonIcon,
                        fontSize: 15,
                      ),
                      value: _approved,
                      activeColor: globalState.theme.button,
                      onChanged: (bool value) {
                        _setNetworkApproved(value);
                      }))
            ]),
      ))
    ]);

    final _publicNetworkWidgets = Scrollbar(
        controller: _scrollController,
        //thumbVisibility: true,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollController,
            child: WrapperWidget(
                child: Column(children: [
              ClipOval(
                  child: _image != null
                      ? Image.file(_image!,
                          height: radius, width: radius, fit: BoxFit.cover)
                      : FileSystemService.discoverableFurnaceImageExistsSync(
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
              _adultOnly == true ? _adultNetwork : Container(),
              const Padding(
                padding: EdgeInsets.only(top: 0, bottom: 10),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 39, right: 39, top: 10),
                  child: ICText(
                    network.name,
                    fontSize: (20 - globalState.scaleDownTextFont) /
                        globalState.mediaScaleFactor,
                    color: globalState.theme.button,
                  )),
              Padding(
                  padding: const EdgeInsets.only(
                      left: 39, right: 39, top: 10, bottom: 10),
                  child: ICText(
                    network.description,
                    fontSize: (18 - globalState.scaleDownTextFont) /
                        globalState.mediaScaleFactor,
                    overflow: TextOverflow.visible,
                  )),
              const Padding(
                padding: EdgeInsets.only(top: 20),
              ),
              globalState.user.role == Role.IC_ADMIN &&
                      widget.fromPending == false
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: overrideNetworkButton)
                  : Container(),
              globalState.isDesktop() == false
                  ? Container()
                  : widget.fromPending == true
                      ? Container()
                      : connectButton,
              globalState.isDesktop() == false
                  ? Container()
                  : widget.network.hostedFurnaceImage != null &&
                          widget.userFurnace != null
                      ? reportNetworkButton
                      : Container(),
              widget.fromPending == true ? approveNetworkButton : Container(),
              widget.fromPending == true ? overrideNetworkButton : Container(),
            ]))));

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.networkDetails,
          pop: _leave,
        ),
        body: SafeArea(
            left: false,
            top: true,
            right: false,
            bottom: true,
            child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _publicNetworkWidgets,
                      ),
                      globalState.isDesktop()
                          ? Container()
                          : widget.fromPending == true
                              ? Container()
                              : connectButton,
                      globalState.isDesktop()
                          ? Container()
                          : widget.network.hostedFurnaceImage != null &&
                                  widget.userFurnace != null
                              ? reportNetworkButton
                              : Container(),
                      widget.fromPending == true
                          ? approveNetworkButton
                          : Container(),
                      widget.fromPending == true
                          ? overrideNetworkButton
                          : Container(),
                    ]))));
  }

  _leave() {
    if (_override == true) {
      Navigator.pop(context, _override);
    } else if (_approved == true && widget.fromPending == true) {
      Navigator.pop(context, _approved);
    } else {
      Navigator.pop(context);
    }
  }

  void _applyToPublicNetwork() {
    if (widget.userFurnace == null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => JoinDiscoverableLanding(
                    network: widget.network,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => JoinDiscoverableNetwork(
                    userFurnace: widget.userFurnace!,
                    network: widget.network,
                  )));
    }
  }

  void _setNetworkApproved(bool value) {
    _hostedFurnaceBloc.setNetworkApproved(
        widget.userFurnace!, widget.network, value);
  }

  void _setNetworkOverride(bool value) async {
    _hostedFurnaceBloc.setNetworkOverride(
        widget.userFurnace!, widget.network, value);
  }

  void _reportNetwork() async {
    Violation? violation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPost(
            member: null,
            type: ReportType.NETWORK,
            userCircleCache: null,
            circleObject: null,
            circleObjectBloc: null,
            userFurnace: widget.userFurnace!,
            network: widget.network,
          ),
        ));

    if (violation != null) {
      _hostedFurnaceBloc.reportAvatar(widget.userFurnace!, violation);

      FormattedSnackBar.showSnackbarWithContext(
          context,
          AppLocalizations.of(context)!.potentialViolationReported,
          "",
          3,
          false);
    }
  }
}
