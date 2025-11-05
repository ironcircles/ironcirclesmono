import 'dart:convert';

ReplyObjectCache replyObjectCacheFromJson(String str) =>
    ReplyObjectCache.fromJson(json.decode(str));

String replyObjectCacheToJson(ReplyObjectCache data) =>
    json.encode(data.toJson());

class ReplyObjectCache {
  int? pk;
  String? seed;
  String? circleObjectid;
  String? replyObjectid;
  String? replyObjectJson;
  String? creator;
  String? type;

  int retryDecrypt;

  DateTime? lastUpdate;
  DateTime? created;

  //bool draft;

  ReplyObjectCache({
    this.pk,
    this.seed,
    this.circleObjectid,
    this.replyObjectid,
    this.replyObjectJson,
    this.creator,
    this.type,

    this.retryDecrypt = 0,

    this.lastUpdate,
    this.created,

    //this.draft,
  });

  factory ReplyObjectCache.fromJson(Map<String, dynamic> json) =>
      ReplyObjectCache(
        pk: json["pk"],
        circleObjectid: json["circleObject"],
        replyObjectid: json["replyObject"],
        replyObjectJson: json["replyObjectJson"],
        seed: json["seed"],
        creator: json["creator"],
        type: json["type"],

        retryDecrypt: json["retryDecrypt"] ?? 0,

        //draft: json["draft"] == 1 ? true : false,

        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        created: json["created"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["created"]).toLocal(),
      );

  Map<String, dynamic> toJson() => {
    "circleObject": circleObjectid,
    "replyObject": replyObjectid,
    "replyObjectJson": replyObjectJson,
    "seed": seed,
    "creator": creator,
    "type": type,
    //"draft": draft ? 1 : 0,
    "retryDecrypt": retryDecrypt,
    "lastUpdate": lastUpdate?.millisecondsSinceEpoch,
    "created": created?.millisecondsSinceEpoch,
  };

}