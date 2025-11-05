import 'package:ironcirclesapp/models/export_models.dart';
import 'package:uuid/uuid.dart';

//Subscription fromJson(String str) => Subscription.fromJson(json.decode(str));
//String toJson(Subscription data) => json.encode(data.toJson());

class Subscription {
  //int pk;
  String id;
  String userID;
  String purchaseDetailsJson;
  String seed;
  String type;
  DateTime transactionDate;
  DateTime? cancelDate;
  DateTime? pauseDate;
  DateTime? resumeDate;
  String verificationLocal;
  String verificationServer;
  String verificationSource;
  int status;
  String purchaseID;

  Subscription({
    required this.id,
    required this.userID,
    required this.seed,
    required this.purchaseDetailsJson,
    required this.type,
    required this.transactionDate,
    this.cancelDate,
    this.pauseDate,
    this.resumeDate,
    required this.verificationLocal,
    required this.verificationServer,
    required this.verificationSource,
    required this.status,
    required this.purchaseID,
  });

  factory Subscription.blank() => Subscription(
      id: '',
      userID: '', //globalState.userFurnace!.userid!,
      seed: const Uuid().v4(),
      type: '',
      purchaseDetailsJson: '',
      transactionDate: DateTime.now(),
      verificationLocal: '',
      verificationServer: '',
      verificationSource: '',
      status: SubscriptionStatus.PENDING,
      purchaseID: '');

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json["_id"],
        userID: json["user"],
        type: json["type"],
        seed: json["seed"],
        purchaseDetailsJson: json["purchaseDetailsJson"] ?? '',
        transactionDate: DateTime.parse(json["transactionDate"]).toLocal(),
        cancelDate: json["cancelDate"] == null
            ? null
            : DateTime.parse(json["cancelDate"]).toLocal(),
        pauseDate: json["pauseDate"] == null
            ? null
            : DateTime.parse(json["pauseDate"]).toLocal(),
        resumeDate: json["resumeDate"] == null
            ? null
            : DateTime.parse(json["resumeDate"]).toLocal(),
        verificationLocal: json["verificationLocal"],
        verificationServer: json["verificationServer"],
        verificationSource: json["verificationSource"],
        purchaseID: json["purchaseID"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "userID": userID,
        "type": type,
        "seed": seed,
        "purchaseDetailsJson": purchaseDetailsJson,
        "transactionDate": transactionDate.toUtc().toString(),
        "cancelDate": cancelDate == null ? '' : cancelDate!.toUtc().toString(),
        "pauseDate": pauseDate == null ? '' : pauseDate!.toUtc().toString(),
        "resumeDate": resumeDate == null ? '' : resumeDate!.toUtc().toString(),
        "verificationLocal": verificationLocal,
        "verificationServer": verificationServer,
        "verificationSource": verificationSource,
        "status": status,
        "purchaseID": purchaseID,
      };

  factory Subscription.fromJsonSQL(Map<String, dynamic> json) =>
      Subscription(
        id: json["id"] ?? '',
        userID: json["userID"],
        type: json["type"],
        purchaseDetailsJson: json["purchaseDetailsJson"] ?? '',
        seed: json["seed"],
        transactionDate:
            DateTime.fromMillisecondsSinceEpoch(json["transactionDate"])
                .toLocal(),
        cancelDate: json["cancelDate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["cancelDate"]).toLocal(),
        pauseDate: json["pauseDate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["pauseDate"]).toLocal(),
        resumeDate: json["resumeDate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["resumeDate"]).toLocal(),
        verificationLocal: json["verificationLocal"],
        verificationServer: json["verificationServer"],
        verificationSource: json["verificationSource"],
        status: json["status"],
        purchaseID: json["purchaseID"],
      );

  Map<String, dynamic> toJsonSQL() => {
        "id": id,
        "userID": userID,
        "type": type,
        "seed": seed,
        "purchaseDetailsJson": purchaseDetailsJson,
        "transactionDate": transactionDate.millisecondsSinceEpoch,
        "cancelDate":
            cancelDate?.millisecondsSinceEpoch,
        "pauseDate":
            pauseDate?.millisecondsSinceEpoch,
        "resumeDate":
            resumeDate?.millisecondsSinceEpoch,
        "verificationLocal": verificationLocal,
        "verificationServer": verificationServer,
        "verificationSource": verificationSource,
        "status": status,
        "purchaseID": purchaseID,
      };
}

class SubscriptionCollection {
  final List<Subscription> subscriptions;

  SubscriptionCollection.fromJSON(Map<String, dynamic> json)
      : subscriptions = (json['subscriptions'] as List)
            .map((json) => Subscription.fromJson(json))
            .toList();
}
