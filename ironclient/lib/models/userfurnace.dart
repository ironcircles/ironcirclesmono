import 'dart:convert';
import 'dart:io';

import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/user.dart';

enum NetworkType { FORGE, HOSTED, SELF_HOSTED }

UserFurnace userFurnaceFromJson(String str) =>
    UserFurnace.fromJson(json.decode(str));

String userFurnaceToJson(UserFurnace data) => json.encode(data.toJson());

class UserFurnace {
  int? pk;
  String? authServerUserid;
  String? id;
  String? userid;
  String? username;
  Avatar? avatar;
  String? token;
  String? forgeToken;
  String? forgeUserId;
  String? alias;
  String? hostedId;
  String? hostedFurnaceImageId;
  String? hostedName;
  String? hostedAccessCode;
  String? url;
  String? apikey;
  String? password;
  bool discoverable;
  bool adultOnly;
  bool memberAutonomy;
  String? description;
  String? link;
  String? pin;
  bool? authServer;
  String? furnaceJson;
  bool? connected;
  bool? guarded;
  bool? transparency;
  int? lastLogin;
  int? invitations;
  int? actionsRequired;
  int? actionsRequiredLowPriority;
  bool? autoKeychainBackup;
  NetworkType type; // = NetworkType.HOSTED;
  bool newNetwork = false;
  int accountType;
  int role;
  String? linkedUser;
  bool enableWall;
  String? passwordHash;
  String? passwordNonce;

  ///UI only
  User? user;
  File? image;
  File? userAvatar;

  UserFurnace(
      {this.pk,
      this.id,
      this.userid,
      this.linkedUser,
      this.username,
      this.avatar,
      this.token,
      this.forgeToken,
      this.forgeUserId,
      this.alias,
      this.hostedId,
      this.hostedFurnaceImageId,
      this.hostedName,
      this.hostedAccessCode,
      this.url,
      this.apikey,
      this.furnaceJson,
      this.authServerUserid,
      this.authServer,
      this.passwordHash,
      this.passwordNonce,
      this.connected,
      this.guarded = false,
      this.transparency = false,
      this.type = NetworkType.HOSTED,
      this.lastLogin,
      this.password,
      this.discoverable = false,
      this.adultOnly = false,
      this.memberAutonomy = true,
      this.enableWall = false,
      this.description,
      this.link,
      this.pin,
      this.autoKeychainBackup,
      this.invitations = 0,
      this.actionsRequired = 0,
      this.actionsRequiredLowPriority = 0,
      this.accountType = AccountType.FREE,
      this.role = Role.MEMBER});

  UserFurnace.init(User user)
      : accountType = AccountType.FREE,
        role = Role.MEMBER,
        //standalone = false,
        enableWall = false,
        discoverable = false,
        type = NetworkType.HOSTED,
        adultOnly = false,
        memberAutonomy = true {
    username = user.username;
    userid = user.id;
    token = user.token;
    accountType = user.accountType!;
    role = user.role;
    //this.type = false;
  }

  static UserFurnace initForge(bool authServer) {
    UserFurnace localFurnace = UserFurnace();
    localFurnace.authServer = authServer;
    localFurnace.hostedId = '';
    localFurnace.hostedFurnaceImageId = '';
    localFurnace.hostedName = '';
    localFurnace.type = NetworkType.FORGE;
    localFurnace.discoverable = false;
    localFurnace.adultOnly = false;
    localFurnace.memberAutonomy = true;
    localFurnace.description = '';
    localFurnace.link = '';
    localFurnace.alias = 'IronForge';
    localFurnace.id = 'IronForge';
    localFurnace.url = urls.forge;
    localFurnace.apikey = urls.forgeAPIKEY;

    return localFurnace;
  }

  UserFurnace.initFurnace(
      {this.authServerUserid,
      this.username,
      this.password,
      this.pin,
      this.alias,
      this.url,
      this.apikey,
      this.authServer})
      : accountType = AccountType.FREE,
        role = Role.MEMBER,
        discoverable = false,
        type = NetworkType.HOSTED,
        adultOnly = false,
        memberAutonomy = true,
        enableWall = false {
    authServerUserid = authServerUserid;
    discoverable = discoverable;
    username = username;
    password = password;
    description = description;
    link = link;
    alias = alias;
    url = url;
    apikey = apikey;
    authServer = authServer;
    guarded = false;
    transparency = false;
    accountType = AccountType.FREE;
    role = Role.MEMBER;
    // this.authServer = false;
    connected = false;
    //this.type = false;
  }

  factory UserFurnace.fromJson(Map<String, dynamic> jsonMap) => UserFurnace(
        pk: jsonMap["pk"],
        id: jsonMap["id"],
        userid: jsonMap["userid"],
        linkedUser: jsonMap["linkedUser"],
        username: jsonMap["username"],
        avatar: jsonMap["avatarJson"] == null
            ? null
            : Avatar.fromJson(json.decode(jsonMap["avatarJson"])),
        token: jsonMap["token"],
        forgeToken: jsonMap["forgeToken"],
        forgeUserId: jsonMap["forgeUserId"],
        alias: jsonMap["alias"],
        discoverable: jsonMap["discoverable"] == 1 ? true : false,
        enableWall: jsonMap["enableWall"] == 1 ? true : false,
        description: jsonMap["description"],
        link: jsonMap["link"],
        adultOnly: jsonMap["adultOnly"] == 1 ? true : false,
        memberAutonomy: jsonMap["memberAutonomy"] == 1 ? true : false,
        //hostedId: jsonMap["hostedId"],
        type: jsonMap["type"] == null
            ? jsonMap["hostedName"] == IRONFORGE
                ? NetworkType.FORGE
                : NetworkType.HOSTED
            : NetworkType.values[jsonMap["type"]],
        hostedFurnaceImageId: jsonMap["hostedFurnaceImageId"],
        hostedName: jsonMap["hostedName"],
        hostedAccessCode: jsonMap["hostedAccessCode"],
        hostedId: jsonMap["hostedId"],
        accountType: jsonMap["accountType"] ?? AccountType.FREE,
        role: jsonMap["role"] ?? Role.MEMBER,
        url: jsonMap["url"],
        autoKeychainBackup: jsonMap["autoKeychainBackup"],
        furnaceJson: jsonMap["furnaceJson"],
        apikey: jsonMap["apikey"],
        authServerUserid: jsonMap["authServerUserid"],
        passwordHash: jsonMap["passwordHash"],
        passwordNonce: jsonMap["passwordNonce"],
        invitations: jsonMap["invitations"],
        actionsRequired: jsonMap["actionsRequired"],
        actionsRequiredLowPriority: jsonMap["actionsRequiredLowPriority"],
        authServer: jsonMap["authServer"] == 1 ? true : false,
        connected: jsonMap["connected"] == 1 ? true : false,
        guarded: jsonMap["guarded"] == 1 ? true : false,
        transparency: jsonMap["transparency"] == 1 ? true : false,
        password: jsonMap[
            "generatedPassword"], //only used for generated passwords during registration, not the users pass/pin
        pin: jsonMap[
            "generatedPin"], //only used for generated passwords during registration, not the users pass/pin
        lastLogin: jsonMap["lastLogin"],
      );

  Map<String, dynamic> toJson() => {
        //"pk": pk,
        "id": id,
        "userid": userid,
        "linkedUser": linkedUser,
        "username": username,
        "avatarJson": avatar == null ? null : json.encode(avatar!.toJson()),
        "token": token,
        "forgeToken": forgeToken,
        "forgeUserId": forgeUserId,
        "alias": alias,
        "discoverable": discoverable ? 1 : 0,
        "enableWall": enableWall ? 1 : 0,
        "adultOnly": adultOnly ? 1 : 0,
        "memberAutonomy": memberAutonomy ? 1 : 0,
        "description": description,
        "link": link,
        "hostedId": hostedId,
        "hostedFurnaceImageId": hostedFurnaceImageId,
        "hostedName": hostedName,
        "hostedAccessCode": hostedAccessCode,
        "url": url,
        "accountType": accountType,
        "role": role,
        "apikey": apikey,
        "type": type.index,
        //"autoKeychainBackup": autoKeychainBackup,
        "furnaceJson": furnaceJson,
        "authServerUserid": authServerUserid,
        "passwordHash": passwordHash,
        "passwordNonce": passwordNonce,
        "invitations": invitations,
        "actionsRequired": actionsRequired,
        "actionsRequiredLowPriority": actionsRequiredLowPriority,
        "authServer": authServer! ? 1 : 0,
        "connected": connected! ? 1 : 0,
        "guarded": guarded! ? 1 : 0,
        "transparency": transparency! ? 1 : 0,
        "lastLogin": lastLogin,
      };

  ///this should only be used for brand users, once they enter their own pass/pin, the pass pin fields are deleted
  Map<String, dynamic> toJsonWithGeneratedPassPin() => {
        "pk": pk,
        "id": id,
        "userid": userid,
        "linkedUser": linkedUser,
        "username": username,
        "avatarJson": avatar == null ? null : json.encode(avatar!.toJson()),
        "token": token,
        "forgeToken": forgeToken,
        "forgeUserId": forgeUserId,
        "alias": alias,
        "discoverable": discoverable ? 1 : 0,
        "enableWall": enableWall ? 1 : 0,
        "adultOnly": adultOnly ? 1 : 0,
        "memberAutonomy": memberAutonomy ? 1 : 0,
        "description": description,
        "link": link,
        "hostedId": hostedId,
        "hostedFurnaceImageId": hostedFurnaceImageId,
        "hostedName": hostedName,
        "hostedAccessCode": hostedAccessCode,
        "url": url,
        "accountType": accountType,
        "type": type.index,
        "role": role,
        "apikey": apikey,
        //"autoKeychainBackup": autoKeychainBackup,
        "furnaceJson": furnaceJson,
        "authServerUserid": authServerUserid,
        "passwordHash": passwordHash,
        "passwordNonce": passwordNonce,
        "invitations": invitations,
        "actionsRequired": actionsRequired,
        "actionsRequiredLowPriority": actionsRequiredLowPriority,
        "authServer": authServer! ? 1 : 0,
        "connected": connected! ? 1 : 0,
        "guarded": guarded! ? 1 : 0,
        "transparency": transparency! ? 1 : 0,
        "lastLogin": lastLogin,
        'generatedPassword': password ?? '',
        'generatedPin': pin ?? '',
      };

  Map<String, dynamic> toFurnaceJson() => {
        "pk": pk,
        "id": id,
        "userid": userid,
        "linkedUser": linkedUser,
        "username": username,
        "avatarJson": avatar == null ? null : json.encode(avatar!.toJson()),
        "token": token,
        "forgeToken": forgeToken,
        "forgeUserId": forgeUserId,
        "alias": alias,
        "discoverable": discoverable ? 1 : 0,
        "enableWall": enableWall ? 1 : 0,
        "adultOnly": adultOnly ? 1 : 0,
        "memberAutonomy": memberAutonomy,
        "description": description,
        "link": link,
        "accountType": accountType,
        "role": role,
        "type": type.index,
        "hostedId": hostedId,
        "hostedFurnaceImageId": hostedFurnaceImageId,
        "hostedName": hostedName,
        "hostedAccessCode": hostedAccessCode,
        "url": url,
        "apikey": apikey,
        //"furnaceJson": furnaceJson,
        "autoKeychainBackup": autoKeychainBackup,
        "authServerUserid": authServerUserid,
        "passwordHash": passwordHash,
        "passwordNonce": passwordNonce,
        "invitations": invitations,
        "actionsRequired": actionsRequired,
        "actionsRequiredLowPriority": actionsRequiredLowPriority,
        "authServer": authServer! ? 1 : 0,
        "connected": connected! ? 1 : 0,
        "guarded": guarded! ? 1 : 0,
        "transparency": transparency! ? 1 : 0,
        "lastLogin": lastLogin,
      };

  populateNonColumn() {
    Map<String, dynamic> map = json.decode(furnaceJson!);

    UserFurnace userFurnace = UserFurnace.fromJson(map);

    autoKeychainBackup = userFurnace.autoKeychainBackup;
  }

  static UserFurnace deepCopy(UserFurnace userFurnace) {
    return UserFurnace(
      pk: userFurnace.pk,
      id: userFurnace.id,
      userid: userFurnace.userid,
      linkedUser: userFurnace.linkedUser,
      username: userFurnace.username,
      token: userFurnace.token,
      forgeToken: userFurnace.forgeToken,
      forgeUserId: userFurnace.forgeUserId,
      //standalone: userFurnace.standalone,
      alias: userFurnace.alias,
      discoverable: userFurnace.discoverable,
      enableWall: userFurnace.enableWall,
      adultOnly: userFurnace.adultOnly,
      memberAutonomy: userFurnace.memberAutonomy,
      description: userFurnace.description,
      link: userFurnace.link,
      accountType: userFurnace.accountType,
      role: userFurnace.role,
      type: userFurnace.type,
      hostedId: userFurnace.hostedId,
      hostedFurnaceImageId: userFurnace.hostedFurnaceImageId,
      hostedName: userFurnace.hostedName,
      hostedAccessCode: userFurnace.hostedAccessCode,
      url: userFurnace.url,
      apikey: userFurnace.apikey,
      autoKeychainBackup: userFurnace.autoKeychainBackup,
      authServerUserid: userFurnace.authServerUserid,
      passwordHash: userFurnace.passwordHash,
      passwordNonce: userFurnace.passwordNonce,
      invitations: userFurnace.invitations,
      actionsRequired: userFurnace.actionsRequired,
      actionsRequiredLowPriority: userFurnace.actionsRequiredLowPriority,
      authServer: userFurnace.authServer,
      connected: userFurnace.connected,
      guarded: userFurnace.guarded,
      transparency: userFurnace.transparency,
      lastLogin: userFurnace.lastLogin,
    );
  }
}
