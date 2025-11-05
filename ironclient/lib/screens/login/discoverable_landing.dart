import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/networksearch.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class DiscoverableFromLanding extends StatefulWidget {
  const DiscoverableFromLanding({
    Key? key,
  });

  @override
  _LandingState createState() {
    return _LandingState();
  }
}

class _LandingState extends State<DiscoverableFromLanding> {
  final ScrollController _scrollController = ScrollController();

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
  Widget build(BuildContext context) {
    return Scaffold(
        //key: _scaffoldKey,
        backgroundColor: globalState.theme.background,
        appBar:
            ICAppBar(title: AppLocalizations.of(context)!.chooseANetworkTitle),
        body: SafeArea(
            left: false,
            right: true,
            bottom: true,
            child: Stack(children: [
              Column(children: [
                Expanded(
                    child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            controller: _scrollController,
                            child: const WrapperWidget(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                  NetworkSearch(
                                      userFurnace: null, fromLanding: true),
                                ])))))
              ]),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
  }
}
