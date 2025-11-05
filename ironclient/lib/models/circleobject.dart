import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/blob_url.dart';
import 'package:ironcirclesapp/models/circleagoracall.dart';
import 'package:ironcirclesapp/models/circlealbum.dart';
import 'package:ironcirclesapp/models/circlefile.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/circlevideo.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetpair.dart';
import 'package:uuid/uuid.dart';

CircleObject circleObjectFromJson(String str) =>
    CircleObject.fromJson(json.decode(str));

String circleObjectToJson(CircleObject data) => json.encode(data.toJson());

class ForcedOrder {
  final String seed;
  final String type;

  ForcedOrder({required this.seed, required this.type});
}

class CircleObject {
  List<CircleObjectReaction>? reactions;
  String? id;
  Circle? circle;
  User? creator;
  User? lastEdited;
  CircleVote? vote;
  CircleGif? gif;
  CircleImage? image;
  CircleFile? file;
  CircleLink? link;
  CircleVideo? video;
  CircleEvent? event;
  CircleList? list;
  CircleRecipe? recipe;
  CircleAlbum? album;
  CircleAgoraCall? agoraCall;

  ///3+ images
  String? removeFromCache;
  String? body;
  String? replyObjectID;
  String? reply;
  String? replyUsername;
  String? replyUserID;
  int? subType;
  String? subString1;
  String? subString2;
  String? subString3;
  String? subString4;
  String? encryptedBody;
  String? type;
  String? typeOriginal;
  DateTime? lastUpdate;
  DateTime? lastUpdateNotReaction;
  DateTime? lastReactedDate;
  DateTime? created;
  String? time;
  String? seed;
  String? storageID;
  String? date;
  String? lastUpdatedDate;
  String? lastUpdatedTime;
  bool? emojiOnly;
  DateTime? timerExpires;
  int? timer;
  DateTime? scheduledFor;
  bool showOptionIcons = false;
  int sortIndex = 0;
  int albumCount = 0;
  int retries;
  int nonUIRetries;
  bool editing = false;
  bool hiRes;
  bool oneTimeView;
  bool pinned = false;
  List<String>? pinnedUsers;
  List<User>? taggedUsers;
  bool draft;
  int? dateIncrement;

  //String objectRatchet;
  String crank;
  String signature;
  String verification;
  String verificationFailed;
  String device;
  String senderRatchetPublic;
  List<RatchetIndex> ratchetIndexes;
  String? foundIndex;

  //hitchhikers
  UserFurnace? userFurnace;
  UserCircleCache? userCircleCache;
  int? transferPercent;
  List<CancelToken>? cancelTokens;
  int? thumbnailTransferState;
  int? fullTransferState;
  List<int>? secretKey; //in memory temporarily to use for encrypting blobs
  CircleObject? original;
  RatchetPair? ratchetPair;
  BlobUrl? transferUrls;
  CancelToken? cancelToken;
  bool unstable = false;
  bool refreshNeeded = false;
  //MediaCollection? draftMediaCollection;
  List<Media>? draftMediaCollection;

  //ui
  bool updating = false;
  bool showDate = false;
  final GlobalKey globalKey = GlobalKey();
  bool interactive = true;
  String? isolateError;
  String? isolateTrace;
  ImageProvider? imageProvider;
  bool decryptingImage = false;

  DateTime? originalCreated;

  addToken(CancelToken cancelToken) {
    cancelTokens ??= [];
    cancelTokens!.add(cancelToken);
  }

  removeToken(CancelToken cancelToken) {
    if (cancelTokens != null) cancelTokens!.remove(cancelToken);
  }

  CircleObject(
      {this.id,
      this.reactions,
      this.circle,
      this.lastEdited,
      this.creator,
      this.vote,
      this.link,
      this.list,
      this.recipe,
      this.event,
      this.gif,
      this.image,
      this.file,
      this.album,
      this.video,
      this.agoraCall,
      this.removeFromCache,
      this.body,
      this.replyObjectID,
      this.reply,
      this.replyUsername,
      this.replyUserID,
      this.subType,
      this.subString1,
      this.subString2,
      this.subString3,
      this.subString4,
      this.encryptedBody,
      this.type,
      this.typeOriginal,
      this.lastUpdate,
      this.lastUpdateNotReaction,
      this.lastReactedDate,
      this.created,
      this.date,
      this.oneTimeView = false,
      this.time,
      this.scheduledFor,
      this.draftMediaCollection,
      this.lastUpdatedDate,
      this.lastUpdatedTime,
      this.timer,
      this.timerExpires,
      this.emojiOnly,
      this.seed,
      this.storageID,
      this.hiRes = false,
      this.pinned = false,
      this.pinnedUsers,
      this.taggedUsers,
      //this.objectRatchet = '',
      this.thumbnailTransferState,
      this.fullTransferState,
      this.crank = '',
      this.signature = '',
      this.verification = '',
      this.verificationFailed = '',
      this.device = '',
      this.senderRatchetPublic = '',
      this.sortIndex = 0,
      this.albumCount = 0,
      required this.ratchetIndexes,
      this.retries = 0,
      this.nonUIRetries = 0,
      this.dateIncrement,
      this.secretKey,
      this.draft = false});

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

    //debugPrint("initDates: ${this.created}");
  }

  factory CircleObject.fromJson(Map<String, dynamic> jsonMap) => CircleObject(
      id: jsonMap["_id"],
      circle:
          jsonMap["circle"] == null ? null : Circle.fromJson(jsonMap["circle"]),
      creator:
          jsonMap["creator"] == null ? null : User.fromJson(jsonMap["creator"]),
      lastEdited: jsonMap["lastEdited"] == null
          ? null
          : User.fromJson(jsonMap["lastEdited"]),
      vote:
          jsonMap["vote"] == null ? null : CircleVote.fromJson(jsonMap["vote"]),
      event: jsonMap["event"] == null
          ? null
          : CircleEvent.fromJson(jsonMap["event"]),
      link:
          jsonMap["link"] == null ? null : CircleLink.fromJson(jsonMap["link"]),
      recipe: jsonMap["recipe"] == null
          ? null
          : CircleRecipe.fromJson(jsonMap["recipe"]),
      secretKey: jsonMap["secretKey"] == null
          ? null
          : List<int>.from(jsonMap["secretKey"].map((x) => x)),
      list:
          jsonMap["list"] == null ? null : CircleList.fromJson(jsonMap["list"]),
      gif: jsonMap["gif"] == null ? null : CircleGif.fromJson(jsonMap["gif"]),
      image: jsonMap["image"] == null
          ? null
          : CircleImage.fromJson(jsonMap["image"]),
      file:
          jsonMap["file"] == null ? null : CircleFile.fromJson(jsonMap["file"]),
      draftMediaCollection: jsonMap["draftMediaCollection"] == null
          ? null
          : MediaCollection.fromJSON(jsonMap, "draftMediaCollection").media,
      reactions: jsonMap["reactionsPlus"] == null
          ? null
          : CircleObjectReactionCollection.fromJSON(jsonMap, "reactionsPlus")
              .reactions,
      album: jsonMap["album"] == null
          ? null
          : CircleAlbum.fromJson(jsonMap["album"]),
      video: jsonMap["video"] == null
          ? null
          : CircleVideo.fromJson(jsonMap["video"]),
      agoraCall: jsonMap["agoraCall"] == null
          ? null
          : CircleAgoraCall.fromJson(jsonMap["agoraCall"]),
      removeFromCache: jsonMap["removeFromCache"],
      body: jsonMap["body"],
      pinned: jsonMap["pinned"] ?? false,
      draft: jsonMap["draft"] ?? false,
      pinnedUsers: jsonMap["pinnedUsers"] == null
          ? null
          : List.from(jsonMap["pinnedUsers"]),
      replyObjectID: jsonMap["replyObjectID"],
      reply: jsonMap["reply"],
      replyUsername: jsonMap["replyUsername"],
      replyUserID: jsonMap["replyUserID"],
      timer: jsonMap["timer"],
      timerExpires: jsonMap["timerExpires"] == null
          ? null
          : DateTime.parse(jsonMap["timerExpires"]).toLocal(),
      scheduledFor: jsonMap["scheduledFor"] == null
          ? null
          : DateTime.parse(jsonMap["scheduledFor"]).toLocal(),
      subType: jsonMap["subType"],
      subString1: jsonMap["subString1"],
      subString2: jsonMap["subString2"],
      subString3: jsonMap["subString3"],
      subString4: jsonMap["subString4"],
      encryptedBody: jsonMap["encryptedBody"],
      seed: jsonMap["seed"],
      storageID: jsonMap["storageID"],
      hiRes: jsonMap["hiRes"] ?? false,
      oneTimeView: jsonMap["oneTimeView"] ?? false,
      sortIndex: jsonMap["sortIndex"] ?? 0,
      type: jsonMap["type"],
      typeOriginal: jsonMap["typeOriginal"],
      emojiOnly: jsonMap["emojiOnly"] ?? false,
      thumbnailTransferState: jsonMap["thumbnailTransferState"],
      fullTransferState: jsonMap["fullTransferState"],
      lastUpdate: jsonMap["lastUpdate"] == null
          ? null
          : DateTime.parse(jsonMap["lastUpdate"]).toLocal(),
      lastUpdateNotReaction: jsonMap["lastUpdateNotReaction"] == null
          ? jsonMap["lastUpdate"] == null
              ? null
              : DateTime.parse(jsonMap["lastUpdate"]).toLocal()
          : DateTime.parse(jsonMap["lastUpdateNotReaction"]).toLocal(),
      lastReactedDate: jsonMap["lastReactedDate"] == null
          ? null
          : DateTime.parse(jsonMap["lastReactedDate"]).toLocal(),
      created: jsonMap["created"] == null
          ? null
          : DateTime.parse(jsonMap["created"]).toLocal(),
      date: jsonMap["created"] == null
          ? null
          : DateFormat.yMMMd()
              .format(DateTime.parse(jsonMap["created"]).toLocal()),
      time: jsonMap["created"] == null
          ? null
          : (globalState.language == Language.ENGLISH)
              ? DateFormat.jm()
                  .format(DateTime.parse(jsonMap["created"]).toLocal())
              : DateFormat('HH:mm')
                  .format(DateTime.parse(jsonMap["created"]).toLocal()), //D
      //.format(DateTime.parse(jsonMap["created"]).toLocal()),
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
      ratchetIndexes: jsonMap["ratchetIndexes"] == null
          ? []
          : jsonMap["ratchetIndexes"] is String
              ? []
              : RatchetIndexCollection.fromJSON(jsonMap, "ratchetIndexes")
                  .ratchetIndexes,
      //objectRatchet: jsonMap["objectRatchet"] == null ? '' : jsonMap["objectRatchet"],
      crank: jsonMap["crank"] ?? '',
      signature: jsonMap["signature"] ?? '',
      verification: jsonMap["verification"] ?? '',
      verificationFailed: jsonMap["verificationFailed"] ?? '',
      device: jsonMap["device"] ?? '',
      albumCount: jsonMap["albumCount"] ?? 0,
      senderRatchetPublic: jsonMap["senderRatchetPublic"] ?? '',
      retries: jsonMap["retries"] ?? 0,
      taggedUsers: jsonMap["taggedUsers"] == null
          ? null
          : UserCollection.fromJSON(jsonMap, "taggedUsers").users);

  Map<String, dynamic> toJson() => {
        "_id": id,
        "circle": circle?.toJson(),
        "creator": creator?.toJson(),
        "lastEdited": lastEdited?.toJson(),
        "secretKey": secretKey,
        "video": video?.toJson(),
        "vote": vote?.toJson(),
        "gif": gif?.toJson(),
        "link": link?.toJson(),
        "image": image?.toJson(),
        "file": file?.toJson(),
        "draftMediaCollection": draftMediaCollection == null
            ? null
            : List<dynamic>.from(draftMediaCollection!.map((x) => x)),
        "reactionsPlus": reactions == null
            ? null
            : List<dynamic>.from(reactions!.map((x) => x)),
        "album": album?.toJson(),
        "list": list?.toJson(),
        "event": event?.toJson(),
        "recipe": recipe?.toJson(),
        "agoraCall": agoraCall?.toJson(),
        "ratchetIndexes": List<dynamic>.from(ratchetIndexes.map((x) => x)),
        "removeFromCache": removeFromCache,
        "body": body,
        "replyObjectID": replyObjectID,
        "reply": reply,
        "replyUsername": replyUsername,
        "replyUserID": replyUserID,
        "subType": subType,
        "subString1": subString1,
        "subString2": subString2,
        "subString3": subString3,
        "subString4": subString4,
        "encryptedBody": encryptedBody,
        "seed": seed,
        "storageID": storageID,
        "albumCount": albumCount,
        "sortIndex": sortIndex,
        "hiRes": hiRes,
        "pinned": pinned,
        "draft": draft,
        "oneTimeView": oneTimeView,
        "type": type,
        "timer": timer,
        "timerExpires": timerExpires?.toUtc().toString(),
        "scheduledFor": scheduledFor?.toUtc().toString(),
        "typeOriginal": typeOriginal,
        "thumbnailTransferState": thumbnailTransferState,
        "fullTransferState": fullTransferState,
        //"objectRatchet": objectRatchet,
        "crank": crank,
        "signature": signature,
        "verification": verification,
        "verificationFailed": verificationFailed,
        "device": device,
        "senderRatchetPublic": senderRatchetPublic,
        "emojiOnly": emojiOnly ?? false,
        "created": created?.toUtc().toString(),
        "lastUpdate": lastUpdate?.toUtc().toString(),
        "lastUpdateNotReaction": lastUpdateNotReaction?.toUtc().toString(),
        "lastReactedDate": lastReactedDate?.toUtc().toString(),
        "retries": retries,
        "taggedUsers": taggedUsers == null
            ? null
            : List<dynamic>.from(taggedUsers!.map((x) => x)),
      };

  String getCreatedUTC() {
    return created!.toUtc().toString();
  }

  static _determineWaitingOn(
      CircleObject beforeMe, CircleObject me, Duration duration) {
    if (beforeMe.created!.difference(me.created!) <=
        const Duration(seconds: 15)) {
      return beforeMe.seed!;
    }

    return '';
  }

  static String getWaitingOn(CircleObject me) {
    String waitingOn = '';

    ///find me
    int index = globalState.forcedOrder
        .indexWhere((element) => element.seed == me.seed!);

    ///get the seed of the item before me

    if (index > 0) {
      CircleObject beforeMe = globalState.forcedOrder[index - 1];

      ///based on type, decide whether to force order or not
      if (me.type == CircleObjectType.CIRCLEMESSAGE) {
        if (beforeMe.type == CircleObjectType.CIRCLEMESSAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(seconds: 10));
        } else if (beforeMe.type == CircleObjectType.CIRCLEIMAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 5));
        } else if (beforeMe.type == CircleObjectType.CIRCLEVIDEO) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 10));
        }
      } else if (me.type == CircleObjectType.CIRCLEIMAGE) {
        if (beforeMe.type == CircleObjectType.CIRCLEMESSAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(seconds: 10));
        } else if (beforeMe.type == CircleObjectType.CIRCLEIMAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 5));
        } else if (beforeMe.type == CircleObjectType.CIRCLEVIDEO) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 10));
        }
      } else if (me.type == CircleObjectType.CIRCLEVIDEO) {
        if (beforeMe.type == CircleObjectType.CIRCLEMESSAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(seconds: 10));
        } else if (beforeMe.type == CircleObjectType.CIRCLEIMAGE) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 5));
        } else if (beforeMe.type == CircleObjectType.CIRCLEVIDEO) {
          waitingOn =
              _determineWaitingOn(beforeMe, me, const Duration(minutes: 10));
        }
      }
    }

    return waitingOn;
  }

  static clearItems(String mySeed) {
    try {
      ///clear everything before and including mySeed
      if (globalState.forcedOrder.isNotEmpty) {
        int index = globalState.forcedOrder
            .indexWhere((element) => element.seed == mySeed);

        if (index > -1) {
          globalState.forcedOrder.removeRange(0, index);
        }
      }
    } catch (err) {
      debugPrint('CircleObject.clearPriorItems: $err');
    }
  }

  static CircleObject prepNewCircleObject(
      UserCircleCache userCircleCache,
      UserFurnace userFurnace,
      String? body,
      int index,
      CircleObject? replyObject,
      {String? type}) {
    try {
      CircleObject newCircleObject = CircleObject(
        creator: User(
          username: userFurnace.username,
          id: userFurnace.userid,
          accountType: userFurnace.accountType,
        ),
        body: body ?? '',
        circle: userCircleCache.cachedCircle,
        sortIndex: index,
        ratchetIndexes: [],
        created: DateTime.now(),
        seed: const Uuid().v4(),
        type: type,
        /*circle: Circle(
          id: userCircleCache.circle,
        )*/
      );

      globalState.forcedOrder.add(newCircleObject);

      if (replyObject != null) {
        if (replyObject.id != null) {
          newCircleObject.replyObjectID = replyObject.id;
        }
        newCircleObject.reply = replyObject.body;
        newCircleObject.replyUsername = replyObject.creator!.username;
        newCircleObject.replyUserID = replyObject.creator!.id;
      }

      newCircleObject.initDates();
      newCircleObject.userFurnace = userFurnace;
      newCircleObject.userCircleCache = userCircleCache;

      return newCircleObject;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObject.prepNewCircleObject: $err');
      rethrow;
    }
  }

  revertEncryptedFields(CircleObject original) {
    try {
      body = original.body;
      link = original.link;
      gif = original.gif;
      emojiOnly = original.emojiOnly;
      subType = original.subType;
      subString1 = original.subString1;
      subString2 = original.subString2;
      subString3 = original.subString3;
      subString4 = original.subString4;
      replyObjectID = original.replyObjectID;
      reply = original.reply;
      replyUsername = original.replyUsername;
      replyUserID = original.replyUserID;
      taggedUsers = original.taggedUsers;
      secretKey = original.secretKey;
      if (type == CircleObjectType.CIRCLELIST) {
        list!.revertEncryptionFields(original.list!);
      } else if (type == CircleObjectType.CIRCLERECIPE) {
        recipe!.revertEncryptionFields(original.recipe!);
      } else if (type == CircleObjectType.CIRCLEIMAGE) {
        image!.revertEncryptionFields(original.image!);
      } else if (type == CircleObjectType.CIRCLEEVENT) {
        event!.revertEncryptionFields(original.event!);
      } else if (type == CircleObjectType.CIRCLEVIDEO) {
        video!.revertEncryptionFields(original.video!);
      } else if (type == CircleObjectType.CIRCLEFILE) {
        file!.revertEncryptionFields(original.file!);
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObject.revertEncryptedFields: $err');
      rethrow;
    }
  }

  mapDecryptedFields(Map<String, dynamic> json) {
    try {
      body = json["body"];
      emojiOnly = json["emojiOnly"] ?? false;
      link = json["link"] == null ? null : CircleLink.fromJson(json["link"]);
      gif = json["gif"] == null ? null : CircleGif.fromJson(json["gif"]);
      subType = json["subType"];
      subString1 = json["subString1"];
      subString2 = json["subString2"];
      subString3 = json["subString3"];
      subString4 = json["subString4"];
      replyObjectID = json["replyObjectID"];
      reply = json["reply"];
      replyUsername = json["replyUsername"];
      replyUserID = json["replyUserID"];
      taggedUsers = json["taggedUsers"] == null
          ? null
          : UserCollection.fromJSON(json, "taggedUsers").users;

      if (type == CircleObjectType.CIRCLELIST) {
        list!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLERECIPE) {
        recipe!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLEIMAGE) {
        image!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLEEVENT) {
        event!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLEVIDEO) {
        video!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLEFILE) {
        file!.mapDecryptedFields(json);
      } else if (type == CircleObjectType.CIRCLEALBUM) {
        //album!.mapDecryptedFields(json);
      }
    } catch (err, trace) {
      debugPrint('$trace');
      //LogBloc.insertError(err, trace);
      debugPrint('CircleObject.mapDecryptedFields: $err');
      rethrow;
    }
  }

  ///encrypts a CircleObject, also removes child elements that should be blanked out(object.blankEncryptionFields)
  Map<String, dynamic> fetchFieldsToEncrypt() {
    try {
      Map<String, dynamic> retValue = <String, dynamic>{};

      retValue["body"] = body;
      retValue["emojiOnly"] = emojiOnly ?? false;
      retValue["link"] = link?.toJson();
      retValue["gif"] = gif?.toJson();

      retValue["subType"] = subType;
      retValue["subString1"] = subString1;
      retValue["subString2"] = subString2;
      retValue["subString3"] = subString3;
      retValue["subString4"] = subString4;
      retValue["replyObjectID"] = replyObjectID;
      retValue["reply"] = reply;
      retValue["replyUsername"] = replyUsername;
      retValue["replyUserID"] = replyUserID;
      retValue["taggedUsers"] = taggedUsers == null
          ? null
          : List<dynamic>.from(taggedUsers!.map((x) => x));

      if (type == CircleObjectType.CIRCLELIST) {
        retValue["list"] = list!.fetchFieldsToEncrypt();
        list!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLERECIPE) {
        retValue["recipe"] = recipe!.fetchFieldsToEncrypt();
        recipe!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLEIMAGE) {
        retValue["image"] = image!.fetchFieldsToEncrypt();
        //image!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLEEVENT) {
        retValue["event"] = event!.fetchFieldsToEncrypt();
        event!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLEVIDEO) {
        retValue["video"] = video!.fetchFieldsToEncrypt();
        //image!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLEFILE) {
        retValue["file"] = file!.fetchFieldsToEncrypt();
        file!.blankEncryptionFields();
      } else if (type == CircleObjectType.CIRCLEALBUM) {
        retValue["album"] = album!.fetchFieldsToEncrypt();
      }

      return retValue;
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('CircleObject.fetchFieldsToEncrypt: $err');
      rethrow;
    }
  }

  bool canShare(String userID, Circle circle) {
    ///If the object is in the device only circle or was created by the user, always allow sharing
    if (circle.id == DeviceOnlyCircle.circleID || creator!.id == userID) {
      return true;
    }

    ///check setting based on type
    if (type == CircleObjectType.CIRCLEVIDEO ||
        type == CircleObjectType.CIRCLEIMAGE ||
        type == CircleObjectType.CIRCLEGIF ||
        type == CircleObjectType.CIRCLEFILE ||
        type == CircleObjectType.CIRCLEALBUM) {
      if (circle.privacyShareImage!) return true;
    }

    return false;
  }
}

class CircleObjectCollection {
  final List<CircleObject> circleObjects;

  CircleObjectCollection.fromJSON(Map<String, dynamic> json,
      {key = 'circleobjects'})
      : circleObjects = (json[key] as List)
            .map((json) => CircleObject.fromJson(json))
            .toList();

  ///This sort is called from InsideCircle.listen.allCircleObjects.listen
  static List<CircleObject> sort(
    List<CircleObject> objects,
  ) {
    objects.sort((a, b) {
      return b.created!.compareTo(a.created!);
    });

    /*

    objects.sort((a, b) {
      if (b.id == null && b.draft != true && a.draft != true) {
        return b.sortIndex.compareTo(a.sortIndex);
      } else {
        return b.created!.compareTo(a.created!);
      }
    });

     */

    return objects;
  }

  static int findIndexByDate(List<CircleObject> objects, DateTime dateTime) {
    int index = -1;

    if (objects[0].created!.compareTo(dateTime) < 0) {
      index = 0;
    } else {
      //start at the bottom and work backwards until we find the right place to insert
      for (CircleObject existing in objects) {
        if (existing.created!.compareTo(dateTime) < 0) {
          break;
        }
        index++;
      }
    }

    return index;
  }

  ///Only call this for new object saves and updates to the saved object
  ///Do not call for objects coming in from another user
  static void upsertObject(
      List<CircleObject> circleObjects,
      CircleObject upsertObject,
      String circleID,
      List<UserCircleCache> wallUserCircleCaches) {
    int index = circleObjects
        .indexWhere((circleObject) => circleObject.seed == upsertObject.seed);

    ///verify this is the right circle
    if (index == -1) {
      if (upsertObject.circle!.id != circleID) {
        if (wallUserCircleCaches.isNotEmpty) {
          index = wallUserCircleCaches.indexWhere(
              (element) => element.circle == upsertObject.circle!.id);
          if (index == -1) {
            return;
          }
        } else {
          return;
        }
      }

      circleObjects.insert(0, upsertObject);
    } else {
      DateTime created = circleObjects[index].created!;
      int sortIndex = circleObjects[index].sortIndex;
      circleObjects[index] = upsertObject;
      circleObjects[index].created = created;
      circleObjects[index].sortIndex = sortIndex;
    }
  }

  static void addWallHitchhikers(
      List<CircleObject> objectsToAdd,
      List<UserFurnace> wallFurnaces,
      List<UserCircleCache> wallUserCircleCaches) {
    if (wallUserCircleCaches.isNotEmpty) {
      Iterable<CircleObject> missingHitchhikers =
          objectsToAdd.where((element) => element.userCircleCache == null);

      for (CircleObject circleObject in missingHitchhikers) {
        int index = wallUserCircleCaches
            .indexWhere((element) => element.circle == circleObject.circle!.id);

        if (index > -1) {
          circleObject.userCircleCache = wallUserCircleCaches[index];
          circleObject.userFurnace = wallFurnaces.firstWhere((element) =>
              element.pk == wallUserCircleCaches[index].userFurnace);
        }
      }
    }
  }

  static void addObjects(
      List<CircleObject> circleObjects,
      List<CircleObject> objectsToAdd,
      String circleID,
      List<UserFurnace> wallFurnaces,
      List<UserCircleCache> wallUserCircleCaches) {
    if (objectsToAdd.isNotEmpty) {
      ///if it's a wall post, make sure it didn't lose the hitchhikers
      addWallHitchhikers(objectsToAdd, wallFurnaces, wallUserCircleCaches);

      objectsToAdd.sort((a, b) {
        return b.created!.compareTo(a.created!);
      });

      if (circleObjects.isEmpty) {
        circleObjects.addAll(objectsToAdd);
      } else {
        for (CircleObject newObject in objectsToAdd) {
          int index = -1;

          ///chaos engineering -- this should never happen
          if (newObject.circle!.id != circleID) {
            if (wallUserCircleCaches.isNotEmpty) {
              int userCircleCacheIndex = wallUserCircleCaches.indexWhere(
                  (element) => element.circle == newObject.circle!.id);
              if (userCircleCacheIndex == -1) {
                break;
              }
            } else {
              break;
            }
          }

          if (newObject.id != null) {
            ///Test for the CircleObjectID first
            index = circleObjects
                .indexWhere((circleobject) => circleobject.id == newObject.id);
          }

          if (index == -1 && newObject.seed != null) {
            ///we didn't find this object, see if there was a seed
            index = circleObjects.indexWhere(
                (circleobject) => circleobject.seed == newObject.seed);
          }

          if (index != -1 &&
              (newObject.type == CircleObjectType.CIRCLELIST ||
                  newObject.type == CircleObjectType.CIRCLERECIPE ||
                  newObject.type == CircleObjectType.CIRCLEVOTE)) {
            ///force add and remove
            ///don't use the index in case the list has changed
            circleObjects.removeWhere(
                (circleobject) => circleobject.seed == newObject.seed);
            index = -1;
          }

          if (index == -1) {
            ///we didn't find the CircleObjectID or the seed; legit new item

            index = 0;

            //start at the bottom and work backwards until we find the right place to insert
            for (CircleObject existing in circleObjects) {
              if (existing.created!.compareTo(newObject.created!) < 0) {
                //&& (existing.id != null || existing.draft == true)) {
                break;
              }

              if (index != null) index++;
            }

            circleObjects.insert(index, newObject);

            // index = 0;
          } else {
            if (index != null) {
              if (circleObjects[index].id == null) {
                DateTime doNoJump = circleObjects[index].created!;

                if (newObject.circle!.memberSessionKeys.isEmpty) {
                  newObject.circle!.memberSessionKeys
                      .addAll(circleObjects[index].circle!.memberSessionKeys);
                }

                circleObjects[index] = newObject;
                circleObjects[index].created = doNoJump;
              } else {
                circleObjects[index] = newObject;
              }
            } else
              debugPrint('index is null');
          }
        }

        CircleObjectCollection.sort(circleObjects);
      }
    }
  }

  ///from InsideCircle
  /*_addCircleObject(CircleObject circleObject, {bool sort = false}) {
    try {
      if (mounted) {
        setState(() {
          ///If there are items from another circle being processed we don't want to process the saved event here.
          if (circleObject.circle!.id != _currentCircle) return;

          ///Test for the CircleObjectID first
          int index = -1;

          if (circleObject.id != null) {
            index = _circleObjects.indexWhere(
                (circleobject) => circleobject.id == circleObject.id);
          }

          if (index == -1) {
            index = _circleObjects.indexWhere(
                (circleobject) => circleobject.seed == circleObject.seed);
          }

          if (index == -1) {
            _circleObjects.insert(0, circleObject);
          } else {
            _circleObjects[index] = circleObject;

            if (sort) {
              ///only sort if the item was saved on the server
              _circleObjects.sort((a, b) {
                return b.created!.compareTo(a.created!);
              });
            }
          }

          _showSpinner = false;
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('InsideCircle._addCircleObject: $err');
      setState(() {
        _showSpinner = false;
      });
    }
  }*/
}
