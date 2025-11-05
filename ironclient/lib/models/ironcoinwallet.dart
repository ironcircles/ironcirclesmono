import 'dart:core';

class IronCoinWallet {
  double balance;
  // List<IronCoinTransaction> transactions;
  String? created;

  IronCoinWallet({
    this.balance = 0,
    // this.transactions = const [],
    this.created,
  });

  factory IronCoinWallet.fromJson(Map<String, dynamic> jsonMap) =>
      IronCoinWallet(
        balance: jsonMap['balance'].toDouble(),
        // transactions: jsonMap['transactions'] == null
        //     ? []
        //     : IronCoinTransactionCollection.fromJSON(jsonMap, 'transactions')
        //         .transactions,
        created: jsonMap['created'],
      );

  // Map<String, dynamic> toJson() => {
  //       'balance': balance,
  //       'transactions': paymentType,
  //       'created': created,
  //     };
}
