import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/subscriptions_bloc.dart';
import 'package:ironcirclesapp/blocs/user_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/payment/privacyplus_subscription.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';
import 'package:url_launcher/url_launcher.dart';

class IronStorePrivacyPlus extends StatefulWidget {
  final bool fromFurnaceManager;

  const IronStorePrivacyPlus({Key? key, required this.fromFurnaceManager})
      : super(key: key);

  @override
  _LocalState createState() => _LocalState();
}

List<String> _kProductIds = <String>[
  Subscriptions.getSubscriptionProductID(),
];

const String APPLE_EULA_URL =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

class _LocalState extends State<IronStorePrivacyPlus> {
  final UserBloc _userBloc = UserBloc();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  UserFurnace? _userFurnace;

  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  //bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _userFurnace = globalState.userFurnace;

    _username.text = _userFurnace!.username!;

    _userBloc.usernameUpdated.listen((success) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(context,
            AppLocalizations.of(context)!.usernameUpdated, "", 1, false);
      }
    }, onError: (err) {
      //Navigator.pushReplacementNamed(context, '/login');
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);

      debugPrint("error $err");
    }, cancelOnError: false);

    _userBloc.avatarChanged.listen((success) {
      if (mounted) {
        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.avatarUpdated, "", 1, false);
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    SubscriptionsBloc.subscriptionCanceled.listen((success) {
      if (success == true && mounted) {
        setState(() {});
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    SubscriptionsBloc.purchaseCanceled.listen((success) {
      _purchasePending = false;
      if (mounted) setState(() {});
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, cancelOnError: false);

    SubscriptionsBloc.productDelivered.listen((purchaseDetails) {
      if (mounted) {
        setState(() {
          _purchasePending = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, cancelOnError: false);

    SubscriptionsBloc.errorOccurred.listen((iAP) {
      if (mounted) {
        setState(() {
          _purchasePending = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      _purchasePending = false;
      if (mounted) setState(() {});
    }, cancelOnError: false);

    SubscriptionsBloc.purchaseComplete.listen((subscription) {
      globalState.subscription = subscription;
      _userFurnace!.accountType = AccountType.PREMIUM;
      _purchasePending = false;
      if (mounted) setState(() {});
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 1);
      debugPrint("error $err");
      _purchasePending = false;
      if (mounted) setState(() {});
      //Navigator.pop(context, null);
    }, cancelOnError: false);

    initStoreInfo();

    super.initState();
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          globalState.inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    //globalState.subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tosRow = Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        const Spacer(),
        TextButton(
            child: ICText(
              Platform.isIOS
                  ? AppLocalizations.of(context)!
                      .eula //'License Agreement (EULA)'
                  : AppLocalizations.of(context)!.termsOfService,
              color: globalState.theme.buttonIcon,
            ),
            onPressed: () {
              _termsOfService();
            }),
        const Spacer(),
      ]),
    );

    final privacyRow = Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
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
    );

    final makeBody = Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: WrapperWidget(child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                              child: Text(
                                  globalState.userSetting.accountType ==
                                          AccountType.PREMIUM
                                      ? AppLocalizations.of(context)!.activated
                                      : AppLocalizations.of(context)!
                                          .subscribeNow,
                                  textScaler: const TextScaler.linear(1.0),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: globalState.theme.labelText,
                                      fontSize:
                                          globalState.userSetting.fontSize +
                                              5)))
                        ],
                      )),
                  _loading
                      ? spinkit
                      : _isAvailable
                          ? globalState.userSetting.accountType ==
                                  AccountType.FREE
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10, top: 4, bottom: 0),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                            child: GradientButton(
                                          height: 45,
                                          text: (globalState.subscription !=
                                                      null &&
                                                  globalState.subscription!
                                                          .status ==
                                                      SubscriptionStatus
                                                          .PENDING)
                                              ? AppLocalizations.of(context)!
                                                  .pending
                                              : '\$1.99/Month',
                                          onPressed: () => _subscribe(),
                                        ))
                                      ]),
                                )
                              : Container()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, top: 4, bottom: 0),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                        child: ICText(Platform.isIOS
                                            ? 'AppStore'
                                            : 'PlayStore ${AppLocalizations.of(context)!.isCurrentlyUnavailable}'))
                                  ]),
                            ),
                  tosRow,
                  privacyRow,
                  _premiumLineItem(
                      AppLocalizations.of(context)!.ironCoinPerMonth),
                  _premiumLineItem(
                      AppLocalizations.of(context)!.joinUnlimitedNetworks),
                  (globalState.userSetting.allowHidden &&
                          !globalState.userSetting.minor)
                      ? _premiumLineItem(
                          AppLocalizations.of(context)!.hideUnlimitedChats)
                      : Container(),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .reserveUsernameAcrossAllNetworks),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .remoteWipeAppIfDeviceLostOrStolen),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .shredImageVideosFilesOnDeletion),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .streamVideosPlayWithoutDownloading),
                  _premiumLineItem(
                      AppLocalizations.of(context)!.unlimitedUploadFileSize),
                  //_premiumLineItem('Generate chat history for user'),
                  //_premiumLineItem('Delete all content sent to a specific user'),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .bringYourOwnStorageWasabiS3),
                  //_premiumLineItem('Create owner controlled Circles'),
                  //_premiumLineItem('Create temporary Circles'),
                  //_premiumLineItem('Import data from Facebook into a Circle'),
                  _premiumLineItem(
                      AppLocalizations.of(context)!.privacyBadgeOnAvatar),
                  _premiumLineItem(AppLocalizations.of(context)!
                      .higherPriorityOnFeatureRequests),
                  //_premiumLineItem('Premium support'),

                  Row(children: [
                    globalState.user.role == Role.IC_ADMIN
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 25, bottom: 0, left: 10),
                            child: TextButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      globalState.theme.buttonDisabled)),
                              onPressed: () => _forceCancel(),
                              child: Text(
                                'TEST UNSUBSCRIBE',
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: globalState.userSetting.fontSize),
                              ),
                            ))
                        : Container(),
                    const Spacer(),
                    globalState.userSetting.accountType == AccountType.PREMIUM
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 25, bottom: 0, left: 10),
                            child: TextButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      globalState.theme.buttonDisabled)),
                              onPressed: () => _cancel(),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .unsubscribe
                                    .toUpperCase(),
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: globalState.userSetting.fontSize),
                              ),
                            ))
                        : Container()
                  ])
                ]))),
      ),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: const ICAppBar(title: 'Privacy+'),
            body: Stack(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: makeBody,
                      ),
                      Container(
                        //  color: Colors.white,
                        padding: const EdgeInsets.all(0.0),
                        //child: makeBottom,
                      ),
                    ],
                  )),
              _purchasePending ? spinkit : Container()
            ])));
  }

  Future<void> initStoreInfo() async {
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

  Widget _premiumLineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 4, left: 10, right: 5),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Expanded(
          child: Text(
            text,
            textScaler: const TextScaler.linear(1),
            style: TextStyle(
                color: globalState.theme.labelText,
                fontSize: globalState.userSetting.fontSize),
          ),
        ),
        (globalState.userSetting.accountType == AccountType.PREMIUM)
            ? Text(AppLocalizations.of(context)!.active.toUpperCase(),
                textScaler: const TextScaler.linear(1),
                style: TextStyle(
                    color: globalState.theme.buttonIcon,
                    fontSize: globalState.userSetting.fontSize))
            : Text(
                AppLocalizations.of(context)!.off.toUpperCase(),
                textScaler: const TextScaler.linear(1),
                style: TextStyle(
                    color: globalState.theme.buttonDisabled,
                    fontSize: globalState.userSetting.fontSize),
              ),
      ]),
    );
  }

  _cancel() async {
    try {
      //_subscribe();
      if (Platform.isIOS) {
        launchUrl(Uri.parse("https://apps.apple.com/account/subscriptions"),
            mode: LaunchMode.externalApplication);
      } else if (Platform.isAndroid) {
        SubscriptionsBloc.cancel();
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  _forceCancel() async {
    try {
      await SubscriptionsBloc.cancel();

      _userFurnace = globalState.userFurnace;

      if (mounted) {
        setState(() {});
      }
      //launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions?sku=privacy_plus&package=com.ironcircles.ironcirclesapp'), mode: LaunchMode.externalApplication);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, true);
    }
  }

  _retry() async {
    await SubscriptionsBloc.checkPendingPurchases();
  }

  /*_subscribe() async {
    try {
      //FormattedSnackBar.showSnackbarWithContext(context, 'coming soon!', "", 2);
      var subscription = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PrivacyPlusSubscription(
                    userFurnace: widget.userFurnace!,
                  )));

      if (subscription != null) {
        setState(() {
          globalState.subscription = subscription;
        });

        FormattedSnackBar.showSnackbarWithContext(context, 'subscribed', "", 2);
      } else {
        setState(() {});

        FormattedSnackBar.showSnackbarWithContext(context, 'pending', "", 2);
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2);
    }
  }

   */

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

  _subscribe() async {
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

    ///There is only one for now
    ProductDetails productDetails = _products.first;

    late PurchaseParam purchaseParam;

    final Map<String, PurchaseDetails> purchases =
        Map<String, PurchaseDetails>.fromEntries(
            _purchases.map((PurchaseDetails purchase) {
      if (purchase.pendingCompletePurchase) {
        //globalState.inAppPurchase.completePurchase(purchase);
        debugPrint('break');
      }
      return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
    }));

    if (Platform.isAndroid) {
      final GooglePlayPurchaseDetails? oldSubscription =
          SubscriptionsBloc.getOldSubscription(productDetails, purchases);

      purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          changeSubscriptionParam: (oldSubscription != null)
              ? ChangeSubscriptionParam(
                  oldPurchaseDetails: oldSubscription,
                  replacementMode: ReplacementMode.withTimeProration, //.immediateWithTimeProration,
                )
              : null);
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
    }

    try {
      await globalState.inAppPurchase
          .buyNonConsumable(purchaseParam: purchaseParam);
    } catch (err, trace) {
      await SubscriptionsBloc.cancelPendingiOS();
      debugPrint(err.toString());
      _purchasePending = false;

      if (mounted) setState(() {});
    }
  }
}
