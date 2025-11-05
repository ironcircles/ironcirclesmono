import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/usercircleenvelope.dart';
import 'package:ironcirclesapp/models/circle.dart';
import 'package:ironcirclesapp/models/usercircle.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';

UserCircleCache userCircleCacheFromJson(String str) =>
    UserCircleCache.fromJson(json.decode(str));

String userCircleCacheToJson(UserCircleCache data) =>
    json.encode(data.toJson());

class UserCircleCache {
  int? pk;
  String? usercircle;
  String? circle;
  String? user;
  String? dmMember;
  String? prefName;
  String? circleName;
  String? background;
  String? circlePath;
  String? circleJson;
  Color? backgroundColor;
  String? masterBackground;
  int? backgroundSize;
  int? masterBackgroundSize;
  DateTime? lastItemUpdate;
  DateTime? lastLocalAccess;
  DateTime? lastUpdate;
  bool? showBadge;
  bool dm;
  bool dmConnected;
  bool? hidden;
  bool? hiddenOpen;
  bool pinned;
  bool? guarded;
  bool muted;
  bool closed;
  bool? guardedOpen;
  String? guardedPin;
  int? userFurnace;
  UserFurnace? furnaceObject;
  Circle? cachedCircle;
  String? crank;
  UserCircleEnvelope? envelope;
  GlobalKey? globalKey;

  //UI only
  bool selected = false;

  UserCircleCache({
    this.pk,
    this.usercircle,
    this.circle,
    this.circleJson,
    this.cachedCircle,
    this.user,
    this.prefName,
    this.circleName,
    this.lastItemUpdate,
    this.lastUpdate,
    this.lastLocalAccess,
    this.backgroundColor,
    //this.lastAccess,
    this.dm = false,
    this.dmConnected = false,
    this.showBadge,
    this.hidden,
    this.hiddenOpen,
    this.pinned = false,
    this.guarded,
    this.muted = false,
    this.closed = false,
    this.guardedOpen,
    this.guardedPin,
    this.userFurnace,
    this.background,
    this.circlePath,
    this.masterBackground,
    this.backgroundSize,
    this.masterBackgroundSize,
    this.crank,
    this.dmMember,
    // this.backgroundPath,
    //this.masterBackgroundPath
  });

  refreshFromUserCircle(UserCircle userCircle, int? userFurnacePK) {
    usercircle = userCircle.id;

    circle = userCircle.circle?.id;
    cachedCircle = userCircle.circle;

    dm = userCircle.circle == null ? false : userCircle.circle!.dm;
    dmConnected = userCircle.dmConnected;
    if (userCircle.dm != null) dmMember = userCircle.dm!.id;
    user = userCircle.user?.id;
    prefName = userCircle.prefName ?? prefName;
    //circleName = userCircle.circle == null ? null : userCircle.circle!.name;  //we don't every want this to be populated from the server (null)
    background = userCircle.background;
    backgroundColor = userCircle.backgroundColor;
    masterBackground =
        userCircle.circle?.background;
    circleJson = json.encode(userCircle.circle!.toJson()).toString();

    backgroundSize = userCircle.backgroundSize ?? 0;
    masterBackgroundSize = userCircle.circle == null
        ? null
        : (userCircle.circle!.backgroundSize ?? 0);

    lastItemUpdate = userCircle.lastItemUpdate;

    if (userCircle.lastAccessed != null && lastLocalAccess != null) {
      ///Don't flip the badge if user was in the Circle after the last local message date, their setLastAccessed might still be processing
      if (userCircle.lastItemUpdate!.compareTo(lastLocalAccess!) > 0) {
        showBadge = userCircle.showBadge;
      } else if (userCircle.showBadge == false) {
        ///unless the badge was turned off serverside, then flip anyways
        showBadge = false;
      }
    } else

      ///normal behavior
      showBadge = userCircle.showBadge;

    lastUpdate = userCircle.lastUpdateDate;

    hidden = userCircle.hidden ?? false;
    guarded = userCircle.guarded ?? false;
    //pinned = userCircle.pinned;
    muted = userCircle.muted;
    closed = userCircle.closed;
    guardedPin = userCircle.guardedPin == null
        ? null
        : pinToString(userCircle.guardedPin!);

    //hiddenOpen = userCircle.hiddenOpen == null ? false : userCircle.hiddenOpen;
    userFurnace = userFurnacePK;
  }

  static String pinToString(List<int> pin) {
    String pinString = '';

    for (int i in pin) {
      pinString = '$pinString-$i';
    }

    return pinString;
  }

  static List<int> stringToPin(String pinString) {
    List<int> pin = [];

    List<String> pinArray = pinString.split('-');

    for (String number in pinArray) {
      if (number.isNotEmpty) pin.add(int.parse(number));
    }

    /*
    pinString.c
    for (int i in pin) {
      pinString = pinString + i.toString();
    }

     */

    return pin;
  }
  //loadFromUserCircle(UserCircle userCircle)

  /*
  factory UserCircleCache.fromUserCircle(UserCircle userCircle) =>
      UserCircleCache(        // pk: json["pk"],
        usercircle: userCircle.id,
        circle: userCircle.circle.id,
        user: userCircle.user.id,
        prefName: userCircle.prefName,
        circleName: userCircle.circle.name,
       // userFurnace: json["userFurnace"],
        background: userCircle.background,
        masterBackground: userCircle.circle.background,
        //backgroundPath: json["backgroundPath"],
        lastItemUpdate: userCircle.lastItemUpdate,
        lastLocalAccess: userCircle.ljson["lastLocalAccess"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastLocalAccess"])
            .toLocal(),
        showBadge: json["showBadge"] == 1 ? true : false,
        hidden: json["hidden"] == 1 ? true : false,);
  */

  factory UserCircleCache.fromJson(Map<String, dynamic> json) =>
      UserCircleCache(
        //pk: json["pk"],
        usercircle: json["usercircle"],
        circle: json["circle"],
        user: json["user"],
        dmMember: json["dmMember"],
        dmConnected: json["dmConnected"] == null
            ? false
            : json["dmConnected"] == 0
                ? false
                : true,
        crank: json["crank"],
        prefName: json["prefName"],
        circleName: json["circleName"],
        userFurnace: json["userFurnace"],
        backgroundColor: json["backgroundColor"] == null
            ? null
            : Color(json["backgroundColor"]),
        background: json["background"],
        masterBackground: json["masterBackground"],
        circleJson: json["circleJson"],
        cachedCircle: json["circleJson"] == null
            ? null
            : Circle.fromJson(_getMap(json["circleJson"])!),
        circlePath: json["circlePath"],
        backgroundSize: json["backgroundSize"] ?? 0,
        masterBackgroundSize: json["masterBackgroundSize"] ?? 0,
        lastItemUpdate: json["lastItemUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastItemUpdate"])
                .toLocal(),
        lastLocalAccess: json["lastLocalAccess"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastLocalAccess"])
                .toLocal(),
        lastUpdate: json["lastUpdate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastUpdate"]).toLocal(),
        dm: json["dm"] == 1 ? true : false,
        showBadge: json["showBadge"] == 1 ? true : false,
        hidden: json["hidden"] == 1 ? true : false,
        hiddenOpen: json["hiddenOpen"] == 1 ? true : false,
        guarded: json["guarded"] == 1 ? true : false,
        pinned: json["pinnedCircle"] == null
            ? false
            : json["pinnedCircle"] == 1
                ? true
                : false,
        muted: json["muted"] == 1 ? true : false,
        closed: json["closed"] == null
            ? false
            : json["closed"] == 1
                ? true
                : false,
        guardedPin: json["guardedPinString"],
        guardedOpen: json["guardedOpen"] == 1 ? true : false,
      );

  static Map<String, dynamic>? _getMap(String val) {
    return json.decode(val);
  }

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "usercircle": usercircle,
        "circle": circle,
        "user": user,
        "dmMember": dmMember,
        "prefName": prefName,
        "circleName": circleName,
        "crank": crank,
        "userFurnace": userFurnace,
        "backgroundColor":
            backgroundColor?.value,
        "background": background,
        "masterBackground": masterBackground,
        "circleJson": circleJson,

        "backgroundSize": backgroundSize ?? 0,
        "masterBackgroundSize": masterBackgroundSize ?? 0,

        "circlePath": circlePath,
        // "backgroundPath": backgroundPath,
        // "masterBackgroundPath": masterBackgroundPath,
        "lastItemUpdate": lastItemUpdate?.millisecondsSinceEpoch,
        "lastLocalAccess": lastLocalAccess?.millisecondsSinceEpoch,
        "lastUpdate":
            lastUpdate?.millisecondsSinceEpoch,
        "showBadge": showBadge == null ? 0 : (showBadge! ? 1 : 0),
        "hidden": hidden == null ? 0 : (hidden! ? 1 : 0),
        "hiddenOpen": hiddenOpen == null ? 0 : (hiddenOpen! ? 1 : 0),
        "guarded": guarded == null ? 0 : (guarded! ? 1 : 0),
        "dm": dm ? 1 : 0,
        "dmConnected": dmConnected ? 1 : 0,
        "pinnedCircle": pinned ? 1 : 0,
        "muted": muted ? 1 : 0,
        "closed": closed ? 1 : 0,
        "guardedPinString": guardedPin,
        "guardedOpen": guardedOpen == null ? 0 : (guardedOpen! ? 1 : 0),
      };

  bool checkPin(List<int> pinToCheck) {
    bool retValue = false;

    if (guardedPin == null)
      throw ('UserCircleCache.pinToCheck: guardedPin == null');

    //List<int> pin = guardedPin!.codeUnits;

    if (listEquals(stringToPin(guardedPin!), pinToCheck)) retValue = true;

    return retValue;
  }

  GlobalKey getGlobalKey(){
    globalKey ??= GlobalKey();
    return globalKey!;

  }
}

class UserCircleCacheCollection {
  final List<UserCircleCache> userCircles;

  UserCircleCacheCollection.fromJSON(Map<String, dynamic> json)
      : userCircles = (json['usercircles'] as List)
            .map((json) => UserCircleCache.fromJson(json))
            .toList();
}
