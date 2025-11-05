import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ironcirclesapp/blocs/backgroundtask_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/subscriptions_bloc.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/models/backgroundtask.dart';
import 'package:ironcirclesapp/models/circlerecipetemplate.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/home.dart';
import 'package:ironcirclesapp/screens/login/applink.dart';
import 'package:ironcirclesapp/screens/login/autologin.dart';
import 'package:ironcirclesapp/screens/login/landing.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class App extends StatefulWidget {
  //final SharedMedia? sharedMedia;

  //App({required this.sharedMedia});
  const App();

  @override
  State<StatefulWidget> createState() {
    return _AppState();
  }
}

class _AppState extends State<App> {
  //late StreamSubscription _intentDataStreamSubscription;
  //MediaCollection? _mediaCollection;
  //String? _sharedText;
  // bool _share = false;
  //RemoteMessage? _messageReceived;
  late FirebaseBloc _firebaseBloc;
  late GlobalEventBloc _globalEventBloc;

  // _initHive() async {
  //   Hive
  //     ..init(await globalState.getAppPath())
  //   //..registerAdapter(RatchetKeyAdapter())
  //   //..registerAdapter(CircleLastUpdateAdapter())
  //   //..registerAdapter(RatchetIndexAdapter())
  //     ..registerAdapter(CircleRecipeTemplateAdapter())
  //     ..registerAdapter(CircleRecipeTemplateIngredientAdapter())
  //     ..registerAdapter(CircleRecipeTemplateInstructionAdapter());
  //   //..registerAdapter(CircleImageAdapter());
  // }

  //final _appLinks = AppLinks();

  _getInitialLinks() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Get any initial links
      globalState.initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();
      /*if (globalState.initialLink != null) {
      //LogBloc.insertLog(globalState.initialLink!.link.toString(), 'App');
    } else
      debugPrint('incoming string is null');

     */
    }
  }

  handleAppLifecycleState() async {
    AppLifecycleState _lastLifecyleState;
    SystemChannels.lifecycle.setMessageHandler((msg) {
      debugPrint(
          "********************handleAppLifecycleState FIRED WITH: $msg");

      switch (msg) {
        case "AppLifecycleState.paused":
          _lastLifecyleState = AppLifecycleState.paused;
          _globalEventBloc.broadCastApplicationStateChanged(_lastLifecyleState);
          break;
        case "AppLifecycleState.inactive":
          _lastLifecyleState = AppLifecycleState.inactive;
          _globalEventBloc.broadCastApplicationStateChanged(_lastLifecyleState);
          break;
        case "AppLifecycleState.resumed":
          _lastLifecyleState = AppLifecycleState.resumed;
          _globalEventBloc.broadCastApplicationStateChanged(_lastLifecyleState);
          globalState.setGlobalState();
          if (mounted) globalState.setLocaleAndLanguage(context);
          break;
      }

      //LogBloc.insertLog('handleAppLifecycleState fired with: $msg', 'App.handleAppLifecycleState');

      return Future.value(null);
    });
  }

  _initBackgroundListener() {
    FileDownloader().updates.listen((update) {

      BackgroundTaskBloc.processUpdate(_globalEventBloc, update);
    });

    ///not sure where this should be yet
    FileDownloader().start();
  }

  @override
  void initState() {
    super.initState();

    //init firebase (for no content message notifications)
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    handleAppLifecycleState();

    setupInteractedMessage();

    _getInitialLinks();

    //_initHive();

    _initBackgroundListener();

    if (globalState.isDesktop()) {
      ///There are only two tabs, default to Circles
      globalState.selectedCircleTabIndex = 0;
    }

    FileSystemService.cleanUpSystemCache();

    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        //Navigator.pushNamed(context, dynamicLinkData.link.path);
        //print(dynamicLinkData.link);

        NavigationService.navigationKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_context) => AppLink(
                  link: dynamicLinkData.link.toString(),
                )),
            ModalRoute.withName("/home"));

        //_globalEventBloc.broadcastMagicLink(dynamicLinkData.link.toString());
        //globalState.initialLink
      }).onError((error) {
        // Handle errors
      });
    }

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          globalState.inAppPurchase.purchaseStream;

      ///Move this to after token validation
      globalState.subscriptions =
          purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
            SubscriptionsBloc.listenToPurchaseUpdated(purchaseDetailsList);
          }, onError: (Object error) {
            debugPrint(error.toString());
          });
    }

    // _globalEventBloc.sharedMedia.listen((mediaCollection) {
    //   // if (mounted) {
    //   // NavigationService.navigationKey.currentState!.pushAndRemoveUntil(
    //   //     MaterialPageRoute(
    //   //         builder: (_context) => ReceiveShare(
    //   //               sharedMedia: sharedMedia,
    //   //             )),
    //   //     ModalRoute.withName("/home"));
    //   //
    //   // }
    //   _globalEventBloc.broadcastPopToHomeAndOpenShare(ShareHolder(sharedMedia: mediaCollection));
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);
    //
    // _globalEventBloc.sharedVideo.listen((sharedVideo) {
    //   MediaCollection mediaCollection = MediaCollection();
    //   mediaCollection.media
    //       .add(Media(mediaType: MediaType.video, path: sharedVideo.path));
    //   _globalEventBloc.broadcastPopToHomeAndOpenShare(ShareHolder(sharedMedia: mediaCollection));
    //   //if (mounted) {
    //   // NavigationService.navigationKey.currentState!.pushAndRemoveUntil(
    //   //     MaterialPageRoute(
    //   //         builder: (_context) => ReceiveShare(
    //   //               sharedVideos: [sharedVideo],
    //   //             )),
    //   //     ModalRoute.withName("/home"));
    //
    //   // }
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);
    //
    // _globalEventBloc.sharedText.listen((sharedText) {
    //   //if (mounted) {
    //   NavigationService.navigationKey.currentState!.pushAndRemoveUntil(
    //       MaterialPageRoute(
    //           builder: (context) => ReceiveShare(
    //                 sharedText: sharedText,
    //               )),
    //       ModalRoute.withName("/home"));
    //   //}
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);

    // _globalEventBloc.closeHiddenCircles.listen((value) {
    //   _closeHiddenCircles();
    //   //}
    // }, onError: (err) {
    //   debugPrint("error $err");
    // }, cancelOnError: false);

    if (Platform.isAndroid || Platform.isIOS) {
      /// For sharing images coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialMedia()
          .then((List<SharedMediaFile> value) {
        try {
          if (value.isEmpty) return;

          debugPrint(
              '****************************************** MEDIA SHARE CLOSED **************');
          globalState.sharedMediaCollection.populateFromSharedMediaFile(value);
          // });
        } catch (err, trace) {
          LogBloc.insertError(err, trace);
          debugPrint("getInitialMedia error: $err");
        }
      });

      /// For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then((String? value) {
        if (value != null) {
          debugPrint(
              '****************************************** TEXT SHARE CLOSED **************');

          if (value.contains('ironcircles.page.link')) return;
          globalState.sharedText = value;
        }
      });

      // For sharing images coming from outside the app while the app is in the memory
      ReceiveSharingIntent.getMediaStream().listen(
              (List<SharedMediaFile> value) {
            try {
              debugPrint(
                  '****************************************** MEDIA SHARE **************');
              if (value.isEmpty) return;

              setState(() {
                debugPrint("Shared:${value.map((f) => f.path).join(",")}");

                /* if (value[0].type == SharedMediaType.VIDEO) {
            _sharedVideos = [File(value[0].path)];
            _globalEventBloc.shareVideo(_sharedVideos![0]);
          } else {

          */
                MediaCollection mediaCollection = MediaCollection();
                mediaCollection.populateFromSharedMediaFile(value);
                _globalEventBloc.broadcastPopToHomeAndOpenShare(
                    SharedMediaHolder(message: '', sharedMedia: mediaCollection));
                //}

                //_share = true;
              });
            } catch (err, trace) {
              LogBloc.insertError(err, trace);
              debugPrint("getIntentDataStream error: $err");
            }
          }, onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      ReceiveSharingIntent.getTextStream().listen((String value) {
        //if (value == null) return;

        ///let the app link handler process app links
        if (value.contains('ironcircles.page.link') &&
            value != globalState.lastCreatedMagicLink) {
          globalState.lastCreatedMagicLink = '';
          return;
        }

        debugPrint(
            '****************************************** TEXT SHARE **************');

        debugPrint(value);

        _globalEventBloc.broadcastPopToHomeAndOpenShare(
            SharedMediaHolder(message: '', sharedText: value));

        // });
      }, onError: (err) {
        debugPrint("getLinkStream error: $err");
      });
    }
  }

  setupInteractedMessage() {
    ///listen to events while app is open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //LogBloc.insertLog('onMessageOpenedApp', message.data.toString());

      _globalEventBloc.processInteractedMessage(message, false);
    });

    ///moved to autologin
    /*
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      globalState.messageReceived = initialMessage;
    }

     */

    return;
  }

  // void _closeHiddenCircles() async {
  //   globalState.hiddenOpen = false;
  //   await UserCircleBloc.closeHiddenCircles(_firebaseBloc);
  //
  //   //if (mounted) {
  //   NavigationService.navigationKey.currentState!.pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (context) => const Home()),
  //       (Route<dynamic> route) => false);
  //
  //   _globalEventBloc.broadcastMemCacheCircleObjectsRemoveAllHidden();
  // }

  @override
  void dispose() {
    globalState.subscriptions.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //LogBloc.insertLog('$_share', 'app build');

    return MaterialApp(
        navigatorKey: NavigationService.navigationKey,
        theme: globalState.theme.getTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate, // Add this line

          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('en', ''), // English
          Locale('tr', ''), //Turkish
          // Locale('iw'), // Hebrew
        ],
        //locale: const Locale('en'),
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
          //case '/login':
          //return MaterialPageRoute(builder: (context) => Login());
            case '/landing':
              return MaterialPageRoute(builder: (context) => const Landing());
            case '/home':
              return MaterialPageRoute(builder: (context) => const Home());
          // case '/share':
          //   return MaterialPageRoute(
          //       builder: (context) => const ReceiveShare());
            default:
              return null;
          }
        },
        /*routes: <String, WidgetBuilder>{
        //'/': (context) => Login(),
        '/login': (context) => Login(),
        '/home': (context) => Home(),
        '/share': (context) => ReceiveShare(),
      },*/
        home: const AutoLogin(
          //messageReceived: _messageReceived,
        )
      //share: _share,
      //mediaCollection: _mediaCollection,
      //sharedText: _sharedText),
    );
  }
}