import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_ironcoin.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_privacyplus.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

// class TAB {
//   static const int IRONCOIN = 0;
//   static const int PRIVACY = 1;
// }

class IronStore extends StatefulWidget {
  //final int tab;
  const IronStore({
    Key? key,
    //this.tab = 0,
  }) : super(key: key);

  @override
  _LocalState createState() => _LocalState();
}

class _LocalState extends State<IronStore> {
  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();

  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    IronCoinBloc.ironCoinFetched.listen((success) {
      if (mounted) setState(() {});
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    _ironCoinBloc.fetchCoins();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    // final tabs = DefaultTabController(
    //     length: 2,
    //     initialIndex: widget.tab,
    //     child: Scaffold(
    //         backgroundColor: globalState.theme.background,
    //         appBar: PreferredSize(
    //             preferredSize: const Size(30.0, 40.0),
    //             child: TabBar(
    //                 dividerHeight: 0.0,
    //                 padding: const EdgeInsets.only(left: 3, right: 3),
    //                 indicatorSize: TabBarIndicatorSize.label,
    //                 indicatorPadding:
    //                     const EdgeInsets.symmetric(horizontal: -10.0),
    //                 labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
    //                 tabAlignment: TabAlignment.start,
    //                 unselectedLabelColor: globalState.theme.unselectedLabel,
    //                 labelColor: globalState.theme.buttonIcon,
    //                 isScrollable: true,
    //                 indicatorColor: Colors.black,
    //                 indicator: BoxDecoration(
    //                     borderRadius: BorderRadius.circular(10),
    //                     color: Colors.lightBlueAccent.withOpacity(.1)),
    //                 tabs: [
    //                   Tab(
    //                       child: Align(
    //                     alignment: Alignment.center,
    //                     child: Text(AppLocalizations.of(context)!.ironCoinTab,
    //                         textScaler: const TextScaler.linear(1.0),
    //                         style: const TextStyle(fontSize: 15.0)),
    //                   )),
    //                   Tab(
    //                       child: Align(
    //                     alignment: Alignment.center,
    //                     child: Text(AppLocalizations.of(context)!.privacy,
    //                         textScaler: const TextScaler.linear(1.0),
    //                         style: const TextStyle(fontSize: 15.0)),
    //                   )),
    //                 ])),
    //         body: TabBarView(children: [
    //           const IronStoreIronCoin(),
    //           SettingsPremium(
    //             userFurnace: globalState.userFurnace,
    //             fromFurnaceManager: false,
    //           ),
    //         ])));

    return Scaffold(
        backgroundColor: globalState.theme.background,
        appBar: const ICAppBar(
          title: "IronStore",
        ),
        //drawer: NavigationDrawer(),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(),
                          child: WrapperWidget(
                              child: Column(children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 20),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Row(children: [
                                  Expanded(
                                      child: GradientButton(
                                    color1: Colors.teal[500],
                                    color2: Colors.teal[200],
                                    onPressed: _openIronCoin,
                                    text: "IRONCOIN",
                                  ))
                                ])),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 20),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Row(children: [
                                  Expanded(
                                      child: GradientButton(
                                    color1: Colors.green,
                                    color2: Colors.green[200],
                                    text: "PRIVACY+",
                                    onPressed: _openPrivacyPlus,
                                  ))
                                ])),
                          ])))))
            ])));
  }

  _openIronCoin() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IronStoreIronCoin(),
        ));
  }

  _openPrivacyPlus() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IronStorePrivacyPlus(
            fromFurnaceManager: false,
          ),
        ));
  }
}
