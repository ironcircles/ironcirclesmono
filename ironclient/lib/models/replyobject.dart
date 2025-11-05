import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';

class ReplyObject {
  String? id; ///for reply object
  String? seed;
  String? type;
  String? circleObjectID; ///original circle object
  User? creator;
  int sortIndex = 0;
  List<int>? secretKey;
  String? body;
  bool? emojiOnly;
  DateTime? lastUpdate;
  DateTime? lastUpdateNotReaction;
  DateTime? created;
  Circle? circle;
  String device;
  String? typeOriginal;
  String? encryptedBody;

  String? replyToID;
  ///null for average reply,
  ///another reply object for chain of replies

  //String? replyObjectID;
  ///how to have reply to reply?
  //User? lastEdited;
  //String? UserID;
  //Circle? circle;
  CircleObject? circleObject;
  bool? refreshNeeded;
  List<User>? taggedUsers;
  List<CircleObjectReaction>? reactions;
 ///are these needed?
  // DateTime? lastReactedDate;

  ///temporary variables?
  bool showOptionIcons = false;
  RatchetPair? ratchetPair;
  String? isolateError;
  String? isolateTrace;
  final GlobalKey globalKey = GlobalKey();

  ///done pile
  // String? storageID;
  String crank;
  String signature;
  String verification;
  String verificationFailed;
  String senderRatchetPublic;
  List<RatchetIndex> ratchetIndexes;

  String? date;
  String? time;
  String? lastUpdatedDate;
  String? lastUpdatedTime;

  //CircleObjectLineItem? encryptedLineItem;

  ReplyObject({
    this.id,
    this.seed,
    this.type,
    this.circleObjectID,
    this.creator,
    this.sortIndex = 0,
    this.secretKey,
    this.body,
    this.emojiOnly,
    this.lastUpdate,
    this.lastUpdateNotReaction,
    this.created,
    this.circle,
    this.device = '',
    this.typeOriginal,
    this.encryptedBody,
    this.replyToID,
    this.taggedUsers,
    this.reactions,

    //this.replyObjectID,
    //this.showOptionIcons,
    //this.lastEdited,
    this.circleObject,
    this.refreshNeeded,

    ///done pile
    // this.storageID,
    this.crank = '',
    this.signature = '',
    this.verification = '',
    this.verificationFailed = '',
    this.senderRatchetPublic = '',
    required this.ratchetIndexes,

    this.date,
    this.time,
    this.lastUpdatedDate,
    this.lastUpdatedTime,

    //this.encryptedLineItem,
  });

  initDates() {
    created = DateTime.now().toLocal();
    lastUpdate = DateTime.now().toLocal();
    lastUpdateNotReaction = lastUpdate;
    date = DateFormat.yMMMd().format(DateTime.parse(created.toString()));
    time = DateFormat.jm().format(DateTime.parse(created.toString()));
    lastUpdatedDate =
        DateFormat.yMMMd().format(DateTime.parse(lastUpdate.toString()));
    lastUpdatedTime =
        DateFormat.jm().format(DateTime.parse(lastUpdate.toString()));
  }

  factory ReplyObject.fromJson(Map<String, dynamic> jsonMap) => ReplyObject(
    id: jsonMap["_id"],
    seed: jsonMap["seed"],
    type: jsonMap["type"],
    circleObjectID: jsonMap["circleObjectID"],
    creator: jsonMap["creator"] == null ? null : User.fromJson(jsonMap["creator"]),
    sortIndex: jsonMap["sortIndex"] ?? 0,
    secretKey: jsonMap["secretKey"] == null
        ? null
        : List<int>.from(jsonMap["secretKey"].map((x) => x)),
    body: jsonMap["body"],
    emojiOnly: jsonMap["emojiOnly"] ?? false,
    circle:
    jsonMap["circle"] == null ? null : Circle.fromJson(jsonMap["circle"]),
    device: jsonMap["device"] ?? '',
    typeOriginal: jsonMap["typeOriginal"],
    encryptedBody: jsonMap["encryptedBody"],
    replyToID: jsonMap["replyToID"],
    taggedUsers: jsonMap["taggedUsers"] == null
        ? null
        : UserCollection.fromJSON(jsonMap, "taggedUsers").users,
    reactions: jsonMap["reactions"] == null
      ? null
      : CircleObjectReactionCollection.fromJSON(jsonMap, "reactions").reactions,

    // storageID: jsonMap["storageID"],
    crank: jsonMap["crank"] ?? '',
    signature: jsonMap["signature"] ?? '',
    verification: jsonMap["verification"] ?? '',
    verificationFailed: jsonMap["verificationFailed"] ?? '',
    senderRatchetPublic: jsonMap["senderRatchetPublic"] ?? '',
    ratchetIndexes: jsonMap["ratchetIndexes"] == null
        ? []
        : jsonMap["ratchetIndexes"] is String
        ? []
        : RatchetIndexCollection.fromJSON(jsonMap, "ratchetIndexes").ratchetIndexes,
    created: jsonMap["created"] == null
        ? null
        : DateTime.parse(jsonMap["created"]).toLocal(),
    lastUpdate: jsonMap["lastUpdate"] == null
        ? null
        : DateTime.parse(jsonMap["lastUpdate"]).toLocal(),
    lastUpdateNotReaction: jsonMap["lastUpdateNotReaction"] == null
        ? jsonMap["lastUpdate"] == null
        ? null
        : DateTime.parse(jsonMap["lastUpdate"]).toLocal()
        : DateTime.parse(jsonMap["lastUpdateNotReaction"]).toLocal(),
    date: jsonMap["created"] == null
        ? null
        : DateFormat.yMMMd()
        .format(DateTime.parse(jsonMap["created"]).toLocal()),
    time: jsonMap["created"] == null
        ? null
        : (globalState.language == Language.ENGLISH) ? DateFormat.jm().format(DateTime.parse(jsonMap["created"]).toLocal()) : DateFormat('HH:mm').format(DateTime.parse(jsonMap["created"]).toLocal()), //D
    lastUpdatedDate: jsonMap["lastUpdateNotReaction"] == null
        ? jsonMap["lastUpdate"] == null
        ? null
        : DateFormat.yMMMd()
        .format(DateTime.parse(jsonMap["lastUpdate"]).toLocal())
        : DateFormat.yMMMd().format(
        DateTime.parse(jsonMap["lastUpdateNotReaction"]).toLocal()),
    lastUpdatedTime: jsonMap["lastUpdateNotReaction"] == null
        ? jsonMap["lastUpdate"] == null
        ? null
        : DateFormat.jm()
        .format(DateTime.parse(jsonMap["lastUpdate"]).toLocal())
        : DateFormat.jm().format(
        DateTime.parse(jsonMap["lastUpdateNotReaction"]).toLocal()),
    // encryptedLineItem: jsonMap["encryptedLineItem"] == null
    //     ? null
    //     : CircleObjectLineItem.fromJson(jsonMap["encryptedLineItem"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "seed": seed,
    "type": type,
    "circleObjectID": circleObjectID,
    "creator": creator?.toJson(),
    "sortIndex": sortIndex,
    "secretKey": secretKey,
    "body": body,
    "emojiOnly": emojiOnly ?? false,
    "circle": circle?.toJson(),
    "device": device,
    "typeOriginal": typeOriginal,
    "encryptedBody": encryptedBody,
    "replyToID": replyToID,
    "taggedUsers": taggedUsers == null
        ? null
        : List<dynamic>.from(taggedUsers!.map((x) => x)),
    "reactions": reactions == null
      ? null
      : List<dynamic>.from(reactions!.map((x) => x)),

    "created": created?.toUtc().toString(),
    // "storageID": storageID,
    "crank": crank,
    "signature": signature,
    "verification": verification,
    "verificationFailed": verificationFailed,
    "senderRatchetPublic": senderRatchetPublic,
    "ratchetIndexes": List<dynamic>.from(ratchetIndexes.map((x) => x)),
    "lastUpdate": lastUpdate?.toUtc().toString(),
    "lastUpdateNotReaction": lastUpdateNotReaction?.toUtc().toString(),
    //"encryptedLineItem": encryptedLineItem,
  };

  revertEncryptedFields(ReplyObject original) {
    try {
      body = original.body;
      emojiOnly = original.emojiOnly;
      //circleObjectID = original.circleObjectID;
      circleObject = original.circleObject;
      if (original.circleObjectID == null) {
        circleObjectID = original.circleObject!.id;
      } else {
        circleObjectID = original.circleObjectID;
      }

      replyToID = original.replyToID;

      taggedUsers = original.taggedUsers;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("replyObject.revertEncryptedFields: $err");
      rethrow;
    }
  }

  ///encrypts a replyObject, also removes child elements that
  ///should be blanked out (object.blankEncryptionFields)
  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = <String, dynamic>{};

      retValue["body"] = body;
      retValue["emojiOnly"] = emojiOnly ?? false;
      retValue["circleObjectID"] = circleObjectID;
      retValue["replyToID"] = replyToID;
      retValue["taggedUsers"] = taggedUsers == null
          ? null
          : List<dynamic>.from(taggedUsers!.map((x) => x));

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('ReplyObject.fetchFieldsToEncrypt: $err');
      rethrow;
    }
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      body = json["body"];
      emojiOnly = json["emojiOnly"] ?? false;
      circleObjectID = json["circleObjectID"];
      replyToID = json["replyToID"];
      // reply = json["reply"];
      // replyUsername = json["replyUsername"];
      // replyUserID = json["replyUserID"];
      taggedUsers = json["taggedUsers"] == null
          ? null
          : UserCollection.fromJSON(json, "taggedUsers").users;
    } catch (err, trace) {
      debugPrint('$trace');
      debugPrint('ReplyObject.mapDecryptedFields: $err');
      rethrow;
    }
  }

}

// class ReplyObjects {
//   final List<ReplyObject> objects;
//
//   ReplyObjects.fromJSON(Map<String, dynamic> json, String key)
//     : objects = (json[key] as List).map((json) => ReplyObject.fromJson(json)).toList();
// }

class ReplyObjectCollection {
  final List<ReplyObject> replyObjects;

  ReplyObjectCollection.fromJSON(Map<String, dynamic> json,
      {key = 'replyobjects'})
      : replyObjects = (json[key] as List)
      .map((json) => ReplyObject.fromJson(json))
      .toList();

  static List<ReplyObject> sort(
      List<ReplyObject> objects
      ) {
    objects.sort((a, b) {
      return b.created!.compareTo(a.created!);
    });

    return objects;
  }

  static void addObjects(
      List<ReplyObject> replyObjects,
      List<ReplyObject> objectsToAdd,
      String circleObjectID,
      UserFurnace userFurnace,
      ) {
    if (objectsToAdd.isNotEmpty) {
      objectsToAdd.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });

      if (replyObjects.isEmpty) {
        replyObjects.addAll(objectsToAdd);
      } else {
        for (ReplyObject newObject in objectsToAdd) {
          int index = -1;

          ///chaos engineering -- this should never happen
          // if (newObject.replyObjectID != circleObjectID) {
          //   ///???
          // }

          if (newObject.id != null) {
            ///Test for the id first
            index = replyObjects.indexWhere((replyobject) => replyobject.id == newObject.id);
          }

          if (index == -1 && newObject.seed != null) {
            ///we didn't find this object, see if there was a seed
            index = replyObjects.indexWhere(
                    (replyobject) => replyobject.seed == newObject.seed);
          }

          if (index == -1) {
            ///we didn't find the id or the seed; legit new item

            index = 0;

            //start at the bottom and work backwards until we find the right place to insert
            for (ReplyObject existing in replyObjects) {
              if (existing.created!.compareTo(newObject.created!) < 0) {
                break;
              }

              if (index != null) index++;
            }

            replyObjects.insert(index, newObject);
          } else {
            if (index != null) {
              if (replyObjects[index].id == null) {
                DateTime doNoJump = replyObjects[index].created!;
                replyObjects[index] = newObject;
                replyObjects[index].created = doNoJump;
              } else {
                replyObjects[index] = newObject;
              }
            } else {
              debugPrint('index is null');
            }
          }

          ReplyObjectCollection.sort(replyObjects);
        }
      }
    }
  }

  ///Only call this for new object saves and updates to the saved object
  ///Do not call for objects coming in from another user
  static void upsertObject(
      List<ReplyObject> replyObjects,
      ReplyObject upsertObject,
      String circleObjectID,
      UserCircleCache userCircleCache) {
    int index = replyObjects.indexWhere((replyObject) => replyObject.seed == upsertObject.seed);

    ///verify this is the right circle
    if (index == -1) {
      if (upsertObject.circleObjectID! != circleObjectID) {
        if (userCircleCache.circle != upsertObject.circle!.id) {
          return;
        }
      }
      replyObjects.insert(0, upsertObject);
    } else {
      DateTime created = replyObjects[index].created!;
      int sortIndex = replyObjects[index].sortIndex;
      replyObjects[index] = upsertObject;
      replyObjects[index].created = created;
      replyObjects[index].sortIndex = sortIndex;
    }
  }

}