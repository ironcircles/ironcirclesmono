import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:rxdart/rxdart.dart';

//final CircleObjectBloc _circleObjectBloc = CircleObjectBloc();
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

FirebaseMessaging? _firebaseMessaging;

_removeNotification() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  //List<PendingNotificationRequest> list = await _flutterLocalNotificationsPlugin.
  //debugPrint ("break");
}

class SuppressNotification {
  final String title;
  final String? circleID;
  final String payload;

  SuppressNotification(this.title, this.circleID, this.payload);
}

class FirebaseBloc {
  final _suppressNotification = PublishSubject<SuppressNotification>();
  Stream<SuppressNotification> get suppressNotification =>
      _suppressNotification.stream;

  final _circleEvent = PublishSubject<String?>();
  Stream<String?> get circleEvent => _circleEvent.stream;

  final _calendarRefresh = PublishSubject<String>();
  Stream<String> get calendarRefresh => _calendarRefresh.stream;

  final _circleRemoveNotification = PublishSubject<String>();
  Stream<String> get circleRemoveNotification =>
      _circleRemoveNotification.stream;

  final _requestsUpdated = PublishSubject<bool>();
  Stream<bool> get requestsUpdated => _requestsUpdated.stream;

  final _networkRequestsUpdated = PublishSubject<bool>();
  Stream<bool> get networkRequestsUpdated => _networkRequestsUpdated.stream;

  //large file transfer streams
  final _videoProgressIndicator = PublishSubject<CircleObject>();
  Stream<CircleObject> get videoProgressIndicator =>
      _videoProgressIndicator.stream;

  void resetToken() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _firebaseMessaging!.getToken();
    }
  }

  FirebaseBloc(
    FirebaseMessaging? firebaseMessaging,
  ) {
    _firebaseMessaging = firebaseMessaging;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification2');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsIOS);

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  removeNotification() async {
    await _removeNotification();
  }

  showNotification(String body, {String payload = ''}) async {
    if (body.isNotEmpty && body != 'IronCircles') {
      showNotificationWithDefaultSound(body, _flutterLocalNotificationsPlugin,
          payload: payload);
    }
  }

  userRequestsNotification() {
    _requestsUpdated.sink.add(true);
  }

  networkRequestsNotification() {
    _networkRequestsUpdated.sink.add(true);
  }

  removeNotificationForCircle(String body) {
    _circleRemoveNotification.sink.add(body);
  }

  sinkCalendarRefresh() async {
    _calendarRefresh.sink.add('');
  }

  sinkCircleEvent(String? body, String? circleID, bool showNotification,
      {String payload = ''}) async {
    if (_suppressNotification.hasListener && body != null) {
      debugPrint('has listener');
      _suppressNotification.sink
          .add(SuppressNotification(body, circleID, payload));
    } else if (showNotification) {
      debugPrint('does not have listener');
      //if (Platform.isAndroid)

      if (body != null &&
          body.isNotEmpty &&
          body != 'IronCircles' &&
          showNotification) {
        debugPrint('showing notification: body: $body');
        await showNotificationWithDefaultSound(
            body /*+ " from app"*/, _flutterLocalNotificationsPlugin,
            payload: payload);
      }
    }

    _circleEvent.sink.add(circleID);
  }

  Future showNotificationWithDefaultSound(String body,
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
      {String payload = ''}) async {
    debugPrint('showNotificationWithDefaultSound');
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'IronCircles',
      'IronCircles?',
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        macOS: iOSPlatformChannelSpecifics,
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'IronCircles',
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  dispose() async {
    //_movieId.close();
    await _circleEvent.drain();
    await _circleEvent.close();

    await _calendarRefresh.drain();
    await _calendarRefresh.close();

    await _circleRemoveNotification.drain();
    await _circleRemoveNotification.close();

    await _suppressNotification.drain();
    await _suppressNotification.close();

    await _videoProgressIndicator.drain();
    await _videoProgressIndicator.close();

    await _networkRequestsUpdated.drain();
    await _networkRequestsUpdated.close();

    await _requestsUpdated.drain();
    await _requestsUpdated.close();
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    selectNotification(payload);
  }

  Future selectNotification(String? payload) async {
    debugPrint(
        'FIREBASE INTERACTED selectNotification from app handler fired off');
    if (payload != null && payload.isNotEmpty) {
      //debugPrint('notification payload: $payload');
      GlobalEventBloc globalEventBloc = globalState.globalEventBloc;

      //List<UserFurnace> userFurnaces =
      await TableUserFurnace.readConnectedForUser(globalState.user.id);

      List<String> parsed = payload.split(":");

      if (parsed[0] == 'UserCircle') {
        UserCircleCache userCircleCache =
            await TableUserCircleCache.read(parsed[1].replaceAll(':', ''));

        globalEventBloc.goInside(userCircleCache);
      } else if (parsed[0] == 'Invitation') {
        globalEventBloc.gotoInvitations();
      } else if (parsed[0] == 'ActionRequired') {
        globalEventBloc.gotoActionRequired();
      } else if (parsed[0] == 'Backlog') {
        globalEventBloc.gotoBacklog();
      } else if (parsed[0] == 'IronCoinWallet') {
        globalEventBloc.gotoIronCoinWallet();
      }
    }
  }
}
