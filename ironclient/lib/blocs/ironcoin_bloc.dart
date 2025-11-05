import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ironcointransaction.dart';
import 'package:ironcirclesapp/models/purchase.dart';
import 'package:ironcirclesapp/models/stablediffusionpricing.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/services/cache/table_purchase.dart';
import 'package:ironcirclesapp/services/ironcoin_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class IronCoinBloc {
  final IronCoinService _ironCoinService = IronCoinService();

  // final ironCurrency = PublishSubject<List<dynamic>>();
  // Stream<List<dynamic>> get ironCurrencyStream => ironCurrency.stream;

  final recentCoinPayment = PublishSubject<IronCoinTransaction>();
  Stream<IronCoinTransaction> get recentCoinPaymentStream =>
      recentCoinPayment.stream;

  final recentCoinRefund = PublishSubject<IronCoinTransaction>();
  Stream<IronCoinTransaction> get recentCoinRefundStream =>
      recentCoinRefund.stream;

  final coinLedger = PublishSubject<List<IronCoinTransaction>>();
  Stream<List<IronCoinTransaction>> get coinLedgerStream => coinLedger.stream;

  static final _productDelivered = PublishSubject<Purchase>();
  static Stream<Purchase> get productDelivered => _productDelivered.stream;

  static final _purchaseComplete = PublishSubject<Purchase>();
  static Stream<Purchase> get purchaseComplete => _purchaseComplete.stream;

  static final _purchaseCanceled = PublishSubject<bool>();
  static Stream<bool> get purchaseCanceled => _purchaseCanceled.stream;

  static final _ironCoinFetched = PublishSubject<bool>();
  static Stream<bool> get ironCoinFetched => _ironCoinFetched.stream;

  ///get prices/default values
  requestCurrency() async {
    try {
      StableDiffusionPricing stableDiffusionPricing =
          await _ironCoinService.getCurrency();
      globalState.stableDiffusionPricing = stableDiffusionPricing;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  ///requesting image generation
  coinPaymentProcess(int cost, String paymentType,
      {StableDiffusionPrompt? prompt}) async {
    try {
      IronCoinTransaction? payment = await _ironCoinService.processCoinPayment(
          globalState.userFurnace!, cost, paymentType,
          prompt: prompt);
      recentCoinPayment.sink.add(payment!);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      recentCoinPayment.sink.addError(error);
    }
  }

  ///when image gen fails
  coinPaymentRefund(int cost, String paymentType) async {
    try {
      IronCoinTransaction? payment = await _ironCoinService.processCoinRefund(
          globalState.userFurnace!, cost, paymentType);
      if (payment != null) recentCoinRefund.sink.add(payment);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      recentCoinRefund.sink.addError(error);
    }
  }

  ///requesting coin ledger
  fetchLedger() async {
    try {
      List<IronCoinTransaction>? payments =
          await _ironCoinService.fetchLedger(globalState.userFurnace!);
      coinLedger.sink.add(payments ?? []);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      coinLedger.sink.addError(error);
    }
  }

  ///requesting your ironcoins
  fetchCoins() async {
    try {
      bool fetched =
          await _ironCoinService.fetchCoins(globalState.userFurnace!);
      _ironCoinFetched.sink.add(fetched);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
    }
  }

  ///give coins from your account to another user
  giveCoins(User recipient, int coins) async {
    try {
      IronCoinTransaction? payment = await _ironCoinService.giveCoins(
          globalState.userFurnace!, recipient, coins);
      if (payment != null) recentCoinPayment.sink.add(payment);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      recentCoinPayment.sink.addError(error);
    }
  }

  /// called from subscriptions bloc
  static Future<void> handleUpdatedPurchase(
      PurchaseDetails purchaseDetails) async {
    Purchase? purchase = Purchase.blank();
    try {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('handleUpdatedPurchase PENDING');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        if (Platform.isIOS) {
          globalState.inAppPurchase.completePurchase(purchaseDetails);
        }

        _purchaseCanceled.sink.add(true);
        debugPrint('handleUpdatedPurchase CANCELED');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (Platform.isIOS) {
          cancelPendingiOS();
        }
        _purchaseCanceled.addError(purchaseDetails.error!);
        // _purchaseCanceled.sink.add(true);
        debugPrint('handleUpdatedPurchase ERROR');
      } else {
        debugPrint('Trying to purchase');

        debugPrint('handleUpdatedPurchase ${purchaseDetails.status}');
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          purchase = await prepPurchaseForVerificationAndDelivery(
              globalState.userFurnace!, purchaseDetails);

          if (purchase == null) {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (purchaseDetails.pendingCompletePurchase &&
            purchase.status == PurchaseObjectStatus.PURCHASED) {
          await globalState.inAppPurchase.completePurchase(purchaseDetails);

          TablePurchase.delete(purchase);

          _purchaseComplete.sink.add(purchase);
        } else {
          if (purchaseDetails.error != null &&
              !purchaseDetails.error!.message
                  .contains('BillingResponse.itemAlreadyOwned')) {
            _purchaseComplete.sink.addError(purchase);
          } else {
            _purchaseCanceled.sink.add(true);
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      _purchaseComplete.sink.add(purchase!);
    }
  }

  static Future<Purchase?> prepPurchaseForVerificationAndDelivery(
      UserFurnace userFurnace, PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.productID == Purchases.getIronCoinProductID()) {
        String purchaseDetailsJson = '';

        if (purchaseDetails is GooglePlayPurchaseDetails) {
          PurchaseWrapper billingClientPurchase =
              (purchaseDetails as GooglePlayPurchaseDetails)
                  .billingClientPurchase;
          purchaseDetailsJson = billingClientPurchase.originalJson;
        } else if (purchaseDetails is AppStorePurchaseDetails) {
          SKPaymentTransactionWrapper skProduct =
              (purchaseDetails as AppStorePurchaseDetails).skPaymentTransaction;
          purchaseDetailsJson = json.encode(skProduct.toFinishMap());
        }

        int firstIndex = purchaseDetailsJson.indexOf('quantity');
        int lastIndex = purchaseDetailsJson.indexOf('acknowledged');
        String quantity =
            purchaseDetailsJson.substring(firstIndex + 10, lastIndex - 2);

        Purchase? purchase = Purchase(
            seed: const Uuid().v4(),
            id: '',
            quantity: int.parse(quantity),
            purchaseDetailsJson: purchaseDetailsJson,
            userID: userFurnace.userid!,
            type: Purchases.getIronCoinProductID(),
            transactionDate: DateTime.fromMillisecondsSinceEpoch(
                int.parse(purchaseDetails.transactionDate!)),
            verificationLocal:
                purchaseDetails.verificationData.localVerificationData,
            verificationServer:
                purchaseDetails.verificationData.serverVerificationData,
            verificationSource: purchaseDetails.verificationData.source,
            status: PurchaseObjectStatus.PENDING,
            purchaseID: purchaseDetails.purchaseID!);

        purchase = await verifyAndDeliverPurchaseProduct(purchase);
        return purchase;
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
    return null;
  }

  static Future<Purchase?> verifyAndDeliverPurchaseProduct(
      Purchase purchase) async {
    try {
      ///cache locally
      TablePurchase.upsert(purchase);

      purchase =
          await IronCoinService.purchase(globalState.userFurnace!, purchase);

      _purchaseComplete.sink.add(purchase);
      return purchase;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
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

  static Future<Purchase?> reverifyAndDeliverProduct(Purchase purchase) async {
    try {
      ///cache locally
      TablePurchase.upsert(purchase);

      await IronCoinService.purchase(globalState.userFurnace!, purchase);

      _productDelivered.sink.add(purchase);

      return purchase;
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      rethrow;
    }
  }

  static void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    _purchaseComplete.sink.addError(Purchase.blank());
  }

  static checkPendingPurchases() async {
    try {
      List<Purchase> purchases = await TablePurchase.readPendingForUser(
          globalState.userFurnace!.userid!);

      for (Purchase purchase in purchases) {
        //print(purchase);

        ///TODO Verifiy it is not more than 4 days old
        if (purchase.verificationServer.isNotEmpty) {
          Purchase? validated = await reverifyAndDeliverProduct(purchase);

          if (validated != null) {
            Map<String, dynamic> map =
                jsonDecode(validated.purchaseDetailsJson);

            map['isAutoRenewing'] = true;

            //PurchaseWrapper purchaseWrapper = PurchaseWrapper.fromJson(map);
            PurchaseWrapper purchaseWrapper = (map as GooglePlayPurchaseDetails).billingClientPurchase;

            //debugPrint('break');

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

            //validated.status = PurchaseObjectStatus.PURCHASED;
            await TablePurchase.delete(purchase);

            _purchaseComplete.sink.add(purchase);
          }
        }
      }
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      throw (error);
    }
  }

  dispose() async {
    await recentCoinPayment.drain();
    recentCoinPayment.close();

    await _purchaseComplete.drain();
    _purchaseComplete.close();

    await _productDelivered.drain();
    _productDelivered.close();

    await _ironCoinFetched.drain();
    _ironCoinFetched.close();

    await _purchaseCanceled.drain();
    _purchaseCanceled.close();
  }
}
