import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/actionneededbloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/screens/login/network_connect_hosted.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class NetworkManagerRequests extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final String? toast;
  final UserFurnaceBloc userFurnaceBloc;

  const NetworkManagerRequests(
      {Key? key,
      this.toast,
      required this.userFurnace,
      required this.userFurnaces,
      required this.userFurnaceBloc})
      : super(key: key);

  @override
  NetworkManagerRequestsState createState() => NetworkManagerRequestsState();
}

class NetworkManagerRequestsState extends State<NetworkManagerRequests> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late List<NetworkRequest> _requests;
  final ScrollController _scrollController = ScrollController();
  late HostedFurnaceBloc _hostedFurnaceBloc;
  final ActionNeededBloc _actionNeededBloc = ActionNeededBloc();
  late GlobalEventBloc _globalEventBloc;
  late UserCircleBloc _userCircleBloc;

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(color: globalState.theme.spinner, size: 60);

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _userCircleBloc = UserCircleBloc(globalEventBloc: _globalEventBloc);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

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

    _hostedFurnaceBloc.getRequests(widget.userFurnace, globalState.user);

    super.initState();
  }

  @override
  void dispose() {
    _actionNeededBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ListTile makeListTile(NetworkRequest row) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text(
            row.hostedFurnace.name,
            textScaler: TextScaler.linear(globalState.cardScaleFactor),
            style: TextStyle(
                color: globalState.theme.textFieldPerson,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      row.description != ''
                          ? Flexible(
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
                  Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            ICText(
                              row.status == NetworkRequestStatus.ACCEPTED
                                  ? AppLocalizations.of(context)!.requestApproved
                                  : row.status == NetworkRequestStatus.DECLINED
                                      ? AppLocalizations.of(context)!.requestDeclined
                                      : AppLocalizations.of(context)!.requestPending,
                              textScaleFactor: 1.0,
                              fontSize: 14,
                              color: globalState.theme.furnace,
                            ),
                            Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: SizedBox(
                                    child: InkWell(
                                        onTap: () => _cancelRequest(row),
                                        child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: ICText(
                                              AppLocalizations.of(context)!.cancel.toLowerCase(),
                                              textAlign: TextAlign.end,
                                              color: globalState
                                                  .theme.labelTextSubtle,
                                              fontSize: 14,
                                            ))))),
                            const Spacer(),
                            row.status == NetworkRequestStatus.ACCEPTED
                                ? InkWell(
                                    onTap: () => _joinNetwork(row),
                                    child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: ICText(
                                          AppLocalizations.of(context)!.joinNow.toUpperCase(),
                                          textAlign: TextAlign.end,
                                          color: globalState.theme.buttonIcon,
                                          fontSize: 14,
                                        )))
                                /*GradientButtonDynamic(
                                    text: 'JOIN NOW',
                                    onPressed: () => _joinNetwork(row),
                                  )*/
                                : Container(),
                          ])),
                ],
              )),
          /*trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          row.status == NetworkRequestStatus.ACCEPTED
          ? GradientButtonDynamic(
            onPressed: () => _joinNetwork(row),
            text: "Join Now",
          )
              : Container(),
        ]
      )*/
        );

    Card makeCard(NetworkRequest row) => Card(
          surfaceTintColor: Colors.transparent,
          color: globalState.theme.card,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: makeListTile(row),
        );

    final makeRequests = _showSpinner
        ? Center(child: spinkit)
        : _requests.isNotEmpty
            ? SingleChildScrollView(
                child: Container(
                    padding: const EdgeInsets.only(
                        left: 0, right: 0, top: 0, bottom: 5),
                    child: ListView.builder(
                        /*separatorBuilder: (context, index) => Divider(
                              color: globalState.theme.divider,
                            ),

                         */
                        scrollDirection: Axis.vertical,
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: _requests.length,
                        itemBuilder: (BuildContext context, int index) {
                          NetworkRequest row = _requests[index];

                          return WrapperWidget(child: makeCard(row));
                        })))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    ICText(
                      AppLocalizations.of(context)!.noPendingRequests,
                      fontSize: 17,
                    )
                  ]);

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            body: SafeArea(
                left: false,
                top: false,
                right: false,
                bottom: true,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[Expanded(child: makeRequests)]))));
  }

  _cancelRequest(NetworkRequest request) async {
    _userCircleBloc.refreshedUserCircles
        .listen((refreshUserCircleCaches) async {
      ///deletes from cache and API
      _actionNeededBloc
          .dismissNetworkNotification([widget.userFurnace], request);
    });

    if (request.status == NetworkRequestStatus.ACCEPTED) {
      ///reload action required client side
      _userCircleBloc.fetchUserCircles([widget.userFurnace], true, false);
    }

    ///delete request API side
    request.status = NetworkRequestStatus.CANCELED;
    _hostedFurnaceBloc.updateRequest(
      widget.userFurnace,
      request,
    );

    ///delete request client side
    setState(() {
      _requests.remove(request);
    });
  }

  _joinNetwork(NetworkRequest request) async {
    bool canAddNetwork = await PremiumFeatureCheck.canAddNetwork(context, widget.userFurnaces);

    if (canAddNetwork) {

      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NetworkConnectHosted(
                userFurnace: widget.userFurnace,
                source: Source.fromNetworkRequests,
                authServer: false,
                request: request,
              )));

      widget.userFurnaceBloc.request(globalState.user.id!);
      _hostedFurnaceBloc.getRequests(widget.userFurnace, globalState.user);
    }
  }
}
