import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/hostedfurnace.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/screens/login/discoverablenetworkdetail.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:provider/provider.dart';

class PendingNetworks extends StatefulWidget {
  final UserFurnace userFurnace;

  const PendingNetworks({
    Key? key,
    required this.userFurnace,
}) : super(key: key);

  @override
  PendingNetworksState createState() => PendingNetworksState();
}

class PendingNetworksState extends State<PendingNetworks> {

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60
  );

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late GlobalEventBloc _globalEventBloc;
  late HostedFurnaceBloc _hostedFurnaceBloc;

  double radius = 50;

  List<HostedFurnace> _networks = [];

  @override
  void initState() {
    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _hostedFurnaceBloc.pendingDiscoverableNetworks.listen((hostedFurnaces) {
      if (hostedFurnaces.isNotEmpty) {
        for (HostedFurnace network in hostedFurnaces) {
          if (network.hostedFurnaceImage != null) {
            _hostedFurnaceBloc.downloadDiscoverableImage(_globalEventBloc, widget.userFurnace, network);
          }
        }
      }
      setState(() {
        _networks = hostedFurnaces;
        _showSpinner = false;
      });
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _globalEventBloc.progressFurnaceImageIndicator.listen((hostedFurnaceImage) {
      if (mounted) setState(() {});
    });

    _hostedFurnaceBloc.getPendingDiscoverable(widget.userFurnace);

  }

  @override
  void dispose() {
    super.dispose();
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

    Widget viewNetworks = Column(
        children: [
          _networks.isNotEmpty
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
                        _openNetworkDetails(network);
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
                                Column(
                                    children: <Widget>[
                                      Row(children: <Widget>[
                                        Stack(
                                            alignment: _adultOnly == true
                                                ? Alignment.bottomRight
                                                : Alignment.center,
                                            children: [
                                              ClipOval(
                                                  child: InkWell(
                                                      child: network.hostedFurnaceImage !=
                                                          null
                                                          ? network.hostedFurnaceImage!
                                                          .thumbnailTransferState ==
                                                          BlobState.READY ||
                                                          FileSystemService
                                                              .returnDiscoverableNetworkImagePath(
                                                              network
                                                                  .hostedFurnaceImage!) !=
                                                              null
                                                          ? Image.file(File(FileSystemService.returnDiscoverableNetworkImagePath(network.hostedFurnaceImage!)!),
                                                          height: radius,
                                                          width: radius,
                                                          fit: BoxFit.cover)
                                                          : network.hostedFurnaceImage!
                                                          .thumbnailTransferState ==
                                                          BlobState
                                                              .DOWNLOADING
                                                          ? SpinKitThreeBounce(
                                                        size: 12,
                                                        color: globalState
                                                            .theme
                                                            .threeBounce,
                                                      )
                                                          : spinkit
                                                          : Image.asset(
                                                          'assets/images/ios_icon.png',
                                                          height: radius,
                                                          width: radius,
                                                          fit: BoxFit.fitHeight))),
                                              _adultOnly == true
                                                  ? _adultNetwork
                                                  : Container(),
                                            ]
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.only(
                                                left: 0, right: 8.0, top: 0, bottom: 0
                                            )
                                        ),
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
                              ])
                          )
                      )
                  );
                } catch (err, trace) {
                  LogBloc.insertError(err, trace);
                  return Expanded(child: spinkit);
                }
              }
          )
              : _showSpinner ? spinkit : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: Text("No Pending Networks",
                      style: ICTextStyle.getStyle(context: context, 
                          color: globalState.theme.buttonDisabled, fontSize: 14))
              )
            ],
          )
        ]
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      appBar: const ICAppBar(title: 'Pending Networks'),
      body: SafeArea(
        left: false,
        top: false,
        right: true,
        bottom: false,
        child: Stack(
          children: [
            Column(children: [
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    //keyboardDismissBehavior
                    controller: _scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        viewNetworks,
                      ]
                    )
                  )
                )
              )
            ])
          ]
        )
      )
    );

  }

  void _openNetworkDetails(HostedFurnace network) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DiscoverableNetworkDetail(
              userFurnace: widget.userFurnace,
              network: network,
              fromPending: true,
            )
        )
    );
    if (result == true) {
      setState(() {
        ///refresh page
        _networks.remove(network);
      });
    }
  }

}