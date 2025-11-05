library global_state;

import 'dart:async';
import 'dart:io';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/member_bloc.dart';
import 'package:ironcirclesapp/constants/enums.dart';
import 'package:ironcirclesapp/encryption/forwardsecrecy_user.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/ironcoinwallet.dart';
import 'package:ironcirclesapp/models/officialnotification.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/models/stablediffusionpricing.dart';
import 'package:ironcirclesapp/screens/insidecircle/circleobjectscreens/capturemedia.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:ironcirclesapp/services/stablediffusion_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final GlobalState globalState = GlobalState._private();

class GlobalState {
  GlobalState._private();

  SecureStorageService secureStorageService = SecureStorageService();

  GlobalEventBloc globalEventBloc = GlobalEventBloc();

  ///open screen variables
  UserCircleCacheAndShare? enterCircle;
  UserCircleCacheAndShare? enterDM;
  //UserCircleCache? enterDM;
  int selectedHomeIndex = 0;
  int selectedCircleTabIndex = 1;
  //int? selectedCirclesIndex;

  bool showHomeTutorial = false;
  bool requestedFromLanding = false;
  bool showPrivateVaultPrompt = false;
  int? selectedNotificationType;
  HomeNavToScreen homeShortCutResultScreen = HomeNavToScreen.nothing;

  bool runOnce = false;
  PendingDynamicLinkData? initialLink;
  String? lastCreatedMagicLink;

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> subscriptions;
  List<PurchaseDetails> subscriptionQueue = [];
  Subscription? subscription;

  MediaCollection sharedMediaCollection = MediaCollection();
  String sharedText = '';
  RemoteMessage? messageReceived;
  int language = 1;
  String locale = 'en_us';

  ///UI GET in progress
  DateTime? lastInvitationByUserFetch;
  DateTime? lastInvitationByCircleFetch;
  DateTime? userCircleFetch;
  //DateTime? circleObjectFetch;
  //bool fetchingUserCircles = false;
  //bool fetchingCircleObjects = false;

  bool coldStart = true;
  StableDiffusionPricing stableDiffusionPricing = StableDiffusionPricing();

  User user = User();
  bool firstLoadComplete = false;
  UserFurnace? userFurnace = UserFurnace();
  List<UserFurnace> userFurnaces = [];
  UserSetting userSetting = UserSetting(id: '', username: '', fontSize: 16);
  String downloadDirectory = '';
  Device _device = Device(uuid: '', pushToken: '');
  String _appPath = '';
  bool loggingOut = false;
  bool loggedOutToLanding = false;
  bool hiddenOpen = false;
  bool handledRemoteNotificationCheck = false;
  List<RatchetKey> signatureKeys = [];
  bool updateAvailable = false;
  HostedInvitation? connectedHostedInvitation;
  //bool showInsideCircleTutorial = false;
  //bool _messageFeed = true;
  late MasterTheme theme;
  CaptureState captureState = CaptureState();
  final double _fontSize = FontSize.DEFAULT;
  List<Member> members = [];
  bool themeLoaded = false;
  double _mediaScaleFactor = 1.0;
  TextScaler _mediaScaler = const TextScaler.linear(1.0);
  final double _menuScaleFactor = 1.2;
  bool importing = false;
  final double _nameScaleFactor = 1.2;
  final double _screenNameScaleFactor = 1.2;
  final double _cardScaleFactor = 1.4;
  final double _labelScaleFactor = 1.4;
  final double _textFieldScaleFactor = 1.4;
  final double _dialogScaleFactor = 1.2;
  final double _dropdownScaleFactor = 1.2;
  final double _messageScaleFactor = 2.0;
  final double _messageHeaderScaleFactor = 1.2;
  final double screenWidthBeforeScaleDown = 360;
  double scaleDownButtonFont = 0;
  double scaleDownTextFont = 0;
  double scaleDownIcons = 0;
  bool _mustUpdate = false;
  bool dismissInvitations = false;
  IronCoinWallet ironCoinWallet = IronCoinWallet();

  //build information
  int build = 0;
  String version = '';

  //home variables
  double? lastSelectedIndexCircles;
  double? lastSelectedIndexDMs;
  String? lastSelectedFilter;
  String? circleTypeFilter;
  String? lastSelectedUserFilter;
  //bool? sortAlpha;
  bool? sortName;
  OfficialNotification? notification;

  ///Ok to lose state variables
  List<LastFetched> lastFetched = [];
  List<UserCircleCache> justHid = [];
  List<String> deletedUserCircleID = [];
  List<CircleObject> forcedOrder = [];
  String dezgoAPIKey = 'not fetched';
  String dezgoAPIKeyForRegistration = 'not fetched';

  getDezgoKey(UserFurnace userFurnace) async {
    if (dezgoAPIKey == 'not fetched' || dezgoAPIKey.isEmpty) {
      dezgoAPIKey = await StableDiffusionAIService.getKey(userFurnace);
    }
    return dezgoAPIKey;
  }

  Future<String> getDezgoKeyForRegistration() async {
    if (dezgoAPIKeyForRegistration == 'not fetched' ||
        dezgoAPIKeyForRegistration.isEmpty) {
      dezgoAPIKeyForRegistration =
          await StableDiffusionAIService.getKeyForRegistration();
    }

    return dezgoAPIKeyForRegistration;
  }

  setGlobalState() async {
    if (_appPath.isEmpty) {
      final AuthenticationBloc _authenticationBloc = AuthenticationBloc();
      await _authenticationBloc.authenticateUser();
      // User user = User();
      // UserFurnace? userFurnace = UserFurnace();

      await UserSetting.populateUserSettings('');
      // UserSetting userSetting = UserSetting(id: '', username: '', fontSize: 16);
      // late MasterTheme theme;

      getDevice();
      // Device _device = Device(uuid: '', pushToken: '');

      setAppPath();
      // String _appPath = '';

      await ForwardSecrecyUser.getSignatureKey(userFurnace!);
      // List<RatchetKey> signatureKeys = [];

      MemberBloc.populateGlobalStateWithAll();
      // List<Member> members = [];

      ///not used anymore
      // List<UserFurnace> userFurnaces = [];
    }
  }

  setLocaleAndLanguage(BuildContext context) {
    if (context.mounted == false) return;

    var lame = AppLocalizations.of(context);

    if (lame != null) {
      if (int.parse(lame.language) == Language.TURKISH) {
        locale = 'tr';
      }
      // locale = (AppLocalizations.of(context)!.language).toString() == Language.TURKISH.toString()? 'tr': 'en_us';
      language = (locale == 'tr') ? 2 : 1;
    }
  }

  setAppPath() async {
    //build\windows\x64\runner\Debug

    if (_appPath.isEmpty) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();

      if (Platform.isWindows) {
        _appPath = join(documentsDirectory.path, "irondesktop");

        if (kDebugMode || kProfileMode) {
          _appPath = join(_appPath, "debug");
        }
      } else {
        _appPath = documentsDirectory.path;

        if (Platform.isMacOS && (kDebugMode || kProfileMode)) {
          _appPath = join(_appPath, "debug");
        }
      }
    }
  }

  Future<String> getAppPath() async {
    if (_appPath.isEmpty) {
      await setAppPath();
    }
    return _appPath;
  }

  String getAppPathSync() {
    if (_appPath.isEmpty) {
      setAppPath();
    }
    return _appPath;
  }

  RatchetKey getSignatureKey(String userID) {
    ///todo this should be async and reload signatureKeys if blank
    if (signatureKeys.isNotEmpty) {
      int index = signatureKeys.indexWhere((element) => element.user == userID);

      if (index >= 0) {
        return signatureKeys[index];
      }
    }

    return RatchetKey.blank();
  }

  Future<Device> getDevice() async {
    if (_device.uuid == null ||
        _device.uuid!.isEmpty ||
        _device.pushToken == null ||
        _device.pushToken!.isEmpty) {
      _device = await TableDevice.read();
    }

    return _device;
  }

  String getDevicePushTokenSync() {
    return _device.pushToken ?? '';
  }

  String getDeviceUUIDSync() {
    return _device.uuid ?? '';
  }

  setDevice(Device device) {
    _device = device;
  }

  clearDevice() {
    _device = Device(uuid: '', pushToken: '');
  }

  isDesktop() {
    //return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    // ||
    //     Platform.isAndroid;
  }

  updateCoinBalance(double coins) {
    globalState.ironCoinWallet.balance = coins;
    // globalState.userSetting.ironCoin = coins;
    // TableUserSetting.upsert(userSetting);
  }

  // setCoinDefaults(currency) {
  //   globalState.imageDimension = [];
  //   globalState.upscaledImageDimension = [];
  //
  //   globalState.newUserCoins = currency[0];
  //   globalState.subscriberCoins = currency[1];
  //
  //   globalState.imageDimension.add(currency[2].toDouble());
  //   globalState.upscaledImageDimension.add(currency[3].toDouble());
  //
  //   globalState.imageDimension.add(currency[4].toDouble());
  //   globalState.upscaledImageDimension.add(currency[5].toDouble());
  //
  //   globalState.imageDimension.add(currency[6].toDouble());
  //   globalState.upscaledImageDimension.add(currency[7].toDouble());
  //
  //   globalState.imageDimension.add(currency[8].toDouble());
  //   globalState.upscaledImageDimension.add(currency[9].toDouble());
  //
  //   globalState.perLora = currency[10].toInt();
  //   globalState.perStep = currency[11].toDouble();
  //
  // }

  setScale(double screenWidth, {double? mediaScaleFactor}) {
    if (screenWidth <= screenWidthBeforeScaleDown) {
      scaleDownButtonFont = 3;
      scaleDownTextFont = 3;
      scaleDownIcons = 5;
    }

    if (mediaScaleFactor != null) {
      _setMediaScaleFactor = mediaScaleFactor;
    }

    return screenWidth;
  }

  setScaler(double screenWidth, {TextScaler? mediaScaler}) {
    if (screenWidth <= screenWidthBeforeScaleDown) {
      scaleDownButtonFont = 3;
      scaleDownTextFont = 3;
      scaleDownIcons = 5;
    }

    if (mediaScaler != null) {
      _setMediaScaler = mediaScaler;
    }

    return screenWidth;
  }

  // double get mediaScaler {
  //   return _mediaScaler;
  // }
  //
  double get chipDividerFactor {
    return _mediaScaleFactor;
  }

  double get mediaScaleFactor {
    return _mediaScaleFactor;
  }

  double get dropdownScaleFactor {
    if (_mediaScaleFactor < _dropdownScaleFactor)
      return _mediaScaleFactor;
    else
      return _dropdownScaleFactor;
  }

  double get messageHeaderScaleFactor {
    if (_mediaScaleFactor < _messageHeaderScaleFactor)
      return _mediaScaleFactor;
    else
      return _messageHeaderScaleFactor;
  }

  double get messageScaleFactor {
    if (_mediaScaleFactor < _messageScaleFactor)
      return _mediaScaleFactor;
    else
      return _messageScaleFactor;
  }

  double get dialogScaleFactor {
    if (_mediaScaleFactor < _dialogScaleFactor)
      return _mediaScaleFactor;
    else
      return _dialogScaleFactor;
  }

  double get labelScaleFactor {
    if (_mediaScaleFactor < _labelScaleFactor)
      return _mediaScaleFactor;
    else
      return _labelScaleFactor;
  }

  double get textFieldScaleFactor {
    if (_mediaScaleFactor < _textFieldScaleFactor)
      return _mediaScaleFactor;
    else
      return _textFieldScaleFactor;
  }

  double get menuScaleFactor {
    if (_mediaScaleFactor < _menuScaleFactor)
      return _mediaScaleFactor;
    else
      return _menuScaleFactor;
  }

  double get nameScaleFactor {
    return 1.0;

    /*
    if (_mediaScaleFactor < _nameScaleFactor)
      return _mediaScaleFactor;
    else
      return _nameScaleFactor;

     */
  }

  double get screenNameScaleFactor {
    return 1.0;
    /*
    if (_mediaScaleFactor < _screenNameScaleFactor)
      return _mediaScaleFactor;
    else
      return _screenNameScaleFactor;

     */
  }

  double get cardScaleFactor {
    return 1.0;

    /*if (_mediaScaleFactor < _cardScaleFactor)
      return _mediaScaleFactor;
    else
      return _cardScaleFactor;

     */
  }

  set _setMediaScaleFactor(double mediaScaleFactor) {
    _mediaScaleFactor = mediaScaleFactor;
  }

  set _setMediaScaler(TextScaler mediaScaler) {
    _mediaScaler = mediaScaler;
    //_textScalerScale - mediaScaler.scale;
  }

  double _textScalerScale = 1.0;

  double get titleSize {
    return _fontSize + 2;
  }

  double get dateFontSize {
    return _fontSize - 2;
  }

  double get emojiOnlySize {
    return _fontSize + 15;
  }

  double get emojiEmbededSize {
    return _fontSize + 7;
  }

  bool get mustUpdate {
    return _mustUpdate;
  }

  Color getRadioColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.disabled,
      MaterialState.selected,
    };
    if (states.any(interactiveStates.contains)) {
      return globalState.theme.buttonIcon;
    }
    return globalState.theme.buttonDisabled;
  }

  Color getSwitchColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
      MaterialState.selected,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.lightBlueAccent.withOpacity(.1);
    }
    return Colors.transparent;
  }

  int minimumBuild = -1;

  setUpdateAvailable(int latestBuild, [int? minimumBuild]) async {
    if (build < latestBuild) {
      updateAvailable = true;
    } else {
      updateAvailable = false;
    }

    if (minimumBuild != null && build < minimumBuild) {

      this.minimumBuild = minimumBuild;
      _mustUpdate = true;
    }
  }

  dispose() async {
    subscriptions.cancel();
  }
}

class LastFetched {
  UserFurnace userFurnace;
  DateTime lastFetched;

  LastFetched(this.userFurnace, this.lastFetched);
}
