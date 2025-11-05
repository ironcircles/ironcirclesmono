import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/subscription_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class SubscriptionsBloc {
  static final _productDelivered = PublishSubject<Subscription>();
  static Stream<Subscription> get productDelivered => _productDelivered.stream;

  static final _purchaseComplete = PublishSubject<Subscription>();
  static Stream<Subscription> get purchaseComplete => _purchaseComplete.stream;

  static final _purchaseCanceled = PublishSubject<bool>();
  static Stream<bool> get purchaseCanceled => _purchaseCanceled.stream;

  static final _errorOccurred = PublishSubject<IAPError>();
  static Stream<IAPError> get errorOccurred => _errorOccurred.stream;

  static final _subscriptionCanceled = PublishSubject<bool>();
  static Stream<bool> get subscriptionCanceled => _subscriptionCanceled.stream;

  /*
  static Future<bool> subscriptionStatus(
  String sku,
  [Duration duration = const Duration(days: 30),
  Duration grace = const Duration(days: 0)]) async {
    if (Platform.isIOS) {
      var history = await FlutterInappPurchase.getPurchaseHistory();

      for (var purchase in history) {
        Duration difference =
        DateTime.now().difference(purchase.transactionDate);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }
      return false;
    } else if (Platform.isAndroid) {
      var purchases = await FlutterInappPurchase.getAvailablePurchases();

      for (var purchase in purchases) {
        if (purchase.productId == sku) return true;
      }
      return false;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }
}
   */

  /*
  class _SubscriptionState extends State<Subscription> {
  bool userSubscribed;
  _SubscriptionState() {
  SubcsriptionStatus.subscriptionStatus(iapId, const Duration(days: 30), const
  Duration(days: 0)).then((val) => setState(() {
  userSubscribed = val;
   }));
   }
}
   */

  static Future<void> listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {

    debugPrint('listenToPurchaseUpdated FIRED OFF');

    ///don't process anythign in the queue until the user has been authenticated
    ///this will be called again in authentication_bloc
    if (globalState.isDesktop() || globalState.userFurnace == null ||
        globalState.userFurnace!.userid == null) {
      globalState.subscriptionQueue = purchaseDetailsList;
      return;
    }

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {

      if (purchaseDetails.productID == 'ironcoins') {
        await IronCoinBloc.handleUpdatedPurchase(purchaseDetails);

      } else {
        Subscription? subscription = Subscription.blank();

        try {
          if (purchaseDetails.status == PurchaseStatus.pending) {
            debugPrint('listenToPurchaseUpdated PENDING');
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            if (Platform.isIOS) {
              globalState.inAppPurchase.completePurchase(purchaseDetails);
            }

            _purchaseCanceled.sink.add(true);
            debugPrint('listenToPurchaseUpdated CANCELED');
          } else if (purchaseDetails.status == PurchaseStatus.error) {
            if (Platform.isIOS) {
              //globalState.inAppPurchase.completePurchase(purchaseDetails);
              cancelPendingiOS();
            }
            handleError(purchaseDetails.error!);
            _purchaseCanceled.sink.add(true);
            debugPrint('listenToPurchaseUpdated ERROR');
          } else {
            ///On iOS, a bunch of already processed purchases are included.
            ///Also check Subscriptions to see if it has already been processed
            debugPrint('Trying to purchase');
            List<Subscription> subscriptions =
            await TableSubscription.readForUser(
                globalState.userFurnace!.userid!);

            int index = subscriptions.indexWhere(
                    (element) => element.purchaseID == purchaseDetails.purchaseID);

            if (index != -1) {
              Subscription subscription = subscriptions[index];

              if (subscription.status == SubscriptionStatus.ACTIVE ||
                  subscription.status == SubscriptionStatus.CANCELED) {
                continue;
              }
            }

            ///If there is already an active subscription, ignore others and attempt to cancel
            index = subscriptions.indexWhere(
                    (element) => element.status == SubscriptionStatus.ACTIVE);

            if (index != -1){
              cancelPendingiOS();
              continue;

            }


            debugPrint('listenToPurchaseUpdated ${purchaseDetails.status}');
            if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
              subscription = await prepForVerificationAndDelivery(
                  globalState.userFurnace!, purchaseDetails);

              if (subscription == null) {
                _handleInvalidPurchase(purchaseDetails);
                return;
              }
            }
            if (purchaseDetails.pendingCompletePurchase &&
                subscription.status == SubscriptionStatus.ACTIVE) {
              await globalState.inAppPurchase.completePurchase(purchaseDetails);

              globalState.subscription = subscription;

              _purchaseComplete.sink.add(subscription);
            } else {
              if (purchaseDetails.error != null &&
                  !purchaseDetails.error!.message
                      .contains('BillingResponse.itemAlreadyOwned')) {
                globalState.subscription = subscription;
                _purchaseComplete.sink.addError(subscription);
              } else {
                _purchaseCanceled.sink.add(true);
              }
            }
          }
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          _purchaseComplete.sink.add(subscription!);
        }

      }
    }
  }

  static void handleError(IAPError error) {
    _errorOccurred.sink.add(error);
  }

  static void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    globalState.subscription = Subscription.blank();
    _purchaseComplete.sink.addError(globalState.subscription!);
  }

  static Future<Subscription?> prepForVerificationAndDelivery(
      UserFurnace userFurnace, PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.productID == Subscriptions.getSubscriptionProductID()) {
        String purchaseDetailsJson = '';

        if (purchaseDetails is GooglePlayPurchaseDetails) {
          PurchaseWrapper billingClientPurchase =
              (purchaseDetails as GooglePlayPurchaseDetails)
                  .billingClientPurchase;
          purchaseDetailsJson = billingClientPurchase.originalJson;
        } else if (purchaseDetails is AppStorePurchaseDetails) {
          SKPaymentTransactionWrapper skProduct =
              (purchaseDetails as AppStorePurchaseDetails).skPaymentTransaction;
          //purchaseDetails

          purchaseDetailsJson = json.encode(skProduct.toFinishMap());
        }

        Subscription? subscription = Subscription(
            seed: const Uuid().v4(),
            id: '',
            purchaseDetailsJson: purchaseDetailsJson,
            userID: userFurnace.userid!,
            type:  Subscriptions.getSubscriptionProductID(),
            transactionDate: DateTime.fromMillisecondsSinceEpoch(
                int.parse(purchaseDetails.transactionDate!)),
            verificationLocal:
                purchaseDetails.verificationData.localVerificationData,
            verificationServer:
                purchaseDetails.verificationData.serverVerificationData,
            verificationSource: purchaseDetails.verificationData.source,
            status: SubscriptionStatus.PENDING,
            purchaseID: purchaseDetails.purchaseID!);

        subscription = await verifyAndDeliverProduct(userFurnace, subscription);
        return subscription;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
    return null;
  }

  static Future<Subscription?> verifyAndDeliverProduct(
      UserFurnace userFurnace, Subscription subscription) async {
    try {
      ///cache locally
      TableSubscription.upsert(subscription);
      globalState.subscription = subscription;

      //throw("network crashed");

      subscription =
          await SubscriptionService.subscribe(userFurnace, subscription);

      _productDelivered.sink.add(subscription);

      return subscription;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }

    return null;
  }

  static Future<Subscription?> reverifyAndDeliverProduct(
      UserFurnace userFurnace, Subscription subscription) async {
    try {
      ///cache locally
      TableSubscription.upsert(subscription);
      globalState.subscription = subscription;

      await SubscriptionService.subscribe(userFurnace, subscription);

      _productDelivered.sink.add(subscription);

      return subscription;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }

    return null;
  }

  static GooglePlayPurchaseDetails? getOldSubscription(
      ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    // This is just to demonstrate a subscription upgrade or downgrade.
    // This method assumes that you have only 2 subscriptions under a group, 'subscription_silver' & 'subscription_gold'.
    // The 'subscription_silver' subscription can be upgraded to 'subscription_gold' and
    // the 'subscription_gold' subscription can be downgraded to 'subscription_silver'.
    // Please remember to replace the logic of finding the old subscription Id as per your app.
    // The old subscription is only required on Android since Apple handles this internally
    // by using the subscription group feature in iTunesConnect.
    GooglePlayPurchaseDetails? oldSubscription;
    /*if (productDetails.id == _kSilverSubscriptionId &&
        purchases[_kGoldSubscriptionId] != null) {
      oldSubscription =
      purchases[_kGoldSubscriptionId]! as GooglePlayPurchaseDetails;
    } else if (productDetails.id == _kGoldSubscriptionId &&
        purchases[_kSilverSubscriptionId] != null) {
      oldSubscription =
      purchases[_kSilverSubscriptionId]! as GooglePlayPurchaseDetails;
    }

     */
    if (purchases[ Subscriptions.getSubscriptionProductID()] != null)
      oldSubscription =
          purchases[ Subscriptions.getSubscriptionProductID()]! as GooglePlayPurchaseDetails;

    return oldSubscription;
  }

  static liveActivateSubscription() {}

  static checkPendingPurchases() async {
    try {

      if (globalState.isDesktop()){
        return;
      }

      List<Subscription> subscriptions =
          await TableSubscription.readPendingForUser(
              globalState.userFurnace!.userid!);

      for (Subscription subscription in subscriptions) {
        //print(subscription);

        ///TODO Verify it is not more than 4 days old
        if (subscription.verificationServer.isNotEmpty) {
          Subscription? validated = await reverifyAndDeliverProduct(
              globalState.userFurnace!, subscription);

          if (validated != null) {
            Map<String, dynamic> map =
                jsonDecode(validated.purchaseDetailsJson);

            map['isAutoRenewing'] = true;

            //PurchaseWrapper purchaseWrapper = PurchaseWrapper.fromJson(map);
            PurchaseWrapper purchaseWrapper = (map as GooglePlayPurchaseDetails).billingClientPurchase;

            debugPrint('break');

            if (Platform.isAndroid) {
              GooglePlayPurchaseDetails googlePlayPurchaseDetails =
                  GooglePlayPurchaseDetails(
                      billingClientPurchase: purchaseWrapper,
                      productID: validated.type,
                      verificationData: PurchaseVerificationData(
                          localVerificationData: validated.verificationLocal,
                          serverVerificationData: validated.verificationServer,
                          source: validated.verificationSource),
                      transactionDate: validated
                          .transactionDate.millisecondsSinceEpoch
                          .toString(),
                      status: PurchaseStatus.purchased);

              await globalState.inAppPurchase
                  .completePurchase(googlePlayPurchaseDetails);
            } else if (Platform.isIOS) {
              var paymentWrapper = SKPaymentQueueWrapper();
              var transactions = await paymentWrapper.transactions();
              transactions.forEach((transaction) async {
                if (transaction.transactionState ==
                    SKPaymentTransactionStateWrapper.purchasing)
                  await paymentWrapper.finishTransaction(transaction);
              });
            }

            validated.status = SubscriptionStatus.ACTIVE;
            await TableSubscription.upsert(subscription);

            globalState.subscription = validated;
            _purchaseComplete.sink.add(subscription);
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      throw (error);
    }
  }

  static cancelPendingiOS() async {
    try {
      if (Platform.isIOS) {
        var paymentWrapper = SKPaymentQueueWrapper();
        var transactions = await paymentWrapper.transactions();
        transactions.forEach((transaction) async {
          if (transaction.transactionState ==
                  SKPaymentTransactionStateWrapper.purchasing ||
              transaction.transactionState ==
                  SKPaymentTransactionStateWrapper.purchased)
            await paymentWrapper.finishTransaction(transaction);
        });
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      throw (error);
    }
  }

  static cancel() async {
    try {
      late Subscription subscription;

      /*if (Platform.isIOS) {
        var paymentWrapper = SKPaymentQueueWrapper();
        var transactions = await paymentWrapper.transactions();
        transactions.forEach((transaction) async {
          if (transaction.transactionState ==
              SKPaymentTransactionStateWrapper.purchasing)
            await paymentWrapper.finishTransaction(transaction);
        });
      }*/

      ///set the subscription to canceled

      //load the most recent Subscription
      subscription =
          await TableSubscription.readLatestActive(globalState.user.id!);

      if (subscription.purchaseID.isEmpty) {
        ///This should only happen for the 3 early adopters
        subscription = Subscription(
            id: '',
            seed: const Uuid().v4(),
            purchaseDetailsJson: '',
            userID: globalState.user.id!,
            type:  Subscriptions.getSubscriptionProductID(),
            transactionDate: DateTime.now().toLocal(),
            verificationLocal: '',
            verificationServer: '',
            verificationSource: '',
            status: SubscriptionStatus.CANCELED,
            purchaseID: '');
      }

      ///cancel serverside
      bool canceled = await SubscriptionService.cancel(globalState.userFurnace!, subscription);
      _subscriptionCanceled.sink.add(canceled);

    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      throw (error);
    }
  }

  dispose() async {
    await _purchaseComplete.drain();
    _purchaseComplete.close();

    await _productDelivered.drain();
    _productDelivered.close();

    await _errorOccurred.drain();
    _errorOccurred.close();

    await _purchaseCanceled.drain();
    _purchaseCanceled.close();

    await _subscriptionCanceled.drain();
    _subscriptionCanceled.close();
  }
}
