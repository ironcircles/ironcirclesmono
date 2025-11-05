import 'dart:convert';
import 'dart:ui';

import 'package:ironcirclesapp/models/circle.dart';
import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/user.dart';

UserCircle userCircleFromJson(String str) =>
    UserCircle.fromJson(json.decode(str));

String userCircleToJson(UserCircle data) => json.encode(data.toJson());

class UserCircle {
  String? id;
  Circle? circle;
  User? user;
  User? dm;
  bool dmConnected;
  String? prefName;
  Color? backgroundColor;
  String? background;
  int? backgroundSize;
  bool? hidden;
  bool? guarded;
  bool pinned;
  bool muted;
  bool closed;
  List<int>? guardedPin;
  String? removeFromCache;
  String? hiddenPassphrase;
  int? newItems;
  DateTime? lastAccessed;
  int? pinnedOrder;
  DateTime? lastItemUpdate;
  bool? showBadge;
  String? lastUpdate;
  DateTime? lastUpdateDate;
  String? createdDate;
  String? furnace;
  //RatchetKey nextPublic;
  List<RatchetKey> ratchetKeys;
  RatchetIndex? ratchetIndex;

  UserCircle(
      {this.id,
      this.circle,
      this.user,
      this.dm,
      this.dmConnected = false,
      this.prefName,
      this.background,
      this.backgroundSize,
      this.hidden = false,
      this.guarded = false,
      this.backgroundColor,
      this.removeFromCache,
      this.hiddenPassphrase,
      this.guardedPin,
      this.newItems,
      this.lastAccessed,
      this.pinnedOrder,
      this.lastItemUpdate,
      this.showBadge,
      this.lastUpdate,
      this.lastUpdateDate,
      this.createdDate,
      this.furnace,
      required this.ratchetKeys,
      this.ratchetIndex,
      this.closed = false,
      this.pinned = false,
      this.muted = false});

  factory UserCircle.fromJson(Map<String, dynamic> json) => UserCircle(
        id: json["_id"],
        removeFromCache: json["removeFromCache"],
        circle: json["circle"] == null
            ? null
            //: Circle.fromJson(json["circle"]),
            : (json['circle'].runtimeType == String
                ? Circle(id: json["circle"])
                : Circle.fromJson(json["circle"])),
        user: User.fromJson(json["user"]),
        dm: json["dm"] == null
            ? null
            : json["dm"].runtimeType == String
                ? null
                : User.fromJson(json["dm"]),
        dmConnected: json["dmConnected"] ?? false,
        prefName: json["prefName"],
        furnace: json["furnace"],
        backgroundColor: json["backgroundColor"] == null
            ? null
            : Color(json["backgroundColor"]),
        background: json["background"],
        backgroundSize: json["backgroundSize"] ?? 0,
        hidden: json["hidden"],
        hiddenPassphrase: json["hiddenPassphrase"],
        guarded: json["guarded"],
        guardedPin:
            json["guardedPin"]?.cast<int>(),
        newItems: json["newItems"],
        lastAccessed: json["lastAccessed"] == null
            ? null
            : DateTime.parse(json["lastAccessed"]).toLocal(),
        pinnedOrder: json["pinnedOrder"],
        lastItemUpdate: json["lastItemUpdate"] == null
            ? null
            : DateTime.parse(json["lastItemUpdate"]).toLocal(),
        lastUpdateDate: json["lastUpdate"] == null
            ? null
            : DateTime.parse(json["lastUpdate"]).toLocal(),
        showBadge: json["showBadge"],
        pinned: json["pinned"] ?? false,
        muted: json["muted"],
        closed: json["closed"],
        lastUpdate: json["lastUpdate"],
        createdDate: json["createdDate"],
        ratchetKeys: json["ratchetPublicKeys"] == null
            ? []
            : RatchetKeyCollection.fromJSON(json, "ratchetPublicKeys")
                .ratchetKeys,
        ratchetIndex: json["ratchetIndex"] == null
            ? null
            : RatchetIndex.fromJson(json["ratchetIndex"]),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "circle": circle,
        "user": user,
        "prefName": prefName,
        "dmConnected": dmConnected,
        "backgroundColor":
            backgroundColor?.value,
        "background": background,
        "backgroundSize": backgroundSize ?? 0,
        "furnace": furnace,
        "hidden": hidden,
        "pinned": pinned,
        "muted": muted,
        "closed": closed,
        "hiddenPassphrase": hiddenPassphrase,
        "guarded": guarded,
        "guardedPin": guardedPin,
        "removeFromCache": removeFromCache,
        "newItems": newItems,
        "lastAccessed": lastAccessed,
        "pinnedOrder": pinnedOrder,
        "lastItemUpdate": lastItemUpdate,
        "showBadge": showBadge,
        "lastUpdate": lastUpdate,
        "createdDate": createdDate,
      };
}

class UserCircleCollection {
  final List<UserCircle> userCircles;

  /*
  UserCircleCollection.fromJSON(Map<String, dynamic> json)
      : userCircles = (json['usercircles'] as List)
            .map((json) => UserCircle.fromJson(json))
            .toList();


   */
  UserCircleCollection.fromJSON(Map<String, dynamic> json, String key)
      : userCircles = (json[key] as List)
            .map((json) => UserCircle.fromJson(json))
            .toList();
}
