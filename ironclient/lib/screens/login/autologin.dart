import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/encryption/kyber/kyber.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/updatetracker.dart';
import 'package:ironcirclesapp/screens/circles/home.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpatterncapture.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_updatetracker.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AutoLogin extends StatefulWidget {
  const AutoLogin({
    Key? key,
  }) : super(key: key);

  @override
  _AutoLoginState createState() => _AutoLoginState();
}

class _AutoLoginState extends State<AutoLogin> with WidgetsBindingObserver {
  final authBloc = AuthenticationBloc();
  final databaseBloc = DatabaseBloc();
  late BuildContext _context;
  Duration wait = const Duration(minutes: 2);
  Duration waitTime = const Duration(minutes: 2);
  bool _timeoutChair = false;
  bool _kyberReady = false;

  //late UserCircleBloc _userCircleBloc;
  late GlobalEventBloc _globalEventBloc;
  late FirebaseBloc _firebaseBloc;
  final DeviceBloc _deviceBloc = DeviceBloc();

  int attempts = globalState.userSetting.attempts == null
      ? 0
      : globalState.userSetting.attempts!;
  DateTime lastAttempt = globalState.userSetting.lastAttempt == null
      ? DateTime.now()
      : globalState.userSetting.lastAttempt!;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  final kyberspinner = const SpinKitDualRing(
    color: Colors.red,
    size: 60,
  );

  _authenticate() async {
    try {
      //Device device = await globalState.getDevice();
      ///get this from device info in case iPhone users have an invalid UUID
      Device device = await UserSetting.getDeviceInfo();

      //KyberGenerationResult? keys;

      ///reset the deviceid if user is on on ios and build is 154
      if (globalState.build == 154 && Platform.isIOS) {
        UpdateTracker updateTracker =
            await TableUpdateTracker.read(UpdateTrackerType.iosDeviceID);

        if (updateTracker.value == false) {
          device.oldID = device.uuid;
          device.uuid = Uuid().v4();
          device.kyberSharedSecret = '';

          //keys = Kyber.k1024().generateKeys();

          globalState.setDevice(device);
          TableDevice.upsert(device);

          //TableUpdateTracker.upsert(updateTrackerType, status);

          // await _deviceBloc.updateDeviceID(device);
        }
      }

      // ///check to see if user has a kyber public key
      // _kyberReady = await _deviceBloc.isKyberInit(device);
      //
      // if (!_kyberReady) {
      //   try {
      //     await _deviceBloc.getNewKyberPublicKey(device);
      //   } catch (err, trace) {
      //     LogBloc.insertError(err, trace);
      //   }
      // }

      await UserCircleBloc.closeHiddenCircles(_firebaseBloc);

      ///test token
      authBloc.authenticateToken(_globalEventBloc);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
    }
  }

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    super.initState();

    WidgetsBinding.instance.addObserver(this);

    try {
      //make sure the database was created
      databaseBloc.databaseCreated.listen((success) {
        _authenticate();
      }, onError: (err) {
        //FlutterNativeSplash.remove();
        Navigator.pushReplacementNamed(context, '/landing');

        debugPrint("error $err");
      }, cancelOnError: true);

      databaseBloc.createDatabase();
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
    }

    authBloc.authToken.listen((user) async {
      ///There could be a timing issue with the two global state variables below getting set
      ///Need to also check after Circles.dart is loaded

      //LogBloc.insertLog('autologin hit listener', 'autologin');

      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        RemoteMessage? initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();

        if (initialMessage != null) {
          globalState.messageReceived = initialMessage;

          try {
            int? notificationType = await _globalEventBloc
                .processInteractedMessage(initialMessage, true);

            if (notificationType != null) {
              if (globalState.userSetting.patternPinString != null) {
                _checkPattern(user, notificationType: notificationType);
              } else {
                globalState.selectedNotificationType = notificationType;
                _processNotification(notificationType, user);
              }
            } else {
              _determineRoute(user);
            }
          } catch (err, trace) {
            LogBloc.insertError(err, trace);
            _determineRoute(globalState.user);
          }
        } else {
          _setupDefault(user);
        }
      } else {
        _setupDefault(user);
      }
    }, onError: (err, trace) {
      LogBloc.insertError(err, trace);
      LogBloc.insertLog('Pushed to landing', 'autologin');
      Navigator.pushReplacementNamed(_context, '/landing');
    }, cancelOnError: true);
  }

  _setupDefault(User user) {
    if (globalState.user.id == null) {
      globalState.user = user;

      _determineRoute(globalState.user);
    } else {
      _determineRoute(globalState.user);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setState(() => this._context = context);

    globalState.setScaler(MediaQuery.of(context).size.width,
        mediaScaler: MediaQuery.textScalerOf(context));

    return Scaffold(
        backgroundColor: globalState.theme.background,
        body: Center(
          child: _timeoutChair
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ICText(_timerMessage, fontSize: 20),
                  SizedBox(
                      child: Image.asset(
                    'assets/images/appstore.png',
                    height: 250,
                    width: 250,
                  ))
                ])
              : _kyberReady
                  ? spinkit
                  : kyberspinner,
        ));
  }

  _checkPattern(User user, {int? notificationType}) {
    if (globalState.userSetting.lastAttempt != null) {
      Duration duration =
          DateTime.now().difference(globalState.userSetting.lastAttempt!);

      if (duration.inSeconds <= waitTime.inSeconds) {
        setState(() {
          wait = duration;

          _timerMessage =
              'locked out for ${wait.inMinutes}:${(wait.inSeconds - (wait.inMinutes * 60)).toString().length == 1 ? '0${wait.inSeconds - (wait.inMinutes * 60)}' : (wait.inSeconds - (wait.inMinutes * 60)).toString()}';

          _wait2(1, user, notificationType: notificationType);

          _timeoutChair = true;
        });

        if (attempts >= 5) attempts = 0;

        return;
      }
    }
    DialogPatternCapture.capture(
        context, _pinCaptured, 'Swipe pattern to enter',
        dismissible: false, user: user, notificationType: notificationType);
  }

  _determineRoute(User user) async {
    if (globalState.userSetting.patternPinString != null) {
      _checkPattern(user);
    } else {
      _goHome(user);
    }
  }

  _goHome(User user) {
    if (globalState.userSetting.patternPinString != null) {
      globalState.userSetting.clearPatternLockout();
    }

    NavigationService navigationService = NavigationService();

    navigationService.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Home()),
      keepPreviousPages: false,
    );

    // Navigator.pushReplacementNamed(
    //   context,
    //   '/home',
    //   arguments: user,
    // );
  }

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

  String _timerMessage = '';

  _displayTime(User user, {int? notificationType}) {
    if (wait <= Duration.zero) {
      globalState.userSetting.clearPatternLockout();
      _appGuarded(user, notificationType: notificationType);
    } else {
      wait = wait - const Duration(seconds: 1);

      setState(() {
        _timerMessage =
            'locked out for ${wait.inMinutes}:${(wait.inSeconds - (wait.inMinutes * 60)).toString().length == 1 ? '0${wait.inSeconds - (wait.inMinutes * 60)}' : (wait.inSeconds - (wait.inMinutes * 60)).toString()}';
      });
    }
  }

  _wait2(int count, User user, {int? notificationType}) {
    const oneMin = Duration(seconds: 1);

    Timer.periodic(oneMin, (Timer t) {
      if (wait <= Duration.zero) {
        t.cancel();
      }
      _displayTime(user, notificationType: notificationType);
    });
  }

  _locked(User user, {int? notificationType}) {
    globalState.userSetting.setPatternLockout();

    wait = waitTime;

    setState(() {
      _timerMessage =
          'locked out for ${wait.inMinutes}:${(wait.inSeconds - (wait.inMinutes * 60)).toString().length == 1 ? '0${wait.inSeconds - (wait.inMinutes * 60)}' : (wait.inSeconds - (wait.inMinutes * 60)).toString()}';
    });

    attempts = 0;
    _wait2(1, user, notificationType: notificationType);
  }

  _pinCaptured(List<int> pin, User user, {int? notificationType}) {
    String pinPattern = '';

    ///the pattern may have been reset serverside by an admin
    if (globalState.userSetting.patternPinString != null) {
      pinPattern = globalState.userSetting.patternPinString!;
    }

    List<int> checkPin = stringToPin(pinPattern);
    if (listEquals(pin, checkPin)) {
      if (notificationType != null) {
        _processNotification(notificationType, user);
      } else {
        _goHome(user);
      }
    } else {
      UserCircleBloc userCircleBloc =
          UserCircleBloc(globalEventBloc: _globalEventBloc);
      userCircleBloc.saveSwipePatternAttempt(null, null);

      attempts++;

      globalState.userSetting.setAttempts(attempts);

      if (attempts >= 5 &&
          DateTime.now().difference(lastAttempt).inMinutes < 2) {
        lastAttempt = DateTime.now();
        _locked(user, notificationType: notificationType);
        setState(() {
          _timeoutChair = true;
        });
      } else {
        FormattedSnackBar.showSnackbarWithContext(
            context, 'wrong pattern ($attempts of 5)', "", 1, false);
        lastAttempt = DateTime.now();
        _appGuarded(user, notificationType: notificationType);
      }
    }
  }

  _appGuarded(User user, {int? notificationType}) async {
    setState(() {
      _timeoutChair = false;
    });
    await DialogPatternCapture.capture(
        context, _pinCaptured, 'Swipe pattern to enter',
        dismissible: false, user: user, notificationType: notificationType);
  }

  _pushToHomeAndOpenScreen(HomeNavToScreen homeNavToScreen) {
    NavigationService navigationService = NavigationService();

    navigationService.pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => Home(
                openScreen: homeNavToScreen,
              )),
      keepPreviousPages: false,
    );
  }

  _pushToHomeAndOpenTab(int bottomNavigationOptions) {
    NavigationService navigationService = NavigationService();

    navigationService.pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => Home(
                tab: bottomNavigationOptions,
              )),
      keepPreviousPages: false,
    );
  }

  _processNotification(int notificationType, User user) {
    if (notificationType == NotificationType.MESSAGE ||
        notificationType == NotificationType.EVENT ||
        notificationType == NotificationType.REACTION) {
      _goHome(user);
    } else if (notificationType == NotificationType.INVITATION) {
      _pushToHomeAndOpenScreen(HomeNavToScreen.invitations);
    } else if (notificationType == NotificationType.ACTION_NEEDED) {
      _pushToHomeAndOpenTab(BottomNavigationOptions.ACTIONS);
    } else if (notificationType == NotificationType.BACKLOG_ITEM ||
        notificationType == NotificationType.BACKLOG_REPLY) {
      _pushToHomeAndOpenScreen(HomeNavToScreen.backlog);
    } else if (notificationType == NotificationType.GIFTED_IRONCOIN) {
      _pushToHomeAndOpenScreen(HomeNavToScreen.giftedIronCoin);
    }
  }
}
