import 'package:ironcirclesapp/models/export_models.dart';
import 'package:uuid/uuid.dart';

class Purchase {
  String id;
  String userID;
  String type;
  DateTime transactionDate;
  String verificationLocal;
  String verificationServer;
  String verificationSource;
  int status;
  String purchaseID;
  String seed;
  int quantity;
  String purchaseDetailsJson;

  Purchase({
    required this.id,
    required this.userID,
    required this.type,
    required this.transactionDate,
    required this.verificationLocal,
    required this.verificationServer,
    required this.verificationSource,
    required this.status,
    required this.purchaseID,
    required this.seed,
    required this.quantity,
    required this.purchaseDetailsJson,
  });

  factory Purchase.blank() => Purchase(
    id: '',
    userID: '',
    seed: const Uuid().v4(),
    type: '',
    purchaseDetailsJson: '',
    transactionDate: DateTime.now(),
    verificationLocal: '',
    verificationServer: '',
    verificationSource: '',
    status: SubscriptionStatus.PENDING,
    quantity: 0,
    purchaseID: '');

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json["_id"],
    userID: json["user"],
    type: json["type"],
    seed: json["seed"],
    purchaseDetailsJson: json["purchaseDetailsJson"] ?? '',
    transactionDate: DateTime.parse(json["transactionDate"]).toLocal(),
    verificationLocal: json["verificationLocal"],
    verificationServer: json["verificationServer"],
    verificationSource: json["verificationSource"],
    purchaseID: json["purchaseID"],
    quantity: json["quantity"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "userID": userID,
    "type": type,
    "seed": seed,
    "purchaseDetailsJson": purchaseDetailsJson,
    "transactionDate": transactionDate.toUtc().toString(),
    "verificationLocal": verificationLocal,
    "verificationServer": verificationServer,
    "verificationSource": verificationSource,
    "status": status,
    "quantity": quantity,
    "purchaseID": purchaseID,
  };

  factory Purchase.fromJsonSQL(Map<String, dynamic> json) =>
    Purchase(
        id: json["id"] ?? '',
        userID: json["userID"],
        type: json["type"],
        purchaseDetailsJson: json["purchaseDetailsJson"] ?? '',
        seed: json["seed"],
        transactionDate:
          DateTime.fromMillisecondsSinceEpoch(json["transactionDate"]).toLocal(),
        verificationLocal: json["verificationLocal"],
        verificationServer: json["verificationServer"],
        verificationSource: json["verificationSource"],
        status: json["status"],
        quantity: json["quantity"],
        purchaseID: json["purchaseID"],
       );

  Map<String, dynamic> toJsonSQL() => {
    "id": id,
    "userID": userID,
    "type": type,
    "seed": seed,
    "purchaseDetailsJson": purchaseDetailsJson,
    "transactionDate": transactionDate.millisecondsSinceEpoch,
    "verificationLocal": verificationLocal,
    "verificationServer": verificationServer,
    "verificationSource": verificationSource,
    "status": status,
    "quantity": quantity,
    "purchaseID": purchaseID,
  };
}

class PurchaseCollection {
  final List<Purchase> purchases;

  PurchaseCollection.fromJSON(Map<String, dynamic> json)
    : purchases = (json["purchases"] as List)
      .map((json) => Purchase.fromJson(json))
      .toList();
}