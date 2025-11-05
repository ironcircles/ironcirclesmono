import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/models/hostedfurnace.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/expandingtext.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class JoinDiscoverableNetwork extends StatefulWidget {
  final UserFurnace userFurnace;
  //final List<UserFurnace> userFurnaces;
  final String? toast;
  final HostedFurnace network;

  const JoinDiscoverableNetwork({
    Key? key,
    this.toast,
    required this.userFurnace,
    //required this.userFurnaces,
    required this.network,
  }) : super(key: key);

  @override
  _JoinDiscoverableNetworkState createState() =>
      _JoinDiscoverableNetworkState();
}

class _JoinDiscoverableNetworkState extends State<JoinDiscoverableNetwork> {
  bool _showAPIKey = false;
  UserFurnace? localFurnace;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final TextEditingController _apikey = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _message = TextEditingController();
  List<NetworkRequest> _requests = [];

  @override
  void initState() {
    super.initState();

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    _hostedFurnaceBloc.requestsError.listen((error) {
      if (error == true) {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.requestSubmitted, "", 3, false);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.requestEnded, "", 3, false);
      debugPrint("error $err");
    }, cancelOnError: false);

    _hostedFurnaceBloc.requests.listen((requests) {
      _requests = requests;
    });

    _hostedFurnaceBloc.getRequests(widget.userFurnace, globalState.user);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _networkApplyWidgets(BuildContext context, double screenWidth) {
    return Column(
      children: [
        Padding(
            padding:
                const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 5),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: ICText(
                      AppLocalizations.of(context)!.requestToJoinNetwork,
                      fontSize: globalState.userSetting.fontSize,
                      color: globalState.theme.buttonIcon),
                )
              ]),
              const Padding(
                padding: EdgeInsets.only(top: 10),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 20),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                            child: ExpandingText(
                                height: 300,
                                labelText: AppLocalizations.of(context)!
                                    .enterRequest
                                    .toLowerCase(),
                                controller: _message,
                                maxLength: 1000,
                                validator: (value) {
                                  return null;
                                }))
                      ]))
            ]))
      ],
    );
  }
  //
  // Widget _networkWidgets(BuildContext context, double screenWidth) {
  //   return Column(
  //     children: [
  //       Padding(
  //           padding:
  //               const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 5),
  //           child: Column(children: [
  //             Row(children: [
  //               Expanded(
  //                 child: ICText(
  //                     AppLocalizations.of(context)!.instantJoinAccessCode,
  //                     fontSize: globalState.userSetting.fontSize,
  //                     color: globalState.theme.buttonIcon),
  //               )
  //             ]),
  //             const Padding(
  //               padding: EdgeInsets.only(top: 10),
  //             ),
  //             Padding(
  //                 padding: const EdgeInsets.only(left: 10, right: 49),
  //                 child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     children: <Widget>[
  //                       Expanded(
  //                           child: FormattedText(
  //                               labelText:
  //                                   AppLocalizations.of(context)!.accessCode,
  //                               obscureText: !_showAPIKey,
  //                               maxLength: 25,
  //                               maxLines: 1,
  //                               controller: _apikey,
  //                               validator: (value) {
  //                                 if (value.isEmpty) {
  //                                   return AppLocalizations.of(context)!
  //                                       .errorFieldRequired;
  //                                 }
  //                                 return null;
  //                               })),
  //                       IconButton(
  //                           icon: Icon(Icons.remove_red_eye,
  //                               color: _showAPIKey
  //                                   ? globalState.theme.buttonIcon
  //                                   : globalState.theme.buttonDisabled),
  //                           onPressed: () {
  //                             setState(() {
  //                               _showAPIKey = !_showAPIKey;
  //                             });
  //                           })
  //                     ])),
  //           ])),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final requestConnectButton =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Spacer(),
      Padding(
          padding:
              const EdgeInsets.only(left: 5, top: 20, bottom: 20, right: 5),
          child: GradientButtonDynamic(
              text: AppLocalizations.of(context)!.requestToJoinButton,
              onPressed: () {
                _requestConnectToNetwork(widget.network);
              }))
    ]);

    /*
    final connectWithCodeButton =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Spacer(),
      Padding(
          padding:
              const EdgeInsets.only(left: 5, top: 20, bottom: 35, right: 5),
          child: GradientButtonDynamic(
              text: 'JOIN WITH ACCESS CODE',
              onPressed: () {
                if (_apikey.text != "") {
                  _connectWithCode(widget.network);
                } else {
                  FormattedSnackBar.showSnackbarWithContext(
                      context, 'Please enter access code', '', 3, false);
                }
              }))
    ]);

     */

    return Scaffold(
        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.joinNetwork,
        ),
        backgroundColor: globalState.theme.background,
        body: Padding(
                padding:
                    const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 0),
                child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    controller: _scrollController,
                    child: WrapperWidget(
                        child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          _networkApplyWidgets(context, screenWidth),
                          requestConnectButton,
                          /*Container(
                        height: 1,
                        color: globalState.theme.buttonDisabled,
                      ),
                      _networkWidgets(context, screenWidth),
                      connectWithCodeButton,

                       */
                        ])))));
  }

  /*
  _connectWithCode(HostedFurnace network) async {
    try {
      if (mounted) {
        if (await _hostedFurnaceBloc.checkIfAlreadyOnNetwork(network.name)) {
          if (mounted) {
            DialogNotice.showNoticeOptionalLines(context, 'Already connected',
                'You cannot connect to the same network twice', false);

            return;
          }
        }
      }
      bool nameAvailable =
          await _hostedFurnaceBloc.valid(network.name, _apikey.text);
      if (!nameAvailable && mounted) {
        DialogNotice.showNotice(
            context,
            'Network not found',
            'Please check the access code and try again',
            null,
            null,
            null,
            false);
        return;
      }
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NetworkConnectHosted(
                    userFurnace: widget.userFurnaces[0],
                    fromFurnaceManager: true,
                    authServer: false,
                    network: network,
                    //actionRequired: act,
                  )));
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

   */

  ///request to connect
  _requestConnectToNetwork(HostedFurnace network) async {
    try {
      if (mounted) {
        if (await _hostedFurnaceBloc.checkIfAlreadyOnNetwork(network.name)) {
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
      if (_requests.isNotEmpty) {
        for (NetworkRequest req in _requests) {
          if (req.hostedFurnace.id == network.id) {
            DialogNotice.showNoticeOptionalLines(
                context,
                AppLocalizations.of(context)!.alreadyRequested,
                AppLocalizations.of(context)!.alreadyRequestedMessage,
                false);
            return;
          }
        }
      }

      String message = _message.text;
      NetworkRequest request = NetworkRequest(
          status: 0,
          hostedFurnace: widget.network,
          user: globalState.user,
          description: message);
      setState(() {
        _hostedFurnaceBloc.makeRequest(widget.userFurnace, request);
      });
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }
}
