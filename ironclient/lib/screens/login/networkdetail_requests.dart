import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/screens/login/networkdetail_requestdetail.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class NetworkRequests extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final HostedFurnaceBloc hostedFurnaceBloc;
  final List<NetworkRequest> networkRequests;
  final bool fromActionRequired;

  const NetworkRequests(
      {Key? key,
      required this.userFurnace,
      required this.hostedFurnaceBloc,
      required this.networkRequests,
      required this.fromActionRequired,
      required this.userFurnaces})
      : super(key: key);

  @override
  NetworkRequestsState createState() => NetworkRequestsState();
}

class NetworkRequestsState extends State<NetworkRequests> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final userFurnaceBloc = UserFurnaceBloc();
  late final GlobalEventBloc _globalEventBloc;
  //late HostedFurnace hostedFurnace;
  late List<NetworkRequest> _requests;

  UserFurnace? localFurnace;
  double radius = 200 - (globalState.scaleDownTextFont * 2);

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    widget.hostedFurnaceBloc.networkRequests.listen((networkRequests) {
      if (mounted) {
        setState(() {
          _requests = networkRequests;
          _showSpinner = false;
        });
      }
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      debugPrint("error $err");
    }, cancelOnError: false);

    _initListeners();

    widget.hostedFurnaceBloc.getNetworkRequests(widget.userFurnace);

    _requests = widget.networkRequests;
    if (_requests.isNotEmpty) {
      setState(() {
        _showSpinner = false;
      });
    }

    localFurnace ??= widget.userFurnace;

    /* if (localFurnace!.role == Role.OWNER ||
        localFurnace!.role == Role.ADMIN ||
        localFurnace!.role == Role.IC_ADMIN ||
        localFurnace!.discoverable == true) {
      widget.hostedFurnaceBloc.getMembers(localFurnace!);
      _showSpinner = true;
    }*/

    super.initState();
  }

  @override
  void dispose() {
    userFurnaceBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ListTile makeListTile(NetworkRequest row) => ListTile(
      onTap: () => _fullScreen(row),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text(
            row.user.username!,
            textScaler: TextScaler.linear(globalState.cardScaleFactor),
            style: TextStyle(
                color: globalState.theme.textFieldPerson,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      row.description != ''
                          ? Expanded(
                              child: ICText(
                              row.description,
                              color: globalState.theme.labelText,
                              fontSize: 14,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.visible,
                              maxLines: 8,
                            ))
                          : Container(),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.only(left: 5.0, right: 0),
                            child: ICText(
                              row.status == NetworkRequestStatus.DECLINED
                                  ? AppLocalizations.of(context)!.networkRequestDeclined
                                  : AppLocalizations.of(context)!.networkRequestPending,
                              textScaleFactor: 1.0,
                              fontSize: 14,
                              color: globalState.theme.furnace,
                            )),
                        const Spacer(),
                        row.status == NetworkRequestStatus.DECLINED
                            ? Container()
                            : SizedBox(
                                child: InkWell(
                                    onTap: () => _denyRequest(row),
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 10,
                                            left: 6,
                                            right: 6),
                                        child: ICText(
                                          AppLocalizations.of(context)!.deny.toLowerCase(),
                                          textAlign: TextAlign.center,
                                          color:
                                              globalState.theme.buttonDisabled,
                                          fontSize: 14,
                                        )))),
                        row.status == NetworkRequestStatus.DECLINED
                            ? Container()
                            : const Padding(
                                padding: EdgeInsets.only(right: 5),
                              ),
                        SizedBox(
                            child: InkWell(
                                onTap: () => _acceptRequest(row),
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10, bottom: 10, left: 6, right: 6),
                                    child: ICText(
                                      AppLocalizations.of(context)!.accept.toLowerCase(),
                                      textAlign: TextAlign.end,
                                      color: globalState.theme.buttonIcon,
                                      fontSize: 14,
                                    )))),
                      ]),
                ],
              )),
          trailing: IconButton(
              icon: const Icon(Icons.navigate_next_rounded),
              onPressed: () {
                _fullScreen(row);
              }),
        );

    Card makeCard(NetworkRequest row) => Card(
          surfaceTintColor: Colors.transparent,
          color: globalState.theme.card,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: makeListTile(row),
        );

    final makeRequests = _requests.isNotEmpty
            ? Scrollbar(
                controller: _scrollController,
                //thumbVisibility: true,
                child: ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                          color: globalState.theme.divider,
                        ),
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _requests.length,
                    itemBuilder: (BuildContext context, int index) {
                      NetworkRequest row = _requests[index];

                      return WrapperWidget(child:makeCard(row));
                    }))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    ICText(
                      AppLocalizations.of(context)!.noPendingRequests,
                      fontSize: 17,
                    )
                  ]);

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.networkRequests),
        body: SafeArea(
            left: false,
            top: false,
            right: true,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                widget.userFurnace.connected!
                    ? Expanded(child:
                    _showSpinner
                      ? Center(child: spinkit)
                          : makeRequests
                    )
                    : Container(),
              ],
            )));
  }

  _denyRequest(NetworkRequest request) async {
    request.status = NetworkRequestStatus.DECLINED;
    widget.hostedFurnaceBloc
        .updateRequest(widget.userFurnace, request, );
    setState(() {
      request.status = NetworkRequestStatus.DECLINED;
    });
    if (widget.fromActionRequired == true) {
      _requests.remove(request);
    }
    if (_requests.isEmpty) {
      Navigator.pop(context, true);
    }
  }

  _acceptRequest(NetworkRequest request) async {
    request.status = NetworkRequestStatus.ACCEPTED;
    widget.hostedFurnaceBloc
        .updateRequest(widget.userFurnace, request,);
    setState(() {
      _requests.remove(request);
    });
    if (_requests.isEmpty) {
      widget.hostedFurnaceBloc.requestsDone();
      Navigator.pop(context, true);
    }
  }

  _fullScreen(NetworkRequest networkRequest) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NetworkDetailRequestDetail(
                  networkRequest: networkRequest,
                  accept: _acceptRequest,
                  deny: _denyRequest,
                )));
  }

  void _initListeners() {
    userFurnaceBloc.userFurnace.listen((success) {
      localFurnace = success;

      if (!success!.connected!) {
        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.networkDisconnected, "", 1, false);
        setState(() {});
      }
    }, onError: (err) {
      setState(() {
        localFurnace = null;
      });
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    userFurnaceBloc.removed.listen((success) {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.networkRemoved, "", 2, false);

      Navigator.pop(context);
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);
  }
}

class FurnaceConnection {
  final UserFurnace userFurnace;
  final User user;

  FurnaceConnection({required this.userFurnace, required this.user});
}
