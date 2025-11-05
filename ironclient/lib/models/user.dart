import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/avatar.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ironcointransaction.dart';

class User {
  String? id;
  int? pk;
  String? username;
  Avatar? avatar;
  String? devices;
  String? token;
  String? lastUpdate;
  String? created;
  Color? messageColor;
  UserFurnace? userFurnace;
  int? securityMinPassword;
  int? securityDaysPasswordValid;
  bool? passwordExpired;
  bool accountRecovery;
  List<User>? allowedList;
  List<User>? blockedList;
  bool? blockedEnabled;
  bool? keyGen;
  bool? autoKeychainBackup;
  bool? submitLogs;
  bool allowClosed;
  DateTime? tos;
  int? accountType;
  String? signature;
  int role;
  bool passwordBeforeChange;
  bool minor;
  bool reservedUsername;
  bool lockedOut;
  bool? clearPattern;
  bool joinBeta;
  bool? removeFromCache;

  // int ironCoin;
  // List<CoinPayment>? coinLedger;

  //bool needPin = false;

  ///place holder for login and registration
  late List<UserCircle> userCircles;
  late List<CircleObject> circleObjects;

  User({
    this.id,
    this.pk,
    this.username,
    this.avatar,
    this.devices,
    this.token,
    this.lastUpdate,
    this.created,
    this.securityMinPassword,
    this.securityDaysPasswordValid,
    this.passwordExpired,
    this.allowedList,
    this.blockedList,
    this.accountRecovery = false,
    this.blockedEnabled,
    this.keyGen,
    this.autoKeychainBackup,
    this.submitLogs,
    this.signature,
    this.clearPattern,
    this.tos,
    this.accountType,
    this.allowClosed = false,
    this.passwordBeforeChange = false,
    this.minor = false,
    this.reservedUsername = false,
    this.role = Role.MEMBER,
    this.lockedOut = false,
    this.removeFromCache,
    this.joinBeta = false,
    // this.ironCoinWallet,
  }) {
    // ironCoinWallet ??= IronCoinWallet();
    userCircles = [];
    circleObjects = [];
  }

  String getUsernameAndAlias(GlobalState globalState) {
    String alias = Member.returnAlias(id!, globalState.members);

    //return username! + (alias.isEmpty ? '' : ' ($alias)');
    return alias.isEmpty ? username ?? '' : '$alias ($username)';
  }

  Color getColor(GlobalState globalState) {
    return Member.returnColor(id!, globalState.members);
  }

  static List<IronCoinTransaction> _getIronCoinLedger(
      Map<String, dynamic> json, String value) {
    List<IronCoinTransaction> retValue = [];
    try {
      if (json.containsKey(value)) {
        retValue =
            IronCoinTransactionCollection.fromJSON(json, value).transactions;
      }
    } catch (err) {
      debugPrint(err.toString());
    }
    return retValue;
  }

  static List<User> _determineIfPopulated(
      Map<String, dynamic> json, String value) {
    List<User> retValue = [];
    try {
      if (json.containsKey(value)) {
        retValue = UserCollection.fromJSON(json, value).users;
      }
    } catch (err) {
      //TODO this error needs to be handled, blockList throws an error if not populated
      //debugPrint(value);
      // debugPrint(json);
      //json[value].runtimeType;
      // LogBloc.insertError(err, trace);
      //debugPrint(err);
    }
    return retValue;
  }

  factory User.fromJson(Map<String, dynamic> jsonMap) => User(
        username: jsonMap['username'],
        id: jsonMap['_id'],
        pk: jsonMap['pk'],
        minor: jsonMap['minor'] == null ? false : jsonMap["minor"],
        accountType: jsonMap['accountType'],
        clearPattern: jsonMap['clearPattern'],
        role: jsonMap['role'] ?? Role.MEMBER,
        keyGen: jsonMap['keyGen'],
        removeFromCache: jsonMap['removeFromCache'],
        joinBeta: jsonMap['joinBeta'] ?? false,
        autoKeychainBackup: jsonMap.containsKey('autoKeychainBackup')
            ? jsonMap['autoKeychainBackup']
            : false,
        passwordBeforeChange: jsonMap.containsKey('passwordBeforeChange')
            ? jsonMap['passwordBeforeChange']
            : false,
        submitLogs:
            jsonMap.containsKey('submitLogs') ? jsonMap['submitLogs'] : false,
        avatar: jsonMap.containsKey('avatar')
            ? jsonMap['avatar'] == null
                ? null
                : Avatar.fromJson(jsonMap['avatar'])
            : null,
        devices: jsonMap.containsKey('devices')
            ? json.encode(jsonMap['devices'])
            : null,
        token: jsonMap.containsKey('token') ? jsonMap['token'] : null,
        tos: jsonMap["tos"] == null
            ? null
            : DateTime.parse(jsonMap["tos"]).toLocal(),
        lastUpdate:
            jsonMap.containsKey('lastUpdate') ? jsonMap['lastUpdate'] : null,
        created: jsonMap.containsKey('created')
            ? (jsonMap["created"]) == null
                ? null
                : DateTime.parse(jsonMap["created"]).toLocal().toString()
            : null,
        // ironCoinWallet: IronCoinWallet.fromJson(jsonMap["ironCoinWallet"]),
        signature: jsonMap['signature'],
        securityMinPassword: jsonMap["securityMinPassword"],
        securityDaysPasswordValid: jsonMap["securityDaysPasswordValid"],
        accountRecovery: jsonMap["accountRecovery"] ?? false,
        passwordExpired: jsonMap["passwordExpired"],
        lockedOut: jsonMap["lockedOut"] ?? false,
        blockedEnabled: jsonMap["blockedEnabled"] ?? false,
        reservedUsername: jsonMap["reservedUsername"] ?? false,
        allowedList: _determineIfPopulated(jsonMap, "allowedList"),
        blockedList: _determineIfPopulated(jsonMap, "blockedList"),
        allowClosed:
            jsonMap.containsKey('allowClosed') ? jsonMap['allowClosed'] : false,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'keyGen': keyGen,
        'accountType': accountType,
        'role': role,
        'removeFromCache': removeFromCache,
        'autoKeychainBackup': autoKeychainBackup,
        'passwordBeforeChange': passwordBeforeChange,
        'submitLogs': submitLogs,
        'avatar': avatar?.toJson(),
        'devices': devices,
        'lastUpdate': lastUpdate,
        "tos": tos?.toUtc().toString(),
        'created': created,
        'signature': signature,
        'accountRecovery': accountRecovery,
        "securityMinPassword": securityMinPassword,
        "securityDaysPasswordValid": securityDaysPasswordValid,
        "passwordExpired": passwordExpired,
        "allowClosed": allowClosed,
        "reservedUsername": reservedUsername,
        // "ironCoin": ironCoin,
        // "coinLedger": coinLedger,
      };

  Map<String, dynamic> toJsonReduced() => {
    '_id': id,
    'username': username,
  };
}

class UserCollection {
  final List<User> users;

  UserCollection.fromJSON(Map<String, dynamic> json, String key)
      : users = (json[key] as List).map((json) => User.fromJson(json)).toList();
}

class UserListItem {
  int value;
  User user;

  UserListItem(this.value, this.user);
}
