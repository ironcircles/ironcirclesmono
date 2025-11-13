import 'dart:async';

import 'package:flutter/services.dart';

class VoicePlatformChannel {
  VoicePlatformChannel._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.ironcircles/voice_channel');
  static const EventChannel _eventChannel =
      EventChannel('com.ironcircles/voice_events');

  static Stream<Map<String, dynamic>>? _cachedEvents;

  static Stream<Map<String, dynamic>> get events =>
      _cachedEvents ??= _eventChannel.receiveBroadcastStream().map((dynamic event) {
        if (event is Map) {
          return event.cast<String, dynamic>();
        }
        return <String, dynamic>{};
      }).asBroadcastStream();

  static Future<Map<String, dynamic>?> startVoiceMemo() async {
    final dynamic response = await _methodChannel.invokeMethod('startVoiceMemo');
    return _asStringMap(response);
  }

  static Future<Map<String, dynamic>?> stopVoiceMemo() async {
    final dynamic response = await _methodChannel.invokeMethod('stopVoiceMemo');
    return _asStringMap(response);
  }

  static Future<void> cancelVoiceMemo() async {
    await _methodChannel.invokeMethod('cancelVoiceMemo');
  }

  static Future<void> startVoiceToText() async {
    await _methodChannel.invokeMethod('startVoiceToText');
  }

  static Future<void> stopVoiceToText() async {
    await _methodChannel.invokeMethod('stopVoiceToText');
  }

  static Future<Map<String, dynamic>?> checkMicrophone({bool forcePrompt = false}) async {
    final dynamic response = await _methodChannel.invokeMethod(
      'checkMicrophone',
      <String, dynamic>{'forcePrompt': forcePrompt},
    );
    return _asStringMap(response);
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }
}
