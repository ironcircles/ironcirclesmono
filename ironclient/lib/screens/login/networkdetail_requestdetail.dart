import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/networkrequest.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class NetworkDetailRequestDetail extends StatefulWidget {
  final NetworkRequest networkRequest;
  final Function accept;
  final Function deny;

  const NetworkDetailRequestDetail({
    Key? key,
    required this.networkRequest,
    required this.accept,
    required this.deny,
  }) : super(key: key);

  @override
  _NetworkDetailRequestDetailState createState() =>
      _NetworkDetailRequestDetailState();
}

class _NetworkDetailRequestDetailState
    extends State<NetworkDetailRequestDetail> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final userFurnaceBloc = UserFurnaceBloc();

  UserFurnace? localFurnace;
  double radius = 200 - (globalState.scaleDownTextFont * 2);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userFurnaceBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Scrollbar(
        controller: _scrollController,
        //thumbVisibility: true,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollController,
            child: Row(children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Text(widget.networkRequest.description)))
            ])));

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar: ICAppBar(title: AppLocalizations.of(context)!.requestDetail),
        body: SafeArea(
            left: false,
            top: false,
            right: true,
            bottom: true,
            child: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(children: [
                          ICText(
                            '${AppLocalizations.of(context)!.network}: ',
                            color: globalState.theme.labelText,
                          ),
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Text(widget
                                      .networkRequest.hostedFurnace.name)))
                        ])),
                    const Padding(padding: EdgeInsets.only(bottom: 10)),
                    Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(children: [
                          ICText(
                            '${AppLocalizations.of(context)!.requester}: ',
                            color: globalState.theme.labelText,
                          ),
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: ICText(
                                      widget.networkRequest.user.username!,
                                      color: globalState.theme.button)))
                        ])),
                    const Padding(padding: EdgeInsets.only(bottom: 10)),
                    Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(children: [
                          ICText(
                            '${AppLocalizations.of(context)!.status}: ',
                            color: globalState.theme.labelText,
                          ),
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: ICText(
                                      widget.networkRequest.status ==
                                              NetworkRequestStatus.DECLINED
                                          ? AppLocalizations.of(context)!.declined.toLowerCase()
                                          : AppLocalizations.of(context)!.pending.toLowerCase(),
                                      color: widget.networkRequest.status ==
                                              NetworkRequestStatus.DECLINED
                                          ? globalState.theme.warning
                                          : globalState.theme.urgentAction)))
                        ])),
                    const Padding(padding: EdgeInsets.only(bottom: 10)),
                    Expanded(child: makeBody),
                    Row(
                      children: [
                        widget.networkRequest.status ==
                                NetworkRequestStatus.DECLINED
                            ? const Spacer()
                            : Expanded(
                                child: GradientButton(
                                    text: AppLocalizations.of(context)!.deny.toLowerCase(),
                                    color2: globalState.theme.buttonDisabled,
                                    onPressed: _deny),
                              ),
                        Expanded(
                            child: GradientButton(
                          text: AppLocalizations.of(context)!.accept.toLowerCase(),
                          onPressed: _accept,
                        ))
                      ],
                    )
                  ],
                ))));
  }

  _accept() {
    widget.accept(widget.networkRequest);
    Navigator.pop(context);
  }

  _deny() {
    widget.deny(widget.networkRequest);
    Navigator.pop(context);
  }
}
