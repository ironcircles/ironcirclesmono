import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:ironcirclesapp/blocs/subscriptions_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

///
///
///
///THIS CLASS IS NOT USED OTHER THAN FOR REFERENCE
///
///

// Auto-consume must be true on iOS.
// To try without auto-consume on another platform, change `true` to `false` here.
final bool _kAutoConsume = Platform.isIOS || true;
const String _kPrivacyPlusID = 'privacy_plus';

const List<String> _kProductIds = <String>[
  _kPrivacyPlusID,
];

class PrivacyPlusSubscriptionDONOTUSE extends StatefulWidget {


  const PrivacyPlusSubscriptionDONOTUSE();

  @override
  State<PrivacyPlusSubscriptionDONOTUSE> createState() =>
      _PrivacyPlusSubscriptionState();
}

class _PrivacyPlusSubscriptionState extends State<PrivacyPlusSubscriptionDONOTUSE> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  @override
  void initState() {
    SubscriptionsBloc.productDelivered.listen((purchaseDetails) {
      if (mounted) {
        setState(() {
          //_purchases.add(purchaseDetails);
          _purchasePending = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2, true);
      debugPrint("error $err");
    }, cancelOnError: false);

    SubscriptionsBloc.errorOccurred.listen((iAP) {
      if (mounted) {
        setState(() {
          _purchasePending = false;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  true);
      debugPrint("error $err");
    }, cancelOnError: false);

    SubscriptionsBloc.purchaseComplete.listen((subscription) {
      //if (mounted)
      Navigator.pop(context, subscription);
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 1);
      debugPrint("error $err");

      Navigator.pop(context, null);
    }, cancelOnError: false);

    initStoreInfo();
    super.initState();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await globalState.inAppPurchase.isAvailable();
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
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      //_consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
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
    const _header = Column(
      children: [
        Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                    child: ICText(
                  'Subscribe to Privacy+ for \$1.99 per month.\n\nCancel at anytime.',
                  fontSize: 16,
                ))
              ],
            ))
      ],
    );

    final List<Widget> stack = <Widget>[];
    if (_queryProductError == null) {
      stack.add(
        ListView(
          children: <Widget>[
            _header,
            // _buildConnectionCheckTile(),
            _buildProductList(),
            //_buildConsumableBox(),
            //_buildRestoreButton(),
          ],
        ),
      );
    } else {
      stack.add(Center(
        child: Text(_queryProductError!),
      ));
    }
    if (_purchasePending) {
      stack.add(
        Stack(
          children: <Widget>[
            const Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.grey),
            ),
            Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      globalState.theme.button)
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: globalState.theme.background,
      appBar: const ICAppBar(
        title: 'Privacy+',
      ),
      body: Stack(
        children: stack,
      ),
    );
  }

  Card _buildProductList() {
    if (_loading) {
      return Card(
          surfaceTintColor: Colors.transparent,
          color: globalState.theme.card,
          child: ListTile(
              leading: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      globalState.theme.button)
              ), title: const Text('loading...')));
    }
    if (!_isAvailable) {
      return const Card();
    }
    //ListTile productHeader = ListTile(title: ICText(''));
    final List<ListTile> productList = <ListTile>[];
    if (_notFoundIds.isNotEmpty) {
      productList.add(ListTile(
          title: Text('[${_notFoundIds.join(", ")}] not found',
              style: TextStyle(color: ThemeData.light().colorScheme.error)),
          subtitle: const Text('Subscription not found')));
    }

    // This loading previous purchases code is just a demo. Please do not use this as it is.
    // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
    // We recommend that you use your own server to verify the purchase data.
    final Map<String, PurchaseDetails> purchases =
        Map<String, PurchaseDetails>.fromEntries(
            _purchases.map((PurchaseDetails purchase) {
      if (purchase.pendingCompletePurchase) {
        //globalState.inAppPurchase.completePurchase(purchase);
        debugPrint('break');
      }
      return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
    }));
    productList.addAll(_products.map(
      (ProductDetails productDetails) {
        final PurchaseDetails? previousPurchase = purchases[productDetails.id];
        return ListTile(
          title: Text(
            productDetails.title,
          ),
          subtitle: Text(
            productDetails.description,
          ),
          trailing: previousPurchase != null
              ? const IconButton(
                  onPressed: null, //confirmPriceChange(context),
                  icon: Icon(Icons.upgrade))
              : TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    late PurchaseParam purchaseParam;

                    if (Platform.isAndroid) {
                      // NOTE: If you are making a subscription purchase/upgrade/downgrade, we recommend you to
                      // verify the latest status of you your subscription by using server side receipt validation
                      // and update the UI accordingly. The subscription purchase status shown
                      // inside the app may not be accurate.
                      final GooglePlayPurchaseDetails? oldSubscription =
                          SubscriptionsBloc.getOldSubscription(
                              productDetails, purchases);

                      purchaseParam = GooglePlayPurchaseParam(
                          productDetails: productDetails,
                          changeSubscriptionParam: (oldSubscription != null)
                              ? ChangeSubscriptionParam(
                                  oldPurchaseDetails: oldSubscription,
                                  replacementMode:
                                      ReplacementMode.withTimeProration, //.immediateWithTimeProration,
                                )
                              : null);
                    } else {
                      purchaseParam = PurchaseParam(
                        productDetails: productDetails,
                      );
                    }

                    globalState.inAppPurchase
                        .buyNonConsumable(purchaseParam: purchaseParam);
                  },
                  child: Text(productDetails.price),
                ),
        );
      },
    ));

    return Card(child: Column(children: productList));
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

/*
  Future<void> confirmPriceChange(BuildContext context) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper priceChangeConfirmationResult =
          await androidAddition.launchPriceChangeConfirmationFlow(
        sku: 'purchaseId',
      );
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Price change accepted'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            priceChangeConfirmationResult.debugMessage ??
                'Price change failed with code ${priceChangeConfirmationResult.responseCode}',
          ),
        ));
      }
    }
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }*/

}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
