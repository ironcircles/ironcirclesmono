import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/services/voice_platform_channel.dart';

class VoiceMemoDraft {
  final String filePath;
  final int durationMs;
  final List<double> waveform;

  VoiceMemoDraft({
    required this.filePath,
    required this.durationMs,
    List<double>? waveform,
  }) : waveform = waveform ?? const [];

  VoiceMemoDraft copyWith({
    String? filePath,
    int? durationMs,
    List<double>? waveform,
  }) {
    return VoiceMemoDraft(
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      waveform: waveform ?? this.waveform,
    );
  }
}

class EncryptedVoiceMemo {
  final File encryptedFile;
  final List<int> secretKey;
  final String nonce;
  final String mac;
  final int durationMs;
  final Uint8List previewBytes;
  final List<double> waveform;

  const EncryptedVoiceMemo({
    required this.encryptedFile,
    required this.secretKey,
    required this.nonce,
    required this.mac,
    required this.durationMs,
    required this.previewBytes,
    required this.waveform,
  });
}

class VoiceMemoService {
  VoiceMemoService._();

  static String? _currentRecordingPath;
  static VoiceMemoDraft? _pendingDraft;

  static VoiceMemoDraft? get pendingDraft => _pendingDraft;

  static Future<bool> startRecording() async {
    final response = await VoicePlatformChannel.startVoiceMemo();
    final path = response?['path'] as String?;
    if (path == null) {
      debugPrint('VoiceMemoService.startRecording: no file path returned');
      return false;
    }
    _currentRecordingPath = path;
    _pendingDraft = null;
    return true;
  }

  static Future<VoiceMemoDraft?> stopRecording() async {
    final response = await VoicePlatformChannel.stopVoiceMemo();
    final path = response?['path'] as String?;
    final durationMs = (response?['durationMs'] as num?)?.toInt() ?? 0;

    if (path == null) {
      debugPrint('VoiceMemoService.stopRecording: no file path returned');
      return null;
    }

    final file = File(path);
    if (!file.existsSync()) {
      debugPrint('VoiceMemoService.stopRecording: file missing at $path');
      return null;
    }

    final draft = VoiceMemoDraft(filePath: path, durationMs: durationMs);
    _currentRecordingPath = null;
    _pendingDraft = draft;
    return draft;
  }

  static Future<void> discardDraft() async {
    final draft = _pendingDraft;
    if (draft != null) {
      try {
        final file = File(draft.filePath);
        if (file.existsSync()) file.deleteSync();
      } catch (err) {
        debugPrint('VoiceMemoService.discardDraft: unable to delete file -> $err');
      }
    }
    _pendingDraft = null;
  }

  static Future<EncryptedVoiceMemo?> finalizeDraft({
    List<int>? secretKey,
    List<double>? waveform,
  }) async {
    final draft = _pendingDraft;
    if (draft == null) {
      debugPrint('VoiceMemoService.finalizeDraft: no pending draft');
      return null;
    }

    final file = File(draft.filePath);
    if (!file.existsSync()) {
      debugPrint('VoiceMemoService.finalizeDraft: draft file missing at ${draft.filePath}');
      _pendingDraft = null;
      return null;
    }

    late final Uint8List previewBytes;
    try {
      previewBytes = await file.readAsBytes();
    } catch (err) {
      debugPrint('VoiceMemoService.finalizeDraft: unable to read preview bytes -> $err');
      previewBytes = Uint8List(0);
    }

    final encryptedArgs = await EncryptBlob.encryptBlob(
      draft.filePath,
      secretKey: secretKey,
    );

    try {
      if (file.existsSync()) file.deleteSync();
    } catch (err) {
      debugPrint('VoiceMemoService.finalizeDraft: unable to delete original file -> $err');
    }

    _pendingDraft = null;
    return EncryptedVoiceMemo(
      encryptedFile: encryptedArgs.encrypted,
      secretKey: encryptedArgs.key ?? [],
      nonce: encryptedArgs.nonce,
      mac: encryptedArgs.mac,
      durationMs: draft.durationMs,
      previewBytes: previewBytes,
      waveform: waveform ?? draft.waveform,
    );
  }

  static Future<void> cancelRecording() async {
    await VoicePlatformChannel.cancelVoiceMemo();
    final path = _currentRecordingPath;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (err) {
        debugPrint('VoiceMemoService.cancelRecording: unable to delete temp file -> $err');
      }
    }
    _currentRecordingPath = null;
  }
}
