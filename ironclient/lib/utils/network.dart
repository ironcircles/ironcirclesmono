import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class Network {
  static Future<bool> isConnected() async {
    bool connected = true;

    //return connected;
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      connected = false;
    }

    return connected;
  }

  static Future<bool> isMobile() async {
    bool mobile = true;

    var connectivityResult = await (Connectivity().checkConnectivity());

    ///check kDebugMode because emulator is always connected to mobile
    if ( kDebugMode || connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn) ||
        connectivityResult.contains(ConnectivityResult.bluetooth) ||
        connectivityResult.contains(ConnectivityResult.other) ||
        connectivityResult.contains(ConnectivityResult.none)) {
      mobile = false;
    }

    return mobile;
  }
}
