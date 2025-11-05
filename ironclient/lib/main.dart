import 'dart:async';
import 'dart:convert';
import 'dart:io';
//import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ironcirclesapp/app.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/invitations_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/replyobject_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/circleobjectreaction.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/notificationtracker.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:ironcirclesapp/services/cache/export_tables.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_notificationtracker.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/cache/update_database.dart';
import 'package:ironcirclesapp/services/device_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const int BUILD = 159;
const String VERSION = 'v1.2.36';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//final FirebaseBloc _firebaseBloc = FirebaseBloc(_firebaseMessaging);
FirebaseBloc _firebaseBloc = FirebaseBloc(null);
final GlobalEventBloc _globalEventBloc = GlobalEventBloc();
final DeviceBloc _deviceBloc = DeviceBloc();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('BACKGROUND message handler fired off');
  debugPrint('message: ${message.data}');
  try {
    if (Platform.isIOS) {
      //LogBloc.insertLog('background handler fired off', 'background handler');
    }

    //LogBloc.insertLog('background message: ${json.encode(message.data)}', 'background handler');

    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    _processMessage(message, false, false, true);
  } catch (e, trace) {
    LogBloc.insertError(e, trace, source: 'background handler');
  }
}

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  //'This channel is used for important notifications.', // description
  importance: Importance.high,
);

/// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

_initialize() async {
  //HttpOverrides.global = new ICHttpOverrides();

  await initializeDateFormatting();

  await FileSystemService.makePaths();

  try {
    ///alter databases changes (non upgrade path, use upgrade for production)
    await UpdateDatabase.fixTables();
  } catch (err) {
    debugPrint(err.toString());

    ///On desktop the database isn't deleted during uninstall
    ///So, if the decryption fails because there is an old key, delete the database and the key
    if (globalState.isDesktop()) {
      await DatabaseProvider.deleteDatabase();
      await UpdateDatabase.fixTables();
    }
  }

  ///set the app path
  await globalState.setAppPath();
  LogBloc.deleteOlderThanThirty();

  ///set the theme
  await UserSetting.populateUserSettings('');

  ///track free coins before registration
  if (!await globalState.secureStorageService.keyExists(KeyType.FREE_COINS)) {
    globalState.secureStorageService.writeKey(KeyType.FREE_COINS, "50");
  }
}

Future<void> main() async {
  ///dummy code to ensure import statement isn't tree shaken
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  //await initializeService();

  ///ensure debugPrint commands don't print to stdout in release mode.
  ///Comment this out for testing only
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) => '';
  }

  ///dummy call to get SSS up and running
  await globalState.secureStorageService.readKey(KeyType.FREE_COINS);

  await _initialize();

  ///replaced SecureStorageService with SQLLite
  /*
  if (!await SecureStorageService.keyExists(KeyType.DEVICEID)) {
    //New device, user cleared data, or uninstall/reinstalled app
    String deviceID = Uuid().v4();

    String platform = Platform.isIOS ? 'iOS' : 'Android';
    LogBloc.postLog('New installation on $platform', 'main');

    await SecureStorageService.writeKey(KeyType.DEVICEID, deviceID);
    globalState.deviceID = deviceID;
  } else
    globalState.deviceID =
        await (SecureStorageService.readKey(KeyType.DEVICEID));

            globalState.pushToken =
    await (SecureStorageService.readKey(KeyType.PUSHTOKEN));
    SecureStorageService.debugPrintKey(KeyType.PUSHTOKEN);

  */

  ///Setting deviceID should occur before FirebaseInit
  Device device = await TableDevice.read();

  if (device.uuid == null || device.uuid!.isEmpty) {
    try {
      device = Device(uuid: const Uuid().v4(), pushToken: '');

      if (Platform.isIOS) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        device.platform = 'iOS';

        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        //debugPrint('Running on ${iosInfo.utsname.machine}');
        device.model = '${iosInfo.utsname.machine}, ${iosInfo.systemVersion}';
        device.manufacturerID = iosInfo.identifierForVendor ?? '';
      } else {
        device.platform = DeviceBloc.getPlatformString();
      }

      try {
        bool _kyberReady = await _deviceBloc.isKyberInit(device);
        if (_kyberReady == false) {
          await _deviceBloc.getNewKyberPublicKey(device);
        }
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }

      LogBloc.postLog('New installation on ${device.platform}', 'main');

      globalState.setDevice(device);

      await TableDevice.upsert(device);
    } catch (err, trace) {
      LogBloc.insertError(err, trace, source: 'main');
    }
  } else {
    globalState.setDevice(device);
  }

  debugPrint('deviceID: ${device.uuid}');

  ///This should occur after globalState.deviceID is initialized
  if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
    await Firebase.initializeApp();

    _firebaseBloc = FirebaseBloc(_firebaseMessaging);

    String? apnsToken;

    if (Platform.isIOS || Platform.isMacOS) {
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();

      if (apnsToken == null) {
        ///wait 2 seconds for the token to be retrieved
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    try {
      //NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      // TODO: If necessary send token to application server.
      _saveToken(fcmToken);

      /// Note: This callback is fired at each app startup and whenever a new
      /// token is generated.
    }).onError((err) {
      // Error getting token.
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FOREGROUND message handler fired off');
      _processMessage(message, true, true, false);
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _firebaseMessaging.setAutoInitEnabled(true);

    _firebaseMessaging.getToken().then((token) {
      if (token != null) _saveToken(token);
    });

    // if (Platform.isAndroid) {
    //   _firebaseMessaging.getToken().then((token) {
    //     if (token != null) _saveToken(token);
    //   });
    // } else if (Platform.isIOS || Platform.isMacOS) {
    //   if (apnsToken == null) {
    //     ///wait 2 seconds for the token to be retrieved
    //     await Future.delayed(const Duration(seconds: 2));
    //   } else {
    //     _saveToken(apnsToken);
    //   }
    // }
  }
  globalState.build = BUILD;
  globalState.version = VERSION;

  runApp(Provider(
    create: (_) => _firebaseBloc,
    child: Provider(
      create: (_) => _globalEventBloc,
      //child: App(sharedMedia: _sharedMedia),
      child: const App(),
    ),
  ));
}

_updateCircle(UserCircleBloc userCircleBloc, String body, String circleID,
    bool showNotification) async {
  List<UserCircle> userCircles = [];
  // String circleID = data["object2"]; //["data"]["object"];

  try {
    //update the circle cache
    userCircles =
        await userCircleBloc.refreshFurnaceFromPushNotification(circleID, true);

    //notify the world
    for (UserCircle userCircle in userCircles) {
      if (userCircle.circle != null) {
        //debugPrint(userCircle.circle.id);

        if (userCircle.circle!.id == circleID) {
          _firebaseBloc.sinkCircleEvent(body, circleID, showNotification,
              payload: 'UserCircle:${userCircle.id}');

          break;
        }
      }
    }
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint(err.toString());
  }
}

///Flutter team recommends this be a high level function in main
Future<dynamic> _processMessage(RemoteMessage message, bool showNotification,
    bool generalUpdate, bool fromBackground) async {
  /**
   *
   * TITLE return values
   *
   * activity in IronCircles
   * invitation in IronCircles
   * CircleObject Deleted
   *
   */

  ///TODO remove the hardcoded string compares for notification type once everyone is on v61

  final UserCircleBloc _userCircleBloc =
      UserCircleBloc(globalEventBloc: _globalEventBloc);

  final CircleObjectBloc _circleObjectBloc =
      CircleObjectBloc(globalEventBloc: _globalEventBloc);

  final ReplyObjectBloc _replyObjectBloc = ReplyObjectBloc(
      globalEventBloc: _globalEventBloc, userCircleBloc: _userCircleBloc);

  String? body;
  String? id;
  int? notificationType;

  try {
    ///theme will not be loaded yet for message notification press

    // if (!fromBackground) {
    //   LogBloc.insertLog('foreground message: ${json.encode(message.data)}', '_processMessage');
    // }

    var data = message.data;
    id = data["id"];
    notificationType = data["notificationType"] == null
        ? -1
        : int.parse(data["notificationType"]);

    debugPrint('Notification Type: $notificationType');

    if (message.notification != null) body = message.notification!.body;

    if (await TableNotificationTracker.exists(id)) {
      return;
    } else
      debugPrint(id);

    await TableNotificationTracker.upsert(NotificationTracker(id: id));

    if (body != null) debugPrint(body);

    if (body == null) {
      ///data only
      if (data["replyUpdate"] != null) {
        ///fetch reply
        var decode = json.decode(data["replyUpdate"])!;
        var reply = decode["_id"];
        var obj = decode["seed"];
        await _replyObjectBloc.uploadFromPushNotification(reply, obj);
      } else if (data["reply"] != null) {
        ///data only notification deleting a wall reply
        String replyObjectID = data["reply"];
        await _replyObjectBloc.deleteFromPushNotification(replyObjectID);
      } else if (data["object2"] != null) {
        String circleID = data["object2"]; //["data"]["object"];
        _updateCircle(_userCircleBloc, '', circleID, false);
      } //else {
      //   LogBloc.insertLog('no circleID in message: $message', 'processMessage');
      // }
    } else if (notificationType == NotificationType.REPLY) {
      var decode = json.decode(data["object"])!;
      var reply = decode["_id"];
      var obj = decode["seed"];
      try {
        await _replyObjectBloc.uploadFromPushNotification(reply, obj);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
      }
    } else if (body == 'New activity in IronCircles' ||
        body == 'New ironclad message' ||
        body == 'New ironclad event' ||
        body == 'Member reacted to your ironclad message' ||
        body == 'Member updated ironclad message' ||
        body == 'Member updated ironclad event' ||
        body == 'Message removed by IronCircles' ||
        notificationType == NotificationType.MESSAGE ||
        notificationType == NotificationType.EVENT) {
      if (data.containsKey("object")) {
        var decode = json.decode(data["object"]!);
        String circleID = decode["circle"]["_id"];

        try {
          CircleObject circleObject = CircleObject.fromJson(decode!);

          UserCircleCache userCircleCache =
              await _userCircleBloc.refreshFromPushNotification(
                  circleObject, /*generalUpdate*/ false, false);

          _firebaseBloc.sinkCircleEvent(body, circleID, showNotification,
              payload: 'UserCircle:${userCircleCache.usercircle}');
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
          await _userCircleBloc.refreshFurnaceFromPushNotification(
              circleID, true);
        }
      } else if (data.containsKey("objectID")) {
        ///reaction notification

        String id = data["objectID"];
        CircleObject circleObject = await _circleObjectBloc.fetchObjectById(id);

        var decodedReaction = json.decode(data["reaction"]);
        CircleObjectReaction reaction =
            CircleObjectReaction.fromJson(decodedReaction);

        circleObject = await _circleObjectBloc.processReactionNotification(
            circleObject, reaction);

        UserCircleCache userCircleCache =
            await _userCircleBloc.refreshFromPushNotification(
                circleObject, /*generalUpdate*/ false, false);

        _firebaseBloc.sinkCircleEvent(
            body, circleObject.circle?.id, showNotification,
            payload: 'UserCircle:${userCircleCache.usercircle}');
      } else if (data.containsKey("object3")) {
        debugPrint("RECEIVED ALBUM NOTIFICATION");
        var decode = json.decode(data["object3"]!);
        String circleID = decode["circle"]["_id"];

        try {
          CircleObject circleObject = CircleObject.fromJson(decode!);

          UserCircleCache userCircleCache =
              await _userCircleBloc.refreshFromPushNotification(
                  circleObject, /*generalUpdate*/ false, false);

          _firebaseBloc.sinkCircleEvent(body, circleID, showNotification,
              payload: 'UserCircle:${userCircleCache.usercircle}');
        } catch (error, trace) {
          LogBloc.insertError(error, trace);
          debugPrint(error.toString());
          await _userCircleBloc.refreshFurnaceFromPushNotification(
              circleID, true);
        }
      } else {
        late List<UserCircle> userCircles;
        String circleID = data["object2"]; //["data"]["object"];

        try {
          //update the circle cache
          userCircles = await _userCircleBloc
              .refreshFurnaceFromPushNotification(circleID, true);
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
        }

        if (showNotification) {
          //notify the world
          for (UserCircle userCircle in userCircles) {
            if (userCircle.circle != null) {
              //debugPrint(userCircle.circle.id);

              if (userCircle.circle!.id == circleID) {
                _firebaseBloc.sinkCircleEvent(body, circleID, showNotification,
                    payload: 'UserCircle:${userCircle.id}');

                break;
              }
            }
          }
        }
      }

      if (body == 'Member updated ironclad event' ||
          body == 'New ironclad event' ||
          notificationType == NotificationType.EVENT) {
        _firebaseBloc.sinkCalendarRefresh();
      }
    } else if (body == 'User deleted item in Circle' ||
        body == 'Member deleted ironclad message' ||
        notificationType == NotificationType.DELETE) {
      String? circle = data["object2"];
      String? circleObjectID = data["object1"];

      if (circleObjectID != null) {
        await _userCircleBloc.deleteFromPushNotification(circleObjectID);
      }
      late List<UserCircle> userCircles;

      try {
        //update the circle cache
        userCircles = await _userCircleBloc.refreshFurnaceFromPushNotification(
            circle, false);
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint(err.toString());
      }

      //notify the world
      for (UserCircle userCircle in userCircles) {
        if (userCircle.circle != null) {
          //debugPrint(userCircle.circle.id);

          if (userCircle.circle!.id == circle) {
            //_firebaseBloc.sinkCircleEvent(body, circle, false);
            _firebaseBloc.sinkCircleEvent(
                body, userCircle.circle!.id, showNotification,
                payload: 'UserCircle:${userCircle.id}');

            break;
          }
        }
      }
    } else if (body == 'New invitation in IronCircles' ||
        notificationType == NotificationType.INVITATION) {
      try {
        //LogBloc.insertLog(message.data["object2"], "main");
        await InvitationBloc.saveInvitationFromNotification(_globalEventBloc,
            Invitation.fromJson(json.decode(message.data["object2"])));
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        LogBloc.insertLog(
            'invitation notification failed: $message', 'processMessage');
        debugPrint(err.toString());
      }

      if (showNotification /*&& Platform.isAndroid*/) {
        _firebaseBloc.showNotification(body, payload: 'Invitation:new');
      }
    } else if (body == 'Action needed in IronCircles' ||
        notificationType == NotificationType.ACTION_NEEDED) {
      try {
        var userFurnaces =
            await TableUserFurnace.readAllForUser(globalState.user.id);
        UserCircleBloc userCircleBloc =
            UserCircleBloc(globalEventBloc: _globalEventBloc);
        await userCircleBloc.fetchUserCircles(userFurnaces, false, true);
        //_globalEventBloc.broadcastActionNeededRefresh();
      } catch (err, trace) {
        LogBloc.insertError(err, trace);
        debugPrint(err.toString());
      }

      if (showNotification /*&& Platform.isAndroid*/)
        _firebaseBloc.showNotification(body, payload: 'ActionRequired:new');
    } else if (notificationType == NotificationType.WIPE_DEVICE) {
      /*///temporary code
      _globalEventBloc.broadcastWipePhone();
      await Future.delayed(const Duration(seconds: 2));
       */
      DeviceBloc.wipeDeviceCallback('device wiped');
    } else if (notificationType == NotificationType.BACKLOG_REPLY ||
        notificationType == NotificationType.BACKLOG_ITEM) {
      if (showNotification /*&& Platform.isAndroid*/)
        _firebaseBloc.showNotification(body, payload: 'Backlog:new');
    } else if (notificationType == NotificationType.REPLY_REACTION) {
      debugPrint("got reply reaction notification");

      var decode = json.decode(data["object"]!);
      var replyObjectID = decode["_id"];

      var decodedReaction = json.decode(data["reaction"]);
      CircleObjectReaction reaction =
          CircleObjectReaction.fromJson(decodedReaction);

      ReplyObject replyObject = await _replyObjectBloc
          .processReactionNotification(replyObjectID, reaction);

      // UserCircleCache userCircleCache =
      // await _userCircleBloc.refreshFromPushNotification(
      //     circleObject, /*generalUpdate*/ false, false);

      // _firebaseBloc.sinkCircleEvent(
      //     body, replyObject.circle?.id, showNotification,
      //     payload: 'Circle:${replyObject.circle}');
    } else if (notificationType == NotificationType.DEACTIVATE_DEVICE) {
      DeviceBloc.deactivateDeviceCallback();
    } else if (notificationType == NotificationType.USER_REQUEST_UPDATE) {
      _firebaseBloc.userRequestsNotification();
      if (showNotification)
        _firebaseBloc.showNotification(body, payload: 'UserRequestUpdate:new');
    } else if (notificationType == NotificationType.NETWORK_REQUEST_UPDATE) {
      _firebaseBloc.networkRequestsNotification();
      if (showNotification)
        _firebaseBloc.showNotification(body, payload: 'NetRequestUpdate:new');
    } else if (notificationType == NotificationType.GIFTED_IRONCOIN) {
      if (showNotification)
        _firebaseBloc.showNotification(body, payload: 'IronCoinWallet:new');
    } else if (notificationType == NotificationType.CIRCLEAGORACALL) {
      if (data.containsKey("object")) {
        var decode = json.decode(data["object"]!);
        String circleID = decode["circle"]["_id"];

        try {
          CircleObject circleObject = CircleObject.fromJson(decode!);

          UserCircleCache userCircleCache =
              await _userCircleBloc.refreshFromPushNotification(
                  circleObject, /*generalUpdate*/ false, false);

          _firebaseBloc.sinkCircleEvent(body, circleID, showNotification,
              payload: 'UserCircle:${userCircleCache.usercircle}');
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint(err.toString());
          await _userCircleBloc.refreshFurnaceFromPushNotification(
              circleID, true);
        }
      } else if (showNotification) {
        _firebaseBloc.showNotification(body, payload: 'CircleAgoraCall:new');
      }
    } else {
      if (data["object2"] != null) {
        String circleID = data["object2"]; //["data"]["object"];
        _updateCircle(_userCircleBloc, body, circleID, false);
      } // else if (showNotification /*&& Platform.isAndroid*/)
      //_firebaseBloc.showNotification(body);
    }
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
    debugPrint(err.toString());
  }

  return Future<void>.value();
}

Future _saveToken(String pushtoken) async {
  try {
    debugPrint("pushtoken update: $pushtoken");

    Device device = await globalState.getDevice();

    if (device.pushToken != pushtoken) {
      //it may match the front end, but not the backend
      device.pushToken = pushtoken;
      //await SecureStorageService.writeKey(KeyType.PUSHTOKEN, pushtoken);
      TableDevice.upsert(device);

      DeviceService.updateFireToken(pushtoken);

      globalState.setDevice(device);
    }
  } catch (err, trace) {
    LogBloc.insertError(err, trace);
  }

  return;
}
//
// final service = FlutterBackgroundService();
//
// Future<void> initializeService() async {
//
//   if (Platform.isIOS || Platform.isAndroid) {
//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         iOS: DarwinInitializationSettings(),
//         android: AndroidInitializationSettings('ic_bg_service_small'),
//       ),
//     );
//   }
//
//   // await flutterLocalNotificationsPlugin
//   //     .resolvePlatformSpecificImplementation<
//   //         AndroidFlutterLocalNotificationsPlugin>()
//   //     ?.createNotificationChannel(channel);
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       // this will be executed when app is in foreground or background in separated isolate
//       onStart: onStart,
//
//       /// auto start service
//       autoStart: true,
//       isForegroundMode: false,
//
//       // notificationChannelId: 'my_foreground',
//       // initialNotificationTitle: 'AWESOME SERVICE',
//       // initialNotificationContent: 'Initializing',
//       // foregroundServiceNotificationId: 888,
//       // foregroundServiceTypes: [AndroidForegroundType.location],
//     ),
//     iosConfiguration: IosConfiguration(
//       // auto start service
//       autoStart: true,
//
//       // this will be executed when app is in foreground in separated isolate
//       onForeground: onStart,
//
//       /// you have to enable background fetch capability on xcode project
//       onBackground: onIosBackground,
//     ),
//   );
//
//   service.startService();
// }
//
// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   // WidgetsFlutterBinding.ensureInitialized();
//   // DartPluginRegistrant.ensureInitialized();
//   //
//   // SharedPreferences preferences = await SharedPreferences.getInstance();
//   // await preferences.reload();
//   // final log = preferences.getStringList('log') ?? <String>[];
//   // log.add(DateTime.now().toIso8601String());
//   // await preferences.setStringList('log', log);
//
//   return true;
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//
//   /// you can see this log in logcat
//   debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
//
//   // test using external plugin
//   final deviceInfo = DeviceInfoPlugin();
//   String? device;
//   if (Platform.isAndroid) {
//     final androidInfo = await deviceInfo.androidInfo;
//     device = androidInfo.model;
//   } else if (Platform.isIOS) {
//     final iosInfo = await deviceInfo.iosInfo;
//     device = iosInfo.model;
//   }
//
//   service.invoke(
//     'update',
//     {
//       "current_date": DateTime.now().toIso8601String(),
//       "device": device,
//     },
//   );
// }
//