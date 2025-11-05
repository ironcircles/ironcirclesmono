import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/constants/urls.dart';
import 'package:ironcirclesapp/encryption/encryptapitraffic.dart';
import 'package:ironcirclesapp/encryption/kyber/kyber.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
import 'package:ironcirclesapp/services/cache/table_device.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';
import 'package:ironcirclesapp/services/device_service.dart';
import 'package:ironcirclesapp/services/navigation_service.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:ironcirclesapp/utils/network.dart';
import 'package:rxdart/rxdart.dart';

class DeviceBloc {
  DeviceService _deviceService = DeviceService();

  final _devicesLoaded = PublishSubject<List<Device>>();
  Stream<List<Device>> get devicesLoaded => _devicesLoaded.stream;

  final _deactivated = PublishSubject<Device>();
  Stream<Device> get deactivated => _deactivated.stream;

  final _wiped = PublishSubject<Device>();
  Stream<Device> get wiped => _wiped.stream;

  static String getPlatformString() {
    return Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "iOS"
            : Platform.isMacOS
                ? "macos"
                : Platform.isLinux
                    ? "linux"
                    : Platform.isWindows
                        ? "windows"
                        : "unknown";
  }

  // updateDeviceID(Device device) async {
  //   try {
  //     UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();
  //     userFurnace ??= UserFurnace(url: urls.forge, apikey: urls.forgeAPIKEY);
  //
  //     await _deviceService.updateDeviceID(userFurnace, device);
  //
  //
  //   } catch (err) {
  //     rethrow;
  //   }
  // }

  Future<bool> isKyberInit(Device device) async {
    UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();
    userFurnace ??= UserFurnace(url: urls.forge, apikey: urls.forgeAPIKEY);

    // Map map = {'test': 'test'};
    //
    // var encrypt = await EncryptAPITraffic.encrypt(device, map);
    //
    //
    // var decrypt = await EncryptAPITraffic.decryptTest(device, encrypt);

    // await _service.kyberTest(device, userFurnace.url ?? urls.forge);
    //
    //   return true;

    if (device.kyberSharedSecret == null || device.kyberSharedSecret!.isEmpty) {
      ///are we connected to the internet?
      bool connected = true;

      ///TBR
      connected = await Network.isConnected();

      if (connected) {
        return false;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  getNewKyberPublicKey(Device device) async {
    try {
      UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();
      userFurnace ??= UserFurnace(url: urls.forge, apikey: urls.forgeAPIKEY);

      // await _service.kyberTest(device, userFurnace.url ?? urls.forge);
      //
      // return;

      ///get the server public key
      KyberEncryptionResult kyberEncryptionResult = await _deviceService
          .getNewKyberPublicKey(device, userFurnace.url ?? urls.forge);

      ///send the cipher text (cc) for the server to calculate the shared secret
      await _deviceService.postCipherText(device, userFurnace.url ?? urls.forge,
          kyberEncryptionResult.cipherText.bytes);

      ///store the shared secret in encrypted storage
      device.kyberSharedSecret =
          base64UrlEncode(kyberEncryptionResult.sharedSecret.bytes);
      //List<int> testing = base64Url.decode(device.kyberSharedSecret!);

      await TableDevice.upsert(device);
      globalState.setDevice(device);
    } catch (err) {
      rethrow;
    }
  }

  updateKyberPublicKey(Device device) async {
    try {
      UserFurnace? userFurnace = await TableUserFurnace.readMostRecent();
      userFurnace ??= UserFurnace(url: urls.forge, apikey: urls.forgeAPIKEY);

      ///get the server public key
      KyberEncryptionResult kyberEncryptionResult =
          await _deviceService.updateKyberPublicKey(
              userFurnace, device, userFurnace.url ?? urls.forge);

      ///send the cipher text (cc) for the server to calculate the shared secret
      await _deviceService.putCipherText(
          userFurnace,
          device,
          userFurnace.url ?? urls.forge,
          kyberEncryptionResult.cipherText.bytes);

      ///store the shared secret in encrypted storage
      device.kyberSharedSecret =
          base64UrlEncode(kyberEncryptionResult.sharedSecret.bytes);

      await TableDevice.upsert(device);
      globalState.setDevice(device);
    } catch (err) {
      rethrow;
    }
  }

  get(List<UserFurnace> userFurnaces) async {
    try {
      List<Device> sinkValue = [];

      for (UserFurnace userFurnace in userFurnaces) {
        List<Device> devices = await _deviceService.get(userFurnace);
        sinkValue.addAll(devices);
      }

      ///remove deactivated devices
      sinkValue.removeWhere((element) => element.activated == false);
      sinkValue.sort((a, b) => b.lastAccessed!.compareTo(a.lastAccessed!));

      ///Remove duplicates. The user could be on more than one furnace at a time
      final ids = Set();
      sinkValue.retainWhere((x) => ids.add(x.uuid!));

      _devicesLoaded.sink.add(sinkValue);
    } catch (err) {
      _devicesLoaded.sink.addError(err.toString());
    }
  }

  remoteWipe(Device device) async {
    try {
      await _deviceService.remoteWipe(device);
      _wiped.sink.add(device);
    } catch (err) {
      _wiped.sink.addError(err.toString());
    }
  }

  static wipeDeviceCallback(String toastMessage) async {
    navService.logout(globalState.userFurnace!, toastMessage: toastMessage);

    ///clear the database
    DatabaseBloc.clearCache();

    ///Clear all files
    FileSystemService.deleteCache();

    ///remove the backup key
    globalState.secureStorageService.writeKey(
        KeyType.USER_KEYCHAIN_BACKUP_DEPRECATED +
            globalState.userFurnace!.userid!,
        '');
    globalState.userSetting.setBackupKey('');

    ///remove the backup key
    globalState.userSetting.setLastIncremental(DateTime.parse('20200101'));
    globalState.userSetting.setLastFull(DateTime.parse('20200101'));
    globalState.secureStorageService
        .writeKey(KeyType.LAST_KEYCHAIN_BACKUP_DEPRECATED, '');

    ///clear globalstate
    globalState.sharedMediaCollection = MediaCollection();
    globalState.sharedText = '';
    globalState.messageReceived = null;
    globalState.userFurnace = UserFurnace();
    globalState.userFurnaces = [];
    globalState.userSetting = UserSetting(id: '', username: '', fontSize: 16);
    globalState.clearDevice();
    //globalState.deviceID = '';
    globalState.hiddenOpen = false;
  }

  static deactivateDeviceCallback() async {
    navService.logout(globalState.userFurnace!);
  }

  deactivate(Device device) async {
    try {
      await _deviceService.deactivate(device);
      _deactivated.sink.add(device);
    } catch (err) {
      _deactivated.sink.addError(err.toString());
    }
  }

  dispose() async {
    await _devicesLoaded.drain();
    _devicesLoaded.close();

    await _deactivated.drain();
    _deactivated.close();

    await _wiped.drain();
    _wiped.close();
  }
}
