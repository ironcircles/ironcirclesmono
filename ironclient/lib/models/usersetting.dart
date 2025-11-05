import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/darktheme.dart';
import 'package:ironcirclesapp/screens/themes/lighttheme.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/table_usersetting.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';

class UserSetting {
  int? pk;
  String id;
  String username;
  int accountType;
  //int role;
  int theme;
  int lastColorIndex;
  double fontSize;
  bool unreadFeedOn;
  bool allowHidden;
  bool submitLogs;
  bool autoKeychainBackup;
  String backupKey;
  bool accountRecovery;
  bool minor;
  DateTime? lastAccessedDate;
  bool reservedUsername;
  bool passwordHelpersSet;
  DateTime? lastLogSubmission;
  String? lastSharedToNetwork;
  String? lastSharedToCircle;
  bool allowLastSharedToCircle;
  bool passwordBeforeChange;
  bool askedToGuardVault;
  bool firstTimeInCircle;
  bool firstTimeInFeed;
  DateTime? lastFull;
  DateTime? lastIncremental;
  String? patternPinString;
  int? attempts;
  DateTime? lastAttempt;
  double? ironCoin;
  bool sortAlpha;

  UserSetting(
      {this.pk,
      required this.id,
      required this.username,
      this.accountType = AccountType.FREE,
      //this.role = Role.MEMBER,
      this.theme = ThemeSetting.DARK,
      this.lastColorIndex = 0,
      this.fontSize = 16,
      this.unreadFeedOn = true,
      this.allowHidden = false,
      this.submitLogs = false,
      this.lastAccessedDate,
      this.autoKeychainBackup = true,
      this.backupKey = '',
      this.accountRecovery = false,
      this.patternPinString,
      this.attempts,
      this.lastAttempt,
      this.minor = true,
      this.reservedUsername = false,
      this.passwordHelpersSet = false,
      this.passwordBeforeChange = false,
      this.lastLogSubmission,
      this.lastSharedToNetwork,
      this.lastSharedToCircle,
      this.allowLastSharedToCircle = true,
      this.askedToGuardVault = true,
      this.firstTimeInCircle = true,
      this.firstTimeInFeed = true,
      this.lastFull,
      this.lastIncremental,
      this.sortAlpha = false,
      this.ironCoin});

  List<int> stringToPin(String pinString) {
    List<int> pin = [];

    List<String> pinArray = pinString.split('-');

    for (String number in pinArray) {
      if (number.isNotEmpty) pin.add(int.parse(number));
    }

    return pin;
  }

  String pinToString(List<int> pin) {
    String pinString = '';

    for (int i in pin) {
      pinString = '$pinString-$i';
    }

    return pinString;
  }

  clearPatternLockout() async {
    attempts = 0;
    lastAttempt = null;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.attempts: attempts,
      TableUserSetting.lastAttempt: lastAttempt,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setPatternLockout() async {
    attempts = 5;
    lastAttempt = DateTime.now();

    Map<String, dynamic> reducedMap = {
      TableUserSetting.attempts: attempts,
      TableUserSetting.lastAttempt: lastAttempt!.millisecondsSinceEpoch,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setAttempts(int pAttempts) async {
    attempts = pAttempts;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.attempts: attempts,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setPatternPinString(List<int> patternPinString) async {
    this.patternPinString = pinToString(patternPinString);

    Map<String, dynamic> reducedMap = {
      TableUserSetting.patternPinString: this.patternPinString,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setSortAlpha(bool sortAlpha) async {
    this.sortAlpha = sortAlpha;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.sortAlpha: this.sortAlpha,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  inactivePatternPinString() async {
    patternPinString = null;
    attempts = 0;
    lastAttempt = null;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.patternPinString: patternPinString,
      TableUserSetting.attempts: attempts,
      TableUserSetting.lastAttempt: lastAttempt,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setLastColorIndex(int pLastColorIndex, {bool save = true}) async {
    if (pLastColorIndex > globalState.theme.messageColorOptions!.length - 1)
      lastColorIndex = 0;
    else
      lastColorIndex = pLastColorIndex;

    debugPrint('lastColorIndex: $lastColorIndex');
    debugPrint('lastColorIndex: ${globalState.userSetting.lastColorIndex}');

    if (save) {
      Map<String, dynamic> reducedMap = {
        TableUserSetting.lastColorIndex: lastColorIndex
      };
      await TableUserSetting.upsertReducedMap(this, reducedMap);
    }
  }

  setUnreadFeedOn(bool unreadFeedOn) async {
    this.unreadFeedOn = unreadFeedOn;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.unreadFeedOn: this.unreadFeedOn ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setAskedToGuardVault(bool value) async {
    askedToGuardVault = value;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.askedToGuardVault: askedToGuardVault ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setFirstTimeInCircle(bool value) async {
    firstTimeInCircle = value;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.firstTimeInCircle: firstTimeInCircle ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setFirstTimeInFeed(bool value) async {
    firstTimeInFeed = value;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.firstTimeInFeed: firstTimeInFeed ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setLastSharedTo(bool allowLastSharedToCircle, String? lastSharedToNetwork,
      String? lastSharedToCircle) async {
    this.allowLastSharedToCircle = allowLastSharedToCircle;
    this.lastSharedToNetwork = lastSharedToNetwork;
    this.lastSharedToCircle = lastSharedToCircle;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.allowLastSharedToCircle:
          this.allowLastSharedToCircle ? 1 : 0,
      TableUserSetting.lastSharedToNetwork: this.lastSharedToNetwork,
      TableUserSetting.lastSharedToCircle: this.lastSharedToCircle
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setTheme(int theme) async {
    this.theme = theme;
    Map<String, dynamic> reducedMap = {TableUserSetting.theme: this.theme};
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setLastLogSubmission(DateTime lastLogSubmission) async {
    this.lastLogSubmission = lastLogSubmission;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.lastLogSubmission:
          this.lastLogSubmission?.millisecondsSinceEpoch,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setAccountRecovery(bool accountRecovery) async {
    this.accountRecovery = accountRecovery;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.accountRecovery: this.accountRecovery ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setSubmitLogs(bool submitLogs) async {
    this.submitLogs = submitLogs;

    Map<String, dynamic> reducedMap = {
      TableUserSetting.submitLogs: this.submitLogs ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setFontSize(double fontSize) async {
    this.fontSize = fontSize;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.fontSize: this.fontSize
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setLastFull(DateTime lastFull) async {
    this.lastFull = lastFull;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.lastFull: this.lastFull?.millisecondsSinceEpoch
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setLastIncremental(DateTime lastIncremental) async {
    this.lastIncremental = lastIncremental;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.lastIncremental:
          this.lastIncremental?.millisecondsSinceEpoch
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setBackupKey(String backupKey) async {
    this.backupKey = backupKey;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.backupKey: this.backupKey
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setPasswordBeforeChange(bool passwordBeforeChange) async {
    this.passwordBeforeChange = passwordBeforeChange;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.passwordBeforeChange: this.passwordBeforeChange ? 1 : 0,
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  setAccountType(int accountType) async {
    this.accountType = accountType;
    Map<String, dynamic> reducedMap = {
      TableUserSetting.accountType: this.accountType
    };
    await TableUserSetting.upsertReducedMap(this, reducedMap);
  }

  factory UserSetting.fromJson(Map<String, dynamic> json) => UserSetting(
        pk: json['pk'],
        id: json['id'],
        username: json['username'],
        accountType: json['accountType'],
        //role: json['role'],
        accountRecovery: json['accountRecovery'] == 0 ? false : true,
        theme: json['theme'],
        lastColorIndex: json['lastColorIndex'],
        fontSize: json['fontSize'],
        backupKey: json['backupKey'],
        unreadFeedOn: json['unreadFeedOn'] == 0 ? false : true,
        lastAccessedDate: json["lastAccessedDate"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastAccessedDate"])
                .toLocal(),
        allowHidden: json['allowHidden'] == 0 ? false : true,
        askedToGuardVault:
            json['askedToGuardVault'] == null || json['askedToGuardVault'] == 1
                ? true
                : false,
        firstTimeInCircle:
            json['firstTimeInCircle'] == null || json['firstTimeInCircle'] == 1
                ? true
                : false,
        firstTimeInFeed:
            json['firstTimeInFeed'] == null || json['firstTimeInFeed'] == 1
                ? true
                : false,
        submitLogs: json['submitLogs'] == 0 ? false : true,
        autoKeychainBackup: json['autoKeychainBackup'] == 0 ? false : true,
        minor: json['minor'] == 0 ? false : true,
        reservedUsername: json['reservedUsername'] == 0 ? false : true,
        passwordHelpersSet: json['passwordHelpersSet'] == 0 ? false : true,
        passwordBeforeChange: json['passwordBeforeChange'] == 0 ? false : true,
        lastLogSubmission: json.containsKey('lastLogSubmission')
            ? (json["lastLogSubmission"]) == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(json["lastLogSubmission"])
                    .toLocal()
            : null,
        lastSharedToNetwork: json['lastSharedToNetwork'],
        lastSharedToCircle: json['lastSharedToCircle'],
        allowLastSharedToCircle:
            json['allowLastSharedToCircle'] == 0 ? false : true,
        lastFull: json["lastFull"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastFull"]).toLocal(),
        lastIncremental: json["lastIncremental"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastIncremental"])
                .toLocal(),
        attempts: json['attempts'],
        lastAttempt: json["lastAttempt"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["lastAttempt"])
                .toLocal(),
        patternPinString: json['patternPinString'],
        ironCoin: json['ironCoin'] == null ? 0 : json['ironCoin'].toDouble(),
        sortAlpha:
            json['sortAlpha'] == null || json['sortAlpha'] == 0 ? false : true,
      );

  Map<String, dynamic> toJsonForLogging() => {
        'id': id,
        'username': username,
        'accountType': accountType,
        'accountRecovery': accountRecovery ? 1 : 0,
        'theme': theme,
        'lastColorIndex': lastColorIndex,
        'fontSize': fontSize,
        //'backupKey': backupKey,
        'unreadFeedOn': unreadFeedOn ? 1 : 0,
        'allowHidden': allowHidden ? 1 : 0,
        'submitLogs': submitLogs ? 1 : 0,
        'autoKeychainBackup': autoKeychainBackup ? 1 : 0,
        'lastAccessedDate': DateTime.now().millisecondsSinceEpoch,
        'minor': minor ? 1 : 0,
        'askedToGuardVault': askedToGuardVault ? 1 : 0,
        'firstTimeInCircle': firstTimeInCircle ? 1 : 0,
        'firstTimeInFeed': firstTimeInFeed ? 1 : 0,
        'reservedUsername': reservedUsername ? 1 : 0,
        'passwordBeforeChange': passwordBeforeChange ? 1 : 0,
        'passwordHelpersSet': passwordHelpersSet ? 1 : 0,
        'lastLogSubmission': lastLogSubmission?.millisecondsSinceEpoch,
        'lastSharedToNetwork': lastSharedToNetwork,
        'lastSharedToCircle': lastSharedToCircle,
        'allowLastSharedToCircle': allowLastSharedToCircle ? 1 : 0,
        "lastFull": lastFull?.millisecondsSinceEpoch,
        "lastIncremental": lastIncremental?.millisecondsSinceEpoch,
        'patternPinString': patternPinString,
        'attempts': attempts,
        'lastAttempt': lastAttempt?.millisecondsSinceEpoch,
        'ironCoin': ironCoin,
        'sortAlpha': sortAlpha ? 1 : 0
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'accountType': accountType,
        //'role': role,
        'accountRecovery': accountRecovery ? 1 : 0,
        'theme': theme,
        'lastColorIndex': lastColorIndex,
        'fontSize': fontSize,
        'backupKey': backupKey,
        'unreadFeedOn': unreadFeedOn ? 1 : 0,
        'allowHidden': allowHidden ? 1 : 0,
        'submitLogs': submitLogs ? 1 : 0,
        'autoKeychainBackup': autoKeychainBackup ? 1 : 0,
        'lastAccessedDate': DateTime.now().millisecondsSinceEpoch,
        'minor': minor ? 1 : 0,
        'askedToGuardVault': askedToGuardVault ? 1 : 0,
        'firstTimeInCircle': firstTimeInCircle ? 1 : 0,
        'firstTimeInFeed': firstTimeInFeed ? 1 : 0,
        'reservedUsername': reservedUsername ? 1 : 0,
        'passwordBeforeChange': passwordBeforeChange ? 1 : 0,
        'passwordHelpersSet': passwordHelpersSet ? 1 : 0,
        'lastLogSubmission': lastLogSubmission?.millisecondsSinceEpoch,
        'lastSharedToNetwork': lastSharedToNetwork,
        'lastSharedToCircle': lastSharedToCircle,
        'allowLastSharedToCircle': allowLastSharedToCircle ? 1 : 0,
        "lastFull": lastFull?.millisecondsSinceEpoch,
        "lastIncremental": lastIncremental?.millisecondsSinceEpoch,
        'patternPinString': patternPinString,
        'attempts': attempts,
        'lastAttempt': lastAttempt?.millisecondsSinceEpoch,
        'ironCoin': ironCoin,
        'sortAlpha': sortAlpha ? 1 : 0
      };

  static Future<String> getSafeBackupKey(
      UserSetting userSetting, String user) async {
    try {
      if (userSetting.backupKey.isNotEmpty) {
        return userSetting.backupKey;
      } else {
        UserSetting? cachedSetting = await TableUserSetting.read(user);

        if (cachedSetting != null) {
          return cachedSetting.backupKey;
        }
      }

      throw ('No backup key found');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);

      return '';
    }
  }

  static refreshFromCache(UserSetting userSetting, User user) async {
    try {
      UserSetting? cachedSetting = await TableUserSetting.read(user.id!);
      if (cachedSetting != null) {
        userSetting.theme = cachedSetting.theme;
        userSetting.lastFull = cachedSetting.lastFull;
        userSetting.lastIncremental = cachedSetting.lastIncremental;
        userSetting.lastColorIndex = cachedSetting.lastColorIndex;
        userSetting.backupKey = cachedSetting.backupKey;
        userSetting.fontSize = cachedSetting.fontSize;
        userSetting.lastSharedToCircle = cachedSetting.lastSharedToCircle;
        userSetting.lastSharedToNetwork = cachedSetting.lastSharedToNetwork;
        userSetting.lastLogSubmission = cachedSetting.lastLogSubmission;
        userSetting.ironCoin = cachedSetting.ironCoin;
      }

      debugPrint('refreshFromCache time: ${DateTime.now()}');
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  static populateUserSettingsFromAPI(
      UserSetting userSetting, User user, bool override) async {
    try {
      if (userSetting.lastIncremental == null) {
        await refreshFromCache(userSetting, user);
      }

      userSetting.allowHidden = user.allowClosed;
      userSetting.accountType = user.accountType!;
      //userSetting.role = user.role;
      userSetting.minor = user.minor;
      userSetting.submitLogs = user.submitLogs!;
      userSetting.autoKeychainBackup = user.autoKeychainBackup!;
      userSetting.reservedUsername = user.reservedUsername;
      userSetting.passwordBeforeChange = user.passwordBeforeChange;
      userSetting.id = user.id!;
      userSetting.username = user.username!;
      userSetting.accountRecovery = user.accountRecovery;
      userSetting.ironCoin = globalState.ironCoinWallet.balance;

      if (override) {
        userSetting.askedToGuardVault = false;
        userSetting.firstTimeInCircle = false;
        userSetting.firstTimeInFeed = false;
        userSetting.lastFull = null;
        userSetting.lastIncremental = null;
      }

      await TableUserSetting.upsert(userSetting);

      ///wait
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  static populateUserSettings(String userID) async {
    UserSetting? userSetting;

    try {
      if (userID.isEmpty) {
        UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();

        if (userFurnace != null) {
          userID = userFurnace.userid!;
          userSetting = await TableUserSetting.read(userID);
        } else {
          //LogBloc.insertLog(
          //   'Auth UserFurnace not found', 'UserSetting: populateUserSetting');
        }
      } else
        userSetting = await TableUserSetting.read(userID);

      if (userSetting == null) {
        LogBloc.insertLog(
            'User setting not found', 'UserSetting: populateUserSetting');

        ///it's a new device.
        userSetting = UserSetting(
            id: userID,
            username: '',
            fontSize: 16,
            allowHidden: false,
            minor: true,
            submitLogs: false,
            accountType: AccountType.FREE,
            //role: Role.MEMBER,
            unreadFeedOn: true,
            theme: ThemeSetting.DARK,
            allowLastSharedToCircle: true,
            lastColorIndex: -1);

        await TableUserSetting.upsert(userSetting);
      }

      ///there was a bug where the lastFull and lastIncremental were set to a future date (microsecondsSinceEpoch instead of millisecondsSinceEpoch)
      ///remove when everyone is on b124
      if (userSetting.lastFull != null &&
          userSetting.lastFull!.compareTo(DateTime.now()) > 0) {
        await userSetting
            .setLastFull(DateTime.now().subtract(const Duration(days: 9)));
      }
      if (userSetting.lastIncremental != null &&
          userSetting.lastIncremental!.compareTo(DateTime.now()) > 0) {
        await userSetting.setLastIncremental(DateTime.now());
      }

      await _loadTheme(userSetting);
      globalState.userSetting = userSetting;
      await MemberBloc.populateGlobalStateWithAll();
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  static Future<Device> getDeviceInfo({UserFurnace? userFurnace}) async {

      Device upsert = await globalState.getDevice();

      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

        if (Platform.isIOS) {
          upsert.platform = 'iOS';

          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          //debugPrint('Running on ${iosInfo.utsname.machine}');
          upsert.model = '${iosInfo.utsname.machine}, ${iosInfo.systemVersion}';

          if (upsert.manufacturerID != iosInfo.identifierForVendor){

            upsert.manufacturerID = iosInfo.identifierForVendor ?? '';
            await TableDevice.upsert(upsert);
          }

          // if (upsert.uuid != iosInfo.identifierForVendor) {
          //   LogBloc.postLog(
          //       'local uuid: ${upsert.uuid}, iOS uuid: ${iosInfo.identifierForVendor}', 'UserSetting.getDeviceInfo');
          //
          //   ///This should only happen for early adopter iOS devices
          //   upsert.uuid = iosInfo.identifierForVendor;
          //   await TableDevice.upsert(upsert);
          // }

          ///verify it is an actual device, log the user out if not
          if (kReleaseMode) {
            if (!iosInfo.isPhysicalDevice && userFurnace != null) {
              LogBloc.postLog(
                  'virtual device detected', 'UserSetting.getDeviceInfo');
              await navService.logout(userFurnace);
            }
          }
        } else if (Platform.isAndroid) {
          upsert.platform = 'android';

          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          debugPrint('Running on ${androidInfo.model}'); // e.g. "Moto G (4)"
          upsert.model = androidInfo.model;

          ///verify it is an actual device, log the user out if not
          if (kReleaseMode) {
            if (!androidInfo.isPhysicalDevice && userFurnace != null) {
              LogBloc.postLog(
                  'virtual device detected', 'UserSetting.getDeviceInfo');
              await navService.logout(userFurnace);
            }
          } else {
            ///for testing
            upsert.model = randomModel();
          }
        }

        // upsert.model = device.model;
        // upsert.platform = device.platform;
        // upsert.manufacturer = device.manufacturer;

        globalState.setDevice(upsert);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }

      return upsert;

  }

  static _loadTheme(UserSetting userSetting) async {
    if (globalState.themeLoaded) return;

    globalState.themeLoaded = true;

    if (userSetting.theme == ThemeSetting.LIGHT) {
      globalState.theme = LightTheme();
    } else {
      globalState.theme = DarkTheme();
    }

    if (userSetting.lastColorIndex == -1) {
      userSetting.lastColorIndex = 0;

      Map<String, dynamic> reducedMap = {
        TableUserSetting.lastColorIndex: userSetting.lastColorIndex,
      };
      await TableUserSetting.upsertReducedMap(userSetting, reducedMap);
      await MemberBloc.setInitialColors();
    }
  }

  static String randomModel() {
    List<String> models = [
      'SM-N976U',
      'SM-F936U',
      'SM-S908U',
      'SM-N981U',
      'SM-S916U',
      'SM-A156U1',
      'WTATTRW2',
      'Pixel 3',
      'Pixel 4',
      'Pixel 4a',
      'Pixel 5',
      'Pixel 6',
      'moto g',
      'moto x',
      'moto z',
      'moto e',
      'moto one',
      'moto edge',
      'moto g stylus',
      'moto g power',
      'moto g play',
      'moto g fast',
      'moto g9',
      'moto g9 play',
      'moto g9 plus',
      'moto g9 power',
      'moto g9 play',
      'moto g9 plus'
    ];

    return models[Random().nextInt(models.length)];
  }
}
