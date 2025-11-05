/*

///  IronCircles Elliptic Curve Diffie–Hellman (ECDH) key agreement scheme (Curve25519)
///  Achieves forward secrecy by ratcheting a key for each message
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/encryption/v1/forwardsecrecy.dart' as v1;
import 'package:ironcirclesapp/encryption/forwardsecrecy.dart';
import 'package:ironcirclesapp/models/export_models.dart';

import 'package:ironcirclesapp/models/ratchetkey.dart';

class FSVersionControl {
  static Future<List<CircleObject>> decryptCircleObjects(
    String userID,
    String userCircleID,
    List<CircleObject> circleObjects,
  ) async {
    try {
      return v1.ForwardSecrecy.decryptCircleObjects(
        userID,
        userCircleID,
        circleObjects,
      );
    } catch (err, trace) {
      LogBloc.insertError(err, trace,
          source: 'ForwardSecrecy.decryptCircleObjects');
      rethrow;
    }
  }

  static Future<RatchetKey> generateKeyPair(
      String user, String userCircle) async {
    try {
      return v1.ForwardSecrecy.generateKeyPair(user, userCircle);
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('RatchetKey.generateKeyPair: $err');
      rethrow;
    }
  }
}

 */
