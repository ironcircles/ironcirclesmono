import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/payment/coinledger.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_privacyplus.dart';
import 'package:ironcirclesapp/screens/payment/privacyplus_subscription.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';

class IronStoreIronCoin extends StatefulWidget {
  const IronStoreIronCoin({
    Key? key,
  }) : super(key: key);

  @override
  _LocalState createState() => _LocalState();
}

List<String> _kProductIds = <String>[
  Subscriptions.getSubscriptionProductID(),
  Purchases.getIronCoinProductID(),
];

class _LocalState extends State<IronStoreIronCoin> {
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _purchasePending = false;
  bool _isAvailable = false;
  IronCoinBloc _ironCoinBloc = IronCoinBloc();
  List<String> _notFoundIds = <String>[];
  String? _queryProductError;
  bool _loading = true;
  double coins = globalState.ironCoinWallet.balance;
  String price = "1.99";
  String description =
      "20,000 IronCoins that can be used for image generation and editing";

  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    IronCoinBloc.purchaseCanceled.listen((success) {
      debugPrint("purchaseCanceled");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, onError: (err) {
      debugPrint("error $err");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, cancelOnError: false);

    IronCoinBloc.ironCoinFetched.listen((fetched) {
      if (mounted) {
        setState(() {
          coins = globalState.ironCoinWallet.balance;
        });
      }
    }, onError: (err) {
      debugPrint("error $err");
    }, cancelOnError: false);

    IronCoinBloc.purchaseComplete.listen((purchase) {
      ///fetch wallet
      _ironCoinBloc.fetchCoins();
      debugPrint("purchaseComplete");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, onError: (err) {
      debugPrint("error $err");
      _purchasePending = false;
    }, cancelOnError: false);

    initStoreInfo();

    super.initState();

    _ironCoinBloc.fetchCoins();
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          globalState.inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    coins = globalState.ironCoinWallet.balance;

    final makePreviousBody = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 5),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Text(
                        'IronCoin',
                        textScaler:
                            TextScaler.linear(globalState.textFieldScaleFactor),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: globalState.theme.labelText),
                      ),
                    ]),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipOval(
                                child: Image.asset(
                              'assets/images/ironcoin.png',
                              height: 20,
                              width: 20,
                              fit: BoxFit.fitHeight,
                            )),
                            const Padding(padding: EdgeInsets.only(right: 3)),
                            Text(formatter.format(coins),
                                style: TextStyle(
                                    color: globalState.theme.buttonDisabled,
                                    fontSize: 14),
                                textScaler: const TextScaler.linear(1.0))
                          ]),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 0, right: 10, left: 10),
                        child: InkWell(
                            onTap: () {
                              _openCoinLedger();
                            },
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState
                                                  .theme.menuBackground,
                                              border: Border.all(
                                                  color: Colors.lightBlueAccent
                                                      .withOpacity(.1),
                                                  width: 2.0),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                                bottomLeft:
                                                    Radius.circular(12.0),
                                                bottomRight:
                                                    Radius.circular(12.0),
                                              )),
                                          padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 15,
                                              right: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  AppLocalizations.of(context)!
                                                      .viewLedger,
                                                  textScaler:
                                                      const TextScaler.linear(
                                                          1.0),
                                                  style: TextStyle(
                                                    fontSize: 16 -
                                                        globalState
                                                            .scaleDownTextFont,
                                                    color: globalState
                                                        .theme.labelText,
                                                  )),
                                              Icon(Icons.keyboard_arrow_right,
                                                  color: globalState
                                                      .theme.labelText,
                                                  size: 25.0),
                                            ],
                                          ))),
                                ]))),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: ICText(
                          '${AppLocalizations.of(context)!.purchase} IronCoin: ${AppLocalizations.of(context)!.ironCoinComingSoon}!',
                          color: globalState.theme.button,
                          fontSize: 20,
                        )),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 10,
                      ),
                    ),
                Row(
                  children: [Expanded(
                        child: ICText(AppLocalizations.of(context)!
                            .ironCoinComingSoonMessage))]),
                  ],
                )))));

    final makeBody = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 5),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Text(
                        'IronCoin ${AppLocalizations.of(context)!.balance.toLowerCase()}: ',
                        textScaler:
                            TextScaler.linear(globalState.textFieldScaleFactor),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: globalState.theme.labelText),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 10, top: 10, bottom: 10),
                          child: ClipOval(
                              child: Image.asset(
                            'assets/images/ironcoin.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.fitHeight,
                          ))),
                      const Padding(padding: EdgeInsets.only(right: 3)),
                      Text(formatter.format(coins),
                          style: TextStyle(
                              color: globalState.theme.buttonDisabled,
                              fontSize: 14),
                          textScaler: const TextScaler.linear(1.0))
                    ]),
                    Padding(
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 0, right: 10, left: 10),
                        child: InkWell(
                            onTap: () {
                              _openCoinLedger();
                            },
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: globalState
                                                  .theme.menuBackground,
                                              border: Border.all(
                                                  color: Colors.lightBlueAccent
                                                      .withOpacity(.1),
                                                  width: 2.0),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                                bottomLeft:
                                                    Radius.circular(12.0),
                                                bottomRight:
                                                    Radius.circular(12.0),
                                              )),
                                          padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 15,
                                              right: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  AppLocalizations.of(context)!
                                                      .viewLedger,
                                                  textScaler:
                                                      const TextScaler.linear(
                                                          1.0),
                                                  style: TextStyle(
                                                    fontSize: 16 -
                                                        globalState
                                                            .scaleDownTextFont,
                                                    color: globalState
                                                        .theme.labelText,
                                                  )),
                                              Icon(Icons.keyboard_arrow_right,
                                                  color: globalState
                                                      .theme.labelText,
                                                  size: 25.0),
                                            ],
                                          ))),
                                ]))),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                              child: ICText(
                            '${AppLocalizations.of(context)!.add} IronCoins',
                            color: globalState.theme.button,
                            fontSize: 20,
                          )),
                        ],
                      ),
                    ),

                    Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(children: [
                          Flexible(child: ICText(
                              // 'IronCoin allows you to generate or modify images using AI.\n\nFor $price, you get $description.'))
                              '$price ${AppLocalizations.of(context)!.willGetYou.toLowerCase()} $description.'))
                        ])),

                    Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(children: [
                          Flexible(
                              child: ICText(
                                  '${AppLocalizations.of(context)!.imageGenDefault} $price.'))
                        ])),

                    // Padding(
                    //     padding: const EdgeInsets.only(bottom: 20),
                    //     child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //         children: [
                    //           Row(children: [
                    //             ClipOval(
                    //                 child: Image.asset(
                    //               'assets/images/ironcoin.png',
                    //               height: 20,
                    //               width: 20,
                    //               fit: BoxFit.fitHeight,
                    //             )),
                    //             const Padding(padding: EdgeInsets.only(right: 3)),
                    //             // Text(formatter.format(globalState.ironCoinWallet.balance),
                    //             //     style: TextStyle(
                    //             //         color: globalState.theme.buttonDisabled,
                    //             //         fontSize: 14),
                    //             //     textScaler: const TextScaler.linear(1.0))
                    //             ICText("100,000"),
                    //
                    //             ///make this a variable from API
                    //           ]),
                    //           GradientButton(
                    //             text: "\$10.00",
                    //             width: 80,
                    //             height: 40,
                    //             onPressed: () => _purchase(),
                    //           ),
                    //         ])),

                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GradientButton(
                                text: AppLocalizations.of(context)!
                                    .buyNow
                                    .toUpperCase(),
                                width: 200,
                                height: 40,
                                onPressed: () => _purchase(),
                              ),
                            ])),

                    Padding(
                      padding: const EdgeInsets.only(
                          left: 0, right: 0, top: 0, bottom: 0),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Spacer(),
                            TextButton(
                                child: ICText(
                                  Platform.isIOS
                                      ? AppLocalizations.of(context)!
                                          .eula //'License Agreement (EULA)'
                                      : AppLocalizations.of(context)!
                                          .termsOfService,
                                  color: globalState.theme.buttonIcon,
                                ),
                                onPressed: () {
                                  _termsOfService();
                                }),
                            const Spacer(),
                          ]),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                          left: 0, right: 0, top: 0, bottom: 0),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Spacer(),
                            TextButton(
                                child: ICText(
                                  AppLocalizations.of(context)!.privacyPolicy,
                                  color: globalState.theme.buttonIcon,
                                ),
                                onPressed: () {
                                  _privacyPolicy();
                                }),
                            const Spacer(),
                          ]),
                    ),
                  ],
                )))));

    return SafeArea(
        child: Scaffold(
            appBar: const ICAppBar(title: 'IronCoin'),
            body: Padding(
                padding: const EdgeInsets.only(
                    top: 0, left: 25, right: 25, bottom: 5),
                child: Column(children: [
                  Expanded(
                      child: Platform.isAndroid ? makeBody : makePreviousBody)
                ]))));
  }

  Future<void> initStoreInfo() async {
    if (!Platform.isAndroid) {
      return;

      /// not supported yet
    }
    final bool isAvailable = await globalState.inAppPurchase.isAvailable();
    debugPrint(isAvailable.toString());
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _notFoundIds = <String>[];
        _purchasePending = false;
        _loading = false;
      });

      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          globalState.inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse = await globalState
        .inAppPurchase
        .queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      debugPrint(productDetailResponse.error!.message);

      if (mounted)
        setState(() {
          _queryProductError = productDetailResponse.error!.message;
          _isAvailable = isAvailable;
          _products = productDetailResponse.productDetails;
          _purchases = <PurchaseDetails>[];
          _notFoundIds = productDetailResponse.notFoundIDs;
          _purchasePending = false;
          _loading = false;
        });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      if (mounted)
        setState(() {
          _queryProductError = null;
          _isAvailable = isAvailable;
          _products = productDetailResponse.productDetails;
          _purchases = <PurchaseDetails>[];
          _notFoundIds = productDetailResponse.notFoundIDs;
          _purchasePending = false;
          _loading = false;
        });
      return;
    } else {
      ProductDetails details = productDetailResponse.productDetails
          .firstWhere((element) => element.id == "ironcoins");
      setState(() {
        price = details.price;
        description = details.description;
      });
    }

    //final List<String> consumables = await ConsumableStore.load();
    if (mounted)
      setState(() {
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _notFoundIds = productDetailResponse.notFoundIDs;
        //_consumables = consumables;
        _purchasePending = false;
        _loading = false;
      });
  }

  _openCoinLedger() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoinLedger(
            userFurnace: globalState.userFurnace!,
          ),
        ));
  }

  _purchase() async {
    if (_purchasePending) return;

    setState(() {
      _purchasePending = true;
    });

    if (_products.isEmpty) {
      setState(() {
        _purchasePending = false;
      });
      return;
    }

    ProductDetails productDetails =
        _products.singleWhere((element) => element.id == "ironcoins");

    late PurchaseParam purchaseParam;

    purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      await globalState.inAppPurchase
          .buyConsumable(purchaseParam: purchaseParam);
    } catch (err, trace) {
      await IronCoinBloc.cancelPendingiOS();
      debugPrint(err.toString());
      _purchasePending = false;

      if (mounted) setState(() {});
    }
  }

  _termsOfService() {
    if (Platform.isIOS) {
      LaunchURLs.openExternalBrowserUrl(context, APPLE_EULA_URL);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfService(
              readOnly: true,
            ),
          ));
    }
  }

  _privacyPolicy() {
    LaunchURLs.openExternalBrowserUrl(
        context, 'https://ironcircles.com/policies');
  }
}
