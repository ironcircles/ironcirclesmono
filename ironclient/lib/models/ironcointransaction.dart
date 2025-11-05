import 'dart:core';

class IronCoinTransaction {
  int amount;
  String paymentType;
  String? created;

  IronCoinTransaction({
    required this.amount,
    required this.paymentType,
    required this.created,
  });

  factory IronCoinTransaction.fromJson(Map<String, dynamic> jsonMap) =>
      IronCoinTransaction(
        amount: jsonMap['amount'],
        paymentType: jsonMap['paymentType'],
        created: jsonMap['created'],
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'paymentType': paymentType,
        'created': created,
      };
}

class IronCoinTransactionCollection {
  final List<IronCoinTransaction> transactions;

  IronCoinTransactionCollection.fromJSON(Map<String, dynamic> json, String key)
      : transactions = (json[key] as List)
            .map((json) => IronCoinTransaction.fromJson(json))
            .toList();
}
