import 'dart:async';
import 'dart:math' as math;

import 'package:ironcirclesapp/services/voice_memo_service.dart';
import 'package:ironcirclesapp/services/voice_platform_channel.dart';

class VoiceInputState {
  final bool memoRecording;
  final bool voiceToTextActive;
  final String partialText;
  final double soundLevel;
  final double waveformLevel;
  final VoiceMemoDraft? draft;

  const VoiceInputState({
    required this.memoRecording,
    required this.voiceToTextActive,
    required this.partialText,
    required this.soundLevel,
    required this.waveformLevel,
    required this.draft,
  });

  VoiceInputState copyWith({
    bool? memoRecording,
    bool? voiceToTextActive,
    String? partialText,
    double? soundLevel,
    double? waveformLevel,
    VoiceMemoDraft? draft,
  }) {
    return VoiceInputState(
      memoRecording: memoRecording ?? this.memoRecording,
      voiceToTextActive: voiceToTextActive ?? this.voiceToTextActive,
      partialText: partialText ?? this.partialText,
      soundLevel: soundLevel ?? this.soundLevel,
      waveformLevel: waveformLevel ?? this.waveformLevel,
      draft: draft ?? this.draft,
    );
  }

  static const VoiceInputState initial = VoiceInputState(
    memoRecording: false,
    voiceToTextActive: false,
    partialText: '',
    soundLevel: 0.0,
    waveformLevel: 0.0,
    draft: null,
  );
}

class VoiceInputBloc {
  final _stateController = StreamController<VoiceInputState>.broadcast();
  VoiceInputState _state = VoiceInputState.initial;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  VoiceInputBloc() {
    _eventSubscription = VoicePlatformChannel.events.listen(_handlePlatformEvent);
  }

  Stream<VoiceInputState> get stream => _stateController.stream;

  VoiceInputState get state => _state;

  void _emit(VoiceInputState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<bool> startVoiceMemoRecording() async {
    if (_state.memoRecording) return false;
    final started = await VoiceMemoService.startRecording();
    if (started) {
      _emit(_state.copyWith(memoRecording: true, draft: null, waveformLevel: 0.0));
    }
    return started;
  }

  Future<VoiceMemoDraft?> stopVoiceMemoRecording() async {
    if (!_state.memoRecording) return null;
    final draft = await VoiceMemoService.stopRecording();
    _emit(_state.copyWith(
      memoRecording: false,
      draft: draft,
      soundLevel: 0.0,
      waveformLevel: 0.0,
    ));
    return draft;
  }

  Future<void> discardVoiceMemoDraft() async {
    await VoiceMemoService.discardDraft();
    _emit(_state.copyWith(draft: null, soundLevel: 0.0, waveformLevel: 0.0));
  }

  Future<EncryptedVoiceMemo?> finalizeVoiceMemoDraft({
    List<int>? secretKey,
    List<double>? waveform,
  }) async {
    final result = await VoiceMemoService.finalizeDraft(
      secretKey: secretKey,
      waveform: waveform,
    );
    if (result != null) {
      _emit(_state.copyWith(draft: null, soundLevel: 0.0, waveformLevel: 0.0));
    }
    return result;
  }

  Future<void> cancelVoiceMemoRecording() async {
    if (_state.memoRecording) {
      await VoiceMemoService.cancelRecording();
      _emit(_state.copyWith(memoRecording: false, soundLevel: 0.0, waveformLevel: 0.0));
    }
  }

  Future<bool> startVoiceToText() async {
    if (_state.voiceToTextActive) return false;
    await VoicePlatformChannel.startVoiceToText();
    _emit(_state.copyWith(voiceToTextActive: true, partialText: ''));
    return true;
  }

  Future<void> stopVoiceToText() async {
    if (!_state.voiceToTextActive) return;
    await VoicePlatformChannel.stopVoiceToText();
    _emit(_state.copyWith(voiceToTextActive: false));
  }

  void clearPartial() {
    _emit(_state.copyWith(partialText: ''));
  }

  void _handlePlatformEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final status = event['status'] as String?;

    if (type == 'voiceMemo') {
      switch (status) {
        case 'started':
          _emit(_state.copyWith(memoRecording: true, soundLevel: 0.0, waveformLevel: 0.0));
          break;
        case 'error':
          _emit(_state.copyWith(memoRecording: false, soundLevel: 0.0, waveformLevel: 0.0));
          break;
        case 'amplitude':
          final level = (event['level'] as num?)?.toDouble() ?? 0.0;
          final smoothed = level > 0.01
              ? level.clamp(0.0, 1.0)
              : (_state.soundLevel * 0.82);
          final rawRms = (event['rms'] as num?)?.toDouble();
          final rawPeak = (event['peak'] as num?)?.toDouble();
          final double rawValue =
              (rawPeak ?? rawRms ?? level).clamp(0.0, 1.0);
          final double shapedWaveform =
              math.pow(rawValue, 0.45).toDouble().clamp(0.0, 1.0);
          _emit(_state.copyWith(
            soundLevel: smoothed.clamp(0.0, 1.0),
            waveformLevel: shapedWaveform,
          ));
          break;
        case 'stopped':
        case 'cancelled':
          _emit(_state.copyWith(
            memoRecording: false,
            soundLevel: 0.0,
            waveformLevel: 0.0,
          ));
          break;
        default:
          break;
      }
    } else if (type == 'voiceToText') {
      switch (status) {
        case 'started':
        case 'ready':
        case 'listening':
        case 'processing':
          _emit(_state.copyWith(voiceToTextActive: true));
          break;
        case 'partial':
          final text = event['text'] as String? ?? '';
          _emit(_state.copyWith(partialText: text));
          break;
        case 'final':
          final text = event['text'] as String? ?? '';
          _emit(_state.copyWith(partialText: text));
          break;
        case 'stopped':
        case 'error':
          _emit(_state.copyWith(voiceToTextActive: false));
          break;
        default:
          break;
      }
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _stateController.close();
  }
}
